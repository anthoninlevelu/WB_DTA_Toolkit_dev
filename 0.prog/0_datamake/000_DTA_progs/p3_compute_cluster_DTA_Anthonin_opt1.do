********************************************************************************
********************************************************************************
/*                   Cluster Provisions                                       */
********************************************************************************

set graphics off

*** OPTION 1 ***

* Loop through all new datasets and append resulting clustering.

global area `" "Antidumping Duties" "Competition Policy" "Countervailing Duties" "Environmental Laws" "Export Restrictions" "Intellectual Property Rights (IPR)" "Investment" "Labor Market Regulations" "Movement of Capital" "Public Procurement" "Rules of Origin" "Sanitary and Phytosanitary Measures (SPS)" "Services" "State Owned Enterprises" "Subsidies" "Technical Barriers to Trade (TBT)" "Trade Facilitation and Customs" "Visa and Asylum"  "' 

* global for all PTAs that are not already "deep" in the non-LE and LE (Result of the A/ subroutine)

global all_agree_nole  "3 4 6 7 8 9 10 11 12 14 15 17 19 21 22 24 25 26 27 30 31 32 33 34 35 36 38 39 40 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 86 87 88 91 92 93 94 95 96 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 118 119 120 121 12 2 123 124 125 126 127 128 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 153 154 155 156 157 158 159 160 161 162 163 164 165 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 183 184 186 187 188 190 191 192 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 216 217 218 222 223 224 225 226 227 228 229 230 231 232 233 234 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 256 257 259 260 261 262 263 264 265 266 267 268 269 270 271 272 273 274 275 276 277 278 279 280 281 282 284 285 286 287 288 289 290 291 292 293 294 295 296 297 298 299 300 301 302 304 305 306 307 309 311 312 319 320 321 322 323 324 326 327 330 331 332 333 338 340 341 342 343 345 346 348 349 350 352 353 354 355 356 357 358 359 360 361 363 364 366 367 368 369 370 372 373 374 375 376 377 378 379 380 381 382 383 384 385 386 388 389 390 391 393 394 395 396 398 399 400"

global all_agree_le "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 86 87 88 89 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 183 184 186 187 188 189 190 191 192 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255 256 257 258 259 260 261 262 263 264 265 266 267 268 269 270 271 272 273 274 275 276 277 278 279 280 281 282 283 284 285 286 287 288 289 290 291 292 293 294 295 296 297 298 299 300 301 302 303 304 305 306 307 308 309 311 312 313 318 319 320 321 322 323 324 326 327 330 331 332 333 338 340 341 342 343 345 346 347 348 349 350 351 352 353 354 355 356 357 358 359 360 361 363 364 366 367 368 369 370 372 373 374 375 376 377 378 379 380 381 382 383 384 385 386 388 389 390 391 393 394 395 396 398 399 400"



* global for LE or non- LE (this should be added to the '0.Master_DTA.do' do.file.)

macro drop le
macro drop nole
global le "_le"
global nole "_nole"


* This way, we run either the clustering with LE or non-LE policy areas.

********
** LE **
********


if le == "_le" {
	
			* setup excel output

			putexcel set "$TEMP/switch_opt1_$le.xlsx", replace
			putexcel A1 = "id_agree"
			putexcel B1 = "provision"
			putexcel C1 = "k3_baseline"
			putexcel D1 = "k3" 

			* start loop

			local j = 1

			foreach agree of global all_agree_le {
				
					local p = 0
					
				foreach area of global area {
					
					local p = `p' + 1
					local j = `j'+ 1
					
					di "Agreement: `agree'"
					di "Area: `area'" 
					di "Prov number: `p'"
					
					********************************************************************************
					*A/ Run baseline clustering and append the results to the excel file (this step can be improved as very repetitive)
					********************************************************************************

					global type "w"

					use "$CLUS/data_agree_cluster_$type.dta", clear
							
							
							keep id_agree id_provision rta_deep_std_le

							reshape wide rta_deep_std_le, i(id_agree) j(id_provision)  

					*******************************************************************************
				
							foreach v of varlist  _all   {

								if "`v'" != "id_agree" {
				
								replace  `v' = 0 if  `v' == .


								*egen std_`v'  = std(`v')
								*replace   `v' = std_`v'

								}

							}
							
					********************************************************************************
					
					
							/* clean variables */

							cap drop k*
							cap drop g*
							cap drop clav*
							cap drop medo_*
							cap drop sil_*
							sort id_agree

							*Anthonin: For every agreement concerning all economies, we need to know which provisions to implement in order to reach a "k-mean == 2", that is, a DEEP PTA! 


														 
														 
							********************************************************************************
							** BASELINE CLASSIFICATION ** 							 
														 
							********************************************************************************
							/* Generate a distance matrix */
							sort id_agree
							matrix dissim dist_L 	= rta_deep_std_le*	, L2
							matrix dissim dist_L2 	= rta_deep_std_le*	, L2squared

							********************************************************************************
							/*  Ward : Agglomerative hierarchical methods such */
							cluster wardslinkage rta_deep_std_le*, name(clav_war)

							cluster stop
							calinski	   , dist(dist_L2) 	id(id_agree) graph
							*gr export "$CLUS/agree_clainski_$type.pdf", as(pdf) replace
							 
							dudahart	   , dist(dist_L2) 	id(id_agree) graph(dht)
							*gr export "$CLUS/agree_dudahart_$type.pdf", as(pdf) replace
							 
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
							cluster kmean rta_deep_std_le*, k(`i') name(k`i') start(random($seed))

							* k-median clusters
							cluster kmedians rta_deep_std_le*, k(`i') name(kmed`i') start(random($seed))

							*********************************************************
							* Evaluate Silhouette of clusters
							silhouette   k`i' , dist(dist_L2) id(id_agree) gen(sil_k`i'_L2) lwidth(0.8 0.8 0.8)
							 *gr export "$CLUS\agree_silhouette_kmean`i'_$type.pdf", as(pdf) replace
							 

							silhouette   k`i' , dist(dist_L2) id(id_agree) gen(sil_kmed`i'_L2) lwidth(0.8 0.8 0.8)
							 *gr export "$CLUS\agree_silhouette_kmedian`i'_$type.pdf", as(pdf) replace
							  
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
							
							tab baseline_k3
							levelsof id_agree if baseline_k3 != 2

					
					* Append results of baseline
					
					qui putexcel A`j' = "`agree'"
					qui putexcel B`j' = "`p'"
					
					qui sum baseline_k3 if id_agree == `agree'
					local k3b = r(mean)
					qui putexcel C`j' = "`k3b'"

					
					********************************************************************************
					*B/ Run counterfactual datasets one by one and append the results to the excel file
					********************************************************************************
					
					* COUNTERFACTUALS CLASSIFICATION *							 

					********************************************************************************
					* Only X out of XXXX  PTA are 'Deep'

					tab baseline_k3 
					tab id_agree if baseline_k3 == 2

					
						*1.1.1. load new dataset
						global type "w"
						********************************************************************************
						*use "$CLUS/data_agree_cluster_CF/data_agree_cluster_w_40_14.dta", clear
						use "$CLUS/data_agree_cluster_CF/data_agree_cluster_w_`agree'_`p'.dta", clear

							cap drop area_num
							gen area_num = 0
							replace area_num = 1 if Area == "`area'"
							
							keep id_agree id_provision rta_deep_std_le

							reshape wide rta_deep_std_le, i(id_agree) j(id_provision)  

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

							*Anthonin: For every agreement concerning all economies, we need to know which provisions to implement in order to reach a "k-mean == 2", that is, a DEEP PTA! 
								 
														 
							
						*1.1.2. generate clustering
						********************************************************************************
							/* 						Generate a distance matrix 							*/
							sort id_agree
							matrix dissim dist_L 	= rta_deep_std_le*	, L2
							matrix dissim dist_L2 	= rta_deep_std_le*	, L2squared

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
								cluster kmean rta_deep_std_le*, k(`k') name(k`k') start(random($seed))

							* k-median clusters
							*cluster kmedians rta_deep_std*, k(`i') name(kmed`i') start(random($seed))

							*********************************************************
							* Evaluate Silhouette of clusters
							*silhouette   k`k' , dist(dist_L2) id(id_agree) gen(sil_k`k'_L2) lwidth(0.8 0.8 0.8)
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

						*1.1.3. store results

							di "Storing results to excel file"
							
							qui sum k3 if id_agree == `agree' 
							local k3m = r(mean)
							qui putexcel D`j' = "`k3m'" 
						
						
						
				}

				
				
			}
				




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


			*1.2. summarize results : which provisions for each PTA allow to go from either shallow/med to deep?

			* Comment here: 

			import excel "$TEMP/switch_opt1_$le.xlsx", firstrow clear
			destring _all, replace
			gen switch_ = 0
			replace switch_ = 1 if k3 == 2
			tab provision if switch_ == 1 

			//   provision |      Freq.     Percent        Cum.
			// ------------+-----------------------------------
			//           1 |         30       42.25       42.25
			//           3 |          1        1.41       43.66
			//           9 |          9       12.68       56.34
			//          12 |         31       43.66      100.00
			// ------------+-----------------------------------
			//       Total |         71      100.00



}

************
** NON-LE **
************

else {

			* setup excel output

			putexcel set "$TEMP/switch_opt1_$nole.xlsx", replace
			putexcel A1 = "id_agree"
			putexcel B1 = "provision"
			putexcel C1 = "k3_baseline"
			putexcel D1 = "k3" 

			* start loop

			local j = 1

			foreach agree of global all_agree {
				
					local p = 0
					
				foreach area of global area {
					
					local p = `p' + 1
					local j = `j'+ 1
					
					di "Agreement: `agree'"
					di "Area: `area'" 
					di "Prov number: `p'"
					
					********************************************************************************
					*A/ Run baseline dataset and append the results to the excel file (this step can be improved as very repetitive)
					********************************************************************************

					global type "w"

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
					
					
							/* clean variables */

							cap drop k*
							cap drop g*
							cap drop clav*
							cap drop medo_*
							cap drop sil_*
							sort id_agree

							*Anthonin: For every agreement concerning all economies, we need to know which provisions to implement in order to reach a "k-mean == 2", that is, a DEEP PTA! 


														 
														 
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
							*gr export "$CLUS/agree_clainski_$type.pdf", as(pdf) replace
							 
							dudahart	   , dist(dist_L2) 	id(id_agree) graph(dht)
							*gr export "$CLUS/agree_dudahart_$type.pdf", as(pdf) replace
							 
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
							 *gr export "$CLUS\agree_silhouette_kmean`i'_$type.pdf", as(pdf) replace
							 

							silhouette   k`i' , dist(dist_L2) id(id_agree) gen(sil_kmed`i'_L2) lwidth(0.8 0.8 0.8)
							 *gr export "$CLUS\agree_silhouette_kmedian`i'_$type.pdf", as(pdf) replace
							  
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
							
							tab baseline_k3 
							levelsof id_agree if baseline_k3 !=2 
					
					* Append results of baseline
					
					qui putexcel A`j' = "`agree'"
					qui putexcel B`j' = "`p'"
					
					qui sum baseline_k3 if id_agree == `agree'
					local k3b = r(mean)
					qui putexcel C`j' = "`k3b'"

					
					********************************************************************************
					*B/ Run counterfactual datasets one by one and append the results to the excel file
					********************************************************************************
					
					* COUNTERFACTUALS CLASSIFICATION *							 

					********************************************************************************
					* Only X out of XXXX  PTA are 'Deep'

					tab baseline_k3 
					tab id_agree if baseline_k3 == 2

					
						*1.1.1. load new dataset
						global type "w"
						********************************************************************************
						*use "$CLUS/data_agree_cluster_CF/data_agree_cluster_w_40_14.dta", clear
						use "$CLUS/data_agree_cluster_CF/data_agree_cluster_w_`agree'_`p'.dta", clear

							cap drop area_num
							gen area_num = 0
							replace area_num = 1 if Area == "`area'"
							
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

							*Anthonin: For every agreement concerning all economies, we need to know which provisions to implement in order to reach a "k-mean == 2", that is, a DEEP PTA! 
								 
														 
							
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
							*silhouette   k`k' , dist(dist_L2) id(id_agree) gen(sil_k`k'_L2) lwidth(0.8 0.8 0.8)
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

						*1.1.3. store results

							di "Storing results to excel file"
							
							qui sum k3 if id_agree == `agree' 
							local k3m = r(mean)
							qui putexcel D`j' = "`k3m'" 
						
						
						
				}

				
				
			}
				




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


			*1.2. summarize results : which provisions for each PTA allow to go from either shallow/med to deep?

			* Comment here: 

			import excel "$TEMP/switch_opt1_$nole.xlsx", firstrow clear
			destring _all, replace
			gen switch_ = 0
			replace switch_ = 1 if k3 == 2
			tab provision if switch_ == 1 

	
	
}













