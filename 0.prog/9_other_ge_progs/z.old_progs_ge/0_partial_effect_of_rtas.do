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
*global iso "IDN"
local iso "$iso"

cap 	log close
capture log using "$PROG\00_log_files\partial_equilibriul_effects_`=$iso'", text replace


 cd "$RES\\`iso'\"
********************************************************************************
********************************************************************************
* select countries

use $ge_dataset , clear

bys iso_o: keep if _n == 1
keep iso_o
gen iso_d = iso_o

save "$RES\\`iso'\temp\cty_sample.dta", replace


********************************************************************************
********************************************************************************
* select distances

use "$GRAVITY_COV\dist_cepii_edit", clear





merge m:1 iso_o using "$RES\\`iso'\temp\cty_sample.dta", keepusing(iso_o)
keep if _m == 3
drop _m

merge m:1 iso_d using "$RES\\`iso'\temp\cty_sample.dta", keepusing(iso_d)
keep if _m == 3
drop _m




save "$RES\\`iso'\temp\temp_geo", replace




********************************************************************************
********************************************************************************
* Esti-bration: Agro+Man
********************************************************************************
********************************************************************************
 
use $ge_dataset , clear

gen iso3 = iso_o


merge m:1 iso3 using "$GRAVITY_COV\\WBregio.dta"
drop if _m == 2
drop _m

rename region region_o

cap drop iso3

gen iso3 = iso_d


merge m:1 iso3 using "$GRAVITY_COV\\WBregio.dta"
drop if _m == 2
drop _m

rename region region_d

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
********************************************************************************

egen expcode  		= group(iso_o  )
egen impcode  		= group(iso_d  )

gen sym_id1 		= expcode
gen sym_id2 		= impcode
replace sym_id1 	= impcode if impcode < expcode
replace sym_id2 	= expcode if impcode < expcode
egen sym_pair_id 	= group(sym_id1 sym_id2)

cap drop sym_id1
cap drop sym_id2
cap drop impcode
cap drop expcode

********************************************************************************
********************************************************************************
ppmlhdfe $trade_frictions  		rta_k1 rta_k2 rta_k3  rta_out	INTL_BRDR_*  						, a(FEij =sym_pair_id FEit= it FEjt=jt, savefe)  d
keep if e(sample)
predict y_hat  , mu
gen epsilon 		 	= ($trade_frictions / y_hat)

global beta1 = _b[rta_k1]
global beta2 = _b[rta_k2]
global beta3 = _b[rta_k3]


cap drop FE_combine
gen FE_combine = FEij+FEit+FEjt

cap drop comb_regressors_clus
gen   comb_regressors_clus    =   rta_out*_b[ rta_out] +  INTL_BRDR_1990*_b[ INTL_BRDR_1990 ] +  INTL_BRDR_2000*_b[ INTL_BRDR_2000 ] +  INTL_BRDR_2010*_b[ INTL_BRDR_2010 ]  + FE_combine 

cap drop comb_regressors_clus1
gen   comb_regressors_clus1    =   comb_regressors_clus +  rta_k2*_b[rta_k2]  +  rta_k3*_b[rta_k3]

cap drop comb_regressors_clus2
gen   comb_regressors_clus2    =   comb_regressors_clus +  rta_k1*_b[rta_k1]  +  rta_k3*_b[rta_k3]

cap drop comb_regressors_clus3
gen   comb_regressors_clus3    =   comb_regressors_clus +  rta_k1*_b[rta_k1]  +  rta_k2*_b[rta_k2]

ppmlhdfe $trade_frictions  		rta_k1     comb_regressors_clus1	, noabsorb
ppmlhdfe $trade_frictions  		rta_k2     comb_regressors_clus2	, noabsorb
ppmlhdfe $trade_frictions  		rta_k3     comb_regressors_clus3	, noabsorb


********************************************************************************
********************************************************************************
egen id_pta  = group(id_agree)    

gen beta_rta  = .
gen se_rta    = .

********************************************************************************
********************************************************************************
* Cluster # 1 

egen id_pta1 = group(id_agree)   if rta_k1 == 1
summ id_pta1, d
scalar max_k = `r(max)'


forvalues i = 1 (1)`=max_k'  { 


	disp `i' "/" `=max_k'


gen      rta_`i'  = (id_pta1 == `i') 	
gen  rta_not_`i'  = (rta_k1 - rta_`i')
	
summ   rta_`i' rta_not_`i'
tab rta     rta_`i'
tab rta     rta_not_`i'
tab rta_`i' rta_not_`i'
 
qui ppmlhdfe $trade_frictions   		rta_`i'	 rta_not_`i'	 comb_regressors_clus1	, noabsorb cluster(ij)

replace  beta_rta    = _b[rta_`i']                                   if id_pta1 == `i'
replace  se_rta  	 = _se[rta_`i']                                  if id_pta1 == `i'


cap drop rta_`i'
cap drop rta_not_`i'

 
 
}
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
* Cluster # 2 

egen id_pta2 = group(id_agree)   if rta_k2 == 1
summ id_pta2, d
scalar max_k = `r(max)'


forvalues i = 1 (1)`=max_k'  { 


	disp `i' "/" `=max_k'


gen      rta_`i'  = (id_pta2 == `i') 	
gen  rta_not_`i'  = (rta_k2 - rta_`i')
	
summ   rta_`i' rta_not_`i'
tab rta     rta_`i'
tab rta     rta_not_`i'
tab rta_`i' rta_not_`i'
 
qui ppmlhdfe $trade_frictions   		rta_`i'	 rta_not_`i'	 comb_regressors_clus2	, noabsorb cluster(ij)

replace  beta_rta    = _b[rta_`i']                                   if id_pta2 == `i'
replace  se_rta  	 = _se[rta_`i']                                  if id_pta2 == `i'


cap drop rta_`i'
cap drop rta_not_`i'

 
 
}
********************************************************************************
********************************************************************************
* Cluster # 3 

egen id_pta3 = group(id_agree)   if rta_k3 == 1
summ id_pta3, d
scalar max_k = `r(max)'


forvalues i = 1 (1)`=max_k'  { 


	disp `i' "/" `=max_k'


gen      rta_`i'  = (id_pta3 == `i') 	
gen  rta_not_`i'  = (rta_k3 - rta_`i')
	
summ   rta_`i' rta_not_`i'
tab rta     rta_`i'
tab rta     rta_not_`i'
tab rta_`i' rta_not_`i'
 
qui ppmlhdfe $trade_frictions   		rta_`i'	 rta_not_`i'	 comb_regressors_clus3	, noabsorb cluster(ij)

replace  beta_rta    = _b[rta_`i']                                   if id_pta3 == `i'
replace  se_rta  	 = _se[rta_`i']                                  if id_pta3 == `i'


cap drop rta_`i'
cap drop rta_not_`i'

 
 
}
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************


bys id_pta: egen tot_w = total(y_hat)


bys id_pta: keep if _n == 1

keep agreement kmeanPP2 id_agree beta_rta se_rta tot_w


save  partial_equilibrium_estimation, replace


********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
use  partial_equilibrium_estimation, clear
drop if id_agree == .
gen low  = beta_rta - 1.96* se_rta   /* t-stat with 9 dof and 5% ci*/
gen high = beta_rta + 1.96* se_rta


/*
bys kmeanPP2: egen tot_w_clus  = total(tot_w)
bys kmeanPP2:  gen     w_clus  = tot_w/tot_w_clus
bys kmeanPP2: egen    m_w_clus = mean(w_clus)
			   gen     correct = w_clus/m_w_clus

			   replace beta_rta=correct*beta_rta
			   replace low     =correct*low
			   replace high    =correct*high    
*/


********************************************************************************
********************************************************************************


summ low, 
global min  = round(`r(min)' , 0.1 )

summ high, 
global max  = round(`r(max)' , 0.1 )

*
if round(`r(max)' , 0.1 ) < 0 {
	
global max  =  0	
	
}

********************************************************************************
********************************************************************************

global      lab_beta1     = round(`=$beta1' , 0.01 )
global      lab_beta2     = round(`=$beta2' , 0.01 )
global      lab_beta3     = round(`=$beta3' , 0.01 )

********************************************************************************
********************************************************************************
********************************************************************************
cap drop  label_group
gen       label_group     =  agreement 
replace   label_group     = subinstr(label_group, ", Republic of", "",.) 
replace   label_group     = subinstr(label_group, ",", "",.) 
replace   label_group     = subinstr(label_group, " - ", "-",.) 
replace   label_group     = subinstr(label_group, "Enlargement", "",.) 

replace   label_group     = subinstr(label_group, "EC (12)", "EU12",.) 
replace   label_group     = subinstr(label_group, "EC (15)", "EU15",.) 
replace   label_group     = subinstr(label_group, "EC (25)", "EU25",.) 
replace   label_group     = subinstr(label_group, "EC (27)", "EU27",.) 
replace   label_group     = subinstr(label_group, "EU (28)", "EU28",.) 


replace   label_group     = subinstr(label_group, "European Free Trade Association (EFTA)-1971", "EFTA1971",.) 
replace   label_group     = subinstr(label_group, "European Free Trade Association (EFTA)-1984", "EFTA1984",.) 
replace   label_group     = subinstr(label_group, "European Free Trade Association (EFTA)-1993", "EFTA1993",.) 
replace   label_group     = subinstr(label_group, "European Free Trade Association (EFTA)-2017", "EFTA2017",.) 


replace   label_group     = subinstr(label_group, "ASEAN Free Trade Area (AFTA)", "AFTA",.) 
replace   label_group     = subinstr(label_group, "Asia Pacific Trade Agreement (APTA)", "APTA",.) 


replace   label_group     = subinstr(label_group, "Australia-New Zealand Closer Economic Relations Trade Agreement (ANZCERTA)", "ANZCERTA",.) 

replace   label_group     = subinstr(label_group, "Caribbean Community and Common Market (CARICOM)", "CARICOM", .)
replace   label_group     = subinstr(label_group, "Central European Free Trade Agreement (CEFTA) 2006", "CEFTA", .)
replace   label_group     = subinstr(label_group, "Common Economic Zone (CEZ)", "CEZ", .)
replace   label_group     = subinstr(label_group, "Commonwealth of Independent States (CIS)", "CIS", .)
replace   label_group     = subinstr(label_group, "Comprehensive and Progressive Agreement for Trans-Pacific Partnership (CPTPP)", "CPTPP", .)
replace   label_group     = subinstr(label_group, "Dominican Republic-Central America-United States Free Trade Agreement (CAFTA-DR)", "CAFTA-DR", .)
replace   label_group     = subinstr(label_group, "East African Community (EAC)", "EAC", .)
replace   label_group     = subinstr(label_group, "Economic Community of West African States (ECOWAS)", "ECOWAS", .)
replace   label_group     = subinstr(label_group, "Economic Cooperation Organization (ECO)", "ECO", .)
replace   label_group     = subinstr(label_group, "Economic and Monetary Community of Central Africa (CEMAC)", "CEMAC", .)
replace   label_group     = subinstr(label_group, "Eurasian Economic Community (EAEC)", "EAEC", .)
replace   label_group     = subinstr(label_group, "Eurasian Economic Union (EAEU)", "EAEU", .)
replace   label_group     = subinstr(label_group, "European Economic Area (EEA)", "EEA", .)
replace   label_group     = subinstr(label_group, "Global System of Trade Preferences among Developing Countries (GSTP)", "GSTP", .)
replace   label_group     = subinstr(label_group, "Gulf Cooperation Council (GCC)", "GCC", .)
replace   label_group     = subinstr(label_group, "North American Free Trade Agreement (NAFTA)", "NAFTA", .)
replace   label_group     = subinstr(label_group, "Pan-Arab Free Trade Area (PAFTA)", "PAFTA", .)
replace   label_group     = subinstr(label_group, "South Asian Free Trade Agreement (SAFTA)", "SAFTA", .)
replace   label_group     = subinstr(label_group, "South Asian Preferential Trade Arrangement (SAPTA)", "SAPTA", .)
replace   label_group     = subinstr(label_group, "South Pacific Regional Trade and Economic Cooperation Agreement (SPARTECA)", "SPARTECA", .)
replace   label_group     = subinstr(label_group, "Southern African Customs Union (SACU)", "SACU", .)
replace   label_group     = subinstr(label_group, "Southern African Development Community (SADC)", "SADC", .)
replace   label_group     = subinstr(label_group, "Southern Common Market (MERCOSUR)", "MERCOSUR", .)
replace   label_group     = subinstr(label_group, "Treaty on a Free Trade Area between members of the Commonwealth of Independent States (CIS)", "CIS", .)
replace   label_group     = subinstr(label_group, "West African Economic and Monetary Union (WAEMU)", "WAEMU", .)

replace   label_group     = subinstr(label_group, "Latin American Integration Association (LAIA)", "LAIA", .)
replace   label_group     = subinstr(label_group, "Central American Common Market (CACM)", "CACM", .)
replace   label_group     = subinstr(label_group, "Common Market for Eastern and Southern Africa (COMESA)", "COMESA", .)



  
 
 cap drop rank*
 sort kmeanPP2 beta_rta
 gen rank = _n
 
 
summ  rank, d
global mlab  = 		 `r(max)'
global step  = round(`r(max)'/10)

 
drop if id_agree == 19

********************************************************************************
preserve
bys id_agree: keep if _n == 1
keep id_agree label_group   rank 
save "$RES\\$iso\temp\test_graph_partial", replace
restore

********************************************************************************
********************************************************************************
preserve
 
 use "$RES\\$iso\temp\ge_ppml_data", clear

keep if iso_o =="$iso"
keep if rta   == 1
sort id_agree
keep id_agree 
merge m:1 id_agree using "$RES\\$iso\temp\test_graph_partial"
keep if _m == 3

duplicates  drop 
levelsof rank, local (custom) 
global add =  "`custom'"
keep id_agree
save "$RES\\$iso\temp\test_graph_partial", replace
restore

merge m:1 id_agree using "$RES\\$iso\temp\test_graph_partial"
gen id_iso =(_m==3)
 labmask rank, values(label_group)
********************************************************************************
********************************************************************************


tw  /*
*/  (rcap   low high  rank if id_iso==0  & kmeanPP2==1,  dcolor(white)    msymbol(Th) mcolor(dknavy*1 )      lcolor(dknavy*.25 ))  /*
*/  (dot    beta_rta rank  if id_iso==0  & kmeanPP2==1,  ndots(1)        msymbol(Th ) mcolor(dknavy*1 )     dotextend(no) )  /*
*/  (rcap   low high  rank if id_iso==0  & kmeanPP2==2,  dcolor(white)    msymbol(Dh) mcolor(dknavy*.75 )      lcolor(dknavy*.25 ))  /*
*/  (dot    beta_rta rank  if id_iso==0  & kmeanPP2==2,  ndots(1)        msymbol(Dh ) mcolor(dknavy*.75 )     dotextend(no) )  /*
*/  (rcap   low high  rank if id_iso==0  & kmeanPP2==3,  dcolor(white)    msymbol(Oh) mcolor(dknavy*.5 )      lcolor(dknavy*.25 ))  /*
*/  (dot    beta_rta rank  if id_iso==0  & kmeanPP2==3,  ndots(1)        msymbol(Oh ) mcolor(dknavy*.5 )     dotextend(no) )  /*
*/  (rcap   low high  rank if id_iso==1  , dcolor(white)    msymbol(D) mcolor(cranberry*1 )   lcolor(cranberry*.75 ))  /*
*/  (dot    beta_rta rank  if id_iso==1  ,  ndots(1)        msymbol(T ) mcolor(cranberry*1 )  dotextend(no) )  /*
*/, ylabel( `=$min' ($step) `=$max' ) yline( `=$beta1' `=$beta2' `=$beta3', lpattern(dash)  lcolor(gs10*.5)  ) /*
*/  yline(0 , lcolor(cranberry*.75)  )  /*
*/  ylabel(0 "0" `=$beta1' "$lab_beta1" `=$beta2' " " `=$beta3' "$lab_beta3",   add labsize(vsmall) angle(45) )   /*
*/  xlabel(   $add 	              , 	 valuelabel  alternate 			labsize(vsmall)   angle(45)     )  /*
 */ xtitle("") ytitle("") graphregion(margin(medium))  plotregion(lwidth(none) ) /*
*/ legend(label(1 "95% CI" ) label(2 "Deep") label(4 "Medium") label(6 "Shallow")  row(1) order(2 4 6)   region(lwidth(none) margin(medium) ) size(medium)   ) name(g2,replace)
gr export "RTA_partial_effect.png", as(png) replace
gr export "RTA_partial_effect.pdf", as(pdf) replace


********************************************************************************
********************************************************************************


tw  /*
*/  (rcap   low high  rank if id_iso==0 [w=tot_w], dcolor(white)    msymbol(Dh) mcolor(dknavy*1 )      lcolor(dknavy*.25 ))  /*
*/  (dot    beta_rta rank  if id_iso==0 [w=tot_w],  ndots(1)        msymbol(Th ) mcolor(dknavy*1 )     dotextend(no) )  /*
*/  (rcap   low high  rank if id_iso==1          , dcolor(white)    msymbol(D) mcolor(cranberry*1 )   lcolor(cranberry*.75 ))  /*
*/  (dot    beta_rta rank  if id_iso==1          ,  ndots(1)        msymbol(T ) mcolor(cranberry*1 )  dotextend(no) )  /*
*/, ylabel( `=$min' ($step) `=$max' ) yline( `=$beta1' `=$beta2' `=$beta3', lpattern(dash)  lcolor(gs10*.5)  ) /*
*/  yline(0 , lcolor(cranberry*.75)  )  /*
*/  ylabel(0 "0" `=$beta1' "$lab_beta1" `=$beta2' " " `=$beta3' "$lab_beta3",   add labsize(vsmall) angle(45) )   /*
*/  xlabel(   $add 	              , 	 valuelabel  alternate 			labsize(vsmall)   angle(45)     )  /*
 */ xtitle("") ytitle("") graphregion(margin(medium))  plotregion(lwidth(none) ) /*
*/ legend(label(1 "95% CI" ) label(2 "Estimates")  row(1) order(1 2)   region(lwidth(none) margin(medium) ) size(medium)   ) name(g2,replace) 
gr export "RTA_partial_effect_W.png", as(png) replace
gr export "RTA_partial_effect_W.pdf", as(pdf) replace



********************************************************************************
*******************************************************************************/
summ tot_w, d
replace tot_w    = . if tot_w <= r(p5)


tw  /*
*/  (rcap   low high  rank if id_iso==0 [w=tot_w], dcolor(white)    msymbol(Dh) mcolor(dknavy*1 )      lcolor(dknavy*.25 ))  /*
*/  (dot    beta_rta rank  if id_iso==0 [w=tot_w],  ndots(1)        msymbol(Th ) mcolor(dknavy*1 )     dotextend(no) )  /*
*/  (rcap   low high  rank if id_iso==1          , dcolor(white)    msymbol(D) mcolor(cranberry*1 )   lcolor(cranberry*.75 ))  /*
*/  (dot    beta_rta rank  if id_iso==1          ,  ndots(1)        msymbol(T ) mcolor(cranberry*1 )  dotextend(no) )  /*
**/, ylabel( `=$min' ($step) `=$max' ) yline( `=$beta1' `=$beta2' `=$beta3', lpattern(dash)  lcolor(gs10*.5)  ) /*
*/  yline(0 , lcolor(cranberry*.75)  )  /*
*/  ylabel(0 "0" `=$beta1' "$lab_beta1" `=$beta2' " " `=$beta3' "$lab_beta3",   add labsize(vsmall) angle(45) )   /*
*/  xlabel(   $add 	              , 	 valuelabel  alternate 			labsize(vsmall)   angle(45)     )  /*
 */ xtitle("") ytitle("") graphregion(margin(medium))  plotregion(lwidth(none) ) /*
*/ legend(label(1 "95% CI" ) label(2 "Estimates")  row(1) order(1 2)   region(lwidth(none) margin(medium) ) size(medium)   ) name(g2,replace) 
gr export "RTA_partial_effect_W_trim.png", as(png) replace
gr export "RTA_partial_effect_W_trim.pdf", as(pdf) replace 

********************************************************************************
********************************************************************************

drop if tot_w == .


tw  /*
*/  (rcap   low high  rank if id_iso==0  & kmeanPP2==1,  dcolor(white)    msymbol(Th) mcolor(dknavy*1 )      lcolor(dknavy*.25 ))  /*
*/  (dot    beta_rta rank  if id_iso==0  & kmeanPP2==1,  ndots(1)        msymbol(Th ) mcolor(dknavy*1 )     dotextend(no) )  /*
*/  (rcap   low high  rank if id_iso==0  & kmeanPP2==2,  dcolor(white)    msymbol(Dh) mcolor(dknavy*.75 )      lcolor(dknavy*.25 ))  /*
*/  (dot    beta_rta rank  if id_iso==0  & kmeanPP2==2,  ndots(1)        msymbol(Dh ) mcolor(dknavy*.75 )     dotextend(no) )  /*
*/  (rcap   low high  rank if id_iso==0  & kmeanPP2==3,  dcolor(white)    msymbol(Oh) mcolor(dknavy*.5 )      lcolor(dknavy*.25 ))  /*
*/  (dot    beta_rta rank  if id_iso==0  & kmeanPP2==3,  ndots(1)        msymbol(Oh ) mcolor(dknavy*.5 )     dotextend(no) )  /*
*/  (rcap   low high  rank if id_iso==1  , dcolor(white)    msymbol(D) mcolor(cranberry*1 )   lcolor(cranberry*.75 ))  /*
*/  (dot    beta_rta rank  if id_iso==1  ,  ndots(1)        msymbol(T ) mcolor(cranberry*1 )  dotextend(no) )  /*
*/, ylabel( `=$min' ($step) `=$max' ) yline( `=$beta1' `=$beta2' `=$beta3', lpattern(dash)  lcolor(gs10*.5)  ) /*
*/  yline(0 , lcolor(cranberry*.75)  )  /*
*/  ylabel(0 "0" `=$beta1' "$lab_beta1" `=$beta2' " " `=$beta3' "$lab_beta3",   add labsize(vsmall) angle(45) )   /*
*/  xlabel(   $add 	              , 	 valuelabel  alternate 			labsize(vsmall)   angle(45)     )  /*
 */ xtitle("") ytitle("") graphregion(margin(medium))  plotregion(lwidth(none) ) /*
*/ legend(label(1 "95% CI" ) label(2 "Deep") label(4 "Medium") label(6 "Shallow")  row(1) order(2 4 6)   region(lwidth(none) margin(medium) ) size(medium)   ) name(g2,replace)
gr export "RTA_partial_effect_trim.png", as(png) replace
gr export "RTA_partial_effect_trim.pdf", as(pdf) replace

********************************************************************************
********************************************************************************
