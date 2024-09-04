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
local X   "$year_reg"

cap 	log close
capture log using "$PROG\00_log_files\ge_exd2_`=$iso'", text replace


********************************************************************************
********************************************************************************
* GE
********************************************************************************
********************************************************************************
* clean directory 
cd "$RES\\`iso'\\temp"

local exd   : dir "`c(pwd)'"   files "*EXD2*.dta" 
local exdx  : dir "`c(pwd)'"   files "*EXD2*.xls" 


foreach file in `exd' `exdx'  { 
	erase `file'    
} 

********************************************************************************
********************************************************************************

cap 	log close  
capture log using "$PROG\00_log_files\ge_extd2_`=$iso'", text replace

cd     "$DATA"


use $dataset_am, clear


keep iso_o iso_d pair_id t decade exporter importer trade est_* tij_* gamma_* INTL_BRDR_* rta rta_* region_* id_agree agreement
 cd "$RES\\`iso'\\temp"

********************************************************************************
********************************************************************************

preserve
bys iso_o: keep if _n == 1
keep iso_o region_*
save "$RES\\`iso'\\temp\temp_regio.dta", replace
restore

********************************************************************************
********************************************************************************
merge m:1 iso_o iso_d   using "$RES\\`iso'\temp\temp_geo", keepusing(distwces contig colony comlang_ethno)
keep if _m == 3
drop _m

gen double	ln_DIST  		= ln(distwces)
gen double  ln_DIST_int  	= ln_DIST 		if exporter==importer
replace 	ln_DIST_int		= 0 			if exporter!=importer
rename 		contig    			CNTG
rename 		colony     			CLNY
rename 		comlang_ethno 		LANG


********************************************************************************
********************************************************************************

keep if 		      t== `X'

********************************************************************************
********************************************************************************

local decade = decade
display `decade'

generate tij_bln=tij_bar* exp($rta1_beta *rta_k1 + $rta2_beta *rta_k2 + $rta3_beta *rta_k3 + $rta_out_beta *rta_out  + est_INTL_BRDR_`decade'*INTL_BRDR_`decade' )

display $rta1_beta
display $rta2_beta
display $rta3_beta

display $rta_out_beta
display est_INTL_BRDR_`decade'


*******************************
*0. Domestic Trade*
*******************************


generate tij 	= gamma_ij_alt

*******************************
*1. Create aggregate variables*
*******************************

* Create aggregate output
bysort exporter t: egen Y = sum(trade)

* Create aggregate expenditure
bysort importer t: egen E = sum(trade)
		
****************************************
*2. Chose a country for reference group*
****************************************
gen E_R_BLN = E 				if importer == "$ref_cty"
replace exporter = "ZZZ" 		if exporter == "$ref_cty"
replace importer = "ZZZ" 		if importer == "$ref_cty"
bysort t: egen E_R = mean(E_R_BLN)


************************
*3 Create Fixed Effects*
************************
quietly tabulate exporter, gen(EXPORTER_FE)
quietly tabulate importer, gen(IMPORTER_FE)
******************************
*4. Set additional parameters*
******************************


save ge_ppml_data, replace


********************************************************************************
********************************************************************************
/* Define the extensive margin counterfactual looping (bisogna trasformare EU in 1cty)*/

use "$RES\\`iso'\\RTA_to_sign.dta", clear
keep if agreement == ""
drop if iso       == "`iso'"
egen avg_sh       = rowmean(*_mkts_sh)

********************************************************************************
if "$trim" == "Yes" {

drop if avg_sh <=  0.01

}

********************************************************************************
********************************************************************************

if "$selection_criteria" == "DS" {
keep if item=="demand" | item =="supply int good"
}

********************************************************************************

if "$selection_criteria" == "ALL" {
keep if item=="demand" | item =="supply"
}

********************************************************************************
********************************************************************************


keep iso rank item  

replace item = subinstr(item, " ", "_", .)
reshape wide rank, i(iso) j(item)  string

egen avg_rank = rowmean(rank*)

replace iso =  "EU28" if iso =="AUT" |	iso =="BEL" |	iso =="BGR" |	iso =="CYP" |	/*
*/                       iso =="CZE" |	iso =="DEU" |	iso =="DNK" |	iso =="ESP" |	/*
*/                       iso =="EST" |	iso =="FIN" |	iso =="FRA" |	iso =="GRC" |	/* 
*/                       iso =="HRV" |	iso =="HUN" |	iso =="IRL" |	iso =="ITA" |	/*
*/                       iso =="LTU" |	iso =="LVA" |	iso =="LUX" |   iso =="MLT" |	/*
*/						 iso =="NLD" |	iso =="POL" |	iso =="PRT" |	iso =="ROU" |	/*
*/                       iso =="SVK" |	iso =="SVN" |	iso =="SWE" 	

bys iso: keep if _n == 1 

sort avg_rank
gen rank  = _n
keep if rank <= $rank

levelsof iso, local (cnt) 

********************************************************************************
********************************************************************************
foreach counterfactual in $IDN_ad_hoc   {

global counterfactual = "`counterfactual'"
display "$counterfactual"


use ge_ppml_data, clear

* Estimate the standard gravity model 
ppml tij EXPORTER_FE* IMPORTER_FE* ln_DIST CNTG LANG CLNY if exporter != importer, cluster(pair_id)
     estimates store gravity_est  
    
	* Create the predicted values  
      predict tij_noRTA, mu
      replace tij_noRTA = 1 if exporter == importer

    * Replace the missing trade costs with predictions from the
    * standard gravity regression
     replace tij_bar = tij_noRTA if tij_bar == . 
     replace tij_bln = tij_bar * exp($rta1_beta *rta_k1 + $rta2_beta *rta_k2 + $rta3_beta *rta_k3 + $rta_out_beta *rta_out  + est_INTL_BRDR_`decade'*INTL_BRDR_`decade' ) if tij_bln == .
    
    * Specify the complete set of bilateral trade costs in log to
    * be used as a constraint in the PPML estimation of the 
    * structural gravity model
     generate ln_tij_bln = log(tij_bln)


  * Set the number of exporter fixed effects variables
  quietly ds EXPORTER_FE*
  global N = `: word count `r(varlist)'' 
  global N_1 = $N - 1 
 
  * Estimate the gravity model in the "baseline" scenario with the PPML
  * estimator constrained with the complete set of bilateral trade costs
  ppml trade EXPORTER_FE* IMPORTER_FE1-IMPORTER_FE$N_1 , iter(100) noconst offset(ln_tij_bln)
   predict tradehat_BLN, mu
 
 * Step I.b. Construct baseline indexes 
  * Based on the estimated exporter and importer fixed effects, create
  * the actual set of fixed effects
   forvalues i = 1 (1) $N_1 {
    quietly replace EXPORTER_FE`i' = EXPORTER_FE`i' * exp(_b[EXPORTER_FE`i'])
    quietly replace IMPORTER_FE`i' = IMPORTER_FE`i' * exp(_b[IMPORTER_FE`i'])
   }
   
  * Create the exporter and importer fixed effects for the country of 
  * reference (Germany)
   quietly replace EXPORTER_FE$N = EXPORTER_FE$N * exp(_b[EXPORTER_FE$N ])
   quietly replace IMPORTER_FE$N = IMPORTER_FE$N * exp(0)
   
  * Create the variables stacking all the non-zero exporter and importer 
  * fixed effects, respectively  
   egen exp_pi_BLN = rowtotal(EXPORTER_FE1-EXPORTER_FE$N )
   egen exp_chi_BLN = rowtotal(IMPORTER_FE1-IMPORTER_FE$N ) 

  * Compute the variable of bilateral trade costs, i.e. the fitted trade
  * value by omitting the exporter and importer fixed effects  
   generate tij_BLN = tij_bln   

  * Compute the outward and inward multilateral resistances using the 
  * additive property of the PPML estimator that links the exporter and  
  * importer fixed effects with their respective multilateral resistances
  * taking into account the normalisation imposed
   generate OMR_BLN = Y * E_R / exp_pi_BLN
   generate IMR_BLN = E / (exp_chi_BLN * E_R) 
   
  * Compute the estimated level of international trade in the baseline for
  * the given level of ouptput and expenditures   
   generate tempXi_BLN = tradehat_BLN if exporter != importer
    bysort exporter: egen Xi_BLN = sum(tempXi_BLN)
	 
	 
	

********************************************************************************	
********************************************************************************	
* Now compute as Trade : imports + exports 
********************************************************************************
********************************************************************************
	
	bysort importer: egen Mi_BLN 	 = sum(tempXi_BLN)

					gen  tempTi_BLN  = Xi_BLN + Mi_BLN 								if exporter == importer
   


   bysort exporter: egen Ti_BLN 	 = sum(tempTi_BLN)
  
   drop Mi_BLN
   drop tempXi_BLN
   drop tempTi_BLN

********************************************************************************
********************************************************************************
	  
   generate Y_BLN = Y
   generate E_BLN = E
* Step II: Define a conterfactual scenario
	* The counterfactual scenario consists in removing the impact of the NAFTA
	* by re-specifying the RTA variable with zeros for the country pairs 
	* associated with the NAFTA
********************************************************************************
********************************************************************************

cap drop rta_k1_cfl
cap drop rta_k2_cfl
cap drop rta_k3_cfl


gen 	 rta_k1_cfl 		= rta_k1
gen 	 rta_k2_cfl 		= rta_k2
gen 	 rta_k3_cfl 		= rta_k3

********************************************************************************
********************************************************************************
         
if    ("$counterfactual" != "EU28")        &  ("$counterfactual" != "MERCO")   &  ("$counterfactual" != "SACU")    /*
*/ &  ("$counterfactual" != "ECOWAS")      &  ("$counterfactual" != "EAC")     &  ("$counterfactual" != "GULF")    /*
*/ &  ("$counterfactual" != "EURASIA")     &  ("$counterfactual" != "EU28ASE") &  ("$counterfactual" != "RCEP")    /*
*/ &  ("$counterfactual" != "CANASE")      &  ("$counterfactual" != "DEV8")                                        {

  

replace  rta_k2_cfl  		= 1  if ( iso_o == "`iso'"    			 & iso_d == "`counterfactual'" )   & (exporter!= importer)   & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
replace  rta_k2_cfl  		= 1  if ( iso_o == "`counterfactual'"    & iso_d == "`iso'"            )   & (exporter!= importer)   & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
 
}

******************************************************************************** 
********************************************************************************
 
if "$counterfactual" == "EU28"  {

            gen eu   =  (id_agree == 235)
bys iso_o: egen eu_o = max(eu)

bys iso_d: egen eu_d = max(eu)

replace  rta_k2_cfl  		= 1  if ( iso_o == "`iso'"    			 & eu_d  == 1        )   & (exporter!= importer)  & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
replace  rta_k2_cfl  		= 1  if ( eu_o  == 1                     & iso_d == "`iso'"  )   & (exporter!= importer)  & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
 
}

******************************************************************************** 
********************************************************************************
 
if "$counterfactual" == "MERCO"  {

            gen multi      =  (id_agree == 21)
bys iso_o: egen multi_o    = max(multi)

bys iso_d: egen multi_d    = max(multi)

replace  rta_k2_cfl  	   = 1  if ( iso_o    == "`iso'"     & multi_d  == 1     )   & (exporter!= importer)  & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
replace  rta_k2_cfl  	   = 1  if ( multi_o  == 1           & iso_d == "`iso'"  )   & (exporter!= importer)  & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
 
}

********************************************************************************  
********************************************************************************
  
if "$counterfactual" == "SACU"  {

            gen multi      =  (id_agree == 126)
bys iso_o: egen multi_o    = max(multi)

bys iso_d: egen multi_d    = max(multi)

replace  rta_k2_cfl  	   = 1  if ( iso_o    == "`iso'"     & multi_d  == 1     )   & (exporter!= importer)  & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
replace  rta_k2_cfl  	   = 1  if ( multi_o  == 1           & iso_d == "`iso'"  )   & (exporter!= importer)  & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
 
}

********************************************************************************  
********************************************************************************
if "$counterfactual" == "ECOWAS"  {

            gen multi      =  (id_agree == 103)
bys iso_o: egen multi_o    = max(multi)

bys iso_d: egen multi_d    = max(multi)

replace  rta_k2_cfl  	   = 1  if ( iso_o    == "`iso'"     & multi_d  == 1     )   & (exporter!= importer)  & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
replace  rta_k2_cfl  	   = 1  if ( multi_o  == 1           & iso_d == "`iso'"  )   & (exporter!= importer)  & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
 
}
********************************************************************************  
********************************************************************************
if "$counterfactual" == "EAC"  {

            gen multi      =  (id_agree == 54)
bys iso_o: egen multi_o    = max(multi)

bys iso_d: egen multi_d    = max(multi)

replace  rta_k2_cfl  	   = 1  if ( iso_o    == "`iso'"     & multi_d  == 1     )   & (exporter!= importer)  & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
replace  rta_k2_cfl  	   = 1  if ( multi_o  == 1           & iso_d == "`iso'"  )   & (exporter!= importer)  & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
 
}
********************************************************************************  
********************************************************************************
if "$counterfactual" == "GULF"  {

            gen multi      =  (id_agree == 282)
bys iso_o: egen multi_o    = max(multi)

bys iso_d: egen multi_d    = max(multi)

replace  rta_k2_cfl  	   = 1  if ( iso_o    == "`iso'"     & multi_d  == 1     )   & (exporter!= importer)  & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
replace  rta_k2_cfl  	   = 1  if ( multi_o  == 1           & iso_d == "`iso'"  )   & (exporter!= importer)  & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
 
}

********************************************************************************  
********************************************************************************
if "$counterfactual" == "EURASIA"  {

            gen multi      =  (id_agree == 255)
bys iso_o: egen multi_o    = max(multi)

bys iso_d: egen multi_d    = max(multi)

replace  rta_k2_cfl  	   = 1  if ( iso_o    == "`iso'"     & multi_d  == 1     )   & (exporter!= importer)  & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
replace  rta_k2_cfl  	   = 1  if ( multi_o  == 1           & iso_d == "`iso'"  )   & (exporter!= importer)  & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
 
}

********************************************************************************  
********************************************************************************
if "$counterfactual" == "EU28ASE"  {

            gen multi      =  (id_agree == 25)
bys iso_o: egen multi_o    = max(multi)
bys iso_d: egen multi_d    = max(multi)

            gen eu         =  (id_agree == 235)
bys iso_o: egen eu_o       = max(eu)
bys iso_d: egen eu_d       = max(eu)


replace 	multi_o		   = 1 if eu_o == 1
replace 	multi_d		   = 1 if eu_d == 1

replace  rta_k2_cfl  	   = 1  if ( iso_o    == "`iso'"  & multi_d  == 1       )   & (exporter!= importer)   & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
replace  rta_k2_cfl  	   = 1  if ( multi_o  == 1        &  iso_d    == "`iso'")   & (exporter!= importer)   & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
 
}

********************************************************************************  
********************************************************************************
if "$counterfactual" == "RCEP"  {

merge m:1 iso_d using "$PROG\rcep.dta", keepusing(rcep_d )
drop  if _m == 2
drop _m

merge m:1 iso_o using "$PROG\rcep.dta", keepusing(rcep_o )
drop  if _m == 2
drop _m


replace  rta_k2_cfl  	   = 1  if ( iso_o    == "`iso'"     & rcep_d  == 1        )   & (exporter!= importer)  // & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
replace  rta_k2_cfl  	   = 1  if ( rcep_o   == 1           & iso_d   == "`iso'"  )   & (exporter!= importer)  // & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
 
}

********************************************************************************  
********************************************************************************
if "$counterfactual" == "CANASE"  {

            gen multi      =  (id_agree == 25)
bys iso_o: egen multi_o    = max(multi)
bys iso_d: egen multi_d    = max(multi)

replace multi_o			   = 1 if iso_o =="CAN"
replace multi_d			   = 1 if iso_d =="CAN"

replace  rta_k2_cfl  	   = 1  if ( iso_o    == "`iso'"     & multi_d  == 1     )   & (exporter!= importer)  & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
replace  rta_k2_cfl  	   = 1  if ( multi_o  == 1           & iso_d == "`iso'"  )   & (exporter!= importer)  & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
  
}

********************************************************************************  
********************************************************************************
if "$counterfactual" == "DEV8"  {

            gen multi_o    = 0
            gen multi_d    = 0

replace multi_o			   = 1 if (iso_o =="BGD") |  (iso_o =="EGY")  | (iso_o =="IRN") | (iso_o =="NGA") | (iso_o =="PAK") | (iso_o =="TUR")
replace multi_d			   = 1 if (iso_d =="BGD") |  (iso_d =="EGY")  | (iso_d =="IRN") | (iso_d =="NGA") | (iso_d =="PAK") | (iso_d =="TUR")

replace  rta_k2_cfl  	   = 1  if ( iso_o    == "`iso'"     & multi_d  == 1     )   & (exporter!= importer)  & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
replace  rta_k2_cfl  	   = 1  if ( multi_o  == 1           & iso_d == "`iso'"  )   & (exporter!= importer)  & (rta == 0 | (rta == 1 & strpos(agreement, "GSTP")))
    
}


********************************************************************************  
******************************************************************************** 
********************************************************************************  
******************************************************************************** 
  
 
replace  rta_k1_cfl         = 0 if rta_k2_cfl == 1  
replace  rta_k3_cfl         = 0 if rta_k2_cfl == 1

		* Constructing the counterfactual bilateral trade costs	by imposing the
		* constraints associated with the counterfactual scenario
		cap drop   tij_CFL
		generate tij_CFL = tij_bar * exp($rta1_beta *rta_k1_cfl + $rta2_beta *rta_k2_cfl + $rta3_beta *rta_k3_cfl + $rta_out_beta *rta_out  + est_INTL_BRDR_`decade'*INTL_BRDR_`decade' ) 

	

********************************************************************************	
********************************************************************************			
		
* Step III: Solve the counterfactual model

	* Step III.a.: Obtain conditional general equilibrium effects
	
	* (i):	Estimate the gravity model by imposing the constraints associated 
	* 		with the counterfactual scenario. The constraint is defined  
	* 		separately by taking the log of the counterfactual bilateral trade 
	* 		costs. The parameter of thisexpression will be constrainted to be 
	*		equal to 1 in the ppml estimator	
	
		* Specify the constraint in log
			generate ln_tij_CFL = log(tij_CFL)	
		
		* Re-create the exporters and imports fixed effects
			drop EXPORTER_FE* IMPORTER_FE*
			quietly tabulate exporter, generate(EXPORTER_FE)
			quietly tabulate importer, generate(IMPORTER_FE)

		* Estimate the constrained gravity model and generate predicted trade
		* value
		ppml trade EXPORTER_FE* IMPORTER_FE1-IMPORTER_FE$N_1 ,  noconst offset(ln_tij_CFL) iter(300)  
			predict tradehat_CDL, mu
	
	* (ii):	Construct conditional general equilibrium multilateral resistances
	
		* Based on the estimated exporter and importer fixed effects, create
		* the actual set of counterfactual fixed effects	
			forvalues i = 1(1)$N_1 {
				quietly replace EXPORTER_FE`i' = EXPORTER_FE`i' * exp(_b[EXPORTER_FE`i'])
				quietly replace IMPORTER_FE`i' = IMPORTER_FE`i' * exp(_b[IMPORTER_FE`i'])
			}
		
		* Create the exporter and importer fixed effects for the country of 
		* reference (Germany)
			quietly replace EXPORTER_FE$N = EXPORTER_FE$N * exp(_b[EXPORTER_FE$N ])
			quietly replace IMPORTER_FE$N = IMPORTER_FE$N * exp(0)
			
		* Create the variables stacking all the non-zero exporter and importer 
		* fixed effects, respectively		
			egen exp_pi_CDL  = rowtotal( EXPORTER_FE1-EXPORTER_FE$N )
			egen exp_chi_CDL = rowtotal( IMPORTER_FE1-IMPORTER_FE$N )
			
		* Compute the outward and inward multilateral resistances 				
			generate OMR_CDL = Y * E_R  / exp_pi_CDL
			generate IMR_CDL = E 		/ (exp_chi_CDL * E_R)
			
		* Compute the estimated level of conditional general equilibrium 
		* international trade for the given level of ouptput and expenditures		
			generate tempXi_CDL = tradehat_CDL if exporter != importer
				bysort exporter: egen Xi_CDL = sum(tempXi_CDL)

********************************************************************************	
********************************************************************************	
* Now compute as Trade : imports + exports 
********************************************************************************
********************************************************************************
	
	bysort importer: egen Mi_CDL 	 = sum(tempXi_CDL)

					gen  tempTi_CDL  = Xi_BLN + Mi_CDL 								if exporter == importer
   


   bysort exporter: egen Ti_CDL 	 = sum(tempTi_CDL)
  
   drop Mi_CDL
   drop tempXi_CDL
   drop tempTi_CDL

********************************************************************************
********************************************************************************				
				
				
				
				
				
				
				  

					
	* Step III.b: Obtain full endowment general equilibrium effects

		* Create the iterative procedure by specifying the initial variables, 
		* where s = 0 stands for the baseline (BLN) value and s = 1 stands for  
		* the conditional general equilibrium (CD) value
		
  		* The parameter phi links the value of output with expenditures
			bysort t: generate phi = E		/ Y if exporter == importer
			
			* Compute the change in bilateral trade costs resulting from the 
			* counterfactual
			generate change_tij = tij_CFL 	/ tij_BLN	

			* Re-specify the variables in the baseline and conditional scenarios
				* Output 
				generate Y_0 = Y
				generate Y_1 = Y
				
				* Expenditures, including with respect to the reference country   
				generate E_0 = E
				generate E_R_0 = E_R
				generate E_1 = E
				generate E_R_1 = E_R			
			
				* Predicted level of trade 
				generate tradehat_1 = tradehat_CDL

				
		* (i)	Allow for endogenous factory-gate prices
	
			* Re-specify the factory-gate prices under the baseline and 
			* conditional scenarios				
			generate exp_pi_0 = exp_pi_BLN
			generate tempexp_pi_ii_0 = exp_pi_0 if exporter == importer
				bysort importer: egen exp_pi_j_0 = mean(tempexp_pi_ii_0)
			generate exp_pi_1 = exp_pi_CDL
			generate tempexp_pi_ii_1 = exp_pi_1 if exporter == importer
				bysort importer: egen exp_pi_j_1 = mean(tempexp_pi_ii_1)
				drop tempexp_pi_ii_*
			generate exp_chi_0 		 = exp_chi_BLN	
			generate exp_chi_1 		 = exp_chi_CDL	
			
			* Compute the first order change in factory-gate prices	in the 
			* baseline and conditional scenarios
			generate change_pricei_0 = 0				
			generate change_pricei_1 = ((exp_pi_1 / exp_pi_0) / (E_R_1 / E_R_0))^(1/(1-$sigma_am))
			generate change_pricej_1 = ((exp_pi_j_1 / exp_pi_j_0) / (E_R_1 / E_R_0))^(1/(1-$sigma_am))
		
			* Re-specify the outward and inward multilateral resistances in the
			* baseline and conditional scenarios
			generate OMR_FULL_0 	 = Y_0 * E_R_0 / exp_pi_0
			generate IMR_FULL_0 	 = E_0 / (exp_chi_0 * E_R_0)		
			generate IMR_FULL_1 	 = E_1 / (exp_chi_1 * E_R_1)
			generate OMR_FULL_1 	 = Y_1 * E_R_1 / exp_pi_1
			
		* Compute initial change in outward and multilateral resitances, which 
		* are set to zero		
			generate change_IMR_FULL_1 = exp(0)		
			generate change_OMR_FULL_1 = exp(0)
		

	****************************************************************************
	******************** Start of the Iterative Procedure  *********************
	
	* Set the criteria of convergence, namely that either the standard errors or
	* maximum of the difference between two iterations of the factory-gate 
	* prices are smaller than 0.01, where s is the number of iterations	

	global thr  ="0.005"


save  "temp_iterative_data", replace	
	
 
do "$PROG\3_ge_simulations\0_iterative_procedure.do"

while  ($replic >= $runs ) {
    
use  "temp_iterative_data", clear
	
global 	 thr  =  $thr*(1.10)
	
do "$PROG\3_ge_simulations\0_iterative_procedure.do"
	
} 

			
********************************************************************************			
********************* End of the Iterative Procedure  **************************
********************************************************************************
	display $s 
		* (iv)	Construction of the "full endowment general equilibrium" 
		*		effects indexes
			* Use the result of the latest iteration S
			local S = $s - 2
			
	display `S' 
		*	forvalues i = 1 (1) $N_1 {
		*		quietly replace IMPORTER_FE`i' = IMPORTER_FE`i' * exp(_b[IMPORTER_FE`i'])
		*	}		
		* Compute the full endowment general equilibrium of factory-gate price
			generate change_pricei_FULL = ((exp_pi_`S' / exp_pi_0) / (E_R_`S' / E_R_0))^(1/(1-$sigma_am))		

		* Compute the full endowment general equilibrium of the value output
			generate Y_FULL = change_pricei_FULL  * Y_BLN

		* Compute the full endowment general equilibrium of the value of 
		* aggregate expenditures
			generate tempE_FULL = phi * Y_FULL if exporter == importer
				bysort importer: egen E_FULL = mean(tempE_FULL)
					drop tempE_FULL
			
		* Compute the full endowment general equilibrium of the outward and 
		* inward multilateral resistances 
			generate OMR_FULL = Y_FULL * E_R_`S' / exp_pi_`S'
			generate IMR_FULL = E_`S' / (exp_chi_`S' * E_R_`S')	

		* Compute the full endowment general equilibrium of the value of 
		* bilateral trade 
			generate X_FULL = (Y_FULL * E_FULL * tij_CFL) /(IMR_FULL * OMR_FULL)			
		
		* Compute the full endowment general equilibrium of the value of 
		* total international trade 
			generate tempXi_FULL = X_FULL if exporter != importer
				bysort exporter: egen Xi_FULL = sum(tempXi_FULL)
					

********************************************************************************	
********************************************************************************	
* Now compute as Trade : imports + exports 
********************************************************************************
********************************************************************************
	
	bysort importer: egen Mi_FULL 	 = sum(tempXi_FULL)

					gen  tempTi_FULL  = Xi_FULL + Mi_FULL 								if exporter == importer
   


   bysort exporter: egen Ti_FULL 	 = sum(tempTi_FULL)
  
   drop Mi_FULL
   drop tempXi_FULL
   drop tempTi_FULL

********************************************************************************
********************************************************************************							
					
					  
					
	* Save the conditional and general equilibrium effects results		
	save "2_RTAsEffects_FULLGE_`counterfactual'_`X'.dta", replace
	save "2_RTAsEffects_FULLGE.dta", replace

* Step IV: Collect, construct, and report indexes of interest
	use "2_RTAsEffects_FULLGE.dta", clear
		collapse(mean) OMR_FULL OMR_CDL OMR_BLN change_pricei_FULL Ti_* Xi_* Y_BLN Y_FULL phi, by(exporter)
			rename exporter country
			replace country = "$ref_cty" if country == "ZZZ"
			sort country
		
			* Percent change in full endowment general equilibrium of factory-gate prices
			*generate change_price_FULL = (1 - change_pricei_FULL) / 1 * 100
			generate change_price_FULL   = (change_pricei_FULL - 1 ) / 1 * 100

		* Percent change in full endowment general equilibirum of outward multilateral resistances
			generate change_OMR_CDL = (OMR_CDL^(1/(1-$sigma_am)) - OMR_BLN^(1/(1-$sigma_am))) / OMR_BLN^(1/(1-$sigma_am)) * 100
		
		* Percent change in full endowment general equilibrium of outward multilateral resistances			
			generate change_OMR_FULL = (OMR_FULL^(1/(1-$sigma_am)) - OMR_BLN^(1/(1-$sigma_am))) / OMR_BLN^(1/(1-$sigma_am)) * 100

		* Percent change in conditional general equilibrium of bilateral trade
			generate change_Xi_CDL = (Xi_CDL - Xi_BLN) / Xi_BLN * 100	
			
		* Percent change in full endowment general equilibrium of bilateral trade		
			generate change_Xi_FULL = (Xi_FULL - Xi_BLN) / Xi_BLN * 100

			generate change_Ti_FULL = (Ti_FULL - Ti_BLN) / Ti_BLN * 100

	
	save "2_RTAsEffects_FULL_PROD.dta", replace


	* Construct the percentage changes on import/consumption side
	use "2_RTAsEffects_FULLGE.dta", clear
		collapse(mean) IMR_FULL IMR_CDL IMR_BLN, by(importer)
			rename importer country
			replace country = "$ref_cty" if country == "ZZZ"
			sort country		

		* Conditional general equilibrium of inward multilateral resistances
			generate change_IMR_CDL = (IMR_CDL^(1/(1-$sigma_am)) - IMR_BLN^(1/(1-$sigma_am))) / IMR_BLN^(1/(1-$sigma_am)) * 100
			
		* Full endowment general equilibrium of inward multilateral resistances
			generate change_IMR_FULL = (IMR_FULL^(1/(1-$sigma_am)) - IMR_BLN^(1/(1-$sigma_am))) / IMR_BLN^(1/(1-$sigma_am)) * 100
	save "2_RTAsEffects_FULL_CONS.dta", replace

	* Merge the general equilibrium results from the production and consumption
	* sides
	use "2_RTAsEffects_FULL_PROD.dta", clear
		joinby country using "2_RTAsEffects_FULL_CONS.dta"
		
		* Full endowment general equilibrium of real GDP
			generate rGDP_BLN = Y_BLN / (IMR_BLN ^(1 / (1 -$sigma_am)))
			generate rGDP_FULL = Y_FULL / (IMR_FULL ^(1 / (1 -$sigma_am)))
				generate change_rGDP_FULL = (rGDP_FULL - rGDP_BLN) / rGDP_BLN * 100
			
		* Keep indexes of interest	
			keep country phi change_Xi_CDL change_Xi_FULL  change_Ti_FULL change_price_FULL change_IMR_FULL change_rGDP_FULL   rGDP_FULL  rGDP_BLN Xi_FULL  Xi_BLN Ti_FULL  Ti_BLN
			order country phi change_Xi_CDL change_Xi_FULL change_Ti_FULL change_price_FULL change_IMR_FULL change_rGDP_FULL  rGDP_FULL  rGDP_BLN Xi_FULL  Xi_BLN   Ti_FULL  Ti_BLN

 

			
	* Export the results in Excel
	     gen iso_o = country
		
merge 1:1 iso_o using "$RES\\`iso'\\temp\temp_regio.dta", keepusing(region_o)
keep if _m == 3
drop _m

		local sigma = "$sigma_am"
		gen sigma   = `sigma'
		
		gen replication = rep	
		gen sd_prices 	= sd_p	
		gen max_prices 	= max_p
		gen treshold 	= $thr

		gen trade_share = `X'
        gen count       = "`counterfactual'"
	    gen type        = "EXD2"	
	
	
		export excel using 	"`counterfactual'_EXD2_`X'_AM.xls", firstrow(variables) replace
	    save 				"`counterfactual'_EXD2_`X'_AM.dta", replace

}

cap log close
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************