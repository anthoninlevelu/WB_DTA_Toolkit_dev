/******************************************************************************* 
	     Deep Trade Agreements Toolkit: Trade and Welfare Impacts 

Nadia Rocha, Gianluca Santoni, Giulio Vannelli 

                  	   this version: OCT 2022
				   
website: https://xxxxxxx.org/

when using the tool please cite:  
Fontagné, L., Rocha, N., Ruta, M., Santoni, G. (2022),
 The Economic Impact of Deepening Trade Agreements”, CESIfo working paper 9529.  

*******************************************************************************/
********************************************************************************
local iso "$iso"

********************************************************************************
********************************************************************************
* Esti-bration: Agro+Man
********************************************************************************
********************************************************************************
use "$BACI\gravity_wto", clear 

cap rename iso3_o iso_o 
cap rename iso3_d iso_d
cap rename t year

keep year iso_o iso_d wto_o wto_d
gen wto_od = wto_o*wto_d
duplicates drop 

compress
save 	"$RES\\`iso'\\temp\gravity_wto_temp", replace
 

********************************************************************************
********************************************************************************
local iso "UZB"
 
use $ge_dataset , clear

gen iso3 = iso_o


merge m:1 iso3 using "$GRAVITY_COV\\WBregio_toolkit.dta"  
drop if _m == 2
drop _m

rename region region_o

cap drop iso3

gen iso3 = iso_d


merge m:1 iso3 using "$GRAVITY_COV\\WBregio_toolkit.dta"
drop if _m == 2
drop _m

rename region region_d

********************************************************************************
********************************************************************************

merge 1:1 iso_o iso_d year using "$RES\\`iso'\\temp\gravity_wto_temp"
drop if _m == 2
drop _m 
********************************************************************************
********************************************************************************

* generate RTA dummy
cap drop rta_k*
cap drop RTA_k*
tab kmeanPP2 kmean
 
qui tab kmeanPP2, gen(RTA_k)


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
replace decade = 2010 if year <= 2020 & decade == .
 
 
 
cap drop INTL_BRDR
 
gen  INTL_BRDR = (iso_o != iso_d)
 cap drop  INTL_BRDR_*
 foreach decade in  1990  2000 2010      {
generate INTL_BRDR_`decade'  = 1 if iso_o != iso_d & decade == `decade'
replace  INTL_BRDR_`decade'  = 0 if INTL_BRDR_`decade' == .
}

cap drop ij
egen ij = group(iso_o iso_d)

********************************************************************************
********************************************************************************

*replace wto_od = 0 if rta    == 1 
 replace wto_od = 0 if wto_od == .

********************************************************************************
********************************************************************************

ppml_panel_sg $trade_frictions  		rta 				  rta_out	INTL_BRDR_*  		, ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)    
outreg2 using  "$RES\\`iso'\\Structural_Gravity.xls",   dec(3) keep(rta				  rta_out	INTL_BRDR_* ) addtext(Period, Full, Dependent, $trade_frictions  ) lab     replace

ppml_panel_sg $trade_frictions  		rta_k*				  rta_out	INTL_BRDR_*		, ex(iso_o) 	 im(iso_d) 		year(year)   $sym    genD(gamma_ij_alt)  predict(y_hat)  cluster(ij)    
outreg2 using  "$RES\\`iso'\\Structural_Gravity.xls",   dec(3) keep(rta_k*				  rta_out	INTL_BRDR_* ) addtext(Period, Full, Dependent, $trade_frictions  ) lab    


ppml_panel_sg $trade_frictions  		rta 				  rta_out	INTL_BRDR_*  	wto_od	, ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)    
outreg2 using  "$RES\\`iso'\\Structural_Gravity.xls",   dec(3) keep(rta 	rta_out wto_od	INTL_BRDR_* ) addtext(Period, Full, Dependent, $trade_frictions  ) lab    


ppml_panel_sg $trade_frictions  		rta_k*				  rta_out	INTL_BRDR_*		wto_od , ex(iso_o) 	 im(iso_d) 		year(year)   $sym    genD(gamma_ij_alt)  predict(y_hat)  cluster(ij)    
outreg2 using  "$RES\\`iso'\\Structural_Gravity.xls",   dec(3) keep(rta_k*	 rta_out wto_od	INTL_BRDR_* ) addtext(Period, Full, Dependent, $trade_frictions  ) lab    

********************************************************************************
********************************************************************************