
# Install required packages
import Pkg; Pkg.add("StatsBase")
import Pkg; Pkg.add("FileIO")
import Pkg; Pkg.add("JLD2")
import Pkg; Pkg.add("XLSX")
import Pkg; Pkg.add("Distances")
import Pkg; Pkg.add("Clustering")   


# Set the working directory
cd("d:/santoni/Dropbox/WW_other_projs/WB_2024/WB_GE/WB_DTA_Toolkit/2.res/clusters")

# Print the current working directory
println(pwd())

# Load required packages
using DataFrames
using Clustering
using CSV
using StatsBase
using Plots
using Statistics
using Random
using FileIO
using JLD2
using Distances
using Plots

using XLSX
using StatsBase

######################################################################
# Set seed
Random.seed!(17101979)

# Load data
kmean_r = DataFrame(CSV.File("kmean_r_w.csv"))

# Set row names as first column and remove it
# Julia DataFrames do not support row names, so we'll keep it as a column
df = kmean_r


# Convert DataFrame to matrix and scale it
k_mat       = Matrix(df)
data_scaled = zscore(k_mat)
 
using Distances
println(names(Distances))
######################################################################
# Define Optimal Number of clusters

# Elbow Method
sse = []
for k in 2:10
    result = kmeans(k_mat', k; maxiter=1000000)
    sse_k = sum([euclidean(k_mat'[:, result.assignments[i]], result.centers[:, result.assignments[i]])^2 for i in 1:size(k_mat', 2)])
    push!(sse, sse_k)
end
plot(2:10, sse, xlabel="Number of clusters", ylabel="SSE", title="Elbow Method", legend=false)


# Silhouette Method
sil_scores = []
for k in 2:10
    result = kmeans(k_mat', k; maxiter=1000000)
    sil = mean(silhouettes(result, pairwise(Euclidean(), k_mat')))
    push!(sil_scores, sil)
end
plot(2:10, sil_scores, xlabel="Number of clusters", ylabel="Silhouette Score", title="Silhouette Method", legend=false)



# Elbow Method
sse = []
for k in 2:10
    result = kmeans(data_scaled', k; maxiter=1000000)
    sse_k = sum([euclidean(data_scaled'[:, result.assignments[i]], result.centers[:, result.assignments[i]])^2 for i in 1:size(data_scaled', 2)])
    push!(sse, sse_k)
end
plot(2:10, sse, xlabel="Number of clusters", ylabel="SSE", title="Elbow Method", legend=false)

# Silhouette Method
sil_scores = []
for k in 2:10
    result = kmeans(data_scaled', k; maxiter=1000000)
    sil = mean(silhouettes(result, pairwise(Euclidean(), data_scaled')))
    push!(sil_scores, sil)
end
plot(2:10, sil_scores, xlabel="Number of clusters", ylabel="Silhouette Score", title="Silhouette Method", legend=false)

######################################################################
# Run Clusters

# Perform k-means clustering
for k in 2:5
    kmeans_result_ch = kmeans(k_mat', k; maxiter=100)
    # ... rest of your code that uses kmeans_result_ch ...
end


# Extract clusters and centers
clusters_euclidean_ch = assignments(kmeans_result_ch)
centers_euclidean_runs = kmeans_result_ch.centers

clusters_euclidean_asw = assignments(kmeans_result_asw)
centers_euclidean_runs = kmeans_result_asw.centers

# Visualization
scatter(k.mat[:, 1], k.mat[:, 2], color = clusters_euclidean_ch)
scatter!(centers_euclidean_runs[1, :], centers_euclidean_runs[2, :], color = :black, shape = :star5)

scatter(k.mat[:, 1], k.mat[:, 2], color = clusters_euclidean_asw)
scatter!(centers_euclidean_runs[1, :], centers_euclidean_runs[2, :], color = :black, shape = :star5)

# Prepare data for export
res_1_ch = DataFrame(id_agree = kmean_r["id_agree"], cluster = clusters_euclidean_ch)
res_1_asw = DataFrame(id_agree = kmean_r["id_agree"], cluster = clusters_euclidean_asw)

# Export to Excel
XLSX.writexlsx("kmeansruns_coordinates_euclidean_ch.xlsx", res_1_ch)
XLSX.writexlsx("kmeansruns_coordinates_euclidean_asw.xlsx", res_1_asw)