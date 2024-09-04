

********************************************************************************

global rta_out 					"rta_out"


cap drop if iso_o =="CUW" 
cap drop if iso_d =="CUW" 

keep if est_sample_v_i_hat_zero == 1

replace v  				= . 	 if  est_sample_v				 !=	 1 
replace v_i_hat 		= . 	 if  est_sample_v_i_hat			 !=	 1 
replace v_i_hat_zero    = . 	 if  est_sample_v_i_hat_zero	 !=	 1 



replace v_i_hat_zero    = 0      if  v_i_hat_zero 				  == .          & est_sample_v_i_hat_zero == 1

********************************************************************************

cap drop totV
bys iso_d year: egen totV 			= total(v)
			     gen v_sh   		= v/totV
			  
********************************************************************************
cap drop totV
bys iso_d year: egen totV 			= total(v_i_hat)
			 gen v_i_hat_sh 		= v_i_hat/totV
			 
********************************************************************************			 
cap drop totV
bys iso_d year: egen totV 			= total(v_i_hat_zero)
			 gen v_i_hat_zero_sh 	= v_i_hat_zero/totV
		
********************************************************************************
tab year 
tab year if iso_o == iso_d


keep if year == 2018 | year == 2013 | year == 2008 | year == 2003 | year == 1998 | year == 1993 | year == 1988 | year == 1983 | year == 1978  
*keep if year == 2018 | year == 2013 | year == 2008 | year == 2003 | year == 1998 | year == 1993 | year == 1988 | year == 1983 | year == 1978  | year == 1973

********************************************************************************

