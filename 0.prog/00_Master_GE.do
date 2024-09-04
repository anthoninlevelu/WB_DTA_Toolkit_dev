
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

*  ssc install wbopendata, replace

********************************************************************************
* Define your working path here: this is where you locate the "Toolkit" folder

 
global DB	              "C:/Users/gianl/Dropbox/" 
global DB               "d:/santoni/Dropbox/"
global DB			"/Users/anthoninlevelu/Desktop/World Bank/2024"

global ROOT 		      "$DB/WW_other_projs/WB_2024/WB_GE/WB_DTA_Toolkit"		
global ROOT 		"$DB/PTA_project/FLRS/WB_DTA_Toolkit_dev"	 

* Log files
global LOG                "$ROOT/0.prog/99_log_files"

* Prog datamake
global PROG_dta           "$ROOT/0.prog/0_datamake/000_DTA_progs" 
global PROG_trade         "$ROOT/0.prog/0_datamake/00_TRADE_progs"

 
* Prog GE
global PROG_trade_stat   "$ROOT/0.prog/1_trade_stats" 
global PROG_rta_stat     "$ROOT/0.prog/2_rta_stats"
global PROG_ge 	         "$ROOT/0.prog/3_ge_simulations"


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
global TRADESTATS         "$DATA/BACI"
global GRAVSTATS		  "$DATA/GRAVITY/"
global DTA                "$DATA"
global CTY                "$DATA/CTY"
global TEMP	     		  "$DATA/temp"


* Results
global CLUS	     		  "$ROOT/2.res/clusters"
global GRAV	     		  "$ROOT/2.res/gravity"
global RES	     		  "$ROOT/2.res/toolkit"
global WEB  	          "$ROOT/3.web_toolkit"

* External Data Versioning
global baci_version 	   "BACI_HS02_V202401b"   // this is just to process raw data
global cty_code_baci	   "cty_code_baci_HS2002"
global baci		    	   "baci_HS2002"          // this is the file in the directory

global grav_version 	   "Gravity_V202211"
global countries_gravity   "Countries_V202211"

global prod_version		   "indstat2_2024"
 

* Time span dataset
global year_start		  "1986"
global year_end           "2022"  // ATT: production data Manufacturing only up to 2021 (UNIDO 2024 Release)


*global cluster_var       "kmean kmedian pam h_clus kmeanR_ch kmeanR_asw kmeanR kmeanR_pam kmeanR_man"
global cluster_var        "kmean    kmedian kmean_sil kmedian_sil h_clus pam pamR_eucl  "
global type    			  "w"   				
global dist_lang          "lpn cnl lps csl cor dist distcap distw_harmonic distw_arithmetic contig comcol"
 
global year_GE_end		  "2022"     // this is for the counterfactuals

global first_year         "1986"
global year_start 	      "1986"
global year_end		      "2022" 


global demand_scenarios    "NO"    // those are for on demland scenarios (dofile )

// for trade stats & find extensive margins counterfactuals
global ldate_bg			   "2022"
global ldate_bg1		   "2015"	 
global ldate_bg2		   "2010"	
global ldate_bg3		   "2005"	
global fdate_bg			   "2002"    // for trade stats and rca

global ldate_bg_rta		   "2022"    // for PTA stats and rca
 
******************************************************************************** 
******************************************************************************** 
* Data Make 

do "$PROG_dta/0.Master_DTA.do"
do "$PROG_trade/0.Master_TRADE.do"
 

*******************************************************************************/
******************************************************************************** 
* Loop for the Toolkit
********************************************************************************
********************************************************************************
* 140 countries in the 2024 version of the toolkit

global country_interest "AGO ALB ARG ARM AUS AUT AZE BDI BEL BGD BGR BHR BIH BLR BLZ BOL BRA BRB BRN BWA CAF CAN CHE CHL CHN CMR COG COL CPV CRI CYP CZE DEU DNK DOM DZA ECU EGY ERI ESP EST ETH FIN FJI FRA GAB GBR GEO GHA GMB GRC GTM HND HRV HTI HUN IDN IND IRL IRN IRQ ISL ISR ITA JAM JOR JPN KAZ KEN KGZ KHM KOR KWT LAO LBN LCA LKA LTU LUX LVA MAR MDA MDG MDV MEX MKD MLT MNG MOZ MUS MWI MYS NAM NER NGA NIC NLD NOR NPL NZL OMN PAK PAN PER PHL PNG POL PRT PRY PSE QAT ROU RUS RWA SAU SCG SEN SGP SLV SRB SUR SVK SVN SWE THA TJK TKM TTO TUN TUR TZA UKR URY USA VEN VNM YEM ZAF ZMB ZWE"  

local z      = 0      // this is to count the run in the loop
 
 foreach iso of global country_interest {
	

global z = `z'
* comment out if you dont want to clean the directory
 shell rmdir "$RES//`iso'//temp//" /s /q 
 shell rmdir "$RES//`iso'//"       /s /q
 
 shell mkdir "$RES//`iso'//" 
 shell mkdir "$RES//`iso'//temp//"   

 
********************************************************************************
********************************************************************************
*  This section defines (cleans and generates) all temporary and final directories before execution on your $country_interest (please don't change the parameters).



global iso    "`iso'"
local iso     "$iso"

********************************************************************************
********************************************************************************
********************************************************************************
* GE analysis technical parameters: do not change
********************************************************************************
********************************************************************************
global wto						"wto_od"
global rta1_beta 				"est_RTA1"
global rta2_beta 				"est_RTA2"
global rta3_beta 				"est_RTA3"
global rta_out_beta 			"est_RTA_out"
global wto_beta 			    "est_wto"

********************************************************************************
* Manufacturing plus Agricolture always

global ge_dataset 				"$DATA/TradeProd_Data_Toolkit_2024.dta"
global trade_frictions 			"agro_ieY_man_ieY"
global trade        			"agro_ieY_man_ieY"
global dataset_am 			    "ge_gravity_estibrated_am"
global kmean_alg		    	"kmean"
global rta      		    	"rta_est"
global wto      		    	"wto_od"


 
global preliminary 				"on"     // when "on" runs the preliminary gravity regs to find tau and RTA elasticities
global controls_od              "rta_out rta_psa $wto"
global dist_lang                "lpn cnl lps csl cor dist distcap distw_harmonic distw_arithmetic contig comcol"
 

********************************************************************************
* GE analysis customizable parameters
********************************************************************************
global sym           			" "									  
//  If "sym" then d_ij = d_ji, if the macro is empty "" the bilateral fixed effects for structural gravity are asymmetric.
global sigma_am 				"6"

global runs 					"15"                                      
// This is to select the number of loops to consider before declaring that the GE is not converging; if GE > $runs, it restarts with the default threshold times 1.05, i.e. 0.05*1.05.

global rank 					"10"									 
// select # countries for the optimal number of partners in the extensive margin counterfactuals
global selection_criteria   	"ALL"									  
// "DS" select Extensive margin based on export all goods and imports of intermediate goods (if you set "ALL" it selects the optimal partners based on all goods for imports and expots)
global trim 					"YES"									  // "YES" drops trade partners with less than 1% mkt share for each iso	
********************************************************************************
********************************************************************************
* This section defines the macro regions needed for analysis (do not edit).
 
	use		"$CTY/WBregio_toolkit", clear
	
	gen 		reg_s = "EAP"		if 		region == "East Asia & Pacific"		 
	replace		reg_s = "ECA"		if 		region == "Europe & Central Asia"
	replace		reg_s = "LAC"		if 		region == "Latin America & Caribbean"
	replace		reg_s = "MENA"		if 		region == "Middle East & North Africa"
	replace		reg_s = "NA"		if 		region == "North America"
	replace		reg_s = "SA"		if 		region == "South Asia"
	replace		reg_s = "SSA"		if 		region == "Sub-Saharan Africa"
	
	keep if iso3 ==  "`iso'"
	rename 	region reg_l

********************************************************************************
    local temp =reg_s[1]   
	global reg_s   "`temp'"
	display "$reg_s"

	
	local temp =reg_l[1]   
	global reg_l   "`temp'"
	display "$reg_l"

********************************************************************************
******************************************************************************** 
* Now define the reference contry 
********************************************************************************
******************************************************************************** 
* Now define the reference contry 


use $ge_dataset, clear
 
keep 						 							 if $rta  == 0

gen year_iso   = year       							 if iso_o == "$iso"
egen temp_max  = max(year_iso) 
keep if year  == temp_max

preserve
keep if iso_o == "$iso"
keep iso_o iso_d $trade
rename $trade export
rename iso_d iso3
 save "$RES//`iso'//temp//temp_ref_cty", replace
 restore

bys iso_o: egen totX  = total( $trade)
keep if iso_d == "$iso"
keep iso_o iso_d $trade totX
rename $trade import
rename iso_o iso3

merge 1:1 iso3 using "$RES//`iso'//temp//temp_ref_cty"
drop _m

merge 1:1 iso3 using "$CTY/WBregio_toolkit"
drop if _m == 2
drop _m



keep if region != "$reg_l"

sum totX, d
keep if totX   >= r(p25)                // select a country that is likely not full of zeros

sort totX 


    local temp =iso3[1]   
	global ref_cty   "`temp'"
	display "$ref_cty"				   //  it must not be directly involved in the counterfactuals

********************************************************************************
********************************************************************************

use $ge_dataset, clear
keep if iso_o == iso_d
keep if iso_o == "`iso'"
egen max = max(year)
keep if year == max

local 		  X 	  = year[1]        // defines the most recent years for trade shares
global year_reg  	  =   `X' 

display "$year_reg"
	
	
********************************************************************************	
********************************************************************************	
clear
set obs   1
gen     cty             = "$iso" 
gen     year            = "$year_reg" 
gen     numeraire       = "$ref_cty" 
  

if   `z'  	 == 0 {
	
	
save "$RES//info_simulations_toolkit.dta",  replace

}


if `z'  >= 1 {

append using  "$RES//info_simulations_toolkit.dta"

save "$RES//info_simulations_toolkit.dta",  replace

}



******************************************************************************** 
********************************************************************************
/* Trade statistics: this section selects the data to be used to define the extensive margin counterfactuals
 (i.e., the optimal trading partners with which the target country should enter into a preferential trade agreement - extensive margin).
 p1_trade_stats_panel  : Calculate both Export and Import statistics 
*/


global dist         "distw_harmonic"
global covar 	    "ldist fta_wto contig comcol lpn"            // Variables that are used as proxies for bilateral trade frictions in the structural gravity.
global clus 	    "i j"										// Correction of standard errors in structural gravity regressions (two way cluster)
global EU_aggregate "YES"                                       // if "YES" aggregates EU as a single Export or Import market 
 
 
di `z'
di $z

do "$PROG_trade_stat/p1_trade_stats_panel.do"

********************************************************************************
/* RTA statistics: This section analyzes the target country's existing regime of trade agreements and
defines relevant counterfactuals to assess the deepening of existing agreements (intensive margin). */

local iso     "$iso"
do "$PROG_rta_stat/p2_rta_stats.do"


********************************************************************************
/* 

This section selects the optimal trading partners for extensive margin GE counterfactuals.

 */
 

global covar 	"ldist fta_wto contig comcol lpn"       
global clus 	"i j"
local iso     "$iso"

 do "$PROG_rta_stat/p3_RTA_gravity_selection.do"

********************************************************************************
********************************************************************************
* GE analysis: this section performs the GE analysis 
********************************************************************************
********************************************************************************

	
global preliminary 				"on"     // when "on" runs the preliminary gravity regs to find tau and RTA elasticities
	
 
********************************************************************************
********************************************************************************

  
  local iso     "$iso"
  do "$PROG_ge/1_ge_analysis_v2024.do"
  

  
********************************************************************************
******************************************************************************** 
  local iso     "$iso"

clear
set obs   1

gen     cty             = "$iso" 
gen     year            = "$year_reg" 
gen     numeraire       = "$ref_cty" 



save "$RES//`iso'//info_simulations.dta",  replace

 

  local iso     "$iso"
do  "$PROG_ge/2_build_ge_tables.do" 

  local iso     "$iso"

shell rmdir "$RES//`iso'//temp//"  /s /q         // drop temp folder by country

 local iso     "$iso"
 cd "$RES//`iso'//"
cap erase  ge_gravity_estibrated_am.dta 

 local z  = `z'  + 1 
}


********************************************************************************
* prepare the final data for the web Toolkit
global country_interest "AGO ALB ARG ARM AUS AUT AZE BDI BEL BGD BGR BHR BIH BLR BLZ BOL BRA BRB BRN BWA CAF CAN CHE CHL CHN CMR COG COL CPV CRI CYP CZE DEU DNK DOM DZA"
cd "$WEB"
local files : dir "`c(pwd)'"   files "*.csv" 
display  `files' 

   
foreach file in `files' { 
	erase `file'    
} 


do "$ROOT/0.prog/01_prepare_csv_for_toolkit.do"


********************************************************************************
* make sure the TEMP folder is empty

cd "$TEMP"
local files : dir "`c(pwd)'"   files "*.dta" 
display  `files' 

   
foreach file in `files' { 
	erase `file'    
} 

********************************************************************************
********************************************************************************
