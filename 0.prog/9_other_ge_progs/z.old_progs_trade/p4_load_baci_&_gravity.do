
/******************************************************************************* 
	     Deep Trade Agreements Toolkit: Trade and Welfare Impacts 

			Nadia Rocha, Gianluca Santoni, Giulio Vannelli 

                  	   this version: OCT 2022
				   
website: https://xxxxxxx.org/

when using the tool please cite:  
Fontagné, L., Rocha, N., Ruta, M., Santoni, G. (2022),
 The Economic Impact of Deepening Trade Agreements", CESIfo working paper 9529.  

*******************************************************************************/



 cd "$BACI"

cap 	log close
capture log using "$PROG\00_log_files\p4_load_baci", text replace

********************************************************************************
********************************************************************************
* unzip file 
unzipfile "$baci_version", replace


********************************************************************************
* clean
local files : dir "`c(pwd)'"  files "*code*.csv" 

foreach file in `files' { 
	erase `file'    
} 

********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************


global code_origin "i"
global code_destin "j"


* upload and append 
local s = 1
local files : dir "`c(pwd)'"  files "*.csv" 

foreach file in `files' { 
	
import delimited `file' , encoding(ISO-8859-2)  clear 

destring q , replace force


cap drop ctycode

gen ctycode= $code_origin

merge m:1 ctycode using "codes_iso_cnum.dta", keepusing(iso3digitalpha)
keep if _m==3
drop _m
cap drop ctycode

drop if  iso3digitalpha=="NULL"
rename iso3digitalpha iso_o

replace iso_o="ROM" if iso_o=="ROU"
replace iso_o="PAL" if iso_o=="PSE"
replace iso_o="ZAR" if iso_o=="COD"
replace iso_o="TMP" if iso_o=="TLS"

global crap "SXM SSD BES GUM CUW ATF ASM IOT"
foreach f of global crap {
drop if iso_o=="`f'" 
}
********************************************************************************
cap drop ctycode

gen ctycode= $code_destin

merge m:1 ctycode using "codes_iso_cnum.dta", keepusing(iso3digitalpha)
keep if _m==3
drop _m
cap drop ctycode

drop if  iso3digitalpha=="NULL"
rename iso3digitalpha iso_d

replace iso_d="ROM" if iso_d=="ROU"
replace iso_d="PAL" if iso_d=="PSE"
replace iso_d="ZAR" if iso_d=="COD"
replace iso_d="TMP" if iso_d=="TLS"

global crap "SXM SSD BES GUM CUW ATF ASM IOT"
foreach f of global crap {
drop if iso_d=="`f'" 
}
cap drop if iso_o=="VIR"
cap drop if iso_d=="VIR"


cap drop if iso_o=="UMI"
cap drop if iso_d=="UMI"


********************************************************************************
	
if 	`s'   == 1 {
	
save 	"$BACI\trade_baci", replace
	
}
	 
if 	`s'   > 1 {
	
append  using 	"$BACI\trade_baci"
save 			"$BACI\trade_baci", replace
	
}	

local s = `s'  + 1 
	
} 

********************************************************************************
********************************************************************************

use "$BACI\trade_baci", clear

rename k hs6
drop if hs6 == .
keep iso_o iso_d v t hs6


keep if t >= $fdate_bg
keep if t <= $ldate_bg 


replace iso_o = "PSE" if iso_o =="PAL"
replace iso_d = "PSE" if iso_d =="PAL"

replace iso_o = "ROU" if iso_o =="ROM"
replace iso_d = "ROU" if iso_d =="ROM"


replace iso_o = "COD" if iso_o =="ZAR"
replace iso_d = "COD" if iso_d =="ZAR"


replace iso_o = "TLS" if iso_o =="TMP"
replace iso_d = "TLS" if iso_d =="TMP"



save 			"$BACI\trade_baci", replace

********************************************************************************
********************************************************************************
* clean
local files : dir "`c(pwd)'"  files "*.csv" 

foreach file in `files' { 
	erase `file'    
} 

********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************

cd $GRAVITY 

unzipfile "$grav_version", replace

local files : dir "`c(pwd)'"  files "Gravity*.dta" 


use  `files' , clear



rename year t

********************************************************************************
********************************************************************************
 
replace contig = 1 if iso3_o =="SRB"  & ( iso3_d =="BIH"  |  iso3_d =="BGR"  | iso3_d =="HRV" | iso3_d =="HUN" | iso3_d =="MKD" | iso3_d =="MNE" | iso3_d =="ROU") 
replace contig = 1 if iso3_d =="SRB"  & ( iso3_o =="BIH"  |  iso3_o =="BGR"  | iso3_o =="HRV" | iso3_o =="HUN" | iso3_o =="MKD" | iso3_o =="MNE" | iso3_o =="ROU") 

replace contig = 0 if iso3_o =="SRB"  & contig == .
replace contig = 0 if iso3_d =="SRB"  & contig == .

replace contig = 1 if iso3_o =="MNE"  & ( iso3_d =="HRV"  |  iso3_d =="BIH"  | iso3_d =="SRB" | iso3_d =="ALB" ) 
replace contig = 1 if iso3_d =="MNE"  & ( iso3_o =="HRV"  |  iso3_o =="BIH"  | iso3_o =="SRB" | iso3_o =="ALB" ) 

replace contig = 0 if iso3_o =="MNE"  & contig == .
replace contig = 0 if iso3_d =="MNE"  & contig == .

********************************************************************************
********************************************************************************

replace iso3_o = "DDR" if iso3num_o == 278
replace iso3_d = "DDR" if iso3num_d == 278

replace contig = 1 if iso3_o =="DDR"  & ( iso3_d =="DEU"  |  iso3_d =="POL"  | iso3_d =="CSK"  ) 
replace contig = 1 if iso3_d =="DDR"  & ( iso3_o =="DEU"  |  iso3_o =="POL"  | iso3_o =="CSK"  ) 

replace contig = 0 if iso3_o =="DDR"  & contig == .
replace contig = 0 if iso3_d =="DDR"  & contig == .

********************************************************************************
********************************************************************************

replace iso3_o = "CSK" if iso3num_o == 200
replace iso3_d = "CSK" if iso3num_d == 200

replace contig = 1 if iso3_o =="CSK"  & ( iso3_d =="SUN"  |  iso3_d =="POL"  | iso3_d =="DEU" | iso3_d =="DDR" | iso3_d =="AUT" | iso3_d =="HUN" ) 
replace contig = 1 if iso3_d =="CSK"  & ( iso3_o =="SUN"  |  iso3_o =="POL"  | iso3_o =="DEU" | iso3_o =="DDR" | iso3_o =="AUT" | iso3_o =="HUN" ) 

replace contig = 0 if iso3_o =="CSK"  & contig == .
replace contig = 0 if iso3_d =="CSK"  & contig == .

********************************************************************************
********************************************************************************

replace iso3_o = "SUN" if iso3num_o == 810
replace iso3_d = "SUN" if iso3num_d == 810

replace contig = 1 if iso3_o =="SUN"  & ( iso3_d =="CSK"  |  iso3_d =="POL"  | iso3_d =="HUN" | iso3_d =="ROM" | iso3_d =="FIN"  | iso3_d =="TUR"  | iso3_d =="IRN" | iso3_d =="AFG" | iso3_d =="PAK" | iso3_d =="CHN" | iso3_d =="MNG") 
replace contig = 1 if iso3_d =="SUN"  & ( iso3_o =="CSK"  |  iso3_o =="POL"  | iso3_o =="HUN" | iso3_o =="ROM" | iso3_o =="FIN"  | iso3_o =="TUR"  | iso3_o =="IRN" | iso3_o =="AFG" | iso3_o =="PAK" | iso3_o =="CHN" | iso3_o =="MNG") 

replace contig = 0 if iso3_o =="SUN"  & contig == .
replace contig = 0 if iso3_d =="SUN"  & contig == .

********************************************************************************
********************************************************************************

replace contig = 0 if iso3_o == iso3_d

********************************************************************************
********************************************************************************


duplicates drop

save "$BACI\gravity", replace  

keep if iso3_o =="BEL" | iso3_d =="BEL" 

replace iso3_o = "BLX" if iso3_o =="BEL"
replace iso3_d = "BLX" if iso3_d =="BEL"


append using  "$BACI\gravity"

bys iso3_o iso3_d t: gen obs = _N
drop if dist == .  & obs == 2
drop obs 


preserve
keep if t >= $fdate_bg
keep if t <= $ldate_bg 
save "$BACI\gravity", replace
restore


keep iso3_o iso3_d wto_o wto_d t
compress 

save "$BACI\gravity_wto", replace





********************************************************************************
********************************************************************************

use "$BACI\gravity", clear

global geo_temp_var "contig comlang_off comlang_ethno  comcol  col45   dist distcap distw distwces"

keep iso3_o iso3_d $geo_temp_var

rename iso3_o iso_o
rename iso3_d iso_d
duplicates drop

replace iso_o = "PSE" if iso_o =="PAL"
replace iso_d = "PSE" if iso_d =="PAL"

replace iso_o = "ROU" if iso_o =="ROM"
replace iso_d = "ROU" if iso_d =="ROM"

duplicates drop

bys iso_o iso_d: gen obs = _N
drop if dist == .  & obs == 2
drop obs 

save "$GRAVITY_COV\dist_cepii_edit", replace

********************************************************************************
********************************************************************************

use "$GRAVITY_COV\dist_cepii_edit", replace

keep if iso_o == "RUS" | iso_d =="RUS"


foreach x in $geo_temp_var {
rename  `x' `x'_ru
}


replace iso_o =  "SUN" if iso_o =="RUS"
replace iso_d =  "SUN" if iso_d =="RUS"
duplicates drop
bys iso_o iso_d: gen obs = _N
drop if dist_ru == .  & obs == 2
drop obs 

merge 1:1 iso_o iso_d using  "$GRAVITY_COV\dist_cepii_edit"
 
foreach x in $geo_temp_var {
replace  `x' =  `x'_ru if  `x' == . & _m == 3
}

cap drop *_ru
cap drop _m

save "$GRAVITY_COV\dist_cepii_edit", replace

********************************************************************************
********************************************************************************

use "$GRAVITY_COV\dist_cepii_edit", replace

keep if iso_o == "DEU" | iso_d =="DEU"


foreach x in $geo_temp_var {
rename  `x' `x'_dr
}


replace iso_o =  "DDR" if iso_o =="DEU"
replace iso_d =  "DDR" if iso_d =="DEU"
duplicates drop
bys iso_o iso_d: gen obs = _N
drop if dist_dr == .  & obs == 2
drop obs 

bys iso_o iso_d: keep if _n == _N

merge 1:1 iso_o iso_d using  "$GRAVITY_COV\dist_cepii_edit"
 
foreach x in $geo_temp_var {
replace  `x' =  `x'_dr if  `x' == . & _m == 3
}

cap drop *_dr
cap drop _m

save "$GRAVITY_COV\dist_cepii_edit", replace



********************************************************************************
********************************************************************************

use "$GRAVITY_COV\dist_cepii_edit", replace

keep if iso_o == "CZE" | iso_d =="CZE"


foreach x in $geo_temp_var {
rename  `x' `x'_cz
}


replace iso_o =  "CSK" if iso_o =="CZE"
replace iso_d =  "CSK" if iso_d =="CZE"
duplicates drop
bys iso_o iso_d: gen obs = _N
drop if dist_cz == .  & obs == 2
drop obs 

bys iso_o iso_d: keep if _n == _N

merge 1:1 iso_o iso_d using  "$GRAVITY_COV\dist_cepii_edit"
 
foreach x in $geo_temp_var {
replace  `x' =  `x'_cz if  `x' == . & _m == 3
}

cap drop *_cz
cap drop _m

save "$GRAVITY_COV\dist_cepii_edit", replace



********************************************************************************
********************************************************************************
use "$BACI\gravity", clear

drop if country_exists_o == 0
drop if country_exists_d == 0

save "$BACI\gravity", replace



********************************************************************************
********************************************************************************
/* generate also distance here


use "$GRAVITY_COV\dist_cepii", clear

keep if iso_o == "YUG" | iso_d =="YUG"
replace iso_o = "MNE" if iso_o =="YUG"
replace iso_d = "MNE" if iso_d =="YUG"
duplicates drop
save "$BACI\gravity_MNE", replace  

use "$GRAVITY_COV\dist_cepii", clear

keep if iso_o == "YUG" | iso_d =="YUG"
replace iso_o = "SRB" if iso_o =="YUG"
replace iso_d = "SRB" if iso_d =="YUG"
duplicates drop
append using "$BACI\gravity_MNE"

keep iso_o iso_d colony 
merge 1:1  iso_o iso_d using "$BACI\gravity_SRB_MNE"


append using "$GRAVITY_COV\dist_cepii"

replace iso_o = "SRB" if iso_o =="YUG"
replace iso_d = "SRB" if iso_d =="YUG"

replace iso_o = "PSE" if iso_o =="PAL"
replace iso_d = "PSE" if iso_d =="PAL"

replace iso_o = "ROU" if iso_o =="ROM"
replace iso_d = "ROU" if iso_d =="ROM"

save "$GRAVITY_COV\dist_cepii_edit", replace

*******************************************************************************/*
********************************************************************************
* clean
local files : dir "`c(pwd)'"  files "*.dta" 

foreach file in `files' { 
	erase `file'    
} 

cap log close
********************************************************************************
********************************************************************************
