#!/bin/bash

# ==============================================================================
# DATA DOWNLOAD TEMPLATE
# ==============================================================================
# Purpose: Download public datasets from NCBI GEO for time-course analysis
# Status: TEMPLATE - Replace [DATASET_ACCESSION] with actual accessions
# 
# Public Datasets Reference:
# - Host transcriptomics: GSE210899 (Xu et al. 2022)
# - Pathogen transcriptomics: GSE34632 (O'Connell et al. 2012)
# ==============================================================================

set -e  # Exit immediately if a command exits with a non-zero status

echo "=========================================="
echo "Starting Data Download Pipeline"
echo "=========================================="

# Create directory structure inside pilot-analysis/ to maintain clean repo structure
echo "[INFO] Creating directory structure..."
mkdir -p pilot-analysis/{raw_data,processed_data,metadata,logs}

# ==============================================================================
# OPTION 1: Download via NCBI GEO (Web Interface)
# ==============================================================================
echo "[INFO] Downloading datasets from NCBI GEO..."
echo "[INFO] Please visit and download manually:"
echo "       Host dataset: https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE210899"
echo "       Pathogen dataset: https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE34632"
echo "[INFO] Place downloaded raw fastq/fastq.gz files in: ./pilot-analysis/raw_data/"
echo ""

# ==============================================================================
# OPTION 2: Download via SRA Toolkit (If using SRA accessions)
# ==============================================================================
# Uncomment and replace [SRR_ACCESSION] with actual SRR numbers from GEO

# echo "[INFO] Downloading via SRA Toolkit..."
# prefetch --output-directory ./pilot-analysis/raw_data [SRR_ACCESSION_1]
# prefetch --output-directory ./pilot-analysis/raw_data [SRR_ACCESSION_2]

# # Convert SRA to FASTQ
# # Note: fasterq-dump can also take SRA accessions directly without prior prefetch
# for sra_file in pilot-analysis/raw_data/*.sra; do
#    if [ -f "$sra_file" ]; then
#        echo "[INFO] Converting $(basename "$sra_file") to FASTQ..."
#        fasterq-dump "$sra_file" -O ./pilot-analysis/raw_data -e 8
#    fi
# done

# ==============================================================================
# OPTION 3: Download via wget (If direct FTP/HTTP links are available)
# ==============================================================================
# echo "[INFO] Downloading via FTP..."
# wget -r -P ./pilot-analysis/raw_data ftp://[FTP_PATH_TO_DATASET]

# ==============================================================================
# Verify downloaded files
# ==============================================================================
echo "[INFO] Verifying downloaded files..."

# Robust, safe check for FASTQ files without parsing ls
fastq_exists=false
for file in pilot-analysis/raw_data/*.fastq* pilot-analysis/raw_data/*.fq*; do
    [ -e "$file" ] || continue
    fastq_exists=true
    break
done

if [ "$fastq_exists" = false ]; then
  echo "[WARNING] No FASTQ files found in ./pilot-analysis/raw_data/"
  echo "[INFO] Please ensure datasets are downloaded and placed in the target directory."
  echo "[INFO] Expected formats: *.fastq, *.fastq.gz, *.fq, or *.fq.gz"
  exit 1
fi

# Count files safely
FASTQ_COUNT=$(find pilot-analysis/raw_data/ -name "*.fastq*" -o -name "*.fq*" | wc -l)
echo "[SUCCESS] Found $FASTQ_COUNT raw sequence file(s)"

# Create manifest
echo "[INFO] Creating file manifest..."
ls -lh pilot-analysis/raw_data/*.fastq* pilot-analysis/raw_data/*.fq* > pilot-analysis/metadata/file_manifest.txt 2>/dev/null || true

echo "[SUCCESS] Data download template completed"
echo "=========================================="
