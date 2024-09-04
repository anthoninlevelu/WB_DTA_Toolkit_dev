********************************************************************************
********************************************************************************
********************************************************************************


cap 	log close
capture log using "$PROG/log_files/read_data_provisions", text replace

******************************************************************************** 
*here we select the list of agreements: based on WTO excel file  (which version?? Ask Alvaro)


********************************************************************************
********************************************************************************
/*
same perimeter but need to keep them in  the sample for clusters
North American Free Trade Agreement (NAFTA)	               id_agree:  27	   	Inactive	1994 - 2020 (2019)
United States-Mexico-Canada Agreement (USMCA/CUSMA/T-MEC)  id_agree: 291	 	In Force	2020 - 2999 

 
A S E A N Free Trade Area (AFTA) - 1992	id_agree:   25	 Inactive	1993 - 2010 (2009)
ASEAN Free Trade Area (AFTA)	        id_agree:  295	 In Force	2010 - 2999
*/
********************************************************************************
********************************************************************************
* we fix here RTA Status: if Active goes into cluster if Inactive goes into "opted_out" (Early & PSA  are dropped they goes into RTA = 0 )
cd "$DATA/DTA"
import excel "$dataset", sheet("Agreements") firstrow allstring clear // Bilateral information is created using the 0_Agreements_Information_Dec_2023 dofile



********************************************************************************
* select RTA into the Toolkit

replace Status                 = "Active"   			                             if  WBID   == "25"   | WBID   == "27"
// 25: Asean 1992  ; 27 NAFTA 1994. We set both as active they will just change profile when the update versions will entry into force 
replace Status                 = "Empty_provisions"                                  if  WBID   == "329"         
// 329 Pacific Agreement on Closer Economic Relations Plus (PACER Plus): all provisions are empty not sure how to treat this
replace Status                 = "Empty_provisions"                                  if  WBID   == "328"
// 328	Morocco - United Arab Emirates : all provisions are empty not sure how to treat this

// Entry/Exit to be amended:
replace SpecificEntryExitdates =  "Tuvalu(03-Apr-2022 - ); Vanuatu(10-Oct-2022 - ); " 						+ SpecificEntryExitdates   if  WBID   == "329" 
 // 329	2020	Pacific Agreement on Closer Economic Relations Plus (PACER Plus) :  
 
replace SpecificEntryExitdates = "Sudan(01-Apr-2016 - ); Democratic Republic of the Congo(01-Jul-2022 - );" + SpecificEntryExitdates   if  WBID   == "54" 
 // 54	2000 East African Community (EAC)	
 
 replace SpecificEntryExitdates = "Angola( - 31-Dec-1997);" 												+ SpecificEntryExitdates   if  WBID   == "29" 
//	29	1994 Common Market for Eastern and Southern Africa (COMESA)

 replace SpecificEntryExitdates = "Angola(01-Apr-2003 - ); Madagascar(01-Apr-2014 - ); " 					+ SpecificEntryExitdates   if  WBID   == "95" 
// 	95 Southern African Development Community (SADC)

 replace SpecificEntryExitdates = "Afghanistan(01-Jan-1992 - ); Tajikistan(01-Jan-1992 - ) " 			    + SpecificEntryExitdates   if  WBID   == "24" 
// 	24 Economic Cooperation Organization (ECO)

 replace SpecificEntryExitdates = "Panama(01-Jan-2012 - ); " 			    								+ SpecificEntryExitdates   if  WBID   == "15" 
// 	15 Latin American Integration Association (LAIA)

 replace SpecificEntryExitdates = "Palestine(01-Jan-2016 - ); " 			    						 	+ SpecificEntryExitdates   if  WBID   == "118" 
// 	118 Pan-Arab Free Trade Area (PAFTA)

 replace SpecificEntryExitdates = "Guinea-Bissau(01-May-1997 - ); " 		    						 	+ SpecificEntryExitdates   if  WBID   == "50" 
// 	50 West African Economic and Monetary Union (WAEMU)

 replace SpecificEntryExitdates = subinstr(SpecificEntryExitdates, "United Kingdom( - 31-Dec-2020)", "United Kingdom( - 31-Dec-2019);", .)
// 235 EU (28) Enlargement	(in WTO website UK left 31 January 2020 not 31 December as in the excell file. We set 31 dec 2019 otherwise will be in 2020 trade data): 53 agreement in total need to be adjusted 
 
 replace SpecificEntryExitdates = "United Kingdom( - 31-Dec-2019); " 		    						 	+ SpecificEntryExitdates   if  WBID   == "230" 
// 230 EU - Central America

 replace SpecificEntryExitdates = "United Kingdom(01-Jan-1973 - 31-Dec-2019)" 		    					                           if  WBID   == "4" 
// 	4 EU – Overseas Countries and Territories (OCT) (for consistency)

 
					drop 					if  Status == "Early Announcement"  // only EU-MERCOSUR: no record in the WTO database so ok to drop
*					drop 					if  Type   =="PSA"                  // 28 agreement to be discussed

replace Accession               = "Yes"     if  WBID   == "331" |  WBID   == "177" | WBID   == "323" | WBID   == "333"   


/*
Southern Common Market (MERCOSUR) - Egypt	331
Southern Common Market (MERCOSUR) - India	177
Southern Common Market (MERCOSUR) - Israel	323
Southern Common Market (MERCOSUR) - Southern African Customs Union (SACU)	333
*******************************************************************************/
* Basic data preparation (once for all)
 
destring WBID, replace
drop if WBID == .

rename DateofEntryintoForceG   entry_force 
rename InactiveDate            opted_out
rename WBID 			       id_agree
rename RTAComposition          composition
rename Accession        	   accession
rename Agreement               agreement

replace entry_force 		   = substr(entry_force          , -4, . )
replace entry_force 		   = substr(DateofEntryintoForceS, -4, . )    		if entry_force == ""
replace opted_out 		   	   = substr(opted_out            , -4, . )


destring entry_force 		   , replace
destring opted_out 			   , replace



save  "$TEMP/rta_data_raw.dta", replace

* 399 RTAs here (only dropped EU-MERCOSUR)
********************************************************************************
********************************************************************************
********************************************************************************

use  "$TEMP/rta_data_raw.dta", replace

keep if  Status !="Inactive"


keep id_agree entry_force composition accession agreement Currentsignatories Originalsignatories SpecificEntryExitdates   



replace SpecificEntryExitdates = subinstr(SpecificEntryExitdates, " - )", "/Entry", .)
replace SpecificEntryExitdates = subinstr(SpecificEntryExitdates, "( - ", "(Exit/", .)
replace SpecificEntryExitdates = subinstr(SpecificEntryExitdates, "("   , "/"     , .)
replace SpecificEntryExitdates = subinstr(SpecificEntryExitdates, ")"   , ""      , .)


split Originalsignatories      , parse(;) gen(original)
split Currentsignatories       , parse(;) gen(current)
split SpecificEntryExitdates   , parse(;) gen(change)


reshape long original  current change, i(agreement id_agree entry_force accession composition) j(id_members)

drop 	if original =="" & current =="" & change ==""


split 	change		, parse(/) gen(change_time)

gen     entry_time  = change_time2 					if change_time3 =="Entry"
replace entry_time  = substr(change_time2, 1, 12)    if change_time2 !=""  & change_time3 == ""

gen     exit_time   = change_time3 if change_time2 =="Exit"
replace exit_time   = substr(change_time2, -12, .)   if change_time2 !=""  & change_time3 == ""

replace entry_time  = subinstr(entry_time, " ", "", .)
replace exit_time   = subinstr(exit_time, " ", "", .)

rename change_time1   change_cty  

cap drop change 
cap drop change_time2
cap drop change_time3

cap drop Originalsignatories
cap drop Currentsignatories
cap drop SpecificEntryExitdates


replace  entry_time = substr(entry_time, -4, .)
destring entry_time	, replace


replace  exit_time 	= substr(exit_time, -4, .)
destring exit_time	, replace


replace current     = trim(current)
replace original    = trim(original)
replace change_cty  = trim(change_cty)
 

 
******************************************************************************** 
* NAFTA in
replace entry_time  =  1994 		    if id_agree == 27 
replace exit_time   =  2019 		    if id_agree == 27  
replace current     = original          if id_agree == 27 
replace change_cty  = original          if id_agree == 27 


* ASEAN in  
replace entry_time  =  1993 			if id_agree == 25 
replace exit_time   =  2009 			if id_agree == 25  
replace current     = original      	if id_agree == 25
replace change_cty  = original          if id_agree == 25 
replace agreement   = "A S E A N 1992"  if id_agree == 25  // need to change name to avoid confusion with the following ASEAN (perimeters are the same)

  
********************************************************************************  

rename   exit_time 	  change_exit_time
rename   entry_time   change_entry_time 
  
preserve
keep id_agree agreement entry_force accession composition
duplicates drop
save "$TEMP/id_agree_perimeter", replace
restore


preserve
keep id_agree current 
drop if current ==""
duplicates drop id_agree current, force  

save "$TEMP/perimeter", replace
restore
 

preserve
keep   id_agree change_cty change_entry_time change_exit_time
gen     current = change_cty
drop if current ==""
duplicates drop id_agree current, force  
 
merge 1:m id_agree current using "$TEMP/perimeter"
drop _m 

 
save "$TEMP/perimeter", replace
restore



preserve
keep   id_agree   original
gen  current = original
drop if current ==""
duplicates drop id_agree current, force  

merge 1:1 id_agree current using "$TEMP/perimeter"
drop _m 
  
save "$TEMP/perimeter", replace
restore

********************************************************************************
********************************************************************************
********************************************************************************

use "$TEMP/perimeter", clear

duplicates drop id_agree current, force  

merge m:1 id_agree   using "$TEMP/id_agree_perimeter"
drop _m 
save "$TEMP/perimeter", replace   // 385 id_agree (15 inactive dropped)

unique id_agree

use "$TEMP/perimeter", clear

order id_agree agreement entry_force accession composition original current change_cty change_entry_time change_exit_time


        gen EU_is_member =(current =="European Union")
bys id_agree: egen temp  = max(EU_is_member)
	replace EU_is_member = temp
	cap    drop temp


********************************************************************************
********************************************************************************
* drop few coountries for which we have not entry/exit dates (does not mean we drop agreements still 384)

drop if     current != original & (change_entry_time == . & change_exit_time == .)  /*
*/                              & EU_is_member ==  0                                /*
*/                              & agreement != "AfCFTA (African Continental Free Trade) Agreement"


cap drop EU_is_member

********************************************************************************
/*******************************************************************************
ed if strpos(agreement, "East African Community (EAC)")
ed if strpos(agreement, "Eurasian Economic Union (EAEU)")
ed if strpos(agreement, "Southern African Development Community (SADC)")
ed if strpos(agreement, "South Asian Free Trade Agreement (SAFTA)")
ed if strpos(agreement, "Common Market for Eastern and Southern Africa (COMESA)")
ed if strpos(agreement, "EFTA")
ed if strpos(agreement, "Central American Common Market (CACM)")
ed if strpos(agreement, "EU - Colombia, Ecuador and Peru")
*******************************************************************************/
********************************************************************************
*  Notice there are some double counting (accession and original): fix by hand

drop if change_cty =="Armenia" 		   & id_agree == 255 & accession =="No"
drop if change_cty =="Kyrgyz Republic" & id_agree == 255 & accession =="No"


drop if change_cty =="Seychelles" 	   & id_agree == 95  & accession =="No"
drop if change_cty =="Afghanistan" 	   & id_agree == 136 & accession =="No"


drop if change_cty =="Egypt" 	   	   & id_agree == 29  & accession =="No"
drop if change_cty =="Seychelles" 	   & id_agree == 29  & accession =="No"
drop if current    =="Seychelles" 	   & id_agree == 313  //  This is Egypt's accession to COMESA, which does not govern relations with Seychelles (see above)


drop if change_cty =="Iceland" 	   	   & id_agree == 2   & accession =="No"
drop if change_cty =="Panama" 	   	   & id_agree == 3   & accession =="No"


drop if change_cty =="Ecuador" 	   	   & id_agree == 229 & accession =="No"



********************************************************************************
********************************************************************************
* fix enlargement by hand this is much easier 

drop                                    if original   ==""   & id_agree == 1    // EU treaty only 6 country 

replace change_exit_time  =  1972       if  agreement=="EU Treaty"
replace change_exit_time  =  1980       if  agreement=="EC (9) Enlargement"
replace change_exit_time  =  1985       if  agreement=="EC (10) Enlargement"
replace change_exit_time  =  1994       if  agreement=="EC (12) Enlargement"
replace change_exit_time  =  2003       if  agreement=="EC (15) Enlargement"
replace change_exit_time  =  2006       if  agreement=="EC (25) Enlargement"
replace change_exit_time  =  2012       if  agreement=="EC (27) Enlargement"
replace change_exit_time  =  2999       if  agreement=="EU (28) Enlargement"


replace change_exit_time  =  2999 	    if change_exit_time == .
replace change_entry_time = entry_force if change_entry_time == .


 cap drop change_cty
 
rename change_entry_time cty_entry_time
rename change_exit_time  cty_exit_time


cap drop if current =="Falkland Islands (Islas Malvinas)"   // otherwise will mess up the reclink as it matches with Faroe Islands

// now we have a file with agreements list and members: problem sometimes memebers are agreements itself
save "$TEMP/perimeter", replace

********************************************************************************
/********************************************************************************
Now we need to attache iso3 code to country names
*******************************************************************************/
********************************************************************************

import excel "$dataset", sheet("Bilateral Information") firstrow allstring clear

keep iso1 Economy1
rename iso1     iso_o
gen    iso_d =  iso_o
rename Economy1 current
duplicates drop


replace current = "South Korea"		    					if current =="Korea, Rep." 
replace current = "North Korea"  						    if current =="Korea, Dem. People's Rep."
replace current = "Aruba, the Netherlands with respect to"	if current == "Aruba"	
replace	current = "Bolivia, Plurinational State of"	   		if current == "Bolivia"

 

expand 2   if current =="Congo, Rep."
expand 4   if current =="Congo, Dem. Rep."

bys iso_o: gen obs = _n

replace  current ="Democratic Republic of the Congo" if iso_o =="COD" & obs == 2
replace  current ="Congo" 							 if iso_o =="COD" & obs == 3
replace  current ="Democratic Republic of Congo" 	 if iso_o =="COD" & obs == 4

replace  current ="Republic of Congo"				 if iso_o =="COG" & obs == 2

********************************************************************************

expand 2   if current =="South Korea"		
cap drop obs 
bys iso_o: gen obs = _n
replace current = "Korea, Republic of"  			 if  iso_o =="KOR" & obs == 2	

********************************************************************************

expand 2   if current =="Iran, Islamic Rep."	
cap drop obs 
bys iso_o: gen obs = _n
replace current = "Iran"  			 				 if  iso_o =="IRN" & obs == 2	

********************************************************************************

expand 3   if current =="Lao PDR"
cap drop obs 
bys iso_o: gen obs = _n

replace current = "Lao People's Democratic Republic" if iso_o =="LAO" & obs == 2
replace current = "Laos" 							 if iso_o =="LAO" & obs == 3

********************************************************************************
********************************************************************************

replace current = "Palestine" 					 	 if current =="West Bank and Gaza" 
 
replace current = "Saint Lucia" 					 if current =="St. Lucia" 
replace current = "Chinese Taipei" 					 if current == "Taiwan, China"
 
duplicates drop
gen idu = _n

save "$TEMP/perimeter_cty_code", replace

********************************************************************************
********************************************************************************


use "$TEMP/perimeter", clear

keep id_agree agreement current cty_entry_time cty_exit_time entry_force
duplicates drop
gen idm = _n

reclink2 current using "$TEMP/perimeter_cty_code", gen(score) idm(idm) idu(idu)






********************************************************************************
********************************************************************************
* save members that are actually agreements

gen list_matched    = 1 			if current =="European Free Trade Association (EFTA)"  | /*
*/									   current =="European Union"  						   | /*
*/                                     current =="Southern Common Market (MERCOSUR)"       | /*
*/                                     current =="ASEAN Free Trade Area (AFTA)"   		   | /*
*/                                     current =="Eurasian Economic Union (EAEU)"   	   | /*
*/                                     current =="Southern African Customs Union (SACU)"   | /*
*/                                     current =="Central American Common Market (CACM)"   | /*
*/                                     current =="Gulf Cooperation Council (GCC)"   


********************************************************************************
********************************************************************************
*  save members country match
preserve
keep if _m == 3 | list_matched == 1
keep id_agree agreement current cty_entry_time cty_exit_time entry_force iso_o iso_d
save "$TEMP/rta_cty_code", replace
restore

keep if list_matched == 1
keep current  
rename current agreement_member
duplicates drop
save "$TEMP/rta_agree_code", replace


********************************************************************************
********************************************************************************
* Retrieve the perimeter for members that are agreement 
********************************************************************************
********************************************************************************


use "$TEMP/perimeter", clear
 
cap drop id_accession


********************************************************************************
/*******************************************************************************
GCC, MERCOSUR, SACU, ASEAN no variation in the perimeter but we need them
as they appears as current members in some agreemet and we need to have the list of countries
*******************************************************************************/
********************************************************************************
gen  id_accession= 1     if accession =="Yes" |  strpos(agreement, "GCC") | strpos(agreement, "MERCOSUR") | strpos(agreement, "SACU") | strpos(agreement, "ASEAN") 

gen  agreement_accession    = agreement if id_accession== 1
 
 
 
replace agreement_accession =  "European Union"    if                  agreement=="EU Treaty"           |   agreement=="EC (9) Enlargement"  | /*
*/ 													                   agreement=="EC (10) Enlargement" |   agreement=="EC (12) Enlargement" | /*
*/                                                                     agreement=="EC (15) Enlargement" |   agreement=="EC (25) Enlargement" | /*
*/                                                                     agreement=="EC (27) Enlargement" |   agreement=="EU (28) Enlargement"



replace agreement_accession = "European Free Trade Association (EFTA)" if strpos(agreement, "EFTA")        & id_accession== 1 
replace agreement_accession = "Eurasian Economic Union (EAEU)"         if strpos(agreement, "(EAEU)")  	   & id_accession== 1 
replace agreement_accession = "Central American Common Market (CACM)"  if strpos(agreement, "(CACM)")  	   & id_accession== 1 

replace agreement_accession = "Gulf Cooperation Council (GCC)"         if strpos(agreement, "(GCC)")  	   & id_accession== 1 
replace agreement_accession = "Southern Common Market (MERCOSUR)"      if strpos(agreement, "(MERCOSUR)")  & id_accession== 1 
replace agreement_accession = "Southern African Customs Union (SACU)"  if strpos(agreement, "(SACU)")  	   & id_accession== 1 
replace agreement_accession = "ASEAN Free Trade Area (AFTA)"       	   if strpos(agreement, "ASEAN")  	   & id_accession== 1 

 
replace agreement_accession = subinstr(agreement_accession, "EU - ", "EU--", 1)
replace agreement_accession = subinstr(agreement_accession, "United Kingdom - ", "United Kingdom--", 1)

split agreement_accession if id_accession== 1, parse(" - ") gen(accessed_cty)
replace accessed_cty2       = subinstr(accessed_cty2, "Accession of ", "",  .)

replace agreement_accession = accessed_cty1 if id_accession== 1
replace agreement_accession = agreement     if id_accession== . &  agreement_accession ==""

replace agreement_accession = subinstr(agreement_accession, "EU--", "EU - " , 1)
replace agreement_accession = subinstr(agreement_accession, "United Kingdom--", "United Kingdom - " , 1)


sort  agreement_accession
order id_accession id_agree agreement_accession entry_force
 
replace id_accession        =  0 if id_accession == .
bys agreement_accession: egen temp = max(id_accession)
		replace   id_accession     = temp

keep if 	id_accession    == 1	

********************************************************************************
********************************************************************************
* retain the original version of the agreement as no further accession are recorded 

drop if     strpos(agreement, "GCC")       & id_agree != 282 
drop if     strpos(agreement, "MERCOSUR")  & id_agree != 21 
drop if     strpos(agreement, "SACU")      & id_agree != 126 
drop if     strpos(agreement, "ASEAN")     & id_agree != 295

  

********************************************************************************
/*******************************************************************************

below we identify country codes and perimeters of agreement when registered 
members are agreements

*******************************************************************************/
********************************************************************************

order     cty_entry_time cty_exit_time current  agreement_accession
keep      agreement_accession current cty_entry_time cty_exit_time 

rename agreement_accession agreement_member
merge m:1 agreement_member using "$TEMP/rta_agree_code" 
keep if _m == 3
cap drop _m 
  

rename agreement_member signatory
duplicates drop

bys current signatory: egen min_y = min(cty_entry_time)
bys current signatory: egen max_y = max(cty_exit_time)

		replace cty_exit_time  = max_y
drop if cty_entry_time > min_y

cap drop *_y
cap drop accession
cap drop id_agree



duplicates drop
gen idm = _n

reclink2 current using "$TEMP/perimeter_cty_code", gen(score) idm(idm) idu(idu)


rename current   current_cty
rename signatory current 

rename iso_o     iso_cty_o
rename iso_d     iso_cty_d
duplicates drop

keep current current_cty cty_entry_time cty_exit_time iso_cty_o iso_cty_d
rename cty_entry_time signatory_entry_time
rename cty_exit_time  signatory_exit_time

save "$TEMP/perimeter_multilateral_agreements", replace

********************************************************************************
********************************************************************************

use "$TEMP/perimeter_multilateral_agreements", clear

preserve
keep if current =="European Union"
keep current iso_cty_o signatory_entry_time signatory_exit_time
rename current multilateral
rename iso_cty_o iso_o
gen             iso_d = iso_o
save "$TEMP/perimeter_european_union", replace
restore



preserve
keep if current=="ASEAN Free Trade Area (AFTA)"
keep current iso_cty_o signatory_entry_time signatory_exit_time
rename current multilateral
rename iso_cty_o iso_o
gen             iso_d = iso_o
save "$TEMP/perimeter_asean", replace
restore




preserve
keep if current=="European Free Trade Association (EFTA)"
keep current iso_cty_o signatory_entry_time signatory_exit_time
rename current multilateral
rename iso_cty_o iso_o
gen             iso_d = iso_o
save "$TEMP/perimeter_efta", replace
restore

// What about Angola listed as memer but there is a disclaimer in the WTO website
use "$TEMP/rta_cty_code", clear
keep if  strpos(agreement, "(COMESA)")
bys iso_o: keep if _n == 1
keep iso_o  cty_entry_time cty_exit_time

rename cty_entry_time   signatory_entry_time
rename cty_exit_time    signatory_exit_time

gen  iso_d = iso_o
save "$TEMP/perimeter_comesa", replace



********************************************************************************
/*******************************************************************************
we know have a list of countries by agreement member and time of accession/leave
*******************************************************************************/
********************************************************************************

use "$TEMP/rta_cty_code", clear

joinby current using "$TEMP/perimeter_multilateral_agreements", unmatched(both)


*drop if  iso_cty_o     == "GBR"          & _m == 3 & id_agree == 285 
* id_agree	 285	agreement	 EU - United Kingdom	entry_force 2021


replace          iso_o = iso_cty_o   			if _m == 3
replace          iso_d = iso_cty_d   			if _m == 3

replace cty_entry_time = signatory_entry_time   if _m == 3
replace cty_exit_time  = signatory_exit_time    if _m == 3

replace cty_entry_time = 2008                   if _m == 3 & id_agree == 175 
* id_agree	agreement 175	ASEAN - Japan (this was ratified under the old ASEAN )

replace cty_entry_time = 2005                   if _m == 3 & id_agree == 106
* ASEAN - China	id_agree 106




gen          signatory = current
replace 	  current  = current_cty			if _m == 3


 

cap drop iso_cty_o
cap drop iso_cty_d
cap drop signatory_entry_time
cap drop signatory_exit_time

cap drop current_cty

bys id_agree current: gen obs = _N

********************************************************************************
/*******************************************************************************
 if more than one observation exists retain the observation where country appears as memeber
*******************************************************************************/
********************************************************************************

drop if _m == 3  & obs > 1   // member states that signed in a different period than the overall agreement
drop _m 


drop if cty_exit_time == entry_force 
  
 

cap drop obs
bys id_agree iso_o: gen obs = _N
tab obs

cap drop obs 
duplicates drop

save "$TEMP/perimeter_all_agreements", replace
unique id_agree   // 385

order  id_agree entry_force agreement cty_entry_time cty_exit_time iso_o current signatory
keep   id_agree entry_force agreement cty_entry_time cty_exit_time iso_o current signatory

rename signatory      signatory_o
rename current        cty_o
rename cty_exit_time  cty_exit_time_o
rename cty_entry_time cty_entry_time_o

save "$TEMP/perimeter_all_agreements_o", replace


rename signatory_o      signatory_d
rename iso_o            iso_d
rename cty_o            cty_d
rename cty_exit_time_o  cty_exit_time_d
rename cty_entry_time_o cty_entry_time_d

joinby id_agree entry_force agreement using "$TEMP/perimeter_all_agreements_o"


order  id_agree entry_force agreement iso_o iso_d signatory_o signatory_d cty_o cty_d cty_entry_time_o cty_exit_time_o cty_entry_time_d cty_exit_time_d    

drop if iso_o == iso_d

drop if entry_force > cty_exit_time_o       // This is correct. Drop countries if the RTA is ratified after they leave the agreement
drop if entry_force > cty_exit_time_d

save "$TEMP/perimeter_all_agreements_od", replace

********************************************************************************
/*******************************************************************************
 To avoid repetition, accession does not affect the inter-agreement relations:
 
 do this by hand this is better I think
 
 
*******************************************************************************/
********************************************************************************
use "$TEMP/perimeter_all_agreements_od", clear

gen id_eu = (id_agree == 1 | id_agree == 5 | id_agree == 13  | id_agree ==18  | id_agree == 28  | id_agree == 89  | id_agree == 117  | id_agree == 235 )

gen     bilateral_eu = 0
replace	bilateral_eu = 1    if strpos(agreement, "EU ")  
replace bilateral_eu = 1 	if  (agreement =="European Economic Area (EEA)")
replace bilateral_eu = 0 	if  strpos(agreement, "EAEU") 

replace bilateral_eu = 0 	if         id_eu == 1
replace bilateral_eu = 0 	if  bilateral_eu == .

 

/*******************************************************************************
 signatory_exit_time >  entry_force: let UK out of EU agreements in 2019
 signatory_exit_time >= entry_force: let UK in the EU agreements in 2019
*******************************************************************************/

merge m:1 iso_o using "$TEMP/perimeter_european_union", keepusing(iso_o signatory_*)
*     gen  eu_o  =(_m==3  & signatory_entry_time <= entry_force &  signatory_exit_time >=  entry_force & signatory_entry_time != . & signatory_exit_time != .)  
// this was wrong, no matter when a country join EU bilateral agreement should not affect intra eu relations
      gen     eu_o  =(_m==3)
	  replace eu_o  = 0   if iso_o =="GBR" & entry_force > 2019  // starting from 2020 GBR no longer EU
 
	  drop _m 
cap drop signatory_*

merge m:1 iso_d using "$TEMP/perimeter_european_union", keepusing(iso_d signatory_*)
*     gen  eu_d =(_m==3  & signatory_entry_time <= entry_force &  signatory_exit_time >=  entry_force & signatory_entry_time != . & signatory_exit_time != .)
      gen     eu_d =(_m==3)
	  replace eu_d = 0   if iso_d =="GBR" & entry_force > 2019  // starting from 2020 GBR no longer EU

	  
   drop _m 
   cap drop signatory_*

 
drop if (eu_o ==1 & eu_d ==1 )  &  (bilateral_eu ==  1 )  
drop if (eu_o ==0 & eu_d ==0 )  &  (bilateral_eu ==  1 )  

cap drop eu_o
cap drop eu_d
cap drop id_eu
cap drop bilateral_eu


********************************************************************************
********************************************************************************
gen     id_asean        = (id_agree == 295 )
gen 	bilateral_asean = strpos(agreement, "ASEAN")
replace bilateral_asean = 0 							if         id_asean == 1

merge m:1 iso_o using "$TEMP/perimeter_asean", keepusing(iso_o signatory_*)
*      gen  asean_o =(_m==3  & signatory_entry_time <= entry_force &  signatory_exit_time >= entry_force & signatory_entry_time != . & signatory_exit_time != .)
       gen  asean_o =(_m==3)
drop _m 
cap drop signatory_*


merge m:1 iso_d using "$TEMP/perimeter_asean", keepusing(iso_d signatory_*)
*     gen  asean_d =(_m==3  & signatory_entry_time <= entry_force &  signatory_exit_time >= entry_force & signatory_entry_time != . & signatory_exit_time != .)
      gen  asean_d =(_m==3 )
drop _m 
cap drop signatory_*

 
drop if (asean_o ==1 & asean_d ==1 )  &  (bilateral_asean ==  1   ) 
drop if (asean_o ==0 & asean_d ==0 )  &  (bilateral_asean ==  1   ) 


cap drop asean_o
cap drop asean_d
cap drop id_asean
cap drop bilateral_asean
 

********************************************************************************
********************************************************************************
gen     id_efta        = (id_agree == 2 )
gen 	bilateral_efta = strpos(agreement, "EFTA")
replace bilateral_efta = 0 	       if  strpos(agreement, "CEFTA")  & bilateral_efta == 1

replace bilateral_efta = 0 							if         id_efta == 1

merge m:1 iso_o using "$TEMP/perimeter_efta", keepusing(iso_o signatory_*)
*     gen  efta_o =(_m==3  & signatory_entry_time <= entry_force &  signatory_exit_time >= entry_force & signatory_entry_time != . & signatory_exit_time != .)
      gen  efta_o =(_m==3)
drop _m 
cap drop signatory_*
 

merge m:1 iso_d using "$TEMP/perimeter_efta", keepusing(iso_d signatory_*)
*     gen  efta_d =(_m==3  & signatory_entry_time <= entry_force &  signatory_exit_time >= entry_force & signatory_entry_time != . & signatory_exit_time != .)
      gen  efta_d =(_m==3)
drop _m 
cap drop signatory_*

 
drop if (efta_o ==1 & efta_d ==1 )  &  (bilateral_efta ==  1 ) & id_agree != 318    // id_agree	318	entry_force 1970	EFTA - Accession of Iceland
drop if (efta_o ==0 & efta_d ==0 )  &  (bilateral_efta ==  1 ) & id_agree != 318 
 

cap drop efta_o
cap drop efta_d
cap drop id_efta
cap drop bilateral_efta


********************************************************************************
/*******************************************************************************
fix  accessions:
id_agree	entry_force	agreement

90	2002	Asia Pacific Trade Agreement (APTA) - Accession of China

318	1970	EFTA - Accession of Iceland
348 1999	Latin American Integration Association (LAIA) - Accession of Cuba

257	2015	Eurasian Economic Union (EAEU) - Accession of Armenia
264	2015	Eurasian Economic Union (EAEU) - Accession of the Kyrgyz Republic

267	2015	Southern African Development Community (SADC) - Accession of Seychelles
275	2011	South Asian Free Trade Agreement (SAFTA) - Accession of  Afghanistan
313	1999	Common Market for Eastern and Southern Africa (COMESA) - Accession of Egypt



339	2013	Central American Common Market (CACM) - Accession of Panama
341	2017	EU - Colombia and Peru - Accession of Ecuador
347	2009	Common Market for Eastern and Southern Africa (COMESA) - Accession of Seychelles



352	2018	EU - Pacific States - Accession of Samoa
353	2020	EU - Pacific States - Accession of Solomon Islands

391	2019	EU - Eastern and Southern Africa States - Accession of Comoros

388	2021	United Kingdom - Pacific States - Accession of Samoa
389	2021	United Kingdom - Pacific States - Accession of Solomon Islands

297	2016	Eurasian Economic Union (EAEU) - Viet Nam




368	2021	United Kingdom - Pacific States
388	2021	United Kingdom - Pacific States - Accession of Samoa
389	2021	United Kingdom - Pacific States - Accession of Solomon Islands
392	2021	United Kingdom - Iceland, Liechtenstein and Norway
372	2021	United Kingdom - Switzerland - Liechtenstein
 

216	2007	East African Community (EAC) - Accession of Burundi and Rwanda

Southern Common Market (MERCOSUR) - Egypt	331
Southern Common Market (MERCOSUR) - India	177
Southern Common Market (MERCOSUR) - Israel	323
Southern Common Market (MERCOSUR) - Southern African Customs Union (SACU)	333
Botswana; Lesotho; Namibia; South Africa; Eswatini

*******************************************************************************/
********************************************************************************
********************************************************************************
drop if  iso_o != "EGY" & iso_d !="EGY" & id_agree == 331
drop if  iso_o != "IND" & iso_d !="IND" & id_agree == 177
drop if  iso_o != "ISR" & iso_d !="ISR" & id_agree == 323

 
gen      MERCOSUR_o = 0
gen      MERCOSUR_d = 0

replace  MERCOSUR_o        = 1   if ((iso_o == "ARG") | (iso_o == "BRA")  | (iso_o == "PRY")  | (iso_o == "URY")   )  & ( id_agree == 333 )
replace  MERCOSUR_d        = 1   if ((iso_d == "ARG") | (iso_d == "BRA")  | (iso_d == "PRY")  | (iso_d == "URY")   )  & ( id_agree == 333 )


gen      SACU_o = 0 
gen      SACU_d = 0 

replace  SACU_o        = 1   if ((iso_o == "LSO") | (iso_o == "NAM")  | (iso_o == "SWZ")  | (iso_o == "BWA")  | (iso_o == "ZAF")  )  & ( id_agree == 333 )
replace  SACU_d        = 1   if ((iso_d == "LSO") | (iso_d == "NAM")  | (iso_d == "SWZ")  | (iso_d == "BWA")  | (iso_d == "ZAF")  )  & ( id_agree == 333 )


drop if  SACU_o     == 1  & SACU_o	   == 1    							   & ( id_agree == 333  )
drop if  MERCOSUR_o == 1  & MERCOSUR_d == 1    							   & ( id_agree == 333  )

cap drop SACU_o
cap drop SACU_o

cap drop MERCOSUR_o
cap drop MERCOSUR_d


********************************************************************************

drop if  iso_o != "CHN" & iso_d !="CHN" & id_agree == 90

drop if  iso_o != "ISL" & iso_d !="ISL" & id_agree == 318
drop if  iso_o != "CUB" & iso_d !="CUB" & id_agree == 348


drop if  iso_o != "ARM" & iso_d !="ARM" & id_agree == 257
drop if  iso_o != "KGZ" & iso_d !="KGZ" & id_agree == 264

drop if  iso_o != "SYC" & iso_d !="SYC" & id_agree == 267
drop if  iso_o != "AFG" & iso_d !="AFG" & id_agree == 275
drop if  iso_o != "EGY" & iso_d !="EGY" & id_agree == 313

drop if  iso_o != "PAN" & iso_d !="PAN" & id_agree == 339
drop if  iso_o != "ECU" & iso_d !="ECU" & id_agree == 341
drop if  iso_o != "SYC" & iso_d !="SYC" & id_agree == 347

drop if  iso_o != "WSM" & iso_d !="WSM" & id_agree == 352
drop if  iso_o != "SLB" & iso_d !="SLB" & id_agree == 353

drop if  iso_o != "COM" & iso_d !="COM" & id_agree == 391

drop if  iso_o != "WSM" & iso_d !="WSM" & id_agree == 388
drop if  iso_o != "SLB" & iso_d !="SLB" & id_agree == 389

* EAEU-Viet Nam
drop if  iso_o != "VNM" & iso_d !="VNM" & id_agree == 297


*UK
drop if  iso_o != "GBR" & iso_d !="GBR" & id_agree == 389
drop if  iso_o != "GBR" & iso_d !="GBR" & id_agree == 368
drop if  iso_o != "GBR" & iso_d !="GBR" & id_agree == 388
drop if  iso_o != "GBR" & iso_d !="GBR" & id_agree == 392
drop if  iso_o != "GBR" & iso_d !="GBR" & id_agree == 372
 

gen      access_temp_o = 0 
gen      access_temp_d = 0 
replace  access_temp_o = 1  if ((iso_o == "BDI") | (iso_o == "RWA"))  & id_agree == 216
replace  access_temp_d = 1  if ((iso_d == "BDI") | (iso_d == "RWA"))  & id_agree == 216
drop if access_temp_o == 0 & access_temp_d == 0    & id_agree == 216

cap drop access_temp_o
cap drop access_temp_d
 
********************************************************************************
* 246	2013	Mexico - Central America
drop if  iso_o != "MEX" & iso_d !="MEX" & id_agree == 246

********************************************************************************
* Central American Common Market (CACM): iso_o CRI SLV GTM HND NIC PAN (2013) 
* 339	2013	Central American Common Market (CACM) - Accession of Panama
* 230	2013	EU - Central America


gen      CACM_o = 0 
gen      CACM_d = 0 

replace  CACM_o        = 1   if ((iso_o == "GTM") | (iso_o == "NIC")  | (iso_o == "SLV")  | (iso_o == "CRI")  | (iso_o == "HND")  )  & ( id_agree == 339 )
replace  CACM_d        = 1   if ((iso_d == "GTM") | (iso_d == "NIC")  | (iso_d == "SLV")  | (iso_d == "CRI")  | (iso_d == "HND")  )  & ( id_agree == 339 )


drop if  CACM_o == 1  & CACM_d == 1    								   & ( id_agree == 339  )

replace  CACM_o        = 1   if ((iso_o == "GTM") | (iso_o == "NIC")  | (iso_o == "SLV")  | (iso_o == "CRI")  | (iso_o == "HND")   | (iso_o == "PAN") )  & ( id_agree == 230 )
replace  CACM_d        = 1   if ((iso_d == "GTM") | (iso_d == "NIC")  | (iso_d == "SLV")  | (iso_d == "CRI")  | (iso_d == "HND")   | (iso_d == "PAN") )  & ( id_agree == 230 )

 drop if  CACM_o == 1  & CACM_d == 1    						       & ( id_agree == 230 )

cap drop CACM_o
cap drop CACM_d


********************************************************************************
* Fiji  Papua New Guinea 
* 368	2021	United Kingdom - Pacific States
* 389	2021	United Kingdom - Pacific States - Accession of Solomon Islands
* 388	2021	United Kingdom - Pacific States - Accession of Samoa



gen      PACIFIC_o = 0 
gen      PACIFIC_d = 0 

replace  PACIFIC_o = 1   if ((iso_o == "FJI") | (iso_o == "PNG"))  
replace  PACIFIC_d = 1   if ((iso_d == "FJI") | (iso_d == "PNG"))  


drop if  PACIFIC_o == 1  & PACIFIC_d == 1    								   & ( id_agree == 368 ) 
drop if  PACIFIC_o == 1  & PACIFIC_d == 1    								   & ( id_agree == 389 ) 
drop if  PACIFIC_o == 1  & PACIFIC_d == 1    								   & ( id_agree == 388 ) 

cap drop PACIFIC_o
cap drop PACIFIC_d



********************************************************************************
* 391	2019	EU - Eastern and Southern Africa States - Accession of Comoros	COM	ZWE

merge m:1 iso_o using "$TEMP/perimeter_european_union", keepusing(iso_o signatory_*)
      *gen  eu_o  =(_m==3  & signatory_entry_time <= entry_force &  signatory_exit_time >=  entry_force & signatory_entry_time != . & signatory_exit_time != .)
	  gen     eu_o  =(_m==3)
	  replace eu_o  = 0   if iso_o =="GBR" & entry_force > 2019  // starting from 2020 GBR no longer EU
	  
	  drop _m 
cap drop signatory_*

merge m:1 iso_d using "$TEMP/perimeter_european_union", keepusing(iso_d signatory_*)
  *  gen  eu_d =(_m==3  & signatory_entry_time <= entry_force &  signatory_exit_time >=  entry_force & signatory_entry_time != . & signatory_exit_time != .)
     gen     eu_d  =(_m==3)
	 replace eu_d  = 0   if iso_d =="GBR" & entry_force > 2019  // starting from 2020 GBR no longer EU
   drop _m 
cap drop signatory_*

 

drop if ( eu_o     != 1 & iso_d =="COM"  & id_agree == 391)
drop if ( eu_d     != 1 & iso_o =="COM"  & id_agree == 391)

cap drop eu_o
cap drop eu_d

save "$TEMP/perimeter_od", replace

use "$TEMP/perimeter", clear
keep id_agree composition
duplicates drop
save "$TEMP/composition_agree", replace

********************************************************************************
********************************************************************************

use "$TEMP/perimeter_od", clear

bys iso_o iso_d entry_force: gen obs = _N
tab obs

merge m:1 id_agree using "$TEMP/composition_agree", keepusing(composition)
drop if _m ==2
drop _m

gen bilateral =(strpos(composition, "Bilat"))
bys iso_o iso_d entry_force: egen max = max(bilateral)

drop if bilateral == 0 & max == 1 & obs > 1

cap drop bilateral
cap drop max
cap drop obs
bys iso_o iso_d entry_force: gen obs = _N
tab obs

********************************************************************************
* 368	2021	United Kingdom - Pacific States	 
* 388	2021	United Kingdom - Pacific States - Accession of Samoa	 
* 389	2021	United Kingdom - Pacific States - Accession of Solomon Islands	 

cap drop if iso_o =="WSM" & iso_d=="GBR" & id_agree == 368 & obs == 2
cap drop if iso_d =="WSM" & iso_o=="GBR" & id_agree == 368 & obs == 2

cap drop if iso_o =="SLB" & iso_d=="GBR" & id_agree == 368 & obs == 2
cap drop if iso_d =="SLB" & iso_o=="GBR" & id_agree == 368 & obs == 2

********************************************************************************
* 372	2021	United Kingdom - Switzerland - Liechtenstein
* 392	2021	United Kingdom - Iceland, Liechtenstein and Norway

cap drop if iso_o =="LIE" & iso_d=="GBR" & id_agree == 392 & obs == 2
cap drop if iso_d =="LIE" & iso_o=="GBR" & id_agree == 392 & obs == 2


cap drop obs
bys iso_o iso_d entry_force: gen obs = _N
tab obs
cap drop obs




save "$TEMP/perimeter_od", replace
 

********************************************************************************
/*******************************************************************************
* Now cross with years
*******************************************************************************/



********************************************************************************
use "$TEMP/perimeter_od", clear

cross using "$DATA/DTA/year_series.dta"


drop if year < entry_force       // drop years before the agreement entry into force

drop if year < cty_entry_time_o  // drop years before the individual member enters the agreement
drop if year < cty_entry_time_d

drop if year > cty_exit_time_o   // drop years after the individual member leaves the agreement
drop if year > cty_exit_time_d

unique id_agree 
* 385 id_agree
*******************************************************************************
********************************************************************************
* Discard PSA when another agreement is available

merge m:1 id_agree using "$TEMP/rta_data_raw.dta", keepusing(Type)
drop if _m == 2
drop _m

tab Type

cap drop obs
bys iso_o iso_d year: gen obs = _N
tab obs

replace Type = trim(Type)


gen       psa =(strpos(Type, "PSA"))   //  PSA
replace   psa = 0     if (strpos(Type, "PSA & EIA") & psa == 1)
replace   psa = 1 - psa                // select non PSA (if a non PSA exists use that one )

bys iso_o iso_d year: egen max = max(psa)
drop if psa == 0 & max == 1 & obs > 1

cap drop psa
cap drop max

unique id_agree 

* 383 id_agree
*******************************************************************************
********************************************************************************
* Priviledge Bilateral agreements 

cap drop obs
bys iso_o iso_d year: gen obs = _N
tab obs

replace composition = trim(composition)


gen bilateral =(strpos(composition, "Bilat"))   // either bilateral or Bilateral; One Party is an RTA
bys iso_o iso_d year: egen max = max(bilateral)
drop if bilateral == 0 & max == 1 & obs > 1

cap drop bilateral
cap drop max


cap drop obs
bys iso_o iso_d year: gen obs = _N
tab obs

gen bilateral =((composition == "Bilateral"))   // now only bilateral
bys iso_o iso_d year: egen max = max(bilateral)
drop if bilateral == 0 & max == 1 & obs > 1

cap drop bilateral
cap drop max

unique id_agree 

* 382 id_agree
********************************************************************************
********************************************************************************
* AfCFTA only binding for non-previously associated Ctys

cap drop obs
bys iso_o iso_d year: gen obs = _N
tab obs

drop if agreement=="AfCFTA (African Continental Free Trade) Agreement" & obs > 1

********************************************************************************
********************************************************************************
* 308	2019	Eurasian Economic Union (EAEU) - Iran
* 311	2021	Eurasian Economic Union (EAEU) - Serbia
* 297	2016	Eurasian Economic Union (EAEU) - Viet Nam

cap drop obs
bys iso_o iso_d year: gen obs = _N
tab obs

drop if iso_o !="IRN" & iso_d!="IRN" & id_agree == 308  & obs > 1
drop if iso_d !="SRB" & iso_o!="SRB" & id_agree == 311  & obs > 1
drop if iso_d !="VNM" & iso_o!="VNM" & id_agree == 297  & obs > 1

********************************************************************************
********************************************************************************
* 356	2021	United Kingdom - Central America
* 205	2001	Dominican Republic - Central America
* 371	2021	United Kingdom - SACU and Mozambique
* 355	2021	United Kingdom - CARIFORUM States
* 354	2021	United Kingdom - Colombia, Ecuador and Peru
* 359	2021	United Kingdom - Eastern and Southern Africa States


cap drop obs
bys iso_o iso_d year: gen obs = _N
tab obs
drop if iso_o !="GBR" & iso_d!="GBR" & id_agree == 356  & obs > 1
drop if iso_o !="DOM" & iso_d!="DOM" & id_agree == 205  & obs > 1
drop if iso_o !="GBR" & iso_d!="GBR" & id_agree == 371  & obs > 1
drop if iso_o !="GBR" & iso_d!="GBR" & id_agree == 355  & obs > 1
drop if iso_o !="GBR" & iso_d!="GBR" & id_agree == 354  & obs > 1
drop if iso_o !="GBR" & iso_d!="GBR" & id_agree == 359  & obs > 1


********************************************************************************
********************************************************************************
* 111	2006	Dominican Republic - Central America - United States Free Trade Agreement (CAFTA-DR)
* 323	2010	Southern Common Market (MERCOSUR) - Israel
* 331	2017	Southern Common Market (MERCOSUR) - Egypt

drop if iso_o !="USA" & iso_d!="USA" & id_agree == 111  & obs > 1
drop if iso_o !="ISR" & iso_d!="ISR" & id_agree == 323  & obs > 1
drop if iso_o !="EGY" & iso_d!="EGY" & id_agree == 331  & obs > 1

********************************************************************************
* 217	2009	Colombia - Northern Triangle (El Salvador, Guatemala, Honduras)
* 300	2019	Korea, Republic of - Central America

drop if iso_o !="COL" & iso_d !="COL" & id_agree == 217
drop if iso_o !="KOR" & iso_d !="KOR" & id_agree == 300

cap drop obs
bys iso_o iso_d year: gen obs = _N
tab obs

unique id_agree 

// 381

save "$DATA/rta_year_od", replace
 

********************************************************************************
********************************************************************************
* The list of Agreements to be used in the cluster analysis
********************************************************************************
********************************************************************************

use "$DATA/rta_year_od", replace

bys id_agree : keep if _n == 1
keep id_agree entry_force agreement

save "$DATA/rta_list", replace  
unique id_agree
// 381 final agreements to be feeded into the Cluster machine
********************************************************************************
********************************************************************************
********************************************************************************
* Opted out agreements: Inactive RTAs according to the WTO
********************************************************************************
********************************************************************************

use  "$TEMP/rta_data_raw.dta", replace


keep if  Status =="Inactive"    // 15 agreements
 


keep id_agree entry_force  opted_out   agreement Currentsignatories Originalsignatories    


 

split Originalsignatories      , parse(;) gen(original)
split Currentsignatories       , parse(;) gen(current)
 

reshape long original  current  , i(agreement id_agree entry_force opted_out  ) j(id_members)

drop 	if original =="" & current ==""  

cap drop Originalsignatories
cap drop Currentsignatories
cap drop SpecificEntryExitdates
 
 
 
  
preserve
keep id_agree agreement entry_force    opted_out
duplicates drop
save "$TEMP/id_agree_perimeter", replace
restore


preserve
keep id_agree current 
drop if current ==""
duplicates drop id_agree current, force  

save "$TEMP/perimeter", replace
restore
 

 
keep   id_agree   original
gen  current = original
drop if current ==""
duplicates drop id_agree current, force  

merge 1:1 id_agree current using "$TEMP/perimeter"
drop _m 
  
save "$TEMP/perimeter", replace
 

duplicates drop id_agree current, force  

merge m:1 id_agree   using "$TEMP/id_agree_perimeter"
drop _m 
save "$TEMP/opted_out_agreements", replace

********************************************************************************
********************************************************************************

use "$TEMP/opted_out_agreements", clear
replace current = trim(current)

replace current = "European Union"    if agreement =="EU - Croatia" & current != "Croatia"

duplicates drop current id_agree agreement, force 

joinby current using "$TEMP/perimeter_multilateral_agreements", unmatched(both)
drop if _m ==2

replace  _m     =   .          if agreement =="EU - Croatia" & current == "Croatia" 
replace current = current_cty if _m ==3


drop if signatory_entry_time > opted_out    & signatory_entry_time != .
drop if signatory_exit_time  < entry_force  & signatory_exit_time  != .

replace entry_force  = signatory_entry_time  if signatory_entry_time > entry_force   & _m == 3

keep id_agree entry_force  opted_out current agreement
gen idm = _n


reclink2 current using "$TEMP/perimeter_cty_code", gen(score) idm(idm) idu(idu)

    
keep if _m == 3 
keep id_agree entry_force opted_out current agreement iso_o 


rename current        cty_o
save "$TEMP/perimeter_opted_out_agreements_o", replace


rename iso_o            iso_d
rename cty_o            cty_d

joinby id_agree entry_force agreement opted_out using "$TEMP/perimeter_opted_out_agreements_o"



order id_agree entry_force agreement opted_out   iso_o iso_d  cty_o cty_d  
drop if iso_o == iso_d


********************************************************************************
* are those really dropped out agreements ?
* 27	North American Free Trade Agreement (NAFTA) 
* 25	ASEAN Free Trade Area (AFTA) - 1992
* 41	Eurasian Economic Community (EAEC)

********************************************************************************
* 23	Austria	EFTA - Türkiye
* 182	El Salvador	El Salvador- Honduras - Chinese Taipei
* 315	EU - Croatia
* 362	Norway	United Kingdom - Norway and Iceland

drop if iso_o !="TUR" & iso_d !="TUR" & id_agree == 23
drop if iso_o !="TWN" & iso_d !="TWN" & id_agree == 182
drop if iso_o !="HRV" & iso_d !="HRV" & id_agree == 315
drop if iso_o !="GBR" & iso_d !="GBR" & id_agree == 362



cross using "$DATA/DTA/year_series.dta"


cap drop obs
bys iso_o iso_d year: gen obs = _N
tab obs
tab agree if obs> 1



********************************************************************************
********************************************************************************
* few overlapping agree: use the oldest link


bys iso_o iso_d year: egen temp_min = min(entry_force)
bys iso_o iso_d year: egen temp_max = max(opted_out)

replace entry_force = temp_min if obs> 1
replace opted_out   = temp_max if obs> 1

cap drop temp

cap drop obs
bys iso_o iso_d year  : gen  obs	   = _N
tab obs


drop if year < entry_force       // drop years before the agreement entry into force
drop if year >  opted_out        // drop years after   the agreement is opted out
gen     rta_out_v1 = 1

keep agreement iso_o iso_d year  rta_out_v1 opted_out  id_agree
rename agreement agreement_opted_out
rename id_agree  id_agree_opted_out

sort iso_o iso_d year agreement_opted_out
bys iso_o iso_d year: gen rank = _n
drop if rank == 2   // this keep s the agreement Eurasian Economic Community (EAEC) as opted_out_agree (and drops the overlapping Russian Federation - Tajikistan/Kyrgyz Republic/Belarus)

cap drop rank

* to be appended to the final dataset
save "$DATA/perimeter_opted_out_agreements_od", replace   

unique id_agree
//  10 agreements are finally listed as opted out (4 where redundant overlaps)
 


********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
