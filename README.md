# LIFE4136 - *Canis lupus familiaris* Genome-Wide Association Study

## Overview
This repository contains a reproducible bioinformatics pipeline to perform a genome-wide association study (GWAS) on *Canis lupus familiaris* sequencing data. 

---
## Table of Contents
1. [Overview](#overview)  
2. [Prerequisites](#prerequisites)  
3. [Pipeline Workflow](#pipeline-workflow)  
   - [1. Fastp Read Trimming](#1-fastp-read-trimming)  
   - [2. Reference Genome Indexing](#2-reference-genome-indexing)  
   - [3. Alignment and BAM Processing](#3-alignment-and-bam-processing)  
   - [4. BAM Filtering](#4-bam-filtering)  
   - [5. Variant Calling](#5-variant-calling)  
   - [6. Variant Concatenation](#6-variant-concatenation)  
   - [7. Variant Filtering](#7-variant-filtering)  
   - [8. PLINK Preparation](#8-plink-preparation)  
4. [Notes](#notes)  
   - [Modules Used](#modules-used)  
5. [Acknowledgements](#acknowledgements)  
6. [References](#references)

---
## Prerequisites

### Tools and Files required
- Paired end sequencing data (`.fastq.gz` format)
- *Canis lupus familiaris* reference genome (`.fna.gz` format)
- Conda or Miniconda installed - [See conda documents](https://docs.conda.io/projects/conda/en/latest/index.html)

### Environment Creation
The scripts in this repository use a number of tools listed in the [Modules Used](#modules-used) section below. 
To ensure reproducibility, a conda environment file [environment.yml](environment.yml) has been provided, with the correct versions and dependencies.

To create the environment, run: `conda env create -f environment.yml`

Alternatively, the modules can be loaded or installed individually using the version information in the [notes](#notes) below, however you will be required to modify the scripts to accommodate this.

---

## Pipeline workflow
The pipeline consists of several analysis steps, each requiring the results of the previous step. This ensures a reproducible workflow from start to finish. A diagram is available for viewing in the dropdown below. 

The workflow begins with FASTQ files which undergo QC, trimming and alignment to a reference genome. Alignments are processed and filtered and then used to call variants which are combined across the genome and filtered to only high-quality single nucleotide polymorphisms (SNPs). The files are converted to PLINK formats and undergo QC once more before being used for GWAS analysis.

All scripts are designed to be executed on a SLURM-based high performance cluster and need to be run in the order below. Some steps require manual prep (e.g. creation of a file list), so users **must read all instructions provided** with each step before execution.

<details>
<summary><b>Click to view workflow diagram</b></summary>

![GWAS Pipeline Workflow](Assets/R3.svg)

</details>

---
#### 1. Fastp Read Trimming
The first step is to process and prepare your reads. Quality control and read trimming is performed using `fastp` to remove contamination and low quality bases that may impact the alignment and further downstream analyses.

This script [1_Fastp.sh](1_Fastp.sh) will: 
1. Create a folder called `trimmed_fastq` in the project directory.
2. Remove low quality bases
3. Remove adapter contamination sequences
4. Remove very short reads

**Before running the script:**
- Ensure FASTQ reads are in paired-end gzipped format, ending with: `_1.fastq.gz` and `_2.fastq.gz`
- From the directory containing the scripts, run: 
`ls PATH_TO_YOUR_FASTQ_FILES/*_1.fastq.gz > names.txt`
- Ensure that the `names.txt` file exists
- Ensure the paths in `names.txt` are correct
- Change the `--array=0-114` line in the SLURM header to match the number of lines in `names.txt`
- Ensure each `_1.fastq.gz` file has a complementary `_2.fastq.gz` file

Then, run this script using: `sbatch 1_Fastp.sh`

Output files found in the `trimmed_fastq` folder (per sample):

| File | Description |
| --- | --- |
| `*_1.trimmed.fq.gz` | Trimmed forward reads |
| `*_2.trimmed.fq.gz` | Trimmed reverse reads |
| `*.html` | Quality Control report |
| `*.json` | Statistics summary |
| `*.log` | Log output |

---

### 2. Reference Genome Indexing
The reference genome must be uncompressed and indexed, using `bwa` and `samtools`, before it can be used for alignment and variant calling.

The script [2_Index_Reference.sh](2_Index_Reference.sh) will:
1.  Create a new folder called `reference` in the project directory.
2.  Decompress the reference genome into the new folder
3.  Perform `BWA` indexing
4.  Perform `samtools faidx` indexing

**Before running the script:**
Edit the line `REF_GZ=PATH/TO/YOUR/REFERENCE/reference.fna.gz` in [2_Index_Reference.sh](2_Index_Reference.sh) to point your reference genome file.

Then, run the script with: `sbatch 2_Index_Reference.sh`

Output files, found in the `reference` folder:
| File | Description |
| --- | --- |
| `reference.fna` | Unzipped reference file created from the input `.fna.gz` reference file |
| `reference.fna.amb` | BWA index file containing ambiguous base information |
| `reference.fna.bwt` | BWA index file containing transform index information |
| `reference.fna.pac` | BWA packed DNA sequence file |
| `reference.fna.sa` | BWA suffix array index file |
| `reference.fna.fai` | Samtools FASTA index file |

---

### 3. Alignment and BAM processing
The trimmed reads are aligned to the reference genome, using `BWA-MEM`, and duplicates removed using `Picard`

The script [3_Bam_Creation.sh](3_Bam_Creation.sh) performs several steps:
1. Creates a new folder called `bam` in the project directory
2. Aligns trimmed reads to the reference genome
3. Convert SAM files generated by alignment into BAM format
4. Sorts the BAM files by coordinates
5. Remove duplicate reads using Picard
6. Index the resulting BAM files

**Before running the script:**
- From the directory containing the scripts, run:
`ls ../trimmed_fastq/*_1.trimmed.fq.gz > trims.txt`
- Ensure that the `trims.txt` file exists
- Ensure the paths in `trims.txt` are correct
- Change the `--array=0-114` line in the SLURM header to match the number of lines in `trims.txt`

Then, run the script with: `sbatch 3_Bam_Creation.sh`

Output files found in the `bam` folder (per sample):
| File | Description |
| --- | --- |
| `*.rmd.bam` | Final BAM alignment file with duplicates removed |
| `*.rmd.bam.bai` | BAM index file |
| `*.metrics.txt` | Duplicate metrics from Picard |

---

### 4. BAM Filtering
BAM files need to be filtered to remove low quality regions, unmapped and secondary mapped regions and retain only high-quality mapped reads using `samtools`.

The script [4_Bam_Filtering.sh](4_Bam_Filtering.sh) performs the following steps:
1. Creates a folder called `filtered_bam` in the project directory
2. Removes unmapped reads
3. Removes secondary mapped regions
4. Remove reads with a mapping quality score below 20
5. Calculates alignment statistics 

**Before running the script:**
- From the directory containing the scripts, run:
`ls ../bam/*.bam > bam_list.txt`
- Ensure that the `bam_list.txt` file exists
- Change the `--array=0-100` line in the SLURM header to match the **number of BAMs** in `bam_list.txt`

Output files found in the `filtered_bam` folder (per sample):
| File | Description |
| --- | --- |
| `*_filtered.bam` | Filtered BAM file containing the high-quality mapped reads |
| `*_filtered.bam.bai` | Index file for filtered BAM |
| `*_filtered_flagstats.txt` | Summary statistics of alignment after filtering |

---

### 5. Variant Calling
Variants are identified and called using `bcftools mpileup` and `bcftools call`.

The script [5_Variant_Calling.sh](5_Variant_Calling.sh) performs the following steps:
1. Creates a folder called `vcf` in the project directory
2. Generates genotype likelihoods with `bcftools mpileup`
3. Calls variants, on reads with a minimum quality of 30, using `bcftools call`
4. Indexes each VCF file 

**Before running the script:**
- From the directory containing the scripts, run:
`ls ../filtered_bam/*.bam > filtered_bams.txt`
- Ensure that the `filtered_bams.txt` file exists
- Ensure the paths in `filtered_bams.txt` are correct
- Create a file called `dog_chr_names.txt` containing a list of chromosomes in the reference genome, each on a new line (e.g. NC_049222.1)
- Change the `--array=0-37` line in the SLURM header to match the **number of chromosomes** in `dog_chr_names.txt`

Then, run the script with: `sbatch 5_Variant_Calling.sh`

Output files found in the `vcf` folder (per chromosome):

| File | Description |
|---|---|
| `dog.CHR.vcf.gz` | Compressed VCF file for a single chromosome|
| `dog.CHR.vcf.gz.csi` | VCF index file |

---

### 6. Variant Concatenation
The VCF files generated per chromosome in the previous step need to be combined into one whole variant file across the whole genome. To do this, `bcftools concat` is used.

The script [6_Variant_Concat.sh](6_Variant_Concat.sh) performs the following:
- Combines all chromosome VCFs into one single dog genome VCF file
- Indexes the genome VCF file

**Before running the script:**
- From the directory containing the scripts, run:
`ls ../vcf/*.vcf.gz > vcf.list.txt`
- Ensure that the `vcf.list.txt` file exists
- Ensure the paths in `vcf.list.txt` are correct

Then, run the script with: `sbatch 6_Variant_Concat.sh`

Output files, found in the `vcf` folder:
| File | Description |
|---|---|
| `dog.vcf.gz` | Combined genome-wide VCF file containing all chromosome VCF data |
| `dog.vcf.gz.csi` | VCF Index file |

---

### 7. Variant Filtering
The concatenated VCF file contains all SNPs across the whole genome. Further filtering is performed to retain only high-quality SNPs. `bcftools filter` and `bcftools view` are used to remove low confidence sites and retain only biallelic SNPs.

The script [7_Variant_Filtering.sh](7_Variant_Filtering.sh) performs the following steps:
1. Counts the number of raw variants in the concatenated VCF file
2. Filters variants to retain only those with `QUAL>=30` and `INFO/DP>=10`
3. Filters variants to retain only biallelic sites, SNPs only and true variant sites
4. Counts the number of variants remaining after quality and depth filtering
5. Indexes the final filtered VCF

**Before running the script:**
- Ensure that the concatenated VCF file `../vcf/dog.vcf.gz` exists
- Ensure the quality and depth parameters match your preferences

Then run the script with: `sbatch 7_Variant_Filtering.sh`


Output files in `vcf` folder:
| File | Description |
| --- | --- |
| `dog_raw_filtered.vcf.gz` | Filtered raw vcf file |
| `dog_raw_filtered.vcf.gz.csi` | Index file for above filtered vcf file|
| `variant_filtering.log` | Log file containing information on the filtering script as well statistics on the number of variants pre and post filtering |

---

### 8. PLINK Preparation
`PLINK` requires files to be in a specific binary format for processing, so a conversion must be done from VCF files to ones that PLINK can handle. Furthermore, some quality control needs to be conducted before parsing the files to PLINK for the GWAS.

The script [8_Plink_Prep.sh](8_Plink_Prep.sh) performs a number of steps:
1. Creates a folder called `plink` in project directory
2. Converts the filtered VCF file into .bed, .bim and .fam files.
3. Generates missingness data for the genotypes across individuals and SNPs.

Output files found in the `plink` folder:
| File | Description |
| --- | --- |
| `dog_raw.bed` | Binary genotype file containing SNPs |
| `dog_raw.bim`| Variant information file |
| `dog_raw.fam` | Metadata containing IDs, phenotype data etc. |
| `dog_missing.imiss` | Individual missingness statistics |
| `dog_missing.lmiss` | SNP missingness statistics |

---

## Notes
The pipeline is designed to run on a SLURM based High Performance Computing (HPC) cluster. The full list of modules used and version information is provided below.

### Tools and Modules Used

| Software | Version | Purpose |
| ----- | ----- | ----- |
| [conda](https://docs.conda.io) | 25.11.1 | Environment and package management |
| [fastp](https://github.com/OpenGene/fastp) | 0.23.4 | Read trimming and quality control |
| [BWA](https://github.com/lh3/bwa) | 0.7.17 | Alignment of sequences to reference genome | 
| [Samtools](https://github.com/samtools/samtools) | 1.18 | BAM file processing, indexing and sorting |
| [Picard](https://github.com/broadinstitute/picard) | 3.0.0 | Removal of duplicate reads from BAM files |
| [BCFTools](https://github.com/samtools/bcftools) | 1.18 | Variant calling and VCF file generation |
| [PLINK](https://github.com/chrchang/plink-ng) | 2.0 | Genotype filtering and quality control |

See [References](#references) for the full citations of the software used in this workflow.

---

## Acknowledgements
- Tahir Ansari
- Chris Janschke
- Shahwar Nadeem
- Linghzi Li

---

## References
- Anaconda, Inc. (2024) ‘Conda’. Available at: https://docs.conda.io/.
- Chang, C.C. et al. (2015) ‘Second-generation PLINK: rising to the challenge of larger and richer datasets’, GigaScience, 4(1), pp. s13742-015-0047–8. Available at: https://doi.org/10.1186/s13742-015-0047-8.
- Chen, S. et al. (2018) ‘fastp: an ultra-fast all-in-one FASTQ preprocessor’, Bioinformatics, 34(17), pp. i884–i890. Available at: https://doi.org/10.1093/bioinformatics/bty560.
- Danecek, P. et al. (2021) ‘Twelve years of SAMtools and BCFtools.’, GigaScience, 10(2). Available at: https://doi.org/10.1093/gigascience/giab008.
- Li, H. (2013) ‘Aligning sequence reads, clone sequences and assembly contigs with BWA-MEM’, arXiv preprint arXiv:1303.3997 [Preprint].
- ‘Picard toolkit’ (2019) Broad Institute, GitHub repository. Broad Institute. Available at: https://broadinstitute.github.io/picard/.