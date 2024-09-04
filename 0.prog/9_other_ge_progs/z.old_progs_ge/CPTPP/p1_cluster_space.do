

clear all
program drop _all
macro drop _all
matrix drop _all
clear mata
clear matrix
   
set virtual on
set more off
set scheme s1color

set seed 20082015

global seed "20082015"


 global DB 			"D:\Santoni\Dropbox"
*global DB      	"C:\Users\gianl\Dropbox"
 global DB  		"E:\Dropbox\"


********************************************************************************

global ROOT 	                "$DB\WB_DTA_Toolkit"
global PROG 	                "$ROOT\prog"
global DATA 	                "$ROOT\data"
global TEMP	                    "$DATA\temp"
global RES	                    "$ROOT\res"

********************************************************************************
********************************************************************************

cd "$DATA\cty"

cap 	log close
capture log using "$PROG\0_data_make\log_files\build_gravity_rta", text replace


********************************************************************************
*                    Import Cluster and Bilateral RTAs                       *
********************************************************************************
*******************************************************************************/
/* from R

test3    <- list(rownames(df)  , res[["Best.partition"]],   k3[["cluster"]] , km[["cluster"]] , km2[["cluster"]])

v1 = id_agree
v2 = Best.partition: best partition, Euclidean distance, silouette method
v3 = k   : kmean cluster



v4 = km:  A parallel and scalable implementation of the algorithm described in 
Ostrovsky, Rafail, et al. 
"The effectiveness of Lloyd-type methods for the k-means problem."
Journal of the ACM (JACM) 59.6 (2012): 28.




v5 = km2  MORE STABLE
Arthur, D. and S. Vassilvitskii (2007). “k-means++: The advantages of careful seeding.” 
In H. Gabow (Ed.), Proceedings of the 18th Annual ACM-SIAM Symposium on Discrete Algorithms [SODA07], 
Philadelphia, pp. 1027-1035. Society for Industrial and Applied Mathematics.



*******************************************************************************/

import excel "Cluster_list.xlsx", sheet("agreements") firstrow allstring clear
save "$TEMP\temp", replace

********************************************************************************
import excel "kmeans_final.xlsx", firstrow allstring clear
rename V1 id_agree

rename V2 kmeanS_r
rename V3 kmean_r
rename V4 kmeanPP
rename V5 kmeanPP2

destring kmeanPP2, replace
destring kmeanPP, replace
 



merge 1:1 id_agree using "$TEMP\temp"
drop _m

order id_agree agreement entry_force
export excel using "$TEMP\Cluster_list.xlsx", sheet("agreements_full")  sheetreplace firstrow(variables) nolabel 

keep id_agree agreement entry_force
destring id_agree, replace
destring entry_force, replace
save "$TEMP\id_agree_cluster_list.dta", replace 


********************************************************************************
********************************************************************************

import excel "Cluster_list.xlsx", sheet("agreements") firstrow allstring clear

cap drop Entry_Force  
cap drop Signature
cap drop Agree_name
cap drop agreement
cap drop entry_force

save "$TEMP\temp", replace

********************************************************************************
********************************************************************************

import excel "kmeans_final.xlsx", firstrow allstring clear
rename V1 id_agree

rename V2 kmeanS_r
rename V3 kmean_r
rename V4 kmeanPP
rename V5 kmeanPP2

destring kmeanPP2, replace
destring kmeanPP, replace
 



merge 1:1 id_agree using "$TEMP\temp"
drop _m

destring id_agree, replace

gen rta = 1

destring kmean		, replace
destring kmedian	, replace
destring h_cluster	, replace
destring pam		, replace

 
********************************************************************************
foreach k in  kmeanPP2 kmeanPP kmean kmedian h_cluster pam {

bys `k': gen obs = _N   


replace obs = . if  `k' == .

 
egen min     = min(obs) 
egen max     = max(obs) 


replace  `k' =  1 if obs == min
replace  `k' =  3 if obs == max

replace  `k' =  2 if obs < max & obs > min


tab `k'

cap drop obs
cap drop min

cap drop max
cap drop med

}



save "$TEMP\kmeans_estimate", replace
erase "$TEMP\temp.dta"
********************************************************************************


cap drop if kmeanPP2 == .
keep id_agree kmeanPP2 h_cluster pam 

merge 1:1 id_agree using "$TEMP\id_agree_cluster_list.dta"
keep if _m == 3
drop _m
order id_agree agreement entry_force

rename kmeanPP2 kmeanPP_baseline

save "$RES\id_agree_cluster_list.dta", replace 

/*******************************************************************************
*******************************************************************************/


use "bilateral_rta_ctys", clear



replace iso_o="ROM" if iso_o =="ROU"
replace iso_d="ROM" if iso_d =="ROU"

gen iso3 = iso_o


merge m:1 iso3 using "WBregio.dta"
drop if _m == 2
drop _m

rename region region_o

cap drop iso3

gen iso3 = iso_d


merge m:1 iso3 using "WBregio.dta"
drop if _m == 2
drop _m

rename region region_d

keep if region_o =="East Asia & Pacific" | region_d=="East Asia & Pacific"

 
********************************************************************************
 drop if region_o == ""
 drop if region_d == ""

********************************************************************************
* here you will find some specific information of PTAs portfolio by country (to comment results)
merge m:1 id_agree using "$TEMP\kmeans_estimate", keepusing(kmeanPP kmeanPP2)
keep if _m == 3
drop _m


******************************************************************************** 
 

bys id_agree region_o region_d: keep if _n == 1

keep id_agree agreement entry_force region_o  region_d

******************************************************


egen expcode 		= group(region_o id_agree)
egen impcode 		= group(region_d id_agree)

gen sym_id1 		= expcode
gen sym_id2 	    = impcode
replace sym_id1 	= impcode if impcode < expcode
replace sym_id2 	= expcode if impcode < expcode
egen sym_pair_id 	= group(sym_id1 sym_id2)


bys sym_pair_id: keep if _n == 1

merge m:1 id_agree using "$TEMP\kmeans_estimate", keepusing( kmeanPP2 pam  h_cluster)
keep if _m == 3
drop _m

keep id_agree agreement entry_force region_o  region_d  kmeanPP2 pam  h_cluster

egen number_agree = nvals(id_agree)

tab kmeanPP2 if ( region_o == "East Asia & Pacific" | region_d == "East Asia & Pacific" ) & (region_o != region_d )
tab kmeanPP2 if ( region_o == "East Asia & Pacific" & region_d == "East Asia & Pacific" )  
*ed if kmeanPP2 == 1 & ( region_o == "East Asia & Pacific" & region_d == "East Asia & Pacific" )  
*ed if kmeanPP2 == 1 & ( region_o == "East Asia & Pacific" | region_d == "East Asia & Pacific" ) & (region_o != region_d )


save "$TEMP\agreements_with_clusters", replace

********************************************************************************
********************************************************************************
import excel "kmeans_coordinates.xlsx", firstrow allstring clear

rename V1 id_agree

rename V2 x_pca
rename V3 y_pca

destring id_agree, replace
destring x_pca, replace
destring y_pca, replace

***********************************************

merge m:1 id_agree using "id_agree_legend"
keep if _m == 3
drop _m

***********************************************

merge 1:1 id_agree using "$TEMP\kmeans_estimate", keepusing(kmeanPP2 kmeanPP)
keep if _m == 3
drop _m _m

***********************************************
***********************************************


sum y_pca, d
sort y_pca
replace y_pca = y_pca[_n-1]*(1.05) if y_pca ==r(max) 
sum y_pca, d
gsort -y_pca
replace y_pca = y_pca[_n-1]*(1.05) if y_pca ==r(min) 



sum x_pca, d
sort   x_pca
replace x_pca = x_pca[_n-1]*(1.05) if x_pca ==r(max) 
gsort -x_pca
replace x_pca = x_pca[_n-1]*(1.05) if x_pca ==r(min) 


sum x_pca
replace x_pca =  x_pca - r(mean)


sum y_pca
replace y_pca =  y_pca - r(mean)

*replace x_pca = x_pca*-1
*replace y_pca = y_pca*-1
********************************************************************************
********************************************************************************

cap drop label
gen 	label = "" 



********************************************************************************
********************************************************************************

tw (scatter y_pca x_pca if kmeanPP2 ==  1                 ,  					mcolor(dkorange) 	 mlcolor(dkorange) 	mlwidth(medium) msymbol(Oh)  msize(medium)  mlabel(label)   mlabposition(6)  mlabgap(1)  mlabcolor(cranberry)    ) /* 
*/ (scatter y_pca x_pca if kmeanPP2 ==  2 				  ,  					mcolor(gs10) 	 	 mlcolor(gs10) 	mlwidth(medium) msymbol(Th)  msize(medium)      mlabel(label)   mlabposition(4) mlabgap(0) mlabangle(30) mlabcolor(cranberry)  	) /*
*/ (scatter y_pca x_pca if kmeanPP2 ==  3 				 ,  					mcolor(dknavy*.75) 	 mlcolor(dknavy*.75)   	   mlwidth(medium) msymbol(Dh)  msize(medium)  mlabel(label)   mlabposition(7)   mlabgap(-2pt)    mlabcolor(cranberry)  )  , /*
*/ legend(label(1 "Cluster 1") label(2 "Cluster 2")  label(3 "Cluster 3")  row(1)  order(1 2 3) region(lwidth(none) margin(medium) ) ) ytitle("PC1 (11.5 % )")   xtitle("PC2 (65.2 %)")   plotregion(lwidth(none) margin(medium) ) 

*gr export "$RES\space_cluster.pdf", as(pdf) replace

********************************************************************************
********************************************************************************
cap drop china_od
gen china_od =1 if id_agree==90 | id_agree==106 | id_agree==125 | id_agree==133 | id_agree==162 | id_agree==165 | id_agree==179 | id_agree==210 | id_agree==249| id_agree==252 | id_agree==268| id_agree==270

* 281	Comprehensive and Progressive Agreement for Trans-Pacific Partnership (CPTPP)	2018


tw (scatter y_pca x_pca if kmeanPP2 == 1	,  mcolor(dkorange) 	 mlcolor(dkorange) 		mlwidth(medium) msymbol(Oh)   ) /* 
*/ (scatter y_pca x_pca if kmeanPP2 == 2	,  mcolor(dknavy*.75) 	 mlcolor(dknavy*0.75) 	mlwidth(medium) msymbol(Dh)   ) /*
*/ (scatter y_pca x_pca if kmeanPP2 == 3	,  mcolor(gs10) 	 	 mlcolor(gs10) 			mlwidth(medium) msymbol(Th)   )  /*
*/ (scatter y_pca x_pca if china_od ==1   	,  mcolor(cranberry) 	 mlcolor(cranberry) 	mlwidth(medium) msymbol(x)  	msize(medium) )  /*
*/ (scatter y_pca x_pca if id_agree== 281	,  mcolor(cranberry*.5) 	 mlcolor(cranberry*.5) 	mlwidth(medium) msymbol(D)  	msize(medium) mlabel(label)   mlabposition(6)  mlabgap(0) mlabangle(-0) mlabcolor(cranberry*.5)  ),   /*
*/ legend(label(1 "Deep") label(2 "Medium")  label(3 "Shallow") label(4 "PTAs with China")  label(5 "CPTPP")  row(1) /*
*/ order(1 2 3 4 5) region(lwidth(none) margin(medium) ) )ytitle("PC1 (11.5 % )")   xtitle("PC2 (65.2 %)")   plotregion(lwidth(none) margin(medium) )  
gr export "$RES\space_cluster_CPTPP_wnames.pdf", as(pdf) replace
gr export "$RES\space_cluster_CPTPP_wnames.eps", as(eps) preview(on) replace
gr export "$RES\space_cluster_CPTPP_wnames.png", as(png)  replace

********************************************************************************
********************************************************************************

gen kmeanPP2_robust = kmeanPP2

* Reclassify 3 to 1
replace kmeanPP2_robust = 1 if id_agree ==  69 | id_agree == 152 | id_agree == 272
/*
id_agree	x_pca	y_pca	agreement
69	-2.183962	-.11067973	New Zealand - Singapore
152	-2.9366985	.36469585	Common Economic Zone (CEZ)
272	-3.4052414	.41463319	Panama - Dominican Republic

*/
********************************************************************************
* Reclassify 2 to 1
/*
id_agree	x_pca	y_pca	agreement
220	-.5200496	-2.9626321	EFTA - Hong Kong, China
27	-1.205507	-3.5559622	North American Free Trade Agreement (NAFTA)
*/
replace kmeanPP2_robust = 1 if id_agree == 220 | id_agree == 27


********************************************************************************
* Reclassify 3 to 2
/*
id_agree	x_pca	y_pca	agreement
279	1.6565714	.82393751	ASEAN - Korea, Republic of
id_agree	x_pca	y_pca	agreement
125	1.2936144	.61035961	Chile - China

*/

replace kmeanPP2_robust = 2 if id_agree == 279 | id_agree == 125

********************************************************************************

********************************************************************************
* Reclassify 2 to 3
/*
id_agree	x_pca	y_pca	agreement	entry_force
169	.03572692	-.07999668	Canada - Peru	2009
201	.10154261	-.15751038	Canada - Colombia	2011

*/

replace kmeanPP2_robust = 3 if id_agree == 169 | id_agree == 201

********************************************************************************


tw (scatter y_pca x_pca if kmeanPP2_robust ==  1  &  kmeanPP2  == 1 , mcolor(dkorange) 	 mlcolor(dkorange) 	 mlwidth(medium) msymbol(Oh)  msize(medium)  mlabel(label)   mlabposition(6) mlabgap(1)  mlabcolor(cranberry) )  /* 
*/ (scatter y_pca x_pca if kmeanPP2_robust ==  2  &  kmeanPP2  == 2 , mcolor(dknavy*.75) mlcolor(dknavy*.75) mlwidth(medium) msymbol(Dh)  msize(medium)  mlabel(label)   mlabposition(4) mlabgap(0) mlabangle(30) mlabcolor(cranberry)) /*
*/ (scatter y_pca x_pca if kmeanPP2_robust ==  3  &  kmeanPP2  == 3 , mcolor(gs10) 		 mlcolor(gs10)   	 mlwidth(medium) msymbol(Th)  msize(medium)  mlabel(label)   mlabposition(7) mlabgap(-2pt)    mlabcolor(cranberry)) /*
*/ (scatter y_pca x_pca if kmeanPP2_robust ==  1  &  kmeanPP2  == 3 , mcolor(dkorange)   mlcolor(dkorange)   mlwidth(medium) msymbol(Th)  msize(medium)  mlabel(label)   mlabposition(4) mlabgap(0) mlabangle(30) mlabcolor(cranberry)) /*
*/ (scatter y_pca x_pca if kmeanPP2_robust ==  1  &  kmeanPP2  == 2 , mcolor(dkorange)   mlcolor(dkorange)   mlwidth(medium) msymbol(Dh)  msize(medium)  mlabel(label)   mlabposition(4) mlabgap(0) mlabangle(30) mlabcolor(cranberry)) /*
*/ (scatter y_pca x_pca if kmeanPP2_robust ==  2  &  kmeanPP2  == 3 , mcolor(dknavy*.75) mlcolor(dknavy*.75) mlwidth(medium) msymbol(Th)  msize(medium)  mlabel(label)   mlabposition(4) mlabgap(0) mlabangle(30) mlabcolor(cranberry)) /*
*/ (scatter y_pca x_pca if kmeanPP2_robust ==  3  &  kmeanPP2  == 2 , mcolor(gs10) 	     mlcolor(gs10) 		 mlwidth(medium) msymbol(Dh)  msize(medium)  mlabel(label)   mlabposition(4) mlabgap(0) mlabangle(30) mlabcolor(cranberry)) ,/*
*/ legend(label(1 "Cluster 1") label(2 "Cluster 2")  label(3 "Cluster 3")  row(1)  order(1 2 3) region(lwidth(none) margin(medium))) ytitle("PC1 (11.5 % )") xtitle("PC2 (65.2 %)") plotregion(lwidth(none) margin(medium)) 	
*gr export "$RES\space_cluster_robust.pdf", as(pdf) replace
 
keep id_agree kmeanPP2_robust
save  "$TEMP\temp_robust_kmean", replace


rename kmeanPP2_robust kmeanPP_robust
merge 1:1 id_agree using "$TEMP\id_agree_cluster_list.dta"
drop _m
drop if id_agree == .

export excel using "$DATA\Cluster_list_jan_2022.xlsx", sheet("Agreements_Clusters")  sheetreplace firstrow(variables) nolabel 

*******************************************************************************/
********************************************************************************
********************************************************************************
********************************************************************************
cd "$DATA\ge"
global PROG 	 				"$ROOT\prog\1_ge_simulations\CPTPP"


use "trade_wRTA_yearly.dta", clear
keep if $select_dataset == 1
$set_zeros
keep if year     == 2018



keep if id_agree==90 | id_agree==106 | id_agree==125 | id_agree==133 | id_agree==162 | id_agree==165 | id_agree==179 | id_agree==210 | id_agree==249| id_agree==252 | id_agree==268| id_agree==270 | id_agree == 281


merge m:1 iso_d using "$PROG\cptpp.dta", keepusing(cptpp_d )
drop  if _m == 2
drop _m

merge m:1 iso_o using "$PROG\cptpp.dta", keepusing(cptpp_o )
drop  if _m == 2
drop _m



********************************************************************************

preserve

keep if iso_o == "CHN"  
rename iso_d iso3

keep iso3 kmeanPP 
save  "$ROOT\data\cty\temp_map", replace
restore

********************************************************************************

keep if cptpp_o == 1
bys iso_o: keep if _n == 1
rename iso_o iso3
rename kmeanPP kmeanPP_cptpp
keep iso3 kmeanPP_cptpp
merge 1:1 iso3 using "$ROOT\data\cty\temp_map"
drop _m
save  "$ROOT\data\cty\temp_map", replace

********************************************************************************
********************************************************************************
********************************************************************************

cd "$ROOT\data\cty\"

use "world_d.dta", clear

drop if NAME=="BRITISH INDIAN OCEAN TERRITORY"
drop if NAME=="FRENCH SOUTHERN TERRITORIES"
drop if NAME=="VIRGIN ISLANDS" | NAME=="VIRGIN ISLANDS (U.S.)"
drop if NAME=="ANTARCTICA"

replace country ="SERBIA AND MONTENEGRO" if country=="YUGOSLAVIA"

reclink country using "iso3_country.dta", idm(id_m) idu( id_u) gen(myscore)

drop country Ucountry id_m myscore id_u
drop _m

replace iso3="KOR" if  NAME=="KOREA, REPUBLIC OF"

merge m:1 iso3 using "temp_map.dta"
tab iso3  if _m==2
drop if _m==2
drop _m


preserve
keep if kmeanPP_cptpp != .
drop kmeanPP_cptpp
keep _ID
mergepoly _ID using "world_c.dta", coord("cptpp_c.dta") replace

restore


 
********************************************************************************
********************************************************************************

spmap  kmeanPP using "world_c.dta", id(_ID) clmethod(custom) clbreaks(0 2 3) /*
 */   fcolor(sand*1 sand*.5) ndfcolor(white)   ndsize(vvthin)   osize(vvthin ..) plotregion(margin(zero))  /*
 */  legend(label(1 "No Agreement") label(2 "Medium") label(3 "Shallow")  )   legorder(hilo)     /*
 */ polygon(data("cptpp_c.dta") fcolor(sand*.8)  ocolor(dknavy*.8) osize(medthick)  legenda(on) leglabel(CPTPP)  )  
gr save   "map_cptpp.gph", replace
gr export "map_cptpp.pdf", as(pdf) replace
gr export "map_cptpp.png", as(png) replace

 
********************************************************************************
********************************************************************************
