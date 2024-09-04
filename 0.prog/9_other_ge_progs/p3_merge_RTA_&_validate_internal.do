
/******************************************************************************* 
	     The Economic Impact of Deepening Trade Agreements A Toolkit

			       	   this version: MAY 2024
				   
website: https://xxxxxxx.org/

when using the tool please cite:  
Fontagné, L., Rocha, N., Ruta, M., Santoni, G. (2023),
 "The Economic Impact of Deepening Trade Agreements", World Bank Economic Review,  

         https://doi.org/10.1093/wber/lhad005.  

corresponding author: gianluca.santoni@cepii.fr
 
*******************************************************************************/
********************************************************************************

clear *

   
set scheme s1color
set excelxlsxlargefile on
version

set seed 01032018

global seed "01032018"

******************************************************************************** 
* Needed 

*  ssc install wbopendata, replace

********************************************************************************
* Define your working path here: this is where you locate the "Toolkit" folder

 
  global DB	              "C:/Users/gianl/Dropbox/" 
  global DB              "d:/santoni/Dropbox/"


global ROOT 		      "$DB/WW_other_projs/WB_2024/WB_GE/WB_DTA_Toolkit"			 

global PROG_dta           "$ROOT/0.prog/0_datamake/000_DTA_progs" 
global PROG_trade         "$ROOT/0.prog/0_datamake/00_TRADE_progs"


* External data 
global BACI	        	  "$DB/WW_other_projs/DATA/BACI"
global GRAVITY        	  "$DB/WW_other_projs/DATA/GRAVITY"
global LANG               "$DB/WW_other_projs/DATA/LANG"


* Data within the Toolkit package
global DATA 	          "$ROOT/1.data"
global COMTRADE			  "$DATA/COMTRADE"	
global UNIDO			  "$DATA/UNIDO/2024"	
global FAO_prod			  "$DATA/FAO/prod/2024"	
global FAO_trade		  "$DATA/FAO/trade/2024"	
global FREIGHT			  "$DATA/trade_costs"	 	
global DTA                "$DATA"
global CTY                "$DATA/CTY"
global TEMP	     		  "$DATA/temp"


* Results
global CLUS	     		  "$ROOT/2.res/clusters"
global GRAV	     		  "$ROOT/2.res/gravity"


* External Data Versioning
global baci_version 	   "BACI_HS02_V202401b"
global grav_version 	   "Gravity_V202211"
global countries_gravity   "Countries_V202211"

global prod_version		   "indstat2_2024"
 

* Time span dataset
global year_start		  "1986"
global year_end           "2022"  // ATT: production data Manufacturing only up to 2021 (UNIDO 2024 Release)


*global cluster_var       "kmean kmedian pam h_clus kmeanR_ch kmeanR_asw kmeanR kmeanR_pam kmeanR_man"
global cluster_var        "kmean    kmedian kmean_sil kmedian_sil h_clus pam pamR_eucl  "
global type    			  "w"   				
global dist_lang          "lpn cnl lps csl cor dist distcap distw_harmonic distw_arithmetic contig comcol"
 // w: weighted provision matrix ; u: unweighted provision matrix (1/0)

global min_trade		  "100"  // strangely small trade values in Comtrade if less 100US$ drop obs in manufacturing
 
 
********************************************************************************
* this file is generated in 0_datamake/TRADE/03_merge_RTA_&_validate
use "$DATA/trade_rta_ver2024.dta", clear

global controls_od              "rta_out rta_psa wto_od"
global rta                      "rta_est"
global sym 						"sym"



gen mfn_od      = wto_od
replace mfn_od  = 0                     if  iso_o    == iso_d
replace mfn_od  = 0                     if   $rta    == 1
 

cap drop RTA_k*
cap drop rta_k*

qui tab kmean, gen(RTA_k )

replace RTA_k1 	    = 0                    if RTA_k1 == .
replace RTA_k2 	    = 0                    if RTA_k2 == .
replace RTA_k3      = 0                    if RTA_k3 == .

gen rta_k1          = $rta *RTA_k1
gen rta_k2          = $rta *RTA_k2
gen rta_k3          = $rta *RTA_k3

sum  kmean if id_agree == 117
global controls_od              "rta_out rta_psa "

ppml_panel_sg  agro_ieY_man_ieY      rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od  			if  es_iy   == 1 , ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)        
outreg2 using  "$GRAV/WTO_results.xls", dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "kmean"  , Deep, $deep  ) lab      replace  

global controls_od              "rta_out rta_psa wto_od"

ppml_panel_sg  agro_ieY_man_ieY      rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od  			if  es_iy   == 1 , ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)        
outreg2 using  "$GRAV/WTO_results.xls", dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "kmean"  , Deep, $deep  ) lab         
 
ppml_panel_sg  agro_ieY_man_ieY      rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od  			if  es_iy   == 1 , ex(iso_o) 	 im(iso_d) 		year(year) 		    cluster(ij)        
outreg2 using  "$GRAV/WTO_results.xls", dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "kmean"  , Deep, $deep  ) lab         
 
*******************************************************************************
global controls_od              "rta_out rta_psa"

ppml_panel_sg  agro_man      rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od  			if  es_ii   == 1 , ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)        
outreg2 using  "$GRAV/WTO_results.xls", dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "kmean"  , Deep, $deep  ) lab         

global controls_od              "rta_out rta_psa wto_od"

ppml_panel_sg  agro_man      rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od  			if  es_ii   == 1 , ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)        
outreg2 using  "$GRAV/WTO_results.xls", dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "kmean"  , Deep, $deep  ) lab         

ppml_panel_sg  agro_man      rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od  			if  es_ii   == 1 , ex(iso_o) 	 im(iso_d) 		year(year)  	    cluster(ij)        
outreg2 using  "$GRAV/WTO_results.xls", dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "kmean"  , Deep, $deep  ) lab         

  
*******************************************************************************
*******************************************************************************

ppml_panel_sg  agr_i       			 rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od   		if es_agr_i == 1, ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)        
outreg2 using  "$GRAV/Tresor_results.xls", dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "kmean"  , Deep, $deep  ) lab replace        

 
ppml_panel_sg   man_i      			 rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od   		if es_man_i == 1, ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)        
outreg2 using  "$GRAV/Tresor_results.xls", dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "kmean"  , Deep, $deep  ) lab        

ppml_panel_sg  agro_man      		 rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od  			if    es_ii == 1 , ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)        
outreg2 using  "$GRAV/Tresor_results.xls", dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "kmean"  , Deep, $deep  ) lab        

ppml_panel_sg  agro_ieY_man_ieY      rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od  			if  es_iy   == 1 , ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)        
outreg2 using  "$GRAV/Tresor_results.xls", dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "kmean"  , Deep, $deep  ) lab        

ppml_panel_sg  agro_ieY_man_ieY      rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od  			if  es_iy   == 1 , ex(iso_o) 	 im(iso_d) 		year(year)   	    cluster(ij)        
outreg2 using  "$GRAV/Tresor_results.xls", dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "kmean"  , Deep, $deep  ) lab        


********************************************************************************
* this is just for internal verification:
********************************************************************************
global controls_od              "rta_out rta_psa wto_od"
global rta                      "rta_est"
global sym 						" "




local s = 1 


*foreach var in h_clus kmean_rec kmedian pamR_eucl  avg_k     {	

foreach var in    kmean  kmedian h_clus pamR_eucl kmean_rec avg_k     {	
cap drop RTA_k*
cap drop rta_k*

qui tab `var', gen(RTA_k )

replace RTA_k1 	    = 0                    if RTA_k1 == .
replace RTA_k2 	    = 0                    if RTA_k2 == .
replace RTA_k3      = 0                    if RTA_k3 == .

gen rta_k1          = $rta *RTA_k1
gen rta_k2          = $rta *RTA_k2
gen rta_k3          = $rta *RTA_k3

sum  `var' if id_agree == 117
 
global deep=  r(mean)
 display "$deep"
 
foreach Y in      agro_ieY_man_ieY   {	

 ppml_panel_sg  `Y'      rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od   		if es_iy == 1, ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)        

if `s' == 1 {
 outreg2 using  "$GRAV/SG_2024_Validation.xls", dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"  , Deep, $deep  ) lab        
 }


 
if `s' > 1 {
 outreg2 using  "$GRAV/SG_2024_Validation.xls",   dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(Period, Full,  Cluster,  "`var'"  , Deep, $deep  ) lab       
}


local s = `s' + 1



}
}
*/

********************************************************************************
********************************************************************************
* This is for Africa PAPER

cap drop RTA_k*
cap drop rta_k*

qui tab kmean, gen(RTA_k )

replace RTA_k1 	    = 0                    if RTA_k1 == .
replace RTA_k2 	    = 0                    if RTA_k2 == .
replace RTA_k3      = 0                    if RTA_k3 == .

gen rta_k1          = $rta *RTA_k1
gen rta_k2          = $rta *RTA_k2
gen rta_k3          = $rta *RTA_k3

sum  kmean if id_agree == 117
 

ppml_panel_sg  agro_man            rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od  			if  es_ii   == 1 , ex(iso_o) 	 im(iso_d) 		year(year)   sym    cluster(ij)        
outreg2 using  "$GRAV/SG_2024_Validation.xls", dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(d_ij, sym,  Cluster,  "kmean"  , Deep, $deep  ) lab    replace     

 
ppml_panel_sg  agro_man            rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od  			if  es_ii   == 1 , ex(iso_o) 	 im(iso_d) 		year(year)    		cluster(ij)        
outreg2 using  "$GRAV/SG_2024_Validation.xls", dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(d_ij, Asym,  Cluster,  "kmean"  , Deep, $deep  ) lab          
 
  
 
ppml_panel_sg  agro_ieY_man_ieY      rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od  			if  es_iy   == 1 , ex(iso_o) 	 im(iso_d) 		year(year) 	 sym    cluster(ij)        
outreg2 using  "$GRAV/SG_2024_Validation.xls", dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(d_ij, sym,  Cluster,  "kmean"  , Deep, $deep  ) lab         
 
 
ppml_panel_sg  agro_ieY_man_ieY      rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od  			if  es_iy   == 1 , ex(iso_o) 	 im(iso_d) 		year(year) 	        cluster(ij)        
outreg2 using  "$GRAV/SG_2024_Validation.xls", dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(d_ij, Asym,  Cluster,  "kmean"  , Deep, $deep  ) lab         

ppmlhdfe     agro_ieY_man_ieY      rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od  			if  es_iy   == 1 , a(it jt ij)	        cluster(ij)   d      
predict lambda
matrix beta = e(b)
keep if e(sample)

ppml_fe_bias agro_ieY_man_ieY    rta_k1 rta_k2 rta_k3     	INTL_BRDR_*  	 $controls_od        , i(i_iso) j(j_iso) t(year) lambda(lambda) beta(beta)
outreg2 using  "$GRAV/SG_2024_Validation.xls", dec(3) 	keep(	rta_*	  $controls_od		   	INTL_BRDR_* ) addtext(d_ij, Asym,  Cluster,  "kmean"  , Deep, $deep  ) lab         

	

********************************************************************************
*******************************************************************************/
* Markers of Deep Agreements

* ssc install firthlogit

use "$DATA/trade_rta_ver2024.dta", clear

keep if kmean != .

bys id_agree: egen ctys  = nvals(iso_o)
bys id_agree: egen trade = mean(agro_ieY_man_ieY)

keep id_agree entry_force agreement kmean kmedian avg_k kmean_rec ctys trade
duplicates drop


merge m:1 id_agree using "$TEMP/rta_data_raw.dta", keepusing(Type)
drop if _m == 2                                                     // inactive RTAs
drop _m 
 
merge m:1 id_agree using "$CLUS/kmean_r_$type.dta" 
keep if _m == 3
drop _m
 
  
 
xtile year_bins = entry_force , nq(10)

bys year_bins: egen min = min(entry_force)
bys year_bins: egen max = max(entry_force)

tostring min, replace
tostring max, replace




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
label var rta_deep_std18 "Trade Facilitation"

qui tab kmean , gen(KPP_)
global provisions "rta_deep_std1-rta_deep_std18"

 foreach var of varlist rta_deep_std1-rta_deep_std18 {

 egen temp = std(`var')
 
replace `var' = temp
cap drop temp 
 
 }
 
 
//  rta_deep_std1 it is strange. ppml exclude this regressor to make sure the estimates exist. 
    ppml KPP_1 rta_deep_std1  ,   cluster(id_agree)     
 
 
 
 
foreach var of varlist rta_deep_std2-rta_deep_std18 {
    logit KPP_1 `var'  entry_force    ,   robust   or
    estimates store `var'    
}

  

* Plot the results using coefplot with specified formatting
coefplot (rta_deep_std2, label("Countervailing Duties")			 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) 	axis(1)	) ///
         (rta_deep_std3, label("Competition") 					 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std4, label("Environment") 					 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std5, label("Export Taxes")					 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std6, label("IPR") 							 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std7, label("Investment") 					 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std8, label("Labor Market")  				 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std9, label("Movement of Workers") 			 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std10, label("Movement of Capitals") 		 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std11, label("Public Procurement") 			 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std12, label("Rules of Origin") 				 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std13, label("SPS") 							 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std14, label("STE") 							 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std15, label("Services") 			         mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std16, label("Subsidies") 			         mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std17, label("TBT") 					         mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std18, label("Trade Facilitation") 	         mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///		
		 , keep(rta_deep_std*) plotregion(lwidth(none)) grid(between glcolor(gs15) glpattern(dash)) levels(90) xline(1, lcolor(cranberry) axis(1)) ///
    format(%9.3f) graphregion(margin(medium)) legend(off) eform
	
graph export "$GRAV/Tresor_deep_markers_logit.png", as(png) replace

********************************************************************************
 
foreach var of varlist rta_deep_std2-rta_deep_std18 {
    logit KPP_1 `var'  entry_force  if kmean == 1 | kmean == 2 ,   robust   or
    estimates store `var'    
}

  

* Plot the results using coefplot with specified formatting
coefplot (rta_deep_std2, label("Countervailing Duties")			 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) 	axis(1)	) ///
         (rta_deep_std3, label("Competition") 					 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std4, label("Environment") 					 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std5, label("Export Taxes")					 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std6, label("IPR") 							 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std7, label("Investment") 					 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std8, label("Labor Market")  				 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std9, label("Movement of Workers") 			 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std10, label("Movement of Capitals") 		 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std11, label("Public Procurement") 			 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std12, label("Rules of Origin") 				 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std13, label("SPS") 							 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std14, label("STE") 							 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std15, label("Services") 			         mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std16, label("Subsidies") 			         mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std17, label("TBT") 					         mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///
         (rta_deep_std18, label("Trade Facilitation") 	         mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med)) axis(1)) ///		
		 , keep(rta_deep_std*) plotregion(lwidth(none)) grid(between glcolor(gs15) glpattern(dash)) levels(90) xline(1, lcolor(cranberry) axis(1)) ///
    format(%9.3f) graphregion(margin(medium)) legend(off) eform
	
graph export "$GRAV/Tresor_deep_markers_logit1_2.png", as(png) replace

********************************************************************************
********************************************************************************

foreach var of varlist rta_deep_std2-rta_deep_std18 {
     ppml KPP_1   `var'  entry_force  ,   cluster(id_agree)        
    estimates store `var'    
}
 
 
* Plot the results using coefplot with specified formatting
coefplot (rta_deep_std2, label("Countervailing Duties")			 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std3, label("Competition") 					 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std4, label("Environment") 					 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std5, label("Export Taxes")					 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std6, label("IPR") 							 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std7, label("Investment") 					 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std8, label("Labor Market")  				 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std9, label("Movement of Workers") 			 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std10, label("Movement of Capitals") 		 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std11, label("Public Procurement") 			 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std12, label("Rules of Origin") 				 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std13, label("SPS") 							 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std14, label("STE") 							 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std15, label("Services") 			         mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std16, label("Subsidies") 			         mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std17, label("TBT") 					         mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std18, label("Trade Facilitation") 	         mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
   , keep(rta_deep_std*) plotregion(lwidth(none)) grid(between glcolor(gs15) glpattern(dash)) levels(90) xline(1, lcolor(cranberry)) ///
    format(%9.3f) graphregion(margin(medium)) legend(off) eform
	
graph export "$GRAV/Tresor_deep_markers_ppml.png", as(png) replace


 
foreach var of varlist rta_deep_std2-rta_deep_std18 {
     ppml KPP_1   `var'  entry_force  if kmean == 1 | kmean == 2 ,   cluster(id_agree)        
    estimates store `var'    
}
 
 
* Plot the results using coefplot with specified formatting
coefplot (rta_deep_std2, label("Countervailing Duties")			 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std3, label("Competition") 					 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std4, label("Environment") 					 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std5, label("Export Taxes")					 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std6, label("IPR") 							 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std7, label("Investment") 					 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std8, label("Labor Market")  				 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std9, label("Movement of Workers") 			 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std10, label("Movement of Capitals") 		 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std11, label("Public Procurement") 			 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std12, label("Rules of Origin") 				 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std13, label("SPS") 							 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std14, label("STE") 							 mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std15, label("Services") 			         mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std16, label("Subsidies") 			         mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std17, label("TBT") 					         mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
         (rta_deep_std18, label("Trade Facilitation") 	         mcolor(dknavy) m(Dh) msize(medium) ciopts(lcolor(dknavy*0.5) lwidth(med))) ///
   , keep(rta_deep_std*) plotregion(lwidth(none)) grid(between glcolor(gs15) glpattern(dash)) levels(90) xline(1, lcolor(cranberry)) ///
    format(%9.3f) graphregion(margin(medium)) legend(off) eform
	
graph export "$GRAV/Tresor_deep_markers_ppml1_2.png", as(png) replace

********************************************************************************
******************************************************************************** 