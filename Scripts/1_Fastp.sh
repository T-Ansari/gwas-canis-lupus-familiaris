#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=80g
#SBATCH --time=10:00:00
#SBATCH --job-name=fastp
#SBATCH --output=Logs/slurm-%x-%j.out
#SBATCH --error=Logs/slurm-%x-%j.err

set -euo pipefail

# Load Conda Environment
source $HOME/.bash_profile
conda activate CanisGWAS

# Setting fastq file location
FASTQDIR=PATH/TO/YOUR/FASTQ_FILES
OUTDIR=../trimmed_fastq
mkdir -p "$OUTDIR"

# Load file list if exists
if [[ -f names.txt ]]; then
    mapfile -t FILES < names.txt
else
    echo "names.txt not found. Please create it with: ls PATH/TO/YOUR/FASTQ_FILES/*_1.fastq.gz > names.txt" &>2
    exit 1
fi

# Selecting files
FILE=${FILES[$SLURM_ARRAY_TASK_ID]}
SAMPLE=$(basename "$FILE" _1.fastq.gz)
SAMPLE1="$FASTQDIR/${SAMPLE}_1.fastq.gz"
SAMPLE2="$FASTQDIR/${SAMPLE}_2.fastq.gz"

# Check if Fastq samples found successfully
if [[ ! -f "$SAMPLE1" ]] || [[ ! -f "$SAMPLE2" ]]; then
    echo "Error: FASTQs not found for $SAMPLE in $FASTQDIR." >&2
    exit 1
fi

# Running FASTP
fastp \
 --in1 "$SAMPLE1" \
 --in2 "$SAMPLE2" \
 --out1 "$OUTDIR/${SAMPLE}_1.trimmed.fq.gz" \
 --out2 "$OUTDIR/${SAMPLE}_2.trimmed.fq.gz" \
 --thread "$SLURM_CPUS_PER_TASK" \
 -l 50 \
 -h "$OUTDIR/${SAMPLE}.html" \
 -j "$OUTDIR/${SAMPLE}.json" \
 &> "$OUTDIR/${SAMPLE}.log"

echo "Finished fastp for $SAMPLE"

# Deactivate conda environment
conda deactivate