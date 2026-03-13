#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64g
#SBATCH --time=10:00:00
#SBATCH --job-name=vcf_call
#SBATCH --output=/share/BioinfMSc/life4136_2526/rotation3/group1/TA/Scripts/Logs/slurm-%x-%j.out
#SBATCH --error=/share/BioinfMSc/life4136_2526/rotation3/group1/TA/Scripts/Logs/slurm-%x-%j.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mbxta9@nottingham.ac.uk
#SBATCH --array=0-38

# Load Conda Environment
source $HOME/.bash_profile
conda activate CanisGWAS

set -euo pipefail

# Set current directory to script location (for relative paths)
#cd "$(dirname "$0")"

#Create list of bam files
#ls ../bam/*.rmd.bam > bam_list.txt

# Setting file locations
REF=/share/BioinfMSc/life4136_2526/rotation3/group1/TA/reference/reference.fna
VCFDIR=../vcf
BAMLIST=bamlist.txt

mkdir -p "$VCFDIR"

# Create list of fastq files (Run once before script)
#ls "$TRIMDIR"/*_1.trimmed.fq.gz > names.txt

# Load Chromosome names
mapfile -t CHRS < dog_chr_names.txt
CHR=${CHRS[$SLURM_ARRAY_TASK_ID]}

# Output file
OUTFILE="$VCFDIR/dog.${CHR}.vcf.gz"

# Running mpileup and variant calling
bcftools mpileup \
 --threads "$SLURM_CPUS_PER_TASK" \
 -Ou \
 -f "$REF" \
 --min-MQ 30 \
 --min-BQ 30 \
 --annotate FORMAT/DP,FORMAT/AD \
 --bam-list "$BAMLIST" \
 -r "$CHR" | \
bcftools call \
 --threads "$SLURM_CPUS_PER_TASK" \
 -m \
 -v \
 -Oz \
 -o "$OUTFILE"

# Index VCF
bcftools index "$OUTFILE"

echo "Finished Variant Calling for $CHR"

