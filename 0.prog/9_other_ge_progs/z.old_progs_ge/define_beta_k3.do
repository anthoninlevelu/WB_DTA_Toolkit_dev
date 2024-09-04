


********************************************************************************
gen    est_RTA1 	            = _b[rta_k1]
gen    est_RTA2  	            = _b[rta_k2]
gen    est_RTA3  	            = _b[rta_k3]

gen    est_RTA_out 	            = _b[rta_out]


cap gen     est_INTL_BRDR_1980  	= _b[INTL_BRDR_1980]
cap gen     est_INTL_BRDR_1990 		= _b[INTL_BRDR_1990]
cap gen     est_INTL_BRDR_2000 		= _b[INTL_BRDR_2000]


gen     est_INTL_BRDR_2010 		= 0

gen     	INTL_BRDR_2010 		= 0

cap drop t
rename year   t

gen  trade = $trade 

gen   exporter = iso_o
gen   importer = iso_d


cap drop pair_id

rename ij pair_id
********************************************************************************
