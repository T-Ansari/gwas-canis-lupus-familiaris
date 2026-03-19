##########
# Script to calculate missingness 
##########

# Load files
imiss <- read.table("dog/dog_missing.imiss", header=TRUE)
lmiss <- read.table("dog/dog_missing.lmiss", header=TRUE)

# Plot histograms of missingness
hist(imiss$F_MISS, breaks=20, main = "Sample missingness", xlab = "Proportion of missing genotypes", ylab = "Frequency")
hist(lmiss$F_MISS, breaks=20, main = "SNP missingness", xlab = "Proportion of missing genotypes", ylab = "Frequency")

length(imiss$F_MISS)