

********************************************************************************
********************************************************************************
		local s = 3	
		local sd_dif_change_pi = 1
		local max_dif_change_pi = 1
		
		local r = 1	

		while ((`sd_dif_change_pi' > $thr ) | (`max_dif_change_pi' > $thr )) &  ( `r' <  $runs ) {		
		
		local s_1 = `s' - 1
		local s_2 = `s' - 2
		local s_3 = `s' - 3
		
		* (ii)	Allow for endogenous income, expenditures and trade	
			generate trade_`s_1' =  tradehat_`s_2' * change_pricei_`s_2' * change_pricej_`s_2' / (change_OMR_FULL_`s_2'*change_IMR_FULL_`s_2')

			
		* (iii)	Estimation of the structural gravity model
				drop EXPORTER_FE* IMPORTER_FE*
				quietly tabulate exporter, generate (EXPORTER_FE)
				quietly tabulate importer, generate (IMPORTER_FE)
		qui	 ppml trade_`s_1' EXPORTER_FE* IMPORTER_FE1-IMPORTER_FE$N_1 , offset(ln_tij_CFL) noconst iter(300)   difficult
				predict tradehat_`s_1', mu
					
			* Update output & expenditure			
				bysort exporter: egen Y_`s_1' = total(tradehat_`s_1')
				quietly generate tempE_`s_1' = phi * Y_`s_1' if exporter == importer
					bysort importer: egen E_`s_1' = mean(tempE_`s_1')
				quietly generate tempE_R_`s_1' = E_`s_1' if importer == "ZZZ"
					egen E_R_`s_1' = mean(tempE_R_`s_1')
				
			* Update factory-gate prices 
				forvalues i = 1(1)$N_1 {
					quietly replace EXPORTER_FE`i' = EXPORTER_FE`i' * exp(_b[EXPORTER_FE`i'])
					quietly replace IMPORTER_FE`i' = IMPORTER_FE`i' * exp(_b[IMPORTER_FE`i'])
				}
					quietly replace EXPORTER_FE$N = EXPORTER_FE$N * exp(_b[EXPORTER_FE$N ])
					quietly replace IMPORTER_FE$N = IMPORTER_FE$N * exp(0)

				egen exp_pi_`s_1' = rowtotal(EXPORTER_FE1-EXPORTER_FE$N ) 
				quietly generate tempvar1 = exp_pi_`s_1' if exporter == importer
					bysort importer: egen exp_pi_j_`s_1' = mean(tempvar1) 		
					
			* Update multilateral resistances
				generate change_pricei_`s_1'   = ((exp_pi_`s_1' / exp_pi_`s_2') / (E_R_`s_1' / E_R_`s_2'))^(1/(1-$sigma_am))
				generate change_pricej_`s_1'   = ((exp_pi_j_`s_1' / exp_pi_j_`s_2') / (E_R_`s_1' / E_R_`s_2'))^(1/(1-$sigma_am))
			
			
				generate OMR_FULL_`s_1'		   = (Y_`s_1' * E_R_`s_1') / exp_pi_`s_1' 
				generate change_OMR_FULL_`s_1' = OMR_FULL_`s_1' / OMR_FULL_`s_2'					
				egen exp_chi_`s_1' 			   = rowtotal(IMPORTER_FE1-IMPORTER_FE$N )	
				generate IMR_FULL_`s_1'		   = E_`s_1' / (exp_chi_`s_1' * E_R_`s_1')
				generate change_IMR_FULL_`s_1' = IMR_FULL_`s_1' / IMR_FULL_`s_2'
				
			* Iteration until the change in factory-gate prices converges to zero
				generate dif_change_pi_`s_1' = change_pricei_`s_2' - change_pricei_`s_3'
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
			global replic   = `r'
            global s        = `s'
********************************************************************************
********************************************************************************
			