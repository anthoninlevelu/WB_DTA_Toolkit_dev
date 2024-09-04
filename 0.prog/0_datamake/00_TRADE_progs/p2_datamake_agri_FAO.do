
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
gen isic3 = int(isicrevision3productcode/10)

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

// this is only ISIC 01 (Agricoltural goods): att there are 141 HS codes in ISIC 1 that are not included, so no possible to match total ISIC 01 exports from comtrade

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

keep if itemcode    == 1717 | itemcode == 1720 | itemcode == 1723 | itemcode == 1730 | itemcode == 1739 
   

   
   
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
* this block use FAO trade
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


gen     trade_agr = trade_m/(1 + $tc_agr )   
replace trade_agr = trade_x     						if trade_agr == .  & trade_x != .

drop trade_x
drop trade_m

drop if trade_agr == .
drop _m 


save "$TEMP/trade", replace

*******************************************************************************/
********************************************************************************
/* This block use comtrade  trade instead

use "$TEMP/temp_trade_comtrade", clear

keep if year >= $year_start
keep if year <= $year_end

keep year iso_o iso_d trade_agr

save "$TEMP/trade", replace

*******************************************************************************/
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

 
 replace trade_agr = 0 if trade_agr == .

 cap drop _m

save "$TEMP/trade_squared", replace

********************************************************************************
********************************************************************************
use "$TEMP/trade_squared", replace

collapse (sum) Xagr_comtrade =trade_agr, by(year iso_o  )

rename iso_o iso3
keep if year >= $year_start
keep if year <= $year_end
 

save "$TEMP/X", replace

********************************************************************************
********************************************************************************

use "$TEMP/prod", clear

cap rename prod prod_agr

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
 
 
replace Xagr_comtrade 	 = . 							if 		Xagr_comtrade   == 0
replace prod_agr		 = . 							if 		prod_agr 		== 0

gen 	intflow_agr	     = prod_agr		- (Xagr_comtrade )
replace prod_agr   	     = . 					        if intflow_agr          <= 0   // set missing in production values if implied domestic sales are negative
replace intflow_agr	 	 = . 					        if intflow_agr          <= 0
 
********************************************************************************
********************************************************************************	   
	   
keep year iso3 prod* X* intflow*



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
* Only Linear Interpolation of Produciton and Trade


bys iso3: mipolate prod_agr			    year   , linear  gen(prod_agr_i)
bys iso3: mipolate Xagr_comtrade 		year   , linear  gen(Xagr_comtrade_i)
 
 
cap drop  INT*
gen      INT_flows_agr_i                   = prod_agr_i   		- Xagr_comtrade_i
replace  INT_flows_agr_i                   = .                                         if INT_flows_agr_i   	<= 0
 
bys iso3: mipolate INT_flows_agr_i		  year   , linear  gen(INT_flows_agr_ii)
		  replace  INT_flows_agr_ii        = INT_flows_agr_i                           if INT_flows_agr_i 		!= .
 
					

keep year iso3 INT_flow*  intflo*
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


gen trade_agr_i 	     = trade_agr
gen trade_agr_ii 	     = trade_agr


replace trade_agr 	     = intflow_agr   		        if iso_o == iso_d
replace trade_agr_i	     = INT_flows_agr_i		        if iso_o == iso_d
replace trade_agr_ii     = INT_flows_agr_ii		        if iso_o == iso_d

 
replace trade_agr        = 0		                    if iso_o != iso_d & trade_agr     == .
replace trade_agr_i      = 0		                    if iso_o != iso_d & trade_agr_i   == .
replace trade_agr_ii     = 0		                    if iso_o != iso_d & trade_agr_ii  == .


********************************************************************************
********************************************************************************
/* ATT: already expressed in Thousand US$  as manufacturing trade  (FAO stat 1000US$)	  */
********************************************************************************
********************************************************************************


replace trade_agr    	  = trade_agr 		    /1
replace trade_agr_i	 	  = trade_agr_i		    /1
replace trade_agr_ii	  = trade_agr_ii		/1
 
 
keep year iso_o iso_d trade_*

  
compress

label data "This version  $S_TIME  $S_DATE "
save		"$TEMP/AGR_trade_prod_toolkit", replace

********************************************************************************
********************************************************************************
use		"$TEMP/AGR_trade_prod_toolkit", clear



foreach var in agr  agr_i  agr_ii   {

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
save		"$TEMP/AGR_trade_prod_toolkit", replace



********************************************************************************
* double check country iso3 codes
use		"$TEMP/AGR_trade_prod_toolkit", clear

    keep	iso_o
	bys iso_o: keep if _n == 1
 merge 1:1 iso_o using 	"$TEMP/TP_cty"

********************************************************************************
********************************************************************************

use		"$TEMP/AGR_trade_prod_toolkit", clear


merge 1:1 iso_o iso_d year using "$TEMP/MAN_trade_toolkit"
drop _merge




* double check with the GE procedure as it may create issues
drop if   iso_o =="BMU"  
drop if   iso_d =="BMU"  
 



label data "This version  $S_TIME  $S_DATE "
save "$TEMP/AGR_MAN_trade_prod_toolkit", replace

********************************************************************************
********************************************************************************

use  "$TEMP/AGR_MAN_trade_prod_toolkit", clear

foreach var in  agr  agr_i  agr_ii  man    man_i  man_ii min  min_i  min_ii {
	
rename trade_`var' 	`var'
	
}


order es_*, last
  
gen iso3 = iso_o

merge m:1 iso3 year using "$TEMP/temp_gdp"
drop if _m == 2
drop _m 
drop iso3 

*	version 3 2024:   using GDP Ratios

	replace 	     gdp_wb  = . 			            if iso_o != iso_d 
	 gen         x_vagg      = gdp_wb                   if iso_o == iso_d
bys iso_o year: egen  GDP    = total(x_vagg)
	   replace        GDP    = .                        if GDP   == 0


	
*	version 1 2024   using Production Ratio (Manuf to Agro/Min ) 
         gen     y_man       = man_i                    if iso_o == iso_d
         gen     y_min       = min_i                    if iso_o == iso_d
         gen     y_agr       = agr_i                    if iso_o == iso_d
  
	
bys iso_o year: egen  Yman   = total(y_man)
bys iso_o year: egen  Yagr   = total(y_agr )
bys iso_o year: egen  Ymin   = total(y_min)


       replace        Yman   = .                        if Yman  == 0
       replace        Ymin   = .                        if Ymin  == 0
       replace        Yagr   = .                        if Yagr  == 0



	
*	version 2 2024   using Export     Ratio (Manuf to Agro/Min ) 
         gen     x_man       = man_i                    if iso_o != iso_d
         gen     x_min       = min_i                    if iso_o != iso_d
         gen     x_agro      = agr_i                    if iso_o != iso_d 
	   
	
bys iso_o year: egen  Xman   = total(x_man)
bys iso_o year: egen  Xagr   = total(x_agr )
bys iso_o year: egen  Xmin   = total(x_min)


       replace        Xman   = .                        if Xman  == 0
       replace        Xmin   = .                        if Xmin  == 0
       replace        Xagr   = .                        if Xagr  == 0
	
*	version 3 2024:   using Production to GDP Ratios
		gen agr_gdp_ratio    =  Yagr/GDP
		gen man_gdp_ratio    =  Yman/GDP
		gen min_gdp_ratio    =  Ymin/GDP
	
	   
*	version 1 2024   using Production Ratio (Manuf to Agro/Min ) 
	gen agr_manuf_ratioY     =  Yagr/Yman
	gen min_manuf_ratioY     =  Ymin/Yman

*	version 2 2024   using Export     Ratio (Manuf to Agro/Min ) 
	gen agr_manuf_ratioX     =  Xagr/Xman
	gen min_manuf_ratioX     =  Xmin/Xman



sort iso_o   year
bys  iso_o: carryforward  agr_manuf_ratioY    , gen(agr_manuf_ratioY_i)
bys  iso_o: carryforward  agr_manuf_ratioX    , gen(agr_manuf_ratioX_i)
bys  iso_o: carryforward  min_manuf_ratioY    , gen(min_manuf_ratioY_i)
bys  iso_o: carryforward  min_manuf_ratioX    , gen(min_manuf_ratioX_i)

sort iso_o   year
bys  iso_o: carryforward  agr_gdp_ratio      , gen(agr_gdp_ratio_i)
bys  iso_o: carryforward  man_gdp_ratio      , gen(man_gdp_ratio_i)
bys  iso_o: carryforward  min_gdp_ratio      , gen(min_gdp_ratio_i)




gsort iso_o   -year
bys  iso_o: carryforward  agr_manuf_ratioY_i    , replace
bys  iso_o: carryforward  agr_manuf_ratioX_i    , replace
bys  iso_o: carryforward  min_manuf_ratioY_i    , replace
bys  iso_o: carryforward  min_manuf_ratioX_i    , replace

gsort iso_o   -year
bys  iso_o: carryforward  agr_gdp_ratio_i      , replace
bys  iso_o: carryforward  man_gdp_ratio_i      , replace
bys  iso_o: carryforward  min_gdp_ratio_i      , replace


gen    man_iy              = man_i
gen    man_iyl             = man_i
gen    man_ix              = man_i
gen    man_igdp            = man_i

gen    agr_iy              = agr_i
gen    agr_iyl             = agr_i
gen    agr_ix              = agr_i
gen    agr_igdp            = agr_i

gen    min_iy              = min_i
gen    min_iyl             = min_i
gen    min_ix              = min_i
gen    min_igdp            = min_i

       replace 	agr_iy     = man_iy*agr_manuf_ratioY_i         if (iso_o == iso_d) &  man_iy    != .   & agr_iy    == .
       replace 	min_iy     = man_iy*min_manuf_ratioY_i         if (iso_o == iso_d) &  man_iy    != .   & min_iy    == .	   
       replace 	man_iy     = agr_iy*(1/agr_manuf_ratioY_i)     if (iso_o == iso_d) &  agr_iy    != .   & man_iy    == .

       replace 	agr_iyl    = man_iyl*agr_manuf_ratioY_i         if (iso_o == iso_d) &  agr_iyl   == .
       replace 	min_iyl    = man_iyl*min_manuf_ratioY_i         if (iso_o == iso_d) &  min_iyl   == .	   
       replace 	man_iyl    = agr_iyl*(1/agr_manuf_ratioY_i)     if (iso_o == iso_d) &  man_iyl   == .
   
	   
	   replace 	agr_ix     = Xman  *agr_manuf_ratioX_i         if (iso_o == iso_d) &  man_ix    != .   & agr_ix    == .
       replace 	min_ix     = Xman  *min_manuf_ratioX_i         if (iso_o == iso_d) &  man_ix    != .   & min_ix    == .	   
       replace 	man_ix     = Xagr  *(1/agr_manuf_ratioX_i)     if (iso_o == iso_d) &  agr_ix    != .   & man_ix    == .
   	   
       replace 	agr_igdp   = GDP*agr_gdp_ratio_i               if (iso_o == iso_d) &  agr_igdp  == .   & GDP       != .
       replace 	min_igdp   = GDP*min_gdp_ratio_i               if (iso_o == iso_d) &  min_igdp  == .   & GDP       != .
       replace 	man_igdp   = GDP*man_gdp_ratio_i               if (iso_o == iso_d) &  man_igdp  == .   & GDP       != .

	   
	   
	   


cap drop x_*
cap drop y_*
cap drop X*
cap drop Y*

cap drop X*
cap drop gdp_wb
	   
cap drop agr_manuf_rati*
cap drop min_manuf_rati*
cap drop *_gdp_rat*
cap drop GDP




foreach var in man agr       {
foreach cat in igdp  iy  iyl   {

cap drop es_`cat'_`var' 
gen xx   	= `var'_`cat'  if iso_o== iso_d

replace xx 	= -1 	 if iso_o== iso_d & xx == . 


bys iso_o  year: egen min_o   = min(xx)
bys iso_o  year: egen tX_o    = total( `var'_`cat' )

bys iso_d  year: egen min_d   = min(xx)
bys iso_d  year: egen tX_d    = total( `var'_`cat' )



gen es_`cat'_`var' = (min_o == - 1 | min_d == - 1 ) 

cap drop min*
cap drop tX*
cap drop xx

replace es_`cat'_`var' = 1 - es_`cat'_`var'

}
}


compress
label data "This version  $S_TIME  $S_DATE "
save "$TEMP/AGR_MAN_trade_prod_toolkit_V2024", replace
	   
********************************************************************************	   
********************************************************************************

use  "$TEMP/AGR_MAN_trade_prod_toolkit_V2024", clear


	keep	iso_o  
	bys 	iso_o  : keep if _n == 1
	gen iso_d = iso_o
		
save "$DATA/cty/TP_FAO_cty", replace


use  "$TEMP/AGR_MAN_trade_prod_toolkit_V2024", clear
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