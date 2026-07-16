# Detailed Methods Documentation

## Overview

This document provides comprehensive methodological descriptions for the dual-transcriptomics pipeline, enabling full reproducibility and transparency of computational approaches.

---

## 1. Data Sources

### Host Organism Transcriptomics
- **Dataset Accession:** [GSE210899](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE210899)
- **Reference:** Xu et al., 2022
- **Organism:** *Zea mays* (Maize B73)
- **Infection Status:** Infected with *Colletotrichum graminicola*
- **Timepoints:** 0, 24, 40, 60, 96 hours post-infection (hpi)
- **Replicates:** $n = 3$ biological replicates per timepoint (total $N = 15$ libraries)

### Pathogen Transcriptomics
- **Dataset Accession:** [GSE34632](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE34632)
- **Reference:** O'Connell RJ et al., 2012
- **Organism:** *Colletotrichum graminicola* (strain CgM2)
- **Infection Stages:** Pre-penetration appressoria (PA), early biotrophic phase (BP), necrotrophy transition (NP)

---

## 2. Quality Control & Preprocessing

### FastQC Assessment
- **Tool:** FastQC v0.11.9 (Andrews, S.)
- **Purpose:** Assess raw sequencing read quality across all samples.
- **Metrics Evaluated:**
  - Per-base quality distribution
  - Per-base GC content
  - Adapter contamination
  - Duplicate sequences

### Read Trimming with fastp
- **Tool:** fastp v0.23.4
- **Parameters:**
  - Minimum read length: 30 bp
  - Minimum quality threshold: $Q \ge 20$ (Phred quality score)
  - Sliding window size: 4 bp (sliding window quality assessment)
  - Adapter auto-detection: Enabled
- **Purpose:** Remove low-quality bases, index adapters, and low-confidence reads.

---

## 3. Alignment & Quantification

### Alignment Strategy (In Silico Decontamination)
To prevent cross-mapping/mis-mapping of sequence reads in physical co-extracted host-pathogen mixtures, mapping is executed against a combined **host-pathogen reference index** (holobiont genome construct).

### Reference Genome Mapping
- **Tool:** HISAT2 v2.2.1 (Kim et al., 2015)
- **Parameters:**
  - Sensitive-local alignment preset
  - Maximum intron length: 5000 bp (typical for eukaryotes)
  - Threads: 8

### Reference Genomes Used
- **Host Index:** *Zea mays* B73 v4 (Ensembl/Gramene)
- **Pathogen Index:** *Colletotrichum graminicola* CgM2 (NCBI Genomes)

### Transcript Abundance Quantification
- **Tool:** featureCounts v2.0.3 (Liao et al., 2013)
- **Parameters:**
  - Strandedness: Programmatically inferred from library (unstranded or reverse-stranded)
  - Minimum mapping quality: $\text{MAPQ} \ge 10$
  - Feature type: "exon" grouped by "gene_id"

---

## 4. Differential Expression Analysis

### Statistical Framework
- **Tool:** DESeq2 v1.38.0 (Love et al., 2014)
- **Test:** Likelihood Ratio Test (LRT)

### LRT Rationale for Time-Course Data
The Likelihood Ratio Test (LRT) is utilized for time-course multi-timepoint designs to assess whether a gene displays significant expression changes across any timepoint (global trend test) rather than performing excessive pairwise comparisons.

- **Full Model:** $\sim \text{timepoint}$ (expression is a function of time)
- **Reduced Model:** $\sim 1$ (expression remains constant over time)
- **Test Statistic:** Likelihood ratio comparing the deviances of the full model ($d_{\text{full}}$) and the reduced model ($d_{\text{reduced}}$):

$$\Lambda = -2 \ln \left( \frac{\mathcal{L}_{\text{reduced}}}{\mathcal{L}_{\text{full}}} \right) = d_{\text{reduced}} - d_{\text{full}}$$

The statistic $\Lambda$ is evaluated against a $\chi^2$ distribution with degrees of freedom equal to the difference in parameters between models.

### Statistical Thresholds
- **FDR-adjusted p-value:** $< 0.05$ (Benjamini-Hochberg correction)
- **Minimum Log2 Fold Change:** $|\log_2 \text{FC}| \ge 1.5$ (absolute difference between maximum and minimum expressing timepoints)
- **Low-Count Filtering:** Genes with $< 10$ cumulative counts across all samples are excluded prior to statistical testing.

### Normalization
- **Method:** Median-of-ratios normalization (DESeq2 size-factor scaling) to account for variations in sequencing depth and library compositions.

---

## 5. Temporal Gene Clustering

### Tool: Mfuzz (Fuzzy C-Means Clustering)
- **Publication:** Futschik & Carlisle (2005)
- **Method:** Soft clustering, assigning genes to clusters with membership values ranging from 0 to 1.
- **Parameters:**
  - Number of clusters ($k$): 4 (aligned with biological phases: early, mid, late, and transient)
  - Fuzziness parameter ($m$): Programmatically estimated using the standard mathematical estimator `mestimate()` to eliminate arbitrary scaling bias
  - Distance metric: Euclidean

### Rationale
Fuzzy clustering represents biological transitions more accurately than hard partitioning algorithms (e.g., k-means) because:
- Biological systems exhibit continuous, graded gene expression changes over time.
- Membership values ($0 \le \mu \le 1$) quantify assignment confidence, allowing downstream analyses to focus on core driver transcripts.

---

## 6. Co-Expression Network Analysis

### Tool: WGCNA (Weighted Gene Co-Expression Network Analysis)
- **Publication:** Langfelder & Horvath (2008)
- **Method:** Constructs scale-free networks where gene-gene relationships are weighted by correlation.

### Network Construction Steps

#### 6.1 Soft-Threshold Power Selection
- **Purpose:** Determine the power exponent $\beta$ to satisfy a scale-free topology fit ($R^2 \ge 0.85$).
- **Method:** `pickSoftThreshold` evaluated on a strictly **signed** network architecture.
- **Target:** Power selection parameter $\beta$ (typically $\beta \ge 12$ for signed biological transcriptomics networks of $<20$ samples).

#### 6.2 Adjacency Matrix
To preserve the direction of correlation, a signed adjacency matrix $a_{ij}$ is calculated:

$$a_{ij} = \left( \frac{1 + \text{cor}(i,j)}{2} \right)^\beta$$

Where:
- $\text{cor}(i,j)$ is the Pearson correlation between the expression profiles of gene $i$ and gene $j$.
- $\beta$ is the soft-thresholding power.

#### 6.3 Topological Overlap Matrix (TOM)
The adjacency is transformed into the Topological Overlap Matrix ($\text{TOM}$) to account for shared network neighbors, minimizing local noise:

$$\text{TOM}_{ij} = \frac{l_{ij} + a_{ij}}{\min(k_i, k_j) + 1 - a_{ij}}$$

Where:
- $l_{ij} = \sum_{u} a_{iu} a_{uj}$ represents the shared node connectivity between gene $i$ and gene $j$.
- $k_i = \sum_{u} a_{iu}$ is the connectivity of gene $i$.
- Dissimilarity is defined as: $d_{ij} = 1 - \text{TOM}_{ij}$.

#### 6.4 Hierarchical Clustering & Dynamic Tree Cutting
- **Distance Metric:** Dissimilarity ($1 - \text{TOM}$)
- **Linkage Method:** Average linkage clustering (UPGMA)
- **Dynamic Cutting:** `cutreeDynamic` applied with a minimum module size threshold of 30 genes.

---

## 7. Hub Gene Identification

### Definition
Hub genes are identified as nodes exhibiting the highest weighted connectivity within their specific co-expression module.

### Calculation
Intra-module connectivity ($k_{\text{in}}$) for gene $i$ within module $q$ is calculated as:

$$k_{\text{in}}(i) = \sum_{j \in q} a_{ij}$$

Genes are ranked based on $k_{\text{in}}$ per module; the top 10 ranked genes are classified as network hubs.

---

## 8. Visualization & Reporting

### Heatmaps
- **Tool:** pheatmap (R package)
- **Normalization:** Row-wise Z-score scaling:

$$Z = \frac{x - \mu}{\sigma}$$

- **Clustering:** Hierarchical clustering using Euclidean distance metrics and Ward's linkage (`ward.D2`).

### Network Plots
- **Tool:** igraph (R package)
- **Nodes:** Scaled proportionally to intra-module connectivity ($k_{\text{in}}$).
- **Edges:** Scaled proportionally to $\text{TOM}$ weights.
- **Layout:** Fruchterman-Reingold force-directed layout.

---

## 9. Quality Control Checkpoints

### Pre-Analysis QC
- [x] **FastQC:** $>80\%$ of sequencing bases exhibit Phred quality scores $Q > 20$.
- [x] **Adapters:** Global adapter contamination is minimized to $<1\%$ of raw reads.
- [x] **Outliers:** Hierarchical sample tree clustering confirms no anomalous experimental outliers.

### Post-Alignment QC
- [x] **Alignment:** Overall alignment rate $>80\%$ against host and pathogen genomes.
- [x] **Orientation:** Strand-specific orientation is validated.

### Post-DESeq2 QC
- [x] **MA & PCA Plots:** Biological replicates cluster by timepoint, with treatment and infection explaining $>70\%$ of variance.
- [x] **Dispersion:** Dispersion parameters shrink normally toward the fitted trend line.

---

## 10. References

- Andrews, S. (2010). FastQC. Babraham Bioinformatics.
- Kim, D., et al. (2015). HISAT: Fast spliced aligner with low memory requirements. *Nat Methods*, 12(4), 357-360.
- Liao, Y., et al. (2013). featureCounts. *Bioinformatics*, 30(7), 923-930.
- Love, M. I., et al. (2014). Moderated estimation of fold change and dispersion for RNA-seq data with DESeq2. *Genome Biol*, 15(12), 550.
- Langfelder, P., & Horvath, S. (2008). WGCNA: an R package for weighted correlation network analysis. *BMC Bioinformatics*, 9, 559.
- Futschik, M. E., & Carlisle, B. (2005). Noise-robust soft clustering of gene expression time-course data. *J Bioinform Comput Biol*, 3(4), 965-988.
