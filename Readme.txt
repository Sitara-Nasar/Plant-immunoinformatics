# Reproducible Transcriptomics Pipeline for Plant-Pathogen Interactions

This repository hosts the bioinformatics pipeline and reproducible workflows designed for the MSCA Postdoctoral Fellowship. 

To demonstrate feasibility and ensure workflow robustness prior to the start of the fellowship, the pipeline has been piloted and validated using public, high-throughput transcriptomic datasets capturing the time-course infection kinetics of **Maize (*Zea mays*)** and **_Colletotrichum graminicola_**.

## Pilot Dataset & Experimental Design

This pilot utilizes time-series RNA-Seq data to capture the transitional phases of hemibiotrophic infection (the stealth biotrophic phase transitioning to the destructive necrotrophic phase).

### Host: Maize (*Zea mays*)
* **Public Reference Dataset:** NCBI GEO Accession [GSE218099](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE218099)
* **Infection Timepoints:** 0, 24, 36, 40, 60, and 96 hours post-infection (hpi)
* **Objective:** Characterize the chronological induction of host immune receptor signaling pathways and downstream transcriptional defense cascades specifically in the context of endogenous peptide ligand signaling.

### Pathogen: *Colletotrichum graminicola*
* **Public Reference Dataset:** NCBI GEO Accession [GSE34632](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE34632)
* **Infection Timepoints:** Pre-penetration appressoria (PA), early biotrophic phase (BP), switch from biotrophy to necrotrophy (NP)
* **Objective:** Monitor the temporal activation of fungal virulence factors and candidate effectors as the pathogen establishes infection.

## Planned & Validated Pipeline

### 1. Quality Control & Preprocessing
* Quality assessment of raw reads (FASTQ) via **FastQC**.
* Adapter trimming and low-quality base filtering using **fastp** / **Trimmomatic**.

### 2. Alignment & Quantification
* Mapping reads to the reference genomes (*Zea mays* and *C. graminicola*) using **HISAT2** or **STAR**.
* Transcript abundance quantification using **Salmon** / **featureCounts**.

### 3. Time-Course Differential Expression Analysis
* Statistical modeling of temporal gene expression kinetics using the **DESeq2** package in **R** (utilizing LRT/Likelihood Ratio Tests for time-course modeling).
* Clustering of temporal expression profiles to group genes sharing similar activation kinetics (e.g., using **TCseq** or **Mfuzz**).

## Repository Organization
* `/pilot-analysis`: Metadata templates and public dataset accessions for the Maize and *C. graminicola* time-course datasets.
* `/scripts`: Documented pipeline templates for preprocessing, alignment, and R-based time-course modeling.
