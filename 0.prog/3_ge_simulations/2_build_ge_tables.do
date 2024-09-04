local X   "$year_reg"
local iso "$iso"

 
cap 	log close
capture log using  "$LOG/3_ge_simulations/build_ge_tables_`=$iso'", text replace

********************************************************************************
********************************************************************************
* Read Results files

cd "$RES//`iso'//temp/"


local int : dir "`c(pwd)'"  files "*INT_*.dta" 
 

local s = 1 
 
foreach file in   `int'  {

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
local counterfactual    = "`type'_`cty'"

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
export excel  "$RES//`iso'//GE_tables_`X'.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel  replace
}


if `s' > 1 {
export excel  "$RES//`iso'//GE_tables_`X'.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel sheetreplace

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

merge m:1 country using "$CTY/temp_cty_name", keepusing(country_name)
keep if _m==3
drop _m



sort  country_name

keep    country_name country  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL  TREAT change_Ti_FULL
order   country_name country  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL  TREAT change_Ti_FULL
 
if `s' == 1 {
export excel  "$RES//`iso'//Country_GE_tables_`X'.xlsx", sheet("`counterfactual'_CTY")  firstrow(variables) nolabel  replace
}


if `s' > 1 {
export excel  "$RES//`iso'//Country_GE_tables_`X'.xlsx", sheet("`counterfactual'_CTY")  firstrow(variables) nolabel sheetreplace
}


 local s = `s' + 1

}

********************************************************************************
********************************************************************************
cd "$RES//`iso'//temp/"

local int0 : dir "`c(pwd)'"  files "*INT0_*.dta" 



local s = 1 
 
foreach file in   `int0'  {

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
local counterfactual    = "`type'_`cty'"

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
export excel  "$RES//`iso'//INT0_GE_tables_`X'.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel  replace
}


if `s' > 1 {
export excel  "$RES//`iso'//INT0_GE_tables_`X'.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel sheetreplace

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

merge m:1 country using "$CTY/temp_cty_name", keepusing(country_name)
keep if _m==3
drop _m



sort  country_name

keep    country_name country  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL  TREAT change_Ti_FULL
order   country_name country  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL  TREAT change_Ti_FULL
 
if `s' == 1 {
export excel  "$RES//`iso'//INT0_Country_GE_tables_`X'.xlsx", sheet("`counterfactual'_CTY")  firstrow(variables) nolabel  replace
}


if `s' > 1 {
export excel  "$RES//`iso'//INT0_Country_GE_tables_`X'.xlsx", sheet("`counterfactual'_CTY")  firstrow(variables) nolabel sheetreplace
}


 local s = `s' + 1

}

********************************************************************************
********************************************************************************
********************************************************************************
* Read Results files

cd "$RES//`iso'//temp/"


local ext : dir "`c(pwd)'"  files "*EXT1*.dta" 



local s = 1 
 
foreach file in  `ext' {

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
export excel  "$RES//`iso'//GE_EXT1_`X'.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel  replace
}


if `s' > 1 {
export excel  "$RES//`iso'//GE_EXT1_`X'.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel sheetreplace

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

merge m:1 country using "$CTY/temp_cty_name", keepusing(country_name)
keep if _m==3
drop _m



sort  country_name

keep    country_name country  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL  TREAT change_Ti_FULL
order   country_name country  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL  TREAT change_Ti_FULL
 
if `s' == 1 {
export excel  "$RES//`iso'//Country_GE_EXT1_`X'.xlsx", sheet("`counterfactual'_CTY")  firstrow(variables) nolabel  replace
}


if `s' > 1 {
export excel  "$RES//`iso'//Country_GE_EXT1_`X'.xlsx", sheet("`counterfactual'_CTY")  firstrow(variables) nolabel sheetreplace
}


 local s = `s' + 1

}

********************************************************************************
********************************************************************************
* Read Results files

cd "$RES//`iso'//temp/"


local ext : dir "`c(pwd)'"  files "*EXT2*.dta" 



local s = 1 
 
foreach file in  `ext' {

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
export excel  "$RES//`iso'//GE_EXT2_`X'.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel  replace
}


if `s' > 1 {
export excel  "$RES//`iso'//GE_EXT2_`X'.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel sheetreplace

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

merge m:1 country using "$CTY/temp_cty_name" , keepusing(country_name)
keep if _m==3
drop _m



sort  country_name

keep    country_name country  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL  TREAT change_Ti_FULL
order   country_name country  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL  TREAT change_Ti_FULL
 
if `s' == 1 {
export excel  "$RES//`iso'//Country_GE_EXT2_`X'.xlsx", sheet("`counterfactual'_CTY")  firstrow(variables) nolabel  replace
}


if `s' > 1 {
export excel  "$RES//`iso'//Country_GE_EXT2_`X'.xlsx", sheet("`counterfactual'_CTY")  firstrow(variables) nolabel sheetreplace
}


 local s = `s' + 1

}

********************************************************************************
********************************************************************************
* Read Results files

cd "$RES//`iso'//temp/"


local ext : dir "`c(pwd)'"  files "*EXT3*.dta" 



local s = 1 
 
foreach file in  `ext' {

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
export excel  "$RES//`iso'//GE_EXT3_`X'.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel  replace
}


if `s' > 1 {
export excel  "$RES//`iso'//GE_EXT3_`X'.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel sheetreplace

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

merge m:1 country using "$CTY/temp_cty_name" , keepusing(country_name)
keep if _m==3
drop _m



sort  country_name

keep    country_name country  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL  TREAT change_Ti_FULL
order   country_name country  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL  TREAT change_Ti_FULL
 
if `s' == 1 {
export excel  "$RES//`iso'//Country_GE_EXT3_`X'.xlsx", sheet("`counterfactual'_CTY")  firstrow(variables) nolabel  replace
}


if `s' > 1 {
export excel  "$RES//`iso'//Country_GE_EXT3_`X'.xlsx", sheet("`counterfactual'_CTY")  firstrow(variables) nolabel sheetreplace
}


 local s = `s' + 1

}


********************************************************************************
********************************************************************************
* This section is not included in the Toolkit 2.0 (version June  2024)


if "$demand_scenarios" == "YES" {

cd "$RES//`iso'//temp/"


local exd : dir "`c(pwd)'"  files "*EXD1*.dta" 
dis `exd'


local s = 1 
 
foreach file in  `exd' {

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
export excel  "$RES//`iso'//GE_EXD1_`X'.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel  replace
}


if `s' > 1 {
export excel  "$RES//`iso'//GE_EXD1_`X'.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel sheetreplace

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

merge m:1 country using "$CTY/temp_cty_name" , keepusing(country_name)
keep if _m==3
drop _m



sort  country_name

keep    country_name country  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL  TREAT change_Ti_FULL
order   country_name country  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL  TREAT change_Ti_FULL
 
if `s' == 1 {
export excel  "$RES//`iso'//Country_GE_EXD1_`X'.xlsx", sheet("`counterfactual'_CTY")  firstrow(variables) nolabel  replace
}


if `s' > 1 {
export excel  "$RES//`iso'//Country_GE_EXD1_`X'.xlsx", sheet("`counterfactual'_CTY")  firstrow(variables) nolabel sheetreplace
}


 local s = `s' + 1

}

********************************************************************************
********************************************************************************
********************************************************************************
* Read Results files

cd "$RES//`iso'//temp/"


local exd : dir "`c(pwd)'"  files "*EXD2*.dta" 



local s = 1 
 
foreach file in    `exd' {

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
export excel  "$RES//`iso'//GE_EXD2_`X'.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel  replace
}


if `s' > 1 {
export excel  "$RES//`iso'//GE_EXD2_`X'.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel sheetreplace

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

merge m:1 country using "$CTY/temp_cty_name" , keepusing(country_name)
keep if _m==3
drop _m



sort  country_name

keep    country_name country  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL  TREAT change_Ti_FULL
order   country_name country  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL  TREAT change_Ti_FULL
 
if `s' == 1 {
export excel  "$RES//`iso'//Country_GE_EXD2_`X'.xlsx", sheet("`counterfactual'_CTY")  firstrow(variables) nolabel  replace
}


if `s' > 1 {
export excel  "$RES//`iso'//Country_GE_EXD2_`X'.xlsx", sheet("`counterfactual'_CTY")  firstrow(variables) nolabel sheetreplace
}


 local s = `s' + 1

}

********************************************************************************
********************************************************************************

********************************************************************************
* Read Results files

cd "$RES//`iso'//temp/"


local exd : dir "`c(pwd)'"  files "*EXD3*.dta" 



local s = 1 
 
foreach file in    `exd' {

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
export excel  "$RES//`iso'//GE_EXD3_`X'.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel  replace
}


if `s' > 1 {
export excel  "$RES//`iso'//GE_EXD3_`X'.xlsx", sheet("`counterfactual'")  firstrow(variables) nolabel sheetreplace

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

merge m:1 country using "$CTY/temp_cty_name" , keepusing(country_name)
keep if _m==3
drop _m



sort  country_name

keep    country_name country  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL  TREAT change_Ti_FULL
order   country_name country  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL  TREAT change_Ti_FULL
 
if `s' == 1 {
export excel  "$RES//`iso'//Country_GE_EXD3_`X'.xlsx", sheet("`counterfactual'_CTY")  firstrow(variables) nolabel  replace
}


if `s' > 1 {
export excel  "$RES//`iso'//Country_GE_EXD3_`X'.xlsx", sheet("`counterfactual'_CTY")  firstrow(variables) nolabel sheetreplace
}


 local s = `s' + 1

}

}

********************************************************************************
*******************************************************************************/