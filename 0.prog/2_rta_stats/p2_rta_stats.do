 


cap 	log close
capture log using "$LOG/2_rta_stats/rta_stats_`=$iso'", text replace

local iso "$iso"

********************************************************************************
********************************************************************************
* Basic Stats on RTA & Cluster analysis
********************************************************************************
********************************************************************************
* Coverage Agreements 

use 	"$DATA/trade_rta_ver2024"  , clear   // full sample 166 countries

keep if iso_o 		== "`iso'"
keep if year 		== $ldate_bg_rta   // keep the last year in the sample

keep if agreement 	!= ""
 

keep iso_d agreement id_agree $kmean_alg  entry_force


save	"$RES//`iso'//temp/RTA_cty", replace
export excel using "$RES//`iso'//statistics.xlsx", sheet("RTAs_at_place")  sheetreplace firstrow(variables) nolabel

keep	id_agree agreement	
bys	id_agree: keep if _n == 1
save	"$RES//`iso'//temp/id_agree_list", replace

********************************************************************************
********************************************************************************
* Trade in and out RTAs

use "$RES//`iso'//temp/trade_baci_cty", clear

keep if iso_o =="`iso'"

rename t year

collapse (sum) v, by(iso_o iso_d year)


merge m:1 iso_o iso_d year using "$RES//`iso'//temp/gravity_temp"
keep if _m ==3
drop _m

merge m:1 iso_d  using	"$RES//`iso'//temp/RTA_cty" 

keep	if year >= $ldate_bg1

bys iso_o year: egen X     = total(v)
				gen mkt_sh_x = v/X*100


collapse (sum) mkt_sh_x, by(agreement year)

save	"$RES//`iso'//temp/mkt_sh_X", replace

********************************************************************************
********************************************************************************
* Import share from partners

use "$RES//`iso'//temp/trade_baci_cty", clear
keep if iso_d =="`iso'"

rename t year

collapse (sum) v, by(iso_o iso_d year)


merge m:1 iso_o iso_d year using "$RES//`iso'//temp/gravity_temp"
keep if _m ==3
drop _m

rename		iso_d  iso_temp
rename		iso_o  iso_d

merge 	m:1  iso_d  using	"$RES//`iso'//temp/RTA_cty"

keep	if year >= $ldate_bg1

rename		iso_d		iso_o
rename		iso_temp	iso_d


bys iso_d year: egen M     = total(v)
				gen mkt_sh_m = v/M*100

collapse (sum) mkt_sh, by(agreement year)

	
merge	1:1 	year agreement using "$RES//`iso'//temp/mkt_sh_X"
drop	_m

replace	agreement = "RoW" if agreement == ""
export excel using "$RES//`iso'//statistics.xlsx", sheet("mkt_sh_by_RTA")  sheetreplace firstrow(variables) nolabel 


********************************************************************************
********************************************************************************
* this file is computed using the DTA raw data all agreements

use "$DATA/rta_data_for_cluster", clear

merge m:1 id_agree using "$DATA/agree_list_GE.dta", keepusing(entry_force agreement)
keep if _m == 3
drop _m

sum rta_deep, d
replace rta_deep = 0 if rta_deep == .

/* Dicotomize to ease interpretation */
replace rta_deep = 1 if rta_deep > 1 

bys id_provision	: egen max_w		=     max(rta_deep )
drop if max_w == 0  /* Drop provision never active */
cap drop max_w

bys Area: egen num_provision = nvals(id_provision)

rename rta_deep  		agree_coverage

collapse (mean) num_provision agree_coverage, by(id_agree Area)

egen num_agree = nvals(id_agree)   /* 278 */

gen coverage_0  	= (agree_coverage == 0)
gen coverage_25 	= (agree_coverage <  0.25 & agree_coverage > 0)
gen coverage_2550 	= (agree_coverage >= 0.25 & agree_coverage < 0.5)
gen coverage_5075 	= (agree_coverage >= 0.5  & agree_coverage < 0.75)

gen coverage_75 	= (agree_coverage >= 0.75 )


********************************************************************************
********************************************************************************
* Average coverage

preserve

	collapse (mean) num_provision agree_coverage (sum) coverage_*, by(Area)

	export excel using "$RES//`iso'//statistics.xlsx", sheet("PTAs_coverage_all")  sheetreplace firstrow(variables) nolabel 

restore

********************************************************************************
********************************************************************************
* average for Deep Agreements

preserve
    
	merge m:1 id_agree using "$DATA/agree_list_GE.dta", keepusing( $kmean_alg )
	keep if _m ==3
	keep if $kmean_alg    ==  1 

	collapse (mean)   agree_coverage (sum) coverage_*, by(Area)

	export excel using "$RES//`iso'//statistics.xlsx", sheet("PTAs_coverage_deep")  sheetreplace firstrow(variables) nolabel 
restore

********************************************************************************
********************************************************************************

preserve
	
	merge	m:1 	id_agree	using "$RES//`iso'//temp/id_agree_list"
	keep	if _m == 3
	
	tab id_agree

	collapse (mean) agree_coverage, by(Area id_agree)


	reshape wide agree_coverage, i(Area) j(id_agree) 
	export excel using "$RES//`iso'//statistics.xlsx", sheet("PTAs_coverage_cty")  sheetreplace firstrow(variables) nolabel 

restore

cap 	log close


********************************************************************************
*******************************************************************************/
