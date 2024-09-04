



cap 	log close
capture log using "$LOG/1_trade_stats/trade_stats_`=$iso'", text replace

di $z

 if   $z   	 == 0 {
	
wbopendata,  indicator(ny.gdp.mktp.cd) long clear  


drop if countrycode ==""
rename ny_gdp_mktp_cd gdp_wb
keep countrycode countryname year gdp_wb

drop if gdp == .

rename countrycode iso3 

keep year  iso3 gdp_wb countryname
replace iso3="SCG" if   ( iso3=="SRB"  & year  <= 2005 )   //  this is because in Comtrade 
replace iso3="YUG" if   ( iso3=="SCG"  & year  <= 1991 )   //  this is because in Comtrade 

replace iso3="SUN" if   ( iso3=="RUS"  & year  <= 1991 )
replace iso3="CSK" if    (iso3=="CZE" | iso3=="SVK") & year <= 1992

save "$CTY/WBdata_gdp.dta", replace

}
********************************************************************************

local iso     "$iso"




use "$CTY/WBdata_gdp.dta", clear
preserve
bys iso3: keep if _n == 1
keep iso3 countryname
rename iso3 iso_o
	save "$RES//`iso'//temp/wb_country_name", replace
restore


collapse (sum) gdp_wb, by(iso3 year countryname)


keep if year >= $year_start
keep if year <= $year_end



collapse (sum) gdp_wb, by(iso3 year)
replace gdp_wb = gdp_wb/1000000 		/*express in milion US$ */

save "$RES//`iso'//temp/temp_gdp", replace

********************************************************************************
********************************************************************************

use "$CTY/WBregio_toolkit", clear

bys iso3: keep if _n == 1


save "$RES//`iso'//temp/temp_regio", replace

********************************************************************************
cd "$TRADESTATS"
unzipfile  cty_code_baci_HS2002, replace
use cty_code_baci, clear

merge m:1 iso3 using "$DATA/cty/TP_FAO_cty_year",  keepusing(iso3)
drop if _m == 1
drop _m 

rename iso3 country
rename libi country_name
replace    country_name = "Turkey"              if country =="TUR"
replace    country_name = "Yugoslavia"          if country =="YUG"

cap drop ctycode
cap drop if strpos(country_name,  "gium-Luxem")
cap drop if strpos(country_name,  "Fed. Rep. of Germany")
cap drop if strpos(country_name,  "Sudan (...2011)")


save "$CTY/temp_cty_name", replace

cap erase cty_code_baci.dta

********************************************************************************
* upload trade baci
cd "$TRADESTATS"
unzipfile  $baci, replace
use "trade_baci_cty", clear

********************************************************************************
* ensure the same perimeter as trade and production dataset

gen iso3 = iso_o

merge m:1 iso3 using "$DATA/cty/TP_FAO_cty_year",    // CSK, SUN, YUG: not matched
keep if _m == 3
drop _m 

 
drop if t < min_year
drop if t > max_year 

drop min_year
drop max_year
drop iso3 
 
********************************************************************************

gen iso3 = iso_d

merge m:1 iso3 using "$DATA/cty/TP_FAO_cty_year" 
keep if _m == 3
drop _m 

drop if t < min_year
drop if t > max_year 

drop min_year
drop max_year
drop iso3


compress
save "$RES//`iso'//temp/trade_baci_cty", replace

cap erase "trade_baci_cty.dta"

********************************************************************************
********************************************************************************
 


preserve
	rename t year
	collapse (sum) X = v, by(iso_o year)
	rename iso_o iso3
	save "$RES//`iso'//temp/trade", replace
restore 

********************************************************************************

	rename t year
	collapse (sum) M= v, by(iso_d year)
	rename iso_d iso3

merge 1:1 year iso3 using "$RES//`iso'//temp/trade"
cap drop _m

save "$RES//`iso'//temp/trade", replace

********************************************************************************
********************************************************************************

use "$RES//`iso'//temp/temp_gdp", clear
keep if year >= $fdate_bg
merge m:1 iso3 using "$RES//`iso'//temp/temp_regio"
drop if _m ==2
drop _m
 

merge 1:1 iso3 year using "$RES//`iso'//temp/trade"
keep if 	_m == 3
drop 		_merge
			
keep 						if region	== "$reg_l"			
replace region="`iso'" 		if iso3		== "`iso'"
replace region="$reg_s" 	if iso3	    != "`iso'"

replace X = X / 1000   // BACI in thousand dollars
replace M = M / 1000


collapse (sum) X M gdp, by(region year)

gen openness = (X + M)/gdp

keep region year openness

reshape wide openness, i(year) j(region) string

preserve
	keep if year == $ldate_bg3 | year== $ldate_bg2  | year== $ldate_bg1   | year== $ldate_bg
	export excel using "$RES//`iso'//statistics.xlsx", sheet("Openness")  sheetreplace firstrow(variables) nolabel 
restore

preserve
	keep if year >= $fdate_bg
	export excel using "$RES//`iso'//statistics.xlsx", sheet("Openness_long")  sheetreplace firstrow(variables) nolabel 
restore


*******************************************************************************/
********************************************************************************
* Prepare Data: only products exported by the country of interest
********************************************************************************
********************************************************************************

use "$GRAVSTATS/gravity_toolkit.dta" , clear


cap rename iso3_o  iso_o 
cap rename iso3_d  iso_d
cap rename year    t


rename iso_o iso3
merge m:1 iso3 using "$CTY/WBregio_toolkit.dta", keepusing(region)
drop if _m == 2
drop _m

rename iso3	iso_o 
rename region region_o




********************************************************************************
********************************************************************************
 
gen $reg_s 			= (region_o =="$reg_l"  & iso_o !="`iso'")


*******************************************************************************/
********************************************************************************

rename	iso_d iso3

merge m:1 iso3 using "$CTY/WBregio_toolkit.dta", keepusing(region)
drop if _m == 2
drop _m

rename iso3	 	iso_d 
rename region 	region_d
rename t year
compress
save 	"$RES//`iso'//temp/gravity_temp", replace

********************************************************************************
*******************************************************************************
* Trade Stats on number of exported products, geographical distribution & compet 
********************************************************************************
********************************************************************************

use "$RES//`iso'//temp/trade_baci_cty", clear

rename t year
keep if year>= $ldate_bg2  

********************************************************************************

gen iso3 = iso_o
merge m:1 iso3 using "$RES//`iso'//temp/temp_regio"
keep if _m ==3
drop _m iso3

rename 	region region_o

********************************************************************************

gen iso3 = iso_d
merge m:1 iso3 using "$RES//`iso'//temp/temp_regio"
keep if _m ==3
drop _m iso3

rename 	region region_d

********************************************************************************

compress

save 	"$RES//`iso'//temp/trade_t_interv", replace

********************************************************************************
********************************************************************************

* main destination markets: all products

use "$RES//`iso'//temp/gravity_temp" , clear
 bys iso_o year: keep if _n == 1
 keep eu_o iso_o year
save "$RES//`iso'//temp/eu_orig", replace 

use "$RES//`iso'//temp/gravity_temp" , clear
 bys iso_d year: keep if _n == 1
 keep eu_d iso_d year
save "$RES//`iso'//temp/eu_destin", replace 
 
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************

use  "$RES//`iso'//temp/trade_t_interv", clear

replace		region_o = "$reg_s" if region_o == "$reg_l"
replace		region_d = "$reg_s" if region_d == "$reg_l"

keep 		if region_o =="$reg_s" | region_d =="$reg_s"

replace		region_o = iso_o if iso_o == "`iso'"
replace		region_d = iso_d if iso_d == "`iso'"

collapse (sum) v, by(region_o iso_o iso_d region_d year)

********************************************************************************
********************************************************************************
********************************************************************************
* Trade Facts 
********************************************************************************
********************************************************************************
********************************************************************************
preserve
	keep if iso_d == "`iso'"
	joinby iso_o year using "$RES//`iso'//temp/eu_orig", unmatched(both)
	tab _m
	drop if _m == 2

	
********************************************************************************	

if "$EU_aggregate" =="YES" {

	replace iso_o = "EU" if eu_o == 1

}
 
********************************************************************************
 	
	
	collapse (sum) v, by(  iso_o iso_d year)

	 
	bys year iso_d: egen 			M = total(v)

					gen m_mkts_sh   =   v/M

	gsort year iso_d  -m_mkts_sh		  
	export excel using "$RES//`iso'//statistics.xlsx", sheet("Top Mkts M")  sheetreplace firstrow(variables) nolabel 
restore

********************************************************************************
********************************************************************************
********************************************************************************

preserve
		keep if region_d == "$reg_s" | region_d == "`iso'"

joinby iso_o year using "$RES//`iso'//temp/eu_orig", unmatched(both)
	tab _m
	drop if _m == 2

********************************************************************************	

if "$EU_aggregate" =="YES" {

	replace iso_o = "EU" if eu_o == 1

}
 
********************************************************************************		

	collapse (sum) v, by(iso_o region_d year)

	bys year region_d: egen num_mkts = nvals(iso_o)

	bys year region_d: egen 			M = total(v)

					  gen m_mkts_sh   =   v/M

	gsort year region_d  -m_mkts_sh		  
					  
	bys year region_d:  gen 	rank  	  = _n			  


	replace m_mkts_sh = . 							if rank >10


	bys year region_d:  egen top_10_mkts  = total(m_mkts_sh)


	collapse (mean) num_mkts  top_10_mkts, by(year region) 
	reshape wide num_mkts  top_10_mkts, i(year) j(region) string
	export excel using "$RES//`iso'//statistics.xlsx", sheet("Top 10 Mkts M")  sheetreplace firstrow(variables) nolabel 
restore

********************************************************************************
********************************************************************************

preserve

keep if region_d == "$reg_s" | region_d == "`iso'"

	joinby iso_o year using "$RES//`iso'//temp/eu_orig", unmatched(both)
	tab _m
	drop if _m == 2

 
********************************************************************************	

if "$EU_aggregate" =="YES" {

	replace iso_o = "EU" if eu_o == 1

}
 
********************************************************************************
	
collapse (sum) v, by(region_d iso_o year)

bys year region_d: egen 		X = total(v)

				  gen m_mkts_sh   =   v/X

gsort year region  -m_mkts_sh		  
				  
bys year region_d:  gen 	rank  	  = _n			  


drop 							if rank >10
export excel using "$RES//`iso'//statistics.xlsx", sheet("Top 10 Mkts_detail M")  sheetreplace firstrow(variables) nolabel 


drop 							if rank >1
collapse (mean) m_mkts_sh, by(year region_d iso_o)
reshape wide   m_mkts_sh, i(year iso_o) j(region_d) string
export excel using "$RES//`iso'//statistics.xlsx", sheet("First Mkt M")  sheetreplace firstrow(variables) nolabel 
restore


********************************************************************************
********************************************************************************
********************************************************************************

preserve 
	keep if iso_o == "`iso'"
	joinby iso_d year using "$RES//`iso'//temp/eu_destin", unmatched(both)
	tab _m
	drop if _m == 2

	
********************************************************************************	

if "$EU_aggregate" =="YES" {

	replace iso_d = "EU" if eu_d == 1

}
 
********************************************************************************
 
	
	
	collapse (sum) v, by( iso_o iso_d year)

	bys year iso_o: egen num_mkts = nvals(iso_d)

	bys year iso_o: egen 			X = total(v)

					  gen x_mkts_sh   =   v/X
					  
	gsort year iso_o  -x_mkts_sh
	export excel using "$RES//`iso'//statistics.xlsx", sheet("Top Mkts X")  sheetreplace firstrow(variables) nolabel 
restore

********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************

preserve
	keep if region_o == "$reg_s" | region_o == "`iso'"
 
	joinby iso_d year using "$RES//`iso'//temp/eu_destin", unmatched(both)
	tab _m
	drop if _m == 2
	
********************************************************************************	

if "$EU_aggregate" =="YES" {

	replace iso_d = "EU" if eu_d == 1

}
 
********************************************************************************	
	
	collapse (sum) v, by(  region_o iso_d year)

	bys year region_o: egen num_mkts = nvals(iso_d)

	bys year region_o: egen 			X = total(v)

					  gen x_mkts_sh   =   v/X

	gsort year region_o  -x_mkts_sh		  
					  
	bys year region_o:  gen 	rank  	  = _n			  


	replace x_mkts_sh = . 							if rank >10


	bys year region_o:  egen top_10_mkts  = total(x_mkts_sh)


	collapse (mean) num_mkts  top_10_mkts, by(year region) 
	reshape wide num_mkts  top_10_mkts, i(year) j(region) string
	export excel using "$RES//`iso'//statistics.xlsx", sheet("Top 10 Mkts")  sheetreplace firstrow(variables) nolabel 
restore


********************************************************************************
********************************************************************************
********************************************************************************

preserve

	keep if region_o == "$reg_s" | region_o == "`iso'"

	joinby iso_d year using "$RES//`iso'//temp/eu_destin", unmatched(both)
	tab _m
	drop if _m == 2

	
********************************************************************************	

if "$EU_aggregate" =="YES" {

	replace iso_d = "EU" if eu_d == 1

}
 
********************************************************************************
 


collapse (sum) v, by(region_o iso_d year)

bys year region_o: egen 		X = total(v)

				  gen x_mkts_sh   =   v/X

gsort year region  -x_mkts_sh		  
				  
bys year region_o:  gen 	rank  	  = _n			  


drop 							if rank >10
export excel using "$RES//`iso'//statistics.xlsx", sheet("Top 10 Mkts_detail X")  sheetreplace firstrow(variables) nolabel 


drop 							if rank >1
collapse (mean) x_mkts_sh, by(year region_o iso_d)
reshape wide   x_mkts_sh, i(year iso_d) j(region_o) string
export excel using "$RES//`iso'//statistics.xlsx", sheet("First Mkt X")  sheetreplace firstrow(variables) nolabel 
restore

********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
* Number of products EXPORTS


use  "$RES//`iso'//temp/trade_t_interv", clear
replace		region_o = "$reg_s" if region_o == "$reg_l"
keep 	if 	region_o =="$reg_s" 

replace		region_o = iso_o 		if iso_o 	== "`iso'"
keep if 	region_o == "$reg_s" | region_o 	== "`iso'"

********************************************************************************

preserve
	collapse (sum) v, by(region_o iso_o k year)

	bys year iso_o: egen num_products = nvals(k)
	bys year iso_o: egen 			X = total(v)

					  gen x_prod_sh   =   v/X

	gsort year iso_o  -x_prod_sh		  
					  
	bys year iso_o:  gen 	rank  	  = _n			  
	 
	replace x_prod_sh = . 							if rank >10

cap drop if x_prod_sh == .
			
	bys year iso_o:  egen top_10_prod  = total(x_prod_sh)

	collapse (mean) num_products  top_10_prod, by(region_o year) 

	reshape wide num_products  top_10_prod, i(year) j(region_o) string
	export excel using "$RES//`iso'//statistics.xlsx", sheet("Top 10 product X cum share")  sheetreplace firstrow(variables) nolabel 
restore

********************************************************************************
********************************************************************************
 

preserve
	collapse (sum) v, by(region_o k year)

	bys year region_o: egen 			X = total(v)

					  gen x_prod_sh   =   v/X

	gsort year region  -x_prod_sh		  
					  
	bys year region:  gen 	rank  	  = _n			  


	drop 							if rank >10
	export excel using "$RES//`iso'//statistics.xlsx", sheet("Top 10 products X")  sheetreplace firstrow(variables) nolabel 


	drop 							if rank >1
	collapse (mean) x_prod_sh, by(year region_o k)
	reshape wide   x_prod_sh, i(year k) j(region_o) string
	export excel using "$RES//`iso'//statistics.xlsx", sheet("First product X share")  sheetreplace firstrow(variables) nolabel 
restore


********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
* Number of products IMPORTS


use  "$RES//`iso'//temp/trade_t_interv", clear
replace		region_d = "$reg_s" if region_d == "$reg_l"
keep 	if 	region_d =="$reg_s" 

replace		region_d = iso_d 		if iso_d 	== "`iso'"
keep if 	region_d == "$reg_s" | region_d 	== "`iso'"

********************************************************************************

preserve
	collapse (sum) v, by(region_d iso_d k year)

	bys year iso_d: egen num_products = nvals(k)
	bys year iso_d: egen 			M = total(v)

					  gen m_prod_sh   =   v/M

	gsort year iso_d  -m_prod_sh		  
					  
	bys year iso_d:  gen 	rank  	  = _n			  
	 
	replace m_prod_sh = . 							if rank >10

cap drop if m_prod_sh == .
			
	bys year iso_d:  egen top_10_prod  = total(m_prod_sh)

	collapse (mean) num_products  top_10_prod, by(region_d year) 

	reshape wide num_products  top_10_prod, i(year) j(region_d) string
	export excel using "$RES//`iso'//statistics.xlsx", sheet("Top 10 product M cum share")  sheetreplace firstrow(variables) nolabel 
restore

********************************************************************************
********************************************************************************

preserve
	collapse (sum) v, by(region_d k year)

	bys year region_d: egen 			M = total(v)

					  gen m_prod_sh   =   v/M

	gsort year region  -m_prod_sh		  
					  
	bys year region:  gen 	rank  	  = _n			  


	drop 							if rank >10
	export excel using "$RES//`iso'//statistics.xlsx", sheet("Top 10 products M")  sheetreplace firstrow(variables) nolabel 


	drop 							if rank >1
	collapse (mean) m_prod_sh, by(year region_d k)
	reshape wide   m_prod_sh, i(year k) j(region_d) string
	export excel using "$RES//`iso'//statistics.xlsx", sheet("First product M share")  sheetreplace firstrow(variables) nolabel 
restore
********************************************************************************
********************************************************************************
********************************************************************************
* Structural RCA: Competitiveness Ladder: Cross Section 2018
 
use "$RES//`iso'//temp/trade_t_interv", clear

keep if iso_o == "`iso'"

collapse (sum) v, by(year k)


********************************************************************************
********************************************************************************

preserve
	keep if year == $ldate_bg
	bys k: keep if _n ==1
	keep k
	save "$RES//`iso'//k_list_`=$ldate_bg'", replace
restore

********************************************************************************

preserve
	keep if year == $ldate_bg | year == $ldate_bg1
	bys k:  gen obs = _N

	keep if obs == 2		
	bys k: keep if _n ==1
	keep k
	save "$RES//`iso'//k_list_`=$ldate_bg'_`=$ldate_bg1'", replace
restore

preserve
	keep if year == $ldate_bg | year == $ldate_bg1 | year ==  $ldate_bg2
	bys k:  gen obs = _N

	keep if obs >= 2
	bys k: keep if _n ==1
	keep k
	save "$RES//`iso'//k_list_`=$ldate_bg'_`=$ldate_bg1'_`=$ldate_bg2'", replace
restore

********************************************************************************
********************************************************************************
use "$RES//`iso'//temp/trade_baci_cty", clear

keep if   t  >= $fdate_bg

merge m:1 k using 		"$RES//`iso'//k_list_`=$ldate_bg'_`=$ldate_bg1'"
keep if _m == 3
drop _m

rename    t year
collapse (sum) v, by(iso_o iso_d year)

compress
save "$RES//`iso'//temp/est_sample_rca", replace

********************************************************************************
********************************************************************************
 
 
use "$RES//`iso'//temp/est_sample_rca", replace

preserve
	bys year: keep if _n==1
	keep year
	save "$RES//`iso'//temp/square", replace
restore


preserve
	bys 	iso_o: keep if _n==1
	keep 	iso_o
	cross using "$RES//`iso'//temp/square.dta"
	save "$RES//`iso'//temp/square.dta", replace
restore


preserve
	bys 	iso_d: keep if _n==1
	keep 	iso_d
	cross 	using "$RES//`iso'//temp/square.dta"
	save 	"$RES//`iso'//temp/square.dta", replace
restore

merge 1:1 year iso_o iso_d using "$RES//`iso'//temp/square.dta", nogenerate
cap erase 	 "$RES//`iso'//temp/square.dta"


********************************************************************************
* ensure the same perimeter as trade and production dataset

gen iso3 = iso_o

merge m:1 iso3 using "$DATA/cty/TP_FAO_cty_year",    // CSK, SUN, YUG: not matched
keep if _m == 3
drop _m 

 
drop if year < min_year
drop if year > max_year 

drop min_year
drop max_year
drop iso3 
 
********************************************************************************

gen iso3 = iso_d

merge m:1 iso3 using "$DATA/cty/TP_FAO_cty_year" 
keep if _m == 3
drop _m 

drop if year < min_year
drop if year > max_year 

drop min_year
drop max_year
drop iso3



drop if iso_o == iso_d
replace v = 0 if v==.


********************************************************************************
* merge gravity

merge m:1 iso_o iso_d year using "$RES//`iso'//temp/gravity_temp"
drop if _m == 2
drop _m


********************************************************************************
********************************************************************************

cap drop i
cap drop j

egen i 	= group(iso_o)
egen j 	= group(iso_d)

egen it = group(iso_o year)
egen jt = group(iso_d year)


bys jt: egen tx = total(v)

global clus "i j"

gen v_sh            =    v / tx
gen ldist 			= ln( $dist )
gen lx              = ln(v)

********************************************************************************
********************************************************************************
* PPML
 
ppmlhdfe v   $covar  ,  absorb(   ppml_d_jt = jt ppml_d_it = it)  d maxiter(1000) acceleration(steep)  

 

preserve
	collapse (mean)    ppml_d_it   (sum) X = v , by(iso_o year )
	save "$RES//`iso'//temp/est_rca_ppml", replace
restore



********************************************************************************
********************************************************************************

use  "$RES//`iso'//temp/est_rca_ppml", clear

cap rename ppml_d_it d_it

cap drop period
gen	 period = $ldate_bg if year >= ($ldate_bg - 5) 

save "$RES//`iso'//temp/temp_comp_graph", replace

********************************************************************************
********************************************************************************

use "$RES//`iso'//temp/temp_comp_graph", replace

replace d_it 				= exp(d_it)
drop if d_it       			== .

bys year: egen max_rca 		= max(d_it)

gen rca_norm	     		= d_it/max_rca


replace rca_norm            =  .   if rca_norm <= 0.00001
drop if rca_norm            == .

collapse (mean) rca_norm  X, by(iso_o period)

replace rca_norm   = ln(rca_norm)

keep if period == $ldate_bg
label var rca_norm "FEs {&delta}_i)"
hist rca_norm, normal lcolor(dknavy.5)  lwidth(none)   fcolor(dknavy*.25)  normopts(lcolor(dkorange) lw(medthick))  xtitle(" " "FEs (d_it)")    /*
*/ legend(  row(1) region(lwidth(none) margin(medium) ) ) title("")  graphregion(margin(tiny))  plotregion(lwidth(none))
gr export "$RES//`iso'//rca_distribution.png", as(png) replace


********************************************************************************
********************************************************************************
use "$RES//`iso'//temp/temp_comp_graph", replace

replace d_it 				=  exp(d_it)
drop if d_it       			== .

bys year: egen max_rca 		= max(d_it)

gen rca_norm	     		= d_it/max_rca

collapse (mean) rca_norm  X, by(iso_o period)
drop if period ==.

********************************************************************************
********************************************************************************

rename iso_o iso3
merge m:1 iso3 using "$RES//`iso'//temp/temp_regio"
keep if _m == 3
drop _m
 
 
 
preserve

	keep if  period == $ldate_bg

	rename rca_norm share_1pc
	  
	gsort -share_1pc
	gen rank	 = _n
	gen N 		 = _N
	gen rank_pos = N - rank

	summ rank_pos, d
	replace rank_pos = ((rank_pos - r(min)) / (r(max) - r(min)))*100

********************************************************************************
	summ rank_pos, d
	gen		label = iso3 if  (rank_pos>=r(p90) & region =="$reg_l") | iso3 =="`iso'"
	replace label = iso3 if  (rank_pos>=r(p95)                                        )  

	 
********************************************************************************

	gsort share_1pc
	gen position = _n
	egen max_pos = max(share_1pc)

	gen lshare 	 = ln(share_1pc)
	gen lpos 	 = ln(position)
	gen lmax 	 = ln(max_pos)

	gen ecdf 	 = 1 - exp(-[lpos/lmax])


	*tw (scatter ecdf share_1pc,  mcolor(dknavy)  msymbol(T)  msize(small) mlabel(label) mlabangle(45)  mlabposition(2)  mlabcolor(gs5)  ) , /*
	**/  legend( region(lwidth(none)) cols(2) ) note("Year 2019-2016") xtitle("Nun Mkts (%)")   yscale(rev)  ytitle("Exporters (%)") plotregion(lwidth(none)) 

	tabstat share_1pc, s(min p1 p25 p50 p75 max)
	tabstat rank, s(min p25 p50 p75 max)


********************************************************************************

	cap drop share_norm
	sum share_1pc, d
	gen share_norm = share_1pc/r(max)*100

	summ share_1pc, d
	global x0    = round(r(p50),.00001)
	global x1    = round(r(p75),.01)
	global x2    = round(r(max),.01)


	summ rank, d
	global y0    = round(r(min))
	global y1    = round(r(p25))
	global y2    = round(r(p50))
	global y3    = round(r(max))

********************************************************************************

	tabstat share_1pc, s(min p1 p25 p50 p75 max)
	tabstat rank, s(min p25 p50 p75 max)

	tw (scatter rank  share_1pc if label !="`iso'",  mcolor(dknavy)  msymbol(T)  msize(small) mlabel(label) mlabangle(45)  mlabposition(2)  mlabcolor(gs5)  mlabsize(vsmall) ) /*
	*/ (scatter rank  share_1pc if label =="`iso'",  mcolor(dknavy)  msymbol(T)  msize(small) mlabel(label) mlabangle(45)  mlabposition(2)  mlabcolor(cranberry) mlabsize(vsmall) ) , /*
	*/  legend(off)  xtitle("Competitiveness Ladder") yscale(log) xscale(log)    ytitle("Exporters (#)" ) plotregion(lwidth(none)) /*
	*/ name(g1,replace) xla(  `=$x0' "50"  `=$x1'  "75" `=$x2' "100" , grid glstyle(minor_grid )    nogmin nogmax)   yla(  `=$y0' "`=$y0'"   `=$y1' "`=$y1'"   `=$y2' "`=$y2'"   `=$y3' "`=$y3'"  , grid glstyle(minor_grid )    nogmin nogmax) 

	graph export "$RES//`iso'//rca_`=$ldate_bg'.png", as(png) replace

	gen target ="$iso"
	keep target iso3 rank  share_1pc
	duplicates drop
	export excel using "$RES//`iso'//statistics.xlsx", sheet("RCA_details")  sheetreplace firstrow(variables) nolabel 

	
restore

cap 	log close

********************************************************************************
********************************************************************************


