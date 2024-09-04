
******************************************************************************** 
********************************************************************************

cap 	log close
capture log using "$PROG\00_log_files\p2_datamake_FAO", text replace


cd "$DATA/cty"


********************************************************************************
********************************************************************************
* this is from the manufacturing side
use "$TEMP/iso_matched", clear
 

merge 1:1 iso_o using "$TEMP/wb_country_name"
drop if _m == 2
drop _m

replace countryname = "Yugoslavia" if iso3 =="YUG"

save "$TEMP/cty_estimation", replace   // 167
unique iso3
*******************************************************************************/
********************************************************************************
* country name/code: this section was wrong

import delimited "$FAO_prod/FAOSTAT_data_3-26-2024_country.csv", clear


rename country 	countryname

cap rename ïcountrycode countrycode
cap rename countrycode  areacode
rename iso3code 			iso3

keep   areacode   iso3 countryname
  drop if areacode > 4999
  drop if areacode == 420
  drop if areacode == 429




replace iso3			   = "YUG"        if iso3      == "F248"
replace iso3			   = "SUN"        if iso3      == "F228"

replace iso3			   = "ETH"        if iso3      == "F62"
replace iso3               = "BEL"        if iso3      == "F15"

replace iso3			   = "CSK"        if iso3      == "F51"

replace iso3			   = "CHN.XXX"    if iso3      == "F351"

/*
areacode	countryname	iso3
351	China	F351
96	China, Hong Kong SAR	HKG
128	China, Macao SAR	MAC
41	China, mainland	CHN


 */

gen    cnum_o              = areacode
gen    cnum_d              = areacode

gen    iso_o			   = iso3
gen    iso_d			   = iso3



bys areacode: keep if _n == 1
drop if areacode == .



merge m:1 iso_o using  "$TEMP/cty_estimation", keepusing(iso_o)
keep if _m == 3
drop _m


preserve
keep areacode iso3 countryname
save "$TEMP\cty_stats", replace
restore

preserve
 
keep cnum_o cnum_d iso_o iso_d countryname
save "$TEMP\cty_stats_od", replace
restore
 

********************************************************************************
********************************************************************************
* 1) Production item


cd "$FAO_prod/"
unzipfile "Value_of_Production_E_All_Data.zip", replace
import delimited "Value_of_Production_E_All_Data_NOFLAG.csv", clear

keep if elementcode == 57    /*elementcode	element 57	Gross Production Value (current thousand US$)  */
							*itemcode	item_trade	item_prod	_merge 2051		Agriculture	Using only (2)
bys item: keep if _n == 1
keep itemcode item
rename item item_prod
save "$TEMP/item_prod", replace

********************************************************************************
********************************************************************************
* select ISIC Agricoltural perimeter 
import delimited "$DATA/FAO/JobID-48_Concordance_H3_to_I3.CSV", clear 

gen isic2 = int(isicrevision3productcode/100)

gen agro  = (isic2 ==  1 | isic2 == 2 | isic2 == 5 )
gen manuf = (isic2 >= 15 & isic2 <= 37)
*cap drop if agro == 0 & manuf == 0
keep hs2007productcode agro manuf isic2
rename hs2007productcode hs07code 
duplicates drop
/* isic rev 3

A - Agriculture, hunting and forestry 
01 - Agriculture, hunting and related service activities 
02 - Forestry, logging and related service activities 

B - Fishing 
05 - Fishing, operation of fish hatcheries and fish farms; service activities incidental to fishing 

 */
save "$TEMP/item_descr_hs07_agro", replace

********************************************************************************
********************************************************************************

import delimited "$FAO_trade/FAOSTAT_data_3-26-2024_item.csv", clear 
rename *temcode itemcode
save "$TEMP/item_descr_hs", replace


import delimited "$FAO_prod/FAOSTAT_data_3-26-2024_item_group.csv", encoding(UTF-8) clear 
keep itemcode item itemgroup itemgroupcode hs07code
duplicates drop
replace hs07code = "9999999" if hs07code ==""
split hs07code, parse(,)
cap drop hs07code
reshape long hs07code, i(itemgroupcode itemgroup itemcode item)
rename _j level
drop if hs07code == ""
save "$TEMP/item_descr_hs_select", replace

keep itemgroupcode itemgroup
duplicates drop
save "$TEMP/itemgroup_desc", replace

use "$TEMP/item_descr_hs_select", replace
recast str50 item, force
destring hs07code, replace

 
keep if itemgroupcode==1717 | itemgroupcode == 1720 | itemgroupcode == 1723 | itemgroupcode == 1730 | itemgroupcode == 1739 

merge m:1 hs07code using "$TEMP/item_descr_hs07_agro"
drop if _m == 2

// this is only ISIC 01 (Agricoltural goods!)

*  no manufacturing goods recorded here 
* 1717	Cereals, primary	1
* 1720	Roots and Tubers, Total	1
* 1723	Sugar Crops Primary	1
* 1730	Oilcrops Primary	1
* 1739	Vegetables and Fruit Primary	1


********************************************************************************
********************************************************************************
/*
itemgroupcode	itemgroup
1717	Cereals, primary
1720	Roots and Tubers, Total
1723	Sugar Crops Primary
1730	Oilcrops Primary
1739	Vegetables and Fruit Primary
1753	Fibre Crops Primary
1770	Meat indigenous, total
1780	Milk, Total
2041	Crops
2044	Livestock
2051	Agriculture
2054	Food
2057	Non Food

*/

use "$TEMP/item_descr_hs_select", replace

keep if itemgroupcode==1717 | itemgroupcode == 1720 | itemgroupcode == 1723 | itemgroupcode == 1730 | itemgroupcode == 1739 
keep itemgroupcode itemgroup itemcode
duplicates drop

save "$TEMP/item_production_no_manuf", replace

use "$TEMP/item_descr_hs_select", replace
keep if itemgroupcode == 2041 
keep itemgroupcode itemgroup itemcode
duplicates drop
save "$TEMP/item_crops_no_manuf", replace

use "$TEMP/item_descr_hs_select", replace
keep if  itemgroupcode == 2051  
keep itemgroupcode itemgroup itemcode
duplicates drop
save "$TEMP/item_agro_no_manuf", replace

********************************************************************************
********************************************************************************
* Seleziono gli item su cui sono costruiti Production e trade
cd "$FAO_prod/"

import delimited "Value_of_Production_E_All_Data_NOFLAG.csv", clear

keep if elementcode == 57      /*elementcode	element 57	Gross Production Value (current thousand US$)  */

keep if itemcode==1717 | itemcode == 1720 | itemcode == 1723 | itemcode == 1730 | itemcode == 1739 
   

   
   
collapse (sum) y*, by(areacode   area)

cap drop if areacode > 4999
cap drop if areacode == 420
cap drop if areacode == 429

reshape long y, i(areacode area) j(year)


merge m:1  areacode using "$TEMP/cty_stats" 
keep if _m == 3
drop _m


cap drop if y == .
cap drop if y == 0


unique iso3    // 157 countries here
********************************************************************************
********************************************************************************

replace iso3="SCG" if   ( iso3=="SRB"  & year  <= 2005 )   //  this is because in Comtrade 
replace iso3="YUG" if   ( iso3=="SCG"  & year  <= 1991 )   //  this is because in Comtrade 

replace iso3="SUN" if   ( iso3=="RUS"  & year  <= 1991 )
replace iso3="CSK" if    (iso3=="CZE" | iso3=="SVK") & year <= 1992



collapse (sum) y, by(iso3 year)


rename y prod

keep if year >= $year_start
keep if year <= $year_end


save "$TEMP/prod", replace
 
 

********************************************************************************
********************************************************************************
* 2.1) Clean Trade data: Import side

cd "$FAO_trade/"

unzipfile "Trade_DetailedTradeMatrix_E_All_Data.zip", replace
import delimited "Trade_DetailedTradeMatrix_E_All_Data_NOFLAG.csv", clear

keep if elementcode 	   == 5622   // elementcode	element	unit 5622	Import Value	1000 US$

merge m:1 itemcode using  "$TEMP/item_production_no_manuf"
keep if _m == 3
drop _m 

rename reportercountrycode cnum_d 
rename reportercountries   country_d 

rename partnercountrycode  cnum_o 
rename partnercountries    country_o

 keep country_d cnum_o cnum_d country_o itemcode y*
collapse (sum) y*, by(country_d cnum_o cnum_d country_o  )
reshape long y, i(country_d cnum_o cnum_d country_o  ) j(year)
 
********************************************************************************
********************************************************************************

cap drop if y == .
cap drop if y == 0


collapse (sum) y, by(country_d cnum_o cnum_d country_o year)


keep if year >= $year_start
keep if year <= $year_end

********************************************************************************
********************************************************************************
merge m:1 cnum_o using "$TEMP/cty_stats_od", keepusing(iso_o) 
keep if _m == 3
drop _m

********************************************************************************
merge m:1  cnum_d using "$TEMP/cty_stats_od", keepusing(iso_d)  
keep if _m == 3
drop _m

********************************************************************************

replace iso_o="SCG" if   ( iso_o=="SRB"  & year  <= 2005 )   //  this is because in Comtrade 
replace iso_o="YUG" if   ( iso_o=="SCG"  & year  <= 1991 )   //  this is because in Comtrade 

replace iso_o="SUN" if   ( iso_o=="RUS"  & year  <= 1991 )
replace iso_o="CSK" if    (iso_o=="CZE" | iso_o=="SVK") & year <= 1992

replace iso_d="SCG" if   ( iso_d=="SRB"  & year  <= 2005 )   //  this is because in Comtrade 
replace iso_d="YUG" if   ( iso_d=="SCG"  & year  <= 1991 )   //  this is because in Comtrade 

replace iso_d="SUN" if   ( iso_d=="RUS"  & year  <= 1991 )
replace iso_d="CSK" if    (iso_d=="CZE" | iso_d=="SVK") & year <= 1992

drop if  iso_o==iso_d


********************************************************************************

collapse (sum) y , by(iso_o iso_d year)


rename y trade_m

save "$TEMP/trade", replace

********************************************************************************
********************************************************************************
* complete with export declarations

import delimited "Trade_DetailedTradeMatrix_E_All_Data_NOFLAG.csv", clear

keep if elementcode 	   == 5922    /* elementcode	element	unit 5922	Export Value	1000 US$
 */

merge m:1 itemcode using  "$TEMP/item_production_no_manuf"
keep if _m == 3
drop _m 

rename reportercountrycode cnum_o 
rename reportercountries   country_o 

rename partnercountrycode  cnum_d 
rename partnercountries    country_d

 keep country_d cnum_o cnum_d country_o itemcode y*
collapse (sum) y*, by(country_d cnum_o cnum_d country_o  )
reshape long y, i(country_d cnum_o cnum_d country_o  ) j(year)

 
********************************************************************************
********************************************************************************

cap drop if y == .
cap drop if y == 0


collapse (sum) y, by(country_d cnum_o cnum_d country_o year)


keep if year >= $year_start
keep if year <= $year_end

********************************************************************************
********************************************************************************
merge m:1 cnum_o using "$TEMP/cty_stats_od", keepusing(iso_o) 
keep if _m == 3
drop _m

********************************************************************************
merge m:1  cnum_d using "$TEMP/cty_stats_od", keepusing(iso_d)  
keep if _m == 3
drop _m

********************************************************************************

replace iso_o="SCG" if   ( iso_o=="SRB"  & year  <= 2005 )   //  this is because in Comtrade 
replace iso_o="YUG" if   ( iso_o=="SCG"  & year  <= 1991 )   //  this is because in Comtrade 

replace iso_o="SUN" if   ( iso_o=="RUS"  & year  <= 1991 )
replace iso_o="CSK" if    (iso_o=="CZE" | iso_o=="SVK") & year <= 1992

replace iso_d="SCG" if   ( iso_d=="SRB"  & year  <= 2005 )   //  this is because in Comtrade 
replace iso_d="YUG" if   ( iso_d=="SCG"  & year  <= 1991 )   //  this is because in Comtrade 

replace iso_d="SUN" if   ( iso_d=="RUS"  & year  <= 1991 )
replace iso_d="CSK" if    (iso_d=="CZE" | iso_d=="SVK") & year <= 1992

drop if  iso_o==iso_d


********************************************************************************

collapse (sum) y , by(iso_o iso_d year)

rename y trade_x


merge 1:1 iso_o iso_d year using "$TEMP/trade"


gen     trade = trade_m/(1 + $transport_cost )   
replace trade = trade_x     						if trade == .  & trade_x != .

drop trade_x
drop trade_m

drop if trade == .
drop _m 

save "$TEMP/trade", replace

********************************************************************************
********************************************************************************


use "$TEMP/trade", clear

/* Square the dataset */
preserve
bys iso_o: keep if _n==1
keep iso_o
save "$TEMP/square", replace
restore

preserve
bys iso_d: keep if _n==1
keep iso_d
cross using "$TEMP/square"
save "$TEMP/square", replace
restore

preserve
bys year: keep if _n==1
keep year
cross using "$TEMP/square"
save "$TEMP/square", replace
restore


merge 1:1  iso_o iso_d year using "$TEMP/square", nogenerate
cap erase "$TEMP/square"

 
 replace trade = 0 if trade == .

 cap drop _m

save "$TEMP/trade_squared", replace

********************************************************************************
********************************************************************************
use "$TEMP/trade_squared", replace

collapse (sum) X =trade, by(year iso_o  )

rename iso_o iso3
keep if year >= $year_start
keep if year <= $year_end
 

save "$TEMP/X", replace
********************************************************************************
********************************************************************************

use "$TEMP/prod", clear

keep if year >= $year_start
keep if year <= $year_end

********************************************************************************
********************************************************************************

preserve
use "$TEMP/X", clear
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


merge 1:1 year iso3 using "$TEMP/X"
drop if _m == 2

drop _m 
 
 
replace X 	 = . 							if 		X 	 == 0
replace prod = . 							if 		prod == 0

gen 	intflow   	= prod		- (X )
replace prod    	= . 					if intflow <= 0
replace intflow	 	= . 					if intflow <= 0
 
********************************************************************************

gen  non_miss       = (intflow != .)
egen time           =nvals(year)
 
bys iso3: egen cty_stay =  total(non_miss)
	   replace cty_stay = cty_stay/time

summ cty_stay if cty_stay > 0 ,  d
replace prod    	= . 					if cty_stay <= r(p1)
replace intflow	 	= . 					if cty_stay <= r(p1)

********************************************************************************	   
	   
keep year iso3 prod X intflow



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
********************************************************************************
* Merge GDP
merge m:1 iso3 year using "$TEMP/temp_gdp"
drop if _m == 2
drop _m

cap drop iso_o
********************************************************************************
********************************************************************************
********************************************************************************

bys iso3: mipolate prod		   		    year   , linear  gen(prod_i)
bys iso3: mipolate X 			  		year   , linear  gen(X_i)
bys iso3: mipolate gdp_wb				year   , linear  gen(gdp_wb_i)
bys iso3: mipolate intflow   			year   , linear  gen(intflow_i)

********************************************************************************
********************************************************************************

gen share_prod_va     = prod_i/X_i
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


gen prod_i_hat 	  		= share_prod_va*X_i



********************************************************************************
********************************************************************************
gen share_dom_va      = intflow_i/X_i

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


gen intflow_hat 	  = share_dom_va*X_i


********************************************************************************
********************************************************************************
* Trade domestico
********************************************************************************
********************************************************************************


cap drop  INT*
gen      INT_flows                  = prod  		- X_i
replace  INT_flows                  = .                                         if INT_flows 			<= 0

gen      INT_flows_i                = prod_i 		- X_i 
replace  INT_flows_i                = .                                         if INT_flows_i  		<= 0

gen      INT_flows_i_hat            = prod_i_hat 	- X_i 
replace  INT_flows_i_hat            = .                                         if INT_flows_i_hat  	<= 0


replace INT_flows_i                 = INT_flows                                 if INT_flows 		!= .
replace INT_flows_i_hat		        = INT_flows_i                               if INT_flows_i 		!= .

********************************************************************************
********************************************************************************
* use world average (by region income) for the remaining missing domestic sales

   gen iso_o = iso3    // iso_o is the original identifier
   
    
replace iso3 = "ROM"       if iso3  == "ROU"
replace iso3 = "WBG"       if iso3  == "PSE"
replace iso3 = "SRB"       if iso3  == "YUG" 
replace iso3 = "SRB"       if iso3  == "SCG" 


********************************************************************************
********************************************************************************

merge m:1 iso3 using "$DATA/cty/WBregio.dta" 
drop if _m ==2
drop _m

********************************************************************************

rename iso3 country
 
replace country = "ROM"  if country =="ROU"
replace country = "PAL"  if country =="WBG"
replace country = "YUG"  if country =="SRB"

merge m:1 country using "$DATA/cty/income_class_2018.dta" 
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

					    gen prod_i_avg 	  			= avg*X_i
			
						
					gen      INT_flows_i_avg        = prod_i_avg - X_i
					replace  INT_flows_i_avg        = .		                    if INT_flows_i_avg  	<= 0
					replace  INT_flows_i_avg		= INT_flows_i_hat           if INT_flows_i_hat 		!= .

					cap drop avg
					
********************************************************************************
********************************************************************************
 
bys year region_income: egen    avg    				= mean(share_dom_va)


					    gen  intflow_hat_avg 	  	= avg*X_i
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

/* this assumption is maybe  too strong 			 */ 
			gen    INT_flows_i_avg_zero	   = INT_flows_i_avg
 		  replace  INT_flows_i_avg_zero    = 0                                   if ( X_i == 0 | X_i == . )	&  (INT_flows_i_avg_zero == .)
			
						

keep year iso3 INT_flow* intflow_hat*
rename iso3 iso_o
compress
save "$TEMP/inflows_filled_X", replace




********************************************************************************
********************************************************************************
* 4) Square the trade matrix as the production one


use "$TEMP/trade_squared.dta", clear


merge m:1 year    iso_o using "$TEMP/inflows_filled_X"
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

 

replace v       	     = 0		                    if iso_o != iso_d & v 			 == .
replace v_i       	     = 0 		                    if iso_o != iso_d & v_i 		 == .
replace v_i_hat          = 0 		                    if iso_o != iso_d & v_i_hat 	 == .
replace v_i_avg          = 0 		                    if iso_o != iso_d & v_i_avg 	 == .
replace v_i_avg_zero     = 0 		                    if iso_o != iso_d & v_i_avg_zero == .
 
replace v_hat_sales      = 0 		                    if iso_o != iso_d & v_hat_sales  == .
replace v_avg_sales      = 0 		                    if iso_o != iso_d & v_avg_sales  == .


********************************************************************************
********************************************************************************
/* ATT: express in Millions US$  as manufacturing trade 					  */
********************************************************************************
********************************************************************************


replace v  	 		 	  = v 				    /1000
replace v_i  	 		  = v_i				    /1000
replace v_i_hat  	 	  = v_i_hat			    /1000
replace v_i_avg  	 	  = v_i_avg			    /1000
replace v_i_avg_zero  	  = v_i_avg_zero	    /1000

replace v_hat_sales  	  = v_hat_sales	    	/1000
replace v_avg_sales  	  = v_avg_sales	    	/1000

  
 
 
keep year iso_o iso_d v*

compress

label data "This version  $S_TIME  $S_DATE "
save		"$DATA/AGR_trade_prod_toolkit", replace

********************************************************************************
********************************************************************************
use		"$DATA/AGR_trade_prod_toolkit", clear

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
save		"$DATA/AGR_trade_prod_toolkit", replace



********************************************************************************
* double check country iso3 codes
use		"$DATA/AGR_trade_prod_toolkit", clear

    keep	iso_o
	bys iso_o: keep if _n == 1
 merge 1:1 iso_o using 	"$TEMP/TP_cty"

********************************************************************************
********************************************************************************

use		"$DATA/AGR_trade_prod_toolkit", clear

 
  drop if   iso_o =="BMU"  
  drop if   iso_d =="BMU"  
  
  
foreach var in  i  i_hat  i_avg i_avg_zero hat_sales avg_sales    {

rename  v_`var' agro_`var'

}
cap rename v agro

cap drop est_sample_*

********************************************************************************
********************************************************************************
  
merge 1:1 iso_o iso_d year using "$DATA/MAN_trade_toolkit"
drop _merge
cap drop est_sample_*

********************************************************************************
foreach var in  i  i_hat  i_avg i_avg_zero hat_sales avg_sales   {

rename  v_`var' man_`var'

}
cap rename v man

********************************************************************************
  
label data "This version  $S_TIME  $S_DATE "
save "$DATA/AGR_MAN_trade_prod_toolkit", replace


********************************************************************************
********************************************************************************
use  "$DATA/AGR_MAN_trade_prod_toolkit", clear

foreach var in agro agro_i agro_i_hat agro_i_avg agro_i_avg_zero agro_hat_sales agro_avg_sales man man_i man_i_hat man_i_avg man_i_avg_zero man_hat_sales man_avg_sales {

cap drop es_`var'
gen xx   	= `var'  if iso_o== iso_d
replace xx 	= -1 	 if iso_o== iso_d & xx == . 


bys iso_o  year: egen min_o   = min(xx)
bys iso_o  year: egen tX_o    = total(`var' )

bys iso_d  year: egen min_d   = min(xx)
bys iso_d  year: egen tX_d    = total(`var' )



gen es_`var' = (min_o == - 1 | min_d == - 1 ) 

cap drop min*
cap drop tX*
cap drop xx

replace es_`var' = 1 - es_`var'

}

compress
label data "This version  $S_TIME  $S_DATE "
save "$DATA/AGR_MAN_trade_prod_toolkit_V2023", replace

********************************************************************************
********************************************************************************

use  "$DATA/AGR_MAN_trade_prod_toolkit", clear

sum man  man_*  if iso_o != iso_d
sum agro agro_* if iso_o != iso_d
 

keep year iso_o iso_d agro_i man_i  

foreach var in agro_i man_i {

cap drop es_`var'
gen xx   	= `var'  if iso_o== iso_d
replace xx 	= -1 	 if iso_o== iso_d & xx == . 


bys iso_o  year: egen min_o   = min(xx)
bys iso_o  year: egen tX_o    = total(`var' )

bys iso_d  year: egen min_d   = min(xx)
bys iso_d  year: egen tX_d    = total(`var' )



gen es_`var' = (min_o == - 1 | min_d == - 1 ) 

cap drop min*
cap drop tX*
cap drop xx

replace es_`var' = 1 - es_`var'

}

********************************************************************************

gen iso3 = iso_o

merge m:1 iso3 year using "$TEMP/temp_gdp"
drop if _m == 2
drop _m 

	replace 	     gdp_wb  = . 			if iso_o != iso_d 

********************************************************************************

         gen     x_man       = man_i        if iso_o == iso_d
         gen     x_agro      = agro_i       if iso_o == iso_d
         gen     x_vagg      = gdp_wb       if iso_o == iso_d

bys iso_o year: egen  Xman   = total(x_man)
bys iso_o year: egen  Xagro  = total(x_agro)
bys iso_o year: egen  GDP    = total(x_vagg)

       replace        Xman   = .                        if Xman  == 0
       replace        Xagro  = .                        if Xagro == 0
	   replace        GDP    = .                        if GDP   == 0

		gen agro_manuf_ratio =  Xagro/Xman
		gen agro_gdp_ratio   =  Xagro/GDP
		gen man_gdp_ratio    =  Xman/GDP

cap drop x_man
cap drop x_agro
cap drop Xman
cap drop Xagro
cap drop x_vagg
cap drop gdp_wb


sort iso_o   year
bys  iso_o: carryforward  agro_manuf_ratio, gen(agro_manuf_ratio_i)
bys  iso_o: carryforward  agro_gdp_ratio  , gen(agro_gdp_ratio_i)
bys  iso_o: carryforward  man_gdp_ratio   , gen(man_gdp_ratio_i)

gsort iso_o -year
bys   iso_o: carryforward  agro_manuf_ratio_i, replace
bys   iso_o: carryforward  agro_gdp_ratio_i  , replace
bys   iso_o: carryforward  man_gdp_ratio_i   , replace


gen    agro_ie             = agro_i
gen    man_ie              = man_i

gen    agro_igdp           = agro_i
gen    man_igdp            = man_i

       replace 	agro_ie    = man_ie*agro_manuf_ratio_i        if (iso_o == iso_d) &  man_ie   != .    & agro_ie   == .
       replace 	man_ie     = agro_ie*(1/agro_manuf_ratio_i)   if (iso_o == iso_d) &  man_ie   == .    & agro_ie   != .

       replace 	agro_igdp  = GDP*agro_gdp_ratio_i             if (iso_o == iso_d) &  man_igdp != .    & agro_igdp == .
       replace 	man_igdp   = GDP*man_gdp_ratio_i              if (iso_o == iso_d) &  man_igdp == .    & agro_igdp != .
  
	   
	   
	   
	   
cap drop agro_manuf_ratio_i
cap drop agro_manuf_ratio 

cap drop agro_gdp_ratio
cap drop man_gdp_ratio


cap drop agro_gdp_ratio_i 
cap drop man_gdp_ratio_i 

cap drop GDP

compress
label data "This version  $S_TIME  $S_DATE "
save "$DATA/AGR_MAN_trade_prod_toolkit_V2024", replace
	   
********************************************************************************	   
********************************************************************************

use  "$DATA/AGR_MAN_trade_prod_toolkit_V2024", clear


	keep	iso_o  
	bys 	iso_o  : keep if _n == 1
	gen iso_d = iso_o
		
save "$DATA/cty/TP_FAO_cty", replace


use  "$DATA/AGR_MAN_trade_prod_toolkit_V2024", clear
bys iso_o: egen min_year = min(year)
bys iso_o: egen max_year = max(year)
 

bys iso_o: keep if _n==1
keep iso_o min_year  max_year
rename iso_o iso3
save "$DATA/cty/TP_FAO_cty_year", replace

********************************************************************************
********************************************************************************
* clean directory
********************************************************************************
********************************************************************************
 
 cd "$FAO_prod" 


local files : dir "`c(pwd)'"  files "Value_of_Production*.csv" 
display `files'
foreach file in `files' { 
	erase `file'    
} 


cd "$FAO_trade" 


local files : dir "`c(pwd)'"  files "Trade_DetailedTradeMatrix*.csv" 

foreach file in `files' { 
	erase `file'    
} 


********************************************************************************
********************************************************************************