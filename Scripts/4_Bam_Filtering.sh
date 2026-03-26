#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=40g
#SBATCH --time=1:00:00
#SBATCH --job-name=filter_bams
#SBATCH --output=/share/BioinfMSc/life4136_2526/rotation3/group1/CJ/results/logs/slurm/filter_bam/slurm-%x-%j.out
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mbxcj2@exmail.nottingham.ac.uk
#SBATCH --array=0-100


# Source bash profile to enable conda
source $HOME/.bash_profile

# Activate conda environment
conda activate CanisGWAS

# Create bamlist file
#ls ../bam/*.bam > bam_list.txt

# Load sample names into an array
mapfile -t ROOTS < bam_list.txt

# Get the current sample name based on SLURM_ARRAY_TASK_ID
SAMPLE=${ROOTS[$SLURM_ARRAY_TASK_ID]}

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