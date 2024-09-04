
clear all
program drop _all
macro drop _all
matrix drop _all
clear mata
clear matrix
   
set virtual on
set more off
set scheme s1color

set seed 20082015

global seed "20082015"


 global DB 			             "D:\Santoni\Dropbox"
 global DB      	             "C:\Users\gianl\Dropbox"
* global DB  		             "E:\Dropbox\"


********************************************************************************

global ROOT 	                 "$DB\WB_DTA_Toolkit"
global DATA 	                 "$ROOT\data"
global TEMP	                     "$DATA\temp"
global RES	                     "$ROOT\res\CPTPP\ge_res"
global RES_C                     "$ROOT\res\CPTPP\ge_res_c"
global GE 	 	                 "$DATA\ge"

********************************************************************************
********************************************************************************
* Parametrization of the GE Simulations

global t_ij_fix  = "NO"
********************************************************************************
if "$t_ij_fix"   == "yes"      {
global target  					"XXXX"



global cutoff  					"1.3"
}
********************************************************************************


global dataset 					"GE_data_estibrated_AM"
global year    					"2018" 
global ref_cty					"ZAF"
global sigma 					"5"

global rta1_beta 				"est_RTA1"
global rta2_beta 				"est_RTA2"
global rta3_beta 				"est_RTA3"

global rta_out_beta 			"est_RTA_out"


global PROG 	 				"$ROOT\prog\1_ge_simulations\CPTPP"
global counterfactual_prog      "counterfactual_cptpp_sept2021.do"

********************************************************************************


global threshold				"0.005"


 global year    				"2018" 
global cnt          			"rcep_cptpp rcep_new"

* global year    				"2018" 
* global cnt          			"cptpp_pre cptpp_pre_c"  /* run with 2017 */
  
********************************************************************************
********************************************************************************
* GE counterfactual
********************************************************************************
********************************************************************************


foreach counterfactual in $cnt {
foreach X in $year {
cd     "$GE"

use $dataset, clear
cap drop est_sample*
keep iso_o iso_d pair_id t decade exporter importer trade est_* tij_* gamma_* INTL_BRDR_*  rta_*   


********************************************************************************

merge m:1 iso_o iso_d using "$TEMP\temp_geo.dta", 
keep if _m == 3
drop _m



gen double	ln_DIST  		= ln(distwces)
gen double  ln_DIST_int  	= ln_DIST 		if exporter==importer
replace 	ln_DIST_int		= 0 			if exporter!=importer
rename 		contig    			CNTG
rename 		colony     			CLNY
rename 		comlang_ethno 		LANG


********************************************************************************

keep if t== `X'


gen year = t
merge m:1 iso_o year using "$TEMP/gravity_temp", keepusing(eu_o)
drop if _m ==2
drop _m


merge m:1 iso_d year using "$TEMP/gravity_temp", keepusing(eu_d)
drop if _m ==2
drop _m

********************************************************************************

local decade = decade
global decade `decade'
display `decade'

generate tij_bln=tij_bar* exp($rta1_beta *rta_k1 + $rta2_beta *rta_k2 + $rta3_beta *rta_k3 + $rta_out_beta *rta_out  + est_INTL_BRDR_`=$decade'*INTL_BRDR_`=$decade' )

display $rta1_beta
display $rta2_beta
display $rta3_beta

display $rta_out_beta
display est_INTL_BRDR_`=$decade'


*******************************
*0. Domestic Trade*
*******************************


generate tij 	= gamma_ij_alt

*******************************
*1. Create aggregate variables*
*******************************

* Create aggregate output
bysort exporter t: egen Y = total(trade)

* Create aggregate expenditure
bysort importer t: egen E = total(trade)
		
****************************************
*2. Chose a country for reference group*
****************************************
	gen E_R_BLN  = E 	 if importer == "$ref_cty"
replace exporter = "ZZZ" if exporter == "$ref_cty"
replace importer = "ZZZ" if importer == "$ref_cty"
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

save "$RES\ge_ppml_replication", replace


**************************
*II. GE Analysis in Stata*
**************************
*****************************
*Step 1: `Baseline' Scenario*
*****************************
***************************************
*Step 1.a: Estimate `Baseline' Gravity*
***************************************
* Load data
use ge_ppml_data, clear

* Estimate the standard gravity model 
ppml tij EXPORTER_FE* IMPORTER_FE* ln_DIST CNTG LANG CLNY if exporter != importer, cluster(pair_id) iter(300) difficult
     estimates store gravity_est  
    
	* Create the predicted values  
     predict tij_noRTA , mu  
	 
/*******************************************************************************
gen      			  ratio  = tij_bar/tij_noRTA

summ tij_bar if iso_d    =="$target", d
scalar upper_d = r(p95)

summ tij_bar if iso_o    =="$target", d
scalar upper_o = r(p95)

*	  replace tij_bln     = ((tij_noRTA*exp($rta1_beta *rta_k1 + $rta2_beta *rta_k2 + $rta3_beta *rta_k3 + $rta_out_beta *rta_out  + est_INTL_BRDR_`=$decade'*INTL_BRDR_`=$decade' )) + tij_bln)/2	   if iso_d   =="ISR"  & iso_o    =="PAL"
*     replace tij_bar 	  = (tij_noRTA + tij_bar)/2			 if iso_d   =="ISR"  & iso_o    =="PAL" 

	  
* 	 replace tij_bln = ((tij_noRTA*exp($rta1_beta *rta_k1 + $rta2_beta *rta_k2 + $rta3_beta *rta_k3 + $rta_out_beta *rta_out  + est_INTL_BRDR_`=$decade'*INTL_BRDR_`=$decade' )) + tij_bln)/2	 /*
*	 */                        if iso_d == "$target"  & ratio > $cutoff  & tij_bln>= upper_d  &  tij_bln != .  &  exporter != importer


* 	replace tij_bln = ((tij_noRTA*exp($rta1_beta *rta_k1 + $rta2_beta *rta_k2 + $rta3_beta *rta_k3 + $rta_out_beta *rta_out  + est_INTL_BRDR_`=$decade'*INTL_BRDR_`=$decade' )) + tij_bln)/2	/*
*	*/                         if iso_o  == "$target" & ratio > $cutoff  & tij_bln>= upper_o  &  tij_bln != .  &  exporter != importer


*   replace  tij_bar = (tij_noRTA + tij_bar)/2		   		      if iso_o    =="$target" & ratio > $cutoff    & tij_bln>= upper_o  &  tij_bln != .  
*   replace  tij_bar = (tij_noRTA + tij_bar)/2			          if iso_d    =="$target" & ratio > $cutoff    & tij_bln>= upper_d  &  tij_bln != .  

*******************************************************************************/
********************************************************************************

      replace tij_noRTA = 1 if exporter == importer

    * Replace the missing trade costs with predictions from the
    * standard gravity regression
     replace tij_bar = tij_noRTA if tij_bar == . 
     replace tij_bln = tij_bar * exp($rta1_beta *rta_k1 + $rta2_beta *rta_k2 + $rta3_beta *rta_k3 + $rta_out_beta *rta_out  + est_INTL_BRDR_`=$decade'*INTL_BRDR_`=$decade' ) if tij_bln == .
    
	 
	 
	 
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
  ppml trade EXPORTER_FE* IMPORTER_FE1-IMPORTER_FE$N_1 ,   noconst offset(ln_tij_bln)   iter(500)    difficult   
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
 
 
   bysort exporter: egen Xi_BLN = total(tempXi_BLN)
   drop tempXi_BLN
   generate Y_BLN = Y
   generate E_BLN = E
* Step II: Define a conterfactual scenario
	* The counterfactual scenario consists in removing the impact of the NAFTA
	* by re-specifying the RTA variable with zeros for the country pairs 
	* associated with the NAFTA
********************************************************************************

global counterfactual = "`counterfactual'"

display "$counterfactual"
********************************************************************************
cd "$PROG"
do "$counterfactual_prog"
********************************************************************************

		* Constructing the counterfactual bilateral trade costs	by imposing the
		* constraints associated with the counterfactual scenario
		generate tij_CFL = tij_bar * exp($rta1_beta *rta_k1_cfl + $rta2_beta *rta_k2_cfl + $rta3_beta *rta_k3_cfl + $rta_out_beta *rta_out  + est_INTL_BRDR_`=$decade'*INTL_BRDR_`=$decade' ) 
			
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
		
		ppml trade EXPORTER_FE* IMPORTER_FE1-IMPORTER_FE$N_1 ,  noconst offset(ln_tij_CFL)  iter(500)    difficult 
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
			generate 		  tempXi_CDL = tradehat_CDL if exporter != importer
			bysort exporter: egen Xi_CDL = total(tempXi_CDL)
			drop tempXi_CDL

					
	* Step III.b: Obtain full endowment general equilibrium effects

		* Create the iterative procedure by specifying the initial variables, 
		* where s = 0 stands for the baseline (BLN) value and s = 1 stands for  
		* the conditional general equilibrium (CD) value
		
  		* The parameter phi links the value of output with expenditures
			bysort t: generate phi  = E			/ Y 			if exporter == importer
			
			* Compute the change in bilateral trade costs resulting from the 
			* counterfactual
			generate change_tij 	= tij_CFL 	/ tij_BLN	

			* Re-specify the variables in the baseline and conditional scenarios
				* Output 
				generate Y_0 		= Y
				generate Y_1 		= Y
				
				* Expenditures, including with respect to the reference country   
				generate E_0 		= E
				generate E_R_0 		= E_R
				generate E_1 		= E
				generate E_R_1 		= E_R			
			
				* Predicted level of trade 
				generate tradehat_1 = tradehat_CDL

				
		* (i)	Allow for endogenous factory-gate prices
	
			* Re-specify the factory-gate prices under the baseline and 
			* conditional scenarios				
			generate exp_pi_0 		 		 = exp_pi_BLN
			generate tempexp_pi_ii_0 		 = exp_pi_0 if exporter == importer
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
			generate change_pricei_1 = ((exp_pi_1 / exp_pi_0)     / (E_R_1 / E_R_0))^(1/(1-$sigma))
			generate change_pricej_1 = ((exp_pi_j_1 / exp_pi_j_0) / (E_R_1 / E_R_0))^(1/(1-$sigma))
		
			* Re-specify the outward and inward multilateral resistances in the
			* baseline and conditional scenarios
			generate OMR_FULL_0 	 = Y_0 * E_R_0 / exp_pi_0
			generate IMR_FULL_0 	 = E_0         / (exp_chi_0 * E_R_0)		
			generate IMR_FULL_1 	 = E_1         / (exp_chi_1 * E_R_1)
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
		local s = 3	
		local sd_dif_change_pi = 1
		local max_dif_change_pi = 1
		
		global thr  = $threshold

/******************************************************************************		
*******************************************************************************		

if "$counterfactual" == "ECA_n" | "$counterfactual" == "EAP_b" {

global thr  ="0.0075"
		
}	

********************************************************************************

if  "$counterfactual" == "SA_b"    {

global thr  ="0.0125"
		
}
*******************************************************************************/
********************************************************************************

		local r = 1	

		while ((`sd_dif_change_pi' > $thr ) | (`max_dif_change_pi' > $thr )) &  ( `r' < 11 ) {		
		
		local s_1 = `s' - 1
		local s_2 = `s' - 2
		local s_3 = `s' - 3
		* (ii)	Allow for endogenous income, expenditures and trade	
			generate trade_`s_1' =  tradehat_`s_2' * change_pricei_`s_2' * change_pricej_`s_2' / (change_OMR_FULL_`s_2'*change_IMR_FULL_`s_2')

			
		* (iii)	Estimation of the structural gravity model
				drop EXPORTER_FE* IMPORTER_FE*
				quietly tabulate exporter, generate (EXPORTER_FE)
				quietly tabulate importer, generate (IMPORTER_FE)
			    ppml trade_`s_1' EXPORTER_FE* IMPORTER_FE*, offset(ln_tij_CFL) noconst iter(500)    difficult  
				predict tradehat_`s_1', mu
					
			* Update output & expenditure			
				bysort exporter:   egen Y_`s_1' = total(tradehat_`s_1')
				quietly    generate tempE_`s_1' = phi * Y_`s_1' 				if exporter == importer
				bysort importer:   egen E_`s_1' = mean(tempE_`s_1'    )
				quietly  generate tempE_R_`s_1' = E_`s_1' 						if importer == "ZZZ"
								 egen E_R_`s_1' = mean(tempE_R_`s_1'  )
				
			* Update factory-gate prices 
				forvalues i = 1(1)$N_1 {
					quietly replace EXPORTER_FE`i'   = EXPORTER_FE`i' * exp(_b[EXPORTER_FE`i'])
					quietly replace IMPORTER_FE`i'   = IMPORTER_FE`i' * exp(_b[IMPORTER_FE`i'])
				}
				quietly replace EXPORTER_FE$N        = EXPORTER_FE$N * exp(_b[EXPORTER_FE$N ])
							egen exp_pi_`s_1'        = rowtotal(EXPORTER_FE1-EXPORTER_FE$N ) 
				quietly 	generate tempvar1        = exp_pi_`s_1' 			if exporter == importer
				bysort importer: egen exp_pi_j_`s_1' = mean(tempvar1) 		
					
			* Update multilateral resistances
				generate change_pricei_`s_1'         = ((exp_pi_`s_1' / exp_pi_`s_2') / (E_R_`s_1' / E_R_`s_2'))^(1/(1-$sigma))
				generate change_pricej_`s_1'         = ((exp_pi_j_`s_1' / exp_pi_j_`s_2') / (E_R_`s_1' / E_R_`s_2'))^(1/(1-$sigma))
				generate OMR_FULL_`s_1' 	         = (Y_`s_1' * E_R_`s_1') / exp_pi_`s_1' 
				generate change_OMR_FULL_`s_1'       = OMR_FULL_`s_1' / OMR_FULL_`s_2'					
				egen 			 exp_chi_`s_1'       = rowtotal(IMPORTER_FE1-IMPORTER_FE$N )	
				generate 	IMR_FULL_`s_1' 	         = E_`s_1' / (exp_chi_`s_1' * E_R_`s_1')
				generate change_IMR_FULL_`s_1'       = IMR_FULL_`s_1' / IMR_FULL_`s_2'
				
			* Iteration until the change in factory-gate prices converges to zero
				generate dif_change_pi_`s_1' 		= change_pricei_`s_2' - change_pricei_`s_3'
					display "************************* iteration number " `s_2' " *************************"
						summarize dif_change_pi_`s_1', format
					display "**********************************************************************"
					display " "
						local sd_dif_change_pi = r(sd)
						local max_dif_change_pi = abs(r(max))	
						
			local s = `s' + 1
			drop temp* 
			local r = `r' + 1

			
	}

			scalar rep 		= `r'
			scalar sd_p		= `sd_dif_change_pi'
			scalar max_p	= `max_dif_change_pi'

********************* End of the Iterative Procedure  **********************
cd "$RES"
********************************************************************************
	display `s' 
		* (iv)	Construction of the "full endowment general equilibrium" 
		*		effects indexes
			* Use the result of the latest iteration S
			local S = `s' - 2
			
	display `S' 
		*	forvalues i = 1 (1) $N_1 {
		*		quietly replace IMPORTER_FE`i' = IMPORTER_FE`i' * exp(_b[IMPORTER_FE`i'])
		*	}		
		* Compute the full endowment general equilibrium of factory-gate price
			generate change_pricei_FULL  = ((exp_pi_`S' / exp_pi_0) / (E_R_`S' / E_R_0))^(1/(1-$sigma))		

		* Compute the full endowment general equilibrium of the value output
			generate Y_FULL 			 = change_pricei_FULL  * Y_BLN

		* Compute the full endowment general equilibrium of the value of 
		* aggregate expenditures
			generate tempE_FULL 		 = phi * Y_FULL if exporter == importer
			bysort importer: egen E_FULL = mean(tempE_FULL)
					drop tempE_FULL
			
		* Compute the full endowment general equilibrium of the outward and 
		* inward multilateral resistances 
			generate OMR_FULL            = Y_FULL * E_R_`S' / exp_pi_`S'
			generate IMR_FULL            = E_`S' / (exp_chi_`S' * E_R_`S')	

		* Compute the full endowment general equilibrium of the value of 
		* bilateral trade 
			generate X_FULL = (Y_FULL * E_FULL * tij_CFL) /(IMR_FULL * OMR_FULL)			
		
		* Compute the full endowment general equilibrium of the value of 
		* total international trade 
			generate tempXi_FULL = X_FULL if exporter != importer
				bysort exporter: egen Xi_FULL = sum(tempXi_FULL)
					drop tempXi_FULL
					
	* Save the conditional and general equilibrium effects results		
	save "2_RTAsEffects_FULLGE.dta", replace
	save "2_RTAsEffects_FULLGE_`counterfactual'.dta", replace

	

* Step IV: Collect, construct, and report indexes of interest
	use "2_RTAsEffects_FULLGE.dta", clear
		collapse(mean) OMR_FULL OMR_CDL OMR_BLN change_pricei_FULL Xi_* Y_BLN Y_FULL, by(exporter)
			rename exporter country
			replace country = "$CTY" if country == "ZZZ"
			sort country
		
			* Percent change in full endowment general equilibrium of factory-gate prices
			*generate change_price_FULL = (1 - change_pricei_FULL) / 1 * 100
			generate change_price_FULL   = (change_pricei_FULL - 1 ) / 1 * 100

		* Percent change in full endowment general equilibirum of outward multilateral resistances
			generate change_OMR_CDL 	 = (OMR_CDL^(1/(1-$sigma)) - OMR_BLN^(1/(1-$sigma))) / OMR_BLN^(1/(1-$sigma)) * 100
		
		* Percent change in full endowment general equilibrium of outward multilateral resistances			
			generate change_OMR_FULL 	 = (OMR_FULL^(1/(1-$sigma)) - OMR_BLN^(1/(1-$sigma))) / OMR_BLN^(1/(1-$sigma)) * 100

		* Percent change in conditional general equilibrium of bilateral trade
			generate change_Xi_CDL 		 = (Xi_CDL - Xi_BLN) / Xi_BLN * 100	
			
		* Percent change in full endowment general equilibrium of bilateral trade		
			generate change_Xi_FULL 	 = (Xi_FULL - Xi_BLN) / Xi_BLN * 100
	save "2_RTAsEffects_FULL_PROD.dta", replace


	* Construct the percentage changes on import/consumption side
	use "2_RTAsEffects_FULLGE.dta", clear
		collapse(mean) IMR_FULL IMR_CDL IMR_BLN, by(importer)
			rename importer country
			replace country = "$CTY" if country == "ZZZ"
			sort country		

		* Conditional general equilibrium of inward multilateral resistances
			generate change_IMR_CDL 	= (IMR_CDL^(1/(1-$sigma)) - IMR_BLN^(1/(1-$sigma))) / IMR_BLN^(1/(1-$sigma)) * 100
			
		* Full endowment general equilibrium of inward multilateral resistances
			generate change_IMR_FULL 	= (IMR_FULL^(1/(1-$sigma)) - IMR_BLN^(1/(1-$sigma))) / IMR_BLN^(1/(1-$sigma)) * 100
	save "2_RTAsEffects_FULL_CONS.dta", replace

	* Merge the general equilibrium results from the production and consumption
	* sides
	use "2_RTAsEffects_FULL_PROD.dta", clear
		joinby country using "2_RTAsEffects_FULL_CONS.dta"
		
		* Full endowment general equilibrium of real GDP
			generate rGDP_BLN 			= Y_BLN  / (IMR_BLN  ^(1  / (1 -$sigma)))
			generate rGDP_FULL 			= Y_FULL / (IMR_FULL ^(1 / (1 -$sigma)))
			generate change_rGDP_FULL 	= (rGDP_FULL - rGDP_BLN) / rGDP_BLN * 100
			
		* Keep indexes of interest	
			keep country change_Xi_CDL change_Xi_FULL change_price_FULL change_IMR_FULL change_rGDP_FULL   rGDP_FULL  rGDP_BLN Xi_FULL  Xi_BLN
			order country change_Xi_CDL change_Xi_FULL change_price_FULL change_IMR_FULL change_rGDP_FULL  rGDP_FULL  rGDP_BLN Xi_FULL  Xi_BLN


			
	* Export the results in Excel
	     gen iso_o = country
		
merge 1:1 iso_o using "$TEMP\temp_regio.dta", keepusing(region_o)
keep if _m == 3
drop _m

********************************************************************************
if "$counterfactual"    == "rcep_cptpp" | "$counterfactual"    == "rcep_new" {
* Add China to cptpp: cluster 2

merge m:1 iso_o using "$PROG\cptpp.dta", keepusing(cptpp_o )
drop  if _m == 2
drop _m

}

********************************************************************************
if "$counterfactual"    == "rcep_new"  {
* Add China to cptpp: cluster 2

merge m:1 iso_o using "$PROG\rcep.dta", keepusing(rcep_o )
drop  if _m == 2
drop _m

}
********************************************************************************
********************************************************************************
		local sigma     = "$sigma"
		gen sigma       = `sigma'
		
		gen replication = rep	
		gen sd_prices 	= sd_p	
		gen max_prices 	= max_p
		gen year 		= `X'

		
		export excel using 	"`counterfactual'_FULL_`sigma'.xls", firstrow(variables) replace
	    save 				"`counterfactual'_FULL_`sigma'.dta", replace

}
}

********************************************************************************
********************************************************************************
