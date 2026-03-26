#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=80g
#SBATCH --time=10:00:00
#SBATCH --job-name=fastp
#SBATCH --output=/share/BioinfMSc/life4136_2526/rotation3/group1/TA/Scripts/Logs/slurm-%x-%j.out
#SBATCH --error=/share/BioinfMSc/life4136_2526/rotation3/group1/TA/Scripts/Logs/slurm-%x-%j.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mbxta9@nottingham.ac.uk
#SBATCH --array=0-114

# Load Conda Environment
source $HOME/.bash_profile
conda activate CanisGWAS

# Set current directory to script location (for relative paths)
#cd "$(dirname "$0")"

# Setting fastq file location
FASTQDIR=PATH/TO/YOUR/FASTQ_FILES
OUTDIR=../trimmed_fastq
mkdir -p "$OUTDIR"

# Create list of fastq files (Run once before script)
#ls PATH/TO/YOUR/FASTQ_FILES/*_1.fastq.gz > names.txt

# Load file list
mapfile -t FILES < names.txt

# Selecting files
FILE=${FILES[$SLURM_ARRAY_TASK_ID]}
SAMPLE=$(basename "$FILE" _1.fastq.gz)

# Running FASTP
fastp \
 --in1 "$FASTQDIR/${SAMPLE}_1.fastq.gz" \
 --in2 "$FASTQDIR/${SAMPLE}_2.fastq.gz" \
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