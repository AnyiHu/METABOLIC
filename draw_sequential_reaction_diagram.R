# Author ---------------------------
# Patricia Tran
# Oct 2019. Updated May 10, 2020

# Purpose ---------------------------
# this bar plot shows the combo of reactions among taxa. For example, the full oxidation or reduction of some compounds is a multi-step proccess. How many organsisms can do how many of the steps?

# Receive arguments from command line ---------------------------
userprefs <- commandArgs(trailingOnly = TRUE)
R_input_1 <- userprefs[1] # Path to to R_hm_input_1.txt
R_input_2 <- userprefs[2] # Path to to R_hm_input_2.txt
Sequential_info <- userprefs[3] # Path to sequential information file sequential-transformations.tsv
order_input1 <- userprefs[4] # Path to order_of_input_01.txt
order_input2 <- userprefs[5] # Path to order_of_input_02.txt
plots.folder.path <- userprefs[6] # Name of new directory to make to store things
  
if (length(userprefs) > 6){
  mirror.location <- userprefs[7]
}else{
  mirror.location <- "https://cran.mtu.edu"
}

bar.plots.folder <- paste(plots.folder.path, "Bar_plot", sep = "/")

library.path <- .libPaths() 

# Create directories to hold plots ---------------------------
make.plot.directory <- function(FolderPath){
  if (!dir.exists(FolderPath)){
    dir.create(FolderPath)
    cat("made folder: ", FolderPath, "\n")
  }
}


make.plot.directory(FolderPath = plots.folder.path)
print(bar.plots.folder)
dir.create(bar.plots.folder)

plot.folder <- bar.plots.folder

# Load R packages ---------------------------
library(tidyverse)
library(forcats)
library(stringr)
library(plyr)
library(dplyr)

# Read input 1 ---------------------------
energy.flow.input <- read.table(R_input_1, sep="\t")
colnames(energy.flow.input) <- c("Reaction_Letter","Number.of.Genomes","Genome.Coverage")
# Convert the Genome Coverage into Percentages:
energy.flow.input$Genome.Coverage <- energy.flow.input$Genome.Coverage*100

# Plot 1:
plot.name <- paste(plot.folder,"/",".R_input_1.plot", sep="")
sequential.transformations <- read.table(Sequential_info, sep="\t", header=TRUE)

# Ok we need to append the sequential transformation info into the energy flow input:
energy.flow.input.2 <- left_join(energy.flow.input, sequential.transformations, by ="Reaction_Letter")

# convert to a melted format so we can plot both coverage AND number in same bar plot
energy.flow.input.gathered <- energy.flow.input.2 %>% gather(key="Category.to.plot",value="value.to.plot",c(2:3))

#Get the order you want:
order.input.1 <- read.table(order_input1, sep="\t", header=FALSE)
order.input.1 <- left_join(order.input.1, energy.flow.input.gathered, by = c("V1"="Reaction_Letter"))

order.1 <- unique(as.factor(order.input.1$Reaction_Letter_Long))

# this step you only do if the file name is _1.txt
energy.flow.input.gathered$category_f = 
  factor(energy.flow.input.gathered$Category, levels=c('Sulfur oxidation','Sulfur reduction','Denitrification','Nitrogen fixation'))


# Make a list of levels:

energy.flow.input.gathered$Reaction_Letter_Long_f <- factor(energy.flow.input.gathered$Reaction_Letter_Long, levels = order.1)

energy.flow.input.gathered$Category.to.plot <- gsub("Number.of.Genomes", "Number of Genomes", energy.flow.input.gathered$Category.to.plot)
energy.flow.input.gathered$Category.to.plot <- gsub("Genome.Coverage", "Genome Coverage(%)", energy.flow.input.gathered$Category.to.plot)

plot1 <- ggplot(energy.flow.input.gathered, aes(x=Reaction_Letter_Long_f, y=value.to.plot))+
  geom_bar(stat="identity",position=position_dodge())+
  facet_grid(Category.to.plot~category_f, scales="free", switch="y")+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 25, hjust = 1),
        strip.placement = "outside")+
  ylab("Value")+
  xlab("Reaction identifier")+
  ggtitle("Input 1")

plot.name <- paste(plot.folder, "/bar_plot_input_1.pdf", sep="")
pdf(file = plot.name, width = 11, height = 8.5, onefile=FALSE)
plot1
dev.off()

# Do the same thing for Input #2:
energy.flow.input.second <- read.table(R_input_2, sep="\t")
colnames(energy.flow.input.second) <- c("Reaction_Letter","Number.of.Genomes","Genome.Coverage")
# convert Genome Coverage into percentages:
energy.flow.input.second$Genome.Coverage <- energy.flow.input.second$Genome.Coverage*100

energy.flow.input.second.2 <- left_join(energy.flow.input.second, sequential.transformations, by ="Reaction_Letter")


energy.flow.input.gathered.second <- energy.flow.input.second.2 %>% gather(key="Category.to.plot",value="value.to.plot",c(2:3))

# Edit labels to fit in panel grid:
var_width = 5

energy.flow.input.gathered.second <- mutate(energy.flow.input.gathered.second, short_category_name = str_wrap(Category, width = var_width))


order.input.2 <- read.table(order_input2, sep="\t", header=FALSE)
order.input.2 <- left_join(order.input.2, energy.flow.input.gathered.second, by = c("V1"="Reaction_Letter"))

order.2 <- unique(as.factor(order.input.2$Reaction_Letter_Long))
#class(order.2)
#levels(order.2)

energy.flow.input.gathered.second$Reaction_Letter_Long_f <- factor(energy.flow.input.gathered.second$Reaction_Letter_Long, levels = order.2)

# Now we want to put AG oligosacchahride degradation into one category:
energy.flow.input.gathered.second$short_category_name <- gsub('AG-\noligosaccharide\ndegradation.*', 'AG-\noligosaccharide\ndegradation', energy.flow.input.gathered.second$short_category_name)  

# Change y labels:
# FIX THIS
energy.flow.input.gathered.second$Category.to.plot <- gsub("Number.of.Genomes", "Number of Genomes", energy.flow.input.gathered.second$Category.to.plot)
energy.flow.input.gathered.second$Category.to.plot <- gsub("Genome.Coverage", "Genome Coverage(%)", energy.flow.input.gathered.second$Category.to.plot)

# plot second diagram:

plot2 <- ggplot(energy.flow.input.gathered.second, aes(x=Reaction_Letter_Long_f, y=value.to.plot))+
  geom_bar(stat="identity",position=position_dodge())+
  facet_grid(Category.to.plot~short_category_name, scales="free", switch="y")+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90, hjust = 1),
        strip.text.x = element_text(size = 8),
        strip.placement = "outside")+
  ylab("Number of Genome or Genome coverage")+
  xlab("Reaction identifier")+
  ggtitle("Input 2")

plot.name <- paste(plot.folder, "/bar_plot_input_2.pdf", sep="")
pdf(file = plot.name, width = 11, height = 8.5, onefile=FALSE)
plot2
dev.off()

print("Finished making the Sequential Reaction Plots")
