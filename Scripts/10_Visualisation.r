####################################################################
#                                                                  #
#        Title: GWAS Visualisation                                 #
#                                                                  #
#        Author: Tahir Ansari                                      #
#        Date:  25 March 2026                                      #
#                                                                  #
#        Description: Script for visualising GWAS results          #
#                                                                  #
#                                                                  #
####################################################################

#rm(list=ls())
library(qqman)
library(tidyverse)

# Set filepath to your data file
FILEPATH <- "PATH/TO/YOUR/FILE/gwas_dogs_weight_pca3.assoc.linear"

# Read dog data into table - replace with your path to the file
canis_dataset <- read.table(FILEPATH, header = TRUE)

# Function to convert chromosome names to numeric values for qqman manhattan plot
chr_to_int <- function(x, unique_chromosmes) {
  match(x, unique_chromosmes)
}

# Order by CHR and assign numeric values to chromosomes
canis_dataset <- canis_dataset %>% arrange(CHR)
unique_chromosmes <- c(unique(canis_dataset$CHR))
canis_dataset$CHR_NUM <- chr_to_int(canis_dataset$CHR, unique_chromosmes)

# Filter for only ADD
canis_dataset <- canis_dataset[canis_dataset$TEST=="ADD", ]

# Create Manhattan plot
png(file="Canis_Manhattan.png", width = 1600, height=1200)
manhattan(canis_dataset, chr = "CHR_NUM", bp = "BP", p = "P", main = "Genome-wide Association Analysis of Body Weight in Canis lupus familiaris", ylim = c(0,15), col=c("#3f97b4", "#6a6a6a"))
dev.off()

# View Highest P value points
canis_dataset_top_P_value <- canis_dataset %>% arrange(P)
head(canis_dataset_top_P_value, 25)
