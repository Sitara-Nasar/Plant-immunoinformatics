#!/bin/bash

# ==============================================================================
# ALIGNMENT & QUANTIFICATION TEMPLATE (PAIRED-END COMPATIBLE)
# ==============================================================================
# Purpose: Map paired-end reads to reference genomes; quantify transcript abundance
# Status: TEMPLATE - Replace reference paths with your active system paths
# Requirements: HISAT2, samtools, and featureCounts (subread) installed
# ==============================================================================

set -e  # Exit immediately on error

echo "=========================================="
echo "ALIGNMENT & QUANTIFICATION PIPELINE"
echo "=========================================="

# ==============================================================================
# CONFIGURATION (Aligned with pilot-analysis structure)
# ==============================================================================

TRIMMED_DIR="./pilot-analysis/processed_data/trimmed_data"
ALIGNED_DIR="./pilot-analysis/processed_data/aligned_bam"
COUNTS_DIR="./pilot-analysis/processed_data/gene_counts"
LOGS_DIR="./pilot-analysis/logs"

# Reference genome paths (REPLACE WITH ACTUAL PATHS IN DEPLOYMENT)
REFERENCE_GENOME_1="[PATH_TO_REFERENCE_GENOME_1_FASTA]"  # e.g., maize reference
REFERENCE_GENOME_2="[PATH_TO_REFERENCE_GENOME_2_FASTA]"  # e.g., pathogen reference

GTF_FILE_1="[PATH_TO_GTF_1]"  # Gene annotation file 1
GTF_FILE_2="[PATH_TO_GTF_2]"  # Gene annotation file 2

THREADS=8

mkdir -p "$ALIGNED_DIR" "$COUNTS_DIR" "$LOGS_DIR"

# Helper variable: Strip suffix to define index base prefix
INDEX_PREFIX_1="${REFERENCE_GENOME_1%.fa}"
INDEX_PREFIX_2="${REFERENCE_GENOME_2%.fa}"

# ==============================================================================
# 1. BUILD HISAT2 INDICES
# ==============================================================================

echo "[STEP 1] Verifying HISAT2 genome indices..."

if [ ! -f "${INDEX_PREFIX_1}.1.ht2" ]; then
  echo "[INFO] Building HISAT2 index for Host Genome..."
  hisat2-build -p $THREADS "$REFERENCE_GENOME_1" "$INDEX_PREFIX_1"
else
  echo "[INFO] Index for Host Genome detected."
fi

if [ ! -f "${INDEX_PREFIX_2}.1.ht2" ]; then
  echo "[INFO] Building HISAT2 index for Pathogen Genome..."
  hisat2-build -p $THREADS "$REFERENCE_GENOME_2" "$INDEX_PREFIX_2"
else
  echo "[INFO] Index for Pathogen Genome detected."
fi

# ==============================================================================
# 2. ALIGNMENT WITH HISAT2 (Paired-End Processing Loop)
# ==============================================================================

echo "[STEP 2] Aligning paired-end reads to reference genomes..."

# Loop strictly over R1 (Forward) files to avoid double-processing
for r1_file in "$TRIMMED_DIR"/*_1.trimmed.fastq.gz; do
  [ -e "$r1_file" ] || continue  # Safety check if no matching files exist
  
  # Identify matching R2 (Reverse) file
  r2_file="${r1_file/_1.trimmed.fastq.gz/_2.trimmed.fastq.gz}"
  
  if [ ! -f "$r2_file" ]; then
    echo "[WARNING] Matching R2 file not found for $r1_file. Skipping."
    continue
  fi

  base_name=$(basename "$r1_file" _1.trimmed.fastq.gz)
  
  # Map sample naming structure to target reference
  if [[ "$base_name" == *"host"* ]] || [[ "$base_name" == *"maize"* ]]; then
    INDEX="$INDEX_PREFIX_1"
    ORGANISM="Host"
  else
    INDEX="$INDEX_PREFIX_2"
    ORGANISM="Pathogen"
  fi
  
  echo "[PROCESSING] Aliging $base_name ($ORGANISM) as Paired-End"
  
  # Run HISAT2 with paired-end variables
  hisat2 \
    -p $THREADS \
    -x "$INDEX" \
    -1 "$r1_file" \
    -2 "$r2_file" \
    -S "$ALIGNED_DIR/${base_name}.sam" \
    --summary-file "$LOGS_DIR/${base_name}.alignment_summary.txt"
  
  # Convert to BAM, Sort and Index
  echo "[INFO] Converting to sorted BAM: ${base_name}"
  samtools view -@ $THREADS -b "$ALIGNED_DIR/${base_name}.sam" | \
    samtools sort -@ $THREADS -o "$ALIGNED_DIR/${base_name}.sorted.bam" -
  
  samtools index "$ALIGNED_DIR/${base_name}.sorted.bam"
  
  # Clean up temporary SAM files to save storage space
  rm "$ALIGNED_DIR/${base_name}.sam"
  
done

echo "[SUCCESS] All alignments complete"

# ==============================================================================
# 3. QUANTIFY TRANSCRIPT ABUNDANCE WITH featureCounts
# ==============================================================================

echo "[STEP 3] Quantifying transcript abundance with featureCounts..."

# -p flag specifies paired-end reads; -T handles threads
# Process Host BAMs
HOST_BAMS=$(ls "$ALIGNED_DIR"/*host*.sorted.bam "$ALIGNED_DIR"/*maize*.sorted.bam 2>/dev/null || true)
if [ -n "$HOST_BAMS" ]; then
  echo "[INFO] Counting features for Host samples..."
  featureCounts \
    -p \
    -T $THREADS \
    -a "$GTF_FILE_1" \
    -o "$COUNTS_DIR/host_counts.txt" \
    $HOST_BAMS
else
  echo "[WARNING] No host BAM files found. Skipping host feature counts."
fi

# Process Pathogen BAMs
PATHOGEN_BAMS=$(ls "$ALIGNED_DIR"/*pathogen*.sorted.bam "$ALIGNED_DIR"/*graminicola*.sorted.bam 2>/dev/null || true)
if [ -n "$PATHOGEN_BAMS" ]; then
  echo "[INFO] Counting features for Pathogen samples..."
  featureCounts \
    -p \
    -T $THREADS \
    -a "$GTF_FILE_2" \
    -o "$COUNTS_DIR/pathogen_counts.txt" \
    $PATHOGEN_BAMS
else
  echo "[WARNING] No pathogen BAM files found. Skipping pathogen feature counts."
fi

echo "[SUCCESS] Feature counting complete"

# ==============================================================================
# 4. GENERATE ALIGNMENT STATISTICS
# ==============================================================================

echo "[STEP 4] Generating alignment statistics..."

for bam_file in "$ALIGNED_DIR"/*.sorted.bam; do
  [ -e "$bam_file" ] || continue
  base_name=$(basename "$bam_file" .sorted.bam)
  samtools flagstat "$bam_file" > "$LOGS_DIR/${base_name}.flagstat.txt"
done

echo "[SUCCESS] Alignment statistics successfully saved in $LOGS_DIR"
echo "=========================================="
echo "ALIGNMENT & QUANTIFICATION PIPELINE COMPLETE"
echo "=========================================="
