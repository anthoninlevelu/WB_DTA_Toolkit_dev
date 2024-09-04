
********************************************************************************

preserve
	bys year: keep if _n==1
	keep year
	save "$TEMP\square", replace
restore


preserve
	bys 	iso_o: keep if _n==1
	keep 	iso_o
	cross using "$TEMP\square.dta"
	save "$TEMP\square.dta", replace
restore


preserve
	bys 	iso_d: keep if _n==1
	keep 	iso_d
	cross 	using "$TEMP\square.dta"
	save 	"$TEMP\square.dta", replace
restore

merge 1:1 year iso_o iso_d using "$TEMP\square.dta", nogenerate
cap erase 	 "$TEMP\square.dta"

drop if iso_o == iso_d
replace v = 0 if v==.

********************************************************************************
