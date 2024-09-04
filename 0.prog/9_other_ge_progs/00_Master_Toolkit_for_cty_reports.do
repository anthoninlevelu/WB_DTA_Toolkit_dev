/******************************************************************************* 
	     The Economic Impact of Deepening Trade Agreements A Toolkit

			Nadia Rocha, Gianluca Santoni, Giulio Vannelli 

                  	   this version: OCT 2022
				   
website: https://xxxxxxx.org/


when using the tool please cite:  
Fontagné, L., Rocha, N., Ruta, M., Santoni, G. (2023),
 "The Economic Impact of Deepening Trade Agreements”, World Bank Economic Review,  https://doi.org/10.1093/wber/lhad005.  

corresponding author: gianluca.santoni@cepii.fr
 
*******************************************************************************/
********************************************************************************


clear all
program drop _all
macro drop _all
matrix drop _all
clear mata
clear matrix
   
set virtual on
set more off
set scheme s1color
set excelxlsxlargefile on
version
******************************************************************************** 
********************************************************************************
* Define your working path here: this is where you locate the "Toolkit" folder 

 global ROOT 	          "d:\santoni\Dropbox\WW_other_projs\WB_2023\WB_GE\WB_DTA_Toolkit"			 
* global ROOT 			  "C:\Users\gianl\Dropbox\WW_other_projs\WB_2023\WB_GE\WB_DTA_Toolkit"			 
*******************************************************************************/
********************************************************************************


global PROG 	          "$ROOT\0.prog"
global DATA 	          "$ROOT\1.data"
global RES  	          "$ROOT\2.res\toolkit"


global GRAVITY_COV 		  "$DATA\cty"

global CTY        		  "$DATA\cty"
global BACI	        	  "$DATA\trade"
global GRAVITY        	  "$DATA\gravity"

global NET         		  "$DATA\ntw" 
global GE         		  "$DATA\ge" 
global TEMP	     		  "$DATA\temp"


global bilateral_trade     "$DATA\cty\AGR_MAN_trade_prod_toolkit" 

global baci_version 	   "BACI_HS02_V202301"
global grav_version 	   "Gravity_V202211"
global fdate_bg			   "2002"    // for trade stats and rca
global ldate_bg			   "2021"

global ldate_bg_rta		   "2019"    // for PTA stats and rca


global ldate_bg1		   "2015"	 // for trade stats & find extensive margins counterfactuals
global ldate_bg2		   "2010"	
global ldate_bg3		   "2005"	

global first_year          "1986"
global year_start 	       "1986"
global year_end		       "2019"


global dist 			   "dist"    // for trade stats and rca

global fix_rta				"YES"    //  if yes this adjust RTA list for UZB

******************************************************************************** 
******************************************************************************** 
* Data Make (need to run only if raw data updates: INDSTAT, FAO or RTA) 

* do "$PROG\0_data_make\p1_datamake_manuf_tradeProd_v2.do"
* do "$PROG\0_data_make\\p2_datamake_agri_FAO_v2.do"

*do "$PROG\0_data_make\p2a_datamake_FAO_item.do"     // if FAO extrapolation by prod


* global covar_valid 	"rta_k*   rta_out	 INTL_BRDR_*"
*  do "$PROG\0_data_make\p3_merge_RTA_&_validate_v2.do"


* load Baci here and save version to be used in p1_trade_stats & p2_RTA_stats
*  do "$PROG\0_data_make\p4_load_baci_&_gravity.do"    

*  do "$PROG\0_data_make\p4_load_baci_&_gravity22.do"    

*******************************************************************************/
******************************************************************************** 
* Loop for the Toolkit
********************************************************************************
********************************************************************************
* 130 countries in the current version of the toolkit

* global country_interest    "ALB	ARG	ARM	AUS	AUT	AZE	BDI	BEL	BGD	BGR	BHR	BIH	BLR	BLZ	BOL	BRA	BRB	BWA	CAF	CAN	CHE	CHL	CHN	CMR	COL	CPV	CRI	CYP	CUB CZE	DEU	DNK	DZA	ECU	EGY	ERI	ESP	EST	ETH	FIN	FJI	FRA	GBR	GEO	GHA	GRC	GTM	HKG	HND	HRV	HTI	HUN	IDN	IND	IRL	IRN	IRQ	ISL	ISR	ITA	JAM	JOR	JPN	KAZ	KEN	KGZ	KOR	KWT	LAO	LBN	LKA	LTU	LUX	LVA	MAR	MDA	MDV	MEX	MKD	MLT	MMR	MNE	MNG	MOZ	MUS	MWI	MYS	NAM	NER	NGA	NLD	NOR	NPL	NZL	PAK	PER	PHL	POL	PRT	PRY	PSE	ROU	RUS	RWA	SEN	SGP	SLV	SRB	SUR	SVK	SVN	SWE	SWZ	SYR	THA	TJK	TON	TTO	TUN	TUR	TZA	UKR	URY	USA	UZB	VEN	VNM	YEM	ZAF	ZWE"  


  global country_interest    "UZB"
  global iso "UZB"
foreach iso of global country_interest {

* shell rmdir "$RES\\`iso'\\temp\\" /s /q 
*  cd "$RES\\`iso'\"
*  mkdir "temp"   
  
  
  
  
local zz = 0
global iso    "`iso'"
local iso     "$iso"

********************************************************************************
/*
Select the appropriate database to be used in the GE analysis. Note that the GE procedure requires that the database used be "square", i.e. with the same number of exporting and importing countries, and that for the procedure to be consistent with the theoretical model, all countries in the sample must have non-missing values for internal trade.

*/

use "$DATA\trade_rta_toolkit_AGRO_MAN.dta", clear
keep 	  if iso_o == iso_d
summ year if iso_o =="$iso"

********************************************************************************
if `r(N)'  == 0   {

global GE_version          "manuf"          //  
	
	
	
}
	
********************************************************************************
********************************************************************************
if  `r(N)'  != 0   {
	
global GE_version          "agri_manuf"    //  

	
}
	
********************************************************************************
********************************************************************************
* GE analysis technical parameters: do not change
********************************************************************************
********************************************************************************

global rta1_beta 				"est_RTA1"
global rta2_beta 				"est_RTA2"
global rta3_beta 				"est_RTA3"
global rta_out_beta 			"est_RTA_out"


********************************************************************************
********************************************************************************
if "$GE_version"   ==  "agri_manuf" {
* Manufacturing plus Agricolture
global ge_dataset 				"$DATA\trade_rta_toolkit_AGRO_MAN.dta"
global trade_frictions 			"trade_am_sh"
global trade        			"trade_am"

global select_dataset 			"keep if trade_am_sh != ."
global dataset_am 			    "ge_gravity_estibrated_am"
 
 }
 
********************************************************************************
********************************************************************************
if "$GE_version"   ==  "manuf" {
* Manufacturing only
global ge_dataset 				"$DATA\trade_rta_toolkit_MAN.dta"
global trade_frictions 			"trade_m_sh"
global trade        			"trade_m"

global select_dataset 			"keep if trade_m_sh != ."
global dataset_am 			    "ge_gravity_estibrated_m"
 
 }
********************************************************************************
* GE analysis customizable parameters
********************************************************************************
global sym           			"sym"									  
//  If "sym" then d_ij = d_ji, if the macro is empty "" the bilateral fixed effects for structural gravity are asymmetric.
global sigma_am 				"6"

global runs 					"15"                                      
// This is to select the number of loops to consider before declaring that the GE is not converging; if GE > $runs, it restarts with the default threshold times 1.05, i.e. 0.05*1.05.

global rank 					"10"									 
// select # countries for the optimal number of partners in the extensive margin counterfactuals
global selection_criteria   	"DS"									  
// "DS" select Extensive margin based on export all goods and imports of intermediate goods (if you set "ALL" it selects the optimal partners based on all goods for imports and expots)
global trim 					"No"									  // "YES" drops trade partners with less than 1% mkt share for each iso	
	
********************************************************************************
********************************************************************************
********************************************************************************
*  This section defines (cleans and generates) all temporary and final directories before execution on your $country_interest (please don't change the parameters).

 
   !rmdir "$RES\\`iso'\\"    /s /q    
   shell rmdir "$RES\\`iso'\\" /s /q

   mkdir "$RES\\`iso'"  

 shell rmdir "$RES\\`iso'\\temp\\" /s /q

  cd "$RES\\`iso'\"
  mkdir "temp"   
  
  
*******************************************************************************/
********************************************************************************
* This section defines the macro regions needed for analysis (do not edit).
 
	use		"$DATA\cty\WBregio_toolkit", clear
	
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

use $ge_dataset, clear
$select_dataset 

keep 						 							 if rta   == 0

gen year_iso   = year       							 if iso_o == "$iso"
egen temp_max  = max(year_iso) 
keep if year  == temp_max

preserve
keep if iso_o == "$iso"
keep iso_o iso_d $trade
rename $trade export
rename iso_d iso3
 save "$RES\\`iso'\\temp\\temp_ref_cty", replace
 restore

bys iso_o: egen totX  = total( $trade)
keep if iso_d == "$iso"
keep iso_o iso_d $trade totX
rename $trade import
rename iso_o iso3

merge 1:1 iso3 using "$RES\\`iso'\\temp\\temp_ref_cty"
drop _m

merge 1:1 iso3 using "$DATA\cty\WBregio_toolkit"
drop if _m == 2
drop _m



keep if region != "$reg_l"

sort totX 


    local temp =iso3[1]   
	global ref_cty   "`temp'"
	display "$ref_cty"												 //  it must not be directly involved in the counterfactuals
					 

*******************************************************************************/ 
********************************************************************************
/* 

Trade statistics: this section selects the data to be used to define the extensive margin counterfactuals
 (i.e., the optimal trading partners with which the target country should enter into a preferential trade agreement - extensive margin).

 p1_trade_stats_panel  : Calculate both Export and Import statistics 
 
 
*/

global covar 		"ldist rta contig comcol comlang_ethno"     // Variables that are used as proxies for bilateral trade frictions in the structural gravity.
global clus 		"i j"										// Correction of standard errors in structural gravity regressions (two way cluster)

global EU_aggregate "YES"                                        // if "YES" aggregates EU as a single Export or Import market 
 
* do "$PROG\1_trade_stats\p1_trade_stats_panel.do"
  do "$PROG\1_trade_stats\p1_trade_stats_panel_cty.do"
 
********************************************************************************
/*

RTA statistics: This section analyzes the target country's existing regime of trade agreements and
defines relevant counterfactuals to assess the deepening of existing agreements (intensive margin).

 */


  do "$PROG\1_trade_stats\p2_rta_stats_cty.do"


********************************************************************************
/* 

This section selects the optimal trading partners for extensive margin GE counterfactuals.

 */


global covar 	"ldist rta contig comcol comlang_ethno"       
global clus 	"i j"

 do "$PROG\2_choose_RTA_gravity\p1_RTA_gravity_selection.do"

********************************************************************************
********************************************************************************
* GE analysis: this section performs the GE analysis 
********************************************************************************
********************************************************************************

	
global preliminary 				"on"     // when "on" runs the preliminary gravity regs to find tau and RTA elasticities
	
 
********************************************************************************
********************************************************************************

  
  local iso     "$iso"
  do "$PROG\3_ge_simulations\1_ge_analysis_cty.do"
  
  
********************************************************************************
******************************************************************************** 

clear
set obs   1

gen     cty             = "$iso" 
gen     dataset         = "$GE_version"
gen     year            = "$year_reg" 
gen     numeraire       = "$ref_cty" 



save "$RES\\`iso'\\info_simulations.dta",  replace

 
********************************************************************************
 do "$PROG\3_ge_simulations\2_build_ge_tables.do" 
 
*******************************************************************************/

*  shell rmdir "$RES\\`iso'\\temp\\" /s /q 

}
********************************************************************************
********************************************************************************