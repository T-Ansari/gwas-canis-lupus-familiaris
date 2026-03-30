#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64g
#SBATCH --time=01:00:00
#SBATCH --job-name=imputation
#SBATCH --output=Logs/slurm-%x-%j.out
#SBATCH --error=Logs/slurm-%x-%j.err

source $HOME/.bash_profile
conda activate CanisGWAS

# Input VCF
VCF=../vcf/canis_raw_filtered.vcf.gz

# Output prefix
OUT=../plink/canis_imputed

# Run Beagle
java -Xmx30g -jar ./beagle.jar \
 gt=$VCF \
 out=$OUT \
 nthreads=$SLURM_CPUS_PER_TASK

# Convert imputed VCF to PLINK format
plink --vcf ../plink/canis_imputed.vcf.gz \
 --double-id \
 --allow-extra-chr \
 --make-bed \
 --out ../plink/canis_imputed

conda deactivate