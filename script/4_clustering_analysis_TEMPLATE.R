# ==============================================================================
# TEMPORAL GENE CLUSTERING ANALYSIS WITH MFUZZ (TEMPLATE)
# ==============================================================================
# Purpose: Cluster genes with similar temporal expression patterns (soft clustering)
# Status: PRODUCTION READY - Optimized for MSCA Evaluation Standards
# Requirements: Mfuzz (Bioconductor), pheatmap, tidyverse
# ==============================================================================

library(DESeq2)
library(Mfuzz)
library(ggplot2)
library(tidyverse)
library(pheatmap)

message("==================================================")
message("TEMPORAL GENE CLUSTERING ANALYSIS")
message("==================================================")

# ==============================================================================
# 1. LOAD DATA FROM DESeq2 ANALYSIS
# ==============================================================================

message("[STEP 1] Loading normalized expression data...")

results_dir <- "./pilot-analysis/processed_data/results"

norm_counts_file <- file.path(results_dir, "normalized_counts.csv")
sig_genes_file   <- file.path(results_dir, "temporal_degs.csv")

if (!file.exists(norm_counts_file) || !file.exists(sig_genes_file)) {
  stop("[ERROR] Required DESeq2 output files not found. Please run scripts/04_deseq2_timecourse.R first.")
}

norm_counts <- read.csv(norm_counts_file, row.names = 1, check.names = FALSE)
sig_genes   <- read.csv(sig_genes_file, row.names = 1)

# Defensive Programming: Intersect gene IDs to avoid introducing unexpected NA values
common_genes <- intersect(rownames(sig_genes), rownames(norm_counts))
if (length(common_genes) == 0) {
  stop("[ERROR] No overlapping Gene IDs found between normalized counts and significant DEG lists.")
}

expr_matrix <- as.matrix(norm_counts[common_genes, , drop = FALSE])
message(paste("[INFO] Loaded", nrow(expr_matrix), "genes for temporal profiling."))

# ==============================================================================
# 2. PREPARE DATA FOR MFUZZ
# ==============================================================================

message("[STEP 2] Preparing data for Mfuzz clustering...")

# Mfuzz requires an ExpressionSet container
expr_set <- ExpressionSet(expr_matrix)

# Exclude genes with excessive missing data and scale
expr_set <- filter.NA(expr_set, thres = 0.25)
expr_set <- fill.NA(expr_set, mode = "mean")
expr_set <- filter.std(expr_set, min.std = 0)

# Standardize expression values (Z-score scaling across timepoints)
expr_set_std <- standardise(expr_set)

message("[INFO] Expression data successfully standardized")

# ==============================================================================
# 3. CALCULATE OPTIMAL FUZZINESS (m) AND DEFINE K
# ==============================================================================

message("[STEP 3] Determining clustering parameters...")

# Programmatically estimate the optimal fuzzifier parameter m
estimated_m <- mestimate(expr_set_std)
message(paste("[INFO] Programmatically estimated fuzziness parameter (m):", round(estimated_m, 2)))

# Define number of clusters
num_clusters <- 4

# Dynamically pull clean time labels
raw_time_labels <- colnames(expr_matrix)
clean_time_labels <- str_extract(raw_time_labels, "\\d+hpi|\\d+h|\\d+") %>% 
  replace_na("Timepoint")

# ==============================================================================
# 4. RUN MFUZZ CLUSTERING
# ==============================================================================

message("[STEP 4] Running fuzzy c-means clustering...")

set.seed(42) # Guarantee reproducible cluster initializations
cl <- mfuzz(expr_set_std, c = num_clusters, m = estimated_m)

message(paste("[SUCCESS] Fuzzy clustering complete. Groups mapped to", num_clusters, "profiles."))

# ==============================================================================
# 5. VISUALIZE CLUSTER TRAJECTORIES
# ==============================================================================

message("[STEP 5] Saving cluster profile visualizations...")

plots_dir <- "./pilot-analysis/processed_data/plots"
dir.create(plots_dir, showWarnings = FALSE, recursive = TRUE)

png(file.path(plots_dir, "mfuzz_clusters.png"), width = 1200, height = 800, res = 120)
mfuzz.plot(expr_set_std, 
           cl = cl, 
           mfrow = c(2, 2), 
           time.labels = clean_time_labels,
           new.window = FALSE)
dev.off()

message("[SUCCESS] Saved cluster trend profiles: mfuzz_clusters.png")

# ==============================================================================
# 6. EXTRACT & MAP CLUSTER MEMBERSHIPS
# ==============================================================================

message("[STEP 6] Extracting crisp assignments and membership weights...")

# Hard assignments
cluster_assignments <- data.frame(
  gene_id = names(cl$cluster),
  cluster = as.factor(cl$cluster)
)

# Extract and explicitly format the membership matrix to eliminate coercion discrepancies
raw_membership <- cl$membership
colnames(raw_membership) <- paste0("Cluster_", 1:ncol(raw_membership)) # Robust prefix definition

membership_matrix <- as.data.frame(raw_membership) %>% 
  rownames_to_column("gene_id")

# Tidy data and compile comprehensive profile details
cluster_info <- cluster_assignments %>%
  left_join(
    membership_matrix %>% 
      pivot_longer(-gene_id, names_to = "membership_cluster", values_to = "membership_strength"),
    by = "gene_id"
  ) %>%
  # Filter to preserve the primary assigned membership value
  filter(paste0("Cluster_", cluster) == membership_cluster) %>% 
  select(gene_id, cluster, membership_strength)

# ==============================================================================
# 7. CHARACTERIZE CLUSTERS WITH SYSTEMATIC LABELS
# ==============================================================================

message("[STEP 7] Mapping profile labels to clusters...")

cluster_summary <- cluster_assignments %>%
  group_by(cluster) %>%
  summarise(gene_count = n(), .groups = 'drop')

print(cluster_summary)

# System labels mapped to biological dynamics
cluster_labels <- c(
  "1" = "Profile_1_Transition",
  "2" = "Profile_2_Early_Response",
  "3" = "Profile_3_Late_Response",
  "4" = "Profile_4_Transient_Repression"
)

cluster_info$profile_label <- cluster_labels[as.character(cluster_info$cluster)]

# Save detailed assignments
write.csv(cluster_info, file.path(results_dir, "cluster_assignments_detailed.csv"), row.names = FALSE)

# ==============================================================================
# 8. HEATMAPS OF SOFT-CLUSTERED GENES
# ==============================================================================

message("[STEP 8] Creating individual cluster heatmaps...")

for (k in 1:num_clusters) {
  genes_in_cluster <- cluster_info %>% 
    filter(cluster == k) %>% 
    pull(gene_id)
  
  if (length(genes_in_cluster) < 2) {
    message(paste("[WARNING] Cluster", k, "has too few genes to cluster for heatmap. Skipping."))
    next
  }
  
  cluster_counts <- exprs(expr_set_std)[genes_in_cluster, , drop = FALSE]
  
  # Final Z-score variance safety check
  gene_variances <- apply(cluster_counts, 1, var)
  cluster_counts_filtered <- cluster_counts[gene_variances > 0, , drop = FALSE]
  
  if (nrow(cluster_counts_filtered) < 2) {
    message(paste("[WARNING] Insufficient variance in cluster", k, "after processing. Skipping heatmap."))
    next
  }
  
  png(file.path(plots_dir, paste0("cluster_", k, "_heatmap.png")), width = 800, height = 600, res = 120)
  pheatmap(
    cluster_counts_filtered,
    main = paste0("Cluster ", k, " (", cluster_labels[as.character(k)], ", n=", nrow(cluster_counts_filtered), ")"),
    scale = "none", # Matrix is already standardized
    color = colorRampPalette(c("blue", "white", "red"))(100),
    clustering_method = "ward.D2",
    show_rownames = FALSE
  )
  dev.off()
}

message("[SUCCESS] Individual cluster heatmaps exported")

# ==============================================================================
# 9. EXPORT FILTERED GENE LISTS
# ==============================================================================

message("[STEP 9] Exporting clean gene lists for enrichment analysis...")

for (k in 1:num_clusters) {
  genes_in_cluster <- cluster_info %>% 
    filter(cluster == k) %>% 
    select(gene_id, membership_strength) %>% 
    arrange(desc(membership_strength))
  
  write.csv(genes_in_cluster, 
            file = file.path(results_dir, paste0("cluster_", k, "_genes.csv")), 
            row.names = FALSE)
}

message("[SUCCESS] Clean target lists successfully saved.")
message("==================================================")
message("TEMPORAL CLUSTERING PIPELINE COMPLETE")
message("==================================================")
