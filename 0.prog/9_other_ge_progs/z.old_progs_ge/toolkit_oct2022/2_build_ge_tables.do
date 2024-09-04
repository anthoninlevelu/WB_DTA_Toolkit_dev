
local iso "$iso"

/*******************************************************************************
	     Deep Trade Agreements Toolkit: Trade and Welfare Impacts 

Nadia Rocha, Gianluca Santoni, Giulio Vannelli 

                  	   this version: OCT 2022
				   
website: https://xxxxxxx.org/

when using the tool please cite:  
Fontagné, L., Rocha, N., Ruta, M., Santoni, G. (2022),
 The Economic Impact of Deepening Trade Agreements", CESIfo working paper 9529.  

*******************************************************************************/

cap 	log close
capture log using "$ROOT\progs\log_files\build_ge_tables", text replace

********************************************************************************
********************************************************************************
* prepare file with country name

use "$GRAVITY_COV\geo_cepii.dta", clear
keep iso3 country
replace iso3 = "PSE" if iso3 == "PAL"
replace iso3 = "SRB" if iso3 == "YUG"
 
rename country country_name 
rename iso3 country 
duplicates drop 
 
save "$RES\\`iso'\temp\temp_cty_name.dta", replace



********************************************************************************
********************************************************************************
* Read Results files

cd "$RES\\`iso'\temp\"


local int : dir "`c(pwd)'"  files "*INT*.dta" 
local ext : dir "`c(pwd)'"  files "*EXT*.dta" 
local exd : dir "`c(pwd)'"  files "*EXD*.dta" 



local s = 1 
 
foreach file in   `int'  `ext' `exd' {

********************************************************************************
* Format Table
local sigma $sigma 
local X     $year_reg

use  `file' , clear
 

   gen  TREAT  			 = ""
replace TREAT 			 = "`iso'" if (iso_o    == "`iso'")
replace TREAT 			 = "ROW"   if (iso_o    != "`iso'")



summ replication
global rep = `r(mean)'

local cty 				=count[1]   
local type              =type[1]   
local counterfactual    = "`cty'_`type'"

********************************************************************************
********************************************************************************

  
 

collapse (sum) rGDP_FULL  rGDP_BLN  Xi_FULL  Xi_BLN Ti_FULL  Ti_BLN (mean) change_price_FULL change_IMR_FULL, by(TREAT)

  
gen change_rGDP_FULL    	= ( rGDP_FULL  - rGDP_BLN    )/ rGDP_BLN    *100

gen change_Xi_FULL   		= (Xi_FULL     - Xi_BLN      )/ Xi_BLN      *100

gen change_Ti_FULL   		= (Ti_FULL     - Ti_BLN      )/ Ti_BLN      *100


gen id = _n

reshape wide change_rGDP change_Xi change_Ti change_price_FULL change_IMR_FULL, i(id) j(TREAT) string

keep change_*
 
 
order  change_Xi_FULL`iso' change_rGDP_FULL`iso' change_price_FULL`iso' change_IMR_FULL`iso' change_Xi_FULLROW change_rGDP_FULLROW change_Ti_FULL`iso'  change_price_FULLROW change_IMR_FULLROW
 
********************************************************************************
********************************************************************************

 
if `s' == 1 {
export excel  "$RES\\`iso'\\GE_tables_`X'.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel  replace
}


if `s' > 1 {
export excel  "$RES\\`iso'\\GE_tables_`X'.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel sheetreplace

}

********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************



use  `file' , clear

   gen  TREAT  	= ""
replace TREAT 	= "`iso'" if (iso_o    == "`iso'")
replace TREAT 	= "ROW"   if (iso_o    != "`iso'")

 
keep country change_* TREAT 

merge m:1 country using "temp_cty_name.dta", keepusing(country_name)
keep if _m==3
drop _m



sort  country_name

keep    country_name country  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL  TREAT change_Ti_FULL
order   country_name country  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL  TREAT change_Ti_FULL
 
if `s' == 1 {
export excel  "$RES\\`iso'\\Country_GE_tables_`X'.xlsx", sheet("`counterfactual'_CTY")  firstrow(variables) nolabel  replace
}


if `s' > 1 {
export excel  "$RES\\`iso'\\Country_GE_tables_`X'.xlsx", sheet("`counterfactual'_CTY")  firstrow(variables) nolabel sheetreplace
}


 local s = `s' + 1

}

********************************************************************************
********************************************************************************
********************************************************************************
