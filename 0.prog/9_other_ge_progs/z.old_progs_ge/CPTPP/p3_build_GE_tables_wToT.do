
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

global ROOT 	 "$DB\WB_DTA_Toolkit"
global DATA 	 "$ROOT\data"
global TEMP	     "$DATA\temp"
global RES	     "$ROOT\res\CPTPP\ge_res"
global RES_C     "$ROOT\res\CPTPP\ge_res_c"
global GE 	 	 "$DATA\ge"

global CTY 	 	 "$ROOT\data\cty"

********************************************************************************

use "$RES\2_RTAsEffects_FULLGE_rcep_cptpp.dta" , clear

replace    cptpp_o  = 1 if exporter == "CHN"
replace    cptpp_d  = 1 if importer == "CHN"

collapse (sum)  trade tradehat_BLN  X_FULL , by(exporter importer t cptpp_d)
gen gr_trade 	 = (X_FULL - tradehat_BLN)/tradehat_BLN*100


********************************************************************************
* Bilateral Trade within DTA vs Outside DTA

global cnt       "rcep_cptpp rcep_new"
global sigma 	 "5"
local sigma      $sigma 


foreach counterfactual in $cnt {

* Format Table
cd "$RES"

local sigma $sigma 
local X     $year

global name     = "`counterfactual'"

display "$name"

use "$RES\2_RTAsEffects_FULLGE_$name.dta" , clear

drop    if importer == exporter

********************************************************************************
if "$name" =="rcep_cptpp"    {

replace    cptpp_o  = 1 if exporter == "CHN"
replace    cptpp_d  = 1 if importer == "CHN"

keep    if cptpp_o  == 1
replace    cptpp_d  =  0     if cptpp_d == .


}
********************************************************************************

********************************************************************************
if "$name" =="rcep_new"   {


keep    if rcep_o  == 1
replace    rcep_d  =  0     if rcep_d == .


}
********************************************************************************

cap rename cptpp_d sel_d
cap rename rcep_d  sel_d



collapse (sum)  trade tradehat_BLN  X_FULL , by(exporter t sel_d)

keep exporter   t trade tradehat_BLN  X_FULL  sel_d
gen gr_trade 	 = (X_FULL - tradehat_BLN)/tradehat_BLN*100

keep exporter t gr_trade tradehat_BLN sel_d

reshape wide gr_trade tradehat_BLN, i(exporter t) j(sel_d)
rename exporter country
merge m:1 country using "$TEMP\temp_cty_name.dta", keepusing(country_name)
keep if _m == 3
export excel  "CPTPP_GE_tables_cty_`sigma'_f22.xlsx", sheet("trade_within_DTA_$name")  firstrow(variables) nolabel sheetreplace
}



********************************************************************************
********************************************************************************
********************************************************************************
global cnt       "rcep_cptpp rcep_new"
global year      "2018" 
global sigma 	 "5"


foreach counterfactual in $cnt {

* Format Table
cd "$RES"

local sigma $sigma 
local X     $year

use "`counterfactual'_FULL_`sigma'.dta", clear

global name     = "`counterfactual'"

display "$name"

********************************************************************************
if "$name" =="rcep_cptpp"    {

replace region_o =  "$name"   		 if region_o=="East Asia & Pacific" | cptpp_o == 1

}
********************************************************************************

********************************************************************************
if "$name" =="rcep_new"   {

replace region_o =  "$name"   		 if region_o=="East Asia & Pacific" | rcep_o == 1

}
********************************************************************************


   gen  ctn   	= ""
replace ctn 	= region_o			  if (region_o ==  "$name"	 )
replace ctn		= "ROW"  			  if (region_o !=  "$name"	 )

tab ctn

********************************************************************************
summ replication 
scalar rep = r(mean)

if rep >= 11  {

display "error in $name"

...

}

********************************************************************************
collapse (sum) rGDP_FULL  rGDP_BLN  Xi_FULL  Xi_BLN, by(ctn year)

  
gen change_rGDP_FULL    	= ( rGDP_FULL  - rGDP_BLN    )/ rGDP_BLN    *100

gen change_Xi_FULL   		= (Xi_FULL     - Xi_BLN      )/ Xi_BLN      *100



gen id = _n

 reshape wide change_Xi change_rGDP , i(id year) j(ctn) string

       keep year change_*
       order year change_Xi_FULLROW change_rGDP_FULLROW, last
 
export excel  "CPTPP_GE_tables_cty_`sigma'_f22.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel sheetreplace

}

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


use "`counterfactual'_FULL_`sigma'.dta", clear

********************************************************************************
********************************************************************************
if "$name" =="rcep_cptpp"    {

replace region_o =  "$name"   		 if region_o=="East Asia & Pacific" | cptpp_o == 1

}

********************************************************************************
********************************************************************************
if "$name" =="rcep_new"   {

replace region_o =  "$name"   		 if region_o=="East Asia & Pacific" | rcep_o == 1

}

********************************************************************************
********************************************************************************

   gen  ctn   	= ""
replace ctn 	= region_o			  if (region_o ==  "$name"	 )
replace ctn		= "ROW"  			  if (region_o !=  "$name"	 )


cap rename cptpp_o cty_sel
cap rename rcep_o  cty_sel

keep year country change_* rGDP_BLN ctn cty_sel 

merge m:1 country using "$TEMP\temp_cty_name.dta", keepusing(country_name)
keep if _m==3
drop _m



*keep if ctn == "`counterfactual'"
sort  country_name

keep   year country_name country rGDP_BLN change_Xi_FULL change_rGDP_FULL  ctn cty_sel 
order  year country_name country rGDP_BLN change_Xi_FULL  change_rGDP_FULL ctn cty_sel

merge 1:1 country using "$CTY\income_class_2018.dta"
drop if _m == 2
drop _m

replace cty_sel = 2 if country =="CHN"

replace cty_sel = 3 if country =="USA"
replace cty_sel = 4 if country =="DEU"
replace cty_sel = 5 if country =="GBR"
replace cty_sel = 6 if country =="IND"


replace cty_sel = 7 if cty_sel == . & (income_group =="L" |  income_group =="LM") 
replace cty_sel = 8 if cty_sel == . & (income_group =="H" |  income_group =="UM") 

sort    cty_sel country_name

export excel  "CPTPP_GE_tables_cty_`sigma'_f22.xlsx", sheet("`counterfactual'_CTY")  firstrow(variables) nolabel sheetreplace

}
********************************************************************************
********************************************************************************
