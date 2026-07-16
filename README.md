# Plant-immunoinformatics

Reproducible RNA-Seq analysis pipeline for the MSCA project studying plant immune receptor signaling

# Reproducible Transcriptomics Pipeline for Plant-Pathogen Interactions

This repository hosts the bioinformatics pipeline and computational workflows for time-course RNA-Seq analysis of host-pathogen interactions. The pipeline has been piloted and validated using public, high-throughput transcriptomic datasets to demonstrate feasibility and ensure workflow robustness.

---

## ⚠️ Status: PILOT & TEMPLATE PHASE

All scripts in this repository are **TEMPLATES** with generic placeholders. This project is currently **UNFUNDED** (pending review). To protect intellectual property rights while maintaining open-science transparency, project-specific biological targets and detailed methodological applications remain confidential. The pipeline methodology and statistical framework are fully documented and reproducible on any host-pathogen system.

---

## Pilot Datasets & Experimental Design

This pipeline utilizes time-series RNA-Seq data to capture temporal progression of hemibiotrophic fungal infection, spanning establishment phase through tissue colonization.

### Host Dataset
* **Public Reference Dataset:** NCBI GEO Accession [GSE210899](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE210899)
* **Reference:** Xu et al. 2022
* **Infection Timepoints (Available in Dataset):** 0, 24, 40, 60, 96 hours post-infection (hpi)
* **Timepoint Selection for Analysis:** 
  - Gene discovery & feature selection: All timepoints (0, 24, 40, 60, 96 hpi)
  - Experimental validation: Subset of timepoints (0, 24, 40, 60 hpi)
* **Analysis Objective:** Identify temporal gene expression dynamics and co-regulated immune pathway components across infection progression

### Pathogen Dataset
* **Public Reference Dataset:** NCBI GEO Accession [GSE34632](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE34632)
* **Reference:** O'Connell RJ et al., 2012
* **Infection Stages:** Pre-infection, early biotrophic phase, necrotrophy transition
* **Analysis Objective:** Monitor temporal activation of fungal gene expression during pathogenic life-stage transitions

---

## Computational Pipeline Workflow

### 1. Quality Control & Preprocessing
* Quality assessment of raw sequencing reads via **FastQC**
* Adapter trimming and low-quality base removal using **fastp** or **Trimmomatic**
* **Output:** Cleaned, ready-to-align sequencing data

### 2. Alignment & Quantification
* Read mapping to reference genomes using **HISAT2** or **STAR**
* Transcript abundance quantification via **featureCounts** or **Salmon**
* **Output:** Count matrices (host and pathogen separately)

### 3. Time-Course Differential Expression Analysis
* Temporal gene expression modeling using **DESeq2** (R)
* Statistical test: **LRT (Likelihood Ratio Test)** for time-course data
* **Parameters:** FDR-adjusted p-value <0.05, |Log2 fold-change| ≥1.5
* **Output:** Temporal gene expression profiles; early-, mid-, and late-response gene classifications

### 4. Temporal Gene Clustering
* Time-course gene clustering using **TCseq** or **Mfuzz**
* **Objective:** Group genes with similar temporal activation patterns
* **Output:** Gene clusters representing distinct temporal response categories

### 5. Gene Co-Expression Network Analysis
* Weighted gene co-expression network construction using **WGCNA**
* Module detection: Identification of stage-specific gene co-expression modules
* Network topology analysis: Hub gene identification (master regulators)
* **Output:** Co-expression modules, hub genes, network visualizations

---

## Repository Organization
* `/pilot-analysis`: Metadata templates and public dataset accessions for the Maize and *C. graminicola* time-course datasets.
* `/scripts`: Documented pipeline templates for preprocessing, alignment, and R-based time-course modeling.
