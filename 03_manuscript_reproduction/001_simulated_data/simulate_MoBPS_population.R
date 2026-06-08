rm(list = ls())

# Set the working directory to:
# 03_manuscript_reproduction/001_simulated_data/

SCRIPT_DIR <- getwd()

set.seed(1234)

# Load libraries
library(MoBPS)
library(RandomFieldsUtils)
library(miraculix)
library(ASRgenomics)
library(asreml)

# --- 1. Setup Input Parameters ---
snp <- 20300
add <- 300
heri_values <- 0.2
ch.nr <- 4
nf <- 5000
np <- 100
nr <- 900
no <- 500
n_reps <- 30 
ld_gen <- 100

export_path <- file.path(SCRIPT_DIR, "mobps_generated_data")
dir.create(export_path, showWarnings = FALSE, recursive = TRUE)

# --- 2. Main Simulation Loop ---
for (heri in heri_values) {
    
    heri_label <- paste0("Heri_", heri)
    heri_dir <- file.path(export_path, heri_label)
    if(!dir.exists(heri_dir)) dir.create(heri_dir)
    
    # Initialize storage for this heritability level
    data_Np1_list <- list()
    data_Np2_list <- list()
    data_off_list <- list()
    data_nr_list  <- list()
    g_all_list    <- list()
    g_Np2_list    <- list()
    gblup_list    <- list()
    
    # Create Founder Population
    population <- creating.diploid(nindi = nf,
                                   nsnp = snp,
                                   sex.quota = 1,
                                   dataset = "random",
                                   chr.nr = ch.nr,
                                   chromosome.length = 1,
                                   name.cohort = "Founders")
    
    # Define Markers and QTLs
    array_marker <- sort(sample(1:snp, (snp-add))) 
    array_mobps <- rep(FALSE, snp)
    array_mobps[array_marker] <- TRUE
    
    population <- creating.trait(population,
                                 exclude.snps = array_marker,
                                 n.additive = add,
                                 mean.target = 0,
                                 var.target = 1,
                                 trait.name = "Trait1")
    
    population <- add.array(population, marker.included = array_mobps)
    
    # Initial Genotyping and Phenotyping
    population <- breeding.diploid(population, genotyped.array = 2, genotyped.gen = 1)
    population <- breeding.diploid(population, phenotyping.gen = 1, heritability = heri)
    
    # --- 3. LD Build Up (Random Mating) ---
    for (idx in 1:ld_gen) {
        population <- breeding.diploid(population,
                                       breeding.size = nf,
                                       breeding.sex = 1,
                                       selection.size = c(0, nf),
                                       selection.f.cohorts = ifelse(idx == 1, "Founders", paste0("Nf_", idx-1)),
                                       selection.criteria = "random",
                                       name.cohort = paste0("Nf_", idx))
        
        population <- breeding.diploid(population, phenotyping.cohorts = paste0("Nf_", idx))
    }
    
    # --- 4. Breeding Process Iterations ---
    for (i in 1:n_reps) {
        
        # Select Parents (Np1) from the last LD cohort based on Phenotype
        population <- breeding.diploid(population,
                                       selection.size = c(0, np),
                                       selection.f.cohorts = paste0("Nf_", ld_gen),
                                       selection.criteria = "pheno",
                                       copy.individual = TRUE,
                                       name.cohort = paste0("Np1_", i))
        
        # Produce Offspring (No)
        population <- breeding.diploid(population,
                                       breeding.size = no,
                                       breeding.sex = 1,
                                       selection.f.cohorts = paste0("Np1_", i),
                                       name.cohort = paste0("No_", i))
        
        population <- breeding.diploid(population, phenotyping.cohorts = paste0("No_", i))
        
        # Random Pollen/Contaminants (Np2)
        population <- breeding.diploid(population,
                                       selection.size = c(0, np),
                                       selection.f.cohorts = paste0("Nf_", ld_gen),
                                       selection.criteria = "random",
                                       copy.individual = TRUE,
                                       name.cohort = paste0("Np2_", i))
        
        # Random Evaluation Group (Nr)
        population <- breeding.diploid(population,
                                       selection.size = c(0, nr),
                                       selection.f.cohorts = paste0("Nf_", ld_gen),
                                       selection.criteria = "random",
                                       copy.individual = TRUE,
                                       name.cohort = paste0("Nr_", i))
        
        # --- 5. Data Extraction ---
        # Helper to extract Pheno + BV
        get_df <- function(pop, coh) {
            df <- cbind.data.frame(t(get.pheno(pop, cohorts = coh)), t(get.bv(pop, cohorts = coh)))
            colnames(df) <- c("Pheno", "BV")
            return(df)
        }
        
        data_Np1_list[[i]] <- get_df(population, paste0("Np1_", i))
        data_Np2_list[[i]] <- get_df(population, paste0("Np2_", i))
        data_off_list[[i]] <- get_df(population, paste0("No_", i))
        data_nr_list[[i]]  <- get_df(population, paste0("Nr_", i))
        
        # --- 6. Genomic Matrix & GBLUP ---
        m_Np1 <- get.geno(population, cohorts = paste0("Np1_", i), array = 2)
        colnames(m_Np1) <- paste0("Np1_",colnames(m_Np1))
        
        m_Np2 <- get.geno(population, cohorts = paste0("Np2_", i), array = 2)
        colnames(m_Np2) <- paste0("Np2_",colnames(m_Np2))
        m_Np2   <- G.matrix(M = t(m_Np2), method = "VanRaden", na.string = NA)$G
        m_Np2 <- G.tuneup(G = m_Np2, bend = TRUE, eig.tol = 1e-03)$Gb
        g_Np2_list[[i]] <- m_Np2 
        
        
        m_No  <- get.geno(population, cohorts = paste0("No_", i), array = 2)
        colnames(m_No) <- paste0("No_",colnames(m_No))
        
        m_Nr  <- get.geno(population, cohorts = paste0("Nr_", i), array = 2)
        colnames(m_Nr) <- paste0("Nr_",colnames(m_Nr))
        
        
        m_all <- cbind(m_Np1, m_No, m_Nr)
        
        grm   <- G.matrix(M = t(m_all), method = "VanRaden", na.string = NA)$G
        gtune <- G.tuneup(G = grm, bend = TRUE, eig.tol = 1e-03)$Gb
        g_all_list[[i]] <- gtune # Store matrix
        
        ginv  <- G.inverse(G = gtune, sparseform = TRUE)$Ginv.sparse
        #head(attr(ginv, "rowNames"))
        #head(attr(ginv, "colNames"))
        
        # Prepare data for ASReml
        pheno_data <- as.data.frame(t(get.pheno(population, cohorts = c(paste0("Np1_", i), paste0("No_", i), paste0("Nr_", i)))))
        rownames(pheno_data) <- rownames(gtune)
        pheno_data$ID <- rownames(pheno_data)
        pheno_data$ID <- as.factor(pheno_data$ID)
        #head(pheno_data)
        
        # ASReml Fitting
        mm <- asreml(fixed = Trait1 ~ 1,
                     random = ~vm(ID, ginv),
                     residual = ~id(units),
                     na.action = na.method(y="include"),
                     maxit = 500,
                     workspace=5e08,
                     data = pheno_data)
                     
        gblup_list[[i]] <- as.data.frame(summary(mm, coef = TRUE)$coef.random)
        
        print(paste("Completed replicate:", i, "for heritability:", heri))
    }
    
    # --- 7. Save CSV Files ---
    for (rep in 1:n_reps) {
        write.csv(data_Np1_list[[rep]], file = file.path(heri_dir, paste0("rep", rep, "_Np1_Data.csv")))
        write.csv(data_Np2_list[[rep]], file = file.path(heri_dir, paste0("rep", rep, "_Np2_Data.csv")))
        write.csv(data_off_list[[rep]], file = file.path(heri_dir, paste0("rep", rep, "_Offspring_Data.csv")))
        write.csv(data_nr_list[[rep]],  file = file.path(heri_dir, paste0("rep", rep, "_Nr_Data.csv")))
        write.csv(gblup_list[[rep]],    file = file.path(heri_dir, paste0("rep", rep, "_GBLUP_results.csv")))
        
        # Saving the Genomic Matrix
        write.csv(g_all_list[[rep]],    file = file.path(heri_dir, paste0("rep", rep, "_Gmatrix_tuned_all.csv")))
        write.csv(g_Np2_list[[rep]],    file = file.path(heri_dir, paste0("rep", rep, "_Gmatrix_tuned_Np2.csv")))
        
    }
}

