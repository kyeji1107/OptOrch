library(shiny)
library(data.table)
library(Matrix)
library(ggplot2)

# -----------------------------------------------------------------------------
# OptOrch local-run Shiny app
# -----------------------------------------------------------------------------
# This app runs the two R-Gurobi optimization scenarios locally.
# Important:
#   - "Run optimization" displays newly generated results in the Shiny interface.
#   - It does not write, overwrite, or modify existing manuscript reproduction outputs.
#   - "Load existing outputs" reads previously generated outputs from the repository.
#
# Expected location:
#   OptOrch/
#   ├── 03_manuscript_reproduction/
#   └── 04_shiny_app/app.R
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

tuned_params_by_ns <- function(output_flag = 1) {
  list(
    "10" = list(
      MIPGap = 0.005,
      OutputFlag = output_flag,
      NonConvex = 2,
      Aggregate = 0,
      NormAdjust = 0,
      NumericFocus = 3,
      PreMIQCPForm = 1,
      ScaleFlag = 2
    ),
    "20" = list(
      MIPGap = 0.005,
      OutputFlag = output_flag,
      NonConvex = 2,
      Heuristics = 0.5,
      MIQCPMethod = 0,
      PrePasses = 1,
      Presolve = 1,
      ScaleFlag = 0
    ),
    "30" = list(
      MIPGap = 0.005,
      OutputFlag = output_flag,
      NonConvex = 2,
      Aggregate = 0,
      CutPasses = 10,
      Cuts = 1,
      PreMIQCPForm = 1,
      Presolve = 1,
      ScaleFlag = 0,
      ZeroHalfCuts = 0
    ),
    "40" = list(
      MIPGap = 0.005,
      OutputFlag = output_flag,
      NonConvex = 2,
      Heuristics = 0.001,
      NoRelHeurTime = 900,
      ScaleFlag = 2
    )
  )
}

read_scenario_inputs <- function(data_dir, iter, nc = 500) {
  c_path <- list.files(
    data_dir,
    pattern = paste0("^rep", iter, "_Gmatrix_tuned_all\\.csv$"),
    full.names = TRUE
  )[1]
  
  b_path <- list.files(
    data_dir,
    pattern = paste0("^rep", iter, "_GBLUP_results\\.csv$"),
    full.names = TRUE
  )[1]
  
  if (is.na(c_path) || !file.exists(c_path)) {
    stop(sprintf("Coancestry matrix file was not found for dataset number %s.", iter), call. = FALSE)
  }
  
  if (is.na(b_path) || !file.exists(b_path)) {
    stop(sprintf("Breeding value file was not found for dataset number %s.", iter), call. = FALSE)
  }
  
  dfC <- read.csv(
    c_path,
    header = FALSE,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  
  C_block <- dfC[102:601, 102:601, drop = FALSE]
  C_full <- apply(C_block, 2, function(x) suppressWarnings(as.numeric(x)))
  C_mat <- as.matrix(C_full) * 0.5
  
  eig <- eigen(C_mat, symmetric = TRUE)
  eig$values[eig$values < 1e-6] <- 1e-6
  C_mat <- eig$vectors %*% diag(eig$values) %*% t(eig$vectors)
  
  dfB <- read.csv(
    b_path,
    header = TRUE,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  
  raw_id <- as.character(dfB[[1]][101:600])
  ID_vec <- sub("^.*([0-9]{6})$", "\\1", raw_id)
  BV_vec <- suppressWarnings(as.numeric(dfB[[2]][101:600]))
  
  if (length(BV_vec) != nc || anyNA(BV_vec)) {
    stop("Breeding values could not be read correctly from rows 101:600.", call. = FALSE)
  }
  
  list(
    C_mat = C_mat,
    ID_vec = ID_vec,
    BV_vec = BV_vec,
    c_path = c_path,
    b_path = b_path
  )
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
    iter,
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
      iter = iter,
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
      iter = iter,
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
        iter = iter,
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
    iter,
    lower_bound = 0.01,
    upper_bound = 0.15,
    contamination_rate = 0.3,
    external_pollen_parents = 100,
    output_flag = 1
) {
  check_required_packages()
  validate_repo_root(repo_root)
  
  if (lower_bound > upper_bound) {
    stop("The lower contribution bound must not be greater than the upper contribution bound.", call. = FALSE)
  }
  
  nc <- 500
  data_dir <- file.path(
    repo_root,
    "03_manuscript_reproduction",
    "001_simulated_data",
    "MoBPS_generated_data",
    "Heri_0.2"
  )
  
  if (!dir.exists(data_dir)) {
    data_dir_alt <- file.path(
      repo_root,
      "03_manuscript_reproduction",
      "001_simulated_data",
      "mobps_generated_data",
      "Heri_0.2"
    )
    
    if (dir.exists(data_dir_alt)) {
      data_dir <- data_dir_alt
    }
  }
  
  if (!dir.exists(data_dir)) {
    stop(
      paste0(
        "Simulation data directory was not found. Expected location: ",
        file.path(
          repo_root,
          "03_manuscript_reproduction",
          "001_simulated_data",
          "mobps_generated_data",
          "Heri_0.2"
        )
      ),
      call. = FALSE
    )
  }
  
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
    
    ext_path <- file.path(data_dir, sprintf("rep%d_Np2_Data.csv", iter))
    if (!file.exists(ext_path)) {
      stop(sprintf("External pollen data file was not found: %s", ext_path), call. = FALSE)
    }
    
    dfExt <- data.table::fread(ext_path)
    if (!("BV" %in% names(dfExt))) {
      stop(sprintf("Column 'BV' was not found in external pollen data: %s", ext_path), call. = FALSE)
    }
    
    BV_ext_mean <- mean(as.numeric(dfExt$BV), na.rm = TRUE)
    extra_summary <- list(BV_ext_mean = BV_ext_mean)
  }
  
  inputs <- read_scenario_inputs(data_dir = data_dir, iter = iter, nc = nc)
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
  
  params <- tuned_params_by_ns(output_flag = output_flag)[[as.character(ns)]]
  if (is.null(params)) {
    stop(sprintf("No tuned Gurobi parameters were defined for Ns = %d.", ns), call. = FALSE)
  }
  
  log_file <- tempfile(pattern = "optorch_gurobi_", fileext = ".log")
  params$LogFile <- log_file
  
  res <- gurobi::gurobi(model, params = params)
  
  status <- if (!is.null(res$status)) as.character(res$status) else "NULL"
  objval <- if (!is.null(res$objval)) res$objval else NA_real_
  runtime <- if (!is.null(res$runtime)) res$runtime else NA_real_
  
  if (!identical(status, "OPTIMAL")) {
    tables <- make_result_tables(
      iter = iter,
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
      output_note = "Finished. Results are displayed in the Shiny interface only. Existing manuscript reproduction outputs were not modified."
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
    iter = iter,
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
    output_note = "Finished. Results are displayed in the Shiny interface only. Existing manuscript reproduction outputs were not modified."
  )
}

read_existing_outputs <- function(repo_root, scenario, ns, iter) {
  validate_repo_root(repo_root)
  
  if (scenario == "Scenario 1: Status number") {
    scenario_dir <- file.path(
      repo_root,
      "03_manuscript_reproduction",
      "002_scenario1_status_number"
    )
  } else {
    scenario_dir <- file.path(
      repo_root,
      "03_manuscript_reproduction",
      "003_scenario2_pollen_contamination"
    )
  }
  
  iter_dir <- file.path(
    scenario_dir,
    "outputs",
    sprintf("ns_%02d", ns),
    paste0("rep_", iter)
  )
  
  summary_path <- file.path(iter_dir, "summary.csv")
  selected_path <- file.path(iter_dir, "selected_individuals.csv")
  log_file <- file.path(iter_dir, "gurobi.log")
  
  if (!file.exists(summary_path)) {
    stop(sprintf("summary.csv was not found: %s", summary_path), call. = FALSE)
  }
  
  list(
    summary = data.table::fread(summary_path),
    selected = if (file.exists(selected_path)) data.table::fread(selected_path) else data.frame(),
    iter_dir = iter_dir,
    log_file = log_file,
    output_note = paste0("Loaded existing outputs from:\n", iter_dir)
  )
}

ui <- fluidPage(
  titlePanel("OptOrch Local-Run Shiny App"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput(
        inputId = "scenario",
        label = "Scenario",
        choices = c(
          "Scenario 1: Status number",
          "Scenario 2: Pollen contamination"
        )
      ),
      selectInput(
        inputId = "ns",
        label = "Status number (Ns)",
        choices = c(10, 20, 30, 40),
        selected = 10
      ),
      numericInput(
        inputId = "iter",
        label = "Dataset number",
        value = 1,
        min = 1,
        max = 30,
        step = 1
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
        label = "Print Gurobi log in R console",
        value = TRUE
      ),
      actionButton(
        inputId = "run_optimization",
        label = "Run optimization"
      ),
      actionButton(
        inputId = "load_outputs",
        label = "Load existing outputs"
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
      "Choose a scenario and click 'Run optimization' or 'Load existing outputs'.\n",
      "Run optimization displays new results without modifying existing manuscript reproduction outputs."
    )
  )
  
  observeEvent(input$run_optimization, {
    tryCatch({
      repo_root <- find_repo_root()
      validate_repo_root(repo_root)
      
      status_text(
        paste0(
          "Optimization is running. Check the R console for Gurobi progress if logging is enabled.\n",
          "This run will not overwrite existing manuscript reproduction outputs."
        )
      )
      
      withProgress(message = "Running OptOrch optimization", value = 0.2, {
        res <- run_optorch_scenario(
          scenario = input$scenario,
          repo_root = repo_root,
          ns = as.integer(input$ns),
          iter = as.integer(input$iter),
          lower_bound = input$lower_bound,
          upper_bound = input$upper_bound,
          contamination_rate = input$contamination_rate,
          external_pollen_parents = input$external_pollen_parents,
          output_flag = if (isTRUE(input$show_gurobi_log)) 1 else 0
        )
        incProgress(0.8)
      })
      
      result(res)
      status_text(res$output_note)
    }, error = function(e) {
      status_text(paste0("Error:\n", conditionMessage(e)))
    })
  })
  
  observeEvent(input$load_outputs, {
    tryCatch({
      repo_root <- find_repo_root()
      validate_repo_root(repo_root)
      
      res <- read_existing_outputs(
        repo_root = repo_root,
        scenario = input$scenario,
        ns = as.integer(input$ns),
        iter = as.integer(input$iter)
      )
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
        title = paste(input$scenario, "| Ns =", input$ns, "| Dataset number =", input$iter)
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
        "_rep_",
        input$iter,
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
