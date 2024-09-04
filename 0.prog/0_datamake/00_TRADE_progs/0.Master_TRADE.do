
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

ssc install wbopendata, replace

********************************************************************************
* Define your working path here: this is where you locate the "Toolkit" folder

 
global DB	              "C:/Users/gianl/Dropbox/" 
global DB              "d:/santoni/Dropbox/"
* Anthonin:
global DB			"/Users/anthoninlevelu/Desktop/World Bank/2024"


global ROOT 		     "$DB/WW_other_projs/WB_2024/WB_GE/WB_DTA_Toolkit"	
* Anthonin:
global ROOT 		"$DB/PTA_project/FLRS/WB_DTA_Toolkit_dev"	 

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

global uk_fix  			  "fix_before_cluster"   		 // fix_before_cluster or fix_after_cluster

*global cluster_var       "kmean kmedian pam h_clus kmeanR_ch kmeanR_asw kmeanR kmeanR_pam kmeanR_man"
global cluster_var        "kmean    kmedian kmean_sil kmedian_sil h_clus pam pamR_eucl  "
global type    			  "w"   				
global dist_lang          "lpn cnl lps csl cor dist distcap distw_harmonic distw_arithmetic contig comcol"
 // w: weighted provision matrix ; u: unweighted provision matrix (1/0)

global min_trade		  "100"  // strangely small trade values in Comtrade if less 100US$ drop obs in manufacturing
 
 
 
********************************************************************************
* Load Data and compute Transport costs

 do "$PROG_trade/p0_load_baci_&_gravity.do"      
 // also dowload the updated GDP figure (use  ssc install wbopendata)							
 
 do "$PROG_trade/p0_prepare_freight.do"         
 


use  "$DATA/decaf_stats", clear

summ mean_ad_costs if sector == "manuf", d
global  tc_man        = r(mean)
 
summ mean_ad_costs if sector == "agro", d
global  tc_agr        = r(p50) 
 
summ mean_ad_costs if sector == "min", d
global  tc_min        = r(mean) 
  

********************************************************************************
* Build the actual Dataset 
do "$PROG_trade/p1_datamake_manuf_tradeProd.do"
do "$PROG_trade/p2_datamake_agri_FAO.do"

********************************************************************************
********************************************************************************
* make sure the Results folder is empty

cd "$RES"
local files : dir "`c(pwd)'"   files "*.xls" 
display  `files' 

   
foreach file in `files' { 
	erase `file'    
} 
********************************************************************************
********************************************************************************
* Validate Gravity 

do "$PROG_trade/p3_merge_RTA_&_validate.do"


********************************************************************************
* make sure the TEMP folder is empty

cd "$TEMP"
local files : dir "`c(pwd)'"   files "*.dta" 
display  `files' 

   
foreach file in `files' { 
	erase `file'    
} 
********************************************************************************
