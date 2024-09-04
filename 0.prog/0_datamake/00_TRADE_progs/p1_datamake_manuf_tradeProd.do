
********************************************************************************
********************************************************************************

cap 	log close
capture log using "$PROG\log_files\datamake_COMTRADE", text replace


********************************************************************************
********************************************************************************
*   build TP for Manufacturing only: UNIDO + COMTRADE
cd "$COMTRADE"

qui unzipfile "sitc_import_2digit_isic_iso", replace
use "sitc_import_2digit_isic_iso.dta", clear 


cap drop iso_o 
cap drop iso_d 

gen cnum  = cnum_o 
merge m:1 cnum using "country_cnum_iso3_TP2024.dta" , keepusing(iso3 unido_missing)
drop  if          _m  != 3
drop  if unido_missing == 1
cap drop _m 
cap drop cnum
cap drop unido_missing
rename iso3 iso_o 

gen cnum  = cnum_d 
merge m:1 cnum using "country_cnum_iso3_TP2024.dta" , keepusing(iso3 unido_missing)
drop  if          _m  != 3
drop  if unido_missing == 1
cap drop _m 
cap drop cnum
cap drop unido_missing
rename iso3 iso_d 

destring chapt_isic, replace

gen import_decl_man        = tradevalueus     if chapt_isic >= 15 &  chapt_isic <= 37

gen import_decl_agr        = tradevalueus     if chapt_isic == 1

gen import_decl_min        = tradevalueus     if chapt_isic >= 10 &  chapt_isic <= 14


collapse (sum) import_decl*, by(iso_o iso_d year)
  

drop if  iso_o==iso_d

collapse (sum) import_decl*, by(iso_o iso_d year)


save "$TEMP/temp_trade_import_declarations", replace
cap erase sitc_import_2digit_isic_iso.dta

********************************************************************************
********************************************************************************

qui unzipfile "sitc_export_2digit_isic_iso", replace

use "sitc_export_2digit_isic_iso.dta", clear 


cap drop iso_o 
cap drop iso_d 

gen cnum  = cnum_o 
merge m:1 cnum using "country_cnum_iso3_TP2024.dta" , keepusing(iso3 unido_missing)
drop  if          _m  != 3
drop  if unido_missing == 1
cap drop _m 
cap drop cnum
cap drop unido_missing
rename iso3 iso_o 

gen cnum  = cnum_d 
merge m:1 cnum using "country_cnum_iso3_TP2024.dta" , keepusing(iso3 unido_missing)
drop  if          _m  != 3
drop  if unido_missing == 1
cap drop _m 
cap drop cnum
cap drop unido_missing
rename iso3 iso_d 



destring chapt_isic, replace

gen export_decl_man        = tradevalueus     if chapt_isic >= 15 &  chapt_isic <= 37

gen export_decl_agr        = tradevalueus     if chapt_isic == 1

gen export_decl_min        = tradevalueus     if chapt_isic >= 10 &  chapt_isic <= 14



collapse (sum) export_decl*, by(iso_o iso_d year)
 

drop if  iso_o==iso_d

collapse (sum) export_decl*, by(iso_o iso_d year)

merge 1:1 iso_o iso_d year using "$TEMP/temp_trade_import_declarations"



gen 	  trade_man   = import_decl_man / (1 + $tc_man   )   
replace   trade_man   = export_decl_man     				 if trade_man  == .  &  export_decl_man  != .
 

gen 	  trade_agr    = import_decl_agr / (1 + $tc_agr   )   
replace   trade_agr    = export_decl_agr     				 if trade_agr  == .  &  export_decl_agr  != .
 
gen 	  trade_min    = import_decl_min / (1 + $tc_min   )   
replace   trade_min    = export_decl_min     				 if trade_min  == .  &  export_decl_min  != .

 
 
collapse (sum) trade_*, by(iso_o iso_d year)

replace trade_man  =  0    if trade_man < $min_trade
replace trade_agr  =  0    if trade_agr < $min_trade
replace trade_min  =  0    if trade_min < $min_trade

drop if iso_d == "SCG" & year > 2005
drop if iso_o == "SCG" & year > 2005


drop if iso_d == "SRB" & year <= 2005
drop if iso_o == "SRB" & year <= 2005

drop if iso_d == "MNE" & year <= 2005
drop if iso_o == "MNE" & year <= 2005

save "$TEMP/temp_trade_comtrade", replace
cap erase sitc_export_2digit_isic_group.dta

********************************************************************************
********************************************************************************


unique iso_o   // 167*167
unique iso_d



bys iso_o: keep if _n==1
keep iso_o
rename iso_o iso3

gen prod_id = 1

save "$TEMP/X_iso", replace


********************************************************************************
********************************************************************************

use "$TEMP/temp_trade_comtrade", clear

bys iso_o: egen min_year = min(year)
bys iso_o: egen max_year = max(year)
 

bys iso_o: keep if _n==1
keep iso_o min_year  max_year
rename iso_o iso3

gen prod_id = 1

save "$TEMP/X_iso_min_max_year", replace


********************************************************************************
********************************************************************************
* UNIDO 2024

* Preliminarty Step: prepare country code using Comtrade
import delimited "$CTY/country_codes_comtrade.csv", clear 

// this is used for Comtrade
preserve
rename country_code       ctycode
rename country_iso3		  iso3digitalpha     
rename country_name       ctyfullnameenglish

save "$TEMP/codes_iso_cnum.dta", replace
restore

// this is used to add iso3 codes to UNIDO
keep country_code country_name country_iso3
rename country_name country_name_un
rename country_iso3  iso3 

rename country_code country
save "$TEMP/codes_iso_cnum_for_unido.dta", replace


* Upload UNIDO
cd "$UNIDO"

local files : dir "`c(pwd)'"  files "*.zip" 
display `files'


foreach file in `files' { 
	unzipfile `file'    , replace
} 

import delimited "data.csv", clear

replace valueusd  = value  if unittype =="N"  
           drop 		   if unittype =="I"
// for monetary series makesure to retain USD, substitute with value for series in numbers (establisment for example)

keep   countrycode year valueusd activitycode activitycombination unittype variablecode

rename countrycode 			   country


rename activitycode     	   isic 
rename activitycombination     isiccomb 
rename valueusd    			   value 
rename variablecode    		   varcode
rename unittype    			   unit 



label variable country   	   "Country Code"
label variable year 		   "Year"
label variable isic 		   "ISIC Code"
label variable isiccomb 	   "ISIC Combination Code"
label variable value           "Value"
label variable varcode  	   "Variable Code"

label variable unit 		   "Unit"

save "$TEMP/indstat2024.dta", replace

keep if isiccomb != isic
keep isiccomb
duplicates drop 
save "$TEMP/indstat2024_isiccomb.dta", replace

********************************************************************************
********************************************************************************
* Import Country names


import delimited "country.csv", clear

rename country     country_name
rename countrycode country


keep countr*


merge 1:1 country using "$TEMP/codes_iso_cnum_for_unido.dta"
drop if _m ==2
drop _m 

keep country country_name_un iso3

 
cap drop if iso3 =="DDR" // no need because comtrade does not  
 
save "$TEMP/indstat_country_code", replace

********************************************************************************
* Import Variables

import delimited "variable.csv", clear
rename variablecode varcode
save  "$TEMP/indstat_variable_code" , replace

********************************************************************************
* Import ISIC combination details

import delimited "activity_combination.csv", varnames(1) clear 
rename activitycode  isiccomb
rename activity      isiccomb_detail
save  "$TEMP/indstat_isiccomb_detail" , replace

********************************************************************************
********************************************************************************
 
use "$TEMP/indstat2024", replace

drop if country == 278  //  DDR no need because comtrade does not  
merge m:1 country using "$TEMP/indstat_country_code", keepusing(iso3 )
keep if _m == 3  /* all matched: Kosovo included */
drop _m

merge m:1 varcode  using  "$TEMP/indstat_variable_code"
drop if _m == 2 // production index must be _m 2 
drop _m 



gen  	name=""
replace name="plants" 	if varcode==1
replace name="workers" 	if varcode==4
replace name="wages" 	if varcode==5
replace name="y" 		if varcode==14

replace name="va" 		if varcode==20
replace name="k" 		if varcode==21
        drop 			if name=="" 

keep value   year isic isiccomb  name iso3 country
reshape wide value, i( isiccomb  year isic iso3 country) j(name) string

save "$UNIDO/indstat2024.dta", replace

* clean unido directory
local files : dir "`c(pwd)'"  files "*.csv" 
display `files'


foreach file in `files' { 
	erase `file'  
} 

********************************************************************************
********************************************************************************
use "$UNIDO/indstat2024.dta" , clear   /* use the raw INDSTAT data: computed from TradeProd */
keep if isic =="D" | isic =="C"

drop if iso3  == "SCG" & year == 1989
replace iso3  =  "YUG" if   ( iso3=="SCG"  & year  <= 1991 )   //  this is because in Comtrade 
replace iso3  = "SUN"  if   ( iso3=="RUS"  & year  <= 1991 )


********************************************************************************
* ALWAYS CHECK THE ISO CODES IN  COMTRADE!!!
********************************************************************************
* 841	USA and Puerto Rico (...1980)	USA	1962	1980	1962	1980
* 842	USA	USA								1981	2022	1981	2022


replace iso3 			= "USA" 	if iso3             =="PRI"  & year <= 1980
replace country 		= 840   	if country          == 630   & year <= 1980


replace country 		= 841   	if iso3             == "USA"   & year <= 1980
replace country 		= 842   	if iso3             == "USA"   & year >= 1981



********************************************************************************
********************************************************************************
* 56	Belgium	BEL							1999	2022	1999	2022
* 58	Belgium-Luxembourg (...1998)	BEL	1962	1998	1962	1998



replace iso3 			= "BEL"   	if country          == 442     & year <= 1998
replace  country 		= 58     	if iso3 			=="BEL"    & year <= 1998
replace  country 		= 56     	if iso3 			=="BEL"    & year >= 1999

********************************************************************************
********************************************************************************
* 710	South Africa	                ZAF	2000	2022	2000	2022	2000	2022	2000	2022
* 711	Southern African Customs Union	ZA1	1962	1999	1974	1999	1962	1999	1974	1999


replace iso3 			= "ZA1"   	if country          == 748     & year <= 1999
replace iso3 			= "ZA1"   	if country          == 710     & year <= 1999
replace iso3 			= "ZA1"   	if country          == 516     & year <= 1999
replace iso3 			= "ZA1"   	if country          == 426     & year <= 1999
replace iso3 			= "ZA1"   	if country          == 72      & year <= 1999

replace country			= 711    	if iso3             == "ZA1"   & year <= 1999

replace iso3 			= "ZAF"   	if iso3             == "ZA1"   & year <= 1999

********************************************************************************
********************************************************************************
* 356	India (...1974)	IND	1962	1974	1962	1974
* 699	India			IND	1975	2022	1975	2022

replace country			= 699    	if iso3             == "IND"   & year >= 1975


********************************************************************************
********************************************************************************
* 586	Pakistan							PAK	1972	2022	1972	2022
* 588	East and West Pakistan (...1971)	PAK	1962	1971	1962	1971

replace country			= 588    	if iso3             == "PAK"   & year <= 1971


********************************************************************************
********************************************************************************
* 590	Panama, excl.Canal Zone (...1977)	PAN	1962	1977	1962	1977
* 591	Panama								PAN	1978	2022	1978	2022

replace country			= 590    	if iso3             == "PAN"   & year <= 1977


 

********************************************************************************
********************************************************************************
* 704	Viet Nam					1997	2022	1997	2022		VNM
* 868	Rep. of Vietnam (...1974)	1963	1973	1963	1973		VNM


// in Indstat only 704 exists no Vientam prior of 1998

********************************************************************************
********************************************************************************
* 720	Dem. Yemen (...1990)		    YMD	1989	1989	1989	1989
* 886	Arab Rep. of Yemen (...1990)	YEM	1975	1975	1975	1975
* 887	Yemen							YEM	1991	2019	1991	2019

drop if  country		== 887    	& year <= 1990

********************************************************************************
********************************************************************************
* these are the codes in comtrade now

replace country         = 251       if country          == 250 & iso3 =="FRA"
replace country         = 579       if country          == 578 & iso3 =="NOR"
replace country         = 757       if country          == 756 & iso3 =="CHE"
replace country 		= 490       if country          == 158    // this is Taiwan , TWN   (is 490 Asia nes is taiwan?)

********************************************************************************
* the following codes do not exists in Comtrade

drop  if country        == 412    // this is Kosovo ,  _KS
drop  if country        == 630    // this is puerto rico, PRI

********************************************************************************
********************************************************************************

gen prod_man =    valuey if isic =="D"
gen prod_min =    valuey if isic =="C"


collapse (sum) prod_* , by(iso3 year )

replace prod_man = .                   if prod_man == 0
replace prod_min = .                   if prod_min == 0


merge m:1 iso3 using "$TEMP/X_iso_min_max_year", keepusing(iso3)
keep if _m ==  3
drop _m 

save "$TEMP/Y_prod", replace


********************************************************************************
********************************************************************************
bys iso3: keep if _n==1
keep iso3
gen trade_id = 1
save "$TEMP/Y_iso", replace


********************************************************************************
********************************************************************************


use "$TEMP/Y_iso", replace

merge 1:1 iso3 using "$TEMP/X_iso"
drop _m

merge 1:1 iso3 using "$TEMP/VA_iso"
drop if _m == 2
drop _m

keep if trade_id == 1 & prod_id == 1 


bys iso3: keep if _n==1
keep iso3
gen iso_o = iso3
gen iso_d = iso3
save "$TEMP/iso_matched", replace  
unique iso3 /* 167 country codes matches */

********************************************************************************
********************************************************************************


use "$TEMP/temp_trade_comtrade", replace


merge m:1 iso_o using "$TEMP/iso_matched", keepusing(iso_o)
keep if _m == 3
drop _m 

/* we lost here Liberia and Somalia 1986

		cty_name_o	iso3_un	first_year_X	last_year_X	first_year_M	last_year_M
 430	Liberia	LBR	1963	1984	1963	1984
706		Somalia	SOM	1962	1982	1966	1982

*/

merge m:1 iso_d using "$TEMP/iso_matched", keepusing(iso_d)
keep if _m == 3


collapse (sum) Xman_comtrade = trade_man  Xmin_comtrade = trade_min, by(year iso_o)
 
rename iso_o iso3

save "$TEMP/X", replace
unique iso3   // 167  
********************************************************************************
********************************************************************************

use  "$TEMP/temp_gdp", clear

merge m:1 iso3 using "$TEMP/iso_matched", keepusing(iso3)
drop if _m == 2
drop _m

save  "$TEMP/temp_gdp", replace

********************************************************************************
********************************************************************************
* Merge total exports

use "$TEMP/Y_prod", clear

merge m:1 iso3 using "$TEMP/iso_matched", keepusing(iso3)
keep if _m == 3
drop _m


********************************************************************************
********************************************************************************
preserve
bys year: keep if _n==1
keep year
save "$TEMP/square", replace
restore

preserve
bys iso3: keep if _n==1
keep iso3
cross using "$TEMP/square.dta"
save "$TEMP/square", replace
restore


/* Square the dataset */
merge 1:1 year iso3 using "$TEMP/square.dta", nogenerate
cap erase "$TEMP/square.dta"

********************************************************************************
********************************************************************************

merge 1:1 iso3 year using "$TEMP/X"
drop if _m == 2
drop _m 
 

replace Xman_comtrade  = . 		            if 		Xman_comtrade 	 == 0
replace Xmin_comtrade  = . 		            if 		Xmin_comtrade 	 == 0

replace prod_man       = . 		            if 		prod_man	     == 0 
replace prod_min       = . 		            if 		prod_min	     == 0 

 
gen 	intflow_man    = prod_man		- (Xman_comtrade)
replace intflow_man    = . 					if intflow_man <= 0
replace prod_man       = . 					if intflow_man <= 0    // set missing in production values if implied domestic sales are negative

gen 	intflow_min    = prod_min		- (Xmin_comtrade)
replace intflow_min    = . 					if intflow_min <= 0
replace prod_min       = . 					if intflow_min <= 0


keep year iso3 prod_* *_comtrade intflow_*


preserve
bys year: keep if _n==1
keep year
save "$TEMP/square", replace
restore

preserve
bys iso3: keep if _n==1
keep iso3
cross using "$TEMP/square.dta"
save "$TEMP/square", replace
restore


/* Square the dataset */
merge 1:1 year iso3 using "$TEMP/square.dta", nogenerate
cap erase "$TEMP/square.dta"


********************************************************************************
* Only Linear Interpolation of Produciton and Trade
sort iso3 year

bys iso3: mipolate prod_man		   		year   , linear  gen(prod_man_i)
bys iso3: mipolate prod_min		   		year   , linear  gen(prod_min_i)

 
bys iso3: mipolate Xman_comtrade		year   , linear  gen(Xman_comtrade_i)
bys iso3: mipolate Xmin_comtrade   		year   , linear  gen(Xmin_comtrade_i)

 

* generate Interal flows using linearly interpolated series 

cap drop  INT*
gen      INT_flows_man_i                   = prod_man_i   		- Xman_comtrade_i
replace  INT_flows_man_i                   = .                                         if INT_flows_man_i   	<= 0

gen      INT_flows_min_i                   = prod_min_i   		- Xmin_comtrade_i
replace  INT_flows_min_i                   = .                                         if INT_flows_min_i   	<= 0



bys iso3: mipolate INT_flows_man_i		  year   , linear  gen(INT_flows_man_ii)
		  replace  INT_flows_man_ii        = INT_flows_man_i                           if INT_flows_man_i 		!= .


bys iso3: mipolate INT_flows_min_i		  year   , linear  gen(INT_flows_min_ii)
		  replace  INT_flows_min_ii        = INT_flows_min_i                           if INT_flows_min_i 		!= .

keep year iso3 INT_flow*  intflow_*

rename iso3 iso_o
save "$TEMP/inflows_filled", replace

********************************************************************************
********************************************************************************

use "$TEMP/temp_trade_comtrade", clear

keep if year >= $year_start
keep if year <= $year_end





merge m:1 iso_o using "$TEMP/iso_matched", keepusing(iso_o)
keep if _m == 3
drop _m 

merge m:1 iso_d using "$TEMP/iso_matched", keepusing(iso_d)
keep if _m == 3
drop _m 



preserve
bys year: keep if _n==1
keep year
save "$TEMP/square", replace
restore

preserve
bys iso_o: keep if _n==1
keep iso_o
cross using "$TEMP/square.dta"
save "$TEMP/square", replace
restore

preserve
bys iso_d: keep if _n==1
keep iso_d
cross using "$TEMP/square.dta"
save "$TEMP/square", replace
restore


/* Square the dataset */
merge 1:1 year iso_o iso_d using "$TEMP/square.dta", nogenerate
cap erase "$TEMP/square.dta"

save "$TEMP/temp_trade_final", replace

********************************************************************************
********************************************************************************


merge m:1 year iso_o using "$TEMP/inflows_filled"
drop if _m==2
drop _m


gen trade_man_i 	     = trade_man
gen trade_man_ii 	     = trade_man


replace trade_man 	     = intflow_man   		        if iso_o == iso_d
replace trade_man_i	     = INT_flows_man_i		        if iso_o == iso_d
replace trade_man_ii     = INT_flows_man_ii		        if iso_o == iso_d


gen trade_min_i 	     = trade_min
gen trade_min_ii 	     = trade_min


replace trade_min 	     = intflow_min			        if iso_o == iso_d
replace trade_min_i	     = INT_flows_min_i		        if iso_o == iso_d
replace trade_min_ii     = INT_flows_min_ii		        if iso_o == iso_d



replace trade_man        = 0		                    if iso_o != iso_d & trade_man     == .
replace trade_man_i      = 0		                    if iso_o != iso_d & trade_man_i   == .
replace trade_man_ii     = 0		                    if iso_o != iso_d & trade_man_ii  == .

replace trade_min        = 0		                    if iso_o != iso_d & trade_min     == .
replace trade_min_i      = 0		                    if iso_o != iso_d & trade_min_i   == .
replace trade_min_ii     = 0		                    if iso_o != iso_d & trade_min_ii  == .

********************************************************************************
/* ATT: express in thoudand US$ */
********************************************************************************

replace trade_man    	  = trade_man 		    /1000
replace trade_man_i	 	  = trade_man_i		    /1000
replace trade_man_ii	  = trade_man_ii		/1000


replace trade_min 	 	  = trade_min 		    /1000
replace trade_min_i	 	  = trade_min_i		    /1000
replace trade_min_ii	  = trade_min_ii		/1000


 
keep year iso_o iso_d trade_*


save		"$TEMP/MAN_trade_toolkit", replace



********************************************************************************
********************************************************************************
* Crea cty_list per TP
********************************************************************************
********************************************************************************

use		"$TEMP/MAN_trade_toolkit", clear


	keep	iso_o  
	bys 	iso_o  : keep if _n == 1
	tab iso_o
save "$TEMP/TP_cty", replace
 

********************************************************************************
********************************************************************************

use		"$TEMP/MAN_trade_toolkit", clear


foreach var in man  man_i  man_ii  min  min_i  min_ii {

cap drop es_`var'
gen xx   	= trade_`var'  if iso_o== iso_d
replace xx 	= -1 	 if iso_o== iso_d & xx == . 


bys iso_o  year: egen min_o   = min(xx)
bys iso_o  year: egen tX_o    = total(trade_`var' )

bys iso_d  year: egen min_d   = min(xx)
bys iso_d  year: egen tX_d    = total(trade_`var' )



gen es_`var' = (min_o == - 1 | min_d == - 1 ) 

cap drop min*
cap drop tX*
cap drop xx

replace es_`var' = 1 - es_`var'

}


********************************************************************************
********************************************************************************

replace iso_o   = "ROU"  if iso_o =="ROM"
replace iso_d   = "ROU"  if iso_d =="ROM"

replace iso_o   = "PSE"  if iso_o =="PAL"
replace iso_d   = "PSE"  if iso_d =="PAL"

********************************************************************************
********************************************************************************
gen iso3 = iso_o 

merge m:1 iso3 using "$TEMP/X_iso_min_max_year", keepusing(*_year)
keep if _m == 3
 
******

****** 
 
 
drop if year < min_year
drop if year > max_year 

drop min_year
drop max_year
drop iso3 
tab _m
drop _m 

********************************************************************************

gen iso3 = iso_d

merge m:1 iso3 using "$TEMP/X_iso_min_max_year", keepusing(*_year)
keep if _m == 3

drop if year < min_year
drop if year > max_year 

drop min_year
drop max_year
drop iso3 
tab _m
drop _m 
********************************************************************************			

tab year 
tab year if iso_o == iso_d

********************************************************************************
 
 
label data "This version  $S_TIME  $S_DATE "
save		"$TEMP/MAN_trade_toolkit", replace


tab year if iso_o == iso_d & es_man  		== 1
tab year if iso_o == iso_d & es_man_i		== 1 
tab year if iso_o == iso_d & es_man_ii      == 1

cap log close
********************************************************************************
********************************************************************************
