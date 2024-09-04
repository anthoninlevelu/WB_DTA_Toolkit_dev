
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


 global DB 			            "D:\Santoni\Dropbox"
 global DB      	            "C:\Users\gianl\Dropbox"
*global DB  		            "E:\Dropbox\"


********************************************************************************

global ROOT 	                "$DB\WB_DTA_Toolkit"
global PROG 	                "$ROOT\prog"
global DATA 	                "$ROOT\data"
global TEMP	                    "$DATA\temp"
global RES	     				"$ROOT\res\Palestine"

********************************************************************************
********************************************************************************
* Parametrization of the GE Gravity

global qrta_k      				=  "rta_k3"

global select_dataset		    "est_sample_man_i_hat_zero"                 /* this ensures that the estimation dataset is rectangular by year on Manufacturing: with the assumption that when Prod < exports => domestic sales == 0 */


global year_intervals			"off"

global preliminary   			"on"   									/* Set preliminary "on" if need to compute structural gravity estimates  */
global additional_reg			"off"	
********************************************************************************
********************************************************************************
* Compute Trade indexes
********************************************************************************
********************************************************************************
cd "$DATA\ge"


if "$preliminary"   == "on" {

********************************************************************************
********************************************************************************
* prepare EU 

/*
1		EC 		Treaty		1958
5		EC (9) Enlargement	1973
13		EC (10) Enlargement	1981
18		EC (12) Enlargement	1986
28		EC (15) Enlargement	1995
89		EC (25) Enlargement	2004
117		EC (27) Enlargement	2007
235	 	EU (28) Enlargement


*/
use "trade_wRTA_yearly.dta", clear
keep if $select_dataset == 1
keep if id_agree == 1 | id_agree == 5 |  id_agree == 13 | id_agree == 18 | id_agree == 28 | id_agree == 89 | id_agree == 117 | id_agree == 235

keep if rta == 1
bys iso_o year: keep if _n == 1
gen eu_o = 1 

keep iso_o year eu_o
gen iso_d = iso_o 
gen eu_d  = eu_o 

save "$TEMP/gravity_temp", replace

********************************************************************************
********************************************************************************
	
use "trade_wRTA_yearly.dta", clear
keep if $select_dataset == 1

bys iso_o: keep if _n == 1
keep iso_o
gen iso_d = iso_o
save "$TEMP\cty_sample.dta", replace


********************************************************************************	
********************************************************************************
* select dyadic controls

use "$DATA\cty\dist_cepii", clear

merge m:1 iso_o using "$TEMP\cty_sample", keepusing(iso_o)
keep if _m==3
drop _m

merge m:1 iso_d using "$TEMP\cty_sample", keepusing(iso_d)
keep if _m==3
drop _m

keep iso_o iso_d contig comlang_ethno comlang_off colony dist distw distwces

save "$TEMP\temp_geo.dta", replace

* Select Country Name
use "$DATA\cty\geo_cepii", clear
bys iso3: keep if _n == 1
keep iso3 country

rename iso3 iso_o 

merge m:1 iso_o using "$TEMP\cty_sample", keepusing(iso_o)
keep if _m==3
drop _m

rename country country_name
rename iso_o country
save "$TEMP\temp_cty_name.dta", replace

********************************************************************************
* select country geo controls
use "$DATA\cty\WBregio", clear


rename iso3 iso_o
replace iso_o ="PAL" if iso_o =="WBG"
replace iso_o ="YUG" if iso_o =="SRB"

 
merge m:1 iso_o using "$TEMP\cty_sample", keepusing(iso_o)
keep if _m==3
drop _m

gen iso_d = iso_o

rename region region_o
gen region_d = region_o


save "$TEMP\temp_regio.dta", replace

******************************************

use "$TEMP\temp_geo.dta", clear

merge m:1 iso_o using "$TEMP\temp_regio.dta", keepusing(region_o)
keep if _m == 3
drop _m

merge m:1 iso_d using "$TEMP\temp_regio.dta", keepusing(region_d)
keep if _m == 3
drop _m

save "$TEMP\temp_geo.dta", replace


********************************************************************************
********************************************************************************
* Esti-bration
********************************************************************************
********************************************************************************

global trade_frictions 			"trade_man_i_hat_zero_sh"
global trade        			"trade_man_i_hat_zero"
global select_dataset		    "est_sample_man_i_hat_zero"                 /* this ensures that the estimation dataset is rectangular by year on Manufacturing: with the assumption that when Prod < exports => domestic sales == 0 */
global set_zeros    		    "replace $trade = 0  if $trade == ."    



use "trade_wRTA_yearly.dta", clear
keep if $select_dataset == 1
$set_zeros

bys iso_d year: egen tM = total($trade)
gen $trade_frictions    = $trade / tM

********************************************************************************
* generate RTA dummy

tab kmeanPP2 kmean
 
qui tab kmeanPP2, gen(RTA_k)
cap drop rta_k*

replace RTA_k1 		= 0                    if RTA_k1 == .
replace RTA_k2 		= 0                    if RTA_k2 == .
cap replace RTA_k3  = 0                    if RTA_k3 == .

gen rta_k1          = rta*RTA_k1
gen rta_k2          = rta*RTA_k2
cap  gen rta_k3     = rta*RTA_k3


local lab: variable label  RTA_k1
     label var rta_k1  "`lab'"

local lab: variable label  RTA_k2
     label var rta_k2  "`lab'"


cap local lab: variable label  RTA_k3
cap  label var rta_k3  "`lab'"

label var rta "RTA"

********************************************************************************
* add the quasi-agreement PAL-ISR

replace rta 	= 1 if iso_o =="PAL" & iso_d =="ISR"
replace rta 	= 1 if iso_d =="PAL" & iso_o =="ISR"

replace $qrta_k = 1 if iso_o =="PAL" & iso_d =="ISR"
replace $qrta_k = 1 if iso_d =="PAL" & iso_o =="ISR"

********************************************************************************
* generate International Border interacted with time

cap drop decade
gen 	decade = 1980 if year <= 1989
replace decade = 1990 if year <= 1999 & decade == .
replace decade = 2000 if year <= 2009 & decade == .
replace decade = 2010 if year <= 2019 & decade == .
 
 
 
 
 
gen  INTL_BRDR = (iso_o != iso_d)
 cap drop  INTL_BRDR_*
 foreach decade in 1980  1990  2000      {
generate INTL_BRDR_`decade'  = 1 if iso_o != iso_d & decade == `decade'
replace  INTL_BRDR_`decade'  = 0 if INTL_BRDR_`decade' == .
}

egen ij = group(iso_o iso_d)

********************************************************************************

if "$year_intervals" =="yes" {
	
 display "set year interval"
	
}



********************************************************************************

ppml_panel_sg $trade_frictions  		rta 				  rta_out	INTL_BRDR_*  		, ex(iso_o) 	 im(iso_d) 		year(year)      cluster(ij)    
outreg2 using "$RES\Structural_Gravity.xls",   dec(3) keep(rta 				  rta_out	INTL_BRDR_* ) addtext(Period, Full, Dependent, $trade_frictions  ) lab   replace

cap dr

ppml_panel_sg $trade_frictions  		rta_k*				  rta_out	INTL_BRDR_*  		, ex(iso_o) 	 im(iso_d) 		year(year)    genD(gamma_ij_alt)  predict(y_hat)  cluster(ij)    
outreg2 using "$RES\Structural_Gravity.xls",   dec(3) keep(rta_k* rta				  rta_out	INTL_BRDR_* ) addtext(Period, Full, Dependent, $trade_frictions  ) lab    

********************************************************************************

do "$PROG\1_ge_simulations\define_beta_k3.do"

********************************************************************************


replace gamma_ij_alt 	= . if gamma_ij_alt == 0

gen epsilon 		 	= ($trade_frictions /y_hat)
 

generate check_exp		=exp(ln(gamma_ij_alt) +  ln(epsilon))

generate tij_bar		=(gamma_ij_alt)*(epsilon)

corr tij_bar check_exp
cap drop check_exp

replace  tij_bar        = gamma_ij_alt    if trade==0

cap drop gamma_ij_alt
gen     gamma_ij_alt 	= tij_bar 
*/


label data "This version  $S_TIME  $S_DATE "
save "$RES\GE_data_estibrated_MAN_PAL.dta", replace




********************************************************************************
********************************************************************************
* Esti-bration: Agro+Man
********************************************************************************
********************************************************************************
cd "$DATA\ge"

global trade_frictions 			"trade_am_i_hat_zero_sh"
global trade        			"trade_am_i_hat_zero"
global select_dataset		    "est_sample_am_i_hat_zero"                 /* this ensures that the estimation dataset is rectangular by year on Manufacturing: with the assumption that when Prod < exports => domestic sales == 0 */
global set_zeros    		    "replace $trade = 0  if $trade == ."    


********************************************************************************

use "trade_wRTA_yearly.dta", clear
keep if $select_dataset == 1
$set_zeros

bys iso_d year: egen tM = total($trade)
gen $trade_frictions    = $trade / tM


********************************************************************************
* generate RTA dummy

tab kmeanPP2 kmean
 
qui tab kmeanPP2, gen(RTA_k)
cap drop rta_k*

replace RTA_k1 		= 0                    if RTA_k1 == .
replace RTA_k2 		= 0                    if RTA_k2 == .
cap replace RTA_k3  = 0                    if RTA_k3 == .

gen rta_k1          = rta*RTA_k1
gen rta_k2          = rta*RTA_k2
cap  gen rta_k3     = rta*RTA_k3


local lab: variable label  RTA_k1
     label var rta_k1  "`lab'"

local lab: variable label  RTA_k2
     label var rta_k2  "`lab'"


cap local lab: variable label  RTA_k3
cap  label var rta_k3  "`lab'"

label var rta "RTA"

********************************************************************************
* add the quasi-agreement PAL-ISR

replace rta 	= 1 if iso_o =="PAL" & iso_d =="ISR"
replace rta 	= 1 if iso_d =="PAL" & iso_o =="ISR"

replace $qrta_k = 1 if iso_o =="PAL" & iso_d =="ISR"
replace $qrta_k = 1 if iso_d =="PAL" & iso_o =="ISR"

********************************************************************************

********************************************************************************
* generate International Border interacted with time

cap drop decade
gen 	decade = 1980 if year <= 1989
replace decade = 1990 if year <= 1999 & decade == .
replace decade = 2000 if year <= 2009 & decade == .
replace decade = 2010 if year <= 2019 & decade == .
 
 
 
 
 
gen  INTL_BRDR = (iso_o != iso_d)
 cap drop  INTL_BRDR_*
 foreach decade in 1980  1990  2000      {
generate INTL_BRDR_`decade'  = 1 if iso_o != iso_d & decade == `decade'
replace  INTL_BRDR_`decade'  = 0 if INTL_BRDR_`decade' == .
}

egen ij = group(iso_o iso_d)

********************************************************************************

if "$year_intervals" =="yes" {
	
 display "set year interval"
	.. 
	
}



********************************************************************************

ppml_panel_sg $trade_frictions  		rta 				  rta_out	INTL_BRDR_*  		, ex(iso_o) 	 im(iso_d) 		year(year)      cluster(ij)    
outreg2 using "$RES\Structural_Gravity.xls",   dec(3) keep(rta				  rta_out	INTL_BRDR_* ) addtext(Period, Full, Dependent, $trade_frictions  ) lab    

cap dr

ppml_panel_sg $trade_frictions  		rta_k*				  rta_out	INTL_BRDR_*  		, ex(iso_o) 	 im(iso_d) 		year(year)    genD(gamma_ij_alt)  predict(y_hat)  cluster(ij)    
outreg2 using "$RES\Structural_Gravity.xls",   dec(3) keep(rta_k* rta				  rta_out	INTL_BRDR_* ) addtext(Period, Full, Dependent, $trade_frictions  ) lab    

********************************************************************************

do "$PROG\1_ge_simulations\define_beta_k3.do"

********************************************************************************


replace gamma_ij_alt 	= . if gamma_ij_alt == 0

gen epsilon 		 	= ($trade_frictions /y_hat)
 

generate check_exp		=exp(ln(gamma_ij_alt) +  ln(epsilon))

generate tij_bar		=(gamma_ij_alt)*(epsilon)

corr tij_bar check_exp
cap drop check_exp

replace  tij_bar        = gamma_ij_alt    if trade==0

cap drop gamma_ij_alt
gen     gamma_ij_alt 	= tij_bar 
*/


label data "This version  $S_TIME  $S_DATE "
save "$RES\GE_data_estibrated_AM_PAL.dta", replace

if "$additional_reg"    == "on" {
********************************************************************************
********************************************************************************
* Without Esti-bration: Agro+Man
********************************************************************************
********************************************************************************
cd "$DATA\ge"

global trade_frictions 			"trade_am_i_hat_zero_sh"
global trade        			"trade_am_i_hat_zero"
global select_dataset		    "est_sample_am_i_hat_zero"                 /* this ensures that the estimation dataset is rectangular by year on Manufacturing: with the assumption that when Prod < exports => domestic sales == 0 */
global set_zeros    		    "replace $trade = 0  if $trade == ."    


********************************************************************************

use "trade_wRTA_yearly.dta", clear
keep if $select_dataset == 1
$set_zeros

bys iso_d year: egen tM = total($trade)
gen $trade_frictions    = $trade / tM

********************************************************************************
* generate RTA dummy

tab kmeanPP2 kmean
 
qui tab kmeanPP2, gen(RTA_k)
cap drop rta_k*

replace RTA_k1 		= 0                    if RTA_k1 == .
replace RTA_k2 		= 0                    if RTA_k2 == .
cap replace RTA_k3  = 0                    if RTA_k3 == .

gen rta_k1          = rta*RTA_k1
gen rta_k2          = rta*RTA_k2
cap  gen rta_k3     = rta*RTA_k3


local lab: variable label  RTA_k1
     label var rta_k1  "`lab'"

local lab: variable label  RTA_k2
     label var rta_k2  "`lab'"


cap local lab: variable label  RTA_k3
cap  label var rta_k3  "`lab'"

label var rta "RTA"

********************************************************************************
* generate International Border interacted with time

cap drop decade
gen 	decade = 1980 if year <= 1989
replace decade = 1990 if year <= 1999 & decade == .
replace decade = 2000 if year <= 2009 & decade == .
replace decade = 2010 if year <= 2019 & decade == .
 
 
 
 
 
gen  INTL_BRDR = (iso_o != iso_d)
 cap drop  INTL_BRDR_*
 foreach decade in 1980  1990  2000      {
generate INTL_BRDR_`decade'  = 1 if iso_o != iso_d & decade == `decade'
replace  INTL_BRDR_`decade'  = 0 if INTL_BRDR_`decade' == .
}

egen ij = group(iso_o iso_d)

********************************************************************************

if "$year_intervals" =="yes" {
	
 display "set year interval"
	
}



********************************************************************************

ppml_panel_sg $trade_frictions  		rta 				  rta_out	INTL_BRDR_*  		, ex(iso_o) 	 im(iso_d) 		year(year)      cluster(ij)    
outreg2 using "$RES\Structural_Gravity.xls",   dec(3) keep(rta				  rta_out	INTL_BRDR_* ) addtext(Period, Full, Dependent, $trade_frictions  ) lab    

cap dr

ppml_panel_sg $trade_frictions  		rta_k*				  rta_out	INTL_BRDR_*  		, ex(iso_o) 	 im(iso_d) 		year(year)    genD(gamma_ij_alt)  predict(y_hat)  cluster(ij)    
outreg2 using "$RES\Structural_Gravity.xls",   dec(3) keep(rta_k* rta				  rta_out	INTL_BRDR_* ) addtext(Period, Full, Dependent, $trade_frictions  ) lab    

********************************************************************************

do "$PROG\1_ge_simulations\define_beta_k3.do"

********************************************************************************


replace gamma_ij_alt = . 				if gamma_ij_alt == 0
generate tij_bar	 = gamma_ij_alt



label data "This version  $S_TIME  $S_DATE "
save "$RES\GE_data_AM.dta", replace

********************************************************************************
********************************************************************************
* Esti-bration
********************************************************************************
********************************************************************************


global trade_frictions 			"trade_man_i_hat_zero"
global trade        			"trade_man_i_hat_zero"
global select_dataset		    "est_sample_man_i_hat_zero"                 /* this ensures that the estimation dataset is rectangular by year on Manufacturing: with the assumption that when Prod < exports => domestic sales == 0 */
global set_zeros    		    "replace $trade = 0  if $trade == ."    


use "trade_wRTA_yearly.dta", clear
keep if $select_dataset == 1
$set_zeros

********************************************************************************
* generate RTA dummy

tab kmeanPP2 kmean
 
qui tab kmeanPP2, gen(RTA_k)
cap drop rta_k*

replace RTA_k1 		= 0                    if RTA_k1 == .
replace RTA_k2 		= 0                    if RTA_k2 == .
cap replace RTA_k3  = 0                    if RTA_k3 == .

gen rta_k1          = rta*RTA_k1
gen rta_k2          = rta*RTA_k2
cap  gen rta_k3     = rta*RTA_k3


local lab: variable label  RTA_k1
     label var rta_k1  "`lab'"

local lab: variable label  RTA_k2
     label var rta_k2  "`lab'"


cap local lab: variable label  RTA_k3
cap  label var rta_k3  "`lab'"

label var rta "RTA"

********************************************************************************
* generate International Border interacted with time

cap drop decade
gen 	decade = 1980 if year <= 1989
replace decade = 1990 if year <= 1999 & decade == .
replace decade = 2000 if year <= 2009 & decade == .
replace decade = 2010 if year <= 2019 & decade == .
 
 
 
 
 
gen  INTL_BRDR = (iso_o != iso_d)
 cap drop  INTL_BRDR_*
 foreach decade in 1980  1990  2000      {
generate INTL_BRDR_`decade'  = 1 if iso_o != iso_d & decade == `decade'
replace  INTL_BRDR_`decade'  = 0 if INTL_BRDR_`decade' == .
}

egen ij = group(iso_o iso_d)

********************************************************************************

if "$year_intervals" =="yes" {
	
 display "set year interval"
	
}



********************************************************************************

ppml_panel_sg $trade_frictions  		rta_k*				  rta_out	INTL_BRDR_*  		, ex(iso_o) 	 im(iso_d) 		year(year)    genD(gamma_ij_alt)  predict(y_hat)  cluster(ij)    
outreg2 using "$RES\Structural_Gravity.xls",   dec(3) keep(rta_k* rta				  rta_out	INTL_BRDR_* ) addtext(Period, Full, Dependent, $trade_frictions  ) lab    

********************************************************************************

do "$PROG\1_ge_simulations\define_beta_k3.do"

********************************************************************************


replace gamma_ij_alt 	= . if gamma_ij_alt == 0

gen epsilon 		 	= ($trade_frictions /y_hat)
 

generate check_exp		=exp(ln(gamma_ij_alt) +  ln(epsilon))

generate tij_bar		=(gamma_ij_alt)*(epsilon)

corr tij_bar check_exp
cap drop check_exp

replace  tij_bar        = gamma_ij_alt    if trade==0

cap drop gamma_ij_alt
gen     gamma_ij_alt 	= tij_bar 
*/


label data "This version  $S_TIME  $S_DATE "
save "$RES\GE_data_estibrated_MAN_level.dta", replace


********************************************************************************
********************************************************************************
* Esti-bration: Agro+Man
********************************************************************************
********************************************************************************
cd "$DATA\ge"

global trade_frictions 			"trade_am_i_hat_zero"
global trade        			"trade_am_i_hat_zero"
global select_dataset		    "est_sample_am_i_hat_zero"                 /* this ensures that the estimation dataset is rectangular by year on Manufacturing: with the assumption that when Prod < exports => domestic sales == 0 */
global set_zeros    		    "replace $trade = 0  if $trade == ."    


********************************************************************************

use "trade_wRTA_yearly.dta", clear
keep if $select_dataset == 1
$set_zeros

********************************************************************************
* generate RTA dummy

tab kmeanPP2 kmean
 
qui tab kmeanPP2, gen(RTA_k)
cap drop rta_k*

replace RTA_k1 		= 0                    if RTA_k1 == .
replace RTA_k2 		= 0                    if RTA_k2 == .
cap replace RTA_k3  = 0                    if RTA_k3 == .

gen rta_k1          = rta*RTA_k1
gen rta_k2          = rta*RTA_k2
cap  gen rta_k3     = rta*RTA_k3


local lab: variable label  RTA_k1
     label var rta_k1  "`lab'"

local lab: variable label  RTA_k2
     label var rta_k2  "`lab'"


cap local lab: variable label  RTA_k3
cap  label var rta_k3  "`lab'"

label var rta "RTA"

********************************************************************************
* generate International Border interacted with time

cap drop decade
gen 	decade = 1980 if year <= 1989
replace decade = 1990 if year <= 1999 & decade == .
replace decade = 2000 if year <= 2009 & decade == .
replace decade = 2010 if year <= 2019 & decade == .
 
 
 
 
 
gen  INTL_BRDR = (iso_o != iso_d)
 cap drop  INTL_BRDR_*
 foreach decade in 1980  1990  2000      {
generate INTL_BRDR_`decade'  = 1 if iso_o != iso_d & decade == `decade'
replace  INTL_BRDR_`decade'  = 0 if INTL_BRDR_`decade' == .
}

egen ij = group(iso_o iso_d)

********************************************************************************

if "$year_intervals" =="yes" {
	
 display "set year interval"
	
}



********************************************************************************


ppml_panel_sg $trade_frictions  		rta_k*				  rta_out	INTL_BRDR_*  		, ex(iso_o) 	 im(iso_d) 		year(year)    genD(gamma_ij_alt)  predict(y_hat)  cluster(ij)    
outreg2 using "$RES\Structural_Gravity.xls",   dec(3) keep(rta_k* rta				  rta_out	INTL_BRDR_* ) addtext(Period, Full, Dependent, $trade_frictions  ) lab    

********************************************************************************

do "$PROG\1_ge_simulations\define_beta_k3.do"

********************************************************************************


replace gamma_ij_alt 	= . if gamma_ij_alt == 0

gen epsilon 		 	= ($trade_frictions /y_hat)
 

generate check_exp		=exp(ln(gamma_ij_alt) +  ln(epsilon))

generate tij_bar		=(gamma_ij_alt)*(epsilon)

corr tij_bar check_exp
cap drop check_exp

replace  tij_bar        = gamma_ij_alt    if trade==0

cap drop gamma_ij_alt
gen     gamma_ij_alt 	= tij_bar 
*/


label data "This version  $S_TIME  $S_DATE "
save "$RES\GE_data_estibrated_AM_level.dta", replace


********************************************************************************
********************************************************************************
* Esti-bration
********************************************************************************
********************************************************************************


global trade_frictions 			"trade_man_i_hat_sh"
global trade        			"trade_man_i_hat"
global select_dataset		    "est_sample_man_i_hat"                 /* this ensures that the estimation dataset is rectangular by year on Manufacturing: with the assumption that when Prod < exports => domestic sales == 0 */
global set_zeros    		    "replace $trade = 0  if $trade == ."    


use "trade_wRTA_yearly.dta", clear
keep if $select_dataset == 1
$set_zeros

bys iso_d year: egen tM = total($trade)
gen $trade_frictions    = $trade / tM

********************************************************************************
* generate RTA dummy

tab kmeanPP2 kmean
 
qui tab kmeanPP2, gen(RTA_k)
cap drop rta_k*

replace RTA_k1 		= 0                    if RTA_k1 == .
replace RTA_k2 		= 0                    if RTA_k2 == .
cap replace RTA_k3  = 0                    if RTA_k3 == .

gen rta_k1          = rta*RTA_k1
gen rta_k2          = rta*RTA_k2
cap  gen rta_k3     = rta*RTA_k3


local lab: variable label  RTA_k1
     label var rta_k1  "`lab'"

local lab: variable label  RTA_k2
     label var rta_k2  "`lab'"


cap local lab: variable label  RTA_k3
cap  label var rta_k3  "`lab'"

label var rta "RTA"

********************************************************************************
* generate International Border interacted with time

cap drop decade
gen 	decade = 1980 if year <= 1989
replace decade = 1990 if year <= 1999 & decade == .
replace decade = 2000 if year <= 2009 & decade == .
replace decade = 2010 if year <= 2019 & decade == .
 
 
 
 
 
gen  INTL_BRDR = (iso_o != iso_d)
 cap drop  INTL_BRDR_*
 foreach decade in 1980  1990  2000      {
generate INTL_BRDR_`decade'  = 1 if iso_o != iso_d & decade == `decade'
replace  INTL_BRDR_`decade'  = 0 if INTL_BRDR_`decade' == .
}

egen ij = group(iso_o iso_d)

********************************************************************************

if "$year_intervals" =="yes" {
	
 display "set year interval"
	
}



********************************************************************************

ppml_panel_sg $trade_frictions  		rta_k*				  rta_out	INTL_BRDR_*  		, ex(iso_o) 	 im(iso_d) 		year(year)    genD(gamma_ij_alt)  predict(y_hat)  cluster(ij)    
outreg2 using "$RES\Structural_Gravity.xls",   dec(3) keep(rta_k* rta				  rta_out	INTL_BRDR_* ) addtext(Period, Full, Dependent, $trade_frictions  ) lab    

********************************************************************************

do "$PROG\1_ge_simulations\define_beta_k3.do"

********************************************************************************


replace gamma_ij_alt 	= . if gamma_ij_alt == 0

gen epsilon 		 	= ($trade_frictions /y_hat)
 

generate check_exp		=exp(ln(gamma_ij_alt) +  ln(epsilon))

generate tij_bar		=(gamma_ij_alt)*(epsilon)

corr tij_bar check_exp
cap drop check_exp

replace  tij_bar        = gamma_ij_alt    if trade==0

cap drop gamma_ij_alt
gen     gamma_ij_alt 	= tij_bar 
*/


label data "This version  $S_TIME  $S_DATE "
save "$RES\GE_data_estibrated_MAN_cons.dta", replace


********************************************************************************
********************************************************************************
* Esti-bration: Agro+Man
********************************************************************************
********************************************************************************
cd "$DATA\ge"

global trade_frictions 			"trade_am_i_hat_sh"
global trade        			"trade_am_i_hat"
global select_dataset		    "est_sample_am_i_hat"                 /* this ensures that the estimation dataset is rectangular by year on Manufacturing: with the assumption that when Prod < exports => domestic sales == 0 */
global set_zeros    		    "replace $trade = 0  if $trade == ."    


********************************************************************************

use "trade_wRTA_yearly.dta", clear
keep if $select_dataset == 1
$set_zeros

bys iso_d year: egen tM = total($trade)
gen $trade_frictions    = $trade / tM

********************************************************************************
* generate RTA dummy

tab kmeanPP2 kmean
 
qui tab kmeanPP2, gen(RTA_k)
cap drop rta_k*

replace RTA_k1 		= 0                    if RTA_k1 == .
replace RTA_k2 		= 0                    if RTA_k2 == .
cap replace RTA_k3  = 0                    if RTA_k3 == .

gen rta_k1          = rta*RTA_k1
gen rta_k2          = rta*RTA_k2
cap  gen rta_k3     = rta*RTA_k3


local lab: variable label  RTA_k1
     label var rta_k1  "`lab'"

local lab: variable label  RTA_k2
     label var rta_k2  "`lab'"


cap local lab: variable label  RTA_k3
cap  label var rta_k3  "`lab'"

label var rta "RTA"

********************************************************************************
* generate International Border interacted with time

cap drop decade
gen 	decade = 1980 if year <= 1989
replace decade = 1990 if year <= 1999 & decade == .
replace decade = 2000 if year <= 2009 & decade == .
replace decade = 2010 if year <= 2019 & decade == .
 
 
 
 
 
gen  INTL_BRDR = (iso_o != iso_d)
 cap drop  INTL_BRDR_*
 foreach decade in 1980  1990  2000      {
generate INTL_BRDR_`decade'  = 1 if iso_o != iso_d & decade == `decade'
replace  INTL_BRDR_`decade'  = 0 if INTL_BRDR_`decade' == .
}

egen ij = group(iso_o iso_d)

********************************************************************************

if "$year_intervals" =="yes" {
	
 display "set year interval"
	
}



********************************************************************************

ppml_panel_sg $trade_frictions  		rta_k*				  rta_out	INTL_BRDR_*  		, ex(iso_o) 	 im(iso_d) 		year(year)    genD(gamma_ij_alt)  predict(y_hat)  cluster(ij)    
outreg2 using "$RES\Structural_Gravity.xls",   dec(3) keep(rta_k* rta				  rta_out	INTL_BRDR_* ) addtext(Period, Full, Dependent, $trade_frictions  ) lab    

********************************************************************************

do "$PROG\1_ge_simulations\define_beta_k3.do"

********************************************************************************


replace gamma_ij_alt 	= . if gamma_ij_alt == 0

gen epsilon 		 	= ($trade_frictions /y_hat)
 

generate check_exp		=exp(ln(gamma_ij_alt) +  ln(epsilon))

generate tij_bar		=(gamma_ij_alt)*(epsilon)

corr tij_bar check_exp
cap drop check_exp

replace  tij_bar        = gamma_ij_alt    if trade==0

cap drop gamma_ij_alt
gen     gamma_ij_alt 	= tij_bar 
*/


label data "This version  $S_TIME  $S_DATE "
save "$RES\GE_data_estibrated_AM_cons.dta", replace
}

}
********************************************************************************
********************************************************************************
********************************************************************************

