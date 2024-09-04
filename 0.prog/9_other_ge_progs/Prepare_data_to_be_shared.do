
********************************************************************************
********************************************************************************
* for Ariell & Geoffrey
use "$DATA/TradeProd_Data_Toolkit_2024.dta", clear
 
keep region_o region_d iso_o iso_d year id_agree entry_force agreement rta_est agro_ieY_man_ieY es_ii man_i agr_i sym_pair_id jt it ij  cor cnl csl lpn lps distw_harmonic distw_arithmetic dist distcap contig comcol wto_o wto_d 

label var cor  "Common official language, 1/0, DICL Database"
label var cnl  "common native language index, DICL Database"    
label var csl  "common spoken language index, DICL Database"    
label var lpn  "native language proximity index, DICL Database"    
label var lps  "spoken language proximity index, DICL Database"    


label var rta_est     "RTA in force, World Bank DTA, V2"
label var id_agree    "ID agree , World Bank DTA, V2"
label var agreement   "Agreement, World Bank DTA, V2"
label var entry_force "Date of Entry into Force (G), World Bank DTA, V2"

rta_est id_agree entry_force agreement

rename agro_ieY_man_ieY agro_man_iy
label var agro_man_iy "agro + manuf, domestic sales extrapolated"
 
label var es_ii "agro + manuf rectangular dataset, no extrapolation of domestic sales"



note: 
note: when using the tool please cite: Fontagné, L., Rocha, N., Ruta, M., Santoni, G. (2023), The Economic Impact of Deepening Trade Agreements, World Bank Economic Review,  https://doi.org/10.1093/wber/lhad005.  
note: corresponding author: gianluca.santoni@cepii.fr


save "d:\santoni\Dropbox\WW_other_projs\WB_2024\WB_GE\WB_DTA_Toolkit\1.data\TradeProd_Aggregate_Data_2024.dta"

********************************************************************************
********************************************************************************
* Prepare Gravity   : with Farid
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
* for camilo
use "d:\santoni\Dropbox\WW_other_projs\WB_2024\WB_GE\WB_DTA_Toolkit\1.data\TradeProd_Data_Toolkit_2024.dta" 
keep iso_o iso_d year man_i agr_i man_iy agr_iy man_iy agr_iy es_ii es_iy
keep iso_o iso_d year man_i agr_i man_iy agr_iy  agro_ieY_man_ieY es_ii es_iy
drop if es_iy == 0
label var agr_i "agricoltural trade"
label var agr_iy "agricoltural trade, domestic sales extrapolated"
rename agro_ieY_man_ieY agro_man_iy
label var agro_man_iy "agro + manuf, domestic extrapolated"
label var man_i "manufacturing trade"
label var man_iy "manufacturing trade, domestic sales extrapolated"
label var es_ii "rectangular dataset, only i and j with non missing domestic sales"
save "d:\santoni\Dropbox\WW_other_projs\WB_2024\WB_GE\WB_DTA_Toolkit\1.data\TradeProd_Aggregate_Data_2024.dta"