#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=40g
#SBATCH --time=1:00:00
#SBATCH --job-name=filter_bams
#SBATCH --output=Logs/slurm-%x-%j.out
#SBATCH --error=Logs/slurm-%x-%j.err

set -euo pipefail

# Activate conda environment
source $HOME/.bash_profile
conda activate CanisGWAS

# Load sample names into an array if exists
if [[ -f bam_list.txt ]]; then
    mapfile -t FILES < bam_list.txt
else
    echo "bam_list.txt not found. Please create it with: ls ../bam/*.bam > bam_list.txt" &>2
    exit 1
fi

# Get the current sample name based on SLURM_ARRAY_TASK_ID
SAMPLE=${FILES[$SLURM_ARRAY_TASK_ID]}

# Define input files
FILE=${SAMPLE}

# Output directory
OUTDIR=../filtered_bam/
mkdir -p "$OUTDIR"

# Perform Filtering
# -F removes unmapped, secondary mapped, supplementary mapped 
# -f includes properly paired	
# -q 20 is min mapq 20 
samtools view \
--threads 8 \
-F 0x904 \
-f 0x2 \
-q 20 \
-b \
-o $OUTDIR/${SAMPLE}_filtered.bam \
$FILE

# Index BAM
samtools index $OUTDIR/${SAMPLE}_filtered.bam

# Calculate alignment statistics post-filter
samtools flagstat $OUTDIR/${SAMPLE}_filtered.bam > $OUTDIR/${SAMPLE}_filtered_flagstats.txt

# Deactivate conda environment
conda deactivate