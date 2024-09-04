/******************************************************************************* 
*******************************************************************************/
local iso "$iso"

cap 	log close
capture log using "$LOG/3_ge_simulations/ge_int_ext_`=$iso'", text replace


if "$preliminary"   == "on" {



********************************************************************************
********************************************************************************
* Esti-bration: Agro+Man
********************************************************************************
********************************************************************************
 
use $ge_dataset , clear
 

cap drop  RTA_k*
cap drop  rta_k*
qui tab $kmean_alg , gen(RTA_k )

replace RTA_k1 	    = 0                    if RTA_k1 == .
replace RTA_k2 	    = 0                    if RTA_k2 == .
replace RTA_k3      = 0                    if RTA_k3 == .

gen rta_k1          =  $rta *RTA_k1
gen rta_k2          =  $rta *RTA_k2
gen rta_k3          =  $rta *RTA_k3


*ppml_panel_sg $trade   		$rta 				   	INTL_BRDR_*  $controls_od		, ex(iso_o) 	 im(iso_d) 		year(year)  $sym    cluster(ij)    
*outreg2 using  "$RES//`iso'//Structural_Gravity.xls",   dec(3) keep( $rta		$controls_od		     	INTL_BRDR_* ) addtext(Period, Full, Dependent, $trade_frictions  ) lab     

ppml_panel_sg $trade  		rta_k*				   	INTL_BRDR_*	$controls_od	, ex(iso_o) 	 im(iso_d) 		year(year)   $sym    genD(gamma_ij_alt)  predict(y_hat)  cluster(ij)    
outreg2 using  "$RES//`iso'//Structural_Gravity.xls",   dec(3) keep( rta_k*	$controls_od			   	INTL_BRDR_* ) addtext(Period, Full, Dependent, $trade_frictions  ) lab    replace

********************************************************************************

gen    est_RTA1 	= _b[rta_k1]
gen    est_RTA2  	= _b[rta_k2]
gen    est_RTA3  	= _b[rta_k3]
gen    est_RTA_out 	= _b[rta_out]
gen    est_wto   	= _b[$wto   ]



cap gen     est_INTL_BRDR_1990  	= _b[INTL_BRDR_1990]
cap gen     est_INTL_BRDR_2000 		= _b[INTL_BRDR_2000]
cap gen     est_INTL_BRDR_2010 		= _b[INTL_BRDR_2010]


********************************************************************************
********************************************************************************
 
gen trade 				= $trade


replace gamma_ij_alt 	= . 						if gamma_ij_alt == 0 | gamma_ij_alt <= 0.00001

gen epsilon 		 	= ($trade / y_hat)
 
generate check_exp		=exp(ln(gamma_ij_alt) +  ln(epsilon))

generate tij_bar		=(gamma_ij_alt)*(epsilon)

corr tij_bar check_exp
cap drop check_exp

   

replace  tij_bar        = gamma_ij_alt    if  trade ==0


********************************************************************************
if "$estibration"       =="No" {
    
	cap drop    tij_bar  
	
	gen tij_bar         = gamma_ij_alt        
	
}
********************************************************************************

cap drop t
rename year   t
gen   exporter = iso_o
gen   importer = iso_d


cap drop pair_id

rename ij pair_id


label data "This version  $S_TIME  $S_DATE "


cd "$RES\\`iso'\"

drop if t > $year_GE_end

save $dataset_am, replace
cap log close

}

*******************************************************************************/
********************************************************************************
* GE
********************************************************************************
********************************************************************************
* clean directory 
cd "$RES//`iso'//temp"


local int   : dir "`c(pwd)'"   files "*INT*.dta" 
local intx  : dir "`c(pwd)'"   files "*INT*.xls" 

local ext   : dir "`c(pwd)'"   files "*EXT*.dta" 
local extx  : dir "`c(pwd)'"   files "*EXT*.xls" 


local ge    : dir "`c(pwd)'"   files "*RTAsEffects_FULL*.dta" 


foreach file in `ext' `extx' `int'  `intx'  `ge' { 
	erase `file'    
} 

********************************************************************************
********************************************************************************


cd "$RES//`iso'/"

cap 	log close  
capture log using "ge_analysis", text replace

use $dataset_am, clear


keep iso_o iso_d pair_id t decade exporter importer trade est_* tij_* gamma_* INTL_BRDR_* $rta rta_* region_* id_agree agreement $dist_lang $controls_od 
 cd "$RES//`iso'//temp"

********************************************************************************
********************************************************************************

preserve
bys iso_o: keep if _n == 1
keep iso_o region_*
save "$RES//`iso'//temp/temp_regio.dta", replace
restore

********************************************************************************
********************************************************************************

gen double	ln_DIST  		= ln(distw_harmonic )
gen double  ln_DIST_int  	= ln_DIST 		if exporter==importer
replace 	ln_DIST_int		= 0 			if exporter!=importer
replace 	ln_DIST  		= 0 			if exporter==importer

gen double	LANG            = (lpn + cnl + cor)/3

gen double  LANG_int     	= LANG   		if exporter==importer
replace 	LANG_int		= 0 			if exporter!=importer
replace 	LANG    		= 0 			if exporter==importer

rename 		contig    			CNTG
rename 		comcol     			CLNY
gen         HOME            = ( exporter==importer)


********************************************************************************
********************************************************************************

 
keep if 		      t== $year_reg

********************************************************************************
********************************************************************************

local decade = decade
display `decade'
global decade "`decade'"
generate tij_bln=tij_bar* exp($rta1_beta *rta_k1 + $rta2_beta *rta_k2 + $rta3_beta *rta_k3 + $rta_out_beta *rta_out   + $wto_beta * $wto + est_INTL_BRDR_$decade *INTL_BRDR_$decade )

display $rta1_beta
display $rta2_beta
display $rta3_beta

display $rta_out_beta
display est_INTL_BRDR_$decade


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
* select the intensive margin counterfactual looping over existing id_agree 
use ge_ppml_data, clear

keep if iso_o =="`iso'"
keep if $rta   == 1
sort id_agree
levelsof id_agree, local (cnt) 
display "`cnt'"

********************************************************************************
********************************************************************************
*This is for the Intensive margin counterfactuals
foreach counterfactual in `cnt' {

global counterfactual = "`counterfactual'"
display "$counterfactual"


use ge_ppml_data, clear

* Estimate the standard gravity model 
ppml tij EXPORTER_FE* IMPORTER_FE* CNTG CLNY ln_DIST ln_DIST_int LANG_int LANG, noconst cluster(pair_id)
     estimates store gravity_est  
    
	* Create the predicted values  
      predict tij_noRTA, mu
    * replace tij_noRTA = 1 if exporter == importer

    * Replace the missing trade costs with predictions from the
    * standard gravity regression
     replace tij_bar = tij_noRTA if tij_bar == . 
     replace tij_bln = tij_bar * exp($rta1_beta *rta_k1 + $rta2_beta *rta_k2 + $rta3_beta *rta_k3 + $rta_out_beta *rta_out +  $wto_beta * $wto + est_INTL_BRDR_$decade *INTL_BRDR_$decade  ) if tij_bln == .
    
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
   replace tradehat_BLN = round(tradehat_BLN, .000001)

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

 
replace  rta_k1_cfl  		= 1  if (exporter!= importer) & (id_agree == `counterfactual' ) 

 
replace  rta_k2_cfl         = 0 if rta_k1_cfl == 1  
replace  rta_k3_cfl         = 0 if rta_k1_cfl == 1

		* Constructing the counterfactual bilateral trade costs	by imposing the
		* constraints associated with the counterfactual scenario
		cap drop   tij_CFL
		generate tij_CFL = tij_bar * exp($rta1_beta *rta_k1_cfl + $rta2_beta *rta_k2_cfl + $rta3_beta *rta_k3_cfl + $rta_out_beta *rta_out +  $wto_beta * $wto + est_INTL_BRDR_$decade * INTL_BRDR_$decade  ) 

	

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
	    replace tradehat_CDL = round(tradehat_CDL, .000001)

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
	
  
do "$PROG_ge/0_iterative_procedure_v2024.do"

while  ($replic >= $runs ) {
    
use  "temp_iterative_data", clear
	
global 	 thr  =  $thr*(1.10)
	
do "$PROG_ge/0_iterative_procedure_v2024.do"
	
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
		
merge 1:1 iso_o using "$RES//`iso'//temp/temp_regio.dta", keepusing(region_o)
keep if _m == 3
drop _m

		local sigma 	= "$sigma_am"
		gen sigma   	= `sigma'
		
		gen replication = rep	
		gen sd_prices 	= sd_p	
		gen max_prices 	= max_p
		gen treshold 	= $thr
		gen trade_share = $year_reg
        gen count       = "`counterfactual'"
	    gen type        = "INT"	
		
		export excel using 	"`counterfactual'_INT_`X'_AM.xls", firstrow(variables) replace
	    save 				"`counterfactual'_INT_`X'_AM.dta", replace

}
********************************************************************************
********************************************************************************
use ge_ppml_data, clear

keep if iso_o =="`iso'"
keep if $rta   == 1
sort id_agree
levelsof id_agree, local (cnt) 
display "`cnt'"
********************************************************************************
*This is for the Intensive margin counterfactuals
foreach counterfactual in `cnt' {

global counterfactual = "`counterfactual'"
display "$counterfactual"


use ge_ppml_data, clear

* Estimate the standard gravity model 
ppml tij EXPORTER_FE* IMPORTER_FE* CNTG CLNY ln_DIST ln_DIST_int LANG_int LANG, noconst cluster(pair_id)
     estimates store gravity_est  
    
	* Create the predicted values  
      predict tij_noRTA, mu
    * replace tij_noRTA = 1 if exporter == importer

    * Replace the missing trade costs with predictions from the
    * standard gravity regression
     replace tij_bar = tij_noRTA if tij_bar == . 
     replace tij_bln = tij_bar * exp($rta1_beta *rta_k1 + $rta2_beta *rta_k2 + $rta3_beta *rta_k3 + $rta_out_beta *rta_out +  $wto_beta * $wto + est_INTL_BRDR_$decade *INTL_BRDR_$decade  ) if tij_bln == .
        
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
   replace tradehat_BLN = round(tradehat_BLN, .000001)

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

 
replace  rta_k1_cfl  		= 0  if (exporter!= importer) & (id_agree == `counterfactual' ) & rta_k1_cfl == 1
replace  rta_k2_cfl  		= 0  if (exporter!= importer) & (id_agree == `counterfactual' ) & rta_k2_cfl == 1
replace  rta_k3_cfl  		= 0  if (exporter!= importer) & (id_agree == `counterfactual' ) & rta_k3_cfl == 1
 
		* Constructing the counterfactual bilateral trade costs	by imposing the
		* constraints associated with the counterfactual scenario
		cap drop   tij_CFL
		generate tij_CFL = tij_bar * exp($rta1_beta *rta_k1_cfl + $rta2_beta *rta_k2_cfl + $rta3_beta *rta_k3_cfl + $rta_out_beta *rta_out +  $wto_beta * $wto + est_INTL_BRDR_$decade *INTL_BRDR_$decade ) 

	


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
		replace tradehat_CDL = round(tradehat_CDL, .000001)

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
	
 
do "$PROG_ge/0_iterative_procedure_v2024.do"

while  ($replic >= $runs ) {
    
use  "temp_iterative_data", clear
	
global 	 thr  =  $thr*(1.10)
	
do "$PROG_ge/0_iterative_procedure_v2024.do"
	
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
		
merge 1:1 iso_o using "$RES//`iso'//temp/temp_regio.dta", keepusing(region_o)
keep if _m == 3
drop _m

		local sigma 	= "$sigma_am"
		gen sigma   	= `sigma'
		
		gen replication = rep	
		gen sd_prices 	= sd_p	
		gen max_prices 	= max_p
		gen treshold 	= $thr
		gen trade_share = $year_reg
        gen count       = "`counterfactual'"
	    gen type        = "INT_O"	
		
		export excel using 	"`counterfactual'_INT0_`X'_AM.xls", firstrow(variables) replace
	    save 				"`counterfactual'_INT0_`X'_AM.dta", replace

}

********************************************************************************
********************************************************************************

 do "$PROG_ge/1_ge_analysis_endog_k1.do"     // this do Deep    PTAs
 do "$PROG_ge/1_ge_analysis_endog_k2.do"     // this do Medium PTAs
 do "$PROG_ge/1_ge_analysis_endog_k3.do"     // this do Shallow PTAs

 
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************