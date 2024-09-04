********************************************************************************
/******************************************************************************* 
	     The Economic Impact of Deepening Trade Agreements A Toolkit

			       	   this version: JAN 2024
				   
website: https://xxxxxxx.org/

when using the tool please cite:  
Fontagné, L., Rocha, N., Ruta, M., Santoni, G. (2023),
 "The Economic Impact of Deepening Trade Agreements", World Bank Economic Review,  https://doi.org/10.1093/wber/lhad005.  

corresponding author: gianluca.santoni@cepii.fr
 
********************************************************************************
********************************************************************************

clear all
program drop _all
macro drop _all
matrix drop _all
clear mata
clear matrix
   
set virtual on
set more off
set scheme s1color
set excelxlsxlargefile on
version

set seed 01032018

global seed "01032018"

******************************************************************************** 
********************************************************************************
* Define your working path here: this is where you locate the "Toolkit" folder 
 global DB	             "C:\Users\gianl\Dropbox\"
 global DB                "d:\santoni\Dropbox\"

global ROOT 	          "$DB\WW_other_projs\WB_2024\WB_GE\WB_DTA_Toolkit"			 
 
********************************************************************************
********************************************************************************

global PROG 	          "$ROOT\0.prog"
global DATA 	          "$ROOT\1.data"
global DTA                "$DATA\DTA_toolkit_update"
global TEMP	     		  "$DATA\temp"

global CLUS	     		  "$ROOT\2.res\clusters"


global type    		      "w"   // w: weighted provisino matrix ; u: unweighted provision matrix (1/0)
global dataset            "dataset-on-the-intensive-margin-january-2024"  // or dataset-on-the-intensive-margin-december-2023
global cluster_var        "kmean kmedian pam h_clus kmeanR_ch kmeanR_asw kmeanR kmeanR_pam kmeanR_man"
global uk_fix  			  "fix_afer_cluster"   // fix_before_cluser (keep in the cluster UK agreements and use the same provision as EU) or fix_after_cluster (drop UK empty agreements from the cluster fix after withthe same clusters as EU )

cap 	log close 
capture log using "$PROG\log_files\compute_cluster", text replace

*******************************************************************************/
********************************************************************************
/*                  Upload Cluster list                                       */
********************************************************************************
* from R: list(rownames(df)  , res[["Best.partition"]],   k3[["cluster"]],  k3_scaled[["cluster"]], clusters_euclidean_ch, clusters_euclidean_asw, clusters_pam)

import excel "$CLUS\kmeans_final_$type.xlsx", sheet("Sheet1") firstrow clear

rename V1 id_agree
rename V2 kmeanR_man
rename V3 kmeanR
rename V4 kmeanR_scaled
rename V5 kmeanR_ch
rename V6 kmeanR_asw
rename V7 kmeanR_pam

destring _all, replace

save "$CLUS\Rtemp_descriptive_stats_$type.dta", replace

merge 1:1 id_agree using "$CLUS\temp_descriptive_stats_$type.dta"
drop _m

save "$TEMP\cluster_stats.dta", replace

********************************************************************************
********************************************************************************
* if not in the cluster list: fix now UK agreements to be same as EU

if "$uk_fix" ==  "fix_afer_cluster" {


use "$DTA\uk_agree_to_be_fixed.dta", clear

rename id_agree id_agree_raw

rename id_agree_eu id_agree
drop if id_agree == .

merge 1:m id_agree using  "$TEMP\cluster_stats.dta"
keep if _m == 3
drop _m

keep id_agree_uk agreement entry_force $cluster_var
rename id_agree_uk id_agree 
gen uk_agree_to_eu = 1
save  "$TEMP\cluster_value_uk_eu", replace



use "$TEMP\cluster_stats.dta", clear
 

append using  "$TEMP\cluster_value_uk_eu"
save     "$TEMP\cluster_stats.dta", replace 

  }


********************************************************************************


use "$TEMP\cluster_stats.dta", clear

keep id_agree agreement entry_force kmean pam


recode kmean 	  (2 = 1) (3 = 2) (1 = 3)
recode pam        (3 = 1) (2 = 3) (1 = 2)

rename pam kmean_robust

export excel using "$CLUS\Cluster_list_$type.xlsx", sheet("agreements")  sheetreplace firstrow(variables) nolabel 

// 372 id_agree in the clusters
********************************************************************************
********************************************************************************

use "$DATA\rta_year_od", clear
gen rta_v2 = 1   

merge m:1 id_agree using "$TEMP\rta_data_raw.dta", keepusing(Type)
drop if _m == 2 
drop _m 

gen    rta_psa     =(Type =="PSA") 


*drop if rta_psa    == 1

********************************************************************************



merge m:1 id_agree using "$TEMP\cluster_stats.dta"
		drop 	 if _m == 2
gen     rta_uncluster   =(_m == 1)
		drop 		_m

drop if rta_v2 == .
 

keep iso_o iso_d year entry_force  $cluster_var id_agree agreement kmean_sil rta_* Type



cap drop obs
bys iso_o iso_d year  : gen  obs	   = _N
tab obs

* same cluster just different codes: drop overallping links
duplicates drop iso_o iso_d year $cluster_var if obs > 1 , force 



* No recompute the number of redundant links
cap drop obs
bys iso_o iso_d year  : gen  obs	   = _N
tab obs

unique id_agree if obs > 1

********************************************************************************
preserve
keep if obs > 1
egen pair_id = group(iso_o iso_d)
bys id_agree: egen num_pairs = nvals(pair_id)
keep id_agree agreement entry_force year obs num_pairs

bys id_agree: egen start_overlap = min(year)
bys id_agree: egen end_overlap = max(year)
drop year
duplicates drop
*export excel using "$CLUS\issues_to_check.xlsx", sheet("RTA_overlap")  sheetreplace firstrow(variables) nolabel 
export excel using "$CLUS\RTA_overlap.xlsx", sheet("RTA_overlap")  sheetreplace firstrow(variables) nolabel 
restore

********************************************************************************
********************************************************************************
* option 1:  Use the latest
bys iso_o iso_d year: egen temp = max(entry_force)
drop if entry_force < temp & obs > 1 
cap drop temp
cap drop obs
bys iso_o iso_d year  : gen  obs	   = _N
tab obs


*******************************************************************************/
********************************************************************************
/* option 2: Use the oldest
bys iso_o iso_d year: egen temp = min(entry_force)
drop if entry_force > temp & obs > 1 
cap drop temp

cap drop obs
bys iso_o iso_d year  : gen  obs	   = _N
tab obs
cap drop obs
*******************************************************************************/
********************************************************************************
/* option 3: Drop inaccurately estimated clusters  (keep only max silhuette score)
bys iso_o iso_d year: egen temp = max(kmean_sil)
drop if kmean_sil  < temp & obs > 1 
cap drop temp
cap drop obs
bys iso_o iso_d year  : gen  obs	   = _N
tab obs
 
*******************************************************************************/
********************************************************************************

cap drop obs
merge m:1 iso_o iso_d year using "$DATA\perimeter_opted_out_agreements_od"
drop _m

save "$TEMP\bilateral_rta_ctys_$type", replace


********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************

use "$CLUS\ge_gravity_agri_manuf.dta", clear

preserve
bys iso_o: keep if _n == 1
keep iso_o 
save "$TEMP\iso_matched", replace
restore

bys iso_d: keep if _n == 1
keep iso_d 

rename iso_d iso_o
merge 1:1 iso_o using "$TEMP\iso_matched"
drop _m 
gen iso_d = iso_o
save "$TEMP\iso_matched", replace


********************************************************************************
********************************************************************************


use "$TEMP\bilateral_rta_ctys_$type", clear


merge m:1 iso_o using "$TEMP\iso_matched", keepusing(iso_o)
keep if _m == 3
drop _m 

merge m:1 iso_d using "$TEMP\iso_matched", keepusing(iso_d)
keep if _m == 3
drop _m 

drop if year > 2019
save "$TEMP\bilateral_rta_ctys_test_$type", replace


*******************************************************************************/
********************************************************************************
/*                  Upload trade Data from Toolkit v0                         */
********************************************************************************
********************************************************************************

use "$CLUS\ge_gravity_agri_manuf.dta", clear

merge 1:1 iso_o iso_d t using "$CLUS\ge_gravity_manuf.dta", keepusing (trade_m trade_m_sh)
drop _m 

keep   iso_o iso_d t jt it rta rta_out rta_k1 rta_k2 rta_k3 trade_am trade_am_sh trade_m trade_m_sh decade INTL_BRDR INTL_BRDR_1990 INTL_BRDR_2000 INTL_BRDR_2010  rta_k1 rta_k2 rta_k3 agreement entry_force  
gen year  = t
tab year
rename agreement agreement_v0
rename entry_force entry_force_v0


merge 1:1 iso_o iso_d year using "$TEMP\bilateral_rta_ctys_test_$type", 
drop if _m == 2
drop _m 


global var "agreement id_agree entry_force  $cluster_var  kmean_sil   opted_out agreement_opted_out"

foreach var in $var {
sort iso_o iso_d year
bys iso_o iso_d: carryforward  `var', replace
 
}

order agreement agreement_opted_out year rta_v1 rta_out_v1



replace rta_v1     		 = 0 						  if rta_v1 		== .
replace rta_out_v1 		 = 0                       	  if rta_out_v1 	== .
replace rta_psa    		 = 0 						  if rta_psa 		== .
replace rta_uncluster    = 0 						  if rta_uncluster 	== .

 
replace rta_out_v1       = 0                          if rta_v1         == 1     // if a valid RTA exists replace opted out  = 0
  replace rta_v1         = 0						  if rta_uncluster  == 1
*replace rta_v1          = 0       				  	  if   rta_psa      == 1

  replace rta_out_v1     = 1						  if rta_uncluster  == 1
*replace rta_out_v1      = 1						  if rta_psa        == 1

*replace rta_psa         = 0       				  	  if rta_out_v1     == 1     // if a valid RTA exists replace opted out  = 0
*replace rta_v1          = 0       				  	  if   rta_psa      == 1


********************************************************************************
********************************************************************************

merge 1:1 iso_o iso_d year using "$CLUS\gravity_wto_temp"
drop if _m == 2
drop _m 
 
********************************************************************************
cap erase "$CLUS\\Structural_Gravity_sh.xls"
cap erase "$CLUS\\Structural_Gravity_sh.txt"

cap erase "$CLUS\\Structural_Gravity_lev.xls"
cap erase "$CLUS\\Structural_Gravity_lev.txt"


********************************************************************************
global wto_od                   "   "
global sym           			" "									  


cap drop ij
cap drop it
cap drop jt
egen ij = group(iso_o iso_d)
egen it = group(iso_o year)
egen jt = group(iso_d year)

recode kmean 	  (2 = 1) (3 = 2) (1 = 3)
recode pam        (3 = 1) (2 = 3) (1 = 2)

/*
ppml_panel_sg trade_am_sh  	rta 				   			INTL_BRDR_*  	$wto_od 	rta_out, ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)    
outreg2 using  "$CLUS\\Structural_Gravity_sh.xls",   dec(3) 	keep(rta	$wto_od  	rta_out		   	INTL_BRDR_* ) addtext(Period, Full,   Cluster,  None   ) lab      replace

ppml_panel_sg trade_am_sh  	rta_v1 				   			INTL_BRDR_*  	$wto_od 	rta_out_v1, ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)    
outreg2 using  "$CLUS\\Structural_Gravity_sh.xls",   dec(3) 	keep(rta_v1	$wto_od 	rta_out_v1  	INTL_BRDR_* ) addtext(Period, Full,   Cluster,  None   ) lab      
*/


 *foreach var in $cluster_var {
	*kmeanR_asw kmeanR_pam kmedian 
 foreach var in kmean pam {	
preserve
 



qui tab `var', gen(RTA_k_v1)


replace RTA_k_v11 	= 0                    if RTA_k_v11 == .
replace RTA_k_v12 	= 0                    if RTA_k_v12 == .
replace RTA_k_v13   = 0                    if RTA_k_v13 == .

gen rta_k1_v1       = rta_v1*RTA_k_v11
gen rta_k2_v1       = rta_v1*RTA_k_v12
gen rta_k3_v1       = rta_v1*RTA_k_v13

 
global wto_od                   "rta_out_v1"
global sym           			"sym"									  

 ppmlhdfe trade_am_sh  	rta_k1_v1 rta_k2_v1 rta_k3_v1 	INTL_BRDR_*  	$wto_od  	  , a(ij it jt) cluster(ij)    
outreg2 using  "$CLUS\\Structural_Gravity_sh.xls",   dec(3) 	keep(	rta_k1_v1 rta_k2_v1 rta_k3_v1	  $wto_od			   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"   ) lab      
 
 ppml_panel_sg trade_am_sh  	rta_k1_v1 rta_k2_v1 rta_k3_v1 	INTL_BRDR_*  	$wto_od  	 , ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)    
outreg2 using  "$CLUS\\Structural_Gravity_sh.xls",   dec(3) 	keep(	rta_k1_v1 rta_k2_v1 rta_k3_v1	  $wto_od			   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"   ) lab      
 
 ppmlhdfe trade_m_sh  	rta_k1_v1 rta_k2_v1 rta_k3_v1 	INTL_BRDR_*  	$wto_od  	  , a(ij it jt) cluster(ij)    
outreg2 using  "$CLUS\\Structural_Gravity_sh.xls",   dec(3) 	keep(	rta_k1_v1 rta_k2_v1 rta_k3_v1	  $wto_od			   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"   ) lab      
 
  ppml_panel_sg trade_m_sh  	rta_k1_v1 rta_k2_v1 rta_k3_v1 	INTL_BRDR_*  	$wto_od  	 , ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)    
outreg2 using  "$CLUS\\Structural_Gravity_sh.xls",   dec(3) 	keep(	rta_k1_v1 rta_k2_v1 rta_k3_v1	  $wto_od			   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"   ) lab      
 

restore

}



 foreach var in kmean pam {	
preserve
 



qui tab `var', gen(RTA_k_v1)


replace RTA_k_v11 	= 0                    if RTA_k_v11 == .
replace RTA_k_v12 	= 0                    if RTA_k_v12 == .
replace RTA_k_v13   = 0                    if RTA_k_v13 == .

gen rta_k1_v1       = rta_v1*RTA_k_v11
gen rta_k2_v1       = rta_v1*RTA_k_v12
gen rta_k3_v1       = rta_v1*RTA_k_v13

 
global wto_od                   "rta_out_v1"
global sym           			"sym"									  

 ppmlhdfe trade_am   		rta_k1_v1 rta_k2_v1 rta_k3_v1 	INTL_BRDR_*  	$wto_od  	  , a(ij it jt) cluster(ij)    
outreg2 using  "$CLUS\\Structural_Gravity_lev.xls",   dec(3) 	keep(	rta_k1_v1 rta_k2_v1 rta_k3_v1	  $wto_od			   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"   ) lab      
 
 ppml_panel_sg trade_am   	rta_k1_v1 rta_k2_v1 rta_k3_v1 	INTL_BRDR_*  	$wto_od  	 , ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)    
outreg2 using  "$CLUS\\Structural_Gravity_lev.xls",   dec(3) 	keep(	rta_k1_v1 rta_k2_v1 rta_k3_v1	  $wto_od			   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"   ) lab      
 
 ppmlhdfe trade_m  		  	rta_k1_v1 rta_k2_v1 rta_k3_v1 	INTL_BRDR_*  	$wto_od  	  , a(ij it jt) cluster(ij)    
outreg2 using  "$CLUS\\Structural_Gravity_lev.xls",   dec(3) 	keep(	rta_k1_v1 rta_k2_v1 rta_k3_v1	  $wto_od			   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"   ) lab      
 
  ppml_panel_sg trade_m  	rta_k1_v1 rta_k2_v1 rta_k3_v1 	INTL_BRDR_*  	$wto_od  	 , ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)    
outreg2 using  "$CLUS\\Structural_Gravity_lev.xls",   dec(3) 	keep(	rta_k1_v1 rta_k2_v1 rta_k3_v1	  $wto_od			   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"   ) lab      
 

restore

}
********************************************************************************
********************************************************************************
