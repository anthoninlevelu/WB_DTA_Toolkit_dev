********************************************************************************
if "$counterfactual"    == "rcep_new" {
* simulate


merge m:1 iso_d using "$PROG\rcep.dta", keepusing(rcep_d )
drop  if _m == 2
drop _m

merge m:1 iso_o using "$PROG\rcep.dta", keepusing(rcep_o )
drop  if _m == 2
drop _m

cap drop rta_k1_cfl
cap drop rta_k2_cfl
cap drop rta_k3_cfl


gen 	 rta_k1_cfl 		= rta_k1
gen 	 rta_k2_cfl 		= rta_k2
gen 	 rta_k3_cfl 		= rta_k3

 
replace  rta_k3_cfl  		= 1  if ( rcep_o  == 1			& rcep_d  == 1) & (exporter!= importer) & (rta_k1_cfl == 0 ) & (rta_k2_cfl == 0 )
replace  rta_k3_cfl  		= 1  if ( rcep_d  == 1			& rcep_o  == 1) & (exporter!= importer) & (rta_k1_cfl == 0 ) & (rta_k2_cfl == 0 )
 
replace  rta_k1_cfl         = 0 if rta_k3_cfl == 1  
replace  rta_k2_cfl         = 0 if rta_k3_cfl == 1

}
********************************************************************************
********************************************************************************
if "$counterfactual"    == "rcep_cptpp" {
* Add China to cptpp: cluster 2


merge m:1 iso_d using "$PROG\cptpp.dta", keepusing(cptpp_d )
drop  if _m == 2
drop _m

merge m:1 iso_o using "$PROG\cptpp.dta", keepusing(cptpp_o )
drop  if _m == 2
drop _m

merge m:1 iso_d using "$PROG\rcep.dta", keepusing(rcep_d )
drop  if _m == 2
drop _m

merge m:1 iso_o using "$PROG\rcep.dta", keepusing(rcep_o )
drop  if _m == 2
drop _m


cap drop rta_k1_cfl
cap drop rta_k2_cfl
cap drop rta_k3_cfl


gen 	 rta_k1_cfl 		= rta_k1
gen 	 rta_k2_cfl 		= rta_k2
gen 	 rta_k3_cfl 		= rta_k3

replace  rta_k3_cfl  		= 1  if ( rcep_o  == 1			& rcep_d  == 1) & (exporter!= importer) & (rta_k1_cfl == 0 ) & (rta_k2_cfl == 0 )
replace  rta_k3_cfl  		= 1  if ( rcep_d  == 1			& rcep_o  == 1) & (exporter!= importer) & (rta_k1_cfl == 0 ) & (rta_k2_cfl == 0 )
 
replace  rta_k1_cfl         = 0 if rta_k3_cfl == 1  
replace  rta_k2_cfl         = 0 if rta_k3_cfl == 1


replace  rta_k2_cfl  		= 1  if ( iso_o    == "CHN" 	& cptpp_d  == 1) & (exporter!= importer)
replace  rta_k2_cfl  		= 1  if ( iso_d    == "CHN" 	& cptpp_o  == 1) & (exporter!= importer)
 
replace  rta_k1_cfl         = 0 if rta_k2_cfl == 1  
replace  rta_k3_cfl         = 0 if rta_k2_cfl == 1

}
********************************************************************************

********************************************************************************
if "$counterfactual"    == "cptpp_pre"  {
* Add China to cptpp: cluster 2


merge m:1 iso_d using "$PROG\cptpp.dta", keepusing(cptpp_d )
drop  if _m == 2
drop _m

merge m:1 iso_o using "$PROG\cptpp.dta", keepusing(cptpp_o )
drop  if _m == 2
drop _m

cap drop rta_k1_cfl
cap drop rta_k2_cfl
cap drop rta_k3_cfl


gen 	 rta_k1_cfl 		= rta_k1
gen 	 rta_k2_cfl 		= rta_k2
gen 	 rta_k3_cfl 		= rta_k3

 
replace  rta_k2_cfl  		= 1  if ( cptpp_o  == 1     & cptpp_d  == 1) & (exporter!= importer)
replace  rta_k2_cfl  		= 1  if ( cptpp_d  == 1     & cptpp_o  == 1) & (exporter!= importer)
 
replace  rta_k1_cfl         = 0 if rta_k2_cfl == 1  
replace  rta_k3_cfl         = 0 if rta_k2_cfl == 1

}
********************************************************************************
********************************************************************************
if "$counterfactual"    == "cptpp_pre_c"  {
* Add China to cptpp: cluster 2


merge m:1 iso_d using "$PROG\cptpp.dta", keepusing(cptpp_d )
drop  if _m == 2
drop _m

merge m:1 iso_o using "$PROG\cptpp.dta", keepusing(cptpp_o )
drop  if _m == 2
drop _m

cap drop rta_k1_cfl
cap drop rta_k2_cfl
cap drop rta_k3_cfl


gen 	 rta_k1_cfl 		= rta_k1
gen 	 rta_k2_cfl 		= rta_k2
gen 	 rta_k3_cfl 		= rta_k3

 
replace  rta_k2_cfl  		= 1  if ( cptpp_o  == 1     & cptpp_d  == 1)     & (exporter!= importer)
replace  rta_k2_cfl  		= 1  if ( cptpp_d  == 1     & cptpp_o  == 1)     & (exporter!= importer)
replace  rta_k2_cfl  		= 1  if ( iso_o    == "CHN" 	& cptpp_d  == 1) & (exporter!= importer)
replace  rta_k2_cfl  		= 1  if ( iso_d    == "CHN" 	& cptpp_o  == 1) & (exporter!= importer)

 
replace  rta_k1_cfl         = 0 if rta_k2_cfl == 1  
replace  rta_k3_cfl         = 0 if rta_k2_cfl == 1

}
********************************************************************************
********************************************************************************
if "$counterfactual"    == "cptpp_c" {
* Add China to cptpp: cluster 2


merge m:1 iso_d using "$PROG\cptpp.dta", keepusing(cptpp_d )
drop  if _m == 2
drop _m

merge m:1 iso_o using "$PROG\cptpp.dta", keepusing(cptpp_o )
drop  if _m == 2
drop _m

cap drop rta_k1_cfl
cap drop rta_k2_cfl
cap drop rta_k3_cfl


gen 	 rta_k1_cfl 		= rta_k1
gen 	 rta_k2_cfl 		= rta_k2
gen 	 rta_k3_cfl 		= rta_k3

 
replace  rta_k2_cfl  		= 1  if ( iso_o    == "CHN" 	& cptpp_d  == 1) & (exporter!= importer)
replace  rta_k2_cfl  		= 1  if ( iso_d    == "CHN" 	& cptpp_o  == 1) & (exporter!= importer)
 
replace  rta_k1_cfl         = 0 if rta_k2_cfl == 1  
replace  rta_k3_cfl         = 0 if rta_k2_cfl == 1

}
********************************************************************************
********************************************************************************
if "$counterfactual"    == "cptpp_cd" {
* Add China to cptpp and switch to cluster 1

merge m:1 iso_d using "$PROG\cptpp.dta", keepusing(cptpp_d )
drop  if _m == 2
drop _m

merge m:1 iso_o using "$PROG\cptpp.dta", keepusing(cptpp_o )
drop  if _m == 2
drop _m

cap drop rta_k1_cfl
cap drop rta_k2_cfl
cap drop rta_k3_cfl


gen 	 rta_k1_cfl 		= rta_k1
gen 	 rta_k2_cfl 		= rta_k2
gen 	 rta_k3_cfl 		= rta_k3

 
replace  rta_k1_cfl  		= 1  if ( cptpp_o  == 1         & cptpp_d  == 1) & (exporter!= importer)
replace  rta_k1_cfl  		= 1  if ( cptpp_d  == 1         & cptpp_o  == 1) & (exporter!= importer)
replace  rta_k1_cfl  		= 1  if ( iso_o    == "CHN" 	& cptpp_d  == 1) & (exporter!= importer)
replace  rta_k1_cfl  		= 1  if ( iso_d    == "CHN" 	& cptpp_o  == 1) & (exporter!= importer)
 
replace  rta_k2_cfl         = 0 if rta_k1_cfl == 1  
replace  rta_k3_cfl         = 0 if rta_k1_cfl == 1
}
********************************************************************************
********************************************************************************
if "$counterfactual"    == "multi" {
* simulate

merge m:1 iso_d using "$PROG\cptpp.dta", keepusing(cptpp_d )
drop  if _m == 2
drop _m

merge m:1 iso_o using "$PROG\cptpp.dta", keepusing(cptpp_o )
drop  if _m == 2
drop _m

cap drop rta_k1_cfl
cap drop rta_k2_cfl
cap drop rta_k3_cfl


gen 	 rta_k1_cfl 		= rta_k1
gen 	 rta_k2_cfl 		= rta_k2
gen 	 rta_k3_cfl 		= rta_k3

 
replace  rta_k2_cfl  		= 1  if ( rta_k2	  == 0) 					& (exporter!= importer)
replace  rta_k2_cfl  		= 1  if ( rta_k3	  == 1) 					& (exporter!= importer)
replace  rta_k2_cfl  		= 1  if ( rta_k3	  == 0) 					& (exporter!= importer)
replace  rta_k2_cfl  		= 0  if ( rta_k1	  == 1) 					& (exporter!= importer)

 
replace  rta_k1_cfl         = 0 if rta_k2_cfl == 1  
replace  rta_k3_cfl         = 0 if rta_k2_cfl == 1

}
********************************************************************************
