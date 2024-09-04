
******************************************************************************** 
********************************************************************************

cap 	log close

capture log using "$PROG/log_files/p00_prepare_freight", text replace


cd "$FREIGHT"

********************************************************************************
********************************************************************************
* unzip conversion table 


unzipfile "Concordance_H0_to_I3", replace

import delimited "JobID-6_Concordance_H0_to_I3", clear

keep hs198892productcode isicrevision3productcode

rename hs198892productcode hs88

rename isicrevision3productcode isic

save "$TEMP/temp_isic_hs", replace

******************************************************************************** 
********************************************************************************
*clean 
local files : dir "`c(pwd)'"  files "JobID*.csv" 

foreach file in `files' { 
	erase `file'    
} 

cap erase [Content_Types].xml
********************************************************************************
********************************************************************************
* unzip OECD Maritime freight data

unzipfile "OECD_transport_costs", replace

 import delimited "MTC_Data+FootnotesLegend_1b8053de-0eb4-461b-9503-92a202dcdee8.csv", clear

keep if strpos(meastransportcostmeasures, "TR_ADVA")    // ad valorem transport cost

gen year = substr(timeyear, 1, 4)

split comh0commodity, parse(:)

gen length = length( comh0commodity1)

keep if length == 6


destring comh0commodity1, gen(hs88) force


bys hs88: egen mean_ad_costs   =   mean(value) 
bys hs88: egen median_ad_costs = median(value)

tab year

collapse (mean) mean_ad_costs median_ad_costs, by(hs88)
 
merge 1:1 hs88 using  "$TEMP/temp_isic_hs"
 keep if _m == 3
 drop _m
 
gen  chapt_isic = int(isic/100)
gen      sector = ""
replace  sector = "manuf" if chapt_isic >= 15 & chapt_isic<= 36
replace  sector = "min"   if chapt_isic >= 10 & chapt_isic<= 14
replace  sector = "agro"  if chapt_isic == 1

collapse (mean) mean_ad_costs median_ad_costs, by(sector)

save "$DATA/decaf_stats", replace


use  "$DATA/decaf_stats", clear

summ mean_ad_costs if sector == "manuf", d
global  tc_man        = r(mean)
 
summ mean_ad_costs if sector == "agro", d
global  tc_agr        = r(p50) 
 
summ mean_ad_costs if sector == "min", d
global  tc_min        = r(mean) 
  
 
******************************************************************************** 
********************************************************************************
*clean 
local files : dir "`c(pwd)'"  files "MTC_*.csv" 

foreach file in `files' { 
	erase `file'    
} 

local files : dir "`c(pwd)'"  files "MTC_*.txt" 

foreach file in `files' { 
	erase `file'    
} 


******************************************************************************** 
********************************************************************************
