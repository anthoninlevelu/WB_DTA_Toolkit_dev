
********************************************************************************
********************************************************************************

cap 	log close
capture log using "$PROG\log_files\datamake_COMTRADE", text replace


********************************************************************************
********************************************************************************
*   build TP for Manufacturing only: UNIDO + COMTRADE
cd "$COMTRADE"

qui unzipfile "sitc_import_2digit_isic_group", replace
use "sitc_import_2digit_isic_group.dta", clear 


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



collapse (sum) import_decl = tradevalueus, by(iso_o iso_d year)
  

drop if  iso_o==iso_d

collapse (sum) import_decl, by(iso_o iso_d year)


save "$TEMP/temp_trade_import_declarations", replace
cap erase sitc_import_2digit_isic_group.dta

********************************************************************************
********************************************************************************

qui unzipfile "sitc_export_2digit_isic_group", replace

use "sitc_export_2digit_isic_group.dta", clear 


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


collapse (sum) export_decl = tradevalueus, by(iso_o iso_d year)
 

drop if  iso_o==iso_d

collapse (sum) export_decl, by(iso_o iso_d year)

merge 1:1 iso_o iso_d year using "$TEMP/temp_trade_import_declarations"



gen 	   trade  = import_decl/(1 + $transport_cost )   
replace   trade   = export_decl     if trade == .  &  export_decl != .
 


collapse (sum) trade, by(iso_o iso_d year)


drop if iso_d == "SCG" & year > 2005
drop if iso_o == "SCG" & year > 2005


drop if iso_d == "SRB" & year <= 2005
drop if iso_o == "SRB" & year <= 2005

drop if iso_d == "MNE" & year <= 2005
drop if iso_o == "MNE" & year <= 2005

save "$TEMP/temp_trade_comtrade", replace

********************************************************************************
********************************************************************************


unique iso_o   // 167*167
unique iso_d

cap erase sitc_export_2digit_isic_group.dta


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


cd "$UNIDO"

use "indstat2_IND.dta" , clear   /* use the raw INDSTAT data: computed from TradeProd */
keep if isic =="D"

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


collapse (sum) prod = valuey , by(iso3 year country)




********************************************************************************
* add 2021 & 2022: will be extrapolated

preserve
keep if year == 2020
replace year = 2021
save "$TEMP/unido2021append", replace
restore

preserve
keep if year == 2020
replace year =  2022
save "$TEMP/unido2022append", replace
restore


append using "$TEMP/unido2021append",
append using "$TEMP/unido2022append",
replace prod = . if year == 2022 | year == 2021

********************************************************************************
********************************************************************************
 

collapse (sum) prod, by(iso3 year)
replace prod = . if prod == 0



keep if year >= $year_start
keep if year <= $year_end

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



keep if year >= $year_start
keep if year <= $year_end

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


collapse (sum) X_comtrade =trade, by(year iso_o)

rename iso_o iso3

save "$TEMP/X", replace
unique iso3   // 167 lost Somalia and liberia 
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
 

replace X_comtrade  = . 		            if 		X_comtrade 	 == 0
replace prod        = . 		            if 		prod 		 == 0 
 
 
gen 	Y_unido     = prod



gen 	intflow   	= Y_unido		- (X_comtrade)
replace Y_unido 	= . 					if intflow <= 0
replace intflow 	= . 					if intflow <= 0


/*******************************************************************************

gen  non_miss       = (intflow != .)
egen time           =nvals(year)
 
bys iso3: egen cty_stay =  total(non_miss)
	   replace cty_stay = cty_stay/time

summ cty_stay if cty_stay > 0 ,  d
replace Y_unido    	= . 					if cty_stay <= r(p1)
replace intflow	 	= . 					if cty_stay <= r(p1)


*******************************************************************************/	 

keep year iso3 Y_unido X_comtrade intflow


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
* Merge PWT indicators

merge m:1 iso3 year using "$TEMP/temp_gdp"
drop if _m == 2
drop _m


********************************************************************************
********************************************************************************
gen lgdp            = ln(gdp_wb)


bys iso3: mipolate Y_unido		   		year   , linear  gen(Y_unido_i)
bys iso3: mipolate X_comtrade   		year   , linear  gen(X_comtrade_i)
bys iso3: mipolate intflow   			year   , linear  gen(intflow_i)
bys iso3: mipolate gdp_wb		   		year   , linear  gen(gdp_wb_i)

 

********************************************************************************
********************************************************************************

gen share_prod_va     = Y_unido_i/X_comtrade_i
summ 	share_prod_va, d
scalar max = r(p99)
scalar min = r(p1)

replace share_prod_va = .            if share_prod_va > max & share_prod_va != .
replace share_prod_va = .            if share_prod_va < min & share_prod_va != .
cap drop max
cap drop min


sort iso3 year
bys iso3: carryforward  share_prod_va, replace

gsort iso3 -year
bys iso3: carryforward  share_prod_va, replace


gen Y_unido_i_hat 	  = share_prod_va*X_comtrade_i



********************************************************************************
********************************************************************************
gen share_dom_va      = intflow_i/X_comtrade_i

summ 	share_dom_va, d
scalar max = r(p99)
scalar min = r(p1)

replace share_dom_va = .            if share_dom_va > max & share_prod_va != .
replace share_dom_va = .            if share_dom_va < min & share_prod_va != .

cap drop max
cap drop min



sort iso3 year
bys iso3: carryforward  share_dom_va, replace

gsort iso3 -year
bys iso3: carryforward  share_dom_va, replace


gen intflow_hat 	  = share_dom_va*X_comtrade_i


********************************************************************************
********************************************************************************

cap drop  INT*
gen      INT_flows                  = Y_unido   		- X_comtrade_i
replace  INT_flows                  = .                                         if INT_flows 			<= 0

gen      INT_flows_i                = Y_unido_i 		- X_comtrade_i 
replace  INT_flows_i                = .                                         if INT_flows_i  		<= 0

gen      INT_flows_i_hat            = Y_unido_i_hat 	- X_comtrade_i 
replace  INT_flows_i_hat            = .                                         if INT_flows_i_hat  	<= 0


replace INT_flows_i                 = INT_flows                                 if INT_flows 		!= .
replace INT_flows_i_hat		        = INT_flows_i                               if INT_flows_i 		!= .

********************************************************************************
********************************************************************************
* use world average (by region income) for te remaining missing domestic sales
 
   gen iso_o = iso3    // iso_o is the original identifier
   
    
   
replace iso3 = "ROM"       if iso3  == "ROU"
replace iso3 = "WBG"       if iso3  == "PSE"
replace iso3 = "SRB"       if iso3  == "YUG" 
replace iso3 = "SRB"       if iso3  == "SCG" 
replace iso3 = "RUS"       if iso3  == "SUN" 
replace iso3 = "CZE"       if iso3  == "CSK" 
********************************************************************************
********************************************************************************

merge m:1 iso3 using "$DATA/CTY/WBregio.dta" 
drop if _m ==2
drop _m

********************************************************************************

rename iso3 country
 
replace country = "ROM"  if country =="ROU"
replace country = "PAL"  if country =="WBG"
replace country = "YUG"  if country =="SRB"

merge m:1 country using "$DATA/CTY/income_class_2018.dta" 
drop if _m ==2
drop _m

cap drop country 
rename iso_o iso3    // iso_o is the original identifier

********************************************************************************
********************************************************************************
cap drop region_income

replace income = "L" if income_group == "LM"

egen region_income = group(region income_group)

********************************************************************************
********************************************************************************

bys year region_income: egen    avg    				= mean(share_prod_va)
 
					    gen Y_unido_i_avg 	  		= avg*X_comtrade_i
			
						
					gen      INT_flows_i_avg        = Y_unido_i_avg - X_comtrade_i
					replace  INT_flows_i_avg        = .		                    if INT_flows_i_avg  	<= 0
					replace  INT_flows_i_avg		= INT_flows_i_hat           if INT_flows_i_hat 		!= .

					cap drop avg
					
********************************************************************************
********************************************************************************
 
bys year region_income: egen    avg    				= mean(share_dom_va)
 
					    gen  intflow_hat_avg 	  	= avg*X_comtrade_i
					replace  intflow_hat_avg		= intflow_hat           	if intflow_hat 		!= .

					cap drop avg


********************************************************************************


bys iso3: mipolate INT_flows		   		year   , linear  gen(xx_lin)
		  replace  INT_flows               = xx_lin                                    if INT_flows 		    == .
			cap 	drop 			         xx_lin

bys iso3: mipolate INT_flows_i		   		year   , linear  gen(xx_lin)
		  replace  INT_flows_i             = xx_lin                                    if INT_flows_i 		    == .
			cap 	drop 			         xx_lin

bys iso3: mipolate INT_flows_i_hat			year   , linear  gen(xx_lin)
		  replace  INT_flows_i_hat         = xx_lin                                    if INT_flows_i_hat 	    == .
			cap 	drop 			         xx_lin
 
bys iso3: mipolate INT_flows_i_avg			year   , linear  gen(xx_lin)
		  replace  INT_flows_i_avg         = xx_lin                                    if INT_flows_i_hat 	    == .
			cap 	drop 			         xx_lin

********************************************************************************
********************************************************************************			
			 
bys iso3: mipolate intflow_hat    			year   , linear  gen(xx_lin)
		  replace  intflow_hat             = xx_lin                                    if intflow_hat 	       == .
			cap 	drop 			         xx_lin

 
bys iso3: mipolate intflow_hat_avg			year   , linear  gen(xx_lin)
		  replace  intflow_hat_avg         = xx_lin                                    if intflow_hat_avg 	    == .
			cap 	drop 			         xx_lin


********************************************************************************
********************************************************************************			
					
			gen    INT_flows_i_avg_zero	   = INT_flows_i_avg
		  replace  INT_flows_i_avg_zero    = 0                                   if ( X_comtrade_i == 0 | X_comtrade_i == . )  &  (INT_flows_i_avg_zero == .)			
			

keep year iso3 INT_flow* intflow_hat*



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

save "$TEMP\temp_trade_final", replace

********************************************************************************
********************************************************************************


merge m:1 year iso_o using "$TEMP/inflows_filled"
drop if _m==2
drop _m

rename trade v


gen v_i 			     = v
gen v_i_hat 		     = v
gen v_i_avg 		     = v
gen v_i_avg_zero         = v 

gen v_hat_sales          = v 
gen v_avg_sales          = v 
 
replace v       	     = INT_flows 			        if iso_o == iso_d
replace v_i       	     = INT_flows_i 			        if iso_o == iso_d
replace v_i_hat          = INT_flows_i_hat 		        if iso_o == iso_d
replace v_i_avg          = INT_flows_i_avg 		        if iso_o == iso_d
replace v_i_avg_zero     = INT_flows_i_avg_zero 		if iso_o == iso_d

replace v_hat_sales      = intflow_hat			 		if iso_o == iso_d
replace v_avg_sales      = intflow_hat_avg		 		if iso_o == iso_d



 

********************************************************************************
/* ATT: express in Millions US$ */
********************************************************************************

replace v  	 		 	  = v 				    /1000000
replace v_i  	 		  = v_i				    /1000000
replace v_i_hat  	 	  = v_i_hat			    /1000000
replace v_i_avg      	  = v_i_avg	    		/1000000
replace v_i_avg_zero  	  = v_i_avg_zero	    /1000000
 
replace v_hat_sales  	  = v_hat_sales	    	/1000000
replace v_avg_sales  	  = v_avg_sales	    	/1000000

 
keep year iso_o iso_d v*


replace v       	     = 0		                    if iso_o != iso_d & v 			 == .
replace v_i       	     = 0 		                    if iso_o != iso_d & v_i 		 == .
replace v_i_hat          = 0 		                    if iso_o != iso_d & v_i_hat 	 == .
replace v_i_avg          = 0 		                    if iso_o != iso_d & v_i_avg 	 == .
replace v_i_avg_zero     = 0 		                    if iso_o != iso_d & v_i_avg_zero == .

 
replace v_hat_sales      = 0 		                    if iso_o != iso_d & v_hat_sales  == .
replace v_avg_sales      = 0 		                    if iso_o != iso_d & v_avg_sales  == .

save		"$DATA/MAN_trade_toolkit", replace



********************************************************************************
********************************************************************************
* Crea cty_list per TP
********************************************************************************
********************************************************************************

use		"$DATA/MAN_trade_toolkit", clear


	keep	iso_o  
	bys 	iso_o  : keep if _n == 1
	tab iso_o
save "$TEMP/TP_cty", replace
 

********************************************************************************
********************************************************************************
use		"$DATA/MAN_trade_toolkit", clear


foreach var in v_i v_i_hat v_i_avg v_i_avg_zero  v_avg_sales v_hat_sales {

cap drop est_sample_`var'
gen xx   	= `var'  if iso_o== iso_d
replace xx 	= -1 	 if iso_o== iso_d & xx == . 


bys iso_o  year: egen min_o   = min(xx)
bys iso_o  year: egen tX_o    = total(`var' )

bys iso_d  year: egen min_d   = min(xx)
bys iso_d  year: egen tX_d    = total(`var' )



gen est_sample_`var' = (min_o == - 1 | min_d == - 1 ) 

cap drop min*
cap drop tX*
cap drop xx

replace est_sample_`var' = 1 - est_sample_`var'

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
save		"$DATA/MAN_trade_toolkit", replace


tab year if iso_o == iso_d & est_sample_v_i			 == 1
tab year if iso_o == iso_d & est_sample_v_i_avg		 == 1 
tab year if iso_o == iso_d & est_sample_v_i_hat      == 1

cap log close
********************************************************************************
********************************************************************************
