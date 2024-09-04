
/******************************************************************************* 
	     Deep Trade Agreements Toolkit: Trade and Welfare Impacts 

                  	   this version: APR 2024
				   
website: https://xxxxxxx.org/

when using the tool please cite:  
Fontagné, L., Rocha, N., Ruta, M., Santoni, G. (2022),
 The Economic Impact of Deepening Trade Agreements", CESIfo working paper 9529.  
  
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
********************************************************************************
* Define your working path here: this is where you locate the "Toolkit" folder

 
  global DB	              "C:/Users/gianl/Dropbox/"
  global DB              "d:/santoni/Dropbox/"


global ROOT 		      "$DB/WW_other_projs/WB_2024/WB_GE/WB_DTA_Toolkit"			 
 
global PROG 	          "$ROOT/0.prog/TRADE_data_make"
global DATA 	          "$ROOT/1.data"
global COMTRADE			  "$DATA/COMTRADE"	
global UNIDO			  "$DATA/UNIDO"	
global FAO_prod			  "$DATA/FAO/prod/2024"	
global FAO_trade		  "$DATA/FAO/trade/2024"	


global BACI	        	  "$DB/WW_other_projs/DATA/BACI"
global GRAVITY        	  "$DB/WW_other_projs/DATA/GRAVITY"
global LANG                "$DB/WW_other_projs/DATA/LANG"

global DTA                "$DATA"
global TEMP	     		  "$DATA/temp"
global CLUS	     		  "$ROOT/2.res/clusters"
global GRAV	     		  "$ROOT/2.res/gravity"


global baci_version 	   "BACI_HS02_V202401b"
global grav_version 	   "Gravity_V202211"
global countries_gravity   "Countries_V202211"
 


global year_start		  "1986"
global year_end           "2022"

global type				  "w"                        // w: cluster based on weighted matrix
global uk_fix  			  "fix_before_cluser"   
global cluster_var        "kmean kmedian pam h_clus kmeanR_ch kmeanR_asw kmeanR kmeanR_pam kmeanR_man"


cap 	log close
capture log using "$PROG\00_log_files\p3_merge_rta_trade", text replace


********************************************************************************
********************************************************************************
use  "$DATA\trade_rta_prelim.dta", clear


  gen iso3  = iso_o    // iso_o is the original identifier
   
    
replace iso3 = "ROM"       if iso3  == "ROU"
replace iso3 = "WBG"       if iso3  == "PSE"
replace iso3 = "SRB"       if iso3  == "YUG" 
replace iso3 = "SRB"       if iso3  == "SCG" 

 
merge m:1 iso3 using "$DATA/cty/WBregio.dta" 
drop if _m ==2
tab iso_o if _m == 1   // CSK and SUN not included here
drop _m

rename region region_o
drop iso3



gen iso3  = iso_d    // iso_o is the original identifier
   
    
replace iso3 = "ROM"       if iso3  == "ROU"
replace iso3 = "WBG"       if iso3  == "PSE"
replace iso3 = "SRB"       if iso3  == "YUG" 
replace iso3 = "SRB"       if iso3  == "SCG" 

 
merge m:1 iso3 using "$DATA/cty/WBregio.dta" 
drop if _m ==2
tab iso_d if _m == 1   // CSK and SUN not included here
drop _m



rename region region_d
drop iso3






replace region_o="Africa" if region_o =="Sub-Saharan Africa" 
replace region_o="Africa" if iso_o =="ARE" | iso_o =="DZA" | iso_o =="EGY" | iso_o =="MAR" | iso_o =="TUN"
replace region_d="Africa" if region_d =="Sub-Saharan Africa" 
replace region_d="Africa" if iso_d =="ARE" | iso_d =="DZA" | iso_d =="EGY" | iso_d =="MAR" | iso_d =="TUN"



tab year if es_agro_i_hat == 1 &  iso_o== iso_d & region_o =="Africa"
tab year if es_man_i_hat  == 1 &  iso_o== iso_d & region_o =="Africa"


tab year if ( es_man_i_hat        == 1 & es_agro_i_hat       == 1) &  (  iso_o== iso_d & region_o =="Africa")

tab year if ( es_man_i_avg        == 1 & es_agro_i_avg       == 1) &  (  iso_o== iso_d & region_o =="Africa")

tab year if ( es_man_avg_sales    == 1 & es_agro_avg_sales   == 1) &  (  iso_o== iso_d & region_o =="Africa")

********************************************************************************
********************************************************************************
/*******************************************************************************
* Once everything is ok, clean the TEMP directory
 cd  "$TEMP" 
 local files : dir "`c(pwd)'"  files "*.dta*" 

foreach file in `files' { 
	erase `file'    
} 
 
*******************************************************************************/
********************************************************************************
 