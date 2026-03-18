# LIFE4136 - *Canis lupus familiaris* Genome Wide Association Study

## Overview
This repository contains a reproducible bioinformatics pipeline to perform a genome wide association study (GWAS) on *Canis lupus familiaris* sequencing data. 

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
| [fastp](https://github.com/OpenGene/fastp) | 0.23.4 | Read trimming and quality control |
| [BWA](https://github.com/lh3/bwa) | 0.7.17 | Alignment of sequences to reference genome | 
| [Samtools](https://github.com/samtools/samtools) | 1.18 | BAM file processing, indexing and sorting |
| [Picard](https://github.com/broadinstitute/picard) | 3.0.0 | Removal of duplicate reads from BAM files |
| [BCFTools](https://github.com/samtools/bcftools) | 1.18 | Variant calling and VCF file generation |

---

## Pipeline workflow
The pipeline consists of several analysis steps, that require the results of the steps before each one. 

Please ensure the conda environment has been created before attempting these steps.


### 1. Fastp Read Trimming
Quality control and read trimming is performed using `fastp` to remove contamination and low quality bases that may impact the alignment and further downstream analyses.

This script [1_Fastp.sh](1_Fastp.sh) removes: 
- low quality bases
- adapater contamination sequences
- very short reads

**Before running the script:**
- Ensure fastq reads are in paired-end gzipped fastq format, ending with: `_1.fastq.gz` and `_2.fastq.gz`
- From the directory containing the scripts, run: 
`ls "PATH_TO_YOUR_FASTQ_FILES/*_1.fastq.gz > names.txt`
- Ensure that the `names.txt` file exists
- Ensure the paths in `names.txt` are correct
- Change the `--array=0-114` line in the SLURM header to match the number of lines in `names.txt`
- Ensure each `_1.fastq.gz` file has a complementary `_2.fastq.gz` file

Then, run this script using: `sbatch 1_Fastp.sh`

Output files for each sample:

| File | Description |
| --- | --- |
| `*_1.trimmed.fq.gz` | Trimmed forward reads |
| `*_2.trimmed.fq.gz` | Trimmed reverse reads |
| `*.html` | Quality Control report |
| `*.json` | Statistics summary |
| `*.log` | Log output |

### 2. Reference Genome Indexing
The reference genome must be uncompressed and indexed before it can be used for alignment and variant calling.

The script [2_Index_Reference.sh](2_Index_Reference.sh) will:
- Create a new folder called `reference` in the directory containing the scripts folder.
- Unzip the reference genome into the new folder
- Perform `BWA` indexing
- Perform `samtools faidx` indexing

**Before running the script:**
Edit the line `REF_GZ=PATH/TO/YOUR/REFERENCE/reference.fna.gz` in [2_Index_Reference.sh](2_Index_Reference.sh) to point your reference genome file.

Then, run the script with: `sbatch 2_Index_Reference.sh`

### 3. Alignment and BAM processing
The trimmed reads are alined to the reference genome using `BWA-MEM` and duplicates removed using `Picard`

The script [3_Bam_Creation.sh](3_Bam_Creation.sh) performs several steps:
1. Align trimmed reads to the reference genome.
2. Convert SAM files outputted by alignment to BAM files.
3. Sort the BAM files.
4. Remove duplicate reads using Picard.
5. Index the resulting BAM files.

**Before running the script:**
- From the directory containing the scripts, run:
`ls ../trimmed_fastq/*_1.trimmed.fq.gz > trims.txt`
- Ensure that the `trims.txt` file exists
- Ensure the paths in `trims.txt` are correct
- Change the `--array=0-114` line in the SLURM header to match the number of lines in `trims.txt`

Then, run the script with: `sbatch 3_Bam_Creation.sh`

### 4. BAM Filtering
BAM files need to be filtered to remove low quality regions, unmapped and secondary mapped regions

The script [4_Bam_Filtering.sh](4_Bam_Filtering.sh) performs the following steps:
1. Removes unmapped regions
2. Removes secondary mapped regions
3. Remove anything with a quality score below 20

**Before running the script:**
- From the directory containing the scripts, run:
`ls ../bam/*.bam > bam_list.txt`
- Ensure that the `filtered_bams.txt` file exists
- Change the `--array=0-100` line in the SLURM header to match the **number of BAMs** in `bam_list.txt`


### 5. Variant Calling
Variants are identified and called using `bcftools mpileup` and `bcftools call`.

The script [5_Variant_Calling.sh](5_Variant_Calling.sh) performs the following steps:
1. Pileup generation
2. Variant and SNP detection
3. Indexing of VCF output files

**Before running the script:**
- From the directory containing the scripts, run:
`ls ../filtered_bam/*.bam > filtered_bams.txt`
- Ensure that the `filtered_bams.txt` file exists
- Ensure the paths in `filtered_bams.txt` are correct
- Create a file called `dog_chr_names.txt` containing a list of chromosomes in the reference genome.
- Change the `--array=0-37` line in the SLURM header to match the **number of chromosomes** in `dog_chr_names.txt`

Then, run the script with: `sbatch 5_Variant_Calling.sh`

Output files per chromosome:

| File | Description |
|---|---|
| `.vcf.gz` | Compressed variant call file |
| `.vcf.gz.csi` | VCF index file |

### 6. Variant Concatenation
The VCF files generated per chromosome in the previous step need to be combined into one who variant file across the whole genome. To do this, `bcftools concat` is used.

The script `


### 7. Variant Filtering


## Notes
The pipeline is designed to run on a SLURM based High Performance Computing (HPC) cluster.

## Acknowledgements
- Tahir Ansari
- Chris Janschke
- Shahwar Nadeem
- Linghzi Li

## References
- 