
################################################################################
# UPDATE R 

#install.packages("installr")
#library(installr)
#updateR()

################################################################################
################################################################################
#
#      A general equilibrium (GE) assessment of the economic impact of
#         Deep regional Trade Agreements (DTAs)
#
#                 by Lionel Fontagné and Gianluca Santoni
#
#                         this version: January 2024
#     
################################################################################
################################################################################



install.packages("flexclust")  # K-mean ++ algorithm #

install.packages("writexl")


install.packages("tidyverse") 
install.packages("cluster") 

install.packages("factoextra") 

install.packages("NbClust") 
install.packages("flexclust") 
install.packages("ClusterR") 
install.packages("fpc") 
install.packages("haven") 
 
#install.packages("clusternor") 
#install.packages("LICORS") 
#install.packages("tglkmeans")

################################################################################
################################################################################

# Begin by deleting any previously defined variables
rm(list = ls())


  setwd("d:/santoni/Dropbox/WW_other_projs/WB_2024/WB_GE/WB_DTA_Toolkit/2.res/clusters")
# setwd("C:/Users/gianl/Dropbox/WW_other_projs/WB_2024/WB_GE/WB_DTA_Toolkit/2.res/clusters")

 getwd()      


# Load required packages

library(conflicted)
library(dplyr)

library(flexclust)           # Load the flexclust package for clustering
library(tidyverse)           # Load the tidyverse package for data manipulation
library(writexl)             # Load writexl for exporting to Excel
library(cluster)             # Load cluster for clustering algorithms
library(factoextra)          # Load factoextra for clustering visualization
library(NbClust)             # Load NbClust for determining optimal clusters
library(haven)               # read DTA files 
library(fpc)                 # plot cluster

library(ggplot2)
library(dplyr)
 
################################################################################
# upload data from categorical rta provision (not 1-0)
################################################################################

set.seed(17101979)
 

kmean_r      <- read_dta("kmean_r_u.dta")

df           <- data.frame(kmean_r)
rownames(df) <- df[,1]
df[,1]       <- NULL
df

has_rownames(df)
k.mat        <- as.matrix(df)
data_scaled  <- scale(k.mat)


################################################################################
################################################################################
# Section 1: Clustering with kmeansruns (Euclidean Distance, unscaled)
# data_scaled or k.mat
optimal_clusters_ch <- kmeansruns(k.mat, krange = 2:5, critout=TRUE, criterion = "ch",
                                  iter.max = 100, nstart = 1000 , alpha=0.001 ) 
# 'nstart' is the number of random initializations, similar to 'runs' in kmeansCBI

# Extracting clusters and centers
clusters_euclidean_ch  <- optimal_clusters_ch$cluster
centers_euclidean_runs <- optimal_clusters_ch$centers

# Visualization (Euclidean)
fviz_cluster(list(data = k.mat, cluster = clusters_euclidean_ch), 
             geom = "point", stand = FALSE, frame.type = "norm") + theme_bw()

plotcluster(k.mat, clusters_euclidean_ch)
dp <- discrproj(k.mat, clusters_euclidean_ch)
plot(dp$proj[,1], dp$proj[,2], pch = clusters_euclidean_ch + 48, col = clusters_euclidean_ch)

# Prepare data for export (Euclidean)
test1 <- list(kmean_r[["id_agree"]]  , clusters_euclidean_ch, dp$proj[,1], dp$proj[,2])
res_1 <- as.data.frame(do.call(cbind, test1))

# Export to Excel (Euclidean)
write_xlsx(res_1, "kmeansruns_coordinates_euclidean_ch.xlsx")

################################################################################
################################################################################
# Section 1: Clustering with kmeansruns (Euclidean Distance, unscaled)

optimal_clusters_asw <- kmeansruns(data_scaled, krange = 2:5, critout=TRUE, criterion = "asw",
                                   iter.max = 100, nstart = 100 , alpha=0.001 ) 
# 'nstart' is the number of random initializations, similar to 'runs' in kmeansCBI

# Extracting clusters and centers
clusters_euclidean_asw  <- optimal_clusters_asw$cluster
centers_euclidean_runs <- optimal_clusters_asw$centers

# Visualization (Euclidean)
fviz_cluster(list(data = k.mat, cluster = clusters_euclidean_asw), 
             geom = "point", stand = FALSE, frame.type = "norm") + theme_bw()

plotcluster(k.mat, clusters_euclidean_asw)
dp <- discrproj(k.mat, clusters_euclidean_asw)
plot(dp$proj[,1], dp$proj[,2], pch = clusters_euclidean_asw + 48, col = clusters_euclidean_asw)

# Prepare data for export (Euclidean)
test1 <- list(kmean_r[["id_agree"]]  , clusters_euclidean_asw, dp$proj[,1], dp$proj[,2])
res_1 <- as.data.frame(do.call(cbind, test1))

# Export to Excel (Euclidean)
write_xlsx(res_1, "kmeansruns_coordinates_euclidean_asw.xlsx")

# clusters_euclidean_ch, clusters_euclidean_asw
################################################################################
################################################################################
# Section2 : Clustering with PAM (Manhattan Distance, unscaled; or data_scaled )
# method the distance measure to be used. This must be one of:
# "euclidean", "maximum", "manhattan", "canberra", "binary", "minkowski", "pearson", "spearman" or "kendall".

pam_dist_matrix      <- dist(k.mat, method = "euclidean")

# Using PAM for clustering
optimal_clusters_pam <- pam(pam_dist_matrix, k = 3, diss = TRUE, nstart = 10)

# Extracting clusters and medoids
clusters_pam <- optimal_clusters_pam$clustering
medoids_pam <- optimal_clusters_pam$medoids

# Prepare data for export (Manhattan)
# Note: You might need to adjust this part based on how you want to handle medoids
test2 <- list(kmean_r[["id_agree"]]  , clusters_pam)  # Adjust 'dp$proj' accordingly
res_2 <- as.data.frame(do.call(cbind, test2))

# Export to Excel (PAM)
write_xlsx(res_2, "kmedoids_coordinates_pam.xlsx")

################################################################################
################################################################################

# This is Kmeans (Euclidean Distance, unscaled)
k3       <- kmeans(k.mat, centers = 3, nstart = 500, iter.max = 10000)

fviz_cluster(k3, data = k.mat, geom = "point", stand = FALSE, frame.type = "norm") + theme_bw()


plotcluster(k.mat, k3$cluster)
dp = discrproj(df, k3$cluster)
plot(dp$proj[,1], dp$proj[,2], pch=k3$cluster+48, col=k3$cluster) #+48 to get labels correct




test1    <- list(kmean_r[["id_agree"]]  ,  k3[["cluster"]] ,  dp$proj[,1]  ,  dp$proj[,2] )
res_1    <-   as.data.frame(do.call(cbind, test1))

write_xlsx(res_1,"kmeans_coordinates.xlsx")

################################################################################
################################################################################

# This is Kmeans (Euclidean Distance, scaled)
k3_scaled  <- kmeans(data_scaled, centers = 3, nstart = 500, iter.max = 10000)

fviz_cluster(k3_scaled, data = data_scaled, geom = "point", stand = FALSE, frame.type = "norm") + theme_bw()


test1    <- list(kmean_r[["id_agree"]]  ,  k3_scaled[["cluster"]] ,  dp$proj[,1]  ,  dp$proj[,2] )
res_1    <-   as.data.frame(do.call(cbind, test1))

write_xlsx(res_1,"kmeans_scaled_coordinates.xlsx")


################################################################################
################################################################################
# Determining Optimal Clusters


set.seed(1710979)

# The default distance computed is the Euclidean, however support Manhattan, Pearson correlation distance, Spearman correlation distance, Kendall correlation distance
distance <- get_dist(df)

# Display Distancxe MAtrix
#fviz_dist(k.mat, gradient = list(low = "#00AFBB", mid = "white", high = "#FC4E07"))

# Elbow Method
fviz_nbclust(k.mat, hcut, method = "gap_stat")

# Average Silhouette Method
# this on the documentation of the Toolkit
fviz_nbclust(k.mat, kmeans, diss = dist(k.mat, method = "manhattan") , method = "silhouette")

#fviz_nbclust(k.mat, kmeans, diss = dist(k.mat, method = "euclidean") , method = "silhouette")

################################################################################
################################################################################

res <- NbClust(k.mat,  distance = "manhattan", min.nc=2, max.nc=10, method = "kmeans", index = "silhouette")
res$All.index
res$Best.nc
res$Best.partition



test3    <- list(rownames(df)  , res[["Best.partition"]],   k3[["cluster"]],  k3_scaled[["cluster"]], clusters_euclidean_ch, clusters_euclidean_asw, clusters_pam)
res_3    <-   as.data.frame(do.call(cbind, test3))

write_xlsx(res_3,"kmeans_final_u.xlsx")

################################################################################
################################################################################

# Elbow method
fviz_nbclust(df, kmeans, method = "wss") +
  geom_vline(xintercept = 4, linetype = 2)+
  labs(subtitle = "Elbow method")

# Silhouette method
fviz_nbclust(k.mat, kmeans, method = "silhouette")+
  labs(subtitle = "Silhouette method")

# Gap statistic
# nboot = 50 to keep the function speedy. 
# recommended value: nboot= 500 for your analysis.
# Use verbose = FALSE to hide computing progression.
set.seed(123)
fviz_nbclust(df, kmeans, nstart = 25,  method = "gap_stat", nboot = 50)+
  labs(subtitle = "Gap statistic method")

################################################################################
################################################################################

# Section 1: Clustering with kmeansCBI (Euclidean Distance, 10 Runs)
optimal_clusters_euclidean <- kmeansCBI(data = k.mat, dmatrix = as.dist(k.mat),
                                        diss = FALSE, criterion = "asw",
                                        scaling = FALSE, krange = 3:3,
                                        runs = 100 )  # Number of random initializations

# Extracting clusters and centers
clusters_euclidean <- optimal_clusters_euclidean$cluster
centers_euclidean <- optimal_clusters_euclidean$centers


# Cluster stability assessment with clusterboot
boot_result_euclidean <- clusterboot(k.mat, B = 10 , 
                                     clustermethod = kmeansCBI, 
                                     method = "kmeans", 
                                     krange = 2:4,
                                     criterion = "asw",
                                     runs = 100)
# Convert clusterboot results to a data frame for export
boot_res_df <- as.data.frame(boot_result_euclidean$bootmean)



# Visualization (Euclidean)
fviz_cluster(list(data = k.mat, cluster = clusters_euclidean), 
             geom = "point", stand = FALSE, frame.type = "norm") + theme_bw()

plotcluster(data_matrix, clusters_euclidean)
dp <- discrproj(data_matrix, clusters_euclidean)
plot(dp$proj[,1], dp$proj[,2], pch = clusters_euclidean + 48, col = clusters_euclidean)

# Prepare data for export (Euclidean)
test1 <- list(kmean_r[["id_agree"]]  , clusters_euclidean, dp$proj[,1], dp$proj[,2])
res_1 <- as.data.frame(do.call(cbind, test1))

# Create a new Excel workbook
wb <- createWorkbook()

# Add sheets and write data
addWorksheet(wb, "Clustering Results")
writeData(wb, "Clustering Results", res_1)

addWorksheet(wb, "Cluster Stability")
writeData(wb, "Cluster Stability", boot_res_df)

# Save the workbook
saveWorkbook(wb, "kmeansCBI_analysis_euclidean.xlsx", overwrite = TRUE)


###############################################################################
###############################################################################
# Section 2: Clustering with kmeansCBI (Manhattan Distance, 500 Runs)

manhattan_dist_matrix <- as.dist(dist(k.mat, method = "manhattan"))
optimal_clusters_manhattan <- kmeansCBI(data = manhattan_dist_matrix, diss = TRUE,
                                        criterion = "asw", scaling = TRUE, krange = 2:4,
                                        runs = 10)  # Number of random initializations


# Cluster stability assessment with clusterboot for Manhattan distance
boot_result_manhattan <- clusterboot(manhattan_dist_matrix, B = 10, 
                                     clustermethod = kmeansCBI, 
                                     method = "kmeans", 
                                     krange = 2:4,
                                     criterion = "asw",
                                     runs = 10, diss = TRUE)

# Convert clusterboot results to a data frame for export
boot_res_df_manhattan <- as.data.frame(boot_result_manhattan$bootmean)




# Extracting clusters
clusters_manhattan <- optimal_clusters_manhattan$cluster

# Assuming 'clusters_manhattan' is the result of the alternative method
fviz_cluster(list(data = manhattan_dist_matrix, cluster = clusters_manhattan), 
             geom = "point", stand = FALSE, frame.type = "norm") + theme_bw()

plotcluster(data_matrix, clusters_manhattan)
dp <- discrproj(data_matrix, clusters_manhattan)
plot(dp$proj[,1], dp$proj[,2], pch = clusters_manhattan + 48, col = clusters_manhattan)

# Prepare data for export (Manhattan)
test2 <- list(kmean_r[["id_agree"]]  , clusters_manhattan, dp$proj[,1], dp$proj[,2])
res_2 <- as.data.frame(do.call(cbind, test2))

# Create a new Excel workbook for Manhattan distance results
wb_manhattan <- createWorkbook()

# Add sheets and write data for Manhattan distance
addWorksheet(wb_manhattan, "Clustering Results Manhattan")
writeData(wb_manhattan, "Clustering Results Manhattan", res_2)

addWorksheet(wb_manhattan, "Cluster Stability Manhattan")
writeData(wb_manhattan, "Cluster Stability Manhattan", boot_res_df_manhattan)

# Save the workbook for Manhattan distance results
saveWorkbook(wb_manhattan, "kmeansCBI_analysis_manhattan.xlsx", overwrite = TRUE)

################################################################################
################################################################################