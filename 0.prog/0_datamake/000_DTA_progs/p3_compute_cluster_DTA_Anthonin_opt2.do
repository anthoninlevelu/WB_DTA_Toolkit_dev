********************************************************************************
********************************************************************************
/*                   Cluster Provisions                                       */
********************************************************************************

set graphics off


*** OPTION 2 ***

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

*Anthonin: For every agreement concerning African economies, we need to know which provisions to implement in order to reach a "k-mean == 2", that is, a DEEP PTA! 

gen african_pta = 0
replace african_pta = 1 if  (id_agree == 29  | id_agree == 40  | id_agree == 47  | id_agree == 50  | id_agree == 51  | id_agree == 54  | ///
							 id_agree == 55  | id_agree == 56  | id_agree == 95  | id_agree == 96  | id_agree == 102 | id_agree == 103 | ///
							 id_agree == 105 | id_agree == 108 | id_agree == 109 | id_agree == 114 | id_agree == 126 | id_agree == 127 | ///
							 id_agree == 130 | id_agree == 154 | id_agree == 157 | id_agree == 173 | id_agree == 216 | id_agree == 269 | ///
							 id_agree == 289 | id_agree == 290 | id_agree == 313 | id_agree == 319 | id_agree == 333 | id_agree == 347 | ///
							 id_agree == 355 | id_agree == 359 | id_agree == 378 | id_agree == 391 | id_agree == 396)


							 
							 
********************************************************************************
** BASELINE CLASSIFICATION ** 							 
							 
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






* gen baseline indicators *

rename g3  				g3_baseline
rename ga3 				ga3_baseline
rename f3  				f3_baseline
rename k3  				baseline_k3
rename sil_k3_L2  		sil_k3_L2_baseline
rename kmed3  			kmed3_baseline
rename sil_kmed3_L2  	sil_kmed3_L2_baseline








************************************
** COUNTERFACTUALS CLASSIFICATION ** 							 

********************************************************************************
* Only 3 out of 35 African PTA are 'Deep'

tab baseline_k3 if african_pta == 1
tab id_agree if baseline_k3 == 2 & african_pta == 1 

* global for african PTA that are not Deep (remove 29, 313, 347 from the list)
global african_agree  "40 47 50 51 54 55 56 95 96 102 103 105 108 109 114 126 127 130 154 157 173 216 269 289 290 319 333 355 359 378 391 396"


*1.1. perform deepening (replace existing with +1std and missing with the mean)  *

putexcel set "$TEMP/switch_opt2.xlsx", replace
putexcel A1 = "id_agree"
putexcel B1 = "provision"
putexcel C1 = "k3_baseline"
putexcel D1 = "k3"

		
*loop 32 x 18 

local j = 1
foreach agree of global african_agree {
	
	
	forvalues i = 1 (1) 18 {
			
			preserve
		
			*1.1.1. perform deepening (replace existing with +1std and missing with the mean)
			
			di "Agreement: `agree'"
			di "Provision number: `i'"
			
			qui sum rta_deep_std`i', d
			local std_ = r(sd)
			replace rta_deep_std`i' = rta_deep_std`i' + `std_' if (rta_deep_std`i' != 0) & id_agree == `agree'
			
			qui sum rta_deep_std`i', d
			local mean_ = r(mean)
			replace rta_deep_std`i' = `mean_' if (rta_deep_std`i' == 0 | rta_deep_std`i' == .) & id_agree == `agree'
			
			*1.1.2. generate clustering
			********************************************************************************
			/* 						Generate a distance matrix 							*/
			sort id_agree
			matrix dissim dist_L 	= rta_deep_std*	, L2
			matrix dissim dist_L2 	= rta_deep_std*	, L2squared

			********************************************************************************
			/*  			Ward : Agglomerative hierarchical methods such 				*/
			*cluster wardslinkage rta_deep_std*, name(clav_war)

			*cluster stop
			*calinski	   , dist(dist_L2) 	id(id_agree) graph
			*gr export "$CLUS/agree_clainski_$type.pdf", as(pdf) replace
 
			*dudahart	   , dist(dist_L2) 	id(id_agree) graph(dht)
			*gr export "$CLUS/agree_dudahart_$type.pdf", as(pdf) replace
 
			********************************************************************************
			global clav "clav_war"

			forvalues k = 2/4   { 
			
				cap cluster drop k`k'
				cap drop    g`k'
				cap drop    k`k'
				cap drop    sil_k`k'
			********************************************************
			* hierarchical k-clusters based on Wards
			*cluster gen g`i' = gr(`i'), name($clav)
			*cluster waveragelinkag rta_deep_std*, name(clav_w)
			*cluster averagelinkage rta_deep_std*, name(clav)

			********************************************************************************
			/* 					Partitioning methods: k-means, k-medians          		*/

			* k-mean clusters
		
				di "Cluster k-mean"
				di "number of clust: `k'"
				cluster kmean rta_deep_std*, k(`k') name(k`k') start(random($seed))

			* k-median clusters
			*cluster kmedians rta_deep_std*, k(`i') name(kmed`i') start(random($seed))

			*********************************************************
			* Evaluate Silhouette of clusters
			silhouette   k`k' , dist(dist_L2) id(id_agree) gen(sil_k`k'_L2) lwidth(0.8 0.8 0.8)
			*gr export "$CLUS\agree_silhouette_kmean`i'_$type.pdf", as(pdf) replace
 

			*silhouette   k`i' , dist(dist_L2) id(id_agree) gen(sil_kmed`i'_L2) lwidth(0.8 0.8 0.8)
			*gr export "$CLUS\agree_silhouette_kmedian`i'_$type.pdf", as(pdf) replace
  
			*table g`i' k`i'

			*Anthonin: Not working on MAC-ARM64: package problem
			*ari g`i' k`i'
		
			}

			********************************************************************************
			/*                 		Partitioning Around Medoids                        */

			/* generate centroids of each cluster */
			*cap drop medo_*
			*getmedoids g3			, dist(dist_L2) id(id_agree) gen(medo_g3_L2) 
			*getgroup medo_g3_L2		, dist(dist_L2) id(id_agree) gen(medo_gr)

			/* genetic algorithm to search for a global optimum */
			*cap drop cp*
			*clpam ga3, dist(dist_L2) id(id_agree) medoids(3)   ga 
			*clpam many3, dist(dist_L2) id(id_agree) medoids(3)   many

			/* Fuzzy clustering allows objects to be members of multiple clusters, with varying strengths of attachment */
			*clfuzz f3, dist(dist_L2) id(id_agree) k(3)

			*1.1.4. store results

			di "Storing results to excel file"
			
			
			local j = `j'+1
			qui putexcel A`j' = "`agree'"
			qui putexcel B`j' = "`i'"
			qui sum baseline_k3 if id_agree == `agree'
			local k3b = r(mean)
			qui putexcel C`j' = "`k3b'"
			qui sum k3 if id_agree == `agree'
			local k3m = r(mean)
			qui putexcel D`j' = "`k3m'" 
			
			restore
	}

	
	
}
	


*1.2. summarize results : which provisions for each PTA allow to go from either shallow/med to deep?

* so far none of the trial lead to a switch to a Deep pta (k3 ==2). Although some switch from shallow to medium. Area 18 is 

import excel "$TEMP/switch_opt2.xlsx", firstrow clear
destring _all, replace
gen switch_ = 0
replace switch_ = 1 if k3 ==2
tab provision if switch_ == 1 




// ********************************************************************************
// ********************************************************************************
//
// preserve
// keep id_agree rta_deep_std*
// save "$CLUS/kmean_r_$type.dta", replace
// export delimited using "$CLUS/kmean_r_$type.csv", replace
// restore
//
//
// ********************************************************************************
// ********************************************************************************
//
// 
// keep  id_agree g3 ga3 f3  k3 sil_k3_L2  kmed3 sil_kmed3_L2
// order id_agree g3 ga3 f3  k3 sil_k3_L2  kmed3 sil_kmed3_L2
//
// rename g3  			h_cluster
// rename ga3 			pam
// rename f3  			fuzzy
// rename k3  			kmean
// rename sil_k3_L2  	kmean_sil
//
// rename kmed3  			kmedian
// rename sil_kmed3_L2  	kmedian_sil
//
// merge m:1 id_agree using "$DATA/rta_list", keepusing(id_agree agreement entry_force)  
// keep if _m == 3
// drop _m
//
// order id_agree agreement entry_force h_cluster pam fuzzy kmean kmean_sil 
// sort id_
// save "$CLUS/temp_descriptive_stats_$type.dta", replace
//
// ********************************************************************************
// ********************************************************************************
// ********************************************************************************
// ********************************************************************************

