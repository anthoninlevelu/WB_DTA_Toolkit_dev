********************************************************************************
/******************************************************************************* 
	     The Economic Impact of Deepening Trade Agreements A Toolkit

			       	   this version: JAN 2024
				   
website: https://xxxxxxx.org/

when using the tool please cite:  
Fontagné, L., Rocha, N., Ruta, M., Santoni, G. (2023),
 "The Economic Impact of Deepening Trade Agreements", World Bank Economic Review,  

         https://doi.org/10.1093/wber/lhad005.  

corresponding author: gianluca.santoni@cepii.fr
 
********************************************************************************
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

 
  global DB	             "C:\Users\gianl\Dropbox\"
  global DB              "d:\santoni\Dropbox\"


global ROOT 		     "$DB\WW_other_projs\WB_2024\WB_GE\WB_DTA_Toolkit"			 
global CODING 			 "$DB\Regionalism_2017\NADIA_project\data_sept2020\raw_rta\update_september2021"


********************************************************************************
********************************************************************************

global PROG 	          "$ROOT\0.prog"
global DATA 	          "$ROOT\1.data"
global DTA                "$DATA\DTA_toolkit_update"
global TEMP	     		  "$DATA\temp"


global dataset            "dataset-on-the-intensive-margin-january-2024"  // or dataset-on-the-intensive-margin-december-2023


*******************************************************************************/
********************************************************************************


cap 	log close
capture log using "$PROG\log_files\read_data_provisions_dec2023", text replace

********************************************************************************
********************************************************************************
********************************************************************************
/*        Clean data and put them in format for Clusters 				      */
********************************************************************************
********************************************************************************
/* v0 data  2021

import excel "$CODING\dataset-on-the-intensive-margin-september-2021_v2.xlsx", sheet("STATA") firstrow allstring clear

/*
gen agree_284    = agree_2
gen agree_285    = agree_2 
gen agree_286    = agree_2
gen agree_287    = agree_2
*/

reshape long agree_, i(Area Section Subsection Provision Coding) j(id_agree)

keep  Provision Coding
duplicates drop 
rename Provision Provision_v0 
save    "$TEMP\coding_v0", replace



*******************************************************************************/
********************************************************************************
* v2 data 2024

cd "$DTA"

import excel "$dataset", sheet("STATA") firstrow allstring clear
 
reshape long agree_, i(Area Provision Coding) j(id_agree)

rename agree_ provision_value

********************************************************************************
*******************************************************************************
* select the RTAs in the bilateral dataset 

merge m:1 id_agree using "$DATA\rta_list", keepusing(id_agree agreement)   
keep if _m == 3
drop  _m 


save    "$TEMP\provision_value_v2", replace  // 381 agreement in the cluster sample (need now to fix UK agreemts)

********************************************************************************
********************************************************************************
* Fix UK agreements

if "$uk_fix" ==  "fix_before_cluster" {
use "$DTA\uk_agree_to_be_fixed.dta", clear

rename id_agree id_agree_raw

rename id_agree_eu id_agree
drop if id_agree == .

merge 1:m id_agree using  "$TEMP\provision_value_v2"
keep if _m == 3
drop _m

keep id_agree_uk agreement provision_value Coding Provision Area
rename id_agree_uk id_agree 
gen uk_agree_to_eu = 1
save  "$TEMP\provision_value_uk_eu", replace



use "$DTA\uk_agree_to_be_fixed.dta", clear

rename id_agree id_agree_raw
drop if id_agree_eu == .

rename id_agree_uk id_agree
drop if id_agree == .
keep id_agree
merge 1:m id_agree using  "$TEMP\provision_value_v2"
drop if _m == 3
drop _m

append using "$TEMP\provision_value_uk_eu"
save    "$TEMP\provision_value_v2", replace 
}


********************************************************************************
********************************************************************************
/* 381 agreement in the cluster sample ( UK agreemts fixed with the same content as EU: )
unmatched there are no EU agreements here
365	United Kingdom - Kosovo
371	United Kingdom - SACU and Mozambique
387	United Kingdom - Kenya
392	United Kingdom - Iceland, Liechtenstein and Norway
*/

********************************************************************************
********************************************************************************

* Harmonizing coding scale: they must have ordinality 

********************************************************************************
********************************************************************************
use "$TEMP\provision_value_v2", clear



replace   provision_value = trim(provision_value)

replace   provision_value = "0" 		if provision_value =="NA"   /* set equal to 0 (is this correct ? ) */
replace   provision_value = "0" 		if provision_value =="NR"   /* set equal to 0 (is this correct ? ) */
replace   provision_value = "0" 		if provision_value =="N/A"  /* set equal to 0 (is this correct ? ) */
replace   provision_value = "0" 		if provision_value ==""     /* set equal to 0 (is this correct ? ) */
replace   provision_value = "0" 		if provision_value ==" "    /* set equal to 0 (is this correct ? ) */
 


********************************************************************************
********************************************************************************
* Antidumping

tab provision if strpos( Area , "Antidumping")

* Coding: Duration and review of anti-dumping duties and price undertakings Antidumping Duties - prov_34; Antidumping Duties - prov_33

replace   provision_value = "1.5" 	if provision_value =="1 - 3 years"  				 &  strpos( Area , "Antidumping") & strpos( Coding , "prov_34")
replace   provision_value = "5" 	if provision_value =="5 years"  					 &  strpos( Area , "Antidumping")  & strpos( Coding , "prov_33")

 
* Coding: Notification/Consultation (1=yes, 0=no) if yes, length of period (days):Antidumping Duties - prov_18  Antidumping Duties - prov_42

replace   provision_value = "12" 	if provision_value=="15/10"       					 &   strpos( Area , "Antidumping") & ( strpos( Coding ,    "prov_18") | strpos( Coding ,    "prov_42") ) 
 
 
 

/* min  non 0 value */
replace   provision_value = "5" 	if provision_value=="as soon as possible"       	 &   strpos( Area , "Antidumping") & ( strpos( Coding ,    "prov_18") | strpos( Coding ,    "prov_42") ) 

/* average non 0 value */
replace   provision_value = "27" 	if provision_value=="within reaso0ble time frames" 	 &   strpos( Area , "Antidumping") & ( strpos( Coding ,    "prov_18") | strpos( Coding ,    "prov_42") ) 
 
********************************************************************************
********************************************************************************
* Competition Policy

tab provision if strpos( Area , "Competition Policy")

* All 0/1/3 
* 3 // Does the agreement promote open markets either (1) economy wide, (2) sector specific or (3) both? 



********************************************************************************
********************************************************************************
* Countervailing Duties: Countervailing Duties - prov_16

tab provision if strpos( Area , "Countervailing Duties")

replace   provision_value = "30" 	if provision_value=="30 days"       				 &   strpos( Area , "Countervailing Duties") &   strpos( Coding , "prov_16")


********************************************************************************
********************************************************************************
* Environmental Laws

tab provision if strpos( Area , "Environmental Laws")
* All 0/1


********************************************************************************
********************************************************************************
* Export Restrictions

tab provision if strpos( Area , "Export Restrictions")
* All 0/1



********************************************************************************
********************************************************************************
* Intellectual Property Rights (IPR)

tab provision if strpos( Area , "Intellectual Property Rights (IPR)")
* All 0/1



********************************************************************************
********************************************************************************
* Investment

tab provision if strpos( Area , "Investment")
* All 0/1 there is one missing what does it mean? this is Agreement 159 (United States - Oman)

replace   provision_value = "0"  	 	if provision_value==" "        &   strpos( Area , "Investment") &    strpos(Coding, "prov_46")
replace   provision_value = "0"  	 	if provision_value==""         &   strpos( Area , "Investment") &    strpos(Coding, "prov_46")


********************************************************************************
********************************************************************************
* Labor Market Regulations

tab provision if strpos( Area , "Labor Market Regulations")
* All 0/1

********************************************************************************
********************************************************************************
* Movement of Capital

tab provision if strpos( Area , "Movement of Capital")
* All 0/1


********************************************************************************
********************************************************************************
* Public Procurement (this is a mess most of the provisions do not have any ordinality: all 100 provisions have at least one non binary entry)

tab provision if strpos( Area , "Public Procurement")

/*

0	31,426	84.95	84.96
1	5,295	14.31	99.28

*/


replace   provision_value = "0"  	 	if provision_value==""   &   strpos( Area , "Public Procurement")
replace   provision_value = "0"  	 	if provision_value==" "  &   strpos( Area , "Public Procurement")

/* How many days does the agreement allow for the publication of award information? (please indicate for all members of the agreement): from 1/0 to  "For for a reasonable period of time", Public Procurement - prov_86 */
replace provision = "1"  if provision != "0"   & strpos( Area , "Public Procurement")  &    strpos(Coding, "prov_86")


/* there are 99 Provisions here with non-ordinal coding we abstract now. Need to discuss this. */
replace provision = "1"  if provision != "0"    &   strpos( Area , "Public Procurement")

/* Example below how do we code the non binary entry? 

tab provision if Provision =="How many aggregate services sectors from the GATS W/120 does the agreement cover?  (please indicate for all members of the agreement)"
 
                        provision_value |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
                                      0 |        281       76.15       76.15
                                      1 |         69       18.70       94.85
                                     12 |          1        0.27       95.12
                  Annex 13-A, Section E |          1        0.27       95.39
                   Annex 9-A, Section E |          1        0.27       95.66
                         See Annex 19-4 |          1        0.27       95.93
                 See Annex 19-4 of CETA |          1        0.27       96.21
                See Annex 25, Section B |          1        0.27       96.48
                       See Annexes 13-E |          1        0.27       96.75
            See Appendix 5 to Annex XVI |          1        0.27       97.02
    See Parties' Annexes 5-6 to the GPA |          1        0.27       97.29
See Parties' Annexes 5-6 to the GPA; .. |          1        0.27       97.56
               See Section E, Annex 16A |          2        0.54       98.10
      See services listed in Annex 10-4 |          1        0.27       98.37
                          not indicated |          1        0.27       98.64
only available for Japan: Part 2, Sec.. |          1        0.27       98.92
               see Annex 8-A, Section E |          1        0.27       99.19
                          see Annex 9-E |          1        0.27       99.46
            see Section D of Annex 13-A |          1        0.27       99.73
       see details in Annex 10A and 10B |          1        0.27      100.00
----------------------------------------+-----------------------------------
                                  Total |        369      100.00
 
 */

********************************************************************************
********************************************************************************
* Rules of Origin

tab provision if strpos( Area , "Rules of Origin")




 
* Coding:  Is the price basis for the content threshold requirement the FOB/net price?  (Rules of Origin - roo_vcr_fnt)  
replace   provision_value = "1"  	if provision_value=="CIF"         & strpos( Area , "Rules of Origin") &    strpos(Coding, "roo_vcr_fnt")
replace   provision_value = "1"  	if provision_value=="FOB"         & strpos( Area , "Rules of Origin") &    strpos(Coding, "roo_vcr_fnt")

  
* are the two provision below really different: Does the agreement contain drawback rules?   Rules of Origin - roo_drb // Does the agreement allow drawback ?  Rules of Origin - roo_dba

replace   provision_value = "2"  	if provision_value=="Zona Franca"  & strpos( Area , "Rules of Origin")  &    strpos(Coding, "roo_drb")
replace   provision_value = "2"  	if provision_value=="Free Zones"   & strpos( Area , "Rules of Origin")  &    strpos(Coding, "roo_dba")

/*
tab provis if strpos( Provision , "Does the agreement contain drawback" ) | strpos( Provision , "Does the agreement allow drawback" )

                        provision_value |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
                                      0 |        545       80.38       80.38
                                      1 |        128       18.88       99.26
                             Free Zones |          4        0.59       99.85
                            Zona Franca |          1        0.15      100.00
----------------------------------------+-----------------------------------
                                  Total |        678      100.00
*/


******************************************************************************** 
* Coding: Rules of Origin - roo_cer_ex2. Certification What is the threshold for exemption in $US ?  Rules of Origin - roo_cer_ex2

replace   provision_value = "750" 	if provision_value      =="1000AUD/ 6000 RMB"              & strpos( Area , "Rules of Origin")  & strpos(Coding, "roo_cer_ex2")
replace   provision_value = "500" 	if provision_value      =="500EUR"                         & strpos( Area , "Rules of Origin")  & strpos(Coding, "roo_cer_ex2")
replace   provision_value = "1000" 	if provision_value      =="500 (or 1500 luggage)"          & strpos( Area , "Rules of Origin")  & strpos(Coding, "roo_cer_ex2")
replace   provision_value = "1000" 	if provision_value      =="500 EUR (or 1500 in luggage)"   & strpos( Area , "Rules of Origin")  & strpos(Coding, "roo_cer_ex2")

replace   provision_value = "1000" 	if strpos(provision_value,  "500 USD/1200")                & strpos( Area , "Rules of Origin")  & strpos(Coding, "roo_cer_ex2")
replace   provision_value = "1000" 	if strpos(provision_value,  "500/1200")                    & strpos( Area , "Rules of Origin")  & strpos(Coding, "roo_cer_ex2")
replace   provision_value = "1000" 	if strpos(provision_value,  "500 for small packages")      & strpos( Area , "Rules of Origin")  & strpos(Coding, "roo_cer_ex2")
replace   provision_value = "1000" 	if strpos(provision_value,  "500 (EUR)/1200 (EUR)")        & strpos( Area , "Rules of Origin")  & strpos(Coding, "roo_cer_ex2")
replace   provision_value = "1000" 	if strpos(provision_value,  "500 EUR; 1200 EUR")           & strpos( Area , "Rules of Origin")  & strpos(Coding, "roo_cer_ex2")
replace   provision_value = "1000" 	if strpos(provision_value,  "EUR 500; 1,200")              & strpos( Area , "Rules of Origin")  & strpos(Coding, "roo_cer_ex2")

replace   provision_value = "1200" 	if strpos(provision_value,  "1000 AUS Dollars")            & strpos( Area , "Rules of Origin")  & strpos(Coding, "roo_cer_ex2")
replace   provision_value = "1500" 	if strpos(provision_value,  "1200 Euro")                   & strpos( Area , "Rules of Origin")  & strpos(Coding, "roo_cer_ex2")
replace   provision_value = "750" 	if strpos(provision_value,  "100 USD; 500 Pound")          & strpos( Area , "Rules of Origin")  & strpos(Coding, "roo_cer_ex2")


replace   provision_value = "1500" 	if strpos(provision_value,  "1000 Pound")                  & strpos( Area , "Rules of Origin")  & strpos(Coding, "roo_cer_ex2")

********************************************************************************
********************************************************************************

* low value exemption is assumed to be shallow (minimun 200 in the data)
 cap drop temp 
 destring provision_value, gen(temp) force

replace   provision_value = "150" 	if temp == .		& 		provision_value != ""	       & strpos( Area , "Rules of Origin")  & strpos(Coding, "roo_cer_ex2")
replace   provision_value = "0" 	if temp == .		& 		provision_value == ""	       & strpos( Area , "Rules of Origin")  & strpos(Coding, "roo_cer_ex2")
replace   provision_value = "0" 	if temp == .		& 		provision_value == ""	       & strpos( Area , "Rules of Origin")  & strpos(Coding, "roo_cer_ex2")

 cap drop temp 

 
******************************************************************************** 
********************************************************************************
* What is the length of the validity period for the certificate of origin?  Rules of Origin - roo_cer_val
cap drop temp 
destring provision_value, gen(temp) force
	tab 	prov 				    if temp == . 								  & strpos( Area , "Rules of Origin")  & strpos(Coding, "roo_cer_val")


replace   provision_value = "12" 	if strpos(provision_value,  "1 year")          & strpos( Area , "Rules of Origin") & strpos(Coding, "roo_cer_val")
replace   provision_value = "12" 	if strpos(provision_value,  "1 to 2")          & strpos( Area , "Rules of Origin") & strpos(Coding, "roo_cer_val")
replace   provision_value = "6" 	if strpos(provision_value,  "180 days")        & strpos( Area , "Rules of Origin") & strpos(Coding, "roo_cer_val")
replace   provision_value = "4" 	if strpos(provision_value,  "4 months")        & strpos( Area , "Rules of Origin") & strpos(Coding, "roo_cer_val")
replace   provision_value = "10" 	if strpos(provision_value,  "10 months")       & strpos( Area , "Rules of Origin") & strpos(Coding, "roo_cer_val")
replace   provision_value = "12" 	if strpos(provision_value,  "12 months")       & strpos( Area , "Rules of Origin") & strpos(Coding, "roo_cer_val")

replace   provision_value = "12" 	if strpos(provision_value,  "1")               & strpos( Area , "Rules of Origin") & strpos(Coding, "roo_cer_val")
replace   provision_value = "0" 	if temp == .	& 	provision_value == ""	   & strpos( Area , "Rules of Origin") & strpos(Coding, "roo_cer_val")

cap drop temp 



/*
also most of the provision_value ="1" seems to be actually 12 months (RCEP, EU-Vietnam etc...)
shall I assume the baseline is months? EU-UK seems to be within 24 months but in the data it is reported "1 to 2"

. tab prov if strpos( Area , "Rules of Origin") & strpos( Provision , "What is the length of the validity period")

                        provision_value |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
                                      0 |         85       25.00       25.00
                                      1 |         25        7.35       32.35
                                 1 to 2 |          1        0.29       32.65
                                 1 year |          3        0.88       33.53
                                     10 |         13        3.82       37.35
                              10 months |          2        0.59       37.94
                                     12 |         93       27.35       65.29
                              12 months |          6        1.76       67.06
                               180 days |          2        0.59       67.65
                                     24 |         19        5.59       73.24
                                      4 |         67       19.71       92.94
                               4 months |          3        0.88       93.82
                                     48 |         10        2.94       96.76
                                      6 |         11        3.24      100.00
----------------------------------------+-----------------------------------
                                  Total |        340      100.00
*/
 
 
******************************************************************************** 
******************************************************************************** 
* What is the de minimis percentage?  Rules of Origin - roo_cum_dm2
cap drop temp 
 destring provision_value, gen(temp) force
tab prov if temp == . & strpos( Area , "Rules of Origin")    & strpos(Coding, "roo_cum_dm2")

replace   provision_value = "10" 	if strpos(provision_value,  "10 percent")        & strpos( Area , "Rules of Origin") & strpos(Coding, "roo_cum_dm2")
replace   provision_value = "15" 	if strpos(provision_value,  "15 percent")        & strpos( Area , "Rules of Origin") & strpos(Coding, "roo_cum_dm2")
replace   provision_value = "12" 	if strpos(provision_value,  "10-15%")        	 & strpos( Area , "Rules of Origin") & strpos(Coding, "roo_cum_dm2")
replace   provision_value = "10" 	if strpos(provision_value,  ".1")        	     & strpos( Area , "Rules of Origin") & strpos(Coding, "roo_cum_dm2")


/*not sure what 1;7;/10 means  give the average: 10 */
replace   provision_value = "10" 	if temp == .	& 		provision_value != ""    & strpos( Area , "Rules of Origin") & strpos(Coding, "roo_cum_dm2")
replace   provision_value = "0" 	if temp == .	& 		provision_value == ""	 & strpos( Area , "Rules of Origin") & strpos(Coding, "roo_cum_dm2")
cap drop temp 


*********************************************************************************
*********************************************************************************
* What is the percentage of value content required?  roo_vcr_per   What is the percentage of value content required with alt method?  roo_vcr_per2

cap drop temp 
 destring provision_value, gen(temp) force
tab prov 							if temp == .									 & strpos( Area , "Rules of Origin") & (   strpos( Coding , "roo_vcr_per") | strpos( Coding , "roo_vcr_per2")  )

replace   provision_value = "25" 	if strpos(provision_value,  "25 percent")        & strpos( Area , "Rules of Origin") & (   strpos( Coding , "roo_vcr_per") | strpos( Coding , "roo_vcr_per2")  )
replace   provision_value = "35" 	if strpos(provision_value,  "35 percent")        & strpos( Area , "Rules of Origin") & (   strpos( Coding , "roo_vcr_per") | strpos( Coding , "roo_vcr_per2")  )
replace   provision_value = "40" 	if strpos(provision_value,  "40 percent")        & strpos( Area , "Rules of Origin") & (   strpos( Coding , "roo_vcr_per") | strpos( Coding , "roo_vcr_per2")  )
replace   provision_value = "45" 	if strpos(provision_value,  "45 percent")        & strpos( Area , "Rules of Origin") & (   strpos( Coding , "roo_vcr_per") | strpos( Coding , "roo_vcr_per2")  )
replace   provision_value = "10" 	if strpos(provision_value,  ".1")        		 & strpos( Area , "Rules of Origin") & (   strpos( Coding , "roo_vcr_per") | strpos( Coding , "roo_vcr_per2")  )



/*not sure what "See Annex" means  give the average: 33.3% (most of "see annex" are UK agreements) */
replace   provision_value = "33.3" 	if temp == .	& 		provision_value != ""	 & strpos( Area , "Rules of Origin") & (   strpos( Coding , "roo_vcr_per") | strpos( Coding , "roo_vcr_per2")  )
replace   provision_value = "0" 	if temp == .	& 		provision_value == ""	 & strpos( Area , "Rules of Origin") & (   strpos( Coding , "roo_vcr_per") | strpos( Coding , "roo_vcr_per2")  )

********************************************************************************
********************************************************************************
* What is the length of the record keeping period?  roo_cer_rec

cap drop temp 
 destring provision_value, gen(temp) force
tab prov						    if temp == . 								  & strpos( Area , "Rules of Origin")  &  strpos( Coding , "roo_cer_rec")


replace   provision_value = "3" 	if strpos(provision_value,  "3 years")        & strpos( Area , "Rules of Origin")  &  strpos( Coding , "roo_cer_rec")
replace   provision_value = "4" 	if strpos(provision_value,  "4 years")        & strpos( Area , "Rules of Origin")  &  strpos( Coding , "roo_cer_rec")
replace   provision_value = "5" 	if strpos(provision_value,  "5 years")        & strpos( Area , "Rules of Origin")  &  strpos( Coding , "roo_cer_rec")


replace   provision_value = "0" 	if temp == .	& 		provision_value == "" & strpos( Area , "Rules of Origin")  &  strpos( Coding , "roo_cer_rec")

cap drop temp 

********************************************************************************
********************************************************************************
* Sanitary and Phytosanitary Measures

tab provision if strpos( Area , "Sanitary and Phytosanitary Measures")

/* All 0/1 there are 2 entry with 2 and 1 entry with 3.
 what does it mean? the provision states "Is there an SPS chapter or provision?" so why 2 or 3 and not just 1/0? 

 id agree 45 has entry 3 (Commonwealth of Independent States (CIS)) in provision  Sanitary and Phytosanitary Measures (SPS) - prov_02
 id agree 45 has entry 2 in provision: Sanitary and Phytosanitary Measures (SPS) - prov_47 and prov_04
*/

replace   provision_value = "1" 	if strpos(provision_value,  "3")        & strpos( Area , "Sanitary and Phytosanitary Measures") & strpos( Coding  ,  "(SPS) - prov_02")
replace   provision_value = "1" 	if strpos(provision_value,  "2")        & strpos( Area , "Sanitary and Phytosanitary Measures") & strpos( Coding  ,  "(SPS) - prov_47")
replace   provision_value = "1" 	if strpos(provision_value,  "2")        & strpos( Area , "Sanitary and Phytosanitary Measures") & strpos( Coding  ,  "(SPS) - prov_04")

********************************************************************************
********************************************************************************
* Services

tab provision if strpos( Area , "Services")


cap drop temp 
destring provision_value, gen(temp) force
tab prov if temp ==  . &   strpos( Area , "Services")
 
 
 
********************************************************************************
* Coding: Services - roo_m3
/*

tab Provision if temp ==  . &   strpos( Area , "Services") & strpos(Coding, "roo_m3")


Subsection	Provision
Rules of origin for juridical persons	To be considered a service supplier of a party to the agreement, in the case of the supply of services through commercial presences, does a juridical person have to: 
A. Be owned or controlled by natural persons of the other party
B. Be owned or controlled by persons of the other party (whether juridical or natural) AND have substantial business operations (in the other party or a third party)
C. C. Be owned or controlled by juridical persons of the other party AND have substantial business operations (in the other party, a third party or WTO Members
D. Be (i) owned or controlled by natural persons of the other party, OR (ii) be owned or controlled by juridical persons of the other party AND have substantial business operations (in the other party or a third party)
E. Incorporated under the domestic law of the party; 
F. Incorporated under the domestic law of the party and have substantive business operations in the territory of a member
G. Other (please specify in the comments)
*/

tab prov     							 if temp ==  . 				 &   strpos( Area , "Services") & strpos(Coding, "roo_m3")


replace   provision_value = "C"  	 	if provision_value=="A,B,C"  &   strpos( Area , "Services") & strpos(Coding, "roo_m3")
replace   provision_value = "6"  	 	if provision_value=="A"  	 &   strpos( Area , "Services") & strpos(Coding, "roo_m3")
replace   provision_value = "5"  	 	if provision_value=="B"  	 &   strpos( Area , "Services") & strpos(Coding, "roo_m3")
replace   provision_value = "4"  	 	if provision_value=="C"  	 &   strpos( Area , "Services") & strpos(Coding, "roo_m3")
replace   provision_value = "3"  	 	if provision_value=="D"  	 &   strpos( Area , "Services") & strpos(Coding, "roo_m3")
replace   provision_value = "2"  	 	if provision_value=="E"  	 &   strpos( Area , "Services") & strpos(Coding, "roo_m3")	
replace   provision_value = "1"  	 	if provision_value=="F"  	 &   strpos( Area , "Services") & strpos(Coding, "roo_m3") 		
replace   provision_value = "1"  	 	if provision_value=="G"  	 &   strpos( Area , "Services") & strpos(Coding, "roo_m3")	

replace   provision_value = "0" 		if temp == .	& 		provision_value == ""	 & strpos( Area , "Services") & strpos(Coding, "roo_m3")


cap drop temp 
destring provision_value, gen(temp) force
tab Coding if temp ==  . &   strpos( Area , "Services")
 
		
********************************************************************************
********************************************************************************
* Coding: Services - othdip_monr. 
/*

SUBSTANTIVE DISCIPLINES If yes,  does it contain it to
 A. protect the interest of foreign suppliers, 
 B. protect consumers?

*/

tab prov      if temp ==  . &   strpos( Area , "Services") & strpos(Coding, "othdip_monr")
		
replace   provision_value = "1"  	 	if provision_value=="B"  	   &   strpos( Area , "Services") & strpos(Coding, "othdip_monr")
replace   provision_value = "2"  	 	if provision_value=="A,B"      &   strpos( Area , "Services") & strpos(Coding, "othdip_monr")
replace   provision_value = "2"  	 	if provision_value=="A; B"     &   strpos( Area , "Services") & strpos(Coding, "othdip_monr")
replace   provision_value = "3"  	 	if provision_value=="A"  	   &   strpos( Area , "Services") & strpos(Coding, "othdip_monr")

replace   provision_value = "0" 	if temp == .	& 		provision_value == ""	 &   strpos( Area , "Services") & strpos(Coding, "othdip_monr")

********************************************************************************
********************************************************************************
* Coding: Services - trans_comm_nat. 

/*
 Subsection	Provision
Transparency	Please indicate the nature of the discipline above: 
A. General obligation and mandatory nature
B. Obligation subject to limitations or reservations
C. General obligation, but best endeavour nature
D. Voluntary obligation
*/
	
tab prov      if temp ==  . &   strpos( Area , "Services") & strpos(Coding, "trans_comm_nat")
	

replace   provision_value = "A"  	 	if provision_value=="A,C"      &   strpos( Area , "Services") & strpos(Coding, "trans_comm_nat")

replace   provision_value = "1"  	 	if provision_value=="A"        &   strpos( Area , "Services") & strpos(Coding, "trans_comm_nat")
replace   provision_value = "2"  	 	if provision_value=="B"  	   &   strpos( Area , "Services") & strpos(Coding, "trans_comm_nat")
replace   provision_value = "3"  	 	if provision_value=="C"  	   &   strpos( Area , "Services") & strpos(Coding, "trans_comm_nat")
replace   provision_value = "4"  	 	if provision_value=="D"  	   &   strpos( Area , "Services") & strpos(Coding, "trans_comm_nat")

replace   provision_value = "0" 	if temp == .	& 		provision_value == ""	  &   strpos( Area , "Services") & strpos(Coding, "trans_comm_nat")

********************************************************************************
********************************************************************************
* Coding: Services - roo_m4. 
cap drop temp 
destring provision_value, gen(temp) force
tab Coding if temp ==  . &   strpos( Area , "Services")
 
 
/*
Subsection	Provision
Rules of origin for natural persons	To be considered a service supplier of a party to the agreement, do natural persons have to:
A . Have a center of economic interest in the territory of a party; 
B. Be resident in the territory of a party; or 
C. Be a national of a party ?


*/

tab prov      if temp ==  . &   strpos( Area , "Services") & strpos(Coding, "roo_m4")


replace   provision_value = "3"  	 	if provision_value=="A"        &   strpos( Area , "Services") & strpos(Coding, "roo_m4")

replace   provision_value = "2"  	 	if provision_value=="B"  	   &   strpos( Area , "Services") & strpos(Coding, "roo_m4")
replace   provision_value = "2"  	 	if provision_value=="B and C"  &   strpos( Area , "Services") & strpos(Coding, "roo_m4")
replace   provision_value = "2"  	 	if provision_value=="B or C"   &   strpos( Area , "Services") & strpos(Coding, "roo_m4")
replace   provision_value = "2"  	 	if provision_value=="B, C"     &   strpos( Area , "Services") & strpos(Coding, "roo_m4")

replace   provision_value = "2"  	 	if provision_value=="B for Hong Kong; C for Georgia"     &   strpos( Area , "Services") & strpos(Coding, "roo_m4")



replace   provision_value = "1"  	 	if provision_value=="C"  	   &   strpos( Area , "Services") & strpos(Coding, "roo_m4")
replace   provision_value = "1"  	 	if provision_value=="E"  	   &   strpos( Area , "Services") & strpos(Coding, "roo_m4")   /* ATT: E is undocumented, apply most restrictive  */

replace   provision_value = "0" 	if temp == .	& 		provision_value == ""	  &   strpos( Area , "Services") & strpos(Coding, "roo_m4")

 
********************************************************************************
********************************************************************************
* Coding: Services - dr_mutrec_nat
cap drop temp 
destring provision_value, gen(temp) force
tab Coding if temp ==  . &   strpos( Area , "Services")
 
/*

Subsection	Provision
Domestic Regulation (DR)	Please indicate the nature of the discipline above: 
A. General obligation and mandatory nature
B. Obligation subject to limitations or reservations
C. General obligation, but best endeavour nature
D. Voluntary obligation


*/
tab prov      if temp ==  . &   strpos( Area , "Services") & strpos(Coding, "dr_mutrec_nat")


replace   provision_value = "1"  	 	if provision_value=="A"        &   strpos( Area , "Services") & strpos(Coding, "dr_mutrec_nat")
replace   provision_value = "2"  	 	if provision_value=="B"  	   &   strpos( Area , "Services") & strpos(Coding, "dr_mutrec_nat")
replace   provision_value = "3"  	 	if provision_value=="C"  	   &   strpos( Area , "Services") & strpos(Coding, "dr_mutrec_nat")
replace   provision_value = "4"  	 	if provision_value=="C, D"     &   strpos( Area , "Services") & strpos(Coding, "dr_mutrec_nat")
replace   provision_value = "4"  	 	if provision_value=="D"  	   &   strpos( Area , "Services") & strpos(Coding, "dr_mutrec_nat")

replace   provision_value = "0" 	if temp == .	& 		provision_value == ""	  &   strpos( Area , "Services") & strpos(Coding, "dr_mutrec_nat")


********************************************************************************
********************************************************************************
* Coding: Services - dr_objec_nat

/*

Subsection	Provision
Domestic Regulation (DR)	Please indicate the nature of the discipline above: 
A. General obligation and mandatory nature
B. Obligation subject to limitations or reservations
C. General obligation, but best endeavour nature
D. Voluntary obligation


*/
tab prov      if temp ==  . &   strpos( Area , "Services") & strpos(Coding, "dr_objec_nat")


replace   provision_value = "1"  	 	if provision_value=="A"        &   strpos( Area , "Services") & strpos(Coding, "dr_objec_nat")
replace   provision_value = "2"  	 	if provision_value=="B"  	   &   strpos( Area , "Services") & strpos(Coding, "dr_objec_nat")
replace   provision_value = "3"  	 	if provision_value=="C"  	   &   strpos( Area , "Services") & strpos(Coding, "dr_objec_nat")
replace   provision_value = "4"  	 	if provision_value=="D"  	   &   strpos( Area , "Services") & strpos(Coding, "dr_objec_nat")

replace   provision_value = "0" 	if temp == .	& 		provision_value == ""	  &   strpos( Area , "Services") & strpos(Coding, "dr_objec_nat")


********************************************************************************
********************************************************************************
* Coding: Services - struc

/*

Subsection	Provision
Structure of how modes of supply organized	How is services trade structured in this agreement: Please choose one of the options.
A:  All 4 modes covered in a self-contained chapter (plus an Annex on M4, as in the GATS)? 
B : All 4 modes covered in a self-contained chapter (plus an Annex on M4) and an additional Investment chapter/protocol. 
C. Chapter on cross-border trade in services (as in NAFTA, M1, M2 and M4), PLUS one chapter on investment (dealing with M3) and other annexes/chapters on movement of persons.
D. Chapter on cross-border trade in services (M1 & M2), plus an investment chapter (M3), plus a chapter on movement of persons (M4), as in CETA.


*/
tab prov      if temp ==  . &   strpos( Area , "Services") &  (Coding == "Services - struc")


replace   provision_value = "1"  	 	if provision_value=="A"        &   strpos( Area , "Services") &  (Coding == "Services - struc")
replace   provision_value = "2"  	 	if provision_value=="B"  	   &   strpos( Area , "Services") &  (Coding == "Services - struc")
replace   provision_value = "3"  	 	if provision_value=="C"  	   &   strpos( Area , "Services") &  (Coding == "Services - struc")
replace   provision_value = "4"  	 	if provision_value=="D"  	   &   strpos( Area , "Services") &  (Coding == "Services - struc")

replace   provision_value = "0" 	if temp == .	& 		provision_value == ""	  &   strpos( Area , "Services") &  (Coding == "Services - struc")


********************************************************************************
********************************************************************************
* Coding: Services - dis_ma  (DETAILS NEEDED)

/*

Area	         Section	         Subsection	     Provision
Services	SUBSTANTIVE DISCIPLINES	Market access	How is the market access obligation defined?:  
A: As defined in the GATS (by reference to 6 prohibited market access limitations)
B:  As defined in the US FTAs (by reference to 5 prohibited market access limitations, and omitting foreign equity limitations)  
C:  Other (no provision on market access; used different definitions; or other reasons)


*/

tab prov      if temp ==  . &   strpos( Area , "Services") & strpos(Coding, "dis_ma")


replace   provision_value = "3"  	 	if provision_value=="A"        &   strpos( Area , "Services") & strpos(Coding, "dis_ma")
replace   provision_value = "2"  	 	if provision_value=="B"  	   &   strpos( Area , "Services") & strpos(Coding, "dis_ma")
replace   provision_value = "1"  	 	if provision_value=="C"  	   &   strpos( Area , "Services") & strpos(Coding, "dis_ma")


replace   provision_value = "0" 	if temp == .	& 		provision_value == ""	 &   strpos( Area , "Services") & strpos(Coding, "dis_ma")

********************************************************************************
********************************************************************************
* Coding: Services - dispute

/*

Subsection	Provision
Rules of origin for natural persons	Please indicate which one of the following dispute settlement provision apply to the  services agreement? 
A.  State-state dispute settlement; 
B.  Investors-state dispute setllement; 
C.  Both


*/

tab prov      if temp ==  . &   strpos( Area , "Services") & strpos(Coding, "dispute")

 

replace   provision_value = "1"  	 	if provision_value=="A"        &   strpos( Area , "Services") & strpos(Coding, "dispute")
replace   provision_value = "2"  	 	if provision_value=="B"  	   &   strpos( Area , "Services") & strpos(Coding, "dispute")	
replace   provision_value = "3"  	 	if provision_value=="C"  	   &   strpos( Area , "Services") & strpos(Coding, "dispute")
 

replace   provision_value = "0" 	if temp == .	& 		provision_value == ""	 &   strpos( Area , "Services") & strpos(Coding, "dispute")


********************************************************************************
********************************************************************************
* Coding: Services - dr_inf_nat

/*
Subsection	Provision
Domestic Regulation (DR)	Please indicate the nature of the discipline above: 
A. General obligation and mandatory nature
B. Obligation subject to limitations or reservations
C. General obligation, but best endeavour nature
D. Voluntary obligation


*/

tab prov      if temp ==  . &   strpos( Area , "Services") & strpos(Coding, "dr_inf_nat")


replace   provision_value = "1"  	 	if provision_value=="A"        &   strpos( Area , "Services") & strpos(Coding, "dr_inf_nat")
replace   provision_value = "2"  	 	if provision_value=="B"  	   &   strpos( Area , "Services") & strpos(Coding, "dr_inf_nat")
replace   provision_value = "3"  	 	if provision_value=="C"  	   &   strpos( Area , "Services") & strpos(Coding, "dr_inf_nat")
replace   provision_value = "4"  	 	if provision_value=="D"  	   &   strpos( Area , "Services") & strpos(Coding, "dr_inf_nat")


replace   provision_value = "0" 	if temp == .	& 		provision_value == ""	  &   strpos( Area , "Services") & strpos(Coding, "dr_inf_nat")

********************************************************************************
********************************************************************************
* Coding: Services - dr_licdec_nat

/*
Subsection	Provision
Domestic Regulation (DR)	Please indicate the nature of the discipline above: 
A. General obligation and mandatory nature
B. Obligation subject to limitations or reservations
C. General obligation, but best endeavour nature
D. Voluntary obligation


*/


tab prov      if temp ==  . &   strpos( Area , "Services") & strpos(Coding, "dr_licdec_nat")


replace   provision_value = "1"  	 	if provision_value=="A"        &   strpos( Area , "Services") & strpos(Coding, "dr_licdec_nat")
replace   provision_value = "2"  	 	if provision_value=="B"  	   &   strpos( Area , "Services") & strpos(Coding, "dr_licdec_nat")
replace   provision_value = "3"  	 	if provision_value=="C"  	   &   strpos( Area , "Services") & strpos(Coding, "dr_licdec_nat")
replace   provision_value = "4"  	 	if provision_value=="D"  	   &   strpos( Area , "Services") & strpos(Coding, "dr_licdec_nat")

replace   provision_value = "0" 	if temp == .	& 		provision_value == ""	   &   strpos( Area , "Services") & strpos(Coding, "dr_licdec_nat")



********************************************************************************
********************************************************************************
* Coding: Services - dr_status_nat

/*
Subsection	Provision
Domestic Regulation (DR)	Please indicate the nature of the discipline above: 
A. General obligation and mandatory nature
B. Obligation subject to limitations or reservations
C. General obligation, but best endeavour nature
D. Voluntary obligation


*/

tab prov      if temp ==  . &   strpos( Area , "Services") & strpos(Coding, "dr_status_nat")


replace   provision_value = "1"  	 	if provision_value=="A"       &   strpos( Area , "Services") & strpos(Coding, "dr_status_nat")	
replace   provision_value = "2"  	 	if provision_value=="B"  	  &   strpos( Area , "Services") & strpos(Coding, "dr_status_nat")	
replace   provision_value = "3"  	 	if provision_value=="C"  	  &   strpos( Area , "Services") & strpos(Coding, "dr_status_nat")
replace   provision_value = "4"  	 	if provision_value=="D"  	  &   strpos( Area , "Services") & strpos(Coding, "dr_status_nat")

replace   provision_value = "0" 	if temp == .	& 		provision_value == ""	&   strpos( Area , "Services") & strpos(Coding, "dr_status_nat")




********************************************************************************
********************************************************************************
* Coding: Services - s_lib_app

/*

Subsection	Provision
Liberalization approach	In the case of disciplines subject to scheduling/reservations (i.e. market access), what is the approach followed?: 
A. Positive list (as in GATS)
B. Negative list (as in NAFTA)
C. Other (including combinations of the previous ones depending on the discipline, e.g. positive list for MA and negative list for NT): If C, please give details in the comments


*/

tab prov      if temp ==  . &   strpos( Area , "Services") & strpos(Coding, "s_lib_app")


replace   provision_value = "1"  	 	if provision_value=="A"        &   strpos( Area , "Services") & strpos(Coding, "s_lib_app")
replace   provision_value = "2"  	 	if provision_value=="B"  	   &   strpos( Area , "Services") & strpos(Coding, "s_lib_app")
replace   provision_value = "2"  	 	if provision_value=="C"  	   &   strpos( Area , "Services") & strpos(Coding, "s_lib_app")

replace   provision_value = "0" 	if temp == .	& 		provision_value == ""	&   strpos( Area , "Services") & strpos(Coding, "s_lib_app")


********************************************************************************
********************************************************************************
* Coding: Services - trans_nat

/*
Subsection	Provision
Transparency	Please indicate the nature of the discipline above: 
A. General obligation and mandatory nature
B. Obligation subject to limitations or reservations
C. General obligation, but best endeavour nature
D. Voluntary obligation


*/

tab prov      if temp ==  . &   strpos( Area , "Services") & strpos(Coding, "trans_nat")


replace   provision_value = "1"  	 	if provision_value=="A"        &   strpos( Area , "Services") & strpos(Coding, "trans_nat")	
replace   provision_value = "2"  	 	if provision_value=="B"  	   &   strpos( Area , "Services") & strpos(Coding, "trans_nat")	
replace   provision_value = "3"  	 	if provision_value=="C"  	   &   strpos( Area , "Services") & strpos(Coding, "trans_nat")
replace   provision_value = "4"  	 	if provision_value=="D"  	   &   strpos( Area , "Services") & strpos(Coding, "trans_nat")


replace   provision_value = "0" 	if temp == .	& 		provision_value == ""	 &   strpos( Area , "Services") & strpos(Coding, "trans_nat")


********************************************************************************
********************************************************************************
* Coding: Services - dr

/*

Subsection	Provision
Domestic Regulation (DR)	Does the agreement contain provision requiring regulatory measures to be necessary to attain legitimate objectives?: 
A. No
B. Limited to qualification, licensing, and technical standards
C. Applicable to all types of regulation


*/

tab prov      if temp ==  . &   strpos( Area , "Services") & Coding== "Services - dr" 	



replace   provision_value = "3"  	 	if provision_value=="A"        &   strpos( Area , "Services") & Coding== "Services - dr" 	
replace   provision_value = "2"  	 	if provision_value=="B"  	   &   strpos( Area , "Services") & Coding== "Services - dr" 
replace   provision_value = "1"  	 	if provision_value=="C"  	   &   strpos( Area , "Services") & Coding== "Services - dr" 


replace   provision_value = "0" 	if temp == .	& 		provision_value == ""	 &   strpos( Area , "Services") & Coding== "Services - dr" 

********************************************************************************
********************************************************************************
* Coding: Services - dr_sinwin_nat

/*
Subsection	Provision
Domestic Regulation (DR)	Please indicate the nature of the discipline above: 
A. General obligation and mandatory nature
B. Obligation subject to limitations or reservations
C. General obligation, but best endeavour nature
D. Voluntary obligation


*/

tab prov      if temp ==  . &   strpos( Area , "Services") & strpos(Coding, "dr_sinwin_nat")


replace   provision_value = "1"  	 	if provision_value=="A"       &   strpos( Area , "Services") & strpos(Coding, "dr_sinwin_nat")
replace   provision_value = "2"  	 	if provision_value=="B"  	  &   strpos( Area , "Services") & strpos(Coding, "dr_sinwin_nat")
replace   provision_value = "3"  	 	if provision_value=="C"  	  &   strpos( Area , "Services") & strpos(Coding, "dr_sinwin_nat")
replace   provision_value = "4"  	 	if provision_value=="D"  	  &   strpos( Area , "Services") & strpos(Coding, "dr_sinwin_nat") 


replace   provision_value = "0" 	if temp == .	& 		provision_value == ""	&   strpos( Area , "Services") & strpos(Coding, "dr_sinwin_nat")


********************************************************************************
********************************************************************************
* Coding: Services - trans_app_nat

/*


Subsection	Provision
Transparency	Please indicate the nature of the discipline above: 
A. General obligation and mandatory nature
B. Obligation subject to limitations or reservations
C. General obligation, but best endeavour nature
D. Voluntary obligation

*/

tab prov      if temp ==  . &   strpos( Area , "Services") & strpos(Coding, "trans_app_nat")


replace   provision_value = "1"  	 	if provision_value=="A"        &   strpos( Area , "Services") & strpos(Coding, "trans_app_nat")
replace   provision_value = "2"  	 	if provision_value=="B"  	   &   strpos( Area , "Services") & strpos(Coding, "trans_app_nat")
replace   provision_value = "3"  	 	if provision_value=="C"  	   &   strpos( Area , "Services") & strpos(Coding, "trans_app_nat")
replace   provision_value = "4"  	 	if provision_value=="D"  	   &   strpos( Area , "Services") & strpos(Coding, "trans_app_nat")


replace   provision_value = "0" 	if temp == .	& 		provision_value == ""	 &   strpos( Area , "Services") & strpos(Coding, "trans_app_nat")

********************************************************************************
********************************************************************************
* Coding: Services - Services - exc

tab prov      if temp ==  . &   strpos( Area , "Services") & strpos(Coding, "Services - exc")


/*
Does the agreement include general exceptions? (GATS Article XIV list) If yes please list the general exceptions which go beyond the GATS  Article XIV list


*/

replace   provision_value = "1"  	if 					    provision_value =="A"    &   strpos( Area , "Services") & strpos(Coding, "Services - exc")
replace   provision_value = "0" 	if temp == .	& 		provision_value == ""	 &   strpos( Area , "Services") & strpos(Coding, "Services - exc")


********************************************************************************
********************************************************************************
* State Owned Enterprises


tab provision if strpos( Area , "State Owned Enterprises")

* All 0/1


********************************************************************************
********************************************************************************
* Subsidies
tab provision if strpos( Area , "Subsidies")

* All 0/1   ; there is 1 "9" what does it mean? this is Agreement 175 (ASEAN - Japan)

replace   provision_value = "1"  	 	if provision_value=="9"        &   strpos( Area , "Subsidies") & strpos(Coding, "prov_23")


********************************************************************************
********************************************************************************
* Technical Barriers to Trade
tab provision if strpos( Area , "Technical Barriers to Trade")

* All 0/1; there is one missing what does it mean? this is Agreement 30 (EU - Türkiye)

replace   provision_value = "0"  	 	if provision_value=="."        &    strpos( Area , "Technical Barriers to Trade") & strpos(Coding, "prov_33")

********************************************************************************
********************************************************************************
* Trade Facilitation and Customs
tab provision if strpos( Area , "Trade Facilitation and Customs")

* All 0/1 
 
********************************************************************************
********************************************************************************
* Trade Facilitation and Customs

tab provision if strpos( Area , "Visa and Asylum")

* All 0/1 
 
cap drop temp 
 
********************************************************************************
********************************************************************************
* Final check 
 
tab provision_value

replace   provision_value = subinstr(provision_value, " ", "", . )   // eliminate blanks
replace   provision_value = "0"     if provision_value == "" | provision_value == " "

 
********************************************************************************
********************************************************************************
* save dataset 

cap drop id_provision
egen id_provision = group(Area   Coding)

preserve
bys id_provision: keep if _n == 1
keep Area   Coding   Provision id_provision
save "$DATA\provision_list", replace
restore

cap drop  Provision
  

destring id_agree, replace
destring provision_value, replace

rename provision_value rta_deep

order  Area id_provision id_agree rta_deep

save "$DATA\rta_data_for_cluster", replace
********************************************************************************
********************************************************************************
