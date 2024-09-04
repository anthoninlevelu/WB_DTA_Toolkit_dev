/******************************************************************************* 
	     Deep Trade Agreements Toolkit: Trade and Welfare Impacts 

			Nadia Rocha, Gianluca Santoni, Giulio Vannelli 

                  	   this version: FEB 2023
				   
website: https://xxxxxxx.org/

when using the tool please cite:  
Fontagné, L., Rocha, N., Ruta, M., Santoni, G. (2023),
 The Economic Impact of Deepening Trade Agreements”, world Bank Economic Review, forthcoming  

*******************************************************************************/
********************************************************************************


clear all
program drop _all
macro drop _all
matrix drop _all
clear mata
clear matrix
   
set virtual on
set more off
set scheme s1color
set excelxlsxlargefile on
version
******************************************************************************** 
********************************************************************************
* Gianluca's path

 global DB           	  "C:\Users\gianl\Dropbox" 								
*global DB           	  "D:\santoni\Dropbox" 								
 global ROOT 	          "$DB\WW_other_projs\WB_2023\WB_GE\WB_DTA_Toolkit"			 

********************************************************************************
********************************************************************************


global PROG 	          "$ROOT\0.prog"
global DATA 	          "$ROOT\1.data"
global RES  	          "$ROOT\2.res\toolkit"

* make sure this is equal to the master dofile

global fdate_bg			   "2002"    // for trade stats and rca
global ldate_bg			   "2021"

global ldate_bg1		   "2015"	 // for tradede stats
global ldate_bg2		   "2010"	
global ldate_bg3		   "2005"	

global first_year          "1986"
global year_start 	       "1986"
global year_end		       "2019"





********************************************************************************
* this refers to 
global report			    "UZB"
global country_interest     "UZB"   

local iso 				    "$report"
 global country_interest    "UZB"
  global DRAFT  	        "$DB\WW_other_projs\WB_2023\WB_GE\Uzbekistan"

********************************************************************************  
/* this refers to 
global report			    "BLK"
local iso 				    "SRB"

 global country_interest    "ALB BIH MKD MNE SRB"
  global DRAFT  	        "$DB\WW_other_projs\WB_2023\WB_GE\Balkans"

*******************************************************************************/

	use		"$DATA\cty\WBregio", clear
	
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
/* The following organizes the raw results into the report layout */
********************************************************************************
* First table is about trade facts
********************************************************************************

cd "$DRAFT"


// 1.1: trade openness:
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


import excel "$RES\\`iso'\\statistics.xlsx", sheet("Openness") firstrow clear


 if `s' == 0 {

save "$DRAFT\temp\temp_table", replace
 }
 
 
  if `s' > 0 {
merge 1:1 year using "$DRAFT\temp\temp_table"
drop _m

save "$DRAFT\temp\temp_table", replace
 }

local s = `s' + 1 

}

keep if year == $ldate_bg2 | year == $ldate_bg

reshape long openness, i(year) j(iso3) string


           gen temp = openness			   if iso3!="$reg_s"
bys year: egen mean = mean(temp)  
cap drop temp

********************************************************************************
********************************************************************************

local 	 new = _N + 1
        set obs `new'

     replace iso3 ="MEAN"            if   iso3     ==  ""
     replace year = $ldate_bg        if   year     ==  .

	    summ  mean 				     if    year    ==  $ldate_bg 
     replace openness =`r(mean)'     if   openness == .


local 	 new = _N + 1
        set obs `new'

     replace iso3 ="MEAN"            if   iso3     ==  ""
     replace year = $ldate_bg2       if   year     ==  .

	    summ  mean 				     if    year    ==  $ldate_bg2 
     replace openness =`r(mean)'     if   openness == .

cap drop mean
	 

********************************************************************************
********************************************************************************		
replace iso3 = "z."  + iso3  if iso3=="MEAN"
replace iso3 = "zz." + iso3  if iso3=="$reg_s"
		
reshape wide openness  , i(iso3) j(year) 
		
sort iso3

export excel using "$DRAFT\Tables.xlsx", sheet("Table1_a")  sheetreplace firstrow(variables) nolabel 
	
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
/* 	Share in total Exports
(Top 10 markets)	Share in total Exports 
(First market)	First 
Market
*/


// 1.2: # Reached Markets
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


import excel "$RES\\`iso'\\statistics.xlsx", sheet("Top 10 Mkts") firstrow clear


 if `s' == 0 {

save "$DRAFT\temp\temp_table", replace
 }
 
 
  if `s' > 0 {
merge 1:1 year using "$DRAFT\temp\temp_table"
drop _m

save "$DRAFT\temp\temp_table", replace
 }

local s = `s' + 1 

}

keep if year == $ldate_bg2 | year == $ldate_bg
keep year num_mkts*	top_10_mkts*

 
reshape long num_mkts top_10_mkts, i(year) j(iso3) string


           gen temp     = num_mkts			   if iso3!="$reg_s"
bys year: egen mean_num = mean(temp)  
cap drop temp
           gen temp     = top_10_mkts		   if iso3!="$reg_s"
bys year: egen mean_sh  = mean(temp)  
cap drop temp

********************************************************************************
********************************************************************************

local 	 new = _N + 1
        set obs `new'

     replace iso3 ="MEAN"            if   iso3     ==  ""
     replace year = $ldate_bg        if   year     ==  .

	    summ  mean_num  		     if    year       ==  $ldate_bg 
     replace num_mkts    =`r(mean)'  if   num_mkts    == .
	    summ  mean_sh		         if    year       ==  $ldate_bg 
     replace top_10_mkts =`r(mean)'  if   top_10_mkts == .


local 	 new = _N + 1
        set obs `new'

     replace iso3 ="MEAN"            if   iso3     ==  ""
     replace year = $ldate_bg2       if   year     ==  .

	
	    summ  mean_num  		     if    year       ==  $ldate_bg2 
     replace num_mkts    =`r(mean)'  if   num_mkts    == .
	    summ  mean_sh		         if    year       ==  $ldate_bg2 
     replace top_10_mkts =`r(mean)'  if   top_10_mkts == .

cap drop mean*
	 

********************************************************************************
********************************************************************************		
replace iso3 = "z."  + iso3  if iso3=="MEAN"
replace iso3 = "zz." + iso3  if iso3=="$reg_s"
		
reshape wide num_mkts top_10_mkts  , i(iso3) j(year) 
		
sort iso3
order iso3 num_mkts$ldate_bg2	num_mkts$ldate_bg top_10_mkts$ldate_bg2 top_10_mkts$ldate_bg

export excel using "$DRAFT\Tables.xlsx", sheet("Table1_b")  sheetreplace firstrow(variables) nolabel 


********************************************************************************
********************************************************************************
// 1.2: # Suppliers

local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


import excel "$RES\\`iso'\\statistics.xlsx", sheet("Top 10 Mkts M") firstrow clear


 if `s' == 0 {

save "$DRAFT\temp\temp_table", replace
 }
 
 
  if `s' > 0 {
merge 1:1 year using "$DRAFT\temp\temp_table"
drop _m

save "$DRAFT\temp\temp_table", replace
 }

local s = `s' + 1 

}

keep if year == $ldate_bg2 | year == $ldate_bg
keep year num_mkts*	top_10_mkts*

 
reshape long num_mkts top_10_mkts, i(year) j(iso3) string


           gen temp     = num_mkts			   if iso3!="$reg_s"
bys year: egen mean_num = mean(temp)  
cap drop temp
           gen temp     = top_10_mkts		   if iso3!="$reg_s"
bys year: egen mean_sh  = mean(temp)  
cap drop temp

********************************************************************************
********************************************************************************

local 	 new = _N + 1
        set obs `new'

     replace iso3 ="MEAN"            if   iso3     ==  ""
     replace year = $ldate_bg        if   year     ==  .

	    summ  mean_num  		     if    year       ==  $ldate_bg 
     replace num_mkts    =`r(mean)'  if   num_mkts    == .
	    summ  mean_sh		         if    year       ==  $ldate_bg 
     replace top_10_mkts =`r(mean)'  if   top_10_mkts == .


local 	 new = _N + 1
        set obs `new'

     replace iso3 ="MEAN"            if   iso3     ==  ""
     replace year = $ldate_bg2       if   year     ==  .

	
	    summ  mean_num  		     if    year       ==  $ldate_bg2 
     replace num_mkts    =`r(mean)'  if   num_mkts    == .
	    summ  mean_sh		         if    year       ==  $ldate_bg2 
     replace top_10_mkts =`r(mean)'  if   top_10_mkts == .

cap drop mean*
	 

********************************************************************************
********************************************************************************		
replace iso3 = "z."  + iso3  if iso3=="MEAN"
replace iso3 = "zz." + iso3  if iso3=="$reg_s"
		
reshape wide num_mkts top_10_mkts  , i(iso3) j(year) 
		
sort iso3
order iso3 num_mkts$ldate_bg2	num_mkts$ldate_bg top_10_mkts$ldate_bg2 top_10_mkts$ldate_bg



export excel using "$DRAFT\Tables.xlsx", sheet("Table1_b_M")  sheetreplace firstrow(variables) nolabel 


********************************************************************************
********************************************************************************
// 1.3: Share of main suppliers/buyers
/**************************************

local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


import excel "$RES\\`iso'\\statistics.xlsx", sheet("Top Mkts X") firstrow clear


 if `s' == 0 {

save "$DRAFT\temp\temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$DRAFT\temp\temp_table"

save "$DRAFT\temp\temp_table", replace
 }

local s = `s' + 1 

}

keep if year == $ldate_bg2 | year == $ldate_bg

collapse (mean) x_mkts_sh [aw = v], by( iso_d year)
 
		
gsort     -x_mkts_sh -yea
 


export excel using "$DRAFT\Tables.xlsx", sheet("Table1_b2")  sheetreplace firstrow(variables) nolabel 

********************************************************************************
********************************************************************************

local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


import excel "$RES\\`iso'\\statistics.xlsx", sheet("Top Mkts M") firstrow clear


 if `s' == 0 {

save "$DRAFT\temp\temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$DRAFT\temp\temp_table"

save "$DRAFT\temp\temp_table", replace
 }

local s = `s' + 1 

}

keep if year == $ldate_bg2 | year == $ldate_bg

 collapse (mean) m_mkts_sh [aw = v], by(iso_o year)
 
		
gsort     -m_mkts_sh -yea
 


export excel using "$DRAFT\Tables.xlsx", sheet("Table1_b3")  sheetreplace firstrow(variables) nolabel 


*******************************************************************************/
********************************************************************************

local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


import excel "$RES\\`iso'\\statistics.xlsx", sheet("Top 10 Mkts_detail X") firstrow clear


 if `s' == 0 {

save "$DRAFT\temp\temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$DRAFT\temp\temp_table"

save "$DRAFT\temp\temp_table", replace
 }

local s = `s' + 1 

}

keep if year == $ldate_bg2 | year == $ldate_bg

replace region_o ="$report" if region_o !="$reg_s"
collapse (mean) x_mkts_sh [aw = v], by(region_o iso_d year)
 
		
gsort     -x_mkts_sh -yea
 


export excel using "$DRAFT\Tables.xlsx", sheet("Table1_b2")  sheetreplace firstrow(variables) nolabel 
********************************************************************************
********************************************************************************

local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


import excel "$RES\\`iso'\\statistics.xlsx", sheet("Top 10 Mkts_detail M") firstrow clear


 if `s' == 0 {

save "$DRAFT\temp\temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$DRAFT\temp\temp_table"

save "$DRAFT\temp\temp_table", replace
 }

local s = `s' + 1 

}

keep if year == $ldate_bg2 | year == $ldate_bg

replace region_d ="$report" if region_d !="$reg_s"
collapse (mean) m_mkts_sh [aw = v], by(region_d iso_o year)
 
		
gsort     -m_mkts_sh -yea
 


export excel using "$DRAFT\Tables.xlsx", sheet("Table1_b3")  sheetreplace firstrow(variables) nolabel 



/******************************************************************************/
********************************************************************************
********************************************************************************
// 1.3: top Markets
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


import excel "$RES\\`iso'\\statistics.xlsx", sheet("First Mkt X") firstrow clear


 if `s' == 0 {

save "$DRAFT\temp\temp_table", replace
 }
 
 
  if `s' > 0 {
merge 1:1 iso_d year using "$DRAFT\temp\temp_table"
drop _m

save "$DRAFT\temp\temp_table", replace
 }

local s = `s' + 1 

}

keep if year == $ldate_bg2 | year == $ldate_bg
 
 
reshape long x_mkts_sh, i(year iso_d) j(iso3) string
		
		
replace iso3 = "z."  + iso3  if iso3=="MEAN"
replace iso3 = "zz." + iso3  if iso3=="$reg_s"
				
		
reshape wide x_mkts_sh  , i(iso3 iso_d) j(year) 
		
sort iso3
order iso3 iso_d 

drop if x_mkts_sh$ldate_bg2 == . & x_mkts_sh$ldate_bg == .
export excel using "$DRAFT\Tables.xlsx", sheet("Table1_c")  sheetreplace firstrow(variables) nolabel 

********************************************************************************
********************************************************************************
* Second table is anbout trade facts
********************************************************************************
/*
# Exported Products	
Share in total Exports (top 10 products)
Share in total Exports (first products)	
First Product (HS 6-digit)
*/

cd "$DRAFT"

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


import excel "$RES\\`iso'\\statistics.xlsx", sheet("Top 10 product X cum share") firstrow clear


 if `s' == 0 {

save "$DRAFT\temp\temp_table", replace
 }
 
 
  if `s' > 0 {
merge 1:1 year using "$DRAFT\temp\temp_table"
drop _m

save "$DRAFT\temp\temp_table", replace
 }

local s = `s' + 1 

}

keep if year == $ldate_bg2 | year == $ldate_bg
keep year num_products*	  top_10_prod*


reshape long num_products	  top_10_prod, i(year) j(iso3) string


           gen temp     = num_products			   if iso3!="$reg_s"
bys year: egen mean_num = mean(temp)  
cap drop temp
           gen temp     = top_10_prod		       if iso3!="$reg_s"
bys year: egen mean_sh  = mean(temp)  
cap drop temp

********************************************************************************
********************************************************************************

local 	 new = _N + 1
        set obs `new'

     replace iso3 ="MEAN"                if   iso3     ==  ""
     replace year = $ldate_bg            if   year     ==  .

	    summ  mean_num  		         if    year       ==  $ldate_bg 
     replace num_products    =`r(mean)'  if   num_products    == .
	    summ  mean_sh		             if    year       ==  $ldate_bg 
     replace top_10_prod =`r(mean)'      if   top_10_prod == .


local 	 new = _N + 1
        set obs `new'

     replace iso3 ="MEAN"                if   iso3     ==  ""
     replace year = $ldate_bg2           if   year     ==  .

	
	    summ  mean_num  		         if    year       ==  $ldate_bg2 
     replace num_products    =`r(mean)'  if   num_products    == .
	    summ  mean_sh		             if    year       ==  $ldate_bg2 
     replace top_10_prod =`r(mean)'      if   top_10_prod == .

cap drop mean*
	 

********************************************************************************
********************************************************************************		
replace iso3 = "z."  + iso3  if iso3=="MEAN"
replace iso3 = "zz." + iso3  if iso3=="$reg_s"
		
reshape wide num_products	  top_10_prod  , i(iso3) j(year) 
		
sort iso3
order iso3 num_products$ldate_bg2	num_products$ldate_bg top_10_prod$ldate_bg2 top_10_prod$ldate_bg



export excel using "$DRAFT\Tables.xlsx", sheet("Table2_a")  sheetreplace firstrow(variables) nolabel 


********************************************************************************
********************************************************************************
/* 	Share in total Imports
(Top 10 markets)	Share in total Exports 
(First market)	First 
Market
*/


local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


import excel "$RES\\`iso'\\statistics.xlsx", sheet("Top 10 product M cum share") firstrow clear


 if `s' == 0 {

save "$DRAFT\temp\temp_table", replace
 }
 
 
  if `s' > 0 {
merge 1:1 year using "$DRAFT\temp\temp_table"
drop _m

save "$DRAFT\temp\temp_table", replace
 }

local s = `s' + 1 

}

keep if year == $ldate_bg2 | year == $ldate_bg
keep year num_products*	  top_10_prod*


reshape long num_products	  top_10_prod, i(year) j(iso3) string


           gen temp     = num_products			   if iso3!="$reg_s"
bys year: egen mean_num = mean(temp)  
cap drop temp
           gen temp     = top_10_prod		       if iso3!="$reg_s"
bys year: egen mean_sh  = mean(temp)  
cap drop temp

********************************************************************************
********************************************************************************

local 	 new = _N + 1
        set obs `new'

     replace iso3 ="MEAN"                if   iso3     ==  ""
     replace year = $ldate_bg            if   year     ==  .

	    summ  mean_num  		         if    year       ==  $ldate_bg 
     replace num_products    =`r(mean)'  if   num_products    == .
	    summ  mean_sh		             if    year       ==  $ldate_bg 
     replace top_10_prod =`r(mean)'      if   top_10_prod == .


local 	 new = _N + 1
        set obs `new'

     replace iso3 ="MEAN"                if   iso3     ==  ""
     replace year = $ldate_bg2           if   year     ==  .

	
	    summ  mean_num  		         if    year       ==  $ldate_bg2 
     replace num_products    =`r(mean)'  if   num_products    == .
	    summ  mean_sh		             if    year       ==  $ldate_bg2 
     replace top_10_prod =`r(mean)'      if   top_10_prod == .

cap drop mean*
	 

********************************************************************************
********************************************************************************		
replace iso3 = "z."  + iso3  if iso3=="MEAN"
replace iso3 = "zz." + iso3  if iso3=="$reg_s"
		
reshape wide num_products	  top_10_prod  , i(iso3) j(year) 
		
sort iso3
order iso3 num_products$ldate_bg2	num_products$ldate_bg top_10_prod$ldate_bg2 top_10_prod$ldate_bg



export excel using "$DRAFT\Tables.xlsx", sheet("Table2_a_M")  sheetreplace firstrow(variables) nolabel 


********************************************************************************
********************************************************************************
********************************************************************************


// 2.2: top products
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


import excel "$RES\\`iso'\\statistics.xlsx", sheet("First product X share") firstrow clear


 if `s' == 0 {

save "$DRAFT\temp\temp_table", replace
 }
 
 
  if `s' > 0 {
merge 1:1 hs6 year using "$DRAFT\temp\temp_table"
drop _m

save "$DRAFT\temp\temp_table", replace
 }

local s = `s' + 1 

}

keep if year == $ldate_bg2 | year == $ldate_bg
 
 
reshape long x_prod_sh, i(year hs6) j(iso3) string
		
		
replace iso3 = "z."  + iso3  if iso3=="MEAN"
replace iso3 = "zz." + iso3  if iso3=="$reg_s"
				
		
reshape wide x_prod_sh  , i(iso3 hs6) j(year) 
		
sort iso3
order iso3 hs6 

drop if x_prod_sh$ldate_bg2 == . & x_prod_sh$ldate_bg == .
export excel using "$DRAFT\Tables.xlsx", sheet("Table2_b")  sheetreplace firstrow(variables) nolabel 


********************************************************************************
********************************************************************************
********************************************************************************


// 2.2: top products: Imports
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


import excel "$RES\\`iso'\\statistics.xlsx", sheet("First product M share") firstrow clear


 if `s' == 0 {

save "$DRAFT\temp\temp_table", replace
 }
 
 
  if `s' > 0 {
merge 1:1 hs6 year using "$DRAFT\temp\temp_table"
drop _m

save "$DRAFT\temp\temp_table", replace
 }

local s = `s' + 1 

}

keep if year == $ldate_bg2 | year == $ldate_bg
 
 
reshape long m_prod_sh, i(year hs6) j(iso3) string
		
		
replace iso3 = "z."  + iso3  if iso3=="MEAN"
replace iso3 = "zz." + iso3  if iso3=="$reg_s"
				
		
reshape wide m_prod_sh  , i(iso3 hs6) j(year) 
		
sort iso3
order iso3 hs6 

drop if m_prod_sh$ldate_bg2 == . & m_prod_sh$ldate_bg == .
export excel using "$DRAFT\Tables.xlsx", sheet("Table2_b_M")  sheetreplace firstrow(variables) nolabel 


********************************************************************************
********************************************************************************
/********************************************************************************


// 2.2b: RCA
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


import excel "$RES\\`iso'\\statistics.xlsx", sheet("RCA_details") firstrow clear

keep if iso3    =="$iso"
keep if period  == $ldate_bg 


keep iso3 rank_pos N rank

 if `s' == 0 {

save "$DRAFT\temp\temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$DRAFT\temp\temp_table"
 
save "$DRAFT\temp\temp_table", replace
 }

local s = `s' + 1 

}
sort rank_pos
export excel using "$DRAFT\Tables.xlsx", sheet("Table2_rca")  sheetreplace firstrow(variables) nolabel 


********************************************************************************
********************************************************************************
* Third table is about PTA facts
********************************************************************************
********************************************************************************


cd "$DRAFT"

// 3.1:
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


import excel "$RES\\`iso'\\statistics.xlsx", sheet("RTAs_at_place") firstrow clear

keep iso_d agreement entry_force kmeanPP2 id_agree
bys agreement entry_force kmeanPP2 id_agree: egen part = nvals(iso_d)


keep agreement part entry_force kmeanPP2
duplicates drop 



    gen agree_type  = ""
replace agree_type  = "Shallow" if kmeanPP2 == 3
replace agree_type  = "Medium"  if kmeanPP2 == 2
replace agree_type  = "Deep"    if kmeanPP2 == 1


keep agreement part entry_force agree_type

gen country = "$iso"
order country agreement entry_force part   agree_type

 if `s' == 0 {

save "$DRAFT\temp\temp_table0", replace
 }
 
 
  if `s' > 0 {
append using "$DRAFT\temp\temp_table0"
 
save "$DRAFT\temp\temp_table0", replace
 }

local s = `s' + 1 

}

sort country agreement entry_force
export excel using "$DRAFT\Tables.xlsx", sheet("Table3_a")  sheetreplace firstrow(variables) nolabel 
********************************************************************************
********************************************************************************
// 3.2:
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


import excel "$RES\\`iso'\\statistics.xlsx", sheet("mkt_sh_by_RTA") firstrow clear
keep if  year == $ldate_bg

replace mkt_sh_m = mkt_sh_m*0.01
replace mkt_sh_x = mkt_sh_x*0.01

keep agreement mkt_sh_m	mkt_sh_x


keep agreement mkt_sh_m	mkt_sh_x
duplicates drop 



gen country = "$iso"
order country agreement mkt_sh_m	mkt_sh_x

 if `s' == 0 {

save "$DRAFT\temp\temp_table1", replace
 }
 
 
  if `s' > 0 {
append using "$DRAFT\temp\temp_table1"
 
save "$DRAFT\temp\temp_table1", replace
 }

local s = `s' + 1 

}

merge 1:1 country agreement using "$DRAFT\temp\temp_table0"
drop if _m == 1
drop _m
order country agreement entry_force part agree_type mkt_sh_m mkt_sh_x
sort country agreement entry_force
export excel using "$DRAFT\Tables.xlsx", sheet("Table3_b")  sheetreplace firstrow(variables) nolabel 

********************************************************************************
********************************************************************************

// 3.3:
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


import excel "$RES\\`iso'\\statistics.xlsx", sheet("PTAs_coverage_cty") firstrow clear

reshape long agree_coverage, i(Area) j(id_agree)


 order   id_agree agree_coverage

 if `s' == 0 {

save "$DRAFT\temp\temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$DRAFT\temp\temp_table"
 
save "$DRAFT\temp\temp_table", replace
 }

local s = `s' + 1 

}

duplicates drop 

merge m:1 id_agree using "$ROOT\1.data\cty\id_agree_legend"
drop if _m == 2
drop _m 

save "$DRAFT\temp\temp_table", replace
 
 
use "$DATA\ntw\temp_cluster_baseline.dta", clear
 
merge 1:m id_agree using "$DRAFT\temp\temp_table",
drop if _m == 1
drop _m 
duplicates drop 



bys kmeanPP_baseline: egen number = nvals(id_agree)

    gen agree_type  = ""
replace agree_type  = "Shallow" if kmeanPP_baseline == "3"
replace agree_type  = "Medium"  if kmeanPP_baseline == "2"
replace agree_type  = "Deep"    if kmeanPP_baseline == "1" 

collapse (mean) number agree_coverage, by(Area agree_type)


tostring number, replace

replace agree_type = agree_type+number
drop  number

reshape wide agree_coverage, i(Area) j(agree_type) string 

export excel using "$DRAFT\Tables.xlsx", sheet("Table3_c")  sheetreplace firstrow(variables) nolabel 

********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
// 4.1: GE
***************************************
local z = 0
foreach iso of global country_interest {

			

global iso    "`iso'"

cd "$RES\\`iso'\\"
				local r = 0

	  import excel using "GE_tables_2019.xlsx", describe 
				forvalues sheet = 1/`=r(N_worksheet)' {  
	  import excel using "GE_tables_2019.xlsx", describe 


						 local sheetname=r(worksheet_`sheet')  
						 import excel using  "GE_tables_2019.xlsx", sheet("`sheetname'")  firstrow  cellrange("`r(range_`sheet')'") clear
						 gen  counter  = "`sheetname'"
						 cap   drop    *ROW

						 drop if change_rGDP_FULL == .
						 
						 reshape long  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL change_Ti_FULL , i(  counter) j(cty) string
						 
						 drop change_Ti_FULL
						 
	if `r' == 0 {

	save "$DRAFT\temp\temp_ge", replace
	 }					 
						 
	if `r' > 0 {
	append using "$DRAFT\temp\temp_ge"
	   

	save "$DRAFT\temp\temp_ge", replace
	 }
						  
	local r = `r' + 1 
						  
							}
							
********************************************************************************
						
						
if `z' == 0 {

save "$DRAFT\temp\temp_ge_all", replace
 }					 
					 
if `z' > 0 {
append using "$DRAFT\temp\temp_ge_all"
 
save "$DRAFT\temp\temp_ge_all", replace
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
merge m:1 id_agree using "$ROOT\1.data\cty\id_agree_legend", keepusing(agreement)
drop if _m == 2
drop _m 

order counter1 cty agreement change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL
keep counter1 cty agreement change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL
sort cty agreement
export excel using "$DRAFT\Tables.xlsx", sheet("Table4")  sheetreplace firstrow(variables) nolabel 

********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************


local z = 0
foreach iso of global country_interest {

			

global iso    "`iso'"

cd "$RES\\`iso'\\"
				local r = 0

	  import excel using "INT0_GE_tables_2019.xlsx", describe 
				forvalues sheet = 1/`=r(N_worksheet)' {  
	  import excel using "INT0_GE_tables_2019.xlsx", describe 


						 local sheetname=r(worksheet_`sheet')  
						 import excel using  "INT0_GE_tables_2019.xlsx", sheet("`sheetname'")  firstrow  cellrange("`r(range_`sheet')'") clear
						 gen  counter  = "`sheetname'"
						 cap   drop    *ROW

						 drop if change_rGDP_FULL == .
						 
						 reshape long  change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL change_Ti_FULL , i(  counter) j(cty) string
						 
						 drop change_Ti_FULL
						 
	if `r' == 0 {

	save "$DRAFT\temp\temp_ge", replace
	 }					 
						 
	if `r' > 0 {
	append using "$DRAFT\temp\temp_ge"
	   

	save "$DRAFT\temp\temp_ge", replace
	 }
						  
	local r = `r' + 1 
						  
							}
							
********************************************************************************
						
						
if `z' == 0 {

save "$DRAFT\temp\temp_ge_all", replace
 }					 
					 
if `z' > 0 {
append using "$DRAFT\temp\temp_ge_all"
 
save "$DRAFT\temp\temp_ge_all", replace
 }						
			
			
local z = `z' + 1 
			
                        }

replace  change_Xi_FULL     = round(change_Xi_FULL, 0.01)
replace  change_rGDP_FULL   = round(change_rGDP_FULL, 0.01) 
replace  change_price_FULL  = round(change_price_FULL, 0.01)
replace  change_IMR_FULL	= round(change_IMR_FULL, 0.01)					
						
split counter , parse("_")
destring counter3, replace
rename counter3 id_agree
merge m:1 id_agree using "$ROOT\1.data\cty\id_agree_legend", keepusing(agreement)
drop if _m == 2
drop _m 

order counter1 cty agreement change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL
keep counter1 cty agreement change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL
sort cty agreement
export excel using "$DRAFT\Tables.xlsx", sheet("Table4_INT0")  sheetreplace firstrow(variables) nolabel 

********************************************************************************
********************************************************************************
********************************************************************************
// 4.1: GE
***************************************

cd "$DRAFT"

local z = 0
foreach iso of global country_interest {

			

global iso    "`iso'"

cd "$RES\\`iso'\\"
				local r = 0

	  import excel using "Country_GE_EXT1_2019.xlsx", describe 
				forvalues sheet = 1/`=r(N_worksheet)' {  
	  import excel using "Country_GE_EXT1_2019.xlsx", describe 


						 local sheetname=r(worksheet_`sheet')  
						 import excel using  "Country_GE_EXT1_2019.xlsx", sheet("`sheetname'")  firstrow  cellrange("`r(range_`sheet')'") clear
						 
						 gen  counter  = "`sheetname'"
					     keep if country =="$iso"
						 drop if change_rGDP_FULL == .
						 cap drop TREAT	 
						 cap drop change_Ti_FULL
						 
	if `r' == 0 {

	save "$DRAFT\temp\temp_ge", replace
	 }					 
						 
	if `r' > 0 {
	append using "$DRAFT\temp\temp_ge"
	   

	save "$DRAFT\temp\temp_ge", replace
	 }
						  
	local r = `r' + 1 
						  
							}
							
********************************************************************************
						
						
if `z' == 0 {

save "$DRAFT\temp\temp_ge_all", replace
 }					 
					 
if `z' > 0 {
append using "$DRAFT\temp\temp_ge_all"
 
save "$DRAFT\temp\temp_ge_all", replace
 }						
			
			
local z = `z' + 1 
			
                        }

replace  change_Xi_FULL     = round(change_Xi_FULL, 0.01)
replace  change_rGDP_FULL   = round(change_rGDP_FULL, 0.01) 
replace  change_price_FULL  = round(change_price_FULL, 0.01)
replace  change_IMR_FULL	= round(change_IMR_FULL, 0.01)					
						
split counter , parse("_")


sort country counter1
order country  counter1 change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL
keep country  counter1 change_Xi_FULL change_rGDP_FULL change_price_FULL change_IMR_FULL
export excel using "$DRAFT\Tables.xlsx", sheet("Table4_b")  sheetreplace firstrow(variables) nolabel 



********************************************************************************
********************************************************************************
********************************************************************************

cd "$DRAFT\"



// 1.2: # Reached Markets
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


use "$RES\\`iso'\\RTA_to_sign.dta", clear


drop if iso       == "`iso'"

 keep if item=="demand" 
 
keep iso rank item  kmeanPP2 agreement x_mkts_sh m_mkts_sh

  
replace iso =  "EU28" if iso =="AUT" |	iso =="BEL" |	iso =="BGR" |	iso =="CYP" |	/*
*/                       iso =="CZE" |	iso =="DEU" |	iso =="DNK" |	iso =="ESP" |	/*
*/                       iso =="EST" |	iso =="FIN" |	iso =="FRA" |	iso =="GRC" |	/* 
*/                       iso =="HRV" |	iso =="HUN" |	iso =="IRL" |	iso =="ITA" |	/*
*/                       iso =="LTU" |	iso =="LVA" |	iso =="LUX" |   iso =="MLT" |	/*
*/						 iso =="NLD" |	iso =="POL" |	iso =="PRT" |	iso =="ROU" |	/*
*/                       iso =="SVK" |	iso =="SVN" |	iso =="SWE" 	


collapse (min) rank  (sum) x_mkts_sh m_mkts_sh, by(iso kmeanPP2 agreement)


gen country = "$iso"
sort rank

keep if _n <=10

order rank country iso   agreement kmeanPP2 x_mkts_sh m_mkts_sh  
keep rank country  iso  agreement kmeanPP2 x_mkts_sh m_mkts_sh      

 if `s' == 0 {

save "$DRAFT\temp\temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$DRAFT\temp\temp_table"
 
save "$DRAFT\temp\temp_table", replace
 }

local s = `s' + 1 

}

sort country rank

export excel using "$DRAFT\Tables.xlsx", sheet("Table_C1")  sheetreplace firstrow(variables) nolabel 

********************************************************************************
********************************************************************************

cd "$DRAFT\"



// 1.2: # Reached Markets
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


use "$RES\\`iso'\\RTA_to_sign.dta", clear


drop if iso       == "`iso'"

 keep if item =="supply int good" 
 
keep iso rank item  kmeanPP2 agreement x_mkts_sh m_mkts_sh

  
replace iso =  "EU28" if iso =="AUT" |	iso =="BEL" |	iso =="BGR" |	iso =="CYP" |	/*
*/                       iso =="CZE" |	iso =="DEU" |	iso =="DNK" |	iso =="ESP" |	/*
*/                       iso =="EST" |	iso =="FIN" |	iso =="FRA" |	iso =="GRC" |	/* 
*/                       iso =="HRV" |	iso =="HUN" |	iso =="IRL" |	iso =="ITA" |	/*
*/                       iso =="LTU" |	iso =="LVA" |	iso =="LUX" |   iso =="MLT" |	/*
*/						 iso =="NLD" |	iso =="POL" |	iso =="PRT" |	iso =="ROU" |	/*
*/                       iso =="SVK" |	iso =="SVN" |	iso =="SWE" 	


collapse (min) rank  (sum) x_mkts_sh m_mkts_sh, by(iso kmeanPP2 agreement)


gen country = "$iso"
sort rank

keep if _n <=10

order country rank iso  agreement kmeanPP2 x_mkts_sh m_mkts_sh  
keep country rank iso  agreement kmeanPP2 x_mkts_sh m_mkts_sh       

 if `s' == 0 {

save "$DRAFT\temp\temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$DRAFT\temp\temp_table"
 
save "$DRAFT\temp\temp_table", replace
 }

local s = `s' + 1 

}

sort country rank

export excel using "$DRAFT\Tables.xlsx", sheet("Table_C2")  sheetreplace firstrow(variables) nolabel 


********************************************************************************
********************************************************************************


cd "$DRAFT\"



// 1.2: # Reached Markets
***************************************
local s = 0

foreach iso of global country_interest {


global iso    "`iso'"


use "$RES\\`iso'\\RTA_to_sign.dta", clear

drop if iso       == "`iso'"

if "$selection_criteria" == "DS" {
keep if item=="demand" | item =="supply int good"
}

keep iso rank item  

replace item = subinstr(item, " ", "_", .)
reshape wide rank, i(iso) j(item)  string


egen avg_rank = rowmean(rank*)


replace iso =  "EU28" if iso =="AUT" |	iso =="BEL" |	iso =="BGR" |	iso =="CYP" |	/*
*/                       iso =="CZE" |	iso =="DEU" |	iso =="DNK" |	iso =="ESP" |	/*
*/                       iso =="EST" |	iso =="FIN" |	iso =="FRA" |	iso =="GRC" |	/* 
*/                       iso =="HRV" |	iso =="HUN" |	iso =="IRL" |	iso =="ITA" |	/*
*/                       iso =="LTU" |	iso =="LVA" |	iso =="LUX" |   iso =="MLT" |	/*
*/						 iso =="NLD" |	iso =="POL" |	iso =="PRT" |	iso =="ROU" |	/*
*/                       iso =="SVK" |	iso =="SVN" |	iso =="SWE" 	


collapse (mean) *rank*, by(iso)

gen country = "$iso"
sort avg_rank

keep if _n <=10

order country iso avg_rank rankdemand ranksupply_int_good
keep country iso avg_rank rankdemand ranksupply_int_good

 if `s' == 0 {

save "$DRAFT\temp\temp_table", replace
 }
 
 
  if `s' > 0 {
append using "$DRAFT\temp\temp_table"
 
save "$DRAFT\temp\temp_table", replace
 }

local s = `s' + 1 

}

sort country avg_rank

export excel using "$DRAFT\Tables.xlsx", sheet("Table_C3")  sheetreplace firstrow(variables) nolabel 

********************************************************************************
********************************************************************************












********************************************************************************
********************************************************************************
* clean temp directory 
cd "$DRAFT\temp\"

local files : dir "`c(pwd)'"  files "*.dta" 

foreach file in `files' { 
	erase `file'    
} 

cap log close

********************************************************************************		
********************************************************************************
********************************************************************************
********************************************************************************