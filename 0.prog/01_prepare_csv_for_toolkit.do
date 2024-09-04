
local iso "$iso"
********************************************************************************
/* The following organizes the raw results into the report layout */
********************************************************************************
* First table is about trade facts
********************************************************************************

cd "$WEB"

// 0: Procedure Informations
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


use "$RES//`iso'//info_simulations.dta", clear



 if `s' == 0 {

save "$WEB/temp/temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$WEB/temp/temp_table"
save "$WEB/temp/temp_table", replace
 }

local s = `s' + 1 

}

export delimited using "$WEB/table0.csv", replace


********************************************************************************
********************************************************************************
// 1.1: trade openness:
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"

********************************************************************************
********************************************************************************
	use		"$CTY/WBregio_toolkit", clear
	
	gen 		reg_s = "EAP"		if 		region == "East Asia & Pacific"		// con il nome corto non ho problemi per reshape nei file seguenti
	replace		reg_s = "ECA"		if 		region == "Europe & Central Asia"
	replace		reg_s = "LAC"		if 		region == "Latin America & Caribbean"
	replace		reg_s = "MENA"		if 		region == "Middle East & North Africa"
	replace		reg_s = "NA"		if 		region == "North America"
	replace		reg_s = "SA"		if 		region == "South Asia"
	replace		reg_s = "SSA"		if 		region == "Sub-Saharan Africa"
	
	keep if iso3 ==  "`iso'"
	rename 	region reg_l

********************************************************************************
    local temp =reg_s[1]   
	global reg_s   "`temp'"
	display "$reg_s"

global reg_s			  "$reg_s"

********************************************************************************
********************************************************************************
import excel "$RES//`iso'//statistics.xlsx", sheet("Openness_long") firstrow clear


keep if year >= $ldate_bg2  
reshape long openness, i(year) j(iso3) string

keep if iso3 == "`iso'" | iso3 =="$reg_s"

replace iso3 = "$iso" + "_"  + "$reg_s"    if iso3 =="$reg_s"

 if `s' == 0 {

save "$WEB/temp/temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$WEB/temp/temp_table"
save "$WEB/temp/temp_table", replace
 }

local s = `s' + 1 

}


export delimited using "$WEB/table2a.csv", replace
	
********************************************************************************
********************************************************************************
// 1.2: # Reached Markets Exports
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"

********************************************************************************
********************************************************************************
	use		"$CTY/WBregio_toolkit", clear
	
	gen 		reg_s = "EAP"		if 		region == "East Asia & Pacific"		// con il nome corto non ho problemi per reshape nei file seguenti
	replace		reg_s = "ECA"		if 		region == "Europe & Central Asia"
	replace		reg_s = "LAC"		if 		region == "Latin America & Caribbean"
	replace		reg_s = "MENA"		if 		region == "Middle East & North Africa"
	replace		reg_s = "NA"		if 		region == "North America"
	replace		reg_s = "SA"		if 		region == "South Asia"
	replace		reg_s = "SSA"		if 		region == "Sub-Saharan Africa"
	
	keep if iso3 ==  "`iso'"
	rename 	region reg_l

********************************************************************************
    local temp =reg_s[1]   
	global reg_s   "`temp'"
	display "$reg_s"

global reg_s			  "$reg_s"

********************************************************************************
********************************************************************************


import excel "$RES//`iso'//statistics.xlsx", sheet("Top 10 Mkts") firstrow clear


keep if year >= $ldate_bg2  
reshape long num_mkts top_10_mkts, i(year) j(iso3) string

keep if iso3 == "`iso'" | iso3 =="$reg_s"
replace iso3 = "$iso" + "_"  + "$reg_s"    if iso3 =="$reg_s"

 if `s' == 0 {

save "$WEB/temp/temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$WEB/temp/temp_table"
save "$WEB/temp/temp_table", replace

  }

local s = `s' + 1 

}

export delimited using "$WEB/table2bc.csv", replace


********************************************************************************
********************************************************************************
// 1.3: top Markets
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"

********************************************************************************
********************************************************************************
	use		"$CTY/WBregio_toolkit", clear
	
	gen 		reg_s = "EAP"		if 		region == "East Asia & Pacific"		// con il nome corto non ho problemi per reshape nei file seguenti
	replace		reg_s = "ECA"		if 		region == "Europe & Central Asia"
	replace		reg_s = "LAC"		if 		region == "Latin America & Caribbean"
	replace		reg_s = "MENA"		if 		region == "Middle East & North Africa"
	replace		reg_s = "NA"		if 		region == "North America"
	replace		reg_s = "SA"		if 		region == "South Asia"
	replace		reg_s = "SSA"		if 		region == "Sub-Saharan Africa"
	
	keep if iso3 ==  "`iso'"
	rename 	region reg_l

********************************************************************************
    local temp =reg_s[1]   
	global reg_s   "`temp'"
	display "$reg_s"

global reg_s			  "$reg_s"

********************************************************************************
********************************************************************************


import excel "$RES//`iso'//statistics.xlsx", sheet("First Mkt X") firstrow clear

keep if year >= $ldate_bg2  

reshape long x_mkts_sh, i(year iso_d) j(iso3) string

keep if iso3 == "`iso'" | iso3 =="$reg_s"
replace iso3 = "$iso" + "_"  + "$reg_s"    if iso3 =="$reg_s"


 if `s' == 0 {

save "$WEB/temp/temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$WEB/temp/temp_table"
save "$WEB/temp/temp_table", replace

 }

local s = `s' + 1 

}

cap drop if x_mkts_sh == .
export delimited using "$WEB/table2de.csv", replace

********************************************************************************
********************************************************************************
// 1.2: # Reached Markets Imports
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"

********************************************************************************
********************************************************************************
	use		"$CTY/WBregio_toolkit", clear
	
	gen 		reg_s = "EAP"		if 		region == "East Asia & Pacific"		// con il nome corto non ho problemi per reshape nei file seguenti
	replace		reg_s = "ECA"		if 		region == "Europe & Central Asia"
	replace		reg_s = "LAC"		if 		region == "Latin America & Caribbean"
	replace		reg_s = "MENA"		if 		region == "Middle East & North Africa"
	replace		reg_s = "NA"		if 		region == "North America"
	replace		reg_s = "SA"		if 		region == "South Asia"
	replace		reg_s = "SSA"		if 		region == "Sub-Saharan Africa"
	
	keep if iso3 ==  "`iso'"
	rename 	region reg_l

********************************************************************************
    local temp =reg_s[1]   
	global reg_s   "`temp'"
	display "$reg_s"

global reg_s			  "$reg_s"

********************************************************************************
********************************************************************************


import excel "$RES//`iso'//statistics.xlsx", sheet("Top 10 Mkts M") firstrow clear


keep if year >= $ldate_bg2  
reshape long num_mkts top_10_mkts, i(year) j(iso3) string

keep if iso3 == "`iso'" | iso3 =="$reg_s"
replace iso3 = "$iso" + "_"  + "$reg_s"    if iso3 =="$reg_s"

 if `s' == 0 {

save "$WEB/temp/temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$WEB/temp/temp_table"
save "$WEB/temp/temp_table", replace

  }

local s = `s' + 1 

}

export delimited using "$WEB/table2bc_M.csv", replace


********************************************************************************
********************************************************************************
// 1.3: top Markets Imports
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"

********************************************************************************
********************************************************************************
	use		"$CTY/WBregio_toolkit", clear
	
	gen 		reg_s = "EAP"		if 		region == "East Asia & Pacific"		// con il nome corto non ho problemi per reshape nei file seguenti
	replace		reg_s = "ECA"		if 		region == "Europe & Central Asia"
	replace		reg_s = "LAC"		if 		region == "Latin America & Caribbean"
	replace		reg_s = "MENA"		if 		region == "Middle East & North Africa"
	replace		reg_s = "NA"		if 		region == "North America"
	replace		reg_s = "SA"		if 		region == "South Asia"
	replace		reg_s = "SSA"		if 		region == "Sub-Saharan Africa"
	
	keep if iso3 ==  "`iso'"
	rename 	region reg_l

********************************************************************************
    local temp =reg_s[1]   
	global reg_s   "`temp'"
	display "$reg_s"

global reg_s			  "$reg_s"

********************************************************************************
********************************************************************************


import excel "$RES//`iso'//statistics.xlsx", sheet("First Mkt M") firstrow clear

keep if year >= $ldate_bg2  

reshape long m_mkts_sh, i(year iso_o) j(iso3) string

keep if iso3 == "`iso'" | iso3 =="$reg_s"
replace iso3 = "$iso" + "_"  + "$reg_s"    if iso3 =="$reg_s"


 if `s' == 0 {

save "$WEB/temp/temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$WEB/temp/temp_table"
save "$WEB/temp/temp_table", replace

 }

local s = `s' + 1 

}

cap drop if m_mkts_sh == .
export delimited using "$WEB/table2de_M.csv", replace

********************************************************************************
********************************************************************************
* Second table is about trade facts: Exports
********************************************************************************
/*
# Exported Products	
Share in total Exports (top 10 products)
Share in total Exports (first products)	
First Product (HS 6-digit)
*/

cd "$WEB"

// 2.1:
***************************************
/* 	Share in total Exports
(Top 10 markets)	Share in total Exports 
(First market)	First 
Market
*/


local s = 0

foreach iso of global country_interest {

global iso    "`iso'"


********************************************************************************
********************************************************************************
	use		"$CTY/WBregio_toolkit", clear
	
	gen 		reg_s = "EAP"		if 		region == "East Asia & Pacific"		// con il nome corto non ho problemi per reshape nei file seguenti
	replace		reg_s = "ECA"		if 		region == "Europe & Central Asia"
	replace		reg_s = "LAC"		if 		region == "Latin America & Caribbean"
	replace		reg_s = "MENA"		if 		region == "Middle East & North Africa"
	replace		reg_s = "NA"		if 		region == "North America"
	replace		reg_s = "SA"		if 		region == "South Asia"
	replace		reg_s = "SSA"		if 		region == "Sub-Saharan Africa"
	
	keep if iso3 ==  "`iso'"
	rename 	region reg_l

********************************************************************************
    local temp =reg_s[1]   
	global reg_s   "`temp'"
	display "$reg_s"

global reg_s			  "$reg_s"

********************************************************************************
********************************************************************************
 

import excel "$RES//`iso'//statistics.xlsx", sheet("Top 10 product X cum share") firstrow clear

keep if year >= $ldate_bg2  
reshape long num_products  top_10_prod , i(year) j(iso3) string

keep if iso3 == "`iso'" | iso3 =="$reg_s"
replace iso3 = "$iso" + "_"  + "$reg_s"    if iso3 =="$reg_s"

 if `s' == 0 {

save "$WEB/temp/temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$WEB/temp/temp_table"
save "$WEB/temp/temp_table", replace

  }

local s = `s' + 1 

}

export delimited using "$WEB/table3ab.csv", replace

********************************************************************************
********************************************************************************
// 2.2: top products
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


********************************************************************************
********************************************************************************
	use		"$CTY/WBregio_toolkit", clear
	
	gen 		reg_s = "EAP"		if 		region == "East Asia & Pacific"		// con il nome corto non ho problemi per reshape nei file seguenti
	replace		reg_s = "ECA"		if 		region == "Europe & Central Asia"
	replace		reg_s = "LAC"		if 		region == "Latin America & Caribbean"
	replace		reg_s = "MENA"		if 		region == "Middle East & North Africa"
	replace		reg_s = "NA"		if 		region == "North America"
	replace		reg_s = "SA"		if 		region == "South Asia"
	replace		reg_s = "SSA"		if 		region == "Sub-Saharan Africa"
	
	keep if iso3 ==  "`iso'"
	rename 	region reg_l

********************************************************************************
    local temp =reg_s[1]   
	global reg_s   "`temp'"
	display "$reg_s"

global reg_s			  "$reg_s"

********************************************************************************
******************************************************************************** 

import excel "$RES//`iso'//statistics.xlsx", sheet("First product X share") firstrow clear

cap rename k hs6
keep if year >= $ldate_bg2  

reshape long x_prod_sh, i(year hs6) j(iso3) string

keep if iso3 == "`iso'" | iso3 =="$reg_s"
replace iso3 = "$iso" + "_"  + "$reg_s"    if iso3 =="$reg_s"


 if `s' == 0 {

save "$WEB/temp/temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$WEB/temp/temp_table"
save "$WEB/temp/temp_table", replace

 }

local s = `s' + 1 

}

cap drop if x_prod_sh == .

export delimited using "$WEB/table3cd.csv", replace

********************************************************************************
********************************************************************************
********************************************************************************

********************************************************************************
********************************************************************************
* Second table is about trade facts: Imports
********************************************************************************
/*
# Exported Products	
Share in total Exports (top 10 products)
Share in total Exports (first products)	
First Product (HS 6-digit)
*/

cd "$WEB"

// 2.1:
***************************************
/* 	Share in total Exports
(Top 10 markets)	Share in total Exports 
(First market)	First 
Market
*/


local s = 0

foreach iso of global country_interest {

global iso    "`iso'"


********************************************************************************
********************************************************************************
	use		"$CTY/WBregio_toolkit", clear
	
	gen 		reg_s = "EAP"		if 		region == "East Asia & Pacific"		// con il nome corto non ho problemi per reshape nei file seguenti
	replace		reg_s = "ECA"		if 		region == "Europe & Central Asia"
	replace		reg_s = "LAC"		if 		region == "Latin America & Caribbean"
	replace		reg_s = "MENA"		if 		region == "Middle East & North Africa"
	replace		reg_s = "NA"		if 		region == "North America"
	replace		reg_s = "SA"		if 		region == "South Asia"
	replace		reg_s = "SSA"		if 		region == "Sub-Saharan Africa"
	
	keep if iso3 ==  "`iso'"
	rename 	region reg_l

********************************************************************************
    local temp =reg_s[1]   
	global reg_s   "`temp'"
	display "$reg_s"

global reg_s			  "$reg_s"

********************************************************************************
********************************************************************************
 

import excel "$RES//`iso'//statistics.xlsx", sheet("Top 10 product M cum share") firstrow clear

keep if year >= $ldate_bg2  
reshape long num_products  top_10_prod , i(year) j(iso3) string

keep if iso3 == "`iso'" | iso3 =="$reg_s"
replace iso3 = "$iso" + "_"  + "$reg_s"    if iso3 =="$reg_s"

 if `s' == 0 {

save "$WEB/temp/temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$WEB/temp/temp_table"
save "$WEB/temp/temp_table", replace

  }

local s = `s' + 1 

}

export delimited using "$WEB/table3ab_M.csv", replace

********************************************************************************
********************************************************************************
// 2.2: top products
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


********************************************************************************
********************************************************************************
	use		"$CTY/WBregio_toolkit", clear
	
	gen 		reg_s = "EAP"		if 		region == "East Asia & Pacific"		// con il nome corto non ho problemi per reshape nei file seguenti
	replace		reg_s = "ECA"		if 		region == "Europe & Central Asia"
	replace		reg_s = "LAC"		if 		region == "Latin America & Caribbean"
	replace		reg_s = "MENA"		if 		region == "Middle East & North Africa"
	replace		reg_s = "NA"		if 		region == "North America"
	replace		reg_s = "SA"		if 		region == "South Asia"
	replace		reg_s = "SSA"		if 		region == "Sub-Saharan Africa"
	
	keep if iso3 ==  "`iso'"
	rename 	region reg_l

********************************************************************************
    local temp =reg_s[1]   
	global reg_s   "`temp'"
	display "$reg_s"

global reg_s			  "$reg_s"

********************************************************************************
******************************************************************************** 

import excel "$RES//`iso'//statistics.xlsx", sheet("First product M share") firstrow clear

cap rename k hs6
keep if year >= $ldate_bg2  

reshape long m_prod_sh, i(year hs6) j(iso3) string

keep if iso3 == "`iso'" | iso3 =="$reg_s"
replace iso3 = "$iso" + "_"  + "$reg_s"    if iso3 =="$reg_s"


 if `s' == 0 {

save "$WEB/temp/temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$WEB/temp/temp_table"
save "$WEB/temp/temp_table", replace

 }

local s = `s' + 1 

}

cap drop if x_prod_sh == .

export delimited using "$WEB/table3cd_M.csv", replace

********************************************************************************
********************************************************************************
********************************************************************************



********************************************************************************
********************************************************************************
********************************************************************************
// 2.2b: RCA
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


import excel "$RES//`iso'//statistics.xlsx", sheet("RCA_details") firstrow clear

 
 if `s' == 0 {

save "$WEB/temp/temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$WEB/temp/temp_table"
 
save "$WEB/temp/temp_table", replace
 }

local s = `s' + 1 

}


export delimited using "$WEB/figure3_rca.csv", replace


********************************************************************************
********************************************************************************
* Third table is about PTA facts
********************************************************************************
********************************************************************************


cd "$WEB"

// 3.1:
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


import excel "$RES//`iso'//statistics.xlsx", sheet("RTAs_at_place") firstrow clear

keep iso_d agreement entry_force $kmean_alg id_agree
bys agreement entry_force $kmean_alg id_agree: egen part = nvals(iso_d)


keep id_agree agreement part entry_force $kmean_alg
duplicates drop 



    gen agree_type  = ""
replace agree_type  = "Shallow" if $kmean_alg == 3
replace agree_type  = "Medium"  if $kmean_alg == 2
replace agree_type  = "Deep"    if $kmean_alg == 1


keep id_agree agreement part entry_force agree_type

gen    target = "$iso"
order id_agree target  agreement entry_force part   agree_type

 if `s' == 0 {

save "$WEB/temp/temp_table0", replace
 }
 
 
  if `s' > 0 {
append using "$WEB/temp/temp_table0"
save "$WEB/temp/temp_table0", replace
 }

local s = `s' + 1 

}

preserve
drop id_agree
export delimited using "$WEB/table4ad.csv", replace
save "$WEB/temp/temp_table4ad.dta", replace
restore

use "$WEB/temp/temp_table0", clear
keep id_agree target agree_type
save "$WEB/temp/temp_agrees", replace

********************************************************************************
********************************************************************************
// 3.2:
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


import excel "$RES//`iso'//statistics.xlsx", sheet("mkt_sh_by_RTA") firstrow clear
keep if  year == $ldate_bg

replace mkt_sh_m = mkt_sh_m*0.01
replace mkt_sh_x = mkt_sh_x*0.01

keep agreement mkt_sh_m	mkt_sh_x


keep agreement mkt_sh_m	mkt_sh_x
duplicates drop 



gen   target = "$iso"
order target agreement mkt_sh_m	mkt_sh_x

 if `s' == 0 {

save "$WEB/temp/temp_table1", replace
 }
 
 
  if `s' > 0 {
append using "$WEB/temp/temp_table1"
 
save "$WEB/temp/temp_table1", replace
 }

local s = `s' + 1 

}
cap drop if agreement =="RoW"

merge 1:1 target agreement using "$WEB/temp/temp_table4ad.dta"
keep if _m == 3
drop _m

order target agreement entry_force part agree_type mkt_sh_m mkt_sh_x
export delimited using "$WEB/table4ad.csv", replace

********************************************************************************
********************************************************************************
* Table B4
********************************************************************************
********************************************************************************


local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


import excel "$RES//`iso'//statistics.xlsx", sheet("PTAs_coverage_cty") firstrow clear

reshape long agree_coverage, i(Area) j(id_agree)

 gen   target = "$iso"
 order   id_agree agree_coverage

 if `s' == 0 {

save "$WEB/temp/temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$WEB/temp/temp_table"
 
save "$WEB/temp/temp_table", replace
 }

local s = `s' + 1 

}

duplicates drop 

merge m:1 id_agree using "$DATA/agree_list_GE",  keepusing(agreement entry_force $kmean_alg)
drop if _m == 2
drop _m

    gen agree_type  = ""
replace agree_type  = "Shallow" if $kmean_alg ==  3 
replace agree_type  = "Medium"  if $kmean_alg ==  2 
replace agree_type  = "Deep"    if $kmean_alg ==  1  

order target agree_type entry_force id_agree    agreement Area agree_coverage
keep  target agree_type entry_force id_agree    agreement Area agree_coverage

export delimited using "$WEB/table_B4.csv", replace



********************************************************************************
********************************************************************************

local z = 0
foreach iso of global country_interest {

			

global iso    "`iso'"

cd "$RES//`iso'//"

use "info_simulations.dta", clear

    local temp =year[1]   
	global regy   "`temp'"
	
	
				local r = 0

	  import excel using "INT0_GE_tables_$regy.xlsx", describe 
				forvalues sheet = 1/`=r(N_worksheet)' {  
	  import excel using "INT0_GE_tables_$regy.xlsx", describe 


						 local sheetname=r(worksheet_`sheet')  
						 import excel using  "INT0_GE_tables_$regy.xlsx", sheet("`sheetname'")  firstrow  cellrange("`r(range_`sheet')'") clear
						 gen  counter  = "`sheetname'"
						 cap   drop    *ROW

						 drop if change_rGDP_FULL == .
						 
						 reshape long  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL change_Ti_FULL , i(  counter) j(target) string
						 
						 drop change_Ti_FULL
						 
	if `r' == 0 {

	save "$WEB/temp/temp_ge", replace
	 }					 
						 
	if `r' > 0 {
	append using "$WEB/temp/temp_ge"
	   

	save "$WEB/temp/temp_ge", replace
	 }
						  
	local r = `r' + 1 
						  
							}
							
********************************************************************************
						
						
if `z' == 0 {

save "$WEB/temp/temp_ge_all", replace
 }					 
					 
if `z' > 0 {
append using "$WEB/temp/temp_ge_all"
save "$WEB/temp/temp_ge_all", replace
 }						
			
			
local z = `z' + 1 
			
                        }

replace  change_Xi_FULL     = round(change_Xi_FULL   , 0.01)
replace  change_rGDP_FULL   = round(change_rGDP_FULL , 0.01) 
replace  change_price_FULL  = round(change_price_FULL, 0.01)
replace  change_IMR_FULL	= round(change_IMR_FULL  , 0.01)					
						
split counter , parse("_")
destring counter3, replace
rename counter3 id_agree
 

merge m:1 id_agree using "$DATA/agree_list_GE",  keepusing(agreement )
drop if _m == 2
drop _m


cap drop counter
replace change_Xi_FULL   = change_Xi_FULL*-1
replace change_rGDP_FULL = change_rGDP_FULL*-1
gen counter = "quantification of current agreements"

 
order counter target agreement change_Xi_FULL change_rGDP_FULL 
keep  counter target agreement change_Xi_FULL change_rGDP_FULL  
sort  target agreement


export delimited using "$WEB/table4ef.csv", replace


********************************************************************************
********************************************************************************
// 4.1: GE
***************************************
local z = 0
foreach iso of global country_interest {

			

global iso    "`iso'"

cd "$RES//`iso'//"

use "info_simulations.dta", clear

    local temp =year[1]   
	global regy   "`temp'"


				local r = 0

	  import excel using "GE_tables_$regy.xlsx", describe 
				forvalues sheet = 1/`=r(N_worksheet)' {  
	  import excel using "GE_tables_$regy.xlsx", describe 


						 local sheetname=r(worksheet_`sheet')  
						 import excel using  "GE_tables_$regy.xlsx", sheet("`sheetname'")  firstrow  cellrange("`r(range_`sheet')'") clear
						 gen  counter  = "`sheetname'"
						 cap   drop    *ROW

						 drop if change_rGDP_FULL == .
						 
						 reshape long  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL change_Ti_FULL , i(  counter) j(target) string
						 
						 drop change_Ti_FULL
						 
	if `r' == 0 {

	save "$WEB/temp/temp_ge", replace
	 }					 
						 
	if `r' > 0 {
	append using "$WEB/temp/temp_ge"
	   

	save "$WEB/temp/temp_ge", replace
	 }
						  
	local r = `r' + 1 
						  
							}
							
********************************************************************************
						
						
if `z' == 0 {

save "$WEB/temp/temp_ge_all", replace
 }					 
					 
if `z' > 0 {
append using "$WEB/temp/temp_ge_all"
 
save "$WEB/temp/temp_ge_all", replace
 }						
			
			
local z = `z' + 1 
			
                        }

replace  change_Xi_FULL     = round(change_Xi_FULL, 0.01)
replace  change_rGDP_FULL   = round(change_rGDP_FULL, 0.01) 
replace  change_price_FULL  = round(change_price_FULL, 0.01)
replace  change_IMR_FULL	= round(change_IMR_FULL, 0.01)					
						
split counter , parse("_")
destring counter2, replace
rename counter2 id_agree

merge m:1 id_agree using "$DATA/agree_list_GE",  keepusing(agreement )
drop if _m == 2
drop _m


merge 1:1 target id_agree using "$WEB/temp/temp_agrees"
cap drop if _m == 2
cap drop if agree_type == "Deep"
cap drop counter*

gen counter = "Deepening existing agreements (intensive margin)"


order counter target  agreement change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL
keep  counter target  agreement change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL
sort  target agreement
export delimited using "$WEB\table5.csv", replace

********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
// 4.1: GE
***************************************

cd "$WEB"

local z = 0
foreach iso of global country_interest {

			

global iso    "`iso'"

cd "$RES//`iso'//"

use "info_simulations.dta", clear

    local temp =year[1]   
	global regy   "`temp'"




				local r = 0

	  import excel using "Country_GE_EXT1_$regy.xlsx", describe 
				forvalues sheet = 1/`=r(N_worksheet)' {  
	  import excel using "Country_GE_EXT1_$regy.xlsx", describe 


						 local sheetname=r(worksheet_`sheet')  
						 import excel using  "Country_GE_EXT1_$regy.xlsx", sheet("`sheetname'")  firstrow  cellrange("`r(range_`sheet')'") clear
						 
						 gen  counter   = "`sheetname'"
					     keep if country =="$iso"
						 drop if change_rGDP_FULL == .
						 gen target      = "$iso"
						 cap drop TREAT	 
						 cap drop change_Ti_FULL
						 cap drop country
	if `r' == 0 {

	save "$WEB/temp/temp_ge", replace
	 }					 
						 
	if `r' > 0 {
	append using "$WEB/temp/temp_ge"
	   

	save "$WEB/temp/temp_ge", replace
	 }
						  
	local r = `r' + 1 
						  
							}
							
********************************************************************************
						
						
if `z' == 0 {

save "$WEB/temp/temp_ge_all", replace
 }					 
					 
if `z' > 0 {
append using "$WEB/temp/temp_ge_all"
 
save "$WEB/temp/temp_ge_all", replace
 }						
			
			
local z = `z' + 1 
			
                        }

replace  change_Xi_FULL     = round(change_Xi_FULL, 0.01)
replace  change_rGDP_FULL   = round(change_rGDP_FULL, 0.01) 
replace  change_price_FULL  = round(change_price_FULL, 0.01)
replace  change_IMR_FULL	= round(change_IMR_FULL, 0.01)					
						
split counter , parse("_")
rename counter1 partner
cap drop counter*
gen counter    = "Signing  new agreements (extensive margin)"
gen agree_type = "Deep"

order counter agree_type target  partner  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL
keep  counter agree_type target  partner  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL
sort          target agree_type partner


save "$WEB/temp/temp_4_Deep", replace

********************************************************************************
********************************************************************************
***************************************

cd "$WEB"

local z = 0
foreach iso of global country_interest {

			

global iso    "`iso'"

cd "$RES//`iso'//"

use "info_simulations.dta", clear

    local temp =year[1]   
	global regy   "`temp'"


				local r = 0

	  import excel using "Country_GE_EXT2_$regy.xlsx", describe 
				forvalues sheet = 1/`=r(N_worksheet)' {  
	  import excel using "Country_GE_EXT2_$regy.xlsx", describe 


						 local sheetname=r(worksheet_`sheet')  
						 import excel using  "Country_GE_EXT2_$regy.xlsx", sheet("`sheetname'")  firstrow  cellrange("`r(range_`sheet')'") clear
						 
						 gen  counter   = "`sheetname'"
					     keep if country =="$iso"
						 drop if change_rGDP_FULL == .
						 gen target      = "$iso"
						 cap drop TREAT	 
						 cap drop change_Ti_FULL
						 cap drop country
	if `r' == 0 {

	save "$WEB/temp/temp_ge", replace
	 }					 
						 
	if `r' > 0 {
	append using "$WEB/temp/temp_ge"
	   

	save "$WEB/temp/temp_ge", replace
	 }
						  
	local r = `r' + 1 
						  
							}
							
********************************************************************************
						
						
if `z' == 0 {

save "$WEB/temp/temp_ge_all", replace
 }					 
					 
if `z' > 0 {
append using "$WEB/temp/temp_ge_all"
 
save "$WEB/temp/temp_ge_all", replace
 }						
			
			
local z = `z' + 1 
			
                        }

replace  change_Xi_FULL     = round(change_Xi_FULL, 0.01)
replace  change_rGDP_FULL   = round(change_rGDP_FULL, 0.01) 
replace  change_price_FULL  = round(change_price_FULL, 0.01)
replace  change_IMR_FULL	= round(change_IMR_FULL, 0.01)					
						
split counter , parse("_")
rename counter1 partner
cap drop counter*
gen counter    = "Signing  new agreements (extensive margin)"
gen agree_type = "Medium"

order counter agree_type target  partner  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL
keep  counter agree_type target  partner  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL
sort          target agree_type partner


save "$WEB/temp/temp_4_Medium", replace

********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
***************************************

cd "$WEB"

local z = 0
foreach iso of global country_interest {

			

global iso    "`iso'"

cd "$RES//`iso'//"

use "info_simulations.dta", clear

    local temp =year[1]   
	global regy   "`temp'"


				local r = 0

	  import excel using "Country_GE_EXT3_$regy.xlsx", describe 
				forvalues sheet = 1/`=r(N_worksheet)' {  
	  import excel using "Country_GE_EXT3_$regy.xlsx", describe 


						 local sheetname=r(worksheet_`sheet')  
						 import excel using  "Country_GE_EXT3_$regy.xlsx", sheet("`sheetname'")  firstrow  cellrange("`r(range_`sheet')'") clear
						 
						 gen  counter   = "`sheetname'"
					     keep if country =="$iso"
						 drop if change_rGDP_FULL == .
						 gen target      = "$iso"
						 cap drop TREAT	 
						 cap drop change_Ti_FULL
						 cap drop country
	if `r' == 0 {

	save "$WEB/temp/temp_ge", replace
	 }					 
						 
	if `r' > 0 {
	append using "$WEB/temp/temp_ge"
	   

	save "$WEB/temp/temp_ge", replace
	 }
						  
	local r = `r' + 1 
						  
							}
							
********************************************************************************
						
						
if `z' == 0 {

save "$WEB/temp/temp_ge_all", replace
 }					 
					 
if `z' > 0 {
append using "$WEB/temp/temp_ge_all"
 
save "$WEB/temp/temp_ge_all", replace
 }						
			
			
local z = `z' + 1 
			
                        }

replace  change_Xi_FULL     = round(change_Xi_FULL, 0.01)
replace  change_rGDP_FULL   = round(change_rGDP_FULL, 0.01) 
replace  change_price_FULL  = round(change_price_FULL, 0.01)
replace  change_IMR_FULL	= round(change_IMR_FULL, 0.01)					
						
split counter , parse("_")
rename counter1 partner
cap drop counter*
gen counter    = "Signing  new agreements (extensive margin)"
gen agree_type = "Shallow"

order counter agree_type target  partner  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL
keep  counter agree_type target  partner  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL
sort          target agree_type partner

save "$WEB/temp/temp_4_Shallow", replace

********************************************************************************
********************************************************************************

use "$WEB/temp/temp_4_Deep", clear

append using  "$WEB/temp/temp_4_Medium"
append using  "$WEB/temp/temp_4_Shallow"


export delimited using "$WEB/table6_now_fig4.csv", replace


********************************************************************************
********************************************************************************
* clean temp directory 
cd "$WEB/temp/"

local files : dir "`c(pwd)'"  files "*.dta" 

foreach file in `files' { 
	erase `file'    
} 

cap log close

********************************************************************************		
********************************************************************************