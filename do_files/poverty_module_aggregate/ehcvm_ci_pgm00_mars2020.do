*******************************************************************************
*       Enquete harmonisee sur les conditions de vie des menages - UEMOA      *
*  Creation de fichiers de travail NSU et prix a partir des fichiers de base  *
*                                                                             *
* *****************************************************************************
clear
set more off  
/*
global data "C:\EHCVM_CIV_200416"

global datain "$data\Datain"
global datain_men "$datain\Menage"
global datain_com "$datain\Commune"
global datain_aux "$datain\Auxiliaire"

global dataout "$data\Dataout"
global dataout_p "$dataout\Prix"
global dataout_nsu "$dataout\NSU"
global dataout_temp "$dataout\Temp"
*/
* C:\Users\wb324658\OneDrive - WBG\FY18\CI\HDataCIV\Data_CIV\EHCVM-DATA-TRAITEES-24Janvier2020\CIV\Dataout\dataout_p
// global data "C:\Users\wb324658\OneDrive - WBG\FY18\CI\HDataCIV\Data_CIV\EHCVM-DATA-TRAITEES-24Janvier2020\CIV"
// global datain_men "$data\MEN-PRIX(Datain)"
// global datain_aux "$data\MEN-PRIX(Datain)\parametre"

*********************************************************************************
*********************************************************************************

*********************
********************* Creation de fichiers NSU a differents niveaux geographiques
*********************
use "$datain_aux\ehcvm_nsu_CIV2018", clear
****************************************************use "$datain_aux\ehcvm_nsu_CIV2018_19", clear
****************************************************use "$datain_aux\nsu2017_civ_releve_corr.dta", clear
*cap rename s00q01 $admin1
*cap rename s00q02 $admin2
*cap rename s00q03 $admin3

cap rename s00q01 region
cap rename s00q04 milieu

cap rename codeProduit codpr														// adaptez le nom de produitID
cap rename q110a poids
replace unite = unite*10+taille 

monprog_def_zaemil

*cap gen poids=poids_moyen														// adaptez le nom de poids_moyen

keep region zae milieu milieu2 zaemil codpr unite poids
compress
order region zae milieu milieu2 zaemil codpr unite poids
sort  region zae milieu milieu2 zaemil codpr unite
save "$dataout_nsu/ehcvm_nsu_brut_CIV2018.dta", replace


preserve
  collapse (median) poids, by(region milieu codpr unite)
  sort region codpr unite
  save "$dataout_nsu/ehcvm_nsu_regmil_CIV2018.dta", replace /* niveau region */
restore

preserve
  collapse (median) poids, by(zae milieu codpr unite)
  sort zae milieu codpr unite
  save "$dataout_nsu/ehcvm_nsu_zaemil_CIV2018.dta", replace /* niveau zae milieu */
restore

preserve
  collapse (median) poids, by(milieu2 codpr unite)
  sort milieu2 codpr unite
  save "$dataout_nsu/ehcvm_nsu_milieu2_CIV2018.dta", replace /* niveau milieu2 */
restore

preserve
  collapse (median) poids, by(milieu codpr unite)
  sort milieu codpr unite
  save "$dataout_nsu/ehcvm_nsu_milieu_CIV2018.dta", replace /* niveau milieu */
restore

preserve
  collapse (median) poids, by(region codpr unite)
  sort region codpr unite
  save "$dataout_nsu/ehcvm_nsu_region_CIV2018.dta", replace /* niveau region */
restore

preserve
  collapse (median) poids, by(zae codpr unite)
  sort zae codpr unite
  save "$dataout_nsu/ehcvm_nsu_zae_CIV2018.dta", replace /* niveau Zone agroecologique */
restore

preserve
  collapse (median) poids, by(codpr unite)
  sort codpr unite
  save "$dataout_nsu/ehcvm_nsu_nat_CIV2018.dta", replace /* niveau national */
restore


************************************************
/* Creation de fichiers des prix unitaires, a differents niveaux administratifs */
// Mean and median values calculated if minimum number of observations (30)
// for national, mean and median calculated using any number of obs. to have...
// ... a complete set of unit values. 
*****************************************************
*/

use "$datain_men\s07b_me_CIV2018.dta", clear

// Merge info from s00
monprog_merge_s00		

tab1 s07bq07* if s07bq06>=4
keep if s07bq06 <=3											// produit acheter il y a moins de 30 jours

rename s07bq01 codpr
*merge m:1 vague grappe menage using "$data1/s00_me_CIV2018_19.dta", keepusing(s00q00 s00q01 s00q02 s00q03 s00q04 s00q08 s00q23a s00q27) /*nogen*/
*

// Création de zaemil														
monprog_def_zaemil															   

*Creation de unité 
gen 		unite	=	s07bq07b*10+s07bq07c  
label var 	unite "s07bq07b*10 + s07bq07c"


do "$prog\codpr_label.do"
label val codpr codprl
do "$prog\format_unite.do"
label val unite unite

*Unit value
gen vu = s07bq08/s07bq07a
label var vu "Valeurs unité"
	

*Pour les valeurs aberrantes
/*
egen vu_low=pctile(vu), p(25) by(zaemil vague codpr unite)
egen vu_upp=pctile(vu), p(75) by(zaemil vague codpr unite)
egen piqr=iqr(vu), by(zaemil vague codpr unite)
gen vumin=vu_low-(1.5*piqr)							
gen vumax=vu_upp+(1.5*piqr)
*/
egen vumin=pctile(vu), p(3) by(zaemil vague codpr unite)
egen vumax=pctile(vu), p(97) by(zaemil vague codpr unite)

gen flag1 = vu<vumin
gen flag2 = vu>vumax

tab codpr flag1 , row nof
tab codpr flag2 , row nof


replace vu=vumin if flag1==1
replace vu=vumax if flag2==1


********************************************************************************

scalar min_obs = 10

*Au niveau zae milieu vague
egen n_zmv =count(vu), by(zaemil vague codpr unite)
bysort vague zaemil codpr unite: egen vuam_med  = median(vu) if n_zmv >= min_obs
bysort vague zaemil codpr unite: egen vuam_mean = mean(vu)   if n_zmv >= min_obs

preserve
collapse (mean) vuam_med vuam_mean n_zmv, by(zaemil zae milieu milieu2 vague codpr unite)
save "$dataout_p/ehcvm_pu_zaemil_CIV2018_unit.dta", replace
restore


*Au niveau zae vague
egen n_zv =count(vu), by(zae vague codpr unite)
bysort zae vague codpr unite: egen vua_med  = median(vu) if n_zv >= min_obs
bysort zae vague codpr unite: egen vua_mean = mean(vu)   if n_zv >= min_obs

preserve
collapse (mean) vua_med vua_mean n_zv, by(zae vague codpr unite)
save "$dataout_p/ehcvm_pu_zae_CIV2018_unit.dta", replace
restore

*Au niveau milieu vague
egen n_mv =count(vu), by(milieu vague codpr unite)
bysort milieu vague codpr unite: egen vunm_med = median(vu) if n_mv >= min_obs
bysort milieu vague codpr unite: egen vunm_mean = mean(vu)  if n_mv >= min_obs

preserve
collapse (mean) vunm_med vunm_mean n_mv, by(milieu vague codpr unite)
save "$dataout_p/ehcvm_pu_milieu_CIV2018_unit.dta", replace
restore

*Au niveau milieu2 vague
egen n_mv2 =count(vu), by(milieu2 vague codpr unite)
bysort milieu2 vague codpr unite: egen vunm_med2 = median(vu) if n_mv2 >= min_obs
bysort milieu2 vague codpr unite: egen vunm_mean2 = mean(vu)  if n_mv2 >= min_obs

preserve
collapse (mean) vunm_med2 vunm_mean2 n_mv2, by(milieu2 vague codpr unite)
save "$dataout_p/ehcvm_pu_milieu2_CIV2018_unit.dta", replace
restore

*Au niveau vague
egen n_vag =count(vu), by(vague codpr unite)
bysort vague codpr unite: egen vun_med  = median(vu) if n_vag >= min_obs
bysort vague codpr unite: egen vun_mean = mean(vu) 	 if n_vag >= min_obs


preserve
collapse (mean) vun_med vun_mean n_vag, by(vague codpr unite)
save "$dataout_p/ehcvm_pu_nat_CIV2018_unit.dta", replace
restore


*Au niveau milieu2 pas de vague
egen n_m2 =count(vu), by(milieu2 codpr unite)
bysort milieu2 codpr unite: egen vum2_med  = median(vu) if n_m2 >= min_obs
bysort milieu2 codpr unite: egen vum2_mean = mean(vu) 	 if n_m2 >= min_obs

preserve
collapse (mean) vum2_med vum2_mean n_m2, by(milieu2 codpr unite)
save "$dataout_p/ehcvm_pu_m2_CIV2018_unit.dta", replace
restore


*Au niveau milieu pas de vague
egen n_m =count(vu), by(milieu codpr unite)
bysort milieu codpr unite: egen vum_med  = median(vu) if n_m >= min_obs
bysort milieu codpr unite: egen vum_mean = mean(vu) 	 if n_m >= min_obs

preserve
collapse (mean) vum_med vum_mean n_m, by(milieu codpr unite)
save "$dataout_p/ehcvm_pu_m_CIV2018_unit.dta", replace
restore


*Au niveau national
egen n_nat =count(vu), by(codpr unite)
bysort codpr unite: egen vunag_med = median(vu) if n_nat >= min_obs
bysort codpr unite: egen vunag_mean = mean(vu) if n_nat >= min_obs
bysort codpr unite: egen vunag_med_any = median(vu)
bysort codpr unite: egen vunag_mean_any = mean(vu)
replace vunag_med = vunag_med_any if vunag_med==. 
replace vunag_mean = vunag_mean_any if vunag_mean==. 

preserve
collapse (mean) vunag_med vunag_mean n_nat, by(codpr unite)
save "$dataout_p/ehcvm_pu_nat_ag_CIV2018_unit.dta", replace
restore

********************************************************************************
** Mode 
** this produces unit values for only the mode of unite for each product 
** Use the output data files (*_mode) for poverty food basket valuation 

************
* Determination des unites modales par produit au niveau national
preserve
numlabel, add
bysort codpr: egen unit_nat_ag = mode(unite), maxmode
label  val unit_nat_ag unite
keep if unite == unit_nat_ag
gen one=1
collapse one, by(codpr unite unit_nat_ag) 
drop one
tempfile tf_mode
save `tf_mode'
save "$dataout_p/mode_nat_ag_max.dta", replace
restore

preserve
numlabel, add
bysort vague codpr: egen unit_nat = mode(unite), maxmode
label  val unit_nat unite
keep if unite == unit_nat
gen one=1
collapse one, by(vague codpr unite unit_nat) 
drop one
save "$dataout_p/mode_nat_max.dta", replace
restore

************
* Determination des unites modales par produit et par zone : zaemil zae milieu milieu2
foreach i in zae /*zaemil milieu milieu2 */{
preserve
numlabel, add
bysort `i' vague codpr: egen unit_`i' = mode(unite), maxmode
label  val unit_`i' unite
keep if unite == unit_`i'

gen one=1
collapse one, by(codpr `i' vague unit_`i' unite) 
drop one
save "$dataout_p/mode_`i'_vague_max.dta", replace
restore
}

* Determination des unites modales par produit et par zaemil et par vague
**********************************

preserve
numlabel, add

bysort zaemil vague codpr: egen unit_zaemil = mode(unite), maxmode

label  		val unit_zaemil unite
keep if 	unite == unit_zaemil

gen one=1
collapse one, by(codpr unite vague zaemil unit_zaemil) 
drop one
*reshape wide unit_zaemil, i(codpr unite vague) j(zaemil)
save "$dataout_p/mode_zaemil_vague_max.dta", replace
restore

* Determination des unites modales par produit et par milieu2 et par vague
**********************************

preserve
numlabel, add

bysort milieu2 vague codpr: egen unit_milieu2 = mode(unite), maxmode

label  		val unit_milieu2 unite
keep if 	unite == unit_milieu2

gen one=1
collapse one, by(codpr unite vague milieu2 unit_milieu2) 
drop one
*reshape wide unit_zaemil, i(codpr unite vague) j(zaemil)
save "$dataout_p/mode_milieu2_vague_max.dta", replace
restore

* Determination des unites modales par produit et par milieu et par vague
**********************************

preserve
numlabel, add

bysort milieu vague codpr: egen unit_milieu = mode(unite), maxmode

label  		val unit_milieu unite
keep if 	unite == unit_milieu

gen one=1
collapse one, by(codpr unite vague milieu unit_milieu) 
drop one
*reshape wide unit_zaemil, i(codpr unite vague) j(zaemil)
save "$dataout_p/mode_milieu_vague_max.dta", replace
restore

********************************************************************************
// we merge in unitvalues to complete list of zaemil and codpr (for mode unit only)

use "$dataout_p/ehcvm_pu_zaemil_CIV2018_unit.dta", clear
sort codpr unite
merge 1:1 codpr unite zaemil vague  using "$dataout_p/mode_zaemil_vague_max.dta"

tab _m
keep if _m==3 

drop if codpr ==.
drop _merge
save "$dataout_p/ehcvm_pu_zaemil_CIV2018_mode.dta", replace				// Ok Ok 


foreach i in zae milieu milieu2 { 
                use "$dataout_p/ehcvm_pu_`i'_CIV2018_unit.dta", clear
				sort codpr `i' unite
				merge 1:1 codpr unite `i' vague using  "$dataout_p/mode_`i'_vague_max.dta" 
				tab _m
				keep if _m==3
				drop _m
                save "$dataout_p/ehcvm_pu_`i'_CIV2018_mode.dta", replace
}				

* national and by vague
***************************

use "$dataout_p/ehcvm_pu_nat_CIV2018_unit.dta", clear
				sort vague codpr  unite
				merge m:1 vague codpr unite using  "$dataout_p/mode_nat_max.dta" 
				tab _m
				keep if _m==3
				drop _m
                save "$dataout_p/ehcvm_pu_nat_CIV2018_mode.dta", replace
* national
**********************
use "$dataout_p/ehcvm_pu_nat_ag_CIV2018_unit.dta", clear
				sort codpr  unite
				merge m:1 codpr unite using  "$dataout_p/mode_nat_ag_max.dta" 
				tab _m
				keep if _m==3
				drop _m
                save "$dataout_p/ehcvm_pu_nat_ag_CIV2018_mode.dta", replace


** Due to missing at zaemil vague, will impute using unit values from higher levels of aggregation

use "$dataout_p/ehcvm_pu_zaemil_CIV2018_mode.dta", clear
gen vu_med 		= vuam_med
gen vu_mean 	= vuam_mean

drop vuam_med vuam_mean 		//////////////////////////////////////////////////////////////////

gen vu_source 	= 1 if vu_med != .
gen vu_nobs 	= n_zmv if vu_source==1


sort zae vague codpr unite
merge m:1 zae vague codpr unite using "$dataout_p\ehcvm_pu_zae_CIV2018_mode.dta"
drop if _merge==2
drop _merge 
replace vu_source = 2 if vu_med ==. & vua_med !=.
replace vu_nobs = n_zv if vu_source==2

replace vu_med  = vua_med   if vu_med ==. & vua_med != . 
replace vu_mean = vua_mean  if vu_mean ==. & vua_mean != . 

sort milieu2 vague codpr unite
merge m:1 milieu2 vague codpr unite using "$dataout_p\ehcvm_pu_milieu2_CIV2018_mode.dta"
drop if _merge==2
drop _merge 
replace vu_source = 3 if vu_med ==. & vunm_med2 !=.
replace vu_nobs = n_mv2 if vu_source==3

replace vu_med  = vunm_med2  if vu_med ==.  & vunm_med2 != . 
replace vu_mean = vunm_mean2 if vu_mean ==. & vunm_mean2 != .

// skipped imputation using milieu unit values; can undo if desired

sort milieu vague codpr unite
merge m:1 milieu vague codpr unite using "$dataout_p\ehcvm_pu_milieu_CIV2018_mode.dta"
drop if _merge==2
drop _merge 
replace vu_source = 6 if vu_med ==. & vunm_med !=.
replace vu_nobs = n_mv if vu_source==6

replace vu_med  = vunm_med  if vu_med ==.  & vunm_med != . 
replace vu_mean = vunm_mean if vu_mean ==. & vunm_mean != .


sort vague codpr unite
merge m:1 vague codpr unite using "$dataout_p\ehcvm_pu_nat_CIV2018_mode.dta"
drop if _merge==2
drop _merge 
replace vu_source = 4 if vu_med ==. & vun_med !=.
replace vu_nobs = n_vag if vu_source==4

replace vu_med  = vun_med  if vu_med ==.  & vun_med != . 
replace vu_mean = vun_mean if vu_mean ==. & vun_mean != .

sort codpr unite
merge m:1 codpr unite using "$dataout_p\ehcvm_pu_nat_ag_CIV2018_mode.dta"
drop if _merge==2
drop _merge 
replace vu_source = 5 if vu_med ==. & vunag_med !=.
replace vu_nobs = n_nat if vu_source==5

replace vu_med  = vunag_med  if vu_med ==.  & vunag_med != . 
replace vu_mean = vunag_mean if vu_mean ==. & vunag_mean != .

label def vu_source 1 "zae milieu vague" ///
					2 "zae vague" ///
					3 "milieu2 vague" ///
					6 "milieu vague" ///
					4 "vague" ///
					5 "national ag" , replace
label val vu_source vu_source
label  		val unite unite
keep codpr unite vague zaemil zae milieu milieu2 vu_mean vu_med vu_source vu_nobs
order codpr unite vague zaemil zae milieu milieu2 vu_mean vu_med vu_source vu_nobs

drop if vu_nobs ==.
save "$dataout_p\ehcvm_pu_merge_CIV2018_mode.dta", replace

********************************************************************************

use "$datain_men/s07b_me_CIV2018.dta", clear

monprog_merge_s00
drop if s07bq03a==.

rename s07bq01 codpr

monprog_def_zaemil															    // Creation de zaemil

*Creation de unité 
gen unite=s07bq03b*10+s07bq03c  
label var unite "s07bq03b*10 + s07bq03c"														

do "$prog\codpr_label.do"													// Labelisation de codpr
label val codpr codprl
do "$prog\format_unite.do"													// Labelisation de unite
label val unite unite

tempfile tf_7b
save `tf_7b'
keep codpr unite zaemil zae milieu vague
duplicates drop
count

merge 1:1 codpr unite zae milieu zaemil vague using "$dataout_p/ehcvm_pu_zaemil_CIV2018_unit.dta"
rename _merge _merge_zaemil
gen vu_med = vuam_med
gen vu_mean = vuam_mean
gen vu_source = 1 if vu_med != .
gen vu_nobs = n_zmv if vu_source==1


merge m:1 codpr unite zae vague using "$dataout_p/ehcvm_pu_zae_CIV2018_unit.dta"
rename _merge _merge_zae
replace vu_source = 2 if vu_med ==. & vua_med !=.
replace vu_nobs = n_zv if vu_source==2
replace vu_med = vua_med if vu_med ==. & vua_med != . 
replace vu_mean = vua_mean if vu_mean ==. & vua_mean != . 

// skipped imputation using milieu unit values; can undo if desired
/*
merge m:1 codpr unite milieu vague using "$data4/ehcvm_pu_milieu_CIV2018_unit.dta"
rename _merge _merge_milieu
replace vu_source = 3 if vu_med ==. & vunm_med !=.
replace vu_nobs = n_mv if vu_source==3
replace vu_med = vunm_med if vu_med ==. & vunm_med != . 
replace vu_mean = vunm_mean if vu_mean ==. & vunm_mean != 
*/

merge m:1 codpr unite vague using "$dataout_p/ehcvm_pu_nat_CIV2018_unit.dta"
rename _merge _merge_nat
replace vu_source = 4 if vu_med ==. & vun_med !=.
replace vu_nobs = n_vag if vu_source==4
replace vu_med = vun_med if vu_med ==. & vun_med != . 
replace vu_mean = vun_mean if vu_mean ==. & vun_mean != .


merge m:1 codpr unite using "$dataout_p/ehcvm_pu_nat_ag_CIV2018_unit.dta"
rename _merge _merge_nat_ag
replace vu_source = 5 if vu_med ==. & vunag_med !=.
replace vu_nobs = n_nat if vu_source==5
replace vu_med = vunag_med if vu_med ==. & vunag_med != . 
replace vu_mean = vunag_mean if vu_mean ==. & vunag_mean != .

label def vu_source 1 "zae milieu vague" ///
					2 "zae vague" ///
					3 "milieu vague" ///
					4 "vague" ///
					5 "national ag" , replace
label val vu_source vu_source

keep codpr unite vague zaemil zae milieu vu_mean vu_med vu_source vu_nobs
order codpr unite vague zaemil zae milieu vu_mean vu_med vu_source vu_nobs
sort vague zae milieu codpr unite
save "$dataout_p/ehcvm_pu_merge_CIV2018_unit.dta", replace

// this is to identify number of observations that cannot be valued
use `tf_7b', clear
merge m:1 codpr unite zaemil zae milieu vague using "$dataout_p/ehcvm_pu_merge_CIV2018_unit.dta"
count if vu_mean ==.





