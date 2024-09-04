
/******************************************************************************* 
	     Deep Trade Agreements Toolkit: Trade and Welfare Impacts 

                  	   this version: APR 2024
				   
website: https://xxxxxxx.org/

when using the tool please cite:  
Fontagné, L., Rocha, N., Ruta, M., Santoni, G. (2022),
 The Economic Impact of Deepening Trade Agreements", CESIfo working paper 9529.  
  
     https://doi.org/10.1093/wber/lhad005.  

corresponding author: gianluca.santoni@cepii.fr
 
*******************************************************************************/
********************************************************************************


clear *

   
set scheme s1color
set excelxlsxlargefile on
version

set seed 01032018

global seed "01032018"

******************************************************************************** 
********************************************************************************
* Define your working path here: this is where you locate the "Toolkit" folder

 
  global DB	              "C:/Users/gianl/Dropbox/"
  global DB              "d:/santoni/Dropbox/"


global ROOT 		      "$DB/WW_other_projs/WB_2024/WB_GE/WB_DTA_Toolkit"			 
 
global PROG 	          "$ROOT/0.prog/TRADE_data_make"
global DATA 	          "$ROOT/1.data"
global COMTRADE			  "$DATA/COMTRADE"	
global UNIDO			  "$DATA/UNIDO"	
global FAO_prod			  "$DATA/FAO/prod/2024"	
global FAO_trade		  "$DATA/FAO/trade/2024"	


global BACI	        	  "$DB/WW_other_projs/DATA/BACI"
global GRAVITY        	  "$DB/WW_other_projs/DATA/GRAVITY"
global LANG                "$DB/WW_other_projs/DATA/LANG"

global DTA                "$DATA"
global TEMP	     		  "$DATA/temp"
global CLUS	     		  "$ROOT/2.res/clusters"
global GRAV	     		  "$ROOT/2.res/gravity"


global baci_version 	   "BACI_HS02_V202401b"
global grav_version 	   "Gravity_V202211"
global countries_gravity   "Countries_V202211"
 


global year_start		  "1986"
global year_end           "2022"

global type				  "w"                        // w: cluster based on weighted matrix
global uk_fix  			  "fix_before_cluser"   
global cluster_var        "kmean kmedian pam h_clus kmeanR_ch kmeanR_asw kmeanR kmeanR_pam kmeanR_man"


cap 	log close
capture log using "$PROG\00_log_files\p4_merge_rta_trade", text replace


********************************************************************************
********************************************************************************

import excel "$CLUS/kmeans_final_$type.xlsx", sheet("Sheet1") firstrow clear

rename V1 id_agree
rename V2 kmeanR_man
rename V3 kmeanR
rename V4 kmeanR_scaled
rename V5 kmeanR_ch
rename V6 kmeanR_asw
rename V7 kmeanR_pam

destring _all, replace

save "$CLUS/Rtemp_descriptive_stats_$type.dta", replace

merge 1:1 id_agree using "$CLUS/temp_descriptive_stats_$type.dta"
drop _m

save "$TEMP/cluster_stats.dta", replace

********************************************************************************
********************************************************************************
* if not in the cluster list: fix now UK agreements to be same as EU

if "$uk_fix" ==  "fix_afer_cluster" {


use "$DTA/uk_agree_to_be_fixed.dta", clear

rename id_agree id_agree_raw

rename id_agree_eu id_agree
drop if id_agree == .

merge 1:m id_agree using  "$TEMP/cluster_stats.dta"
keep if _m == 3
drop _m

keep id_agree_uk agreement entry_force $cluster_var
rename id_agree_uk id_agree 
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
drop if _m == 2 
drop _m 

gen    rta_psa     =(Type =="PSA") 


*drop if rta_psa    == 1

********************************************************************************



merge m:1 id_agree using "$TEMP/cluster_stats.dta"
		drop 	 if _m == 2
gen     rta_uncluster   =(_m == 1)
		drop 		_m

drop if rta  == .
 

keep iso_o iso_d year entry_force  $cluster_var id_agree agreement kmean_sil rta*  Type



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

 


replace rta_out 		 = 0                       	  if rta_out 	== .
replace rta_psa    		 = 0 						  if rta_psa 		== .
replace rta_uncluster    = 0 						  if rta_uncluster 	== .

 
replace rta_out         = 0                          if rta            == 1     // if a valid RTA exists replace opted out  = 0
replace rta             = 0						     if rta_uncluster  == 1
 
replace rta_out         = 1						  	 if rta_uncluster  == 1
replace rta    			= 0 if year < entry_force
replace rta    			= 0 if rta_psa == 1

gen rta_out_psa         =(rta_out == 1 | rta_psa == 1)       

********************************************************************************

merge 1:1 iso_o iso_d year using "$DATA/GRAVITY/gravity_toolkit.dta"
keep if _m == 3
drop _m


compress

********************************************************************************
********************************************************************************

foreach var in   agro_i         {

     replace `var'                = .  if `var'    == 0 &  iso_o== iso_d

}

********************************************************************************
********************************************************************************

foreach var in    man_i       {

     replace `var'                = .  if `var'    == 0 &  iso_o== iso_d

}

********************************************************************************
******************************************************************************** 

compress
label data "This version  $S_TIME  $S_DATE "
save "$DATA\trade_rta_prelim.dta", replace



********************************************************************************
********************************************************************************
* Regressioni preliminari per validare il dataset 
*	- replicare risultati in WBER paper

use "$DATA\trade_rta_prelim.dta", replace

*cap drop if year > 2019

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
gen wto_od      = wto_o*wto_d
replace wto_od  = 0              if iso_o == iso_d
replace wto_od  = 0              if   rta == 1

global wto_od                   "wto_od rta_out_psa"
global sym           			" "									  
********************************************************************************

cap drop ij
cap drop it
cap drop jt
egen ij = group(iso_o iso_d)
egen it = group(iso_o year)
egen jt = group(iso_d year)



gen agro_man                 = man_i + agro_i   
gen es_agro_man_i            =  es_man_i*es_agro_i
 
bys iso_d year: egen totM    = total(man_i)
             gen man_i_sh    = man_i/ totM
 cap drop totM
 
bys iso_d year: egen totM    = total(agro_i)
             gen agro_i_sh   = agro_i/ totM
 cap drop totM
 
 bys iso_d year: egen totM    = total(agro_man)
             gen  agro_man_sh = agro_i/ totM
 cap drop totM
 
********************************************************************************
********************************************************************************


cap erase "$GRAV/Structural_Gravity_rta.xls"
cap erase "$GRAV/Structural_Gravity_rta.txt"


cap erase "$GRAV/Structural_Gravity_man.xls"
cap erase "$GRAV/Structural_Gravity_man.txt"

cap erase "$GRAV/Structural_Gravity_agro.xls"
cap erase "$GRAV/Structural_Gravity_agro.txt"

cap erase "$GRAV/Structural_Gravity_agro_man.xls"
cap erase "$GRAV/Structural_Gravity_agro_man.txt"



cap erase "$GRAV/Structural_Gravity_man_sh.xls"
cap erase "$GRAV/Structural_Gravity_man_sh.txt"

cap erase "$GRAV/Structural_Gravity_agro_sh.xls"
cap erase "$GRAV/Structural_Gravity_agro_sh.txt"

cap erase "$GRAV/Structural_Gravity_agro_man_sh.xls"
cap erase "$GRAV/Structural_Gravity_agro_man_sh.txt"

********************************************************************************
********************************************************************************

 ppmlhdfe man_i    		   rta 	INTL_BRDR_*  	$wto_od  	                                  , a(ij it jt) cluster(ij)    
outreg2 using  "$GRAV/Structural_Gravity_rta.xls",   dec(3) 	keep(	rta	  $wto_od			   	INTL_BRDR_* ) lab replace
 
 ppmlhdfe man_i    		   rta 	INTL_BRDR_*  	$wto_od  	  	 if   es_man_i           == 1 , a(ij it jt) cluster(ij)    
outreg2 using  "$GRAV/Structural_Gravity_rta.xls",   dec(3) 	keep(	rta	  $wto_od			   	INTL_BRDR_* ) lab
 
 ppmlhdfe agro_i		   rta 	INTL_BRDR_*  	$wto_od  	      	    					  , a(ij it jt) cluster(ij)    
outreg2 using  "$GRAV/Structural_Gravity_rta.xls",   dec(3) 	keep(	rta	  $wto_od			   	INTL_BRDR_* ) lab
 
ppmlhdfe agro_i 		   rta 	INTL_BRDR_*  	$wto_od  	      if  	       es_agro_i    == 1 , a(ij it jt) cluster(ij)    
outreg2 using  "$GRAV/Structural_Gravity_rta.xls",   dec(3) 	keep(	rta	  $wto_od			   	INTL_BRDR_* ) lab

ppmlhdfe agro_man   	   rta	INTL_BRDR_*  	$wto_od  	   								  , a(ij it jt) cluster(ij)    
outreg2 using  "$GRAV/Structural_Gravity_rta.xls",   dec(3) 	keep(	rta	  $wto_od			   	INTL_BRDR_* ) lab

ppmlhdfe agro_man   	   rta	INTL_BRDR_*  	$wto_od  	   	 if  	 es_agro_man_i   == 1  , a(ij it jt) cluster(ij)    
outreg2 using  "$GRAV/Structural_Gravity_rta.xls",   dec(3) 	keep(	rta	  $wto_od			   	INTL_BRDR_* ) lab


 
********************************************************************************
********************************************************************************

 foreach var in kmeanR_man kmeanR kmeanR_ch kmeanR_asw kmeanR_pam h_cluster pam kmean kmedian {	

 
 
preserve
 
cap drop temp
bys `var': egen temp = nvals(iso_o)   if `var' != .
summ temp

replace `var' = 10 					  if temp  == r(min)
replace `var' = 30 					  if temp  == r(max)
replace `var' = 20 					  if `var'  < 10
replace `var' = int(`var'/10)



qui tab `var', gen(RTA_k )


replace RTA_k1 	    = 0                    if RTA_k1 == .
replace RTA_k2 	    = 0                    if RTA_k2 == .
replace RTA_k3      = 0                    if RTA_k3 == .

gen rta_k1          = rta *RTA_k1
gen rta_k2          = rta *RTA_k2
gen rta_k3          = rta *RTA_k3

sum  `var' if id_agree == 117

global deep=  r(mean)
 display "$deep"

*********************************
* manufacturing

 
 ppmlhdfe man_i    		   rta_k1 rta_k2 rta_k3 	INTL_BRDR_*  	$wto_od  	       , a(ij it jt) cluster(ij)    
outreg2 using  "$GRAV/Structural_Gravity_man.xls",   dec(3) 	keep(	rta_*	  $wto_od			   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'" , Deep, $deep  ) lab      

*********************************
* agricolture

  
 ppmlhdfe agro_i    	   rta_k1 rta_k2 rta_k3 	INTL_BRDR_*  	$wto_od  	       , a(ij it jt) cluster(ij)    
outreg2 using  "$GRAV/Structural_Gravity_agro.xls",   dec(3) 	keep(	rta_*	  $wto_od			   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"  , Deep, $deep  ) lab      
    

*********************************
* manufacturing + agricolture

ppmlhdfe agro_man    		   rta_k1 rta_k2 rta_k3 	INTL_BRDR_*  	$wto_od  	   , a(ij it jt) cluster(ij)    
outreg2 using  "$GRAV/Structural_Gravity_agro_man.xls",   dec(3) 	keep(	rta_*	  $wto_od			   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"  , Deep, $deep  ) lab      
  

restore

}

********************************************************************************
********************************************************************************


use "$TEMP/cluster_stats.dta", clear

keep id_agree agreement entry_force kmean pam


recode kmean 	  (2 = 1) (3 = 2) (1 = 3)
recode pam        (3 = 1) (2 = 3) (1 = 2)

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
