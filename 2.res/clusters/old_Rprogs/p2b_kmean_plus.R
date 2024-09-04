
#################################################################################
# UPDATE R 

#install.packages("installr")
#library(installr)
#updateR()

#################################################################################

# Begin by deleting any previously defined variables
rm(list = ls())


install.packages("flexclust")  # K-mean ++ algorithm #
install.packages("writexl")


install.packages("tidyverse") 
install.packages("cluster") 

install.packages("factoextra") 

install.packages("NbClust") 
install.packages("flexclust") 
install.packages("ClusterR") 
install.packages("fpc") 


# Set the working directory to your desired path
setwd("C:/Users/gianl/Dropbox/WW_other_projs/WB_2024/WB_GE/WB_DTA_Toolkit/2.res/clusters")

# Load required packages
library(flexclust)           # Load the flexclust package for clustering
library(tidyverse)           # Load the tidyverse package for data manipulation
library(writexl)             # Load writexl for exporting to Excel
library(cluster)             # Load cluster for clustering algorithms
library(factoextra)          # Load factoextra for clustering visualization
library(NbClust)             # Load NbClust for determining optimal clusters

# Load your dataset
kmean_r <- read_dta("kmean_r.dta")  # Load your dataset from a file

# Perform k-means++ clustering
kmat <- as.matrix(kmean_r)  # Convert data to a matrix
km2 <- kmeanspp(kmat, k = 3, start = "random", iter.max = 5000, nstart = 100)  # Perform k-means++ clustering

# Visualize the clustering results
fviz_cluster(km2, data = kmat, geom = "point", stand = FALSE, frame.type = "norm") + theme_bw()  # Create a clustering plot

# Determine the optimal number of clusters using the Elbow Method
elbow_plot <- fviz_nbclust(kmat, kmeans, method = "wss")  # Elbow Method for optimal clusters

# Determine the optimal number of clusters using the Average Silhouette Method
silhouette_plot <- fviz_nbclust(kmat, kmeans, method = "silhouette")  # Average Silhouette Method

# Export clustering results to Excel
results <- data.frame(kmean_r[["id_agree"]], km2$cluster)  # Create a data frame with IDs and clusters
colnames(results) <- c("ID", "Cluster")  # Rename columns
write_xlsx(results, "kmeans_clusters.xlsx")  # Export to Excel

################################################################################
################################################################################

