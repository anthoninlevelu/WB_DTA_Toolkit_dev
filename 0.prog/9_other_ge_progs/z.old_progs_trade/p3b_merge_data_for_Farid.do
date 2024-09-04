
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



keep year iso_o iso_d  dist distcap distw_harmonic distw_arithmetic contig col_dep_ever comcol col45 wto_o wto_d fta_wto
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
 
use  "$TEMP/AGR_MAN_trade_prod_toolkit_V2024", clear

keep iso_o iso_d year agr agr_i man man_i

label var man   "Manufacturing trade, Mln US$ (INDSTAT + COMTRADE)"
label var man_i "Manufacturing trade, Mln US$ (Linear Interpolation Production)"


label var agr   "Agricultural trade, Mln US$ (FAO Prod + FAO Trade)"
label var agr_i "Agricultural trade, Mln US$ (Linear Interpolation Production)"


merge 1:1 iso_o iso_d year using "$DATA/GRAVITY/gravity_toolkit.dta"
keep if _m == 3
drop _m

compress
label data "This version  $S_TIME  $S_DATE "
save "$TEMP/trade_paper_africa_ver2024.dta", replace

********************************************************************************
********************************************************************************
