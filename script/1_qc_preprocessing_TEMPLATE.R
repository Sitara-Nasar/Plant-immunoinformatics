# ==============================================================================
# QUALITY CONTROL & PREPROCESSING TEMPLATE
# ==============================================================================
# Purpose: FastQC assessment, adapter trimming, quality filtering (PE & SE support)
# Status: TEMPLATE - Adjust parameters as needed for your data
# Requirements: FastQC and fastp must be installed in the active Conda environment
# ==============================================================================

library(tidyverse)
library(stringr)

message("==================================================")
message("QUALITY CONTROL & PREPROCESSING PIPELINE")
message("==================================================")

# ==============================================================================
# 1. DIRECTORY SETUP (Aligned with pilot-analysis structure)
# ==============================================================================

raw_dir     <- "./pilot-analysis/raw_data"
qc_dir      <- "./pilot-analysis/logs/qc_results"
trimmed_dir <- "./pilot-analysis/processed_data/trimmed_data"

dir.create(qc_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(trimmed_dir, showWarnings = FALSE, recursive = TRUE)

message("[STEP 1] Directory structure verified")

# ==============================================================================
# 2. FASTQC QUALITY ASSESSMENT (Before Trimming)
# ==============================================================================

message("[STEP 2] Running FastQC on raw reads...")

# Robustly find fastq/fq/gz files
fastq_files <- list.files(raw_dir, pattern = "\\.(fastq|fq)(\\.gz)?$", full.names = TRUE)

if (length(fastq_files) == 0) {
  stop("[ERROR] No FASTQ files found in ./pilot-analysis/raw_data/. Please run data acquisition first.")
}

message(paste("[INFO] Found", length(fastq_files), "raw sequencing file(s)"))

# Run FastQC
fastqc_cmd <- paste(
  "fastqc",
  paste(fastq_files, collapse = " "),
  paste("--outdir", qc_dir),
  "--threads 4",
  sep = " "
)

message("[COMMAND] Running: fastqc...")
system(fastqc_cmd)
message("[SUCCESS] Pre-trimming FastQC complete")

# ==============================================================================
# 3. ADAPTER TRIMMING & QUALITY FILTERING WITH FASTP (Paired-End Processing)
# ==============================================================================

message("[STEP 3] Trimming adapters and low-quality bases...")

# Filter parameters
MIN_LENGTH <- 30
MIN_QUALITY <- 20
WINDOW_SIZE <- 4

# Identify R1 files to drive the loop (assuming paired-end data '_1' or '_R1')
r1_files <- list.files(raw_dir, pattern = "(_1|_R1)\\.(fastq|fq)(\\.gz)?$", full.names = TRUE)

if (length(r1_files) > 0) {
  message("[INFO] Paired-end data structure detected. Processing pairs...")
  
  for (r1 in r1_files) {
    # Deduce the matching R2 file
    r2 <- str_replace(r1, "(_1|_R1)\\.", "\\2\\.") # Swaps _1 for _2
    if (!str_detect(r2, "(_2|_R2)")) {
      r2 <- str_replace(r1, "_1", "_2") %>% str_replace("_R1", "_R2")
    }
    
    if (!file.exists(r2)) {
      message(paste("[WARNING] Matching R2 file not found for:", basename(r1), "- Skipping."))
      next
    }
    
    base_name <- basename(r1) %>% str_remove("(_1|_R1)\\.(fastq|fq).*$")
    
    out_r1 <- file.path(trimmed_dir, paste0(base_name, "_1.trimmed.fastq.gz"))
    out_r2 <- file.path(trimmed_dir, paste0(base_name, "_2.trimmed.fastq.gz"))
    json_report <- file.path(qc_dir, paste0(base_name, ".fastp.json"))
    html_report <- file.path(qc_dir, paste0(base_name, ".fastp.html"))
    
    fastp_cmd <- paste(
      "fastp",
      "-i", r1,
      "-I", r2,
      "-o", out_r1,
      "-O", out_r2,
      paste("--length_required", MIN_LENGTH),
      paste("--qualified_quality_phred", MIN_QUALITY),
      paste("--window_size", WINDOW_SIZE),
      "--cut_front --cut_tail",
      "--detect_adapter_for_pe",
      paste("--json", json_report),
      paste("--html", html_report),
      "--thread 4",
      sep = " "
    )
    
    message(paste("[PROCESSING PAIR]", base_name))
    system(fastp_cmd)
  }
} else {
  message("[INFO] Single-end data detected (or files do not follow _1/_2 naming conventions). Processing as single-end...")
  
  for (fastq_file in fastq_files) {
    base_name <- basename(fastq_file) %>% str_remove("\\.(fastq|fq).*$")
    
    output_file <- file.path(trimmed_dir, paste0(base_name, ".trimmed.fastq.gz"))
    json_report <- file.path(qc_dir, paste0(base_name, ".fastp.json"))
    html_report <- file.path(qc_dir, paste0(base_name, ".fastp.html"))
    
    fastp_cmd <- paste(
      "fastp",
      "-i", fastq_file,
      "-o", output_file,
      paste("--length_required", MIN_LENGTH),
      paste("--qualified_quality_phred", MIN_QUALITY),
      paste("--window_size", WINDOW_SIZE),
      "--cut_front --cut_tail",
      paste("--json", json_report),
      paste("--html", html_report),
      "--thread 4",
      sep = " "
    )
    
    message(paste("[PROCESSING SE]", base_name))
    system(fastp_cmd)
  }
}

message("[SUCCESS] Adapter trimming complete")

# ==============================================================================
# 4. FASTQC QUALITY ASSESSMENT (After Trimming)
# ==============================================================================

message("[STEP 4] Running Post-Trimming FastQC...")

trimmed_files <- list.files(trimmed_dir, pattern = "\\.trimmed\\.fastq\\.gz$", full.names = TRUE)

if (length(trimmed_files) > 0) {
  fastqc_post_cmd <- paste(
    "fastqc",
    paste(trimmed_files, collapse = " "),
    paste("--outdir", qc_dir),
    "--threads 4",
    sep = " "
  )
  system(fastqc_post_cmd)
  message("[SUCCESS] Post-trimming FastQC complete")
}

# ==============================================================================
# 5. QC SUMMARY REPORT
# ==============================================================================

message("[STEP 5] Generating QC summary...")

if (length(trimmed_files) > 0) {
  qc_summary <- data.frame(
    "Sample" = basename(trimmed_files) %>% str_remove("\\.trimmed.*$"),
    "File_Size_GB" = round(file.size(trimmed_files) / 1e9, 4),
    "Processing_Date" = Sys.Date()
  )
  write.csv(qc_summary, file.path(qc_dir, "qc_summary.csv"), row.names = FALSE)
  message("[SUCCESS] QC summary saved to", file.path(qc_dir, "qc_summary.csv"))
}

message("==================================================")
message("QC PREPROCESSING COMPLETE")
message("==================================================")
message("[FILES] Trimmed reads ready in:", trimmed_dir)
