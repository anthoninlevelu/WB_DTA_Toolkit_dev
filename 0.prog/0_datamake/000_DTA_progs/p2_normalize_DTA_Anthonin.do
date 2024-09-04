

********************************************************************************
********************************************************************************

cap 	log close
capture log using "$PROG/log_file/normalize_data", text replace


  
******************************************************************************** 
********************************************************************************

*** OPTION 1 : COUNTERFACTUAL DATASETS ***


** The goal is to recreate datasets for each AreaXPTA that are pushed to 1 ** 
** We also recreate files for Legally Enforceable. PTAs.
** Then we redo the cluster with those new datasets and compare with the baseline **


* global for AreaXPTA

global area `" "Antidumping Duties" "Competition Policy" "Countervailing Duties" "Environmental Laws" "Export Restrictions" "Intellectual Property Rights (IPR)" "Investment" "Labor Market Regulations" "Movement of Capital" "Public Procurement" "Rules of Origin" "Sanitary and Phytosanitary Measures (SPS)" "Services" "State Owned Enterprises" "Subsidies" "Technical Barriers to Trade (TBT)" "Trade Facilitation and Customs" "Visa and Asylum"  "' 


* global for all PTA (we create counterfactual dataset for each PTA)

global all_agree "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 183 184 186 187 188 189 190 191 192 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255 256 257 258 259 260 261 262 263 264 265 266 267 268 269 270 271 272 273 274 275 276 277 278 279 280 281 282 283 284 285 286 287 288 289 290 291 292 293 294 295 296 297 298 299 300 301 302 303 304 305 306 307 308 309 311 312 313 318 319 320 321 322 323 324 326 327 330 331 332 333 338 340 341 342 343 345 346 347 348 349 350 351 352 353 354 355 356 357 358 359 360 361 363 364 366 367 368 369 370 372 373 374 375 376 377 378 379 380 381 382 383 384 385 386 388 389 390 391 393 394 395 396 398 399 400"


foreach pta of global all_agree {
	
	di "AGREEMENT number: `pta'"		
	local pta = `pta' 
	local v = 0
	local j = 0
	
	foreach are of global area {
		
		local v = `v' + 1
		local j = `j' + 1
		di "----- AREA number `v' : `are' -----"   
	
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
		
		
	
		di "Area number: `are'" 
		di "Push provision to 1"
		replace rta_deep = 1 if (rta_deep == 0 | rta_deep == .) & (Area == "`are'" & id_agree == `pta')
		
		
		gen 	rta_w      						= 			 rta_deep

		replace rta_w 				 			=  0      if rta_w == .   			  /* all  weigthed */

		gen 	rta_u      						= 			 rta_deep
		replace rta_u  							=  0      if rta_u == .   			  /* all  un-weigthed */

		replace rta_u  							=  1      if rta_u >  0 & rta_u != .  /* Dichotomize */

		gen     rta_w_pos 				 		=  			 rta_w
		replace rta_w_pos  						=  .      if rta_w_pos == 0   		  /* only positives    weigthed */

		gen     rta_u_pos 				 		=  			 rta_u
		replace rta_u_pos  						=  .      if rta_u_pos == 0   		  /* only positives un-weigthed */

		********************************************************************************
		/******************************************************************************/
		* drop provision always 0: 934/1071 provisions with at least one non zero entry 

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



		 
		* gen stats by provision: ROW normalization
		bys id_provision	: egen mean_w		=     mean(rta_w )
		bys id_provision	: egen mean_u		=     mean(rta_u )
		bys id_provision	: egen mean_u_pos	=     mean(rta_u_pos )
		bys id_provision	: egen mean_w_pos	=     mean(rta_w_pos)
		 

		 
		 
		 // First: rescale by average on positives only so provisions are on a comparable scale
		   replace rta_w   					    =    ( rta_w / mean_w_pos)   
		  

		 // Second: rescale further by the probability of having a non-zero: rare provisions get more weigth
		   replace rta_w   						=    ( rta_w / mean_u)       
		   replace rta_u   						=    ( rta_u / mean_u)         


		********************************************************************************
		********************************************************************************

		// option 1: geometric average without zeros
		   generate lrta_deep_w 					=  ln( rta_w)
		   generate lrta_deep_u 					=  ln( rta_u)

		// option 2: geometric average with zeros
		*  generate lrta_deep_w 					= ln(   (rta_w) + [   (rta_w^2) +  1]^0.5)
		*  generate lrta_deep_u 					= ln(   (rta_u) + [   (rta_u^2) +  1]^0.5)

		// option 3: simple average without zeros
		* replace   rta_w						    =  .   if rta_w == 0
		* replace   rta_u						    =  .   if rta_u == 0


		  collapse (mean) lrta* rta_w  rta_u	, by(Area id_agree)


		// option 1: geometric average
		 replace 			  lrta_deep_w 		= exp(lrta_deep_w)    
		 replace 			  lrta_deep_u 		= exp(lrta_deep_u) 

		// option 2: simpele average
		*  replace 			  lrta_deep_w 		= rta_w    
		*  replace 			  lrta_deep_u 		= rta_u 

		 replace   			  lrta_deep_w		=  0   if lrta_deep_w == 0
		 replace   			  lrta_deep_u		=  0   if lrta_deep_u == 0


		egen id_provision 						= group(Area)
		
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
		merge 1:1 Area id_agree using `horizontal'
		drop if _merge == 2
		drop _merge 
		
		gen lrta_deep_w_le = lrta_deep_w
		gen lrta_deep_u_le = lrta_deep_u

		*replace the score to 0 if not LE! keep as is if LE 
		replace lrta_deep_w_le = 0 if status == 0 
		replace lrta_deep_w_le = 0 if status == 1 
		
		replace lrta_deep_u_le = 0 if status == 0
		replace lrta_deep_u_le = 0 if status == 1 
		
		drop status
		
		********************************************************************************
		********************************************************************************
		// Save dta files
		 
		preserve
		keep Area id_provision
		bys id_provision: keep if _n== 1
		qui save "$CLUS/data_agree_cluster_CF/id_area_legend_`pta'_`j'", replace
		restore

		compress

		preserve
		rename   lrta_deep_w   rta_deep_std
		rename   lrta_deep_w_le   rta_deep_std_le
		/* Save data for clustering: weighted taking into account the degree of provisions */
		qui save "$CLUS/data_agree_cluster_CF/data_agree_cluster_w_`pta'_`j'", replace

		restore

		preserve
		rename   lrta_deep_u   rta_deep_std
		rename   lrta_deep_u_le   rta_deep_std_le
		/* Save data for clustering: unweighted 1/0 provisions */
		qui save "$CLUS/data_agree_cluster_CF/data_agree_cluster_u_`pta'_`j'", replace

		restore
				
		
		
    }
}















 
********************************************************************************
********************************************************************************
