########################################
#    Script to calculate missingness   #
########################################

# Load files
imiss <- read.table("dog/dog_missing.imiss", header=TRUE)
lmiss <- read.table("dog/dog_missing.lmiss", header=TRUE)

fam_file <- read.table("dog/dog_raw.fam", header=FALSE)

# Plot histograms of missingness
hist(imiss$F_MISS, breaks=20, main = "Sample missingness", xlab = "Proportion of missing genotypes", ylab = "Frequency")
hist(lmiss$F_MISS, breaks=20, main = "SNP missingness", xlab = "Proportion of missing genotypes", ylab = "Frequency")

length(imiss$F_MISS)

head(fam_file)
