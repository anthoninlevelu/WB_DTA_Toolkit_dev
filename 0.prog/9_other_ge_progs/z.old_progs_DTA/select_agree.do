

********************************************************************************
  drop if agreement == "European Free Trade Association (EFTA)"

/*
EFTA is now split into 4 sub-agreement to take into account change in perimeter
*/

*  drop if id_agree == 284 
*  drop if id_agree == 285 
*  drop if id_agree == 286 
*  drop if id_agree == 287 

********************************************************************************
 * drop if id_agree == 281 

/*  
id_agree == 281  agreement == "CP Trans-Pacific Partnership (CPTPP)"

never into force

*/


/******************************************************************************/
  drop if agreement == "Eurasian Economic Union (EAEU) - Accession of Armenia"

/*  
id_agree == 257   Eurasian Economic Union (EAEU) - Accession of Armenia  (CU & EIA)
this is redundant with 
id_agree: 255 Eurasian Economic Union (EAEU) same year and composition   (CU & EIA)
*/

********************************************************************************
  drop if agreement == "Eurasian Economic Union (EAEU) - Accession of the Kyrgyz Republic"


/*
id_agree == 264   Eurasian Economic Union (EAEU) - Accession of the Kyrgyz Republic   (CU & EIA)
this is redundant with 
id_agree: 255 Eurasian Economic Union (EAEU) same year and composition                (CU & EIA)
*/


********************************************************************************
  drop if agreement == "India - Bhutan"

/*
id_agree == 140   India - Bhutan						 	(FTA)
this is redundant with 
id_agree: 136 South Asian Free Trade Agreement (SAFTA)      (FTA)

*/

********************************************************************************
  drop if agreement == "Russian Federation - Belarus - Kazakhstan"

/*

id_agree == 223  Russian Federation - Belarus - Kazakhstan  (CU)
this is redundant with 
id_agree: 41 Eurasian Economic Community (EAEC)             (CU)

*/


********************************************************************************
  drop if agreement == "Japan - Philippines"

/*

id_agree == 156  Japan - Philippines (FTA & EIA)
this is redundant with   
id_agree: 175 ASEAN - Japan           (FTA)

*/


********************************************************************************
  drop if agreement == "Brunei Darussalam - Japan"

 
/*
id_agree == 143  Brunei Darussalam - Japan (FTA & EIA)
this is redundant with 
id_agree: 175 ASEAN - Japan                (FTA)

*/

********************************************************************************
  drop if agreement == "Japan - Indonesia"

*cap drop if id_agree == 139

/*
id_agree == 139  Japan - Indonesia        (FTA & EIA)
this is redundant with 
id_agree: 175 ASEAN - Japan                (FTA)
*/


********************************************************************************
  drop if agreement == "New Zealand - Malaysia"

*cap drop if id_agree == 206

/*
id_agree == 206 New Zealand - Malaysia 			(FTA & EIA)
this is redundant with 
id_agree: 183 ASEAN - Australia - New Zealand   (FTA & EIA)
*/
*******************************************************************************/

