
/******************************************************************************* 

     A general equilibrium (GE) assessment of the economic impact of
                   Deep regional Trade Agreements (DTAs)

                   by Lionel Fontagné and Gianluca Santoni

				   this version: March 2021
				   
			   NEW DATASTE ON AGREEMENTS AND MEMBERS ( release Sept 2021)    

*******************************************************************************/

clear all
program drop _all
macro drop _all
matrix drop _all
clear mata
clear matrix
   
set virtual on
set more off
set scheme s1color

set seed 01032018

global seed "01032018"


 global DB 			"D:\Santoni\Dropbox"
*global DB      	"C:\Users\gianl\Dropbox"
*global DB  		"E:\Dropbox\"


global ROOT 		"$DB\Regionalism_2017\NADIA_project"



********************************************************************************
* Run the baseline cluster plus gravity (partial equilibrium gravity)
global ROOT_P 		"$DB\Regionalism_2017\NADIA_project\progs_march2021"
global PROG 		"$DB\Regionalism_2017\NADIA_project\progs_march2021\1_cluster_baseline"
global RES	 		"$DB\Regionalism_2017\NADIA_project\results_march2021\1_cluster_baseline_oct21_prod_ratio"
global DATA 		"$DB\Regionalism_2017\NADIA_project\data_sept2020\estimation_data_oct2021"
global DATA_WP 		"$DB\Regionalism_2017\NADIA_project\data_sept2020\estimation_data_march2021"
global TEMP_RTA 	"$DB\Regionalism_2017\NADIA_project\data_sept2020\temp_rta_oct2021"
global TEMP_TRADE 	"$DB\Regionalism_2017\NADIA_project\data_sept2020\temp_trade_oct2021"
global TEMP			"$DB\Regionalism_2017\NADIA_project\data_sept2020"



global GRAPH 		"$RES\graphs"


global REPILCATION	"$ROOT\paper_submission\replication_accepted_WBER"
global  TB 		    "$REPILCATION\tables"   
global  GR 		    "$REPILCATION\figures"   
global SUBMIT		"$ROOT\paper_submission"



global CONTROLS 	"$DB\Regionalism_2017\NADIA_project\data_sept2020\"


********************************************************************************
********************************************************************************

cap 	log close
capture log using "$ROOT_P\log_files\provisions_by_cluster", text replace

 *******************************************************************************/
cd $DATA


********************************************************************************
* Descriptive stats about clusters

use "$TEMP_RTA\bilateral_rta_ctys", clear



replace iso_o="ROM" if iso_o =="ROU"
replace iso_d="ROM" if iso_d =="ROU"

replace iso_o="PAL" if iso_o =="PSE"
replace iso_d="PAL" if iso_d =="PSE"

replace iso_o="YUG" if iso_o =="SRB"
replace iso_d="YUG" if iso_d =="SRB"


merge m:1 iso_o using "$TEMP_TRADE\temp_est.dta", keepusing(iso_o)
keep if _m==3
drop _m

merge m:1 iso_d using "$TEMP_TRADE\temp_est.dta", keepusing(iso_d)
keep if _m==3
drop _m





********************************************************************************
do "$ROOT_P\select_agree.do"
********************************************************************************


bys id_agree: keep if _n == 1
cap drop year 

merge m:1 id_agree using "$RES\kmeans_estimate"
drop if _m ==  2
drop _m

xtile year_bins = entry_force , nq(10)

bys year_bins: egen min = min(entry_force)
bys year_bins: egen max = max(entry_force)

tostring min, replace
tostring max, replace

merge 1:1 id_agree using "$RES\temp_descriptive_stats"
keep if _m == 3
drop _m


merge m:1 id_agree using "$TEMP_RTA\size_agree"
keep if _m == 3
drop _m


merge m:1 id_agree using "$RES\kmeans_estimate", keepusing(kmeanPP2)
keep if _m == 3
drop _m

destring kmeanPP2, replace
qui tab kmeanPP2, gen(KPP_)



label var rta_deep_std1  "Anti-dumping"

label var rta_deep_std2  "Countervailing Duties"
label var rta_deep_std3  "Competition"

label var rta_deep_std4  "Environment"
label var rta_deep_std5  "Export Taxes"
label var rta_deep_std6  "IPR"
label var rta_deep_std7  "Investment"
label var rta_deep_std8  "Labor Market"
label var rta_deep_std9  "Movement of Workers"
label var rta_deep_std10 "Movement of Capitals"
label var rta_deep_std11 "Public Procurement"
label var rta_deep_std12 "Rules of Origin"

label var rta_deep_std13 "SPS"
label var rta_deep_std14 "STE"
label var rta_deep_std15 "Services"
label var rta_deep_std16 "Subsidies"
label var rta_deep_std17 "TBT"
label var rta_deep_std18 "Trade Facitlitation"


preserve
keep id_agree  rta_deep_std7
rename rta_deep_std7 score_invest
save temp_agree_invest, replace
restore

/******************************************************************************/

  forvalues a = 1(1) 18  {


egen mean_rta 								= mean(rta_deep_std`a' )
egen min_rta 								= min(rta_deep_std`a' )
egen max_rta 								= max(rta_deep_std`a' )

egen sd_rta 								= sd(rta_deep_std`a' )
replace 			rta_deep_std`a' 	    = (rta_deep_std`a'  - mean_rta)/sd_rta

gen 	 			rta_deep_n`a' 	    	= (rta_deep_std`a'  - min_rta)/(max_rta - min_rta) 


cap drop mean_rta
cap drop sd_rta



cap drop min_rta
cap drop max_rta

}


preserve
keep id_agree  rta_deep_std7
rename rta_deep_std7 score_invest_std
merge 1:1  id_agree using temp_agree_invest
keep if _m == 3
drop _m 
save temp_agree_invest, replace
restore


*******************************************************************************/

global provisions "rta_deep_std1-rta_deep_std18"

reg KPP_3 $provisions  	KPP_2 						, 
est store k3_lpm 

reg KPP_3 $provisions 	KPP_2	 i.year_bins		, 
est store k3c_lpm 

reg KPP_1 $provisions 	KPP_2	 i.year_bins		, 
est store k1c_lpm 

reg KPP_1 $provisions 	KPP_2						, 
est store k1_lpm  




/*******************************************************************************
********************************************************************************

*global cluster "k3"
global cluster "kmeanPP"

oglm $cluster rta_deep_std1-rta_deep_std18  , robust 
margins, dydx(*) predict(outcome(1)) post atmean 
est store k1

oglm $cluster rta_deep_std1-rta_deep_std18  , robust 
margins, dydx(*) predict(outcome(2)) post  atmean
est store k2

oglm $cluster rta_deep_std1-rta_deep_std18  , robust 
margins, dydx(*) predict(outcome(3)) post  atmean
est store k3 


************************************************************
************************************************************

oglm $cluster rta_deep_std1-rta_deep_std18  , robust 
margins,   predict(outcome(1)) post  atmean
est store k1_atmean 

oglm $cluster rta_deep_std1-rta_deep_std18  , robust 
margins,   predict(outcome(2)) post  atmean
est store k2_atmean 


oglm $cluster rta_deep_std1-rta_deep_std18  , robust 
margins,   predict(outcome(3)) post   
est store k3_atmean 

********************************************************************************
*******************************************************************************/

label var rta_deep_std1  "Anti-dumping"

label var rta_deep_std2  "Countervailing Duties"
label var rta_deep_std3  "Competition"

label var rta_deep_std4  "Environment"
label var rta_deep_std5  "Export Taxes"
label var rta_deep_std6  "IPR"
label var rta_deep_std7  "Investment"
label var rta_deep_std8  "Labor Market"
label var rta_deep_std9  "Movement of Workers"
label var rta_deep_std10 "Movement of Capitals"
label var rta_deep_std11 "Public Procurement"
label var rta_deep_std12 "Rules of Origin"

label var rta_deep_std13 "SPS"
label var rta_deep_std14 "STE"
label var rta_deep_std15 "Services"
label var rta_deep_std16 "Subsidies"
label var rta_deep_std17 "TBT"
label var rta_deep_std18 "Trade Facitlitation"

*******************************************************************************
preserve

keep $provisions KPP_* year_bins
save "$REPILCATION\data\fig2.dta", replace

restore

*******************************************************************************

coefplot (k3c_lpm		, label("Cluster # 3")  m(D) mcolor(dkorange)   msize(medium)     ciopts(lcolor(dkorange*0.5)   lwidth(med)) )     /*
*/       (k1c_lpm		, label("Cluster # 1")  m(D) mcolor(dknavy)   msize(medium)     ciopts(lcolor(dknavy*0.5)   lwidth(med)) )      ,     /*
*/     keep( 	rta_deep_std*	 )  plotregion(lwidth(none)) grid(between glcolor(gs15) glpattern(dash)) levels(90) xline(0, lcolor(gs10)  ) /*
*/  format(%9.3f) graphregion(margin(medium))  plotregion(lwidth(none)) legend( region(lwidth(none)) cols(3) )   
graph export "$GRAPH\markers_kmeanPP_new.pdf", as(pdf) replace
gr export "$GR\fig2.pdf", as(pdf) replace
gr export "$SUBMIT\markers_kmeanPP.pdf", as(pdf) replace


*******************************************************************************/
/*                   MAKE a TABLE FOR DESCRIPTION                             */
********************************************************************************

cd $DATA


use rta_data_for_cluster, clear


merge m:1 id_agree using "$TEMP_RTA\id_agree_legend"
keep if _m == 3
drop _m


********************************************************************************
do "$ROOT_P\select_agree.do"
********************************************************************************

*******************************************************************************
* Apparently a coding error only one observation > 1 (among non 0) 

replace rta_deep   = 1          if id_provision == 921 & rta_deep > 1 & rta_deep != .   
* Provision: Does the agreement include any national treatment obligation (goods) for subsidies?.	Coding Subsidies - prov_23  


replace rta_deep   = 1          if id_provision == 738 & rta_deep > 1 & rta_deep != .   
*Provision	 Does the Agreement refer to the WTO SPS Agreement?.	Coding SPS - prov_02


replace rta_deep   = 1			if id_provision == 84  & rta_deep > 1 & rta_deep != .   
* Provision	 Mutually acceptable solution (1=yes, 0 = no). Coding	Countervailing duties - cvd3_a



replace rta_deep   = 1			if id_provision == 663 & rta_deep > 1 & rta_deep != .   
* Provision	 How many days does the agreement allow for tender submission? (please indicate for all members of the agreement). Coding	Public Procurement - prov_74



replace rta_deep   = 1			if id_provision == 675 & rta_deep > 1 & rta_deep != .   
* Provision	 How many days does the agreement allow for the publication of award information? (please indicate for all members of the agreement). Coding	Public Procurement - prov_86


replace rta_deep   = 1			if id_provision == 698 & rta_deep > 1 & rta_deep != .   
* Provision	 What is the percentage of value content required with alt method?.	Coding Rules of Origin - roo_vcr_per2



/******************************************************************************/
* RoO The record keeping period: the shorter the  better 
sum rta_deep 							if id_provision == 681 & rta_deep != 0, d

replace rta_deep   = 1/rta_deep 		if id_provision == 681 & rta_deep != 0
*Provision	 What is the length of the record keeping period?. Coding	Rules of Origin - roo_cer_rec

********************************************************************************
* AD Duration and review of anti-dumping duties and price undertakings: the shorter the  better 

sum rta_deep 							if id_provision == 20 & rta_deep != 0, d
replace rta_deep   = 1/rta_deep 		if id_provision == 20 & rta_deep != 0
* Duration and review of anti-dumping duties and price undertakings		-  review. Coding Anti-dumping - ad3-k-2


sum rta_deep 							if id_provision == 36 & rta_deep != 0, d
replace rta_deep   = 1/rta_deep 		if id_provision == 36 & rta_deep != 0
*  Notification/Consultation (1=yes, 0=no)		if yes, length of period (days). Coding	Anti-dumping - ad3-o-1



*******************************************************************************/

gen 	rta_w      						= 			 rta_deep

replace rta_w 				 			=  0      if rta_w == .   			  /* all  weigthed */

gen 	rta_u      						= 			 rta_deep
replace rta_u  							=  0      if rta_u == .   			  /* all  un-weigthed */

replace rta_u  							=  1      if rta_u >  0 & rta_u != .  /* Dicotomize */

gen     rta_w_pos 				 		=  			 rta_w
replace rta_w_pos  						=  .      if rta_w_pos == 0   		  /* only positives un-weigthed */

gen     rta_u_pos 				 		=  			 rta_u
replace rta_u_pos  						=  .      if rta_u_pos == 0   		  /* only positives un-weigthed */

********************************************************************************

/* Dicotomize to ease interpretation */

********************************************
* gen stats by provision: ROW normalization
bys id_provision	: egen min_w		=      min(rta_w_pos)
bys id_provision	: egen tot_w		=    total(rta_w )

bys id_provision	: egen mean_w		=     mean(rta_w )
bys id_provision	: egen mean_u		=     mean(rta_u )
bys id_provision	: egen mean_w_pos	=     mean(rta_w_pos)
 

 
bys id_provision	: egen total_u		=     total(rta_u )


summ mean_w mean_u mean_w_pos

gen     rta_w_old 						=    rta_w / mean_w


replace rta_w   						=    rta_w / mean_w_pos
replace rta_w   						=    rta_w / mean_u





bys id_provision	: egen max_u		=     max(rta_u )

 
********************************************************** 
drop if max_u == 0  /* Drop provision never active */
**********************************************************

bys Area: egen num_provision = nvals(id_provision)


rename rta_u  		agree_coverage

rename rta_w    	agree_score_new
rename rta_w_old   	agree_score_old

rename mean_u    	prov_freq

rename total_u      check_freq


ed if id_provision==836

ed if id_provision==837

ed if id_provision==850


ed if id_provision==850 & id_agree == 284
ed if id_provision==850 & id_agree == 122
ed if id_provision==850 & id_agree == 129
ed if id_provision==850 & id_agree == 10
ed if id_provision==850 & id_agree == 161


collapse (mean) agree_coverage agree_score* prov_freq check_freq num_provision (max) max_agree = check_freq  (sum) tot_prov = agree_coverage, by(id_agree Area)


********************************************************************************

preserve
keep if Area =="Investment"
keep id_agree agree_coverage
rename agree_coverage invest_coverage
merge 1:1  id_agree using temp_agree_invest
keep if _m == 3
drop _m 

save temp_agree_invest, replace
restore


********************************************************************************

merge m:1 id_agree using "$RES\kmeans_estimate"
keep if _m == 3
drop _m

bys Area: egen average_number_provisions = mean(tot_prov)

merge m:1 id_agree using "$TEMP_RTA\id_agree_legend"
keep if _m == 3
drop _m


ed if id_agree == 284 & Area=="Services"
ed if id_agree == 122 & Area=="Services"
ed if id_agree == 129 & Area=="Services"


ed if id_agree == 10  & Area=="Services"
ed if id_agree == 161 & Area=="Services"


collapse (mean) agree_coverage agree_score* num_provision check_freq  max_agree tot_prov average_number_provisions, by(kmeanPP2 Area) /* this goes into the table: Description_content_clusters */

********************************************************************************
********************************************************************************
********************************************************************************

cd $DATA


use rta_data_for_cluster, clear


merge m:1 id_agree using "$TEMP_RTA\id_agree_legend"
keep if _m == 3
drop _m


********************************************************************************
do "$ROOT_P\select_agree.do"
********************************************************************************

sum rta_deep, d
replace rta_deep = 0 if rta_deep == .

/* Dicotomize to ease interpretation */
replace rta_deep = 1 if rta_deep > 1 

bys id_provision	: egen max_w		=     max(rta_deep )
drop if max_w == 0  /* Drop provision never active */
cap drop max_w


merge m:1 id_agree using "$RES\kmeans_estimate"
keep if _m == 3
drop _m

bys id_provision kmeanPP	: egen max_w		=     max(rta_deep )
bys id_provision kmeanPP	: egen mean_w		=     mean(rta_deep )


bys kmeanPP2: egen _navls = nvals(id_agree)
tab _navls

collapse (mean) max_w mean_w (sum) rta_deep, by(id_provision Area kmeanPP2)


reshape wide max_w mean_w rta_deep, i(id_provision Area) j(kmeanPP2)  


gen 		id_prov_cl1_only = 1 if max_w1==1 & (max_w2 == 0 & max_w3 == 0)
replace 	id_prov_cl1_only = 0 if id_prov_cl1_only == .


gen 		id_prov_cl1_mean = 1 if mean_w1 > mean_w2 & mean_w2 > mean_w3
replace 	id_prov_cl1_mean = 0 if id_prov_cl1_mean == .

tabstat id_prov_cl1_mean id_prov_cl1_only rta_deep1 , by(Area) s(sum) /* this goes into the table: Description_content_clusters (Provisions in Cluster # 1 ) */

**************************************************************

preserve

keep if id_prov_cl1_mean == 1

merge 1:1 id_provision using "$TEMP_RTA\id_provision_legend.dta" 
keep if _m == 3
drop _m

order id_provision Area Section Subsection Provision
keep id_provision Area Section Subsection Provision mean_w1 mean_w2 mean_w3 

save "$TEMP_RTA\148_provisions_clust1", replace /* this goes into the table: 148_provision lists */

restore

********************************************************************************
********************************************************************************


cd $DATA


use rta_data_for_cluster, clear

merge m:1 id_agree using "$TEMP_RTA\id_agree_legend"
keep if _m == 3
drop _m


********************************************************************************
do "$ROOT_P\select_agree.do"
********************************************************************************

sum rta_deep, d
replace rta_deep = 0 if rta_deep == .

/* Dicotomize to ease interpretation */
replace rta_deep = 1 if rta_deep > 1 

bys id_provision	: egen max_w		=     max(rta_deep )
drop if max_w == 0  /* Drop provision never active */
cap drop max_w


merge m:1 id_provision using "$TEMP_RTA\148_provisions_clust1" 
keep if _m == 3
drop _m


keep if rta_deep == 1



merge m:1 id_agree using "$TEMP_RTA\id_agree_legend" 
keep if _m == 3
drop _m

merge m:1 id_agree using "$RES\kmeans_estimate"
keep if _m == 3
drop _m

order id_provision Area id_agree agreement entry_force   kmeanPP2
keep  id_provision Area id_agree agreement entry_force   kmeanPP2
sort id_provision                 /* this goes into the table: 148_provision Agreement lists */

********************************************************************************
********************************************************************************

* New table for Nadia # 1 

cd $DATA


use rta_data_for_cluster, clear


merge m:1 id_agree using "$TEMP_RTA\id_agree_legend"
keep if _m == 3
drop _m


********************************************************************************
do "$ROOT_P\select_agree.do"
********************************************************************************

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


collapse (mean) num_provision agree_coverage (sum) coverage_*, by(Area)


********************************************************************************
********************************************************************************

* New table for Nadia # 2 

cd $DATA


use rta_data_for_cluster, clear


merge m:1 id_agree using "$TEMP_RTA\id_agree_legend"
keep if _m == 3
drop _m


********************************************************************************
do "$ROOT_P\select_agree.do"
********************************************************************************

sum rta_deep, d
replace rta_deep = 0 if rta_deep == .


bys id_provision: egen max_w = max(rta_deep)

drop if max_w == 0  /* Drop provision never active */

keep if Area =="Services"




merge m:1 id_provision using "$TEMP_RTA\id_provision_legend.dta" 
keep if _m == 3
drop _m

merge m:1 id_agree using "$RES\kmeans_estimate", keepusing(kmeanPP2)
keep if _m == 3
drop _m

tab id_provision if Area == "Services" & Section =="SUBSTANTIVE DISCIPLINES" & Subsection=="Others"

order Provision
ed if max == 6


keep if Area == "Services"

egen nvals_prov = nvals(id_prov)
keep if id_provision==850 | id_provision==836 | id_provision==837


merge m:1 id_agree using "$TEMP_RTA\id_agree_legend" 
keep if _m == 3
drop _m

order kmeanPP2 id_provision agreement id_agree rta_deep max

sort  id_agree id_provision
ed if kmeanPP2 ==1

ed if kmeanPP2 ==2

ed if kmeanPP2 ==3

/*Retrieve coverage and score from section above */
********************************************************************************
********************************************************************************

* Prepare data for Armando and Stefania

use "$RES\trade_8017_yearly.dta", clear

keep if year == 2017
keep iso_o iso_d id_agree rta type entry_force

merge m:1 id_agree using temp_agree_invest
drop if _m == 2
drop _m

replace invest_coverage = 0 if rta == 0
summ score_invest score_invest_std
replace score_invest = 0 if score_invest == .
drop score_invest_std
sum rta invest_coverage score_invest

save agree_invest, replace
