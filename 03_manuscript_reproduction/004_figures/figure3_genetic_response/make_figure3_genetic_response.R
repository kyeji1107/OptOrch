# Required packages
library(tidyverse)

# ---------- Modern academic palette ----------
pal <- list(
  Ink       = "#1F2937",
  Slate     = "#6B7280",
  Panel     = "#FFFFFF",
  PanelLine = "#D6DAE1",
  Navy      = "#0F2A4A",
  Mint      = "#3A86B8",
  PinkBox   = "#E9D8A6"
)

#---------------------------------------------------------------
# 0) Path ------------------------------------------------------

# Set the working directory to:
# 03_manuscript_reproduction/004_figures/figure3_genetic_response/

SCRIPT_DIR <- getwd()

SCENARIO1_OUT_DIR <- file.path(
  SCRIPT_DIR,
  "..", "..",
  "002_scenario1_status_number",
  "outputs"
)

SCENARIO2_OUT_DIR <- file.path(
  SCRIPT_DIR,
  "..", "..",
  "003_scenario2_pollen_contamination",
  "outputs"
)

OUT_DIR <- file.path(SCRIPT_DIR, "outputs")

dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

# ---------- Settings ----------
status_numbers <- c(10, 20, 30, 40)
reps <- 1:30

base_no_contam <- SCENARIO1_OUT_DIR
base_contam    <- SCENARIO2_OUT_DIR

output_dir <- OUT_DIR
output_pdf <- file.path(output_dir, "figure3_genetic_response.pdf")
output_csv <- file.path(output_dir, "figure3_data.csv")

# ---------- Utility functions ----------
make_path <- function(base_dir, ns, rep) {
  file.path(base_dir, paste0("ns_", ns), paste0("rep_", rep), "summary.csv")
}

read_first_value <- function(path, colname) {
  if (!file.exists(path)) return(NA_real_)
  df <- tryCatch(readr::read_csv(path, show_col_types = FALSE), error = function(e) NULL)
  if (is.null(df)) return(NA_real_)
  if (!(colname %in% names(df))) return(NA_real_)
  val <- suppressWarnings(as.numeric(df[[colname]][1]))
  if (length(val) == 0) return(NA_real_)
  val
}

# ---------- Collect data ----------
df_no_contam <- tidyr::crossing(status_number = status_numbers, rep = reps) %>%
  mutate(
    case = "no_contamination",
    path = purrr::pmap_chr(list(status_number, rep), ~ make_path(base_no_contam, ..1, ..2)),
    genetic_response = purrr::map_dbl(path, ~ read_first_value(.x, "objval"))
  )

df_contam <- tidyr::crossing(status_number = status_numbers, rep = reps) %>%
  mutate(
    case = "contamination",
    path = purrr::pmap_chr(list(status_number, rep), ~ make_path(base_contam, ..1, ..2)),
    genetic_response = purrr::map_dbl(path, ~ read_first_value(.x, "Gain_total"))
  )

df_all <- bind_rows(df_no_contam, df_contam) %>%
  mutate(
    status_number = factor(status_number, levels = status_numbers),
    case = factor(case, levels = c("no_contamination", "contamination"))
  )

# ---------- Save data ----------
readr::write_csv(df_all, output_csv)

# ---------- Calculate means ----------
df_mean <- df_all %>%
  group_by(status_number, case) %>%
  summarise(
    mean_val = mean(genetic_response, na.rm = TRUE),
    .groups = "drop"
  )

# ---------- Plot settings ----------
case_fills <- c(
  "no_contamination" = pal$Mint,
  "contamination"    = pal$PinkBox
)

case_labels <- c(
  "no_contamination" = "No Contamination",
  "contamination"    = "With Contamination"
)

# ---------- Boxplot ----------
p <- ggplot(df_all, aes(x = status_number, y = genetic_response, fill = case)) +
  geom_boxplot(
    width = 0.62,
    linewidth = 1.05,
    color = pal$Ink,
    staplewidth = 0.45,
    fatten = 0.6,
    outlier.shape = 16,
    outlier.size = 2.2,
    outlier.colour = pal$Ink
  ) +
  # Small circles indicate mean values
  geom_point(
    data = df_mean,
    aes(x = status_number, y = mean_val, group = case),
    shape = 21,
    size = 1.8,
    stroke = 0.7,
    color = pal$Navy,
    fill = "white",
    position = position_dodge(width = 0.62),
    inherit.aes = FALSE
  ) +
  scale_fill_manual(values = case_fills, labels = case_labels) +
  scale_y_continuous(
    limits = c(NA, 2.0),
    breaks = seq(1.0, 2.0, by = 0.25)
  ) +
  scale_x_discrete(
    labels = c(
      "10" = "10*",
      "20" = "20*",
      "30" = "30*",
      "40" = "40*"
    )
  ) +
  labs(
    x = "Status Number",
    y = "Expected Genetic Response",
    fill = NULL
  ) +
  theme_minimal(base_family = "sans", base_size = 14) +
  theme(
    panel.background = element_rect(fill = pal$Panel, color = NA),
    plot.background  = element_rect(fill = "white", color = NA),
    panel.grid.major = element_line(color = pal$PanelLine, linewidth = 0.35),
    panel.grid.minor = element_blank(),
    axis.title = element_text(color = pal$Ink, size = 14),
    axis.text  = element_text(color = pal$Ink, size = 13),
    legend.text = element_text(size = 13),
    plot.margin = margin(10, 18, 10, 12),
    panel.border = element_rect(color = pal$Ink, linewidth = 0.9, fill = NA),
    axis.line = element_blank(),
    legend.position = c(0.98, 0.98),
    legend.justification = c(1, 1),
    legend.background = element_rect(fill = "white", color = pal$PanelLine, linewidth = 0.45),
    legend.key = element_rect(fill = "white", color = NA),
    legend.title = element_blank()
  )

# ---------- Save PDF ----------
pdf_device <- if (capabilities("cairo")) cairo_pdf else "pdf"

ggsave(
  filename = output_pdf,
  plot = p,
  device = pdf_device,
  width = 7.6,
  height = 5.4
)