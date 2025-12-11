###############################################################################
# 2D Z-value Subgroup Visualization (R)
# Author: Sujin Kim
# Created: 2025-04-02
# Last Modified: 2025-12-10
# Description:
#   - Works for ANY bacterial strain (A. baumannii, S. aureus, PAO1 …)
#   - Loads multi-sheet HTS Excel data (IC50, MIC, 9xMIC)
#   - Unified plotting pipeline (all strains handled by one shared codebase))
#   - Performs Z-value thresholding into group1/group2
#   - Exports subgroup-specific transparent PNGs
# NOTE:
#   • This version uses placeholder file paths for GitHub.
#   • Replace PATH/TO/... with your actual local directory.
###############################################################################

library(readr)
library(readxl)
library(dplyr)
library(ggplot2)

###############################################################################
# 1. USER SETTINGS
###############################################################################

# --- (1) File paths ---
setwd("PATH/TO/YOUR/OUTPUT_FOLDER")
file_path <- "PATH/TO/YOUR/EXCEL_FILE.xlsx"

# --- (2) Select strain ---
strain <- "Ab"  
# options: "Ab", "SA", "PAO1", ... (you can add more below)


###############################################################################
# 2. Strain-specific configuration table
###############################################################################
strain_config <- list(
  
  
  Ab = list(
    z_lim = 95,
    subgroup_step = 10,
    x_lim = c(0, 140),
    y_lim = c(0, 140)
  ),
  
  SA = list(
    z_lim = 78,
    subgroup_step = 10,
    x_lim = c(0, 55),
    y_lim = c(0, 260)
  ),
  
  PAO1 = list(
    z_lim = 160,
    subgroup_step = 20,
    x_lim = c(0, 140),
    y_lim = c(0, 140)
  )
)

cfg_strain <- strain_config[[strain]]
cat("Loaded strain:", strain, "\n")
cat("Z-limit:", cfg_strain$z_lim, "\n")
cat("Subgroup step:", cfg_strain$subgroup_step, "\n")


###############################################################################
# 3. Load multi-sheet HTS Excel dataset
###############################################################################
sheet_names <- excel_sheets(file_path)

data <- lapply(sheet_names, function(sheet) {
  read_excel(file_path, sheet = sheet, na = c("", "NA", "N/A", ">100")) %>%
    type_convert(col_types = cols(.default = "n")) %>%
    mutate(
      sheet_name = sheet,
      shape_group = case_when(
        grepl("_IC50", sheet) ~ "IC50",
        grepl("_MIC$",  sheet) ~ "MIC",
        grepl("_9xMIC", sheet) ~ "9xMIC",
        TRUE ~ NA_character_
      )
    ) %>%
    filter(!is.na(shape_group)) %>%
    select(`X value`, `Y_value`, `Z vale`, shape_group) %>%
    rename(`Z value` = `Z vale`) %>%
    filter(!is.na(`X value`) & !is.na(`Y_value`) & !is.na(`Z value`))
}) %>% bind_rows()


###############################################################################
# 4. Z subgroup configuration
###############################################################################
z_group_config <- function(z_lim, actual_max, step) {
  list(
    group1 = list(
      range   = seq(0, z_lim, by = step),
      palette = c("grey", "grey", "#9D3CFF", "#00A0FF", "#009300",
                  "#E6DC32", "#F08228", "red"),
      alpha   = c(0.2, 0.2, 0.3, 0.1, 0.2, 0.1, 0.4, 0.3)
    ),
    
    group2 = if (actual_max > z_lim) {
      list(
        range   = seq(z_lim, max(200, actual_max), by = step),
        palette = colorRampPalette(c("#FFB3AB", "#D5453F", "#800000", "#311010")),
        alpha   = 0.5
      )
    } else NULL
  )
}


###############################################################################
# 5. Main unified plotting function
###############################################################################
create_subgroup_plots <- function(data, group, cfg_strain) {
  
  # Load strain configs
  z_lim <- cfg_strain$z_lim
  step  <- cfg_strain$subgroup_step
  x_lim <- cfg_strain$x_lim
  y_lim <- cfg_strain$y_lim
  
  actual_max <- max(data$`Z value`[data$shape_group == group], na.rm = TRUE)
  cfg_z <- z_group_config(z_lim, actual_max, step)
  
  # Prepare plotting data
  plot_data <- data %>%
    filter(shape_group == group) %>%
    mutate(
      z_group = ifelse(`Z value` <= z_lim, "group1", "group2"),
      
      z_subgroup = ifelse(
        z_group == "group1",
        cut(`Z value`, breaks = cfg_z$group1$range, include.lowest = TRUE, right = FALSE),
        if (!is.null(cfg_z$group2))
          cut(`Z value`, breaks = cfg_z$group2$range, include.lowest = TRUE)
        else NA
      ),
      
      size_group = case_when(
        shape_group == "IC50"  ~ 5,
        shape_group == "MIC"   ~ 4,
        shape_group == "9xMIC" ~ 5
      )
    ) %>%
    filter(!is.na(z_subgroup)) %>%
    mutate(
      subgroup_num = ifelse(z_group == "group1", as.numeric(z_subgroup), NA),
      subgroup_color = case_when(
        z_group == "group1" & subgroup_num %in% c(1,2) ~ "black",
        z_group == "group1" & subgroup_num == 3 ~ "#9D3CFF",
        z_group == "group1" & subgroup_num == 4 ~ "#00A0FF",
        z_group == "group1" & subgroup_num == 5 ~ "#009300",
        z_group == "group1" & subgroup_num == 6 ~ "#E6DC32",
        z_group == "group1" & subgroup_num == 7 ~ "#F08228",
        z_group == "group1" & subgroup_num == 8 ~ "red",
        TRUE ~ "gray"
      )
    )
  
  # Iterate both group1 and group2
  for (g in c("group1", "group2")) {
    
    if (is.null(cfg_z[[g]])) next
    subset_data <- plot_data %>% filter(z_group == g)
    if (nrow(subset_data) == 0) next
    
    unique_subgroups <- unique(subset_data$z_subgroup)
    
    for (sub in unique_subgroups) {
      
      sub_data <- subset_data %>%
        filter(z_subgroup == sub)
      
      if (nrow(sub_data) == 0) next
      
      p <- ggplot(sub_data, aes(`X value`, `Y_value`)) +
        geom_point(
          aes(
            shape = shape_group,
            size  = size_group,
            fill  = if (g == "group1") subgroup_color else `Z value`
          ),
          color = "dimgrey",
          alpha = if (g == "group1")
            cfg_z$group1$alpha[min(length(cfg_z$group1$alpha),
                                   which(unique_subgroups == sub))]
          else cfg_z$group2$alpha
        ) +
        
        {
          if (g == "group1") scale_fill_identity()
          else scale_fill_gradientn(colors = cfg_z$group2$palette(10),
                                    limits = range(cfg_z$group2$range),
                                    guide = "none")
        } +
        
        scale_shape_manual(values = c("IC50"=21, "MIC"=24, "9xMIC"=22)) +
        scale_size_identity() +
        coord_fixed(xlim = x_lim, ylim = y_lim) +
        theme_test() +
        theme(
          aspect.ratio = 1,
          panel.background = element_rect(fill = "transparent"),
          plot.background  = element_rect(fill = "transparent", color = NA)
        )
      
      # Save
      outname <- paste0(strain, "_", group, "_", g, "_", as.character(sub), ".png")
      ggsave(outname, p, width = 6, height = 6, bg = "transparent")
      cat("Saved:", outname, "\n")
    }
  }
}


###############################################################################
# 6. Run pipeline for all 3 sheet(concentration) groups
###############################################################################
for (group in c("IC50", "MIC", "9xMIC")) {
  tryCatch({
    create_subgroup_plots(data, group, cfg_strain)
  }, error = function(e) {
    message("Error in ", group, ": ", e$message)
  })
}
