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


* Anthonin: package * 
* couldn't run on my end without these packages:

net from http://www.stata-journal.com/software/sj15-3/
net install dm0082.pkg, replace
ssc install silhouette, replace
net from "http://teaching.sociology.ul.ie/statacode"
net describe clutils
net install clutils, replace

******************************************************************************** 
********************************************************************************
* Define your working path here: this is where you locate the "Toolkit" folder

 
global DB	             "C:/Users/gianl/Dropbox/"
global DB     			"d:/santoni/Dropbox/"
* Anthonin:
global DB			"/Users/anthoninlevelu/Desktop/World Bank/2024"


global ROOT 		     "$DB/WW_other_projs/WB_2024/WB_GE/WB_DTA_Toolkit"	
* Anthonin:
global ROOT 		"$DB/PTA_project/FLRS/WB_DTA_Toolkit_dev"	 		 
global CODING 			 "$DB/Regionalism_2017/NADIA_project/data_sept2020/raw_rta/update_september2021"


********************************************************************************
********************************************************************************
global PROG_dta           "$ROOT/0.prog/0_datamake/000_DTA_progs" 
global PROG_trade         "$ROOT/0.prog/0_datamake/00_TRADE_progs"

global DATA 	          "$ROOT/1.data"
global DTA                "$DATA/DTA"
global TEMP	     		  "$DATA/temp"
global CLUS	     		  "$ROOT/2.res/clusters"


global dataset            "DTA 2.0 - Vertical Content (v2)"    // dataset available here

global cluster_var        "kmean kmedian pam h_clus kmeanR_ch kmeanR_asw kmeanR kmeanR_pam kmeanR_man"
global type    			  "w"   				
 // w: weighted provision matrix ; u: unweighted provision matrix (1/0)
global uk_fix  			  "fix_before_cluster"   		 // fix_before_cluster or fix_after_cluster
// fix_before_cluster (keep in the cluster UK agreements and use the same provision as EU) or fix_after_cluster (drop UK empty agreements from the cluster fix after with the same clusters as EU )

global drop_psa           "NO"  
// if YES we drop PSA agreements before running clusters ; if NO it keeps the PSA in the clustering
********************************************************************************
********************************************************************************
/* make sure the TEMP folder is empty

cd "$TEMP"
local files : dir "`c(pwd)'"   files "*.dta" 
display  `files' 

   
foreach file in `files' { 
	erase `file'    
} 

*******************************************************************************/
********************************************************************************
* read the data 

do "$PROG_dta/p0_read_DTA.do"
do "$PROG_dta/p1_prepare_DTA_for_cluster.do"
do "$PROG_dta/p2_normalize_DTA.do"


* compute clusters in Stata (new routine in R produce same clusters than Stata kmean)
foreach var in w u {
global type    			  "`var'"   				

do "$PROG_dta/p3_compute_cluster_DTA.do"
}

* run tyhe R-script also, always check the directory in the script:
shell "C:/Program Files/R/R-4.4.0/bin/x64/Rscript.exe" "$PROG_dta/p4_kmean_w.R"
shell "C:/Program Files/R/R-4.4.0/bin/x64/Rscript.exe" "$PROG_dta/p4_kmean_u.R"



********************************************************************************
********************************************************************************
