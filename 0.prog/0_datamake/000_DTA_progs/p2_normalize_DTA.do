

********************************************************************************
********************************************************************************

cap 	log close
capture log using "$PROG/og_file/normalize_data", text replace


********************************************************************************
********************************************************************************

cd "$TEMP"
use rta_data_for_cluster, clear


********************************************************************************
* select the same agreements 
 
merge m:1 id_agree using "$DATA/rta_list", keepusing(id_agree)  
keep if _m == 3
drop _m

********************************************************************************
* Drop PSA  we do  not include in the cluster the PSA 

if "$drop_psa" == "YES" {
merge m:1 id_agree using "$TEMP/rta_data_raw.dta", keepusing(Type)
drop if _m == 2 
drop _m 

gen    rta_psa     = (Type =="PSA")
drop if rta_psa    == 1
}

*******************************************************************************/



keep Area id_provision id_agree rta_deep Coding  uk_agree_to_eu


merge m:1 id_provision using "$DATA/provision_list"
keep if _m == 3
drop _m

********************************************************************************
********************************************************************************
// the shorter period minimizes disruptions to trade hence deeper agreement (is this correct?)

* Antidumping Duties:Imposition and collection of anti-dumping duties -  duty shall not exceed the margin of dumping 
  replace rta_deep   = 1/rta_deep 		if  strpos( Area , "Antidumping")            & (strpos( Coding ,    "prov_28") )         & rta_deep != 0


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

gen 	rta_w      						= 			 rta_deep

replace rta_w 				 			=  0      if rta_w == .   			  /* all  weigthed */

gen 	rta_u      						= 			 rta_deep
replace rta_u  							=  0      if rta_u == .   			  /* all  un-weigthed */

replace rta_u  							=  1      if rta_u >  0 & rta_u != .  /* Dicotomize */

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
preserve
merge m:1  id_provision using "$DATA/provision_list", keepusing(Area   Coding   Provision)
keep if   max_prov_w == 0
unique id_provision
keep id_provision  Area   Coding   Provision
duplicates drop
export excel using "$CLUS/issues_to_check.xlsx", sheet("provisions_with_all_zero_entry")  sheetreplace firstrow(variables) nolabel 
restore
cap drop if max_prov_w  == 0

*******************************************************************************/
********************************************************************************

cap drop max_prov_w
bys id_agree    	: egen max_prov_w	=     max(rta_u )


***************************************
* why this 10 agreement have all zeros? 

preserve
merge m:1  id_agree using "$DATA/rta_list", keepusing(agreement entry_force)

unique id_agree if   max_prov_w == 0
keep if   max_prov_w == 0
keep agreement  id_agree entry_force

duplicates drop
merge 1:1 id_agree using "$TEMP/rta_data_raw.dta", keepusing(Type)
drop if _m == 2
drop _m
export excel using "$CLUS/issues_to_check.xlsx", sheet("agreements_with_all_zero_entry")  sheetreplace firstrow(variables) nolabel 

restore

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

		
 
preserve
keep Area id_provision
bys id_provision: keep if _n== 1
save "$CLUS/id_area_legend", replace
restore

compress

preserve
rename   lrta_deep_w   rta_deep_std
rename	 lrta_deep_w_le   rta_deep_std_le
/* Save data for clustering: weighted taking into account the degree of provisions */
save "$CLUS/data_agree_cluster_w", replace

restore

preserve
rename   lrta_deep_u   rta_deep_std
rename	 lrta_deep_u_le   rta_deep_std_le
/* Save data for clustering: unweighted 1/0 provisions */
save "$CLUS/data_agree_cluster_u", replace

restore

 
********************************************************************************
********************************************************************************
