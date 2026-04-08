library(slam)
library(gurobi)
library(Matrix)
library(data.table)

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

# pollen contamination
np <- 100
C  <- 0.3
s_p <- 1 - C/2

L <- rep(0.01, nc)
U <- rep(0.15, nc)

lb <- c(rep(0, nc),  rep(0, nc))
ub <- c(rep(0.15, nc), rep(1, nc))


# 2) Linear constraints ----------------------------------------

A_c2 <- Matrix(0, 1, 2 * nc, sparse = TRUE)
A_c2[1, 1:nc] <- 1

A_c3a <- cbind(Diagonal(nc, 1), Diagonal(nc, -L))
A_c3b <- cbind(Diagonal(nc, 1), Diagonal(nc, -U))

A_all <- rbind(A_c2, A_c3a, A_c3b)
rhs_all <- c(s_p, rep(0, nc), rep(0, nc))
sense_all <- c("=", rep(">", nc), rep("<", nc))

# 3) Load Data and Run Optimization ---------------------------

for (ns in ns_grid) {
  ns_dir <- file.path(OUT_DIR, sprintf("ns_%02d", ns))
  dir.create(ns_dir, showWarnings = FALSE, recursive = TRUE)
  
  for (iter in iter_grid) { # 1:30 -> iter_grid
    iter_dir <- file.path(ns_dir, paste0("rep_", iter))
    dir.create(iter_dir, showWarnings = FALSE, recursive = TRUE)
    
    c_path <- list.files(DATA_DIR, pattern = paste0("^rep", iter, "_Gmatrix_tuned_all\\.csv$"), full.names = TRUE)[1]
    b_path <- list.files(DATA_DIR, pattern = paste0("^rep", iter, "_GBLUP_results\\.csv$"), full.names = TRUE)[1]
    ext_path <- file.path(DATA_DIR, sprintf("rep%d_Np2_Data.csv", iter))
    
    dfExt <- fread(ext_path)
    BV_ext_mean <- mean(as.numeric(dfExt$BV), na.rm = TRUE)
    
    ### C matrix (block 102~601 in csv) ###
    dfC <- read.csv(c_path, header = FALSE)
    C_block <- dfC[102:601, 102:601]
    C_mat <- apply(C_block, 2, as.numeric)
    C_mat <- as.matrix(C_mat) * 0.5
    
    ### FORCE PSD (Positive Semi-Definiteness) ###
    eig <- eigen(C_mat, symmetric = TRUE)
    eig$values[eig$values < 1e-6] <- 1e-6
    C_mat <- eig$vectors %*% diag(eig$values) %*% t(eig$vectors)
    
    Qc_full <- Matrix(0, 2 * nc, 2 * nc, sparse = TRUE)
    Qc_full[1:nc, 1:nc] <- Matrix(C_mat, sparse = TRUE)
    
    ### BV (ASReml) ###
    dfB <- read.csv(b_path, header = TRUE)
    
    ### row 102~601 in csv == row 101~600 in dfB ###
    raw_id <- as.character(dfB[[1]][101:600])
    ID_vec <- sub("^.*([0-9]{6})$", "\\1", raw_id)
    BV_vec <- as.numeric(dfB[[2]][101:600])
    
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
          rhs = (1 / (2 * ns)) - (C^2 / (8 * np)),
          sense = "<"
        )
      )
    )
    # PARAMs
    PARAM_DIR_BASE <- ""
    PARAM_DIR <- paste0(PARAM_DIR_BASE, ns)
    tuned_prm1 <- file.path(PARAM_DIR, "tuned_prm1.prm")
    
    res <- gurobi(model, params = read_tuned_params(tuned_prm1))
    
    status <- if (!is.null(res$status)) as.character(res$status) else "NULL"
    objval <- if (!is.null(res$objval)) res$objval else NA_real_
    runtime <- if (!is.null(res$runtime)) res$runtime else NA_real_
    
    if (!identical(status, "OPTIMAL")) {
      write.csv( 
        data.frame(
          iter = iter, ns = ns, status = status, objval = objval, runtime = runtime,
          stringsAsFactors = FALSE
        ),
        file.path(iter_dir, "summary.csv"),
        row.names = FALSE
      )
      cat(sprintf("NOT OPTIMAL ns=%d iter=%d status=%s\n", ns, iter, status))
      next
    }
    
    p_vals <- res$x[1:nc]
    r_vals <- res$x[(nc + 1):(2 * nc)]
    
    Gain_internal <- sum(p_vals * BV_vec)
    Gain_total <- Gain_internal + (C/2) * BV_ext_mean
    
    cat(sprintf(
      "ns=%d iter=%d status=OK obj=%.4f runtime=%.2f sum(p)=%.6f Gain_internal=%.6f BVext=%.6f Gain_total=%.6f\n",
      ns, iter, objval, runtime, sum(p_vals), Gain_internal, BV_ext_mean, Gain_total
    ))
    
    saveRDS(p_vals, file.path(iter_dir, sprintf("p_rep_%02d_ns_%02d.rds", iter, ns))) 
    saveRDS(r_vals, file.path(iter_dir, sprintf("r_rep_%02d_ns_%02d.rds", iter, ns))) 
    
    write.csv( 
      data.frame(
        iter = iter,
        ns = ns,
        status = status,
        objval = objval,
        runtime = runtime,
        n_selected = sum(r_vals > 0.5),
        sum_p = sum(p_vals),
        BV_ext_mean = BV_ext_mean,
        Gain_internal = Gain_internal,
        Gain_total = Gain_total,
        stringsAsFactors = FALSE
      ),
      file.path(iter_dir, "summary.csv"),
      row.names = FALSE
    )
    
    selected_idx <- which(r_vals > 0.5)
    if (length(selected_idx) > 0) {
      write.csv(
        data.frame(
          ID = ID_vec[selected_idx],
          iter = iter,
          ns = ns,
          bv = BV_vec[selected_idx],
          p = p_vals[selected_idx],
          r = r_vals[selected_idx],
          stringsAsFactors = FALSE
        ),
        file.path(iter_dir, "selected_individuals.csv"),
        row.names = FALSE
      )
      
      C_sub <- C_mat[selected_idx, selected_idx, drop = FALSE]
      write.csv(
        C_sub,
        file.path(iter_dir, sprintf("Csub_rep_%02d_ns_%02d.csv", iter, ns)),
        row.names = TRUE
      )
    }
  }
}

cat("Done.\n")