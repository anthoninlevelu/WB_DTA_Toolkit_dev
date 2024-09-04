local iso "$iso"


cap 	log close
capture log using "$LOG/2_rta_stats/RTAselect_gravity_$iso", text replace


********************************************************************************
********************************************************************************
********************************************************************************

use "$RES//`iso'//temp/trade_baci_cty", clear

rename t year

********************************************************************************
* Select exported products 

preserve
    
	keep if year >= $ldate_bg1
	
	keep if iso_o == "`iso'"
	
	collapse (sum) v , by(iso_o k year)
	keep if v >= 100

	bys 	k: keep if _n ==1
	keep 	k
	save 	"$RES//`iso'//temp/k_list_X", replace
restore


merge	m:1		k 	using 	"$RES//`iso'//temp/k_list_X"

keep 	if _m == 3
drop	_m


********************************************************************************
********************************************************************************
* Select sample for gravity estimation: using appropriate UN correspondance 
if "$baci_version" 	  == "BACI_HS02_V202401b" {
preserve
import excel "$DATA/class/HS2012-17-BEC5_08_Nov_2018.xlsx", sheet("HS12BEC5") firstrow clear
 keep HS6 BEC5EndUse BEC4ENDUSE BEC4INT BEC4CONS BEC4CAP
 destring BEC4INT , replace force
 destring BEC4CONS, replace force
 destring BEC4CAP , replace force 
 duplicates drop 
 save	"$TEMP/k_BEC4", replace

********************************************************************************
******************************************************************************** 

import excel "$DATA/class/HS 2012 to HS 2002 Correlation and conversion tables.xls", sheet("Conversion HS 2012-HS 2002") cellrange(C7:D5213) firstrow clear
rename HS2012 HS6
merge 1:1 HS6 using "$TEMP/k_BEC4"
keep if _m == 3
drop _m

rename HS2002 k
destring k, replace force
cap drop if k == .

collapse (mean) BEC4INT BEC4CONS BEC4CAP, by(k)

gen stade3 = "I" if ((BEC4INT + BEC4CAP) >  BEC4CONS )

keep stade3 k
save	"$TEMP/k_BEC", replace
restore
}

********************************************************************************
********************************************************************************


merge	m:1 	k			using 	"$TEMP/k_BEC"
drop if _m == 2
drop _m

preserve	
	keep if stade3 == "I"
	collapse (sum) v, by(iso_o iso_d year)
	compress
	save "$RES//`iso'//temp/est_sample_imrt_int_k", replace
restore

collapse (sum) v, by(iso_o iso_d year)
compress


save "$RES//`iso'//temp/est_sample_imrt", replace
	
********************************************************************************
********************************************************************************
* 1a) Inward MRT - all products

use "$RES//`iso'//temp/est_sample_imrt", replace


********************************************************************************
do 	"$PROG_rta_stat/p1b_square"
********************************************************************************

merge m:1 iso_o iso_d year using "$RES//`iso'//temp/gravity_temp"
drop if _m == 2
drop _m



cap drop i
cap drop j

egen i 	= group(iso_o)
egen j 	= group(iso_d)

egen it = group(iso_o year)
egen jt = group(iso_d year)


bys jt: egen tx = total(v)

gen v_sh            =    v / tx
gen ldist 			= ln( $dist )
gen lv              = ln(v)

********************************************************************************
********************************************************************************
* PPML value

preserve
	ppmlhdfe v   $covar  ,  absorb(   ppml_d_jt = jt ppml_d_it = it)  d maxiter(1000) acceleration(steep)

	replace   ppml_d_jt         =  exp(ppml_d_jt)
    drop if   ppml_d_jt         == .

	bys year: egen max_rca 		=  max(ppml_d_jt)
	gen		norm_IMRT           =  ppml_d_jt/max_rca
	
	
     replace norm_IMRT          =  .   if norm_IMRT <= 0.000001
     drop if norm_IMRT          == .
    
	keep if year >= $ldate_bg1
	
	collapse (mean)    norm_IMRT  , by(iso_d)
	rename iso_d iso3
	merge m:1 iso3 using "$DATA/cty/TP_FAO_cty_year", keepusing(iso3)
	keep	if _m == 3
	drop	_m 

	gsort	-norm
	gen		rank = _n
	drop	norm
	keep	if rank <= 30
	
	gen		estimation 	= "PPML value"
	gen		item	  	= "demand"
	save "$RES//`iso'//temp/norm_IMRT_ppml", replace
restore


********************************************************************************
********************************************************************************
* 1b) Inward MRT - intermediate products


use "$RES//`iso'//temp/est_sample_imrt_int_k", replace


********************************************************************************
do 	"$PROG_rta_stat/p1b_square"
********************************************************************************

merge m:1 iso_o iso_d year using "$RES//`iso'//temp/gravity_temp"
drop if _m == 2
drop _m



cap drop i
cap drop j

egen i 	= group(iso_o)
egen j 	= group(iso_d)

egen it = group(iso_o year)
egen jt = group(iso_d year)


bys jt: egen tx = total(v)

gen v_sh            =    v / tx
gen ldist 			= ln( $dist )
gen lv              = ln(v)

********************************************************************************
********************************************************************************
* PPML value

preserve
	ppmlhdfe v   $covar  ,  absorb(   ppml_d_jt = jt ppml_d_it = it)  d maxiter(1000) acceleration(steep)

	replace   ppml_d_jt           = exp(ppml_d_jt)
    drop if   ppml_d_jt           == .
	bys year: egen max_rca 		  = max(ppml_d_jt)
	          gen		norm_IMRT = ppml_d_jt/max_rca
	
	    replace norm_IMRT          =  .   if norm_IMRT <= 0.000001
       drop if norm_IMRT          == .

	keep if year >= $ldate_bg1
	
	collapse (mean)    norm_IMRT  , by(iso_d)
	rename iso_d iso3

	merge m:1 iso3 using "$DATA/cty/TP_FAO_cty_year", keepusing(iso3)
	keep	if _m == 3
	drop	_m 

	gsort	-norm
	gen		rank = _n
	drop	norm
	keep	if rank <= 30
	
	gen		estimation 	= "PPML value"
	gen		item	  	= "demand int good"
	save "$RES//`iso'//temp/norm_IMRT_int_ppml", replace
restore


********************************************************************************
********************************************************************************
* 2) CTY IMPORT SIDE:

use "$RES//`iso'//temp/trade_baci_cty", clear

rename t year


preserve

	keep if year >= $ldate_bg1


	keep if iso_d == "`iso'"
	
	collapse (sum) v , by(iso_d k  year)
  	keep if v >= 100
	
	bys 	k: keep if _n ==1
	keep 	k
	save 	"$RES//`iso'//temp/k_list_M", replace
restore


merge	m:1		k 	using 	"$RES//`iso'//temp/k_list_M"

keep 	if _m == 3
drop	_m

********************************************************************************
********************************************************************************
* Select sample for gravity estimation: using appropriate UN correspondance 
if "$baci_version" 	  == "BACI_HS02_V202401b" {
preserve
import excel "$DATA/class/HS2012-17-BEC5_08_Nov_2018.xlsx", sheet("HS12BEC5") firstrow clear
 keep HS6 BEC5EndUse BEC4ENDUSE BEC4INT BEC4CONS BEC4CAP
 destring BEC4INT , replace force
 destring BEC4CONS, replace force
 destring BEC4CAP , replace force 
 duplicates drop 
 save	"$TEMP/k_BEC4", replace

********************************************************************************
******************************************************************************** 

import excel "$DATA/class/HS 2012 to HS 2002 Correlation and conversion tables.xls", sheet("Conversion HS 2012-HS 2002") cellrange(C7:D5213) firstrow clear
rename HS2012 HS6
merge 1:1 HS6 using "$TEMP/k_BEC4"
keep if _m == 3
drop _m

rename HS2002 k
destring k, replace force
cap drop if k == .

collapse (mean) BEC4INT BEC4CONS BEC4CAP, by(k)

gen stade3 = "I" if ((BEC4INT + BEC4CAP) >  BEC4CONS )

keep stade3 k
save	"$TEMP/k_BEC", replace
restore
}

********************************************************************************
******************************************************************************** 

merge	m:1 	k			using 	"$TEMP/k_BEC"
drop if _m == 2
drop _m 


preserve	
	keep if stade3 == "I"
	collapse (sum) v, by(iso_o iso_d year)
	compress
	save "$RES//`iso'//temp/est_sample_omrt_int_k", replace
restore

collapse (sum) v, by(iso_o iso_d year)
compress

	save "$RES//`iso'//temp/est_sample_omrt", replace
	
********************************************************************************
********************************************************************************
* 1a) Inward MRT - all products

use "$RES//`iso'//temp/est_sample_omrt", replace


********************************************************************************
do 	"$PROG_rta_stat/p1b_square"
********************************************************************************


merge m:1 iso_o iso_d year using "$RES//`iso'//temp/gravity_temp" 
drop if _m == 2
drop _m



cap drop i
cap drop j

egen i 	= group(iso_o)
egen j 	= group(iso_d)

egen it = group(iso_o year)
egen jt = group(iso_d year)


bys jt: egen tx = total(v)

gen v_sh            =    v / tx
gen ldist 			= ln( $dist )
gen lv              = ln(v)

********************************************************************************
********************************************************************************
* PPML value

preserve
	ppmlhdfe v   $covar  ,  absorb(   ppml_d_jt = jt ppml_d_it = it)  d maxiter(1000) acceleration(steep)

	replace   ppml_d_it         = exp(ppml_d_it)
    drop if   ppml_d_it         == .

	bys year: egen max_rca 		= max(ppml_d_it)
	         gen  norm_IMRT     = ppml_d_it/max_rca
	
       replace norm_IMRT        =  .   if norm_IMRT <= 0.000001
       drop if norm_IMRT        == .

	keep if year >= $ldate_bg1
	
	collapse (mean)    norm_IMRT  , by(iso_o)
	rename iso_o iso3

	merge m:1 iso3 using "$DATA/cty/TP_FAO_cty_year", keepusing(iso3)
	keep	if _m == 3
	drop	_m 

	gsort	-norm
	gen		rank = _n
	drop	norm
	keep	if rank <= 30
	
	gen		estimation 	= "PPML value"
	gen		item	  	= "supply"
	save "$RES//`iso'//temp/norm_OMRT_ppml", replace
restore

********************************************************************************
********************************************************************************
* 1b) Inward MRT - intermediate products

use "$RES//`iso'//temp/est_sample_omrt_int_k", replace


********************************************************************************
do 	"$PROG_rta_stat/p1b_square"
********************************************************************************

merge m:1 iso_o iso_d year using "$RES//`iso'//temp/gravity_temp"
drop if _m == 2
drop _m



cap drop i
cap drop j

egen i 	= group(iso_o)
egen j 	= group(iso_d)

egen it = group(iso_o year)
egen jt = group(iso_d year)


bys jt: egen tx = total(v)

gen v_sh            =    v / tx
gen ldist 			= ln( $dist )
gen lv              = ln(v)

********************************************************************************
********************************************************************************
* PPML value

preserve
	ppmlhdfe v   $covar  ,  absorb(   ppml_d_jt = jt ppml_d_it = it)  d maxiter(1000) acceleration(steep)

	
	replace   ppml_d_it         = exp(ppml_d_it)
    drop if   ppml_d_it         == .

	bys year: egen max_rca 		= max(ppml_d_it)
	         gen  norm_IMRT     = ppml_d_it/max_rca
	
       replace norm_IMRT        =  .   if norm_IMRT <= 0.000001
       drop if norm_IMRT        == .
	
	keep if year 				>= $ldate_bg1
	
	collapse (mean)    norm_IMRT  , by(iso_o)
	rename iso_o iso3

	merge m:1 iso3 using "$DATA/cty/TP_FAO_cty_year", keepusing(iso3)
	keep	if _m == 3
	drop	_m 

	gsort	-norm
	
	gen		rank = _n
	drop	norm
	keep	if rank <= 30
	
	gen		estimation 	= "PPML value"
	gen		item	  	= "supply int good"
	save "$RES//`iso'//temp/norm_OMRT_int_ppml", replace
restore


********************************************************************************
********************************************************************************
********************************************************************************

* 3) Export a table of results

use 					"$RES//`iso'//temp/norm_IMRT_ppml", clear

append 	using 			"$RES//`iso'//temp/norm_IMRT_int_ppml"

append 	using 			"$RES//`iso'//temp/norm_OMRT_ppml"

append 	using 			"$RES//`iso'//temp/norm_OMRT_int_ppml"

merge	m:1 iso3	using	"$RES//`iso'//temp/temp_regio"
keep if _m == 3
drop	_m


rename iso3 iso_d

merge 	m:1 iso_d 	 using "$RES//`iso'//temp/RTA_cty", keepus(agreem $kmean_alg )
drop   	if _m == 2
drop 	  _m

sort item estimation rank

rename iso_d iso

save				"$RES//`iso'//RTA_to_sign.dta", replace

********************************************************************************
* Add market shares: 

use			"$RES//`iso'//RTA_to_sign.dta", clear
keep		iso
drop	if 	iso == "`iso'"
bys iso: 	keep if	_n == 1
save		"$RES//`iso'//temp/cty_in_RTA_to_sign.dta", replace

********************************************************************************
********************************************************************************

use "$RES//`iso'//temp/trade_baci_cty", clear

rename t year
keep if year >= $ldate_bg1

keep if iso_d == "`iso'"

collapse (sum) v, by(  iso_o iso_d year)
	 
bys year iso_d: egen 			M = total(v)
gen 	m_mkts_sh   =   v/M
	
collapse (mean) m_mkts_sh, by(iso_o)

rename 	iso_o iso
save	"$RES//`iso'//temp/mkt_sh_M.dta", replace


********************************************************************************
********************************************************************************

use "$RES//`iso'//temp/trade_baci_cty", clear

rename t year
keep if year >= $ldate_bg1

keep if iso_o == "`iso'"

collapse (sum) v, by(iso_o iso_d year)
	 
bys year iso_o: egen 			X = total(v)
gen 	x_mkts_sh   =   v/X
	
collapse (mean) x_mkts_sh, by(iso_d)
					
rename 	iso_d iso

merge 	1:1		iso 	using 		"$RES//`iso'//temp/mkt_sh_M.dta"

replace 	x_mkts_sh = 0 if _m == 2					
replace 	m_mkts_sh = 0 if _m == 1			
					
drop		_m

merge 	1:1		iso 	using 		"$RES//`iso'//temp/cty_in_RTA_to_sign.dta"
keep	if 	_m == 3					
drop		_m

save	"$RES//`iso'//temp/mkt_sh.dta", replace
					
********************************************************************************

use			"$RES//`iso'//RTA_to_sign.dta", clear
				
merge		m:1		iso	using 		"$RES//`iso'//temp/mkt_sh.dta"		
drop		_m
					
sort item estimation rank
save				"$RES//`iso'//RTA_to_sign.dta", replace
export excel using 	"$RES//`iso'//RTA_to_sign.xlsx", sheet("RTA to sign")  sheetreplace firstrow(variables) nolabel 
					
cap 	log close
					
********************************************************************************
********************************************************************************
