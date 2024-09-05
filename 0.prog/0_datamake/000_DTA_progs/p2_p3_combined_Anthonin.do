

********************************************************************************
********************************************************************************

cap 	log close
capture log using "$PROG/log_file/p2_p3_combined", text replace

** The goal is to recreate datasets for each AreaXPTA that are pushed to 1 ** 
** We also recreate files for Legally Enforceable. PTAs.
** Then we redo the cluster with those new datasets and compare with the baseline **
** Both steps (p2 and p3) are combined in one do-file using tempfile to avoid creating new datasets at every iteration.


* global for AreaXPTA

global area `" "Antidumping Duties" "Competition Policy" "Countervailing Duties" "Environmental Laws" "Export Restrictions" "Intellectual Property Rights (IPR)" "Investment" "Labor Market Regulations" "Movement of Capital" "Public Procurement" "Rules of Origin" "Sanitary and Phytosanitary Measures (SPS)" "Services" "State Owned Enterprises" "Subsidies" "Technical Barriers to Trade (TBT)" "Trade Facilitation and Customs" "Visa and Asylum"  "' 


* global for all PTA (we create counterfactual dataset temp files for each PTA)

global all_agree "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 183 184 186 187 188 189 190 191 192 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255 256 257 258 259 260 261 262 263 264 265 266 267 268 269 270 271 272 273 274 275 276 277 278 279 280 281 282 283 284 285 286 287 288 289 290 291 292 293 294 295 296 297 298 299 300 301 302 303 304 305 306 307 308 309 311 312 313 318 319 320 321 322 323 324 326 327 330 331 332 333 338 340 341 342 343 345 346 347 348 349 350 351 352 353 354 355 356 357 358 359 360 361 363 364 366 367 368 369 370 372 373 374 375 376 377 378 379 380 381 382 383 384 385 386 388 389 390 391 393 394 395 396 398 399 400"


* global for LE or non- LE (this should be added to the '0.Master_DTA.do' do.file.)

macro drop le
// global le "_le"
 


* setup excel output

if "$le" == "_le" {
	
		putexcel set "$TEMP/switch_opt1__le.xlsx", replace
		putexcel A1 = "id_agree"
		putexcel B1 = "provision"
		putexcel C1 = "k3_baseline"
		putexcel D1 = "k3" 
}

else {
		putexcel set "$TEMP/switch_opt1__nole.xlsx", replace
		putexcel A1 = "id_agree"
		putexcel B1 = "provision"
		putexcel C1 = "k3_baseline"
		putexcel D1 = "k3" 
}




local j = 1




foreach pta of global all_agree {
	
	di "----- AGREEMENT number: `pta' -----"	
	
	local pta = `pta' 
	local p = 0
	
	foreach are of global area {
		
		********************************************************************************
		* A/ CREATE COUNTERFACTUAL DATASET

		local p = `p' + 1
		local j = `j' + 1
		
		di "----- AREA number `p' : `are' -----"   
	
		cd "$TEMP"
		
		use rta_data_for_cluster, clear
		
		
		********************************************************************************
		* select the same agreements 

		qui merge m:1 id_agree using "$DATA/rta_list", keepusing(id_agree)  
		keep if _m == 3
		drop _m

		********************************************************************************
		* Drop PSA  we do  not include in the cluster the PSA 

		if "$drop_psa" == "YES" {
		qui merge m:1 id_agree using "$TEMP/rta_data_raw.dta", keepusing(Type)
		drop if _m == 2 
		drop _m 

		gen    rta_psa     = (Type =="PSA")
		drop if rta_psa    == 1
		}

		*******************************************************************************/



		keep Area id_provision id_agree rta_deep Coding  uk_agree_to_eu


		qui merge m:1 id_provision using "$DATA/provision_list"
		keep if _m == 3
		drop _m

		********************************************************************************
		********************************************************************************
		// the shorter period minimizes disruptions to trade hence deeper agreement (is this correct?)

		* Antidumping Duties:Imposition and collection of anti-dumping duties -  duty shall not exceed the margin of dumping 
		replace rta_deep   = 1/rta_deep 		if  strpos( Area , "Antidumping")            & (strpos( Coding ,    "prov_28") )         &	 rta_deep != 0


		* Antidumping Duties: Imposition and collection of anti-dumping duties  - lesser duty rule 
		replace rta_deep   = 1/rta_deep 		if  strpos( Area , "Antidumping")            & (strpos( Coding ,    "prov_29") )         & rta_deep != 0

		* Antidumping Duties: Duration and review of anti-dumping duties and price undertakings:  - - duration - established period
		replace rta_deep   = 1/rta_deep 		if  strpos( Area , "Antidumping")            & (strpos( Coding ,    "prov_33") )         & rta_deep != 0



		******************************************************************************** 
		******************************************************************************** 
		   
		* Rules of Origin: What is the length of the record keeping period?
		replace rta_deep   = 1/rta_deep 		if strpos( Area , "Rules of Origin")         &    strpos( Coding , "roo_cer_rec")        &  rta_deep != 0

		* Rules of Origin:   What is the percentage of value content required?
		replace rta_deep   = 1/rta_deep 		if strpos( Area , "Rules of Origin")         &    strpos( Coding , "roo_vcr_per")        &  rta_deep != 0

		* Rules of Origin:   What is the percentage of value content required? (alternative measure)
		replace rta_deep   = 1/rta_deep 		if strpos( Area , "Rules of Origin")         &    strpos( Coding , "roo_vcr_per2")       &  rta_deep != 0
		
		
		******************************************************************************** 
		******************************************************************************** 

		// Add LE information
		
				preserve
				u "$DATA/Alvaro_31_07/PTA_Policy_Areas.dta", clear
				foreach var of varlist h_IPR ExportTaxes Customs SPS TBT STE AD CVM h_Investment /// 
					StateAid Services PublicProcurement VisaandAsylum CompetitionPolicy EnvironmentalLaws ///
					LabourMarketRegulation MovementofCapital {
						rename `var' p_`var'
				}
				reshape long p_, i(WBID) j(prov_, string) 
				rename (WBID prov_ p_) (id_agree Area status)
				
				replace Area = "Antidumping Duties" if Area == "AD"
				replace Area = "Competition Policy" if Area == "CompetitionPolicy"
				replace Area = "Countervailing Duties" if Area == "CVM"
				replace Area = "Environmental Laws" if Area == "EnvironmentalLaws"
				replace Area = "Export Restrictions" if Area == "ExportTaxes"
				replace Area = "Intellectual Property Rights (IPR)" if Area == "h_IPR"
				replace Area = "Investment" if Area == "h_Investment"
				replace Area = "Labor Market Regulations" if Area == "Labor Market Regulations"
				replace Area = "Movement of Capital" if Area == "MovementofCapital"
				replace Area = "Public Procurement" if Area == "PublicProcurement"
				*NA for RoOs
				replace Area = "Rules of Origin" if Area == "Rules of Origin" 
				replace Area = "Sanitary and Phytosanitary Measures (SPS)" if Area == "SPS"
				replace Area = "Services" if Area == "Services"
				replace Area = "State Owned Enterprises" if Area == "STE"
				replace Area = "Subsidies" if Area == "StateAid"
				replace Area = "Technical Barriers to Trade (TBT)" if Area == "TBT"
				replace Area = "Trade Facilitation and Customs" if Area == "Customs"
				replace Area = "Visa and Asylum" if Area == "VisaandAsylum"

				tempfile horizontal
				save `horizontal'
				restore
		
		*we drop observations from the horizontal database*
		merge m:1 Area id_agree using `horizontal'
		drop if _merge == 2
		drop _merge 
		
		* replace all rta_deep (provisions) within a given Area to zero if the Area is not LE!
		
		gen rta_deep_le = rta_deep
		replace rta_deep_le = 0 if status == 0
		drop status
		
		********************************************************************************
		********************************************************************************

		di "Area number: `are'" 
		di "Push provision to 1"
		replace rta_deep = 1 if (rta_deep == 0 | rta_deep == .) & (Area == "`are'" & id_agree == `pta')
		replace rta_deep_le = 1 if (rta_deep_le == 0 | rta_deep_le == .) & (Area == "`are'" & id_agree == `pta')

		/// non-LE
		
		gen 	rta_w      						= 			 rta_deep

		replace rta_w 				 			=  0      if rta_w == .   			  /* all  weigthed */

		gen 	rta_u      						= 			 rta_deep
		replace rta_u  							=  0      if rta_u == .   			  /* all  un-weigthed */

		replace rta_u  							=  1      if rta_u >  0 & rta_u != .  /* Dichotomize */

		gen     rta_w_pos 				 		=  			 rta_w
		replace rta_w_pos  						=  .      if rta_w_pos == 0   		  /* only positives    weigthed */

		gen     rta_u_pos 				 		=  			 rta_u
		replace rta_u_pos  						=  .      if rta_u_pos == 0   		  /* only positives un-weigthed */
		
		
		/// LE
		
		gen 	rta_w_le      						= 			 rta_deep_le 

		replace rta_w_le  				 			=  0      if rta_w_le  == .   			  /* all  weigthed */

		gen 	rta_u_le       						= 			 rta_deep_le 
		replace rta_u_le   							=  0      if rta_u_le  == .   			  /* all  un-weigthed */

		replace rta_u_le   							=  1      if rta_u_le  >  0 & rta_u_le  != .  /* Dichotomize */

		gen     rta_w_pos_le  				 		=  			 rta_w_le 
		replace rta_w_pos_le   						=  .      if rta_w_pos_le  == 0   		  /* only positives    weigthed */

		gen     rta_u_pos_le  				 		=  			 rta_u_le 
		replace rta_u_pos_le   						=  .      if rta_u_pos_le  == 0   		  /* only positives un-weigthed */
		
		

		********************************************************************************
		/******************************************************************************/
		* drop provision always 0 in the non-LE version: 934/1071 provisions with at least one non zero entry 

		cap drop max_prov_w
		bys id_provision	: egen max_prov_w	=     max(rta_u )


		***************************************
		* 137 provisions all zero
// 		preserve
// 		merge m:1  id_provision using "$DATA/provision_list", keepusing(Area   Coding   Provision)
// 		keep if   max_prov_w == 0
// 		unique id_provision
// 		keep id_provision  Area   Coding   Provision
// 		duplicates drop
// 		export excel using "$CLUS/issues_to_check.xlsx", sheet("provisions_with_all_zero_entry")  sheetreplace firstrow(variables) nolabel 
// 		restore
		cap drop if max_prov_w  == 0

		*******************************************************************************/
		********************************************************************************

		cap drop max_prov_w
		bys id_agree    	: egen max_prov_w	=     max(rta_u )


		***************************************
		* why this 10 agreement have all zeros? 

// 		preserve
// 		merge m:1  id_agree using "$DATA/rta_list", keepusing(agreement entry_force)
//
// 		unique id_agree if   max_prov_w == 0
// 		keep if   max_prov_w == 0
// 		keep agreement  id_agree entry_force
//
// 		duplicates drop
// 		merge 1:1 id_agree using "$TEMP/rta_data_raw.dta", keepusing(Type)
// 		drop if _m == 2
// 		drop _m
// 		export excel using "$CLUS/issues_to_check.xlsx", sheet("agreements_with_all_zero_entry")  sheetreplace firstrow(variables) nolabel 
//
// 		restore

		drop if max_prov_w  == 0



		********************************************************************************
		********************************************************************************
		if "$uk_fix" ==  "fix_after_cluster" {

		* drop UK will be fixed as EU after the clustering is finished
		 drop if uk_agree_to_eu == 1
		 
		}

		********************************************************************************
		********************************************************************************


		unique id_agree    // finally using 372 agreements for the clusters


		********************************************************************************
		********************************************************************************

	
		* gen stats by provision, non-LE: ROW normalization
		bys id_provision	: egen mean_w		=     mean(rta_w )
		bys id_provision	: egen mean_u		=     mean(rta_u )
		bys id_provision	: egen mean_u_pos	=     mean(rta_u_pos )
		bys id_provision	: egen mean_w_pos	=     mean(rta_w_pos)
		
		* gen stats by provision, LE: ROW normalization
		bys id_provision	: egen mean_w_le		=     mean(rta_w_le )
		bys id_provision	: egen mean_u_le		=     mean(rta_u_le )
		bys id_provision	: egen mean_u_pos_le	=     mean(rta_u_pos_le )
		bys id_provision	: egen mean_w_pos_le	=     mean(rta_w_pos_le)
		
		 
		 

		 
		 
		 // First: rescale by average on positives only so provisions are on a comparable scale
		   replace rta_w   					    =    ( rta_w / mean_w_pos)   
		   
		   replace rta_w_le   					    =    ( rta_w_le / mean_w_pos_le)   


		 // Second: rescale further by the probability of having a non-zero: rare provisions get more weigth
		   replace rta_w   						=    ( rta_w / mean_u)       
		   replace rta_u   						=    ( rta_u / mean_u) 
		   
		   replace rta_w_le   						=    ( rta_w_le / mean_u_le)       
		   replace rta_u_le   						=    ( rta_u_le / mean_u_le)  


		********************************************************************************
		********************************************************************************

		// option 1: geometric average without zeros
		   generate lrta_deep_w 					=  ln( rta_w)
		   generate lrta_deep_u 					=  ln( rta_u)
		   
		   generate lrta_deep_w_le 					=  ln( rta_w_le)
		   generate lrta_deep_u_le 					=  ln( rta_u_le)

		// option 2: geometric average with zeros
		*  generate lrta_deep_w 					= ln(   (rta_w) + [   (rta_w^2) +  1]^0.5)
		*  generate lrta_deep_u 					= ln(   (rta_u) + [   (rta_u^2) +  1]^0.5)

		// option 3: simple average without zeros
		* replace   rta_w						    =  .   if rta_w == 0
		* replace   rta_u						    =  .   if rta_u == 0


		  collapse (mean) lrta* rta_w*  rta_u*	, by(Area id_agree)


		// option 1: geometric average
		 replace 			  lrta_deep_w 		= exp(lrta_deep_w)    
		 replace 			  lrta_deep_u 		= exp(lrta_deep_u) 
		 
		 replace 			  lrta_deep_w_le 		= exp(lrta_deep_w_le)    
		 replace 			  lrta_deep_u_le 		= exp(lrta_deep_u_le) 

		// option 2: simpele average
		*  replace 			  lrta_deep_w 		= rta_w    
		*  replace 			  lrta_deep_u 		= rta_u 

		 replace   			  lrta_deep_w		=  0   if lrta_deep_w == 0
		 replace   			  lrta_deep_u		=  0   if lrta_deep_u == 0
		 
		 replace   			  lrta_deep_w_le		=  0   if lrta_deep_w_le == 0
		 replace   			  lrta_deep_u_le		=  0   if lrta_deep_u_le == 0


		egen id_provision 						= group(Area)
		
		********************************************************************************
		********************************************************************************
		
		// create tempfiles
		 
		preserve
		keep Area id_provision
		bys id_provision: keep if _n== 1
		tempfile id_area_legend_`pta'_`p'
		save `id_area_legend_`pta'_`p''
		restore

		compress

		preserve
		rename   lrta_deep_w   rta_deep_std
		rename   lrta_deep_w_le   rta_deep_std_le
		/* Save data for clustering: weighted taking into account the degree of provisions */
		tempfile data_agree_cluster_w_`pta'_`p'
		save `data_agree_cluster_w_`pta'_`p''
		restore

		preserve
		rename   lrta_deep_u   rta_deep_std
		rename   lrta_deep_u_le   rta_deep_std_le
		/* Save data for clustering: unweighted 1/0 provisions */
		tempfile data_agree_cluster_u_`pta'_`p'
		save `data_agree_cluster_u_`pta'_`p'' 

		restore
				



		********************************************************************************
		* B/ CREATE COUNTERFACTUAL CLUSTERS

		set graphics off

		* This way, we run either the clustering with LE or non-LE policy areas.

		********
		** LE **
		********

		if "$le" == "_le" {

					* start loop

							di "CLUSTERING LE for: "
							di "Agreement: `pta'"
							di "Area: `are'" 
							di "Area number: `p'"
							
							********************************************************************************
							*B.1/ Run baseline clustering and append the results to the excel file (this step can be improved as very repetitive)
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
									
									* Fix deep PTA cluster number = 0 based on EC-enlargement 27 (117)
									
									sum baseline_k3 if id_agree == 117
									local deep = r(mean)
									replace baseline_k3 = 0 if baseline_k3 == `deep'
									tab baseline_k3
									
									*levelsof id_agree if baseline_k3 != 0
									
									
							
							* Append results of baseline
							
							qui putexcel A`j' = "`pta'"
							qui putexcel B`j' = "`p'"
							
							qui sum baseline_k3 if id_agree == `pta'
							local k3b = r(mean)
							qui putexcel C`j' = "`k3b'"

							
							********************************************************************************
							*B.2/ Run counterfactual datasets one by one and append the results to the excel file
							********************************************************************************
							
							* COUNTERFACTUALS CLASSIFICATION *							 

							********************************************************************************
							* Only X out of XXXX  PTA are 'Deep'

							
								*1.1.1. load temp dataset
								global type "w"
								********************************************************************************
								use `data_agree_cluster_w_`pta'_`p'', clear

									cap drop area_num
									gen area_num = 0
									replace area_num = 1 if Area == "`are'"
									
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
								
									* Fix deep PTA cluster number = 0 based on EC-enlargement 27 (117)
									
									sum k3 if id_agree == 117
									local deep = r(mean)
									replace k3 = 0 if k3 == `deep'
									
									di "Storing results to excel file"
									
									qui sum k3 if id_agree == `pta'
									local k3m = r(mean)
									qui putexcel D`j' = "`k3m'" 
									
									
								
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

						



						}

		************
		** NON-LE **
		************

		else {


					* start loop
							
							* start loop

							di "CLUSTERING non-LE for: "
							di "Agreement: `pta'"
							di "Area: `are'" 
							di "Area number: `p'"
							
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
									
									* Fix deep PTA cluster number = 0 based on EC-enlargement 27 (117)
									
									sum baseline_k3 if id_agree == 117
									local deep = r(mean)
									replace baseline_k3 = 0 if baseline_k3 == `deep'
									tab baseline_k3
									
									*levelsof id_agree if baseline_k3 != 0
							
							* Append results of baseline
							
							qui putexcel A`j' = "`pta'"
							qui putexcel B`j' = "`p'"
							
							qui sum baseline_k3 if id_agree == `pta'
							local k3b = r(mean)
							qui putexcel C`j' = "`k3b'"

							
							********************************************************************************
							*B/ Run counterfactual datasets one by one and append the results to the excel file
							********************************************************************************
							
							* COUNTERFACTUALS CLASSIFICATION *							 

							********************************************************************************
							* Only X out of XXXX  PTA are 'Deep'

							
								*1.1.1. load temp dataset
								global type "w"
								********************************************************************************
								*use "$CLUS/data_agree_cluster_CF/data_agree_cluster_w_40_14.dta", clear 
								use `data_agree_cluster_w_`pta'_`p'', clear
									cap drop area_num
									gen area_num = 0
									replace area_num = 1 if Area == "`are'"
									
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
								
									* Fix deep PTA cluster number = 0 based on EC-enlargement 27 (117)
									
									sum k3 if id_agree == 117
									local deep = r(mean)
									replace k3 = 0 if k3 == `deep'

									di "Storing results to excel file"
									
									qui sum k3 if id_agree == `pta'
									local k3m = r(mean)
									qui putexcel D`j' = "`k3m'" 
									
									
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
											
								
								
						}

						
						
					
					
			

		
    }
	
	
}




*** SUMMARY RESULTS ***


*1.1. summarize results : which provisions for each PTA allow to go from either shallow/med to deep (LE) ?

* Comment here: 

import excel "$TEMP/switch_opt1__le.xlsx", firstrow clear
destring _all, replace
gen switch_ = 0
replace switch_ = 1 if k3 == 0 & k3 != k3_b 
tab provision if switch_ == 1 
sort id_agree
by id_agree: egen switchany_ = sum(switch_)
replace switchany_ = 1 if switchany_ >= 1
replace switchany_ = 1 if k3_baseline == 0

//           1 |        321       14.37       14.37
//           2 |        156        6.98       21.35
//           3 |        121        5.42       26.77
//           4 |        177        7.92       34.69
//           5 |        167        7.48       42.17
//           6 |         16        0.72       42.88
//           7 |        204        9.13       52.01
//           8 |        181        8.10       60.12
//           9 |         37        1.66       61.77
//          10 |        178        7.97       69.74
//          11 |         16        0.72       70.46
//          12 |         59        2.64       73.10
//          13 |        159        7.12       80.21
//          14 |         13        0.58       80.80
//          15 |        173        7.74       88.54
//          16 |         79        3.54       92.08
//          17 |        156        6.98       99.06
//          18 |         21        0.94      100.00




*1.2. summarize results : which provisions for each PTA allow to go from either shallow/med to deep (non-LE)?

* Comment here: 

import excel "$TEMP/switch_opt1__nole.xlsx", firstrow clear
destring _all, replace
gen switch_ = 0
replace switch_ = 1 if k3 == 0 & k3 != k3_b 
tab provision if switch_ == 1 
sort id_agree
by id_agree: egen switchany_ = sum(switch_)
replace switchany_ = 1 if switchany_ >= 1
replace switchany_ = 1 if k3_baseline == 0


//           1 |        290       39.19       39.19
//           3 |         28        3.78       42.97
//           9 |         77       10.41       53.38
//          12 |        339       45.81       99.19
//          16 |          2        0.27       99.46
//          18 |          4        0.54      100.00











 
********************************************************************************
********************************************************************************
