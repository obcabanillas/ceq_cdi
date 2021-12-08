********************************************************************************
*							Country-specific code							   *
*                               Côte d'Ivoire							       *
********************************************************************************

clear
cap program drop monprog_merge_s00
cap program drop monprog_def_zaemil
cap program drop monprog_def_region
cap program drop monprog_lab_region

********************************************************************************

program define monprog_merge_s00
*merge m:1 vague grappe menage using "$datain_men/s00_me_$}pays}.dta", ///
*merge m:1 vague grappe menage using "$data1/s00_me_CIV2018_19.dta", keepusing(s00q00 s00q01 s00q02 s00q03 s00q04 s00q08 s00q23a s00q27) 
merge m:1 vague grappe menage using "$datain_men/s00_me_CIV2018.dta", ///
 keepusing(s00q00 s00q01 s00q02 s00q04 s00q08 s00q23a s00q27)

*** s00q03
keep if _merge ==3
drop _merge
rename s00q01 region
*rename s00q02 $admin2
*rename s00q03 $admin3
rename s00q04 milieu

label var region "Region de residence"
*label var $admin2 "departement de residence"
*label var $admin3 "sous-prefecture de residence"
label var milieu "Milieu residence"
end

********************************************************************************

program define monprog_def_zaemil
*Creation de zae
recode region (4 7 11 21 29 33=1 "CENTRE") ///
			  (2 6 12 18 27=2 "CENTRE-OUEST")  ///
              (3 8 10 14 19 20 22 23 24 28 32=3 "NORD") ///
			  (1 5 13 16 26 30=4 "SUD-EST") ///
			  (9 15 17 25 31=5 "SUD-OUEST") ///
			  (0=6 "ABIDJAN"), gen(zae)
replace zae=6 if region==1 & milieu==1 
label var zae "Zone agroecologique"

*Creation de zaemil
egen zaemil = group(zae milieu)
tab zaemil zae
label def zaemil 1 "CENTRE (urbain)" 2 "CENTRE (rural)" ///
				 3 "CENTRE-OUEST (urbain)" 4 "CENTRE-OUEST (rural)" ///
				 5 "NORD (urbain)" 6 "NORD (rural)" ///
				 7 "SUD-EST (urbain)" 8 "SUD-EST (rural)" ///
				 9 "SUD-OUEST (urbain)" 10 "SUD-OUEST (rural)" ///
				 11 "ABIDJAN", replace
label val zaemil zaemil

* Creation de milieu2
gen     milieu2 = (region==1 & milieu==1)
replace milieu2 = 2 if milieu==1 & milieu2 ==0
replace milieu2 = 3 if milieu==2 & milieu2 ==0
label define milieu2 1 "Abidjan urbain" 2 "Autre urbain" 3 "Rural" 
label values milieu2 milieu2
end

********************************************************************************

program define monprog_lab_region
cap label drop regl
lab def regl  1 "DISTRICT ABIDJAN" 2 "HAUT-SASSANDRA" ///
           3 "PORO" 4 "GBEKE" 5 "INDENIE-DJUABLIN" 6 "TONKPI" ///
           7 "DISTRICT YAMOUSSOUKRO" 8 "GONTOUGO" ///
           9 "SAN-PEDRO" 10 "KABADOUGOU" 11 "N'ZI" 12 "MARAHOUE" ///
          13 "SUD-COMOE" 14 "WORODOUGOU" 15 "LÔH-DJIBOUA"  ///
		  16 "AGNEBY-TIASSA" 17 "GÔH" 18 "CAVALLY" 19 "BAFING" 20 "BAGOUE" ///
          21 "BELIER" 22 "BERE" 23 "BOUNKANI" 24 "FOLON" 25 "GBÔKLE" 26 "GRANDS-PONTS" ///
          27 "GUEMON" 28 "HAMBOL" 29 "IFFOU" 30 "LA ME" 31 "NAWA" 32 "TCHOLOGO" 33 "MORONOU", modify		 
lab val region regl
end


program dir
