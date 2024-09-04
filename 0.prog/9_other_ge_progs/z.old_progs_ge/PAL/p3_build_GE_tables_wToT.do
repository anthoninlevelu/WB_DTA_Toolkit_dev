
clear all
program drop _all
macro drop _all
matrix drop _all
clear mata
clear matrix
   
set virtual on
set more off
set scheme s1color

set seed 20082015

global seed "20082015"


 global DB 			"D:\Santoni\Dropbox"
 global DB      	"C:\Users\gianl\Dropbox"
*global DB  		"E:\Dropbox\"


********************************************************************************
********************************************************************************


global ROOT 	 "$DB\WB_DTA_Toolkit"
global DATA 	 "$ROOT\data"
global TEMP	     "$DATA\temp"
global RES	     "$ROOT\res\Palestine\ge_res"
global RES_C     "$ROOT\res\Palestine\ge_res_c"
global GE 	 	 "$DATA\ge"

global CTY 	 	 "$ROOT\data\cty"



********************************************************************************
/******************************************************************************/

use "$DATA\ge\trade_wRTA_yearly.dta", clear


keep if est_sample_am_i_hat_zero == 1
keep if year >= 2007
keep 					if iso_o =="PAL" | iso_d =="PAL"

drop if iso_o == iso_d


merge m:1 iso_o year using "$TEMP/gravity_temp", keepusing(eu_o)
drop if _m ==2
drop _m


merge m:1 iso_d year using "$TEMP/gravity_temp", keepusing(eu_d)
drop if _m ==2
drop _m

preserve
keep if iso_d == "PAL"

replace iso_o = "EU" if eu_o == 1
collapse (sum) v=trade_am_i_hat_zero, by(  iso_o iso_d year)

 
bys year iso_d: egen 			M = total(v)

				  gen m_mkts_sh   =   v/M*100

gsort year iso_d  -m_mkts_sh		  
export excel using "$RES\statistics_v2.xlsx", sheet("Top Mkts M_GE")  sheetreplace firstrow(variables) nolabel 
				  
 
restore

********************************************************************************

preserve 
keep if iso_o == "PAL"

replace iso_d = "EU" if eu_d == 1

collapse (sum) v=trade_am_i_hat_zero, by(  iso_o iso_d year)

bys year iso_o: egen num_mkts = nvals(iso_d)

bys year iso_o: egen 			X = total(v)

				  gen x_mkts_sh   =   v/X*100

export excel using "$RES\statistics_v2.xlsx", sheet("Top Mkts X_GE")  sheetreplace firstrow(variables) nolabel 

restore



*******************************************************************************/
********************************************************************************
* Bilateral Trade Intensive Margin "ALL" counterfactual

use "$RES\FULLGE_ALL.dta" , clear

keep if exporter =="PAL"
drop if importer == exporter

keep exporter importer t trade tradehat_BLN  X_FULL

gen gr_rate 	 = ln(X_FULL) - ln(tradehat_BLN)
gen delta_export = trade*gr_rate

rename trade 	export_bln
rename X_FULL 	export_full
rename gr_rate 	export_gr_rate

rename importer iso3
rename exporter country
keep iso3 t country export_*

save "$TEMP\temp_bilateral", replace

********************************************************************************
********************************************************************************

use "$RES\FULLGE_ALL.dta" , clear

keep if importer == exporter
gen bln_domestic  = 	Xi_BLN/Y_BLN
gen full_domestic = 	Xi_FULL/Y_FULL
keep importer *_domestic

use "$RES\FULLGE_ALL.dta" , clear

keep if importer =="PAL"
drop if importer == exporter
keep exporter importer t trade tradehat_BLN  X_FULL

gen gr_rate 	 = ln(X_FULL) - ln(tradehat_BLN)
gen delta_import = trade*gr_rate

rename trade 	import_bln
rename X_FULL 	import_full
rename gr_rate 	import_gr_rate

rename exporter iso3
rename importer country
keep iso3 t country import_*

merge 1:1 iso3 country t using "$TEMP\temp_bilateral"
drop _m

order  iso3 t country import_bln import_full export_full export_bln  import_gr_rate export_gr_rate
save "$TEMP\temp_bilateral", replace

rename country target
rename iso3 country

replace country ="$ref_cty" if country =="ZZZ"
merge m:1 country using "$TEMP\temp_cty_name.dta", keepusing(country_name)
keep if _m == 3
drop _m

 

egen totX         = total(export_full)
gen wX            = export_full/totX*100


egen totM         = total(import_full)
gen wM            = import_full/totM*100


gen contribX      = wX*export_gr_rate
gsort -contribX

gen delta_export  = export_full  - export_bln
gen delta_import  = import_full  - import_bln

order country country_name delta_export delta_import wX wM
 
gsort -wX


gen iso_o = country
rename t year
merge m:1 iso_o year using "$TEMP/gravity_temp", keepusing(eu_o)
drop if _m == 2
drop _m


gsort -wX

gen  wX_eu =  wX*eu_o
gen  wM_eu =  wM*eu_o


********************************************************************************
********************************************************************************

 global cnt          			"ALL EU EFTA TUR MENA1 MENA2 MENA3 MENA2b MENA3b"
global year    					"2018" 
global sigma 					"5"

/*
Counterfactuals:

 *_b : Either Origin or Destin (col 1 & 2)
 
 *_w : Within  (col 3 & 4)
 
 *_n : Between ROW (col 5 & 6)
 
 
 
*/
********************************************************************************
********************************************************************************

foreach counterfactual in $cnt {

* Format Table
cd "$RES"

local sigma $sigma 
local X     $year

use "`counterfactual'_FULL_`sigma'.dta", clear

global name     = "`counterfactual'"

display "$name"


/*******************************************************************************
* No Needed here

if "$name" =="EU" | "$name" =="ECA_w" | "$name" =="ECA_n" {

replace region_o =  "$name"   if region_o=="Europe & Central Asia"

}
********************************************************************************
********************************************************************************
if "$name" =="NA_b" | "$name" =="NA_w" | "$name" =="NA_n" {

replace region_o =  "$name"   if region_o=="North America"

}
********************************************************************************
********************************************************************************
if "$name" =="SSA_b" | "$name" =="SSA_w" | "$name" =="SSA_n" {

replace region_o =  "$name"   if region_o=="Sub-Saharan Africa"

}
********************************************************************************
********************************************************************************
if "$name" =="SA_b" | "$name" =="SA_w" | "$name" =="SA_n" {

replace region_o =  "$name"   if region_o=="South Asia"

}
********************************************************************************
********************************************************************************
if "$name" =="MENA_b" | "$name" =="MENA_w" | "$name" =="MENA_n" {

replace region_o =  "$name"   if region_o=="Middle East & North Africa"

}
********************************************************************************
********************************************************************************
if "$name" =="LAC_b" | "$name" =="LAC_w" | "$name" =="LAC_n" {

replace region_o =  "$name"   if region_o=="Latin America & Caribbean"

}
********************************************************************************
********************************************************************************
if "$name" =="EAP_b" | "$name" =="EAP_w" | "$name" =="EAP_n" {

replace region_o =  "$name"   if region_o=="East Asia & Pacific"

}
********************************************************************************
********************************************************************************
if "$name" =="ALL_b" | "$name" =="ALL_w" | "$name" =="ALL_n" {

replace region_o =  "$name"   

}
*******************************************************************************/

   gen  ctn   	= ""
replace ctn 	= iso_o			      if (iso_o    ==  "PAL"	 )
replace ctn		= "ROW"  			  if (iso_o    !=  "PAL"	 )

tab ctn

********************************************************************************
summ replication 
scalar rep = r(mean)

if rep >= 11  {

display "error in $name"

...

}

********************************************************************************

bys ctn: egen w_IMR_FULL    = wtmean(change_IMR_FULL), weight(rGDP_BLN)
bys ctn: egen w_FGATE_FULL  = wtmean(change_price_FULL), weight(rGDP_BLN)

collapse (sum) rGDP_FULL  rGDP_BLN  Xi_FULL  Xi_BLN (mean) w_IMR_FULL w_FGATE_FULL, by(year ctn)

  
gen change_rGDP_FULL    	= ( rGDP_FULL  - rGDP_BLN    )/ rGDP_BLN    *100

gen change_Xi_FULL   		= (Xi_FULL     - Xi_BLN      )/ Xi_BLN      *100



gen id = _n

 reshape wide change_Xi change_rGDP w_IMR_FULL w_FGATE_FULL, i(id year) j(ctn) string

 keep year change_* w_*
 cap  order year change_Xi_FULLROW change_rGDP_FULLROW  w_FGATE_FULLROW w_IMR_FULLROW, last
 
export excel  "WORLD_GE_tables_`sigma'_j22.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel sheetreplace
********************************************************************************
}


********************************************************************************
********************************************************************************
* TRADE by country_name

global year    	           "2018" 
global ref_cty         	   "ZAF"
global sigma         	   "5"
global country_list        "BHR DZA EGY IRN IRQ ISR JOR KWT LBN MAR MLT TUN YEM"
global cnt          	   "MENA1_C MENA2_C MENA3_C MENA2_Cb MENA3_Cb"


cd "$RES_C"



 local s = 1
foreach counterfactual in $cnt {

global counterfactual = "`counterfactual'"



foreach CTY in $country_list {
	
disp "`CTY'"
local sigma $sigma 
local X     $year


use 	"`counterfactual'_`CTY'.dta", clear
 

 keep if country =="PAL"
rename country country_target


replace change_rGDP_FULL	= . if replication >= 11 
replace change_Xi_FULL 		= . if replication >= 11 

replace change_price_FULL 	= . if replication >= 11 
replace change_IMR_FULL 	= . if replication >= 11 

gen partner      = "`CTY'"

keep  year  partner country_target  change_Xi_FULL change_rGDP_FULL rGDP_FULL rGDP_BLN Xi_FULL Xi_BLN change_price_FULL change_IMR_FULL
order year  partner country_target  change_Xi_FULL change_rGDP_FULL rGDP_FULL rGDP_BLN Xi_FULL Xi_BLN change_price_FULL change_IMR_FULL

if `s' == 1 {

save GE_tables_`counterfactual'_CTY, replace

}

if `s' > 1 {

append using GE_tables_`counterfactual'_CTY
save GE_tables_`counterfactual'_CTY, replace


}


local s = `s'  + 1

}


sort partner
rename partner country 
merge m:1 country using "$TEMP\temp_cty_name.dta", keepusing(country_name)
keep if _m==3
drop _m

sort  country_name

export excel  "CTY_GE_tables_`sigma'_dec21.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel sheetreplace
local s = 1

}

********************************************************************************
*******************************************************************************/



 


