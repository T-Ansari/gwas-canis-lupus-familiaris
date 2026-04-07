#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32g
#SBATCH --time=10:00:00
#SBATCH --job-name=makebam
#SBATCH --output=Logs/slurm-%x-%j.out
#SBATCH --error=Logs/slurm-%x-%j.err

set -euo pipefail

# Load Conda Environment
source $HOME/.bash_profile
conda activate CanisGWAS

# Setting file locations
REF=../reference/canis_reference.fna
TRIMDIR=../trimmed_fastq
BAMDIR=../bam
mkdir -p "$BAMDIR"

# Check for reference file
if [[ ! -f "$REF" ]]; then
    echo "Error: $REF not found. Run previous steps first." >&2
    exit 1
fi

# Load file list if exists
if [[ -f trims.txt ]]; then
    mapfile -t FILES < trims.txt
else
    echo "trims.txt not found. Please create it with: ls ../trimmed_fastq/*_1.trimmed.fq.gz > trims.txt" &>2
    exit 1
fi

# Selecting files
FILE=${FILES[$SLURM_ARRAY_TASK_ID]}
SAMPLE=$(basename "$FILE" _1.trimmed.fq.gz)
FILE1="$TRIMDIR/${SAMPLE}_1.trimmed.fq.gz"
FILE2="$TRIMDIR/${SAMPLE}_2.trimmed.fq.gz"
SORTBAM="$BAMDIR/${SAMPLE}.sort.bam"
RMDBAM="$BAMDIR/${SAMPLE}.rmd.bam"
METRICS="$BAMDIR/${SAMPLE}.metrics.txt"

# Check both sample fastqs exist
if [[ ! -f "$FILE1" ]] || [[ ! -f "$FILE2" ]]; then
    echo "Error: trimmed FASTQs not found for $SAMPLE. Run step 1 first." >&2
    exit 1
fi

# Running Alignment and sorting
bwa mem \
 -M \
 -t "$SLURM_CPUS_PER_TASK" \
 "$REF" \
 "$FILE1" \
 "$FILE2" | \
samtools view -b | \
samtools sort -T "$SAMPLE" -o "$SORTBAM"

# Remove duplicates
java -Xmx1g -jar "$EBROOTPICARD/picard.jar" \
MarkDuplicates REMOVE_DUPLICATES=true \
ASSUME_SORTED=true \
VALIDATION_STRINGENCY=SILENT \
MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=1000 \
INPUT="$SORTBAM" \
OUTPUT="$RMDBAM" \
METRICS_FILE="$METRICS"

# Index BAM file
samtools index "$RMDBAM"

# Remove extra files
rm "$SORTBAM"

echo "Finished BAM processing for $SAMPLE"

# Deactivate conda environment
conda deactivate