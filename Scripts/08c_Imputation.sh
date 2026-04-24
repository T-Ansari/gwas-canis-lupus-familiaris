#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64g
#SBATCH --time=01:00:00
#SBATCH --job-name=imputation
#SBATCH --output=Logs/slurm-%x-%j.out
#SBATCH --error=Logs/slurm-%x-%j.err


####################################################################
#                                                                  #
#        Script: Imputation Script                                 #
#                                                                  #
#        Author: Tahir Ansari                                      #
#        Date:  25 March 2026                                      #
#                                                                  #
#        Description: Imputes missing genotypes using Beagle       #
#              and converts the imputed VCF to PLINK               #
#              binary format for downstream GWAS analysis.         #
#                                                                  #
####################################################################

# Load Conda Environment
source $HOME/.bash_profile
conda activate CanisGWAS
set -euo pipefail

# Set Variables
VCF=../vcf/canis_raw_filtered.vcf.gz
OUT=../plink/canis_imputed

if [[ ! -f "$VCF" ]]; then
    echo "Error: $VCF not found. Run previous steps first." >&2
    exit 1
fi

# Run Beagle
export _JAVA_OPTIONS="-Xmx56g"
beagle \
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