# Plant-immunoinformatics

Reproducible RNA-Seq analysis pipeline for the MSCA project studying plant immune receptor signaling.

# Reproducible Transcriptomics Pipeline for Plant-Pathogen Interactions

This repository hosts the bioinformatics pipeline and computational workflows for time-course RNA-Seq analysis of host-pathogen interactions. The pipeline has been piloted and validated using public, high-throughput transcriptomic datasets to demonstrate feasibility and ensure workflow robustness.

---

## ⚠️ Status: PILOT & TEMPLATE PHASE

All scripts in this repository are **TEMPLATES** with generic placeholders. This project is currently **UNFUNDED** (pending review). To protect intellectual property rights while maintaining open-science transparency, project-specific biological targets and detailed methodological applications remain confidential. The pipeline methodology and statistical framework are fully documented and reproducible on any host-pathogen system.

---

## Open Science & Intellectual Property

### Commitment to Reproducibility
* **Methodology fully documented:** All computational steps, statistical parameters, and analytical rationale are explicitly described.
* **Public datasets:** All pilot analyses use open-access, publicly available transcriptomic datasets.
* **Templates provided:** Step-by-step pipeline scripts enable researchers to apply identical methodology to their own data.

### Intellectual Property Protection
To protect proprietary research during the evaluation phase:
* **Gene/sequence identifiers:** Specific candidate genes, effector predictions, and receptor targets remain confidential.
* **Project details:** Specific biological applications, mechanistic hypotheses, and discovery outcomes are withheld.
* **Template approach:** Scripts use generic placeholders, enabling methodology replication without revealing proprietary biological discoveries.

### Reproducibility Without IP Compromise
Users can fully replicate this workflow by:
1. Downloading the public datasets (GSE210899, GSE34632) from NCBI GEO.
2. Applying the identical pipeline methodology using the provided scripts.
3. Running the workflow with our exact statistical thresholds (FDR < 0.05, |Log2FC| ≥ 1.5).

**Upon funding confirmation, detailed target genes, biological results, and custom methodological applications will be released to the research community.**

---

## Pilot Datasets & Experimental Design

This pipeline utilizes time-series RNA-Seq data to capture the temporal progression of hemibiotrophic fungal infection, spanning the establishment phase through tissue colonization.

### Host Dataset
* **Host Organism:** Maize (*Zea mays*)
* **Public Reference Dataset:** NCBI GEO Accession [GSE210899](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE210899)
* **Reference:** Xu et al., 2022
* **Infection Timepoints (Available in Dataset):** 0, 24, 40, 60, 96 hours post-infection (hpi)
* **Timepoint Selection for Analysis:** 
  - **Gene discovery & feature selection:** All timepoints (0, 24, 40, 60, 96 hpi)
  - **Experimental validation:** Subset of timepoints (0, 24, 40, 60 hpi)
* **Analysis Objective:** Identify temporal gene expression dynamics and co-regulated immune pathway components across infection progression.

### Pathogen Dataset
* **Pathogen Organism:** *Colletotrichum graminicola*
* **Public Reference Dataset:** NCBI GEO Accession [GSE34632](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE34632)
* **Reference:** O'Connell RJ et al., 2012
* **Infection Stages:** Pre-infection, early biotrophic phase, necrotrophy transition
* **Analysis Objective:** Monitor temporal activation of fungal gene expression during pathogenic life-stage transitions.

# Plant-immunoinformatics

Reproducible RNA-Seq analysis pipeline for the MSCA project studying plant immune receptor signaling.

# Reproducible Transcriptomics Pipeline for Plant-Pathogen Interactions

This repository hosts the bioinformatics pipeline and computational workflows for time-course RNA-Seq analysis of host-pathogen interactions. The pipeline has been piloted and validated using public, high-throughput transcriptomic datasets to demonstrate feasibility and ensure workflow robustness.

---

## ⚠️ Status: PILOT & TEMPLATE PHASE

All scripts in this repository are **TEMPLATES** with generic placeholders. This project is currently **UNFUNDED** (pending review). To protect intellectual property rights while maintaining open-science transparency, project-specific biological targets and detailed methodological applications remain confidential. The pipeline methodology and statistical framework are fully documented and reproducible on any host-pathogen system.

---

## Open Science & Intellectual Property

### Commitment to Reproducibility
* **Methodology fully documented:** All computational steps, statistical parameters, and analytical rationale are explicitly described.
* **Public datasets:** All pilot analyses use open-access, publicly available transcriptomic datasets.
* **Templates provided:** Step-by-step pipeline scripts enable researchers to apply identical methodology to their own data.

### Intellectual Property Protection
To protect proprietary research during the evaluation phase:
* **Gene/sequence identifiers:** Specific candidate genes, effector predictions, and receptor targets remain confidential.
* **Project details:** Specific biological applications, mechanistic hypotheses, and discovery outcomes are withheld.
* **Template approach:** Scripts use generic placeholders, enabling methodology replication without revealing proprietary biological discoveries.

### Reproducibility Without IP Compromise
Users can fully replicate this workflow by:
1. Downloading the public datasets (GSE210899, GSE34632) from NCBI GEO.
2. Applying the identical pipeline methodology using the provided scripts.
3. Running the workflow with our exact statistical thresholds (FDR < 0.05, |Log2FC| ≥ 1.5).

**Upon funding confirmation, detailed target genes, biological results, and custom methodological applications will be released to the research community.**

---

## Pilot Datasets & Experimental Design

This pipeline utilizes time-series RNA-Seq data to capture the temporal progression of hemibiotrophic fungal infection, spanning the establishment phase through tissue colonization.

### Host Dataset
* **Host Organism:** Maize (*Zea mays*)
* **Public Reference Dataset:** NCBI GEO Accession [GSE210899](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE210899)
* **Reference:** Xu et al., 2022
* **Infection Timepoints (Available in Dataset):** 0, 24, 40, 60, 96 hours post-infection (hpi)
* **Timepoint Selection for Analysis:** 
  - **Gene discovery & feature selection:** All timepoints (0, 24, 40, 60, 96 hpi)
  - **Experimental validation:** Subset of timepoints (0, 24, 40, 60 hpi)
* **Analysis Objective:** Identify temporal gene expression dynamics and co-regulated immune pathway components across infection progression.

### Pathogen Dataset
* **Pathogen Organism:** *Colletotrichum graminicola*
* **Public Reference Dataset:** NCBI GEO Accession [GSE34632](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE34632)
* **Reference:** O'Connell RJ et al., 2012
* **Infection Stages:** Pre-infection, early biotrophic phase, necrotrophy transition
* **Analysis Objective:** Monitor temporal activation of fungal gene expression during pathogenic life-stage transitions.

### Data Download Instructions

To download the raw data, you can use direct GEO downloads or fetch the runs via the SRA Toolkit:

```bash
# Download via NCBI GEO
wget [https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSE210899&format=file](https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSE210899&format=file)
wget [https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSE34632&format=file](https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSE34632&format=file)

# Or use SRA Toolkit for direct access
prefetch SRR_accession_from_GSE210899
prefetch SRR_accession_from_GSE34632

# Create the environment from the provided environment.yml file
conda env create -f environment.yml

# Activate the environment
conda activate plant-pathogen-transcriptomics
