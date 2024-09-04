
#################################################################################
# UPDATE R 

#install.packages("installr")
#library(installr)
#updateR()

#################################################################################

# Begin by deleting any previously defined variables
rm(list = ls())


install.packages("flexclust")      # K-mean ++ algorithm #
#install.packages("clusternor")    # no longer supported in R 4.3.x
#install.packages("LICORS")        # no longer supported in R 4.3.x
install.packages("writexl")
install.packages("tidyverse") 
install.packages("cluster") 
install.packages("factoextra") 
install.packages("NbClust") 
install.packages("flexclust") 
install.packages("ClusterR") 
install.packages("fpc") 


###############################################################################
#      A general equilibrium (GE) assessment of the economic impact of
#         Deep regional Trade Agreements (DTAs)
#
#                 by Lionel Fontagn? and Gianluca Santoni
#
#                         this version: March 2021
#     
###############################################################################

rm(list = ls())

# setwd("E:/Dropbox/Regionalism_2017/NADIA_project/results_march2021/1_cluster_baseline_oct21_CPTPP")
  setwd("D:/Santoni/Dropbox/Regionalism_2017/NADIA_project/results_march2021/1_cluster_baseline_oct21_CPTPP")

 getwd()      



set.seed(1710979)

library(tidyverse)
library(tibble)
library(haven)
library(clusternor)
library(writexl)
library(gridExtra)

library(tidyverse)  # data manipulation
library(cluster)    # clustering algorithms
library(factoextra) # clustering algorithms & visualization
library(NbClust) 
library(LICORS) 

library(cluster)
library(fpc)


###############################################################################
# upload data from categorical rta provision (not 1-0)
###############################################################################


rm(list = ls())
kmean_r      <- read_dta("kmean_r.dta")

df           <- data.frame(kmean_r)
rownames(df) <- df[,1]
df[,1]       <- NULL
df

has_rownames(df)

###############################################################################
###############################################################################

k.mat    <- as.matrix(df)
km       <- KmeansPP(k.mat, centers=3, dist.type = "eucl" , nstart = 1  )

plotcluster(k.mat, km$cluster)
dp = discrproj(df, km$cluster)
plot(dp$proj[,1], dp$proj[,2], pch=km$cluster + 48, col=km$cluster) #+48 to get labels correct




test1    <- list(kmean_r[["id_agree"]]  ,  dp$proj[,1]  ,  dp$proj[,2] )
res_1    <-   as.data.frame(do.call(cbind, test1))
write_xlsx(res_1,"kmeans_coordinates_old.xlsx")


###############################################################################
###############################################################################
# This is the preferred Algorithm
km2      <- kmeanspp(k.mat, k = 3, start = "random", iter.max = 5000 , nstart = 100)

fviz_cluster(km2, data = k.mat, geom = "point", stand = FALSE, frame.type = "norm") + theme_bw()


plotcluster(k.mat, km2$cluster)
dp = discrproj(df, km2$cluster)
plot(dp$proj[,1], dp$proj[,2], pch=km2$cluster+48, col=km2$cluster) #+48 to get labels correct



test1    <- list(kmean_r[["id_agree"]]  ,  dp$proj[,1]  ,  dp$proj[,2] )
res_1    <-   as.data.frame(do.call(cbind, test1))
write_xlsx(res_1,"kmeans_coordinates.xlsx")

###############################################################################
###############################################################################




###############################################################################
# This is equivalent: Kmeans
k3       <- kmeans(df, centers = 3, nstart = 250, iter.max = 1000)



fviz_cluster(k3, data = k.mat, geom = "point", stand = FALSE, frame.type = "norm") + theme_bw()
###############################################################################

test1    <- list(kmean_r[["id_agree"]]  ,  km[["cluster"]])
res_1    <-   as.data.frame(do.call(cbind, test1))

#write_xlsx(res_1,"kmeans_pp.xlsx")

###############################################################################

set.seed(1710979)

distance <- get_dist(df)

##################################
# Determining Optimal Clusters
##################################


# Elbow Method
fviz_nbclust(df, kmeans, method = "wss")

# Average Silhouette Method
fviz_nbclust(df, kmeans, method = "silhouette")
# optimal number of cluster is 2 according to the silhouette score: export plot



test2    <- list(rownames(df)  ,  k3[["cluster"]])
res_2    <-   as.data.frame(do.call(cbind, test2))

#write_xlsx(res_2,"kmeans_r.xlsx")

###############################################################################
# compute cluster: PAM

pamx <- pam(df, 3)

###############################################################################
res <- NbClust(df, diss = NULL, distance = "euclidean", min.nc=2, max.nc=10, method = "kmeans", index = "silhouette")
res$All.index
res$Best.nc
res$Best.partition



test3    <- list(rownames(df)  , res[["Best.partition"]],   k3[["cluster"]] , km[["cluster"]] , km2[["cluster"]])
res_3    <-   as.data.frame(do.call(cbind, test3))

write_xlsx(res_3,"kmeans_final.xlsx")





