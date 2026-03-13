#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=8g
#SBATCH --time=01:00:00
#SBATCH --job-name=index_ref
#SBATCH --output=index_ref.out
#SBATCH --error=index_ref.err

# Load Conda Environment
source $HOME/.bash_profile
conda activate CanisGWAS

# Reference paths
REF_GZ=PATH/TO/YOUR/REFERENCE/reference.fna.gz
REF_DIR=../reference
REF="$REF_DIR/reference.fna"

# Create reference directory if it doesn't exist
mkdir -p "$REF_DIR"

# Unzip reference
gzip -dc "$REF_GZ" > "$REF"

#Index reference using bwa for read alignment
bwa index "$REF"

# Index reference using samtools for variant calling
samtools faidx "$REF"

echo "Reference unzipped and indexed"
