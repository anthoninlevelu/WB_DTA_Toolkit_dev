
********************************************************************************
********************************************************************************

cap 	log close
capture log using "$PROG\00_log_files\p4_merge_rta_trade", text replace



********************************************************************************

import excel "$CLUS/kmeans_final_$type.xlsx", sheet("Sheet1") firstrow clear

rename ID 					 id_agree
rename Clusters_Euclidean_CH kmeanR 
rename PAM_Euclidean         pamR_eucl
rename PAM_Manhattan         pamR_manh
 
 
 keep id_agree kmean* pam*
destring _all, replace

save "$CLUS/Rtemp_descriptive_stats_$type.dta", replace

merge 1:1 id_agree using "$CLUS/temp_descriptive_stats_$type.dta"
drop _m


 
foreach var in $cluster_var {
	
gen raw_`var'  = `var'	
	
}
 
save "$TEMP/cluster_stats.dta", replace 
unique id_agree // 372 if PSA incuded ; 350 when PSA not included

********************************************************************************
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
gen rta_all  = 1   

merge m:1 id_agree using "$TEMP/rta_data_raw.dta", keepusing(Type)
drop if _m == 2                                                     // inactive RTAs
drop _m 

gen    rta_psa     =(Type =="PSA") 
*drop if rta_psa    == 1

********************************************************************************
********************************************************************************


merge m:1 id_agree using "$TEMP/cluster_stats.dta"
		drop 	 if _m == 2
gen     rta_uncluster   =(_m == 1)
gen     rta_cluster     =(_m == 3)
					drop _m



keep iso_o iso_d year entry_force  $cluster_var id_agree agreement  rta*  Type  raw_*
unique id_agree


 



cap drop obs
bys iso_o iso_d year  : gen  obs	   = _N
tab obs

* same cluster just different codes: drop overallping links
duplicates drop iso_o iso_d year $cluster_var if obs > 1 , force 



* No recompute the number of redundant links
cap drop obs
bys iso_o iso_d year  : gen  obs	   = _N
tab obs

unique id_agree if obs > 1   // 42 agree overallping 

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
unique id_agree

********************************************************************************
********************************************************************************
* option 1:  Use the latest
bys iso_o iso_d year: egen temp = max(entry_force)
drop if entry_force < temp & obs > 1 
cap drop temp
cap drop obs
bys iso_o iso_d year  : gen  obs	   = _N
tab obs
unique id_agree
 
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
drop if kmean_sil  != temp & obs > 1 
cap drop temp
cap drop obs
bys iso_o iso_d year  : gen  obs	   = _N
tab obs
unique id_agree
*******************************************************************************/
********************************************************************************

cap drop obs
merge m:1 iso_o iso_d year using "$DATA/perimeter_opted_out_agreements_od"
drop _m
rename rta_out_v1 rta_out
 
save "$TEMP/bilateral_rta_ctys_$type", replace


********************************************************************************
********************************************************************************
********************************************************************************
* Prepare Gravity   
cd "$DATA/GRAVITY"
unzipfile "gravity.zip", replace 

use gravity, clear
rename t year
rename iso3_o iso_o 
rename iso3_d iso_d 


// this was the copding in the first version  (until june 5, 2024)
*replace wto_o = gatt_o if t < 1995
*replace wto_d = gatt_d if t < 1995

gen wto_od      = wto_o *wto_d
gen gatt_od     = gatt_o*gatt_d

replace wto_od  =  0 if iso_o == iso_d
replace gatt_od =  0 if iso_o == iso_d





keep year iso_o iso_d  dist distcap distw_harmonic distw_arithmetic contig col_dep_ever comcol col45 wto_od gatt_od fta_wto eu_o eu_d
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
 
keep iso_o iso_d  lpn cnl lps csl cor
 
merge 1:m iso_o iso_d using "gravity_toolkit.dta"
drop if _m == 1
drop _m

save "gravity_toolkit.dta", replace


keep if year == 2021
replace year =  year + 1


append using  "gravity_toolkit.dta"

replace  col_dep_ever = 0 if col_dep_ever == .    // CHN-HKG and ISR-PAL
save "gravity_toolkit.dta", replace

 
 

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

  
merge 1:1 		iso_d	iso_o year using  "$TEMP/AGR_MAN_trade_prod_toolkit_V2024"
drop if _m==1		
drop _m

********************************************************************************
********************************************************************************

global var "agreement id_agree entry_force  $cluster_var  kmean_sil   opted_out agreement_opted_out"

foreach var in $var {
sort iso_o iso_d year
bys iso_o iso_d: carryforward  `var', replace
 
}

 
 foreach var in rta_all rta_psa rta_uncluster rta_cluster rta_out {

 replace 		   `var' = 0 						  if `var'			== .
}
 
 
 
 
replace rta_uncluster	 = 0                       	  if rta_psa     	== 1  
replace rta_cluster  	 = 0                       	  if rta_psa     	== 1  

 gen rta_est             = rta_cluster + rta_uncluster
 
replace rta_out 		 = 0                       	  if rta_psa     	== 1  
replace rta_out 		 = 0                       	  if rta_est     	== 1  

merge 1:1 iso_o iso_d year using "$DATA/GRAVITY/gravity_toolkit.dta"
keep if _m == 3
drop _m


compress

********************************************************************************
********************************************************************************

foreach var in     agr_ix  agr_iy agr_iyl agr_igdp      {

     replace `var'                = .  if `var'    == 0 &  iso_o== iso_d

}

********************************************************************************
********************************************************************************

foreach var in    man_ix  man_iy  man_iyl man_igdp   {

     replace `var'                = .  if `var'    == 0 &  iso_o== iso_d

}

********************************************************************************
******************************************************************************** 

compress
label data "This version  $S_TIME  $S_DATE "
save "$TEMP/trade_rta_prelim_ver2024.dta", replace



********************************************************************************
********************************************************************************
* Regressioni preliminari per validare il dataset 
*	- replicare risultati in WBER paper

use "$TEMP/trade_rta_prelim_ver2024.dta", clear


********************************************************************************
* add region origin and region destination
   gen iso3  = iso_o     // iso_o is the original identifier
   
    
   
replace iso3 = "ROM"       if iso3  == "ROU"
replace iso3 = "WBG"       if iso3  == "PSE"
replace iso3 = "SRB"       if iso3  == "YUG" 
replace iso3 = "SRB"       if iso3  == "SCG" 
replace iso3 = "RUS"       if iso3  == "SUN" 
replace iso3 = "CZE"       if iso3  == "CSK" 
 
merge m:1 iso3 using "$DATA/CTY/WBregio.dta" 
drop if _m ==2
drop _m
drop iso3

rename region region_o
 
   gen iso3  = iso_d     // iso_o is the original identifier
   
    
   
replace iso3 = "ROM"       if iso3  == "ROU"
replace iso3 = "WBG"       if iso3  == "PSE"
replace iso3 = "SRB"       if iso3  == "YUG" 
replace iso3 = "SRB"       if iso3  == "SCG" 
replace iso3 = "RUS"       if iso3  == "SUN" 
replace iso3 = "CZE"       if iso3  == "CSK" 
 
merge m:1 iso3 using "$DATA/CTY/WBregio.dta" 
drop if _m ==2
drop _m
drop iso3

rename region region_d
 
********************************************************************************
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

generate INTL_BRDR_`decade'  = 1         if iso_o != iso_d & decade == `decade'
replace  INTL_BRDR_`decade'  = 0         if INTL_BRDR_`decade' == .

}


********************************************************************************
********************************************************************************		  
* aggregate: es_igdp_man + es_igdp_agr

gen agro_man                 	= man_i    + agr_i   
gen agro_ieY_man_ieY            = man_iy   + agr_iy   
gen agro_ieYl_man_ieYl          = man_iyl   + agr_iyl   


gen agro_ieV_man_ieV            = man_igdp + agr_igdp   
gen agro_ieX_man_i              = man_i   + agr_ix   
gen agro_ieY_man_i              = man_i   + agr_iy   
gen agro_ieV_man_i              = man_i   + agr_igdp   


gen es_ii                       = es_man_i    * es_agr_i
gen es_gdp                      = es_igdp_man * es_igdp_agr
gen es_iy                       = es_iy_man   * es_iy_agr
gen es_iyl                      = es_iyl_man  * es_iyl_agr


********************************************************************************
********************************************************************************
* Recode clusters from the least populated (No. 1) to the most populated (No. 3)
label var kmedian   	"kmedian"
label var kmean 		"kmean"
label var pamR_eucl 	"pam"

foreach var in h_clus kmedian kmean pamR_eucl   pam   {	
 tab `var'

qui {
cap drop rta_k*
cap drop RTA_k*
cap drop temp

bys `var': egen temp = nvals(iso_o)   if `var' != .
summ temp  , d                           

global group_min = `r(min)'
global group_max = `r(max)'

replace `var' = 10 					     if  temp  == $group_min						 	& `var' != . 
replace `var' = 30 					     if  temp  == $group_max 						    & `var' != .  
replace `var' = 20 					     if (temp  >  $group_min & temp < $group_max )    	& `var' != . 
replace `var' = 30                       if rta_uncluster == 1  // most populated cluster 

replace `var' = int(`var'/10)
 }
 
tab `var'
 


 
}


egen  min_clus = rowmin(h_clus kmedian kmean pamR_eucl)
egen  max_clus = rowmax(h_clus kmedian kmean pamR_eucl)

gen     avg_k  = .
// Model averaging: weighting more less ambiguous clusters
replace avg_k  = 1 						if min_clus == 1 & max_clus == 1
replace avg_k  = 2 						if min_clus == 2 & max_clus == 2
replace avg_k  = 3 						if min_clus == 3 & max_clus == 3

replace avg_k  = 2 						if min_clus == 1 & max_clus >  1
replace avg_k  = 3 						if min_clus == 2 & max_clus >  2


*
foreach var in avg_k h_clus kmedian kmean pamR_eucl   pam   {	 
 tab `var'
// recode after running the regressions
 recode `var' (1 = 1) ( 3 = 2 ) ( 2 = 3)   
 
}
*/

*egen    avg_k = rowmean(h_clus kmedian kmean pamR_eucl)  
*replace avg_k = round(avg_k)


cap drop ij
cap drop it
cap drop jt

egen i_iso = group(iso_o)
egen j_iso = group(iso_d)

egen ij    =  group(iso_o iso_d)
egen it    = group(iso_o year)
egen jt    = group(iso_d year)

gen sym_id1 = iso_o
gen sym_id2 = iso_d

replace sym_id1 = iso_d if iso_d < iso_o
replace sym_id2 = iso_o if iso_d < iso_o
egen sym_pair_id = group(sym_id1 sym_id2)

cap drop sym_id1
cap drop sym_id2



compress
label data "This version  $S_TIME  $S_DATE "
save "$DATA/trade_rta_ver2024.dta", replace

********************************************************************************
********************************************************************************

use "$DATA/trade_rta_ver2024.dta", clear
keep id_agree kmean
duplicates drop

save "$TEMP/kmean_recoding", replace
 

********************************************************************************
********************************************************************************

import excel "$CLUS/kmeans_coordinates.xlsx", sheet("Sheet1") firstrow clear

rename V1 id_agree

rename V2 kmean_check

rename V3 x_pca
rename V4 y_pca

merge m:1 id_agree using "$TEMP/rta_data_raw.dta", keepusing(Type agreement)
drop if _m == 2
drop _m 


merge m:1 id_agree using "$TEMP/cluster_stats.dta", keepusing(kmean )
drop if _m == 2
drop _m 

tab kmean kmean_check
cap drop kmean
cap drop kmean_check

merge m:1 id_agree using "$TEMP/kmean_recoding.dta" 
keep if _m == 3
drop _m 


sum y_pca, d
sort y_pca
replace y_pca = y_pca[_n-1]*(1.05) if y_pca ==r(max) 
sum y_pca, d
gsort -y_pca
replace y_pca = y_pca[_n-1]*(1.05) if y_pca ==r(min) 



sum x_pca, d
sort   x_pca
replace x_pca = x_pca[_n-1]*(1.05) if x_pca ==r(max) 
gsort -x_pca
replace x_pca = x_pca[_n-1]*(1.05) if x_pca ==r(min) 


sum x_pca
replace x_pca =  x_pca - r(mean)


sum y_pca
replace y_pca =  y_pca - r(mean)

*replace x_pca = x_pca*-1
*replace y_pca = y_pca*-1
********************************************************************************
********************************************************************************

cap drop label
gen 	label = "" 



********************************************************************************
********************************************************************************

tw (scatter y_pca x_pca if kmean ==  1  , 	mcolor(dkorange) 	 mlcolor(dkorange) 	mlwidth(medium) msymbol(Oh)  msize(medium)  mlabel(label)   mlabposition(6)  mlabgap(1)  mlabcolor(cranberry)    ) /* 
*/ (scatter y_pca x_pca if kmean ==  2 	, 	mcolor(gs10) mlcolor(gs10) 	mlwidth(medium) msymbol(Th)  msize(medium) mlabel(label)   mlabposition(4) mlabgap(0) mlabangle(30) mlabcolor(cranberry)  	) /*
*/ (scatter y_pca x_pca if kmean ==  3 	,  mcolor(dknavy*.75) mlcolor(dknavy*.75) mlwidth(medium) msymbol(Dh)  msize(medium) mlabel(label) mlabposition(7) mlabgap(-2pt) mlabcolor(cranberry)  )  , /*
*/ legend(label(1 "Cluster 1") label(2 "Cluster 2") label(3 "Cluster 3") row(1) order(1 2 3) region(lwidth(none) margin(medium))) ytitle("PC2 (12.6 % )") xtitle("PC1 (66.5 %)") plotregion(lwidth(none) margin(medium) ) 
gr export "$CLUS/space_cluster.pdf", as(pdf) replace

gen     kmean_rec = kmean

replace kmean_rec = 4  if kmean_rec == 3 &  y_pca < 0.60


tw (scatter y_pca x_pca if kmean_rec ==  1  , 	mcolor(dkorange) 	 mlcolor(dkorange) 	mlwidth(medium) msymbol(Oh)  msize(medium)  mlabel(label)   mlabposition(6)  mlabgap(1)  mlabcolor(cranberry)    ) /* 
*/ (scatter y_pca x_pca if kmean_rec ==  2 	, 	mcolor(gs10) mlcolor(gs10) 	mlwidth(medium) msymbol(Th)  msize(medium) mlabel(label)   mlabposition(4) mlabgap(0) mlabangle(30) mlabcolor(cranberry)  	) /*
*/ (scatter y_pca x_pca if kmean_rec ==  3 	,  mcolor(dknavy*.75) mlcolor(dknavy*.75) mlwidth(medium) msymbol(Dh)  msize(medium) mlabel(label) mlabposition(7) mlabgap(-2pt) mlabcolor(cranberry)  )   /*
*/ (scatter y_pca x_pca if kmean_rec ==  4	,  mcolor(gs10) mlcolor(gs10) mlwidth(medium) msymbol(Dh)  msize(medium) mlabel(label) mlabposition(7) mlabgap(-2pt) mlabcolor(cranberry)  )  , /*
*/ legend(label(1 "Cluster 1") label(2 "Cluster 2") label(3 "Cluster 3") label(4 "Cluster 3 (recoded)") row(1) order(1 2 3) region(lwidth(none) margin(medium))) ytitle("PC2 (12.6 % )") xtitle("PC1 (66.5 %)") plotregion(lwidth(none) margin(medium) ) 
gr export "$CLUS/space_cluster_rec.pdf", as(pdf) replace


replace kmean_rec = 2 if kmean_rec ==  4	

save "$TEMP/cluster_coord_recoded.dta", replace  

********************************************************************************
********************************************************************************

use "$DATA/trade_rta_ver2024.dta", clear

	
merge m:1 id_agree using "$TEMP/cluster_coord_recoded.dta" , keepusing(kmean_rec)
drop _m 

	compress
label data "This version  $S_TIME  $S_DATE "
save "$DATA/trade_rta_ver2024.dta", replace
 
******************************************************************************** 
* Save WB region toolkit data

use "$DATA/trade_rta_ver2024.dta", clear

keep iso_o region_o
rename iso_o iso3
rename region_o region

duplicates drop

save "$CTY/WBregio_toolkit", replace

********************************************************************************
* option Retained: # 3  The best among those above
use "$DATA/trade_rta_ver2024.dta", clear


preserve

keep id_agree  kmean  
drop if kmean == .
duplicates  drop 

merge 1:1 id_agree using  "$TEMP/cluster_stats.dta", keepusing(raw_kmean )
gen unclassed_agree = (_m == 1)

label var unclassed_agree "Empty provisions assigned to the most populous class, medium "
drop _m

merge 1:1 id_agree using  "$DATA/rta_list.dta"
drop if _m == 2 
drop _m

merge m:1 id_agree using "$TEMP/rta_data_raw.dta", keepusing(Type)
drop if _m == 2 
drop _m

gen  cluster  = ""
replace cluster = "Deep"     if kmean == 1
replace cluster = "Medium"   if kmean == 2
replace cluster = "Shallow"  if kmean == 3

gsort raw_kmean -cluster
bys raw_kmean: carryforward cluster, replace
cap drop kmean 
cap drop raw_kmean

gen PSA  = strpos(Type, "PSA" )

save "$DATA/agree_list_ALL", replace // this to be used in the make of the tables
restore 



global controls_od              "rta_out rta_psa wto_od"
global rta                      "rta_est"
global sym 						"sym"

gen mfn_od      = wto_od
replace mfn_od  = 0                     if  iso_o    == iso_d
replace mfn_od  = 0                     if   $rta    == 1
 

preserve

cap drop RTA_k*
cap drop rta_k*

qui tab kmean, gen(RTA_k )

replace RTA_k1 	    = 0                    if RTA_k1 == .
replace RTA_k2 	    = 0                    if RTA_k2 == .
replace RTA_k3      = 0                    if RTA_k3 == .

gen rta_k1          = $rta *RTA_k1
gen rta_k2          = $rta *RTA_k2
gen rta_k3          = $rta *RTA_k3

sum  kmean if id_agree == 117

ppmlhdfe agro_ieY_man_ieY    rta_k1 rta_k2 rta_k3     			INTL_BRDR_*  	$controls_od   if es_iy == 1  			 , a(it jt sym_pair_id) cluster(ij) d 
keep if e(sample)

keep iso_o iso_d year id_agree agreement entry_force region_* agro_ieY_man_ieY $rta rta_all $dist_lang $controls_od id_agree_opted_out agreement_opted_out opted_out rta_out kmean avg_k kmean_rec kmedian pamR_eucl h_clus decade INTL_BRDR* wto_o wto_d i_iso j_iso ij it jt sym_pair_id es_ii mfn_od

compress
label data "This version  $S_TIME  $S_DATE "
save "$DATA/TradeProd_Data_Toolkit_2024.dta", replace
restore 

********************************************************************************
*******************************************************************************

use "$DATA/TradeProd_Data_Toolkit_2024.dta", clear
 
replace region_o="Africa" if region_o =="Sub-Saharan Africa" 
replace region_o="Africa" if iso_o =="ARE" | iso_o =="DZA" | iso_o =="EGY" | iso_o =="MAR" | iso_o =="TUN"
replace region_d="Africa" if region_d =="Sub-Saharan Africa" 
replace region_d="Africa" if iso_d =="ARE" | iso_d =="DZA" | iso_d =="EGY" | iso_d =="MAR" | iso_d =="TUN"

gen temp_afr = ( region_o=="Africa" | region_d=="Africa"  )

bys id_agree: egen Africa_dummy = max(temp_afr) 

preserve
keep id_agree agreement entry_force kmean avg_k kmean_rec kmedian pamR_eucl
duplicates drop 

save "$DATA/agree_list_GE", replace // this to be used in the make of the tables
restore 

keep if  rta_est == 1 | rta_psa == 1
duplicates drop
keep id_agree agreement entry_force kmean rta_est rta_psa Africa_dummy
export excel using "$CLUS/Cluster_list_$type.xlsx", sheet("agreements")  sheetreplace firstrow(variables) nolabel 

*******************************************************************************/
********************************************************************************