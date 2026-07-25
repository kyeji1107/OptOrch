library(data.table)
library(ggplot2)
library(patchwork)

#---------------------------------------------------------------
# 0) Path ------------------------------------------------------

# Set the working directory to:
# 03_manuscript_reproduction/004_figures/figure2_contributions/

SCRIPT_DIR <- getwd()

DATA_DIR <- file.path(SCRIPT_DIR, "..", "..", "001_simulated_data", "MoBPS_generated_data", "Heri_0.2")
SCENARIO1_OUT_DIR <- file.path(SCRIPT_DIR, "..", "..", "002_scenario1_status_number", "outputs")
OUT_DIR <- file.path(SCRIPT_DIR, "outputs")

dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

#---------------------------------------------------------------
# 1) Input and output files ------------------------------------

gblup_file <- file.path(DATA_DIR, "rep1_GBLUP_results.csv")

cases <- list(
  ns10 = list(
    ns_value = 10,
    selected_file = file.path(SCENARIO1_OUT_DIR, "ns_10", "rep_1", "selected_individuals.csv"),
    out_csv = file.path(OUT_DIR, "figure2_data_ns10.csv")
  ),
  ns40 = list(
    ns_value = 40,
    selected_file = file.path(SCENARIO1_OUT_DIR, "ns_40", "rep_1", "selected_individuals.csv"),
    out_csv = file.path(OUT_DIR, "figure2_data_ns40.csv")
  )
)

out_pdf_combined <- file.path(OUT_DIR, "figure2_contributions.pdf")

#---------------------------------------------------------------
# 2) Create matched data ---------------------------------------

make_matched_csv <- function(gblup_file, selected_file, out_csv) {
  
  if (!file.exists(gblup_file)) {
    stop(sprintf("GBLUP file not found: %s", gblup_file))
  }
  
  if (!file.exists(selected_file)) {
    stop(sprintf("Selected individuals file not found: %s", selected_file))
  }
  
  dt1 <- fread(gblup_file)
  setnames(dt1, old = names(dt1)[1], new = "ID")
  
  # Excel rows 102-601 correspond to R rows 101-600 after reading the header.
  # These rows represent the No candidate population.
  dt1 <- dt1[101:600, .(ID, solution)]
  
  # Extract the six-digit individual ID from the first column.
  dt1[, ID := sub(".*([0-9]{6})$", "\\1", as.character(ID))]
  
  dt2 <- fread(selected_file)
  dt2 <- dt2[, .(ID, p, r)]
  dt2[, ID := as.character(ID)]
  
  dt_out <- merge(dt1, dt2, by = "ID", all.x = TRUE)
  dt_out[is.na(p), p := 0]
  dt_out[is.na(r), r := 0]
  
  fwrite(dt_out, out_csv)
  
  invisible(dt_out)
}

#---------------------------------------------------------------
# 3) Plot function ---------------------------------------------

plot_pr_obj <- function(file, ns_value) {
  
  dt <- fread(file)
  
  ggplot(dt, aes(x = solution, y = p)) +
    annotate(
      "rect",
      xmin = -Inf,
      xmax = Inf,
      ymin = 0.01,
      ymax = 0.15,
      fill = "grey70",
      alpha = 0.20
    ) +
    geom_point(
      size = 1.2,
      color = "black",
      alpha = 0.8
    ) +
    annotate(
      "text",
      x = -Inf,
      y = Inf,
      label = paste0("italic(n)[s] == ", ns_value),
      parse = TRUE,
      hjust = -0.1,
      vjust = 1.2,
      size = 4.5,
      family = "sans"
    ) +
    scale_y_continuous(
      limits = c(0, 0.2),
      breaks = c(0, 0.01, 0.05, 0.1, 0.15, 0.2),
      labels = function(x) ifelse(x == 0, "0", x),
      expand = expansion(mult = c(0, 0))
    ) +
    scale_x_continuous(
      breaks = function(x) sort(unique(c(pretty(x), 0.5))),
      labels = function(x) ifelse(x == 0, "0", x),
      expand = expansion(mult = c(0.02, 0.02))
    ) +
    labs(
      x = "Breeding Value",
      y = "Optimal Contribution"
    ) +
    coord_cartesian(clip = "off") +
    theme_minimal(base_family = "sans", base_size = 13) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.border = element_rect(
        color = "black",
        fill = NA,
        linewidth = 0.4
      )
    )
}

#---------------------------------------------------------------
# 4) Generate Figure 2 data ------------------------------------

make_matched_csv(
  gblup_file = gblup_file,
  selected_file = cases$ns10$selected_file,
  out_csv = cases$ns10$out_csv
)

make_matched_csv(
  gblup_file = gblup_file,
  selected_file = cases$ns40$selected_file,
  out_csv = cases$ns40$out_csv
)

#---------------------------------------------------------------
# 5) Generate Figure 2 -----------------------------------------

p_a <- plot_pr_obj(cases$ns10$out_csv, cases$ns10$ns_value)
p_b <- plot_pr_obj(cases$ns40$out_csv, cases$ns40$ns_value)

p_combined <- (p_a / p_b) +
  plot_annotation(tag_levels = "a") &
  theme(
    plot.tag = element_text(family = "sans", size = 14),
    plot.tag.position = c(0.02, 0.98)
  )

#---------------------------------------------------------------
# 6) Save figure -----------------------------------------------

ggsave(
  filename = out_pdf_combined,
  plot = p_combined,
  width = 7,
  height = 8
)

cat("Done. Figure 2 data and PDF were saved in the figures folder.\n")
