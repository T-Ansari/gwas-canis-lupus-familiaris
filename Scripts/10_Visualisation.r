###########################################################################################################################
#
# Script to visualise the results of GWAS analysis of Canis lupus familiaris weight data
#
###########################################################################################################################

library(qqman)
library(tidyverse)

# Read dog data into table
doggies <- read.table("dog/GWAS/gwas_dogs_weight_pca3.assoc.linear", header = TRUE)

# Function to convert chromosome names to numeric values for qqman manhattan plot
chr_to_int <- function(x, unique_chromosmes) {
  match(x, unique_chromosmes)
}

# Order by CHR and assign numeric values to chromosomes
doggies <- doggies %>% arrange(CHR)
unique_chromosmes <- c(unique(doggies$CHR))
doggies$CHR_NUM <- chr_to_int(doggies$CHR, unique_chromosmes)

# Filter for only ADD
doggies <- doggies[doggies$TEST=="ADD", ]

# Create Manhattan plot
png(file="dog/plots.png", width = 1600, height=1200)
manhattan(doggies, chr = "CHR_NUM", bp = "BP", p = "P", main = "Manhattan plot of Canis lupus familiaris weight SNPs", ylim = c(0,15), col=c("#3f97b4", "#6a6a6a"))
dev.off()

# View Highest P value points
doggies_top_P_value <- doggies %>% arrange(P)
head(doggies_top_P_value, 25)
