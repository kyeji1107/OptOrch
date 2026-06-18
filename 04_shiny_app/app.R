library(shiny)
library(data.table)
library(Matrix)
library(ggplot2)

# -----------------------------------------------------------------------------
# OptOrch local-run Shiny app
# -----------------------------------------------------------------------------
# This app runs the two R-Gurobi optimization scenarios locally.
# Important:
#   - "Run optimization" uses BV.csv and coMatrix.csv in 04_shiny_app/Input_data.
#   - It displays newly generated results in the Shiny interface.
#   - It does not write, overwrite, or modify existing manuscript reproduction outputs.
#
# Expected input data location:
#   OptOrch/04_shiny_app/Input_data/BV.csv
#   OptOrch/04_shiny_app/Input_data/coMatrix.csv
#
# Launch from the repository root with:
#   shiny::runApp("04_shiny_app")
# -----------------------------------------------------------------------------

find_repo_root <- function() {
  wd <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  
  if (basename(wd) == "04_shiny_app") {
    return(normalizePath(file.path(wd, ".."), winslash = "/", mustWork = TRUE))
  }
  
  if (dir.exists(file.path(wd, "03_manuscript_reproduction"))) {
    return(wd)
  }
  
  parent <- normalizePath(file.path(wd, ".."), winslash = "/", mustWork = TRUE)
  if (dir.exists(file.path(parent, "03_manuscript_reproduction"))) {
    return(parent)
  }
  
  wd
}

validate_repo_root <- function(repo_root) {
  if (!dir.exists(file.path(repo_root, "03_manuscript_reproduction"))) {
    stop(
      paste0(
        "The repository root could not be detected. ",
        "Please launch the app from the OptOrch repository root using: ",
        "shiny::runApp('04_shiny_app')"
      ),
      call. = FALSE
    )
  }
  
  invisible(TRUE)
}

check_required_packages <- function() {
  required <- c("shiny", "data.table", "Matrix", "ggplot2", "gurobi")
  missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
  
  if (length(missing) > 0) {
    stop(
      paste0(
        "The following required package(s) are missing: ",
        paste(missing, collapse = ", "),
        ". Please install them before running the optimization."
      ),
      call. = FALSE
    )
  }
  
  invisible(TRUE)
}

get_input_data_dir <- function(repo_root) {
  file.path(repo_root, "04_shiny_app", "Input_data")
}

check_input_data_files <- function(repo_root) {
  input_dir <- get_input_data_dir(repo_root)
  bv_path <- file.path(input_dir, "BV.csv")
  comatrix_path <- file.path(input_dir, "coMatrix.csv")
  
  list(
    input_dir = input_dir,
    input_dir_exists = dir.exists(input_dir),
    bv_path = bv_path,
    bv_exists = file.exists(bv_path),
    comatrix_path = comatrix_path,
    comatrix_exists = file.exists(comatrix_path),
    ready = dir.exists(input_dir) && file.exists(bv_path) && file.exists(comatrix_path)
  )
}

format_input_data_status <- function(info) {
  paste0(
    "Input data folder: ", ifelse(info$input_dir_exists, "FOUND", "MISSING"), "\n",
    "BV.csv: ", ifelse(info$bv_exists, "FOUND", "MISSING"), "\n",
    "coMatrix.csv: ", ifelse(info$comatrix_exists, "FOUND", "MISSING"), "\n",
    "Ready to run: ", ifelse(info$ready, "YES", "NO")
  )
}

read_bv_file <- function(bv_path) {
  df <- data.table::fread(
    bv_path,
    header = TRUE,
    data.table = FALSE,
    check.names = FALSE
  )
  
  if (nrow(df) == 0 || ncol(df) < 2) {
    stop("BV.csv must contain at least two columns: ID and BV.", call. = FALSE)
  }
  
  id_col <- if ("ID" %in% names(df)) "ID" else names(df)[1]
  bv_col <- if ("BV" %in% names(df)) "BV" else names(df)[2]
  
  ID_vec <- as.character(df[[id_col]])
  BV_vec <- suppressWarnings(as.numeric(df[[bv_col]]))
  
  if (length(ID_vec) == 0 || anyNA(ID_vec) || any(!nzchar(ID_vec))) {
    stop("Individual IDs could not be read correctly from BV.csv.", call. = FALSE)
  }
  
  if (anyDuplicated(ID_vec)) {
    stop("BV.csv contains duplicated individual IDs.", call. = FALSE)
  }
  
  if (anyNA(BV_vec)) {
    stop("Breeding values could not be read correctly from BV.csv.", call. = FALSE)
  }
  
  list(ID_vec = ID_vec, BV_vec = BV_vec)
}

read_comatrix_file <- function(comatrix_path, ID_vec) {
  nc <- length(ID_vec)
  
  df <- data.table::fread(
    comatrix_path,
    header = TRUE,
    data.table = FALSE,
    check.names = FALSE
  )
  
  if (nrow(df) == nc && ncol(df) == nc + 1) {
    row_ids <- as.character(df[[1]])
    col_ids <- as.character(names(df)[-1])
    C_df <- df[, -1, drop = FALSE]
  } else if (nrow(df) == nc && ncol(df) == nc) {
    row_ids <- NULL
    col_ids <- as.character(names(df))
    C_df <- df
  } else {
    df_no_header <- data.table::fread(
      comatrix_path,
      header = FALSE,
      data.table = FALSE,
      check.names = FALSE
    )
    
    if (nrow(df_no_header) == nc && ncol(df_no_header) == nc) {
      row_ids <- NULL
      col_ids <- NULL
      C_df <- df_no_header
    } else {
      stop(
        paste0(
          "coMatrix.csv dimensions do not match BV.csv. ",
          "Expected a ", nc, " x ", nc, " matrix, or a ", nc, " x ", nc + 1, " matrix with one ID column."
        ),
        call. = FALSE
      )
    }
  }
  
  C_mat <- as.matrix(sapply(C_df, function(x) suppressWarnings(as.numeric(x))))
  
  if (!all(dim(C_mat) == c(nc, nc)) || anyNA(C_mat)) {
    stop("coMatrix.csv could not be converted to a numeric square matrix.", call. = FALSE)
  }
  
  if (!is.null(row_ids)) {
    if (!setequal(row_ids, ID_vec)) {
      stop("The row IDs in coMatrix.csv do not match the IDs in BV.csv.", call. = FALSE)
    }
    row_order <- match(ID_vec, row_ids)
    C_mat <- C_mat[row_order, , drop = FALSE]
  }
  
  if (!is.null(col_ids) && setequal(col_ids, ID_vec)) {
    col_order <- match(ID_vec, col_ids)
    C_mat <- C_mat[, col_order, drop = FALSE]
  }
  
  if (!isTRUE(all.equal(
    unname(C_mat),
    unname(t(C_mat)),
    tolerance = 1e-8,
    check.attributes = FALSE
  ))) {
    max_diff <- max(abs(C_mat - t(C_mat)), na.rm = TRUE)
    stop(
      paste0(
        "coMatrix.csv must be a symmetric coancestry matrix. ",
        "Maximum absolute difference between C[i,j] and C[j,i]: ",
        signif(max_diff, 6)
      ),
      call. = FALSE
    )
  }
  
  dimnames(C_mat) <- NULL
  eig <- eigen(C_mat, symmetric = TRUE)
  eig$values[eig$values < 1e-6] <- 1e-6
  C_mat <- eig$vectors %*% diag(eig$values) %*% t(eig$vectors)
  
  C_mat
}

read_input_data <- function(repo_root) {
  info <- check_input_data_files(repo_root)
  
  if (!info$ready) {
    stop(
      paste0(
        "Input data files were not found.\n",
        "Please place BV.csv and coMatrix.csv in:\n",
        info$input_dir
      ),
      call. = FALSE
    )
  }
  
  bv <- read_bv_file(info$bv_path)
  C_mat <- read_comatrix_file(
    comatrix_path = info$comatrix_path,
    ID_vec = bv$ID_vec
  )
  
  list(
    C_mat = C_mat,
    ID_vec = bv$ID_vec,
    BV_vec = bv$BV_vec,
    c_path = info$comatrix_path,
    b_path = info$bv_path
  )
}

get_gurobi_param_set <- function(param_set, output_flag = 1) {
  base_params <- list(
    OutputFlag = output_flag,
    NonConvex = 2
  )
  
  tuned_params <- switch(
    param_set,
    
    "default" = list(),
    
    "ns10" = list(
      Aggregate = 0,
      NormAdjust = 0,
      NumericFocus = 3,
      PreMIQCPForm = 1,
      ScaleFlag = 2
    ),
    
    "ns20" = list(
      Heuristics = 0.5,
      MIQCPMethod = 0,
      PrePasses = 1,
      Presolve = 1,
      ScaleFlag = 0
    ),
    
    "ns30" = list(
      Aggregate = 0,
      CutPasses = 10,
      Cuts = 1,
      PreMIQCPForm = 1,
      Presolve = 1,
      ScaleFlag = 0,
      ZeroHalfCuts = 0
    ),
    
    "ns40" = list(
      Heuristics = 0.001,
      NoRelHeurTime = 900,
      ScaleFlag = 2
    ),
    
    stop(sprintf("Unknown Gurobi parameter setting: %s", param_set), call. = FALSE)
  )
  
  base_params[names(tuned_params)] <- tuned_params
  base_params
}

get_time_limit_param <- function(time_limit) {
  if (is.null(time_limit) || identical(time_limit, "none")) {
    return(list())
  }
  
  time_limit_value <- suppressWarnings(as.numeric(time_limit))
  
  if (is.na(time_limit_value) || time_limit_value <= 0) {
    stop("TimeLimit must be a positive numeric value in seconds.", call. = FALSE)
  }
  
  list(TimeLimit = time_limit_value)
}

get_mip_gap_param <- function(mip_gap) {
  if (is.null(mip_gap) || !nzchar(trimws(mip_gap))) {
    return(list())
  }
  
  mip_gap_value <- suppressWarnings(as.numeric(mip_gap))
  
  if (is.na(mip_gap_value) || mip_gap_value < 0) {
    stop("MIPGap must be a non-negative numeric value, such as 0.005.", call. = FALSE)
  }
  
  list(MIPGap = mip_gap_value)
}

format_run_status <- function(status, objval = NA_real_, runtime = NA_real_) {
  if (identical(status, "OPTIMAL")) {
    return(paste0(
      "Run status: optimal solution found\n",
      "Gurobi status: ", status, "\n",
      "Objective value: ", objval, "\n",
      "Runtime: ", round(runtime, 2), " seconds"
    ))
  }
  
  if (status %in% c("INFEASIBLE", "INF_OR_UNBD")) {
    return(paste0(
      "Run status: not feasible\n",
      "Gurobi status: ", status, "\n",
      "No selected individuals are available for this run."
    ))
  }
  
  if (identical(status, "TIME_LIMIT")) {
    return(paste0(
      "Run status: time limit reached\n",
      "Gurobi status: ", status, "\n",
      "The optimization stopped because the selected TimeLimit was reached.\n",
      "Please check the Summary tab and Gurobi log to see whether a feasible solution was found before the time limit."
    ))
  }
  
  return(paste0(
    "Run status: finished, but no optimal solution was returned\n",
    "Gurobi status: ", status, "\n",
    "Please check the Summary tab and Gurobi log for details."
  ))
}

build_common_constraints <- function(nc, sum_p, lower_bound, upper_bound) {
  L <- rep(lower_bound, nc)
  U <- rep(upper_bound, nc)
  
  A_c2 <- Matrix(0, 1, 2 * nc, sparse = TRUE)
  A_c2[1, 1:nc] <- 1
  
  A_c3a <- cbind(Diagonal(nc, 1), Diagonal(nc, -L))
  A_c3b <- cbind(Diagonal(nc, 1), Diagonal(nc, -U))
  
  list(
    A = rbind(A_c2, A_c3a, A_c3b),
    rhs = c(sum_p, rep(0, nc), rep(0, nc)),
    sense = c("=", rep(">", nc), rep("<", nc)),
    lb = c(rep(0, nc), rep(0, nc)),
    ub = c(rep(upper_bound, nc), rep(1, nc))
  )
}

make_result_tables <- function(
    ns,
    status,
    objval,
    runtime,
    ID_vec,
    BV_vec,
    p_vals = NULL,
    r_vals = NULL,
    extra_summary = list()
) {
  if (is.null(p_vals) || is.null(r_vals)) {
    summary_df <- data.frame(
      ns = ns,
      status = status,
      objval = objval,
      runtime = runtime,
      n_selected = NA_integer_,
      stringsAsFactors = FALSE
    )
    selected_df <- data.frame()
  } else {
    selected_idx <- which(r_vals > 0.5)
    
    summary_df <- data.frame(
      ns = ns,
      status = status,
      objval = objval,
      runtime = runtime,
      n_selected = length(selected_idx),
      stringsAsFactors = FALSE
    )
    
    if (length(selected_idx) > 0) {
      selected_df <- data.frame(
        ID = ID_vec[selected_idx],
        ns = ns,
        bv = BV_vec[selected_idx],
        p = p_vals[selected_idx],
        r = r_vals[selected_idx],
        stringsAsFactors = FALSE
      )
    } else {
      selected_df <- data.frame()
    }
  }
  
  if (length(extra_summary) > 0) {
    for (nm in names(extra_summary)) {
      summary_df[[nm]] <- extra_summary[[nm]]
    }
  }
  
  list(
    summary = summary_df,
    selected = selected_df
  )
}

run_optorch_scenario <- function(
    scenario,
    repo_root,
    ns,
    lower_bound = 0.01,
    upper_bound = 0.15,
    contamination_rate = 0.3,
    external_pollen_parents = 100,
    output_flag = 1,
    gurobi_param_set = "default",
    time_limit = "none",
    mip_gap = ""
) {
  check_required_packages()
  validate_repo_root(repo_root)
  
  if (lower_bound > upper_bound) {
    stop("The lower contribution bound must not be greater than the upper contribution bound.", call. = FALSE)
  }
  
  inputs <- read_input_data(repo_root)
  nc <- length(inputs$BV_vec)
  
  if (scenario == "Scenario 1: Status number") {
    sum_p <- 1
    quad_rhs <- 1 / (2 * ns)
    extra_summary <- list()
  } else {
    sum_p <- 1 - contamination_rate / 2
    quad_rhs <- (1 / (2 * ns)) - (contamination_rate^2 / (8 * external_pollen_parents))
    
    if (quad_rhs <= 0) {
      stop(
        paste0(
          "The quadratic constraint RHS is not positive. ",
          "Please reduce the pollen contamination rate or increase the number of external pollen parents."
        ),
        call. = FALSE
      )
    }
    
    BV_ext_mean <- mean(inputs$BV_vec, na.rm = TRUE)
    extra_summary <- list(
      BV_ext_mean = BV_ext_mean,
      external_bv_source = "Mean BV of the input candidate set"
    )
  }
  
  cons <- build_common_constraints(
    nc = nc,
    sum_p = sum_p,
    lower_bound = lower_bound,
    upper_bound = upper_bound
  )
  
  Qc_full <- Matrix::Matrix(0, 2 * nc, 2 * nc, sparse = TRUE)
  Qc_full[1:nc, 1:nc] <- Matrix::Matrix(inputs$C_mat, sparse = TRUE)
  
  model <- list(
    modelsense = "max",
    obj = c(inputs$BV_vec, rep(0, nc)),
    vtype = c(rep("C", nc), rep("B", nc)),
    lb = cons$lb,
    ub = cons$ub,
    A = cons$A,
    rhs = cons$rhs,
    sense = cons$sense,
    quadcon = list(
      list(
        Qc = Qc_full,
        rhs = quad_rhs,
        sense = "<"
      )
    )
  )
  
  params <- get_gurobi_param_set(
    param_set = gurobi_param_set,
    output_flag = output_flag
  )
  
  time_limit_param <- get_time_limit_param(time_limit)
  if (length(time_limit_param) > 0) {
    params[names(time_limit_param)] <- time_limit_param
  }
  
  mip_gap_param <- get_mip_gap_param(mip_gap)
  if (length(mip_gap_param) > 0) {
    params[names(mip_gap_param)] <- mip_gap_param
  }
  
  log_file <- tempfile(pattern = "optorch_gurobi_", fileext = ".log")
  params$LogFile <- log_file
  
  res <- gurobi::gurobi(model, params = params)
  
  status <- if (!is.null(res$status)) as.character(res$status) else "NULL"
  objval <- if (!is.null(res$objval)) res$objval else NA_real_
  runtime <- if (!is.null(res$runtime)) res$runtime else NA_real_
  run_status_message <- format_run_status(
    status = status,
    objval = objval,
    runtime = runtime
  )
  
  if (!identical(status, "OPTIMAL")) {
    tables <- make_result_tables(
      ns = ns,
      status = status,
      objval = objval,
      runtime = runtime,
      ID_vec = inputs$ID_vec,
      BV_vec = inputs$BV_vec,
      extra_summary = extra_summary
    )
    
    return(list(
      summary = tables$summary,
      selected = tables$selected,
      iter_dir = NA_character_,
      log_file = log_file,
      output_note = run_status_message
    ))
  }
  
  p_vals <- res$x[1:nc]
  r_vals <- res$x[(nc + 1):(2 * nc)]
  
  if (scenario == "Scenario 2: Pollen contamination") {
    Gain_internal <- sum(p_vals * inputs$BV_vec)
    Gain_total <- Gain_internal + (contamination_rate / 2) * extra_summary$BV_ext_mean
    extra_summary$sum_p <- sum(p_vals)
    extra_summary$Gain_internal <- Gain_internal
    extra_summary$Gain_total <- Gain_total
  }
  
  tables <- make_result_tables(
    ns = ns,
    status = status,
    objval = objval,
    runtime = runtime,
    ID_vec = inputs$ID_vec,
    BV_vec = inputs$BV_vec,
    p_vals = p_vals,
    r_vals = r_vals,
    extra_summary = extra_summary
  )
  
  list(
    summary = tables$summary,
    selected = tables$selected,
    iter_dir = NA_character_,
    log_file = log_file,
    output_note = paste0(
      run_status_message,
      "\nResults are displayed in the Shiny interface only."
    )
  )
}

ui <- fluidPage(
  titlePanel("OptOrch Local-Run Shiny App"),
  
  sidebarLayout(
    sidebarPanel(
      h4("Input data check"),
      verbatimTextOutput("input_data_status"),
      actionButton(
        inputId = "refresh_input_data_status",
        label = "Refresh input data status"
      ),
      hr(),
      selectInput(
        inputId = "scenario",
        label = "Scenario",
        choices = c(
          "Scenario 1: Status number",
          "Scenario 2: Pollen contamination"
        )
      ),
      numericInput(
        inputId = "ns",
        label = "Status number (Ns)",
        value = 10,
        min = 1,
        max = 100,
        step = 1
      ),
      selectInput(
        inputId = "gurobi_param_set",
        label = "Gurobi parameter setting",
        choices = c(
          "Default" = "default",
          "Tuned for Ns = 10" = "ns10",
          "Tuned for Ns = 20" = "ns20",
          "Tuned for Ns = 30" = "ns30",
          "Tuned for Ns = 40" = "ns40"
        ),
        selected = "default"
      ),
      selectInput(
        inputId = "time_limit",
        label = "Time limit",
        choices = c(
          "None" = "none",
          "1 hour" = "3600",
          "3 hours" = "10800",
          "6 hours" = "21600",
          "12 hours" = "43200",
          "24 hours" = "86400"
        ),
        selected = "none"
      ),
      textInput(
        inputId = "mip_gap",
        label = "MIPGap (optional)",
        value = "",
        placeholder = "Leave blank to use Gurobi default (0.0001); e.g., 0.005"
      ),
      numericInput(
        inputId = "lower_bound",
        label = "Lower contribution bound",
        value = 0.01,
        min = 0,
        max = 1,
        step = 0.01
      ),
      numericInput(
        inputId = "upper_bound",
        label = "Upper contribution bound",
        value = 0.15,
        min = 0,
        max = 1,
        step = 0.01
      ),
      conditionalPanel(
        condition = "input.scenario == 'Scenario 2: Pollen contamination'",
        numericInput(
          inputId = "contamination_rate",
          label = "Pollen contamination rate",
          value = 0.3,
          min = 0,
          max = 1,
          step = 0.05
        ),
        numericInput(
          inputId = "external_pollen_parents",
          label = "Number of external pollen parents",
          value = 100,
          min = 1,
          max = 10000,
          step = 1
        )
      ),
      checkboxInput(
        inputId = "show_gurobi_log",
        label = "Print Gurobi log in R console while running",
        value = TRUE
      ),
      actionButton(
        inputId = "run_optimization",
        label = "Run optimization"
      ),
      br(),
      br(),
      downloadButton(
        outputId = "download_selected",
        label = "Download selected individuals"
      )
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Run status", verbatimTextOutput("run_status")),
        tabPanel("Summary", tableOutput("summary_table")),
        tabPanel("Selected individuals", tableOutput("selected_table")),
        tabPanel("Contribution plot", plotOutput("contribution_plot", height = "700px")),
        tabPanel("Gurobi log", verbatimTextOutput("gurobi_log"))
      )
    )
  )
)

server <- function(input, output, session) {
  result <- reactiveVal(NULL)
  status_text <- reactiveVal(
    paste0(
      "Choose a scenario and click 'Run optimization'.\n",
      "Run optimization uses BV.csv and coMatrix.csv in 04_shiny_app/Input_data."
    )
  )
  
  output$input_data_status <- renderText({
    input$refresh_input_data_status
    repo_root <- tryCatch(
      find_repo_root(),
      error = function(e) NA_character_
    )
    
    if (is.na(repo_root)) {
      return("Input data status: error\nRepository root could not be detected.")
    }
    
    format_input_data_status(check_input_data_files(repo_root))
  })
  
  observeEvent(input$run_optimization, {
    tryCatch({
      repo_root <- find_repo_root()
      validate_repo_root(repo_root)
      input_info <- check_input_data_files(repo_root)
      
      if (!isTRUE(input_info$ready)) {
        stop(
          paste0(
            "Input data files are not ready.\n",
            format_input_data_status(input_info)
          ),
          call. = FALSE
        )
      }
      
      mip_gap_label <- if (nzchar(trimws(input$mip_gap))) input$mip_gap else "Gurobi default (0.0001)"
      time_limit_label <- switch(
        input$time_limit,
        "none" = "None",
        "3600" = "1 hour",
        "10800" = "3 hours",
        "21600" = "6 hours",
        "43200" = "12 hours",
        "86400" = "24 hours",
        input$time_limit
      )
      
      status_text(
        paste0(
          "Optimization is running.\n",
          "Input BV file: ", basename(input_info$bv_path), "\n",
          "Input coMatrix file: ", basename(input_info$comatrix_path), "\n",
          "Gurobi parameter setting: ", input$gurobi_param_set, "\n",
          "Time limit: ", time_limit_label, "\n",
          "MIPGap: ", mip_gap_label, "\n",
          "If console logging is enabled, Gurobi progress is printed in the R console while running.\n",
          "The Gurobi log tab will be updated after the run finishes.\n",
          "This run will not overwrite or modify input files."
        )
      )
      
      withProgress(message = "Running OptOrch optimization", value = 0.2, {
        res <- run_optorch_scenario(
          scenario = input$scenario,
          repo_root = repo_root,
          ns = as.integer(input$ns),
          lower_bound = input$lower_bound,
          upper_bound = input$upper_bound,
          contamination_rate = input$contamination_rate,
          external_pollen_parents = input$external_pollen_parents,
          output_flag = if (isTRUE(input$show_gurobi_log)) 1 else 0,
          gurobi_param_set = input$gurobi_param_set,
          time_limit = input$time_limit,
          mip_gap = input$mip_gap
        )
        incProgress(0.8)
      })
      
      result(res)
      status_text(res$output_note)
    }, error = function(e) {
      status_text(paste0("Error:\n", conditionMessage(e)))
    })
  })
  
  output$run_status <- renderText({
    status_text()
  })
  
  output$summary_table <- renderTable({
    req(result())
    result()$summary
  })
  
  output$selected_table <- renderTable({
    req(result())
    selected <- result()$selected
    
    validate(
      need(nrow(selected) > 0, "No selected individuals are available for this run.")
    )
    
    selected
  })
  
  output$contribution_plot <- renderPlot({
    req(result())
    selected <- as.data.frame(result()$selected)
    
    validate(
      need(nrow(selected) > 0, "No selected individuals are available for this run."),
      need("p" %in% names(selected), "Column 'p' was not found."),
      need("ID" %in% names(selected), "Column 'ID' was not found.")
    )
    
    ggplot(selected, aes(x = reorder(ID, p), y = p)) +
      geom_col() +
      coord_flip() +
      labs(
        x = "Selected individual",
        y = "Optimized contribution",
        title = paste(input$scenario, "| Ns =", input$ns)
      ) +
      theme_bw()
  })
  
  output$gurobi_log <- renderText({
    req(result())
    log_file <- result()$log_file
    
    if (is.null(log_file) || !file.exists(log_file)) {
      return("No Gurobi log file was found for this run.")
    }
    
    paste(readLines(log_file, warn = FALSE), collapse = "\n")
  })
  
  output$download_selected <- downloadHandler(
    filename = function() {
      paste0(
        "selected_individuals_",
        gsub("[^A-Za-z0-9]+", "_", tolower(input$scenario)),
        "_ns_",
        input$ns,
        ".csv"
      )
    },
    content = function(file) {
      req(result())
      selected <- result()$selected
      data.table::fwrite(selected, file)
    }
  )
}

shinyApp(ui = ui, server = server)
