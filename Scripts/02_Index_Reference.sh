#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=8g
#SBATCH --time=01:00:00
#SBATCH --job-name=index_ref
#SBATCH --output=Logs/slurm-%x-%j.out
#SBATCH --error=Logs/slurm-%x-%j.err

set -euo pipefail

####################################################################
#                                                                  #
#        Script: Index Reference Script                            #
#                                                                  #
#        Author: Tahir Ansari                                      #
#        Date:  25 March 2026                                      #
#                                                                  #
#        Description: Decompresses and indexes the reference       #
#              genome using BWA and samtools.                      #
#              (Change REF_GZ to your reference file path)         #
#                                                                  #
####################################################################

# Load Conda Environment
source $HOME/.bash_profile
conda activate CanisGWAS

# Reference paths
REF_GZ=PATH/TO/YOUR/REFERENCE/reference.fna.gz
REF_DIR=../reference
REF="$REF_DIR/canis_reference.fna"

# Create reference directory if it doesn't exist
mkdir -p "$REF_DIR"

# Unzip reference if not already done
if [[ ! -f "$REF" ]]; then
    if [[ ! -f "$REF_GZ" ]]; then
        echo "Error: $REF_GZ not found. Please update REF_GZ with the path to your reference file." >&2
        exit 1
    fi
    echo "Unzipping reference genome"
    gzip -dc "$REF_GZ" > "$REF"
    echo "Reference unzipped to $REF"
fi

#Index reference using bwa for read alignment
bwa index "$REF"

# Index reference using samtools for variant calling
samtools faidx "$REF"

echo "Reference unzipped and indexed"

# Deactivate conda environment
conda deactivate