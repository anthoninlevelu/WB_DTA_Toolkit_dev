********************************************************************************
if "$counterfactual"    == "ALL" {

gen efta_o = ( iso_o =="NOR" | iso_o =="CHE" | iso_o =="ISL")
gen efta_d = ( iso_d =="NOR" | iso_d =="CHE" | iso_d =="ISL")


* PAL-EU to Deep

cap drop rta_k1_cfl
cap drop rta_k2_cfl
cap drop rta_k3_cfl


gen 	 rta_k1_cfl 		= rta_k1
gen 	 rta_k2_cfl 		= rta_k2
gen 	 rta_k3_cfl 		= rta_k3

 
replace  rta_k1_cfl  		= 1  if ( iso_o    == "PAL" 				& eu_d == 1)          & (exporter!= importer)
replace  rta_k1_cfl  		= 1  if ( iso_d    == "PAL" 				& eu_o == 1)          & (exporter!= importer)

replace  rta_k1_cfl  		= 1  if ( iso_o    == "PAL" 				& efta_d == 1)        & (exporter!= importer)
replace  rta_k1_cfl  		= 1  if ( iso_d    == "PAL" 				& efta_o == 1)        & (exporter!= importer)
 
replace  rta_k1_cfl  		= 1  if ( iso_o    == "PAL" 				& iso_d    == "TUR" ) & (exporter!= importer)
replace  rta_k1_cfl  		= 1  if ( iso_d    == "PAL" 				& iso_o    == "TUR" ) & (exporter!= importer)
  
 
replace  rta_k2_cfl         = 0 if rta_k1_cfl == 1  
replace  rta_k3_cfl         = 0 if rta_k1_cfl == 1

}
********************************************************************************
********************************************************************************


********************************************************************************
if "$counterfactual"    == "EU" {



* PAL-EU to Deep

cap drop rta_k1_cfl
cap drop rta_k2_cfl
cap drop rta_k3_cfl


gen 	 rta_k1_cfl 		= rta_k1
gen 	 rta_k2_cfl 		= rta_k2
gen 	 rta_k3_cfl 		= rta_k3

 
replace  rta_k1_cfl  		= 1  if ( iso_o    == "PAL" 				& eu_d == 1) & (exporter!= importer)
replace  rta_k1_cfl  		= 1  if ( iso_d    == "PAL" 				& eu_o == 1) & (exporter!= importer)
 
replace  rta_k2_cfl         = 0 if rta_k1_cfl == 1  
replace  rta_k3_cfl         = 0 if rta_k1_cfl == 1

}
********************************************************************************
********************************************************************************
if "$counterfactual"    == "EFTA" {

gen efta_o = ( iso_o =="NOR" | iso_o =="CHE" | iso_o =="ISL")
gen efta_d = ( iso_d =="NOR" | iso_d =="CHE" | iso_d =="ISL")

* PAL-EFTA to Deep

cap drop rta_k1_cfl
cap drop rta_k2_cfl
cap drop rta_k3_cfl


gen 	 rta_k1_cfl 		= rta_k1
gen 	 rta_k2_cfl 		= rta_k2
gen 	 rta_k3_cfl 		= rta_k3

 
replace  rta_k1_cfl  		= 1  if ( iso_o    == "PAL" 				& efta_d == 1) & (exporter!= importer)
replace  rta_k1_cfl  		= 1  if ( iso_d    == "PAL" 				& efta_o == 1) & (exporter!= importer)
 
replace  rta_k2_cfl         = 0 if rta_k1_cfl == 1  
replace  rta_k3_cfl         = 0 if rta_k1_cfl == 1

}
********************************************************************************
********************************************************************************

if "$counterfactual"    == "TUR" {

* PAL-EFTA to Deep

cap drop rta_k1_cfl
cap drop rta_k2_cfl
cap drop rta_k3_cfl


gen 	 rta_k1_cfl 		= rta_k1
gen 	 rta_k2_cfl 		= rta_k2
gen 	 rta_k3_cfl 		= rta_k3

 
replace  rta_k1_cfl  		= 1  if ( iso_o    == "PAL" 				& iso_d    == "TUR" ) & (exporter!= importer)
replace  rta_k1_cfl  		= 1  if ( iso_d    == "PAL" 				& iso_o    == "TUR" ) & (exporter!= importer)
 
replace  rta_k2_cfl         = 0 if rta_k1_cfl == 1  
replace  rta_k3_cfl         = 0 if rta_k1_cfl == 1

}

********************************************************************************
********************************************************************************
if "$counterfactual"    == "MENA1" {
* Within MENA all to High
cap drop rta_k1_cfl
cap drop rta_k2_cfl
cap drop rta_k3_cfl


gen 	 rta_k1_cfl 		= rta_k1
gen 	 rta_k2_cfl 		= rta_k2
gen 	 rta_k3_cfl 		= rta_k3

 
replace  rta_k1_cfl  		= 1  if ( iso_o    == "PAL" 					   & region_d == "Middle East & North Africa" )  & (exporter!= importer)
replace  rta_k1_cfl  		= 1  if ( iso_d    == "PAL" 					   & region_o == "Middle East & North Africa" )  & (exporter!= importer)
 
replace  rta_k2_cfl         = 0 if rta_k1_cfl == 1  
replace  rta_k3_cfl         = 0 if rta_k1_cfl == 1

}
********************************************************************************
********************************************************************************
if "$counterfactual"    == "MENA2" {
* Within MENA all to Medium
cap drop rta_k1_cfl
cap drop rta_k2_cfl
cap drop rta_k3_cfl


gen 	 rta_k1_cfl 		= rta_k1
gen 	 rta_k2_cfl 		= rta_k2
gen 	 rta_k3_cfl 		= rta_k3

 
replace  rta_k2_cfl  		= 1  if ( iso_o    == "PAL" 					   & region_d == "Middle East & North Africa" )  & (exporter!= importer)
replace  rta_k2_cfl  		= 1  if ( iso_d    == "PAL" 					   & region_o == "Middle East & North Africa" )  & (exporter!= importer)
 
replace  rta_k1_cfl         = 0 if rta_k2_cfl == 1  
replace  rta_k3_cfl         = 0 if rta_k2_cfl == 1




}
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
if "$counterfactual"    == "MENA3" {
* Within MENA all to Shallow
cap drop rta_k1_cfl
cap drop rta_k2_cfl
cap drop rta_k3_cfl


gen 	 rta_k1_cfl 		= rta_k1
gen 	 rta_k2_cfl 		= rta_k2
gen 	 rta_k3_cfl 		= rta_k3

 
replace  rta_k3_cfl  		= 1  if ( iso_o    == "PAL" 					   & region_d == "Middle East & North Africa" )  & (exporter!= importer)  
replace  rta_k3_cfl  		= 1  if ( iso_d    == "PAL" 					   & region_o == "Middle East & North Africa" )  & (exporter!= importer)  
 
replace  rta_k1_cfl         = 0 if rta_k3_cfl == 1  
replace  rta_k2_cfl         = 0 if rta_k3_cfl == 1

}
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
if "$counterfactual"    == "MENA2b" {
* Within MENA all to Medium
cap drop rta_k1_cfl
cap drop rta_k2_cfl
cap drop rta_k3_cfl


gen 	 rta_k1_cfl 		= rta_k1
gen 	 rta_k2_cfl 		= rta_k2
gen 	 rta_k3_cfl 		= rta_k3

 
replace  rta_k2_cfl  		= 1  if ( iso_o    == "PAL" 					   & region_d == "Middle East & North Africa" )  & (exporter!= importer)
replace  rta_k2_cfl  		= 1  if ( iso_d    == "PAL" 					   & region_o == "Middle East & North Africa" )  & (exporter!= importer)
 
replace  rta_k1_cfl         = 0 if rta_k2_cfl == 1  
replace  rta_k3_cfl         = 0 if rta_k2_cfl == 1


replace  rta_k1_cfl  		= rta_k1 if ( iso_o    == "PAL"  &  iso_d    == "ISR") | ( iso_d    == "PAL"  &  iso_o    == "ISR")
replace  rta_k2_cfl  		= rta_k2 if ( iso_o    == "PAL"  &  iso_d    == "ISR") | ( iso_d    == "PAL"  &  iso_o    == "ISR")
replace  rta_k3_cfl  		= rta_k3 if ( iso_o    == "PAL"  &  iso_d    == "ISR") | ( iso_d    == "PAL"  &  iso_o    == "ISR")


}
********************************************************************************
********************************************************************************
if "$counterfactual"    == "MENA3b" {
* Within MENA all to Shallow
cap drop rta_k1_cfl
cap drop rta_k2_cfl
cap drop rta_k3_cfl


gen 	 rta_k1_cfl 		= rta_k1
gen 	 rta_k2_cfl 		= rta_k2
gen 	 rta_k3_cfl 		= rta_k3

 
replace  rta_k3_cfl  		= 1  if ( iso_o    == "PAL" 					   & region_d == "Middle East & North Africa" )  & (exporter!= importer)
replace  rta_k3_cfl  		= 1  if ( iso_d    == "PAL" 					   & region_o == "Middle East & North Africa" )  & (exporter!= importer)
 
replace  rta_k1_cfl         = 0 if rta_k3_cfl == 1  
replace  rta_k2_cfl         = 0 if rta_k3_cfl == 1

replace  rta_k1_cfl  		= rta_k1 if ( iso_o    == "PAL"  &  iso_d    == "ISR") | ( iso_d    == "PAL"  &  iso_o    == "ISR")
replace  rta_k2_cfl  		= rta_k2 if ( iso_o    == "PAL"  &  iso_d    == "ISR") | ( iso_d    == "PAL"  &  iso_o    == "ISR")
replace  rta_k3_cfl  		= rta_k3 if ( iso_o    == "PAL"  &  iso_d    == "ISR") | ( iso_d    == "PAL"  &  iso_o    == "ISR")

}
********************************************************************************
********************************************************************************
