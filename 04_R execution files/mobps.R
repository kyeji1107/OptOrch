library(slam)
library(gurobi)
library(Matrix)

read_tuned_params <- function(prm_path = "tuned.prm") {
  if (!file.exists(prm_path)) {
    stop(sprintf("Tuned parameter file not found: %s", prm_path))
  }
  lines <- readLines(prm_path, warn = FALSE)
  lines <- trimws(lines)
  lines <- lines[lines != ""]
  lines <- lines[!startsWith(lines, "#")]
  if (length(lines) == 0) {
    warning(sprintf("No active parameter lines found in %s", prm_path))
    return(list())
  }
  parts <- strsplit(lines, "\\s+")
  param_names <- vapply(parts, function(x) x[1], character(1))
  param_vals_raw <- vapply(parts, function(x) if (length(x) >= 2) x[2] else NA_character_, character(1))
  param_vals <- lapply(param_vals_raw, function(v) {
    num <- suppressWarnings(as.numeric(v))
    if (!is.na(num)) num else v
  })
  names(param_vals) <- param_names
  param_vals
}

#---------------------------------------------------------------
# 0) Path ------------------------------------------------------

DATA_DIR <- ""
OUT_DIR <- ""
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

# 1) Parameter -------------------------------------------------

nc <- 500
ns_grid <- c(10, 20, 30, 40)
iter_grid <- 1:30

L <- rep(0.01, nc)
U <- rep(0.15, nc)

lb <- c(rep(0, nc),  rep(0, nc))
ub <- c(rep(0.15, nc), rep(1, nc))

params_base <- list(
  MIPGap = 0.005,
  OutputFlag = 1,
  NonConvex  = 2
)

# 2) Linear constraints ----------------------------------------

A_c2 <- Matrix(0, 1, 2 * nc, sparse = TRUE)
A_c2[1, 1:nc] <- 1

A_c3a <- cbind(Diagonal(nc, 1), Diagonal(nc, -L))
A_c3b <- cbind(Diagonal(nc, 1), Diagonal(nc, -U))

A_all <- rbind(A_c2, A_c3a, A_c3b)
rhs_all <- c(1, rep(0, nc), rep(0, nc))
sense_all <- c("=", rep(">", nc), rep("<", nc))

# 3) Load Data and Run Optimization ---------------------------

for (ns in ns_grid) {
  
  ### ns-specific dir ###
  ns_dir <- file.path(OUT_DIR, sprintf("ns_%02d", ns))
  dir.create(ns_dir, showWarnings = FALSE, recursive = TRUE)
  
  cat(sprintf("\n===== ns = %d started =====\n", ns))
  flush.console()
  
  for (iter in iter_grid) {
    
    cat(sprintf("ns=%d | iter=%d running...\n", ns, iter))
    flush.console()
    
    ### iter-specific dir under ns ###
    iter_dir <- file.path(ns_dir, paste0("rep_", iter))
    dir.create(iter_dir, showWarnings = FALSE, recursive = TRUE)
    
    ### iter-specific collectors ###
    results_summary_iter <- list()
    row_id_iter <- 0
    
    selected_rows_iter <- list()
    sel_row_id_iter <- 0
    
    ### file paths ###
    c_path <- list.files(
      DATA_DIR,
      pattern = paste0("^rep", iter, "_Gmatrix_tuned_all\\.csv$"),
      full.names = TRUE
    )[1]
    
    b_path <- list.files(
      DATA_DIR,
      pattern = paste0("^rep", iter, "_GBLUP_results\\.csv$"),
      full.names = TRUE
    )[1]
    
    if (is.na(c_path) || is.na(b_path)) {
      cat(sprintf("ns=%d iter=%d skipped (missing C or BV file)\n", ns, iter))
      next
    }
    
    ### C matrix (block 102~601 in csv) ###
    dfC <- read.csv(c_path, header = FALSE, stringsAsFactors = FALSE, check.names = FALSE)
    C_block <- dfC[102:601, 102:601, drop = FALSE]
    C_full <- apply(C_block, 2, function(x) suppressWarnings(as.numeric(x)))
    C_full <- as.matrix(C_full)
    C_mat <- C_full * 0.5
    
    ### FORCE PSD (Positive Semi-Definiteness) ###
    eig <- eigen(C_mat, symmetric = TRUE)
    eig$values[eig$values < 1e-6] <- 1e-6
    C_mat <- eig$vectors %*% diag(eig$values) %*% t(eig$vectors)
    
    Qc_full <- Matrix::Matrix(0, 2 * nc, 2 * nc, sparse = TRUE)
    Qc_full[1:nc, 1:nc] <- Matrix::Matrix(C_mat, sparse = TRUE)
    
    ### BV (ASReml) ###
    dfB <- read.csv(b_path, header = TRUE, stringsAsFactors = FALSE, check.names = FALSE)
    
    ### row 102~601 in csv == row 101~600 in dfB ###
    raw_id <- as.character(dfB[[1]][101:600])
    ID_vec <- sub("^.*([0-9]{6})$", "\\1", raw_id)
    BV_vec <- suppressWarnings(as.numeric(dfB[[2]][101:600]))
    
    model <- list(
      modelsense = "max",
      obj = c(BV_vec, rep(0, nc)),
      vtype = c(rep("C", nc), rep("B", nc)),
      lb = lb,
      ub = ub,
      A = A_all,
      rhs = rhs_all,
      sense = sense_all,
      quadcon = list(
        list(
          Qc = Qc_full,
          rhs = 1 / (2 * ns),
          sense = "<"
        )
      )
    )
    
    # PARAMs
    PARAM_DIR_BASE <- ""
    PARAM_DIR <- paste0(PARAM_DIR_BASE, ns)
    tuned_prm1 <- file.path(PARAM_DIR, "tuned_prm1.prm")
    
    if (!file.exists(tuned_prm1)) {
      stop(sprintf("Tuned prm file not found for ns=%d: %s", ns, tuned_prm1))
    }
    
    res <- gurobi(model, params = read_tuned_params(tuned_prm1))
    #res <- gurobi(model, params = params_base)
    
    status <- if (!is.null(res$status)) res$status else "NULL"
    objval <- if (!is.null(res$objval)) res$objval else NA_real_
    runtime <- if (!is.null(res$runtime)) res$runtime else NA_real_
    
    if (identical(status, "OPTIMAL")) {
      
      p_vals <- res$x[1:nc]
      r_vals <- res$x[(nc + 1):(2 * nc)]
      
      selected_idx <- which(r_vals > 0.5)
      n_selected <- length(selected_idx)
      
      cat(sprintf(
        "ns=%d iter=%d status=OK obj=%.4f n=%d runtime=%.2f\n",
        ns, iter, objval, n_selected, runtime
      ))
      
      ### save p / r ###
      saveRDS(
        p_vals,
        file.path(iter_dir, sprintf("p_rep_%02d_ns_%02d.rds", iter, ns))
      )
      saveRDS(
        r_vals,
        file.path(iter_dir, sprintf("r_rep_%02d_ns_%02d.rds", iter, ns))
      )
      
      ### summary row ###
      row_id_iter <- row_id_iter + 1
      results_summary_iter[[row_id_iter]] <- data.frame(
        iter = iter,
        ns = ns,
        status = status,
        objval = objval,
        runtime = runtime,
        n_selected = n_selected,
        stringsAsFactors = FALSE
      )
      
      if (n_selected > 0) {
        
        sel_ids <- ID_vec[selected_idx]
        sel_bv  <- BV_vec[selected_idx]
        
        sel_df <- data.frame(
          ID = sel_ids,
          iter = iter,
          ns = ns,
          bv = sel_bv,
          p = p_vals[selected_idx],
          r = r_vals[selected_idx],
          stringsAsFactors = FALSE
        )
        
        sel_row_id_iter <- sel_row_id_iter + 1
        selected_rows_iter[[sel_row_id_iter]] <- sel_df
        
        ### Csub ###
        C_sub <- C_mat[selected_idx, selected_idx, drop = FALSE]
        write.csv(
          C_sub,
          file.path(iter_dir, sprintf("Csub_rep_%02d_ns_%02d.csv", iter, ns)),
          row.names = TRUE
        )
      }
      
    } else {
      
      cat(sprintf("ns=%d iter=%d status=%s\n", ns, iter, status))
      
      row_id_iter <- row_id_iter + 1
      results_summary_iter[[row_id_iter]] <- data.frame(
        iter = iter,
        ns = ns,
        status = status,
        objval = objval,
        runtime = runtime,
        n_selected = NA_integer_,
        stringsAsFactors = FALSE
      )
    }
    
    ### save iter-specific summary ###
    if (length(results_summary_iter) > 0) {
      write.csv(
        do.call(rbind, results_summary_iter),
        file.path(iter_dir, "summary.csv"),
        row.names = FALSE
      )
    }
    
    ### save iter-specific selected individuals ###
    if (length(selected_rows_iter) > 0) {
      write.csv(
        do.call(rbind, selected_rows_iter),
        file.path(iter_dir, "selected_individuals.csv"),
        row.names = FALSE
      )
    }
  }
}

cat("Done. Results are grouped by ns, then per iteration.\n")
