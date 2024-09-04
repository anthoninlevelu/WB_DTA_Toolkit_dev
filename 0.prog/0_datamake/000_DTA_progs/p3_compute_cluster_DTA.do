********************************************************************************
********************************************************************************
/*                   Cluster Provisions                                       */
********************************************************************************

use "$CLUS/data_agree_cluster_$type.dta", clear

 
keep id_agree id_provision rta_deep_std 
 


reshape wide rta_deep_std, i(id_agree) j(id_provision)  


*******************************************************************************
	
foreach v of varlist  _all   {

if "`v'" != "id_agree" {
	
replace  `v' = 0 if  `v' == .


*egen std_`v'  = std(`v')
*replace   `v' = std_`v'

}

}
********************************************************************************
********************************************************************************
********************************************************************************
/* clean variables */

cap drop k*
cap drop g*
cap drop clav*
cap drop medo_*
cap drop sil_*
sort id_agree

********************************************************************************
/* Generate a distance matrix */
sort id_agree
matrix dissim dist_L 	= rta_deep_std*	, L2
matrix dissim dist_L2 	= rta_deep_std*	, L2squared



********************************************************************************
/*  Ward : Agglomerative hierarchical methods such */
cluster wardslinkage rta_deep_std*, name(clav_war)

cluster stop
calinski	   , dist(dist_L2) 	id(id_agree) graph
gr export "$CLUS/agree_clainski_$type.pdf", as(pdf) replace
 




dudahart	   , dist(dist_L2) 	id(id_agree) graph(dht)
gr export "$CLUS/agree_dudahart_$type.pdf", as(pdf) replace
 

********************************************************************************
global clav "clav_war"

forvalues i = 2 (1) 4   {

cap drop    g`i'

cap drop    k`i'

********************************************************
* hierarchical k-clusters based on Wards
cluster gen g`i' = gr(`i'), name($clav)
*cluster waveragelinkag rta_deep_std*, name(clav_w)
*cluster averagelinkage rta_deep_std*, name(clav)

********************************************************
/* Partitioning methods: k-means, k-medians           */

* k-mean clusters
cluster kmean rta_deep_std*, k(`i') name(k`i') start(random($seed))

* k-median clusters
cluster kmedians rta_deep_std*, k(`i') name(kmed`i') start(random($seed))

*********************************************************
* Evaluate Silhouette of clusters
silhouette   k`i' , dist(dist_L2) id(id_agree) gen(sil_k`i'_L2) lwidth(0.8 0.8 0.8)
 gr export "$CLUS\agree_silhouette_kmean`i'_$type.pdf", as(pdf) replace
 

silhouette   k`i' , dist(dist_L2) id(id_agree) gen(sil_kmed`i'_L2) lwidth(0.8 0.8 0.8)
 gr export "$CLUS\agree_silhouette_kmedian`i'_$type.pdf", as(pdf) replace
  
table g`i' k`i'

*Anthonin: Not working on MAC-ARM64: package problem
*ari g`i' k`i'

}



********************************************************************************
/*                 Partitioning Around Medoids                        */


/* generate centroids of each cluster */
cap drop medo_*
getmedoids g3			, dist(dist_L2) id(id_agree) gen(medo_g3_L2) 
getgroup medo_g3_L2		, dist(dist_L2) id(id_agree) gen(medo_gr)



/* genetic algorithm to search for a global optimum */
cap drop cp*
clpam ga3, dist(dist_L2) id(id_agree) medoids(3)   ga 
clpam many3, dist(dist_L2) id(id_agree) medoids(3)   many

/* Fuzzy clustering allows objects to be members of multiple clusters, with varying strengths of attachment */
clfuzz f3, dist(dist_L2) id(id_agree) k(3)

********************************************************************************
********************************************************************************

preserve
keep id_agree rta_deep_std*
save "$CLUS/kmean_r_$type.dta", replace
export delimited using "$CLUS/kmean_r_$type.csv", replace
restore


********************************************************************************
********************************************************************************

 
keep  id_agree g3 ga3 f3  k3 sil_k3_L2  kmed3 sil_kmed3_L2
order id_agree g3 ga3 f3  k3 sil_k3_L2  kmed3 sil_kmed3_L2

rename g3  			h_cluster
rename ga3 			pam
rename f3  			fuzzy
rename k3  			kmean
rename sil_k3_L2  	kmean_sil

rename kmed3  			kmedian
rename sil_kmed3_L2  	kmedian_sil

merge m:1 id_agree using "$DATA/rta_list", keepusing(id_agree agreement entry_force)  
keep if _m == 3
drop _m

order id_agree agreement entry_force h_cluster pam fuzzy kmean kmean_sil 
sort id_
save "$CLUS/temp_descriptive_stats_$type.dta", replace

********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************

