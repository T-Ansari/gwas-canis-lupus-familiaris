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
#SBATCH --array=0-114

# Load Conda Environment
source $HOME/.bash_profile
conda activate CanisGWAS

# Setting file locations
REF=../reference/canis_reference.fna
TRIMDIR=../trimmed_fastq
BAMDIR=../bam
mkdir -p "$BAMDIR"

# Create list of fastq files (Run once before script)
#ls "$TRIMDIR"/*_1.trimmed.fq.gz > trims.txt

# Load file list
mapfile -t FILES < trims.txt

# Selecting files
FILE=${FILES[$SLURM_ARRAY_TASK_ID]}
SAMPLE=$(basename "$FILE" _1.trimmed.fq.gz)
FILE1="$TRIMDIR/${SAMPLE}_1.trimmed.fq.gz"
FILE2="$TRIMDIR/${SAMPLE}_2.trimmed.fq.gz"
SORTBAM="$BAMDIR/${SAMPLE}.sort.bam"
RMDBAM="$BAMDIR/${SAMPLE}.rmd.bam"
METRICS="$BAMDIR/${SAMPLE}.metrics.txt"

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