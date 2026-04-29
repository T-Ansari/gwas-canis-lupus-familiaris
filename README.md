# 🧬 *Canis lupus familiaris* Genome-Wide Association Study Pipeline

![Conda](https://img.shields.io/badge/Environment-Conda-blue)
![HPC](https://img.shields.io/badge/Platform-SLURM-green)
![Language](https://img.shields.io/badge/Language-Bash%20%7C%20R-orange)

## 📖 Overview
This repository contains a reproducible bioinformatics pipeline to perform a genome-wide association study (GWAS) on *Canis lupus familiaris* sequencing data. Weight phenotype data is assessed in this workflow; however, it is still applicable to other traits. The pipeline was used to process 115 paired-end whole-genome sequencing samples from raw FASTQ files through to GWAS results and visualisation.

---
## 📚 Table of Contents
1. [Overview](#-overview)  
2. [Prerequisites](#-prerequisites)  
3. [Pipeline Workflow](#-pipeline-workflow)  
   - [1. Fastp Read Trimming](#1-fastp-read-trimming)  
   - [2. Reference Genome Indexing](#2-reference-genome-indexing)  
   - [3. Alignment and BAM Processing](#3-alignment-and-bam-processing)  
   - [4. BAM Filtering](#4-bam-filtering)  
   - [5. Variant Calling](#5-variant-calling)  
   - [6. Variant Concatenation](#6-variant-concatenation)  
   - [7. Variant Filtering](#7-variant-filtering)  
   - [8. PLINK Preparation and QC](#8-plink-preparation-and-qc)  
     - [A. Preparation](#a-preparation)  
     - [B. Missingness Analysis](#b-missingness-analysis)  
     - [C. Imputation](#c-imputation)  
     - [D. Quality Control](#d-quality-control)  
   - [9. GWAS](#9-gwas)  
   - [10. Visualisation and Further Analysis](#10-visualisation-and-further-analysis)  
4. [Output Structure](#-output-structure)
5. [Notes](#-notes)  
   - [Tools Used](#tools-used)  
6. [Acknowledgements](#-acknowledgements)  
7. [References](#-references)

---
## 🔧 Prerequisites

### Tools required
- Conda or Miniconda - [See conda documents](https://docs.conda.io/projects/conda/en/latest/index.html)
- R (4.5.2 used) - [Available Here](https://www.r-project.org/)

### Environment Creation and Installing Packages
The scripts in this repository use a number of tools listed in the [Tools Used](#tools-used) section below. 
To ensure reproducibility, a conda environment file [environment.yml](environment.yml) has been provided, with the correct versions and dependencies. 

**To create the conda environment, run:**
```{bash}
conda env create -f environment.yml
```

Alternatively, the modules can be loaded or installed individually using the version information in the [notes](#-notes) below, however you will be required to modify the scripts to accommodate this.

**For R scripts**, the `qqman` and `tidyverse` packages must be installed manually by running the following in R:
```{r}
install.packages(c("qqman", "tidyverse"))
```

### Input Data
#### 1. Sequencing Data
Paired-end whole-genome sequencing reads in compressed FASTQ format. This pipeline was developed using **115 samples**. Each sample should consist of two files:

| File | Description | Approx. Size (per sample) |
| --- | --- | --- |
| `SampleName_1.fastq.gz` | Forward reads | ~4.7–8.6 GB |
| `SampleName_2.fastq.gz` | Reverse reads | ~4.8–8.6 GB |

#### 2. Reference Genome
The *Canis lupus familiaris* reference genome assembly in compressed FASTA format (`.fna.gz`). This pipeline was designed using the `UU_Cfam_GSD_1.0` (*Canfam4*) assembly (accession *GCF_011100685.1*, size *2.5 GB*) obtained from [NCBI](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_011100685.1/).

#### 3. Phenotype file
A tab-delimited text file named `canis_phenotypes.txt` containing phenotype measurements for each sample. In this pipeline, weight was assessed per sample. The file must follow the following format:

| Column | Name | Description |
| --- | --- | --- |
| 1 | FamilyID | Family identifier |
| 2 | SampleID | Individual sample identifier matching the sample IDs in the `.fam` file [(See Step 8)](#8-plink-preparation-and-qc) |
| 3 | Phenotype | Measurement of phenotype being assessed (Weight in this pipeline) |

Example:
```
Family1  Sample1  25.4
Family2  Sample2  31.7
Family3  Sample3  8.2
```

---

## 📋 Pipeline workflow
The pipeline consists of several analysis steps, each requiring the results of the previous step. This ensures a reproducible workflow from start to finish. A diagram is available for viewing in the dropdown below. 

<details>
<summary><b>Click to view workflow diagram</b></summary>

![GWAS Pipeline Workflow](Assets/Workflow_Diagram.svg)

</details>
<br/>

The workflow begins with FASTQ files which undergo QC, trimming and alignment to a reference genome. Alignments are processed and filtered and then used to call variants which are combined across the genome and filtered to only high-quality single nucleotide polymorphisms (SNPs). The files are converted to PLINK formats and undergo QC once more before being used for GWAS analysis.

All scripts are designed to be executed on a SLURM-based high performance cluster and need to be run in the order below. Some steps require manual prep (e.g. creation of a file list), so users **must read all instructions provided** with each step before execution.

---
#### 1. Fastp Read Trimming
The first step is to process and prepare your reads. Quality control and read trimming are performed using `fastp` to remove contamination and low quality bases that may impact the alignment and further downstream analyses.

This script [01_Fastp.sh](Scripts/01_Fastp.sh) will: 
1. Create a folder called `trimmed_fastq` in the project directory.
2. Remove low quality bases
3. Remove adapter contamination sequences
4. Remove very short reads

**Before running the script:**
- Ensure FASTQ reads are in paired-end gzipped format, ending with: `_1.fastq.gz` and `_2.fastq.gz`

From the directory containing the scripts, run: 
```{bash}
ls PATH_TO_YOUR_FASTQ_FILES/*_1.fastq.gz > names.txt
```
Then:
- Ensure that the `names.txt` file exists
- Ensure the paths in `names.txt` are correct
- Ensure each `_1.fastq.gz` file has a complementary `_2.fastq.gz` file

**Then, run this script using:**
```{bash}
sbatch --array=0-$(($(wc -l < names.txt) - 1)) 01_Fastp.sh
```

Output files found in the `trimmed_fastq` folder (per sample):

| File | Description | Approx. Size (per sample) |
| --- | --- | --- |
| `*_1.trimmed.fq.gz` | Trimmed forward reads | ~4.5–8 GB |
| `*_2.trimmed.fq.gz` | Trimmed reverse reads | ~4.5–8 GB |
| `*.html` | Quality Control report | ~453 KB |
| `*.json` | Statistics summary | ~50 KB |
| `*.log` | Log output | ~1.5 KB |

---

### 2. Reference Genome Indexing
The reference genome must be uncompressed and indexed, using `bwa` and `samtools`, before it can be used for alignment and variant calling.

The script [02_Index_Reference.sh](Scripts/02_Index_Reference.sh) will:
1.  Create a new folder called `reference` in the project directory.
2.  Decompress the reference genome into the new folder
3.  Perform `BWA` indexing
4.  Perform `samtools faidx` indexing

**Before running the script:**
Edit the line `REF_GZ=PATH/TO/YOUR/REFERENCE/reference.fna.gz` in [02_Index_Reference.sh](Scripts/02_Index_Reference.sh) to point your reference genome file.

**Then, run the script with:**
```{bash}
sbatch 02_Index_Reference.sh
```

Output files, found in the `reference` folder:
| File | Description | Approx. Size |
| --- | --- | --- |
| `reference.fna` | Unzipped reference file created from the input `.fna.gz` reference file | ~2.4 GB |
| `reference.fna.amb` | BWA index file containing ambiguous base information | ~9.7 KB |
| `reference.fna.ann` | BWA index file containing sequence name annotations | ~442 KB |
| `reference.fna.bwt` | BWA index file containing transform index information | ~2.4 GB |
| `reference.fna.pac` | BWA packed DNA sequence file | ~592 MB |
| `reference.fna.sa` | BWA suffix array index file | ~1.2 GB |
| `reference.fna.fai` | Samtools FASTA index file | ~82 KB |

---

### 3. Alignment and BAM processing
The trimmed reads are aligned to the reference genome, using `BWA-MEM`, and duplicates are removed using `Picard`

The script [03_Bam_Creation.sh](Scripts/03_Bam_Creation.sh) performs several steps:
1. Creates a new folder called `bam` in the project directory
2. Aligns trimmed reads to the reference genome
3. Creates BAM files from the alignment
4. Sorts the BAM files by coordinates
5. Remove duplicate reads using Picard
6. Index the resulting BAM files

**Before running the script:**
From the directory containing the scripts, run:
```{bash}
ls ../trimmed_fastq/*_1.trimmed.fq.gz > trims.txt
```
Then:
- Ensure that the `trims.txt` file exists
- Ensure the paths in `trims.txt` are correct

**Then, run the script with:**
```{bash}
sbatch --array=0-$(($(wc -l < trims.txt) - 1)) 03_Bam_Creation.sh
```

Output files found in the `bam` folder (per sample):
| File | Description | Approx. Size (per sample) |
| --- | --- | --- |
| `*.rmd.bam` | Final BAM alignment file with duplicates removed | ~10–20 GB |
| `*.rmd.bam.bai` | BAM index file | ~5–15 MB |
| `*.metrics.txt` | Duplicate metrics from Picard | <1 MB |

---

### 4. BAM Filtering
BAM files need to be filtered to remove low-quality regions, unmapped and secondary mapped regions and retain only high-quality mapped reads using `samtools`.

The script [04_Bam_Filtering.sh](Scripts/04_Bam_Filtering.sh) performs the following steps:
1. Creates a folder called `filtered_bam` in the project directory
2. Removes unmapped reads
3. Removes secondary mapped regions
4. Remove reads with a mapping quality score below 20
5. Calculates alignment statistics 

**Before running the script:**
From the directory containing the scripts, run:
```{bash}
ls ../bam/*.bam > bam_list.txt
```
Then:
- Ensure that the `bam_list.txt` file exists

**Then, run the script with:**
```{bash}
sbatch --array=0-$(($(wc -l < bam_list.txt) - 1)) 04_Bam_Filtering.sh
```

Output files found in the `filtered_bam` folder (per sample):
| File | Description | Approx. Size (per sample) |
| --- | --- | --- |
| `*_filtered.bam` | Filtered BAM file containing the high-quality mapped reads | ~8–15 GB |
| `*_filtered.bam.bai` | Index file for filtered BAM | ~5–15 MB |
| `*_filtered_flagstats.txt` | Summary statistics of alignment after filtering | <1 KB |

---

### 5. Variant Calling
Variants are identified and called using `bcftools mpileup` and `bcftools call`.

The script [05_Variant_Calling.sh](Scripts/05_Variant_Calling.sh) performs the following steps:
1. Creates a folder called `vcf` in the project directory
2. Generates genotype likelihoods with `bcftools mpileup`
3. Calls variants using `bcftools call`, filtering on a minimum mapping quality of 30 (`--min-MQ`) and minimum base quality of 30 (`--min-BQ`)
4. Indexes each VCF file 

**Before running the script:**
From the directory containing the scripts, run:
```{bash}
ls ../filtered_bam/*.bam > filtered_bams.txt
```
Then:
- Ensure that the `filtered_bams.txt` file exists
- Ensure the paths in `filtered_bams.txt` are correct
- Create a file called `canis_chr_names.txt` containing a list of chromosomes in the reference genome, each on a new line. This can be generated from the reference index with:
```{bash}
cut -f1 ../reference/canis_reference.fna.fai > canis_chr_names.txt
```

**Then, run the script with:**
```{bash}
sbatch --array=0-$(($(wc -l < canis_chr_names.txt) - 1)) 05_Variant_Calling.sh
```

Output files found in the `vcf` folder (per chromosome):

| File | Description | Approx. Size (per chromosome) |
|---|---|---|
| `canis.CHR.vcf.gz` | Compressed VCF file for a single chromosome | ~50–200 MB |
| `canis.CHR.vcf.gz.csi` | VCF index file | <1 MB |

---

### 6. Variant Concatenation
The VCF files generated per chromosome in the previous step need to be combined into a single genome-wide variant file. To do this, `bcftools concat` is used.

The script [06_Variant_Concat.sh](Scripts/06_Variant_Concat.sh) performs the following:
- Combines all chromosome VCFs into one single dog genome VCF file
- Indexes the genome VCF file

**Before running the script:**
From the directory containing the scripts, run:
```{bash}
ls ../vcf/*.vcf.gz > vcf.list.txt
```
Then:
- Ensure that the `vcf.list.txt` file exists
- Ensure the paths in `vcf.list.txt` are correct

**Then, run the script with:**
```{bash}
sbatch 06_Variant_Concat.sh
```

Output files, found in the `vcf` folder:
| File | Description | Approx. Size |
|---|---|---|
| `canis.vcf.gz` | Combined genome-wide VCF file containing all chromosome VCF data | ~2.0 GB |
| `canis.vcf.gz.csi` | VCF Index file | <1 MB |

---

### 7. Variant Filtering
The concatenated VCF file contains all SNPs across the whole genome. Further filtering is performed to retain only high-quality SNPs. `bcftools filter` and `bcftools view` are used to remove low confidence sites and retain only biallelic SNPs.

The script [07_Variant_Filtering.sh](Scripts/07_Variant_Filtering.sh) performs the following steps:
1. Counts the number of raw variants in the concatenated VCF file
2. Filters variants to retain only those with `QUAL>=30` and `INFO/DP>=10`
3. Filters variants to retain only biallelic sites, SNPs only and true variant sites
4. Counts the number of variants remaining after quality and depth filtering
5. Indexes the final filtered VCF

**Before running the script:**
- Ensure that the concatenated VCF file `../vcf/canis.vcf.gz` exists
- Ensure the quality and depth parameters match your preferences

**Then run the script with:**
```{bash}
sbatch 07_Variant_Filtering.sh
```

Output files in `vcf` folder:
| File | Description | Approx. Size |
| --- | --- | --- |
| `canis_raw_filtered.vcf.gz` | Quality and depth filtered VCF containing biallelic SNPs only | ~6.9 GB |
| `canis_raw_filtered.vcf.gz.csi` | Index file for the filtered VCF | ~1.6 MB |
| `variant_filtering.log` | Log file containing information on the filtering script as well as statistics on the number of variants pre and post filtering | <1 MB |

---

### 8. PLINK Preparation and QC
This step addresses a number of problems that occur during a GWAS using `PLINK`. Firstly, `PLINK` requires files to be in a specific binary format for processing, so a conversion must be done from VCF files to ones that `PLINK` can handle. Then, missingness must be analysed to determine thresholds. Furthermore, quality control needs to be conducted before passing the files to `PLINK` for the GWAS.

#### A. Preparation
The script [08a_Plink_Prep.sh](Scripts/08a_Plink_Prep.sh) performs a number of steps:
1. Creates a folder called `plink` in project directory
2. Converts the filtered VCF file into .bed, .bim and .fam files.
3. Generates missingness data for the genotypes across individuals and SNPs.

**Run the script with:**
```{bash}
sbatch 08a_Plink_Prep.sh
```

Output files found in the `plink` folder:
| File | Description | Approx. Size |
| --- | --- | --- |
| `canis_raw.bed` | Binary genotype file containing SNPs | ~247 MB |
| `canis_raw.bim` | Variant information file containing chromosome, ID, position, and both alleles per SNP | ~274 MB |
| `canis_raw.fam` | Sample metadata containing family ID, sample ID, parental IDs, sex, and phenotype per individual | ~22 KB |
| `canis_missing.imiss` | Individual missingness statistics | ~26 KB |
| `canis_missing.lmiss` | SNP missingness statistics | ~417 MB |

#### B. Missingness analysis
The script [08b_Missingness.r](Scripts/08b_Missingness.r) uses the missingness statistics generated in [Part A](#a-preparation) to create histograms that can be interpreted for appropriate thresholds to be used in [Part D](#d-quality-control).

**Before running the script:**
- Ensure that the file paths point to your `.imiss` and `.lmiss` files

**Then run the script in `R` and interpret the histograms.**

**How to interpret the histograms:**
- High frequency of missingness in Samples should be removed with `--mind`
- High frequency of missingness in SNPs should be removed with `--geno`

#### C. Imputation
Due to the high levels of missing genotype data identified in [Part B](#b-missingness-analysis), filtering would result in a huge loss of variants and reduced statistical power. To overcome this, genotype imputation is performed using `Beagle`, which estimates missing genotypes.

The script [08c_Imputation.sh](Scripts/08c_Imputation.sh) performs the following steps:
1. Takes the filtered VCF file generated in [Step 7](#7-variant-filtering)
2. Runs Beagle to impute missing genotypes
3. Outputs an imputed VCF file
4. Converts the imputed VCF file into PLINK format for downstream GWAS analysis

**Before running the script:**
- Ensure the filtered VCF file exists: `../vcf/canis_raw_filtered.vcf.gz`

**Then run the script with:**
```{bash}
sbatch 08c_Imputation.sh
```

Output files found in the `plink` folder:
| File | Description | Approx. Size |
| --- | --- | --- |
| `canis_imputed.vcf.gz` | VCF file containing imputed genotypes | ~361 MB |
| `canis_imputed.vcf.gz.csi` | Index for the imputed VCF | ~1.7 MB |
| `canis_imputed.bed` | PLINK binary genotype file (imputed data) | ~250 MB |
| `canis_imputed.bim` | Variant information file | ~274 MB |
| `canis_imputed.fam` | Sample metadata file | ~22 KB |
| `*.log` | Log files from Beagle and PLINK | <1 MB |

#### D. Quality Control
The script [08d_Plink_QC.sh](Scripts/08d_Plink_QC.sh) performs quality control based on the thresholds chosen in [Part B](#b-missingness-analysis).

This includes the following:
1. Removal of individuals with high missing genotype rates (`--mind`)
2. Removal of SNPs with high missingness across samples (`--geno`)
3. Filtering of rare variants with a minor allele frequency <0.05 (`--maf`)

**Before running the script:**
 - Ensure the parameters in the script match your chosen thresholds

**Then, run the script with:**
```{bash}
sbatch 08d_Plink_QC.sh
```

Output files found in the `plink` folder:
| File | Description | Approx. Size |
| --- | --- | --- |
| `canis_qc.bed` | Filtered genotype file after QC | ~100–150 MB |
| `canis_qc.bim` | Filtered variant information | ~100–150 MB |
| `canis_qc.fam` | Filtered sample metadata | ~22 KB |
| `*.log` | PLINK log files | <1 MB |

---

### 9. GWAS
This step performs the genome-wide association study using `PLINK`, as well as a number of other steps.

The script [09_GWAS.sh](Scripts/09_GWAS.sh) performs the following steps:
1. Creates folders called `prune` and `gwas` in the project directory
2. Performs an initial GWAS that isn't corrected for population structure
3. Performs LD pruning to remove highly correlated SNPs and reduce linkage disequilibrium effects
4. Performs PCA on the pruned SNP dataset to determine population structure
5. Repeats the GWAS using the top 3 principal components as covariates

**Before running the script:**
- Ensure that the QC filtered PLINK files exist (`canis_qc.bed`, `.bim` and `.fam`)
- Ensure that the phenotypes file `canis_phenotypes.txt` exists in the same directory as the script
- Ensure that the phenotype file contains the correct sample IDs and phenotype values (Three columns in order: `FamilyID`, `SampleID`, `Phenotype`)

**Then, run the script with:**
```{bash}
sbatch 09_GWAS.sh
```

Output files found in the `gwas` and `prune` folders:
| File | Description | Approx. Size |
| --- | --- | --- |
| `gwas/gwas_canis_uncorrected.assoc.linear` | Results of the initial uncorrected GWAS | ~50–200 MB |
| `prune/prune.prune.in` | SNPs retained after LD pruning | ~5–20 MB |
| `prune/prune.prune.out` | SNPs removed during LD pruning | ~5–20 MB |
| `prune/pca20.eigenvec` | Principal component scores for each sample | <1 MB |
| `prune/pca20.eigenval` | Variance explained by each principal component | <1 KB |
| `gwas/gwas_canis_pca3.assoc.linear` | GWAS results corrected for population structure using the PCs | ~50–200 MB |
| `*.log` | PLINK log files | <1 MB |

---
### 10. Visualisation and further analysis
The final step is to visualise the results of the previous step using a Manhattan Plot, which shows the significance of each SNP's association with the phenotype across the genome.  

The Manhattan Plot shows:
- Each SNP plotted across the genome
- Significance of association between each SNP and the phenotype measured

A peak in the Manhattan plot represents SNPs in that region of the genome, with higher association for the phenotype.

The script [10_Visualisation.r](Scripts/10_Visualisation.r) performs the following steps:
1. Loads GWAS results generated by PLINK
2. Converts chromosome names into integers for plotting
3. Filters to only additive effects
4. Generates a Manhattan Plot of genome-wide association results
5. Outputs a list of the most significant SNPs for further analysis

**Before running the script:**
- Ensure the `qqman` and `tidyverse` packages are installed in R.
- Update the `FILEPATH` variable to have the path to your .assoc.linear file

**Then run the script in `R`**

Output files in the script directory:
| File | Description | Approx. Size |
| --- | --- | --- |
| `Canis_Manhattan.png` | Manhattan plot showing genome-wide SNP associations with body weight | ~1–5 MB |
| Console output | Top SNPs ranked by statistical significance (lowest p-values) | N/A |

---

## 📂 Output Structure

After running the pipeline, the project directory will have the following structure:

```
Main/
├── Scripts/
├── trimmed_fastq/        # Trimmed reads
├── reference/            # Reference genome and indexes
├── bam/                  # Sorted BAMs
├── filtered_bam/         # Quality-filtered BAMs
├── vcf/                  # Per-chromosome VCFs and genome-wide VCFs
├── plink/                # PLINK binary files and QC outputs
├── prune/                # LD-pruned SNP files and PCA outputs
└── gwas/                 # GWAS results
```

---

## 📝 Notes
The pipeline is designed to run on a SLURM-based High Performance Computing (HPC) cluster. The full list of modules used and version information is provided below.

File sizes described in this documentation are only estimates and provided as a guide, the sizes may increase or decrease dependant on the samples, reference and other factors.

### Tools Used

| Software | Version | Purpose |
| ----- | ----- | ----- |
| [BCFTools](https://github.com/samtools/bcftools) | 1.18 | Variant calling and VCF file generation |
| [Beagle](https://faculty.washington.edu/browning/beagle/beagle.html) | 5.5 | Imputation of missing genotypes |
| [BWA](https://github.com/lh3/bwa) | 0.7.17 | Alignment of sequences to reference genome | 
| [conda](https://docs.conda.io) | 25.11.1 | Environment and package management |
| [fastp](https://github.com/OpenGene/fastp) | 0.23.4 | Read trimming and quality control |
| [Picard](https://github.com/broadinstitute/picard) | 3.0.0 | Removal of duplicate reads from BAM files |
| [PLINK](https://github.com/chrchang/plink-ng) | 1.9 | Genotype filtering, quality control, PCA, and GWAS|
| [qqman](https://github.com/stephenturner/qqman) | 0.1.9 | Manhattan plot visualisation |
| [R](https://www.r-project.org/)| 4.5.2 | Statistical analysis |
| [Samtools](https://github.com/samtools/samtools) | 1.18 | BAM file processing, indexing and sorting |
| [tidyverse](https://github.com/tidyverse) | 2.0.0 | Data analysis in R |


See [References](#-references) for the full citations of the software used in this workflow.

---

## 🎉 Acknowledgements
- Tahir Ansari
- Chris Janschke
- Shahwar Nadeem
- Linghzi Li

---

## 📚 References
- Anaconda, Inc. (2024) ‘Conda’. Available at: https://docs.conda.io/.
- Browning, B.L., Zhou, Y. and Browning, S.R. (2018) ‘A One-Penny Imputed Genome from Next-Generation Reference Panels’, The American Journal of Human Genetics, 103(3), pp. 338–348. Available at: https://doi.org/10.1016/j.ajhg.2018.07.015.
- Chang, C.C. et al. (2015) ‘Second-generation PLINK: rising to the challenge of larger and richer datasets’, GigaScience, 4(1), pp. s13742-015-0047–8. Available at: https://doi.org/10.1186/s13742-015-0047-8.
- Chen, S. et al. (2018) ‘fastp: an ultra-fast all-in-one FASTQ preprocessor’, Bioinformatics, 34(17), pp. i884–i890. Available at: https://doi.org/10.1093/bioinformatics/bty560.
- Danecek, P. et al. (2021) ‘Twelve years of SAMtools and BCFtools.’, GigaScience, 10(2). Available at: https://doi.org/10.1093/gigascience/giab008.
- Li, H. (2013) ‘Aligning sequence reads, clone sequences and assembly contigs with BWA-MEM’, arXiv preprint arXiv:1303.3997 [Preprint].
- ‘Picard toolkit’ (2019) Broad Institute, GitHub repository. Broad Institute. Available at: https://broadinstitute.github.io/picard/. 
- Turner, S. (2018) ‘qqman: an R package for visualizing GWAS results using Q-Q and manhattan plots’, The Journal of Open Source Software [Preprint]. Available at: https://doi.org/10.21105/joss.00731.
- Wickham, H. et al. (2019) ‘Welcome to the tidyverse’, Journal of Open Source Software, 4(43), p. 1686. Available at: https://doi.org/10.21105/joss.01686.
