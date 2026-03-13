# LIFE4136 - *Canis lupus familiaris* Genome Wide Association Study

---

## Overview
This repository contains a reproducible bioinformatics pipeline to perform a genome wide association study (GWAS) on *Canis lupus familiaris* sequencing data. The pipeline is designed to run on a SLURM based High Performance Computing (HPC) cluster.

---

## Prerequisites

### Tools and Files required
- Paired end sequencing data (`.fastq.gz` format)
- *Canis lupus familiaris* reference genome (`.fna.gz` format)
- Conda or Miniconda installed - [See conda documents](https://docs.conda.io/projects/conda/en/latest/index.html)

### Environment Creation
The scripts in this repository use a number of tools listed in the [Modules Used](###modules-used) section below. 
To ensure reproducibility, a conda environment file [environment.yml](environment.yml) has been provided, with the correct versions and dependencies.

To create the  environment, run: `conda env create -f environment.yml`

Alternatively, the modules can be loaded or installed individually using the version information below, however you will be required to modify the scripts to accomodate this.

### Modules Used

| Software | Version | Purpose |
| ----- | ----- | ----- |
| fastp | 0.23.4 | Read trimming and quality control |
| BWA | 0.7.17 | Alignment of sequences to reference genome | 
| Samtools | 1.18 | BAM file processing, indexing and sorting |
| Picard | 3.0.0 | Removal of duplicate reads from BAM files |
| BCFTools | 1.18 | Variant calling and VCF file generation |


## Pipeline workflow
The pipeline consists of several analysis steps, that require the results of the steps before each one. 

Please ensure the conda environment has been created before attempting these steps.

### 1. Prepare Reads for Trimming

To run fastp, a text file containing a list of paths to your **forward reads** is required. These must be in **paired-end gzipped fastq format**, ending with:
- `_1.fastq.gz`
- `_2.fastq.gz`

From the directory containing the scripts, run: 
`ls "PATH_TO_YOUR_FASTQ_FILES/*_1.fastq.gz > names.txt`

Verify the file has been created before continuing. You do not need to run this for the `_2.fastq.gz` files, the scripts automatically locates the matching files.

### 2. Fastp Read Trimming

The script [1_Fastp.sh](1_Fastp.sh) performs quality control and read trimming using `fastp`.

This step removes: 
- low quality bases
- adapater contamination sequences
- very short reads

The script uses the `names.txt` file created in Step 1 to locate files to process.

Each sample will create the following:

| File | Description |
| --- | --- |
| `*_1.trimmed.fq.gz` | Trimmed forward reads |
| `*_2.trimmed.fq.gz` | Trimmed reverse reads |
| `*.html` | Quality Control report |
| `*.json` | Statistics summary |
| `*.log` | Log output |

**Before running the script:**
- Ensure that the `names.txt` file exists
- The paths in `names.txt` are correct
- Change the `--array=0-114` line in the SLURM header to match the number of lines in `names.txt`
- Ensure each `_1.fastq.gz` file has a complementary `_2.fastq.gz` file

Then, run this script using: `sbatch 1_Fastp.sh`

### 3. Reference Genome Indexing
The reference genome must be uncompressed and indexed before it can be used for alignment and variant calling.

The script [2_Index_Reference.sh](2_Index_Reference.sh) will:
- Create a new folder called `reference` in the directory containing the scripts folder.
- Unzip the reference genome into the new folder
- Perform `BWA` indexing
- Perform `samtools faidx` indexing

**Before running the script:**
Edit the line `REF_GZ=PATH/TO/YOUR/REFERENCE/reference.fna.gz` in [2_Index_Reference.sh](2_Index_Reference.sh) to point your reference genome file.

Then, run the script with: `sbatch 2_Index_Reference.sh`

### 4. Alignment and BAM processing
The script [3_Bam_Creation.sh](3_Bam_Creation.sh) aligns the trimmed reads to the reference genome using `BWA-MEM` and removes duplicates using `Picard`.

The script performs several steps:
1. Align trimmed reads to the reference genome.
2. Convert SAM files outputted by alignment to BAM files.
3. Sort the BAM files.
4. Remove duplicate reads using Picard.
5. Index the resulting BAM files.

**Before running the script:**
- From the directory containing the scripts, run:
`ls ../trimmed_fastq/*_1.trimmed.fq.gz > trims.txt`
- Ensure that the `trims.txt` file exists
- The paths in `trims.txt` are correct
- Change the `--array=0-114` line in the SLURM header to match the number of lines in `trims.txt`

Then, run the script with: `sbatch 3_Bam_Creation.sh`

### 5. Variant Calling

## Notes

## Acknowledgements
- Tahir Ansari
- Chris Janschke
- Shahwar Nadeem
- Linghzi Li