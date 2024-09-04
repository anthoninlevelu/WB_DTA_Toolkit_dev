
********************************************************************************
********************************************************************************

cap 	log close
capture log using "$PROG\00_log_files\p3_load_baci_gravity", text replace

********************************************************************************
********************************************************************************
* WDI indicators GDP:  GDP (current US$)(NY.GDP.MKTP.CD)
wbopendata,  indicator(ny.gdp.mktp.cd) long clear  


drop if countrycode ==""
rename ny_gdp_mktp_cd gdp_wb
keep countrycode countryname year gdp_wb

drop if gdp == .

rename countrycode iso3 

keep year  iso3 gdp_wb countryname
replace iso3="SCG" if   ( iso3=="SRB"  & year  <= 2005 )   //  this is because in Comtrade 
replace iso3="YUG" if   ( iso3=="SCG"  & year  <= 1991 )   //  this is because in Comtrade 

replace iso3="SUN" if   ( iso3=="RUS"  & year  <= 1991 )
replace iso3="CSK" if    (iso3=="CZE" | iso3=="SVK") & year <= 1992

preserve
bys iso3: keep if _n == 1
keep iso3 countryname
rename iso3 iso_o
save "$TEMP/wb_country_name", replace
restore


collapse (sum) gdp_wb, by(iso3 year)


keep if year >= $year_start
keep if year <= $year_end


save "$TEMP/temp_gdp", replace


bys iso3: keep if _n==1
keep iso3
gen gdp_id = 1

save "$TEMP/VA_iso", replace

********************************************************************************
********************************************************************************
* unzip file 
cd "$BACI"

unzipfile "$baci_version", replace

********************************************************************************
********************************************************************************
* Generates the codebook for countries 
local files : dir "`c(pwd)'"  files "country_*.csv" 

import delimited `files' , encoding(ISO-8859-2)  clear 


rename country_code i
rename country_name			  libi
rename country_iso2           iso2
rename country_iso3           iso3


 

replace iso3 = "NAM"  if libi =="Namibia"
replace iso2 = "NA"   if libi =="Namibia"


local new = _N + 1
        set obs `new'
replace i    = 0        if _n == `new'
replace libi = "World"  if _n == `new'
replace iso2 = "00"     if _n == `new'
replace iso3 = "WLD"    if _n == `new'

replace iso3 = "TWN"    if i ==490


drop if iso3 == "N/A"

preserve
keep i iso3 iso2 libi 
rename libi country
rename i    iso

duplicates drop
save "iso2_iso3.dta", replace
 restore



keep  i iso3 libi  
rename i ctycode

save "cty_code_baci.dta", replace

********************************************************************************
* clean
local files : dir "`c(pwd)'"  files "*code*.csv" 

foreach file in `files' { 
	erase `file'    
} 


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

merge m:1 ctycode using "cty_code_baci.dta", keepusing(iso3)

tab ctycode if _m == 1
tab iso3    if _m == 2


keep if _m==3
drop _m
cap drop ctycode

cap drop if  iso3digitalpha=="NULL"
cap rename iso3digitalpha iso_o
cap rename iso3           iso_o
 
********************************************************************************
********************************************************************************

global crap "SXM SSD BES GUM CUW ATF ASM IOT"
foreach f of global crap {
drop if iso_o=="`f'" 
}

********************************************************************************
********************************************************************************
cap drop ctycode

gen ctycode= $code_destin

merge m:1 ctycode using "cty_code_baci.dta", keepusing(iso3)


tab ctycode if _m == 1
tab iso3    if _m == 2

keep if _m==3
drop _m
cap drop ctycode

cap drop if  iso3digitalpha=="NULL"
cap rename   iso3digitalpha iso_d
cap rename   iso3           iso_d
 
********************************************************************************
********************************************************************************

global crap "SXM SSD BES GUM CUW ATF ASM IOT"
foreach f of global crap {
drop if iso_d=="`f'" 
}

********************************************************************************
********************************************************************************


cap drop if iso_o=="VIR"
cap drop if iso_d=="VIR"


cap drop if iso_o=="UMI"
cap drop if iso_d=="UMI"

********************************************************************************
********************************************************************************
	
if 	`s'   == 1 {
	
save 	"trade_baci_cty", replace
	
}
	 
if 	`s'   > 1 {
	
append  using 	"trade_baci_cty"
save 			"trade_baci_cty", replace
	
}	

local s = `s'  + 1 
	
} 

cd "$BACI"
zipfile    "trade_baci_cty.dta", saving("$DATA/BACI/baci_HS2002.zip",  replace )
cap erase  "$BACI/trade_baci_cty.dta"   // zipped file is still in the directory

zipfile    "cty_code_baci.dta", saving("$DATA/BACI/cty_code_baci_HS2002.zip",  replace )
cap erase  "$BACI/cty_code_baci.dta"

zipfile    "iso2_iso3.dta", saving("$DATA/BACI/iso2_iso3_HS2002.zip",  replace )
cap erase  "$BACI/iso2_iso3.dta"


********************************************************************************
********************************************************************************
* clean: Baci directory
 cd "$BACI"
 
local files : dir "`c(pwd)'"  files "*.csv" 

foreach file in `files' { 
	erase `file'    
} 


********************************************************************************
********************************************************************************
* Upload Gravity data 
********************************************************************************
********************************************************************************
 
cd $GRAVITY 

unzipfile "$grav_version", replace

local files : dir "`c(pwd)'"  files "Gravity_V*.dta" 
display `files'

use `files' , clear

tab year

rename year t
keep if t >= $year_start
 


drop if country_exists_o == 0
drop if country_exists_d == 0

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

replace contig = 1 if iso3_o =="DDR"  & ( iso3_d =="DEU"  |  iso3_d =="POL"  | iso3_d =="CSK"  ) 
replace contig = 1 if iso3_d =="DDR"  & ( iso3_o =="DEU"  |  iso3_o =="POL"  | iso3_o =="CSK"  ) 

replace contig = 0 if iso3_o =="DDR"  & contig == .
replace contig = 0 if iso3_d =="DDR"  & contig == .

********************************************************************************
********************************************************************************

 

replace contig = 1 if iso3_o =="CSK"  & ( iso3_d =="SUN"  |  iso3_d =="POL"  | iso3_d =="DEU" | iso3_d =="DDR" | iso3_d =="AUT" | iso3_d =="HUN" ) 
replace contig = 1 if iso3_d =="CSK"  & ( iso3_o =="SUN"  |  iso3_o =="POL"  | iso3_o =="DEU" | iso3_o =="DDR" | iso3_o =="AUT" | iso3_o =="HUN" ) 

replace contig = 0 if iso3_o =="CSK"  & contig == .
replace contig = 0 if iso3_d =="CSK"  & contig == .

********************************************************************************
********************************************************************************
 

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
save "$GRAVITY/gravity", replace  



cd "$GRAVITY"
zipfile    "gravity.dta", saving("$DATA/GRAVITY/gravity.zip",  replace )


 
********************************************************************************
********************************************************************************
* Farid Language

import delimited "$LANG/dicl_database.csv", clear

rename iso3_i   iso_o 
rename iso3_j   iso_d 

keep iso_o iso_d lpn lps cnl csl cor
 

save "$DATA/GRAVITY/language_FT.dta", replace

********************************************************************************
********************************************************************************
* clean gravity directory
cd $GRAVITY 


local files : dir "`c(pwd)'"  files "*.dta" 

foreach file in `files' { 
	erase `file'    
} 

cap log close

********************************************************************************
********************************************************************************
