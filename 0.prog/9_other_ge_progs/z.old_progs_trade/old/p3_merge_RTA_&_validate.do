
********************************************************************************
********************************************************************************

cap 	log close
capture log using "$PROG\00_log_files\p4_merge_rta_trade", text replace


********************************************************************************
********************************************************************************

import excel "$CLUS/kmeans_final_$type.xlsx", sheet("Sheet1") firstrow clear

rename ID 					 id_agree
rename Clusters_Euclidean_CH kmeanR 
rename KMeans_Scaled         kmeanR_scaled
rename PAM_Euclidean         pamR_eucl
rename PAM_Manhattan         pamR_manh
 
 
 keep id_agree kmean* pam*
destring _all, replace

save "$CLUS/Rtemp_descriptive_stats_$type.dta", replace

merge 1:1 id_agree using "$CLUS/temp_descriptive_stats_$type.dta"
drop _m


keep id_agree $cluster_var  
save "$TEMP/cluster_stats.dta", replace  // 372

********************************************************************************
********************************************************************************
* if not in the cluster list: fix now UK agreements to be same as EU

if "$uk_fix" ==  "fix_after_cluster" {


use "$DTA/uk_agree_to_be_fixed.dta", clear

rename id_agree id_agree_raw

rename id_agree_eu id_agree
drop if id_agree == .

merge 1:m id_agree using  "$TEMP/cluster_stats.dta", keepusing($cluster_var)
keep if _m == 3
drop _m

keep id_agree_raw agreement entry_force $cluster_var
rename id_agree_raw id_agree 
gen uk_agree_to_eu = 1
save  "$TEMP/cluster_value_uk_eu", replace



use "$TEMP/cluster_stats.dta", clear
 

append using  "$TEMP/cluster_value_uk_eu"
save     "$TEMP/cluster_stats.dta", replace 

  }


********************************************************************************
********************************************************************************

use "$DATA/rta_year_od", clear
gen rta  = 1   

merge m:1 id_agree using "$DATA/rta_data_raw.dta", keepusing(Type)
drop if _m == 2                                                     // inactive RTAs
drop _m 

gen    rta_psa     =(Type =="PSA") 
*drop if rta_psa    == 1

********************************************************************************
********************************************************************************


merge m:1 id_agree using "$TEMP/cluster_stats.dta"
		drop 	 if _m == 2
gen     rta_uncluster   =(_m == 1)
		drop 		_m



keep iso_o iso_d year entry_force  $cluster_var id_agree agreement  rta*  Type



cap drop obs
bys iso_o iso_d year  : gen  obs	   = _N
tab obs

* same cluster just different codes: drop overallping links
duplicates drop iso_o iso_d year $cluster_var if obs > 1 , force 



* No recompute the number of redundant links
cap drop obs
bys iso_o iso_d year  : gen  obs	   = _N
tab obs

unique id_agree if obs > 1   // 50 agree overallping 

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
export excel using "$CLUS/RTA_overlap.xlsx", sheet("RTA_overlap")  sheetreplace firstrow(variables) nolabel 
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
merge m:1 iso_o iso_d year using "$DATA/perimeter_opted_out_agreements_od"
drop _m
rename rta_out_v1 rta_out

replace rta_out = 0    if rta == 1
replace rta     = 0    if rta == .

save "$TEMP/bilateral_rta_ctys_$type", replace


********************************************************************************
********************************************************************************
********************************************************************************
* Prepare Gravity   
cd "$DATA/GRAVITY"
unzipfile "gravity.zip", replace 

use gravity, clear

replace wto_o = gatt_o if t < 1995
replace wto_d = gatt_d if t < 1995
rename t year
rename iso3_o iso_o 
rename iso3_d iso_d 



keep year iso_o iso_d  dist distcap contig col_dep_ever comcol col45 wto_o wto_d fta_wto
duplicates drop 


********************************************************************************
* ensure the same perimeter as trade and production dataset

gen iso3 = iso_o

merge m:1 iso3 using "$DATA/cty/TP_FAO_cty_year",
keep if _m == 3
drop _m 

 
drop if year < min_year
drop if year > max_year 

drop min_year
drop max_year
drop iso3 
 
********************************************************************************

gen iso3 = iso_d

merge m:1 iso3 using "$DATA/cty/TP_FAO_cty_year" 
keep if _m == 3
drop _m 

drop if year < min_year
drop if year > max_year 

drop min_year
drop max_year
drop iso3

save "gravity_toolkit.dta", replace


cap erase "gravity.dta"

********************************************************************************
******************************************************************************** 
tempfile temp

use  "$DATA/GRAVITY/language_FT", clear

preserve

keep if iso_o == "SRB"  | iso_d =="SRB"
replace iso_o =  "YUG" if iso_o =="SRB"
replace iso_d =  "YUG" if iso_d =="SRB"

save `temp', replace
restore

append using `temp'

********************************************************************************

preserve

keep if iso_o == "SRB"  | iso_d =="SRB"
replace iso_o =  "SCG" if iso_o =="SRB"
replace iso_d =  "SCG" if iso_d =="SRB"

save `temp', replace
restore

append using `temp'


********************************************************************************
preserve

keep if iso_o == "CZE"  | iso_d =="CZE"
replace iso_o =  "CSK" if iso_o =="CZE"
replace iso_d =  "CSK" if iso_d =="CZE"

save `temp', replace
restore
append using `temp'

********************************************************************************
preserve

keep if iso_o == "RUS"  | iso_d =="RUS"
replace iso_o =  "SUN" if iso_o =="RUS"
replace iso_d =  "SUN" if iso_d =="RUS"

save `temp', replace
restore
append using `temp'

********************************************************************************

gen iso3 = iso_o
merge m:1 iso_o using "$DATA/cty/TP_FAO_cty",
keep if _m == 3
drop _m 
drop iso3

gen iso3 = iso_d
merge m:1 iso_d using "$DATA/cty/TP_FAO_cty",
keep if _m == 3
drop _m 
drop iso3
 
merge 1:m iso_o iso_d using "gravity_toolkit.dta"
drop if _m == 1
drop _m

save "gravity_toolkit.dta", replace


keep if year == 2021
replace year =  year + 1


append using  "gravity_toolkit.dta"

replace  col_dep_ever = 0 if col_dep_ever == .    // CHN-HKG and ISR-PAL
save "gravity_toolkit.dta", replace

use "$DATA/GRAVITY/gravity_toolkit.dta", clear

 

********************************************************************************
********************************************************************************
********************************************************************************
cd "$DATA/cty"

use "$TEMP/bilateral_rta_ctys_$type", clear

 cap drop if iso_o =="YUG" & year >= 2006
 cap drop if iso_d =="YUG" & year >= 2006
 
replace iso_o="SCG" if   ( iso_o=="YUG" ) & ( year  <= 2005  & year >= 1992 )   //  this is because in Comtrade 
replace iso_d="SCG" if   ( iso_d=="YUG" ) & ( year  <= 2005  & year >= 1992 )   //  this is because in Comtrade 


********************************************************************************
* ensure the same perimeter as trade and production dataset

gen iso3 = iso_o

merge m:1 iso3 using "$DATA/cty/TP_FAO_cty_year",    // CSK and SUN but this make sense as they were not in the GATT/WTO
keep if _m == 3
drop _m 

 
drop if year < min_year
drop if year > max_year 

drop min_year
drop max_year
drop iso3 
 
********************************************************************************

gen iso3 = iso_d

merge m:1 iso3 using "$DATA/cty/TP_FAO_cty_year" 
keep if _m == 3
drop _m 

drop if year < min_year
drop if year > max_year 

drop min_year
drop max_year
drop iso3

********************************************************************************
********************************************************************************
 
duplicates drop 

  
merge 1:1 		iso_d	iso_o year using  "$DATA/AGR_MAN_trade_prod_toolkit_V2024"
drop if _m==1		
drop _m

********************************************************************************
********************************************************************************

global var "agreement id_agree entry_force  $cluster_var  kmean_sil   opted_out agreement_opted_out"

foreach var in $var {
sort iso_o iso_d year
bys iso_o iso_d: carryforward  `var', replace
 
}


/* .50  .39 .16
replace rta_out 		 = 0                       	  if rta_out 	== .
replace rta_psa    		 = 0 						  if rta_psa 		== .
replace rta_uncluster    = 0 						  if rta_uncluster 	== .

 
replace rta_out         = 0                          if rta            == 1     // if a valid RTA exists replace opted out  = 0
replace rta             = 0						     if rta_uncluster  == 1
 
replace rta_out         = 1						  	 if rta_uncluster  == 1
replace rta    			= 0 if year < entry_force
replace rta    			= 0 if rta_psa == 1

gen rta_out_psa         =(rta_out == 1 | rta_psa == 1)       
*/

 
replace rta              = 0                          if rta            == . 

replace rta_out 		 = 0                       	  if rta_out 	    == .
replace rta_psa    		 = 0 						  if rta_psa 		== .
replace rta_uncluster    = 0 						  if rta_uncluster 	== .


replace rta_out          = 0                          if rta            == 1     // if a valid RTA exists replace opted out  = 0
gen rta_no_psa          = (rta   -  rta_psa)       

 

merge 1:1 iso_o iso_d year using "$DATA/GRAVITY/gravity_toolkit.dta"
keep if _m == 3
drop _m


compress

********************************************************************************
********************************************************************************

foreach var in   agro_i  agro_ie  agro_igdp      {

     replace `var'                = .  if `var'    == 0 &  iso_o== iso_d

}

********************************************************************************
********************************************************************************

foreach var in    man_i  man_ie  man_igdp   {

     replace `var'                = .  if `var'    == 0 &  iso_o== iso_d

}

********************************************************************************
******************************************************************************** 

compress
label data "This version  $S_TIME  $S_DATE "
save "$DATA/trade_rta_prelim.dta", replace



********************************************************************************
********************************************************************************
* Regressioni preliminari per validare il dataset 
*	- replicare risultati in WBER paper

use "$DATA/trade_rta_prelim.dta", replace

*******************************************************************************
********************************************************************************
* generate International Border interacted with time

cap drop decade
gen 	decade = 1980 if year <= 1989
replace decade = 1990 if year <= 1999 & decade == .
replace decade = 2000 if year <= 2009 & decade == .
replace decade = 2010 if year <= 2024 & decade == .
 
 
 
cap drop INTL_BRDR
 
gen  INTL_BRDR = (iso_o != iso_d)
 cap drop  INTL_BRDR_*
 foreach decade in  1990  2000 2010      {
generate INTL_BRDR_`decade'  = 1 if iso_o != iso_d & decade == `decade'
replace  INTL_BRDR_`decade'  = 0 if INTL_BRDR_`decade' == .
}

********************************************************************************		  
* Heterogenous effect? 

gen rta_old = (rta == 1 & entry_force <= 2000)
gen rta_new = (rta == 1 & entry_force >= 2001)

********************************************************************************		  
********************************************************************************

cap drop ij
cap drop it
cap drop jt
egen ij = group(iso_o iso_d)
egen it = group(iso_o year)
egen jt = group(iso_d year)


gen es_agro_man_i            	= es_man_i*es_agro_i

gen agro_man                 	= man_i    + agro_i   
  
gen agro_ie_man_ie              = man_igdp + agro_igdp   
gen agro_ieX_man_ieX            = man_ie   + agro_ie   


gen agro_ieX_man_i              = man_i    + agro_ie   
gen agro_ie_man_i               = man_i    + agro_igdp   


********************************************************************************
/*******************************************************************************

ppmlhdfe agro_ieX_man_i 	      rta		INTL_BRDR_*  $controls_od  	   				   , a(ij it jt) cluster(ij)    

ppmlhdfe agro_ieX_man_i  rta_new rta_old	INTL_BRDR_*  $controls_od  	  if year <= 2020  , a(ij it jt) cluster(ij)    


ppmlhdfe agro_ieX_man_i 	      rta		INTL_BRDR_*  $controls_od  	   if year <= 2020	, a(ij it jt) cluster(ij)    
 
 
 
ppmlhdfe agro_man   	       rta	INTL_BRDR_*  	 		 $controls_od  	   				, a(ij it jt) cluster(ij)    
outreg2 using  "$GRAV/Structural_Gravity_rta.xls",   dec(3) 	keep(	rta	  $controls_od 	INTL_BRDR_* ) lab replace

ppmlhdfe agro_ie_man_i   	   rta	INTL_BRDR_*  	 		 $controls_od  	   	 			, a(ij it jt) cluster(ij)    
outreg2 using  "$GRAV/Structural_Gravity_rta.xls",   dec(3) 	keep(	rta	  $controls_od 	INTL_BRDR_* ) lab

ppmlhdfe agro_ie_man_ie   	   rta	INTL_BRDR_*  	 		 $controls_od  	   				, a(ij it jt) cluster(ij)    
outreg2 using  "$GRAV/Structural_Gravity_rta.xls",   dec(3) 	keep(	rta	  $controls_od 	INTL_BRDR_* ) lab

ppmlhdfe agro_ie_man_i   rta_no_psa rta_psa	INTL_BRDR_*  	 $controls_od  	   	 			, a(ij it jt) cluster(ij)    
outreg2 using  "$GRAV/Structural_Gravity_rta.xls",   dec(3) 	keep(	rta*  $controls_od 	INTL_BRDR_* ) lab

 
 
*******************************************************************************/
********************************************************************************
********************************************************************************
********************************************************************************
/* option 11
global controls_od              "rta_out wto_od"
global rta                      "rta"
global sym 						"sym"


cap drop wto_od
gen wto_od      = wto_o*wto_d
replace wto_od  = 0              if  iso_o == iso_d
 
local s = 1 


foreach var in kmean   {	
*kmean kmeanR_scaled kmedian h_clus pam pamR_eucl pamR_manh 

 
 cap drop temp
bys `var': egen temp = nvals(iso_o)   if `var' != .
summ temp

replace `var' = 10 					  if temp  == r(min)
replace `var' = 30 					  if temp  == r(max) | rta_uncluster == 1
replace `var' = 20 					  if `var'  < 10
replace `var' = int(`var'/10)



qui tab `var', gen(RTA_k )


replace RTA_k1 	    = 0                    if RTA_k1 == .
replace RTA_k2 	    = 0                    if RTA_k2 == .
replace RTA_k3      = 0                    if RTA_k3 == .

gen rta_k1          = $rta *RTA_k1
gen rta_k2          = $rta *RTA_k2
gen rta_k3          = $rta *RTA_k3

sum  `var' if id_agree == 117
 
global deep=  r(mean)
 display "$deep"
}
*/ 
********************************************************************************



cap drop temp
bys kmean: egen temp = nvals(iso_o)   if kmean != .
summ temp

replace kmean = 10 					  if temp  == r(min)
replace kmean = 30 					  if temp  == r(max) | rta_uncluster == 1
replace kmean = 20 					  if kmean  < 10
replace kmean = int(kmean/10)



qui tab kmean, gen(RTA_k )


replace RTA_k1 	    = 0                    if RTA_k1 == .
replace RTA_k2 	    = 0                    if RTA_k2 == .
replace RTA_k3      = 0                    if RTA_k3 == .



sum  kmean if id_agree == 117

********************************************************************************
********************************************************************************
********************************************************************************
* option 1
global controls_od              "rta_out wto_od"
global rta                      "rta"
global sym 						" "


cap drop rta_k*
gen rta_k1          = $rta *RTA_k1
gen rta_k2          = $rta *RTA_k2
gen rta_k3          = $rta *RTA_k3

global deep=  r(mean)
 display "$deep"


cap drop wto_od
gen wto_od      = wto_o*wto_d
replace wto_od  = 0              if  iso_o == iso_d
replace wto_od  = 0              if  $rta == 1 | rta_uncluster == 1

 
local s = 1
foreach Y in      agro_ieX_man_i agro_ieX_man_ieX agro_ie_man_ie {	

 ppml_panel_sg  `Y'      rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od    , ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)        

if `s' == 1 {
 outreg2 using  "$GRAV/SG_2024_until2018_v1.xls",   dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"  , Deep, $deep  ) lab  replace    
 }


 
if `s' > 1 {
 outreg2 using  "$GRAV/SG_2024_until2018_v1.xls",   dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"  , Deep, $deep  ) lab       
}


local s = `s' + 1

}

 global sym 						"sym"

local s = 1
foreach Y in      agro_ieX_man_i agro_ieX_man_ieX agro_ie_man_ie {	

 ppml_panel_sg  `Y'      rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od   , ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)        

if `s' == 1 {
 outreg2 using  "$GRAV/SG_2024_until2018_v1_sym.xls",   dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"  , Deep, $deep  ) lab  replace    
 }


 
if `s' > 1 {
 outreg2 using  "$GRAV/SG_2024_until2018_v1_sym.xls",   dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"  , Deep, $deep  ) lab       
}


local s = `s' + 1

}

********************************************************************************
********************************************************************************
* option 11
global controls_od              "rta_out wto_od"
global rta                      "rta"
global sym 						" "


cap drop wto_od
gen wto_od      = wto_o*wto_d
replace wto_od  = 0              if  iso_o == iso_d
 
 
local s = 1
foreach Y in      agro_ieX_man_i agro_ieX_man_ieX agro_ie_man_ie {	

 ppml_panel_sg  `Y'      rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od   , ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)        

if `s' == 1 {
 outreg2 using  "$GRAV/SG_2024_until2018_v11.xls",   dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"  , Deep, $deep  ) lab  replace    
 }


 
if `s' > 1 {
 outreg2 using  "$GRAV/SG_2024_until2018_v11.xls",   dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"  , Deep, $deep  ) lab       
}


local s = `s' + 1

}

********************************************************************************
********************************************************************************
 global sym 						"sym"


local s = 1
foreach Y in      agro_ieX_man_i agro_ieX_man_ieX agro_ie_man_ie {	

 ppml_panel_sg  `Y'      rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od   , ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)        

if `s' == 1 {
 outreg2 using  "$GRAV/SG_2024_until2018_v11_sym.xls", dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"  , Deep, $deep  ) lab  replace    
 }


 
if `s' > 1 {
 outreg2 using  "$GRAV/SG_2024_until2018_v11_sym.xls",   dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"  , Deep, $deep  ) lab       
}


local s = `s' + 1

}


********************************************************************************
********************************************************************************
* option 2
global controls_od              "rta_out rta_psa wto_od"
global rta                      "rta_no_psa"
global sym
 

 cap drop rta_k*
 
gen rta_k1          = $rta *RTA_k1
gen rta_k2          = $rta *RTA_k2
gen rta_k3          = $rta *RTA_k3

sum  kmean if id_agree == 117




global deep=  r(mean)
 display "$deep"


cap drop wto_od
gen wto_od      = wto_o*wto_d
replace wto_od  = 0              if  iso_o == iso_d
replace wto_od  = 0              if  $rta == 1 | rta_uncluster == 1


cap drop wto_od
gen wto_od      = wto_o*wto_d
replace wto_od  = 0              if  iso_o == iso_d
 
 
local s = 1
foreach Y in      agro_ieX_man_i agro_ieX_man_ieX agro_ie_man_ie {	

 ppml_panel_sg  `Y'      rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od   , ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)        

if `s' == 1 {
 outreg2 using  "$GRAV/SG_2024_until2018_v2.xls",   dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"  , Deep, $deep  ) lab  replace    
 }


 
if `s' > 1 {
 outreg2 using  "$GRAV/SG_2024_until2018_v2.xls",   dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"  , Deep, $deep  ) lab       
}


local s = `s' + 1

}

********************************************************************************
 global sym 						"sym"


local s = 1
foreach Y in      agro_ieX_man_i agro_ieX_man_ieX agro_ie_man_ie {	

 ppml_panel_sg  `Y'      rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od   , ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)        

if `s' == 1 {
 outreg2 using  "$GRAV/SG_2024_until2018_v2_sym.xls", dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"  , Deep, $deep  ) lab  replace    
 }


 
if `s' > 1 {
 outreg2 using  "$GRAV/SG_2024_until2018_v2_sym.xls",   dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"  , Deep, $deep  ) lab       
}


local s = `s' + 1

}



********************************************************************************
********************************************************************************
********************************************************************************
/*******************************************************************************


use "$TEMP/cluster_stats.dta", clear

keep id_agree agreement entry_force kmean pam


rename pam kmean_robust

export excel using "$CLUS/Cluster_list_$type.xlsx", sheet("agreements")  sheetreplace firstrow(variables) nolabel 

// 372 id_agree in the clusters
/*******************************************************************************
* Once everything is ok, clean the TEMP directory
 cd  "$TEMP" 
 local files : dir "`c(pwd)'"  files "*.dta*" 

foreach file in `files' { 
	erase `file'    
} 
 
*******************************************************************************/
