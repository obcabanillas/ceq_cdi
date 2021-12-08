*******************************************************************************
*       Enquete harmonisee sur les conditions de vie des menages - UEMOA      *
*                          Analyse de la pauvrete                             *
* Ce programme utilise les resultats du programme precedent pour faire 4      *
* choses : i) contruire un seuil de pauvrete national; ii) calculer les       *
* seuils par zoneagroecologique qui sont utilises comme deflateur;            * 
* iii) finaliser la construction de l'agregat de bien-etre; iv) creer le      *
* pour l'analyse du bien-etre.                                                *
*******************************************************************************

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

global prog "$data\Programs"

cap log close         
log using "$prog\ehcvm2018_civ_pgm03.log", replace text    
*/


* C:\Users\wb324658\OneDrive - WBG\FY18\CI\HDataCIV\Data_CIV\EHCVM032020\CIV\Datain\Menage
* C:\Users\wb324658\OneDrive - WBG\FY18\CI\HDataCIV\Data_CIV\EHCVM032020\CIV\Datain\Commune
* C:\Users\wb324658\OneDrive - WBG\FY18\CI\HDataCIV\Data_CIV\EHCVM032020\CIV\Datain\Auxiliaire

global data "C:\Users\wb324658\OneDrive - WBG\FY18\CI\HDataCIV\Data_CIV\EHCVM-DATA-TRAITEES-24Janvier2020\CIV"
global datain_men "$data\MEN-PRIX(Datain)"
global datain_aux "$data\MEN-PRIX(Datain)\parametre"

global dataout "$data\Dataout"
global dataout_p "$data\Dataout\dataout_p"
global dataout_nsu "$data\Dataout\dataout_nsu" 
global dataout_temp "$data\Dataout\dataout_temp"  


/*
global data "C:\Users\wb324658\OneDrive - WBG\FY18\CI\HDataCIV\Data_CIV\EHCVM-DATA-TRAITEES-24Janvier2020\CIV"
global datain_men "$data\MEN-PRIX(Datain)"
global datain_aux "$data\MEN-PRIX(Datain)\parametre"
*/


global programs "$data\Programs"
global logs "$programs\logs"

cap log close         

log using "$logs\ehcvm_CIV2018_19_19_pgm03.log", replace text   

***********
*********** Partie 1: Seuil de pauvrete alimentaire ****************************
***********

***** Variables niveau menage, pour la suite des travaux *********************** 

local d_min =3
local d_max =7
local pas =0.05
local NKcal = 2300
local basket = 91

use "$dataout\ehcvm_individu_CIV2018.dta", clear
keep if resid==1   /*  membres du menage   */

gen eqadu1=0.255 if age<1
replace eqadu1=0.450 if age>=1 & age<=3
replace eqadu1=0.620 if age>=4 & age<=6
replace eqadu1=0.690 if age>=7 & age<=10

replace eqadu1=0.860 if age>=11 & age<=14 & sexe==1
replace eqadu1=1.030 if age>=15 & age<=18 & sexe==1
replace eqadu1=1.000 if age>=19 & age<=50 & sexe==1
replace eqadu1=0.790 if age>=51 & sexe==1

replace eqadu1=0.760 if age>=11 & age<=50 & sexe==2
replace eqadu1=0.660 if age>=51 & sexe==2

gen adlt=age>=18
gen enft=age<=17

*Creation de zae
egen zaemil=group(zae milieu)
tab zaemil zae
label def zaemil 1 "CENTRE (urbain)" 2 "CENTRE (rural)" ///
				 3 "CENTRE-OUEST (urbain)" 4 "CENTRE-OUEST (rural)" ///
				 5 "NORD (urbain)" 6 "NORD (rural)" ///
				 7 "SUD-EST (urbain)" 8 "SUD-EST (rural)" ///
				 9 "SUD-OUEST (urbain)" 10 "SUD-OUEST (rural)" ///
				 11 "ABIDJAN", replace
label val zaemil zaemil

collapse (count) hhsize=numind (sum) eqadu1 adlt enft ///
         (first) grappe menage vague zae region milieu zaemil hhweight em, by(hhid)

gen flag=adlt==0
replace adlt=1 if flag==1
replace enft=enft-1 if flag==1
drop flag

gen eqadu2=(1+(0.7*(adlt-1))+(0.5*enft))^0.9

sum
order hhid grappe menage zaemil zae region milieu hhweight hhsize eqadu1 eqadu2 em
sort hhid 
save "$dataout_temp\ehcvm_men_temp.dta", replace
*
*
use "$dataout\ehcvm_conso_CIV2018.dta", clear
drop 	if codpr>=152 & codpr<=164 /* Produits inclus pour tests */
merge m:1 hhid using "$dataout_temp\ehcvm_men_temp.dta", keepusing(em)
drop _merge

gen def_temp=1.001620183 if em==4
replace def_temp=1.005483714 if em==5
replace def_temp=1.011279009 if inlist(em, 6, 7)
replace def_temp=0.996474946 if inlist(em, 9, 10)
replace def_temp=0.996834666 if em==11
replace def_temp=0.998901052 if em==12

replace depan=depan/def_temp


preserve
  gen co_ali=(codpr>=1 & codpr<=136) | (codpr>=139 & codpr<=151)
  lab def co_ali_l 0"Code depenses non-alim." 1"Code depenses alim." 
  lab val co_ali co_ali_l 
  gen dali=depan if co_ali==1 
  gen dnal=depan if co_ali==0
  recode dali dnal (.=0)
  collapse (sum) dali dnal (first) def_temp, by(hhid)
  merge 1:1 hhid using "$dataout_temp\ehcvm_men_temp.dta"
  drop _merge
  gen dtot=dali+dnal
  gen dtet=dtot/hhsize
  gen dalit=dali/hhsize
  gen dnalt=dnal/hhsize
  sum dali dnal dtot dalit dnalt dtet
  *
  xtile ndtet=dtet [pw=hhweight*hhsize], nq(10)
  forval i = 1/11 {
    xtile ndtet`i'=dtet [pw=hhweight*hhsize] if zaemil==`i', nq(10)
  }
  *
  gen ndtets=ndtet1 if zaemil==1  
  forval i=2/11 {  
    replace ndtets=ndtet`i' if zaemil==`i'
	}
  drop ndtet1 ndtet2 ndtet3 ndtet4 ndtet5 ndtet6 ndtet7 ndtet8 ndtet9 ndtet10 ndtet11
   save "$dataout_temp\ehcvm_men_temp.dta", replace
restore
*
***** Panier de consommation pour le seuil de pauvrete ************************* 

gen flag=(codpr==60 | codpr==67 |codpr==127 | codpr==128 | codpr==132 | codpr==134 | codpr==136 | codpr==151) /* On n'a pas de calories */

keep if ((codpr>=1 & codpr<=136) | (codpr>=139 & codpr<=151)) & (flag==0)
merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta"
keep if _merge==3
drop _merge
*
preserve /* panier au niveau national */
  keep if (ndtet>=`d_min' & ndtet<=`d_max') /* exclusion des extremes pour le panier */
  collapse (sum) depant=depan [pw=hhweight], by(codpr)
  egen depan_tot=sum(depant)
  gsort -depant
  gen cobu=depant*100/depan_tot
  gen cobuc=cobu if _n==1
  replace cobuc=cobuc[_n-1]+cobu if _n>1
  keep if cobuc<`basket'  /* On garde les items faisant 85% de la conso totale */
  keep codpr depant depan_tot 
  compress
  sort codpr
  save "$dataout_temp\ehcvm_panier_nat.dta", replace
restore

**===============================

  forval i=1/11 {  
  preserve /* /* panier pour chaque zaemil */ */
    keep if zaemil==`i'

  keep if (ndtet>=`d_min' & ndtet<=`d_max') /* exclusion des extremes pour le panier */
  collapse (sum) depant=depan [pw=hhweight], by(codpr)
  egen depan_tot=sum(depant)
  gsort -depant
  gen cobu=depant*100/depan_tot
  gen cobuc=cobu if _n==1
  replace cobuc=cobuc[_n-1]+cobu if _n>1
  keep if cobuc<`basket'  /* On garde les items faisant 85% de la conso totale */
  keep codpr depant depan_tot 
  compress
  sort codpr
  save "$dataout_temp\ehcvm_panier_zaemil`i'.dta", replace
  restore
	}


preserve /* regroupe de tous les produits de tous les paniers zaemil et national*/
   
use "$dataout_temp\ehcvm_panier_zaemil1.dta", clear
gen zaemil =1
	 forval i=2/11 { 
 append using "$dataout_temp\ehcvm_panier_zaemil`i'.dta"
 replace zaemil =`i' if zaemil ==.
  
	}
save "$dataout_temp\ehcvm_panier_Allzaemil.dta", replace

 append using "$dataout_temp\ehcvm_panier_nat.dta"
 replace zaemil =0 if zaemil ==.

gen InBasket = 1
collapse (sum) InBasket, by(codpr zaemil)
reshape wide InBasket, i(codpr) j(zaemil)

save "$dataout_temp\ehcvm_panier_All.dta", replace
restore


* test 
preserve /* paniers des zae/milieu pour vérifier cohérence national */
  merge m:1 codpr using "$dataout_temp\ehcvm_panier_nat.dta"
  egen depantt=sum(depan*hhweight)  if (ndtets>=`d_min' & ndtets<=`d_max'), by(zaemil)
  egen depantts=sum(depan*hhweight) if (ndtets>=`d_min' & ndtets<=`d_max') & _merge==3, by(zaemil)
  gen eval=depantts/depantt
  drop if eval==.   /* uniquement ???? ménages concerne soit ???% de l'échantillon */
  sort zaemil
  collapse (first) eval, by(zaemil)
  tabstat eval, by(zaemil)
  sort zaemil
  save "$dataout_temp\ehcvm_test_panier_zaemil.dta", replace
restore

merge m:1 codpr using "$dataout_temp\ehcvm_panier_nat.dta"
gen ind_pan=_merge==3
drop _merge
merge m:1 zaemil using "$dataout_temp\ehcvm_test_panier_zaemil.dta"   // tab eval zaemil : le panier represente 80 % a Abidjan et au moins 85% ailleurs
drop _merge

*  
*
******************** Population de référence pour le seuil *********************

use "$dataout_temp\ehcvm_men_temp.dta", clear  /* Population decile 2 a 7 */
gen all=inrange(ndtet,`d_min',`d_max')
collapse (sum) popul28=hhsize [pw=hhweight], by(all)
compress
save "$dataout_temp\ehcvm_popul_dec28.dta", replace
*
*
******** Prix en kilogramme avec conversion des unités non standards ***********
*
use "$dataout_p\ehcvm_pu_merge_CIV2018_mode.dta", clear
 
/* Creation de milieu2
gen     milieu2 = (zae==6 & milieu==1)
replace milieu2 = 2 if milieu==1 & milieu2 ==0
replace milieu2 = 3 if milieu==2 & milieu2 ==0
label define milieu2 1 "Abidjan urbain" 2 "Autre urbain" 3 "Rural" 
label values milieu2 milieu2
*/

sort zae milieu codpr unite
merge m:1 codpr milieu unite zae using "$dataout_nsu\ehcvm_nsu_zaemil_CIV2018.dta", keepusing(poids) 
tab vague if poids==.
drop if _merge ==2
drop _merge

merge m:1 codpr milieu2 unite using "$dataout_nsu\ehcvm_nsu_milieu2_CIV2018.dta", keepusing(poids) update
tab vague if poids==.
drop if _merge ==2
drop _merge

merge m:1 codpr milieu unite using "$dataout_nsu\ehcvm_nsu_milieu_CIV2018.dta", keepusing(poids) update
tab vague if poids==.
drop if _merge ==2
drop _merge

sort codpr unite
merge m:1 codpr unite using "$dataout_nsu\ehcvm_nsu_nat_CIV2018.dta", keepusing(poids) update
tab vague if poids==.
drop if _merge ==2
drop _merge

drop if poids==.

replace vu_med=(vu_med*1000 )/poids if unite!=1000
replace vu_mean=(vu_mean*1000 )/poids if unite!=1000 

collapse (mean) vuam_med=vu_med vuam_mean=vu_mean, by(zae milieu codpr)

save "$dataout_p\ehcvm_pu_zaemil_CIV2018_bbb.dta", replace /* Prix niveau ZAE/Milieu */

collapse (mean) vunag_med=vuam_med vunag_mean=vuam_mean, by(codpr)

save "$dataout_p\ehcvm_pu_nat_ag_CIV2018_mode_bbb.dta", replace /* Prix niveau national */


*********************  Calcul de la conso en calories **************************

use "$dataout_temp\ehcvm_panier_nat.dta", clear  /* Partir du panier de conso */

gen all=1
merge m:1 all using "$dataout_temp\ehcvm_popul_dec28.dta"
keep if _merge==3
drop _merge

sort codpr
merge 1:1 codpr using "$dataout_p\ehcvm_pu_nat_ag_CIV2018_mode_bbb.dta"
keep if _merge==3
drop _merge

sort codpr
merge 1:1 codpr using "$datain_aux\calorie_conversion_WA.dta"
keep if _merge==3
drop _merge 

gen pmn = vunag_mean 
* Conso par tete, par bien et par jour 
gen conso_pc_val=depant/(popul*365)
gen conso_pc_qte=conso_pc_val*10/pmn
gen conso_pc_ener=conso_pc_qte*(1-(refuse/100))*cal   

* Conso par tete, par jour, pour tous les biens, on scale-up pour avoir 2400 kcal  
egen conso_pc_ener_tot=sum(conso_pc_ener)
gen conso_pc_ener_up=conso_pc_ener* `NKcal' /conso_pc_ener_tot
gen conso_pc_qte_up=conso_pc_qte* `NKcal' /conso_pc_ener_tot

*** Comme infos a mettre dans un tableau, il faut retenir : 

tabstat cal conso_pc_qte conso_pc_ener conso_pc_qte_up conso_pc_ener_up, by(codpr) stat(sum)  

recode conso_pc_qte (.=0)
drop if conso_pc_qte==0

keep codpr cal conso_pc_qte conso_pc_ener conso_pc_qte_up conso_pc_ener_up 
order codpr cal conso_pc_qte conso_pc_ener conso_pc_qte_up conso_pc_ener_up 
sort codpr 
save "$dataout_temp\elt_seuil_alim.dta", replace
*
****************** Calcul Seuil alimentaire, national **************************
*
use "$dataout_p\ehcvm_pu_nat_ag_CIV2018_mode_bbb.dta", clear 

clonevar pmn=vunag_mean 

sort codpr
merge m:1 codpr using "$dataout_temp\elt_seuil_alim.dta"
keep if _merge==3
drop _merge

gen conso_pc_val_up=conso_pc_qte_up*pmn*365/10
gen all=1
collapse (sum) zali0=conso_pc_val_up, by(all)
save "$dataout_temp\seuil_nat.dta", replace
*
****************** Calcul Seuil alimentaire, zae/milieu ************************
*
use "$dataout_p\ehcvm_pu_zaemil_CIV2018_bbb.dta", clear 

clonevar pmam=vuam_mean

sort codpr
merge m:1 codpr using "$dataout_temp\elt_seuil_alim.dta"
keep if _merge==3
drop _merge

egen zaemil=group(zae milieu)
tab zaemil zae
label val zaemil zaemil

gen conso_pc_val_up=conso_pc_qte_up*pmam*365/10
sort zaemil
collapse (sum) zali=conso_pc_val_up, by(zaemil)
sort zaemil
save "$dataout_temp\seuil_zaemil.dta", replace

***********
*********** Partie 2: Seuil de pauvrete non-alimentaire ************************
***********

*** verifier population de reference meme chose, deciles 2 a 7 pour seuil non-alimentaire 

*********** Seuil au niveau national 
use "$dataout_temp\ehcvm_men_temp.dta", clear 

drop ndtet
gen all=1
merge m:1 all using "$dataout_temp\seuil_nat.dta"
drop _merge

gen dmin=(1-`pas')*zali0
gen dmax=(1+`pas')*zali0

tab zaemil if dtet>=dmin & dtet<=dmax
tab zaemil if dalit>=dmin & dalit<=dmax

gen alpha=dalit/dtet

preserve
  collapse (mean) alpha0_min=alpha if (dtet>=dmin & dtet<=dmax) [pw=hhweight*dtet], by(all)
  save "$dataout_temp\zmin0.dta", replace  
restore

preserve 
  collapse (mean) alpha0_max=alpha if (dalit>=dmin & dalit<=dmax) [pw=hhweight*dtet], by(all)
  save "$dataout_temp\zmax0.dta", replace  
restore

use "$dataout_temp\seuil_nat.dta", clear
merge 1:1 all using "$dataout_temp\zmin0.dta"
drop _merge
merge 1:1 all using "$dataout_temp\zmax0.dta"
drop _merge
save "$dataout_temp\seuil_nat.dta", replace

*********** Seuil au niveau des zae/milieu 
use "$dataout_temp\ehcvm_men_temp.dta", clear 

drop ndtet
sort zaemil
merge m:1 zaemil using "$dataout_temp\seuil_zaemil.dta"
drop _merge

gen dmin=(1-`pas')*zali
gen dmax=(1+`pas')*zali

tab zaemil if dtet>=dmin & dtet<=dmax
tab zaemil if dalit>=dmin & dalit<=dmax

gen alpha=dalit/dtet

preserve
  collapse (mean) alpha_min=alpha if dtet>=dmin & dtet<=dmax [pw=hhweight*dtet], by(zaemil)
  save "$dataout_temp\zmin1.dta", replace  
restore

preserve 
  collapse (mean) alpha_max=alpha if dalit>=dmin & dalit<=dmax [pw=hhweight*dtet], by(zaemil)
  save "$dataout_temp\zmax1.dta", replace  
restore

use "$dataout_temp\seuil_zaemil.dta", clear

merge m:1 zaemil using "$dataout_temp\zmin1.dta"
drop _merge
merge m:1 zaemil using "$dataout_temp\zmax1.dta"
drop _merge
gen all=1
merge m:1 all using "$dataout_temp\seuil_nat.dta"
drop _merge
save "$dataout_temp\seuil_all.dta", replace

***********
*********** Partie 3: Fichier pour travaux analyses pauvrete *******************
***********

use "$dataout\ehcvm_individu_CIV2018.dta", clear

keep if lien==1
keep sexe age mstat religion nation ethnie alfab educ_hi diplome handig activ7j /// 
     activ12m branch sectins csp country year hhid grappe menage zae region milieu vague 

rename (sexe age mstat religion nation ethnie alfab educ_hi diplome handig ///
        activ7j activ12m branch sectins csp) ///
	   (hgender hage hmstat hreligion hnation hethnie halfab heduc hdiploma hhandig ///
	    hactiv7j hactiv12m hbranch hsectins hcsp)
	   
merge 1:1 hhid using "$dataout_temp\ehcvm_men_temp.dta"
drop _merge

merge m:1 zaemil using "$dataout_temp\seuil_all.dta"
drop _merge


gen zref=zali0*(2-alpha0_min)
*gen zref=((zali0*(2-alpha0_min))+(zali0/alpha0_max))/2
gen zzae=zali*(2-alpha_min)
*gen zzae=((zali*(2-alpha_min))+(zali/alpha_max))/2
gen def_spa=zzae/zref

gen pcexp=dtet/def_spa

* Foood poverty analysis
*gen def_spa_alim=zali/zali0
*gen pcexp_def_alim =dtet/def_spa_alim

* Creation de milieu2
gen     milieu2 = (region==1 & milieu==1)
replace milieu2 = 2 if milieu==1 & milieu2 ==0
replace milieu2 = 3 if milieu==2 & milieu2 ==0
label define milieu2 1 "Abidjan urbain" 2 "Autre urbain" 3 "Rural" 
label values milieu2 milieu2

* decile
xtile  decile  = pcexp [aw=hhweight*hhsize], nq(10)
xtile quintile = pcexp [aw=hhweight*hhsize], nq(5)

*gen  zali = zali0

keep country year hhid grappe menage vague zae region milieu milieu2 hhweight hhsize eqadu1 eqadu2 ///
     hgender hage hmstat hreligion hnation hethnie halfab heduc hdiploma hhandig ///
	 hactiv7j hactiv12m hbranch hsectins hcsp dali dnal dtet dtot pcexp zref zali0 def_spa def_temp decile quintile

order country year hhid grappe menage vague zae region milieu milieu2 hhweight hhsize eqadu1 eqadu2 ///
     hgender hage hmstat hreligion hnation hethnie halfab heduc hdiploma hhandig ///
	 hactiv7j hactiv12m hbranch hsectins hcsp dali dnal dtot dtet pcexp zref zali0 def_spa def_temp decile quintile

lab var grappe "Numero grappe"
lab var menage "Numero menage"
lab var zae "Zone agroecologique"
lab var region "Region residence"
lab var milieu "Milieu residence"
lab var milieu2 "Abidjan, Other urban, Rural"
lab var hhweight "Ponderation menage"
lab var hhsize "Taille menage"
lab var eqadu1 "Nbr adultes-equiv. FAO"
lab var eqadu2 "Nbr adultes-equiv. alt."
lab var hgender "Genre du CM"
lab var hage "Age du CM"
lab var hmstat "Situation famille du CM"
lab var hreligion "Religion du CM"
lab var hnation "Nationalite du CM"
lab var hethnie "Ethnie du CM"
lab var halfab "Alphabetisation du CM"
lab var heduc "Education du CM"
lab var hdiploma "Diplome du CM"
lab var hhandig "Handicap majeur CM"
lab var hactiv7j "Activite 7 jours du CM"
lab var hactiv12m "Activite 12 mois du CM"
lab var hbranch "Branche activite du CM"
lab var hsectins "Secteur instit. du CM"
lab var hcsp "CSP du CM"
lab var dali "Conso annuelle alim. menage"
lab var dnal "Conso annuelle non alim. menage"
lab var dtot "Conso annuelle totale menage"
lab var zref "Seuil pauvrete national"
lab var pcexp "Indicateur de bien-être"
lab var def_spa "Deflateur spatial"
lab var def_temp "Deflateur temporel"
lab var decile "decile pcexp"
lab var quintile "quintile pcexp"
lab var zali0 "Seuil de pauvrete alimentaire national"
compress
sort hhid 
*save "$dataout\ehcvm_welfare_CIV2018.dta", replace

/********* Effacer les fichiers de travail */
/*erase "$dataout_temp\ehcvm_panier_nat.dta"
erase "$dataout_temp\ehcvm_popul_dec28.dta" 
erase "$dataout_temp\elt_seuil_alim.dta"
erase "$dataout_temp\zmin0.dta"
erase "$dataout_temp\zmax0.dta"
erase "$dataout_temp\zmin1.dta"
erase "$dataout_temp\zmax1.dta"
erase "$dataout_temp\seuil_zaemil.dta"
erase "$dataout_temp\seuil_nat.dta"
erase "$dataout_temp\seuil_all.dta"
*/

************* Calcul des indicateurs de pauvrete
gen dif=zref-pcexp
gen p0=100*(dif>0)
gen p1=(dif/zref)*p0
gen p2=((dif/zref)^2)*p0

************* Calcul des indicateurs de pauvrete alimentaire
gen difal=zali0-pcexp
gen p0al=100*(difal>0)

replace hhweight=round(hhweight)

tabstat p0al p0 p1 p2 pcexp dtet [fw=hhweight*hhsize], by(milieu)
tabstat p0al p0 p1 p2 pcexp dtet [fw=hhweight*hhsize], by(milieu2)

drop p0 p1 p2
sepov pcexp [w=hhweight*hhsize], p(zref) /* by(milieu)  by(region)*/ psu(region) strata(milieu)
ppppppppppppppppppppppppppppppppppppppp
tabstat p0al p0 p1 p2 pcexp dtet [fw=hhweight*hhsize], by(region)
tabstat p0al p0 p1 p2 pcexp dtet [fw=hhweight*hhsize], by(vague)

gen pauv=p0/100
gen ind=1

tabstat pauv ind [fw=hhweight*hhsize], s(sum) by(milieu) format(%12.0g)

egen strate=group(region milieu)
svyset grappe [pweight=hhweight], strata(strate)

*igini pcexp, hsize(hhsize) 

************* Calcul des indicateurs d'extrême pauvrete
gen ipl1=175966.3	/* 482.099452 -- 1.90*/
gen ext=ipl1-dtet
gen e0=100*(ext>0)
gen e1=(ext/ipl1)*e0
gen e2=((ext/ipl1)^2)*e0

tabstat e0 e1 e2 [fw=hhweight*hhsize], by(milieu)
tabstat e0 e1 e2 [fw=hhweight*hhsize], by(region)
drop ext

gen ipl2=296364 /*811.956164 -- 3.20*/
gen ext=ipl2-dtet
gen f0=100*(ext>0)
gen f1=(ext/ipl2)*f0
gen f2=((ext/ipl2)^2)*f0

tabstat f0 f1 f2 [fw=hhweight*hhsize], by(milieu)
tabstat f0 f1 f2 [fw=hhweight*hhsize], by(region)
drop ext

gen ipl3=481591.979 /*1319.43008 -- 5.20*/
gen ext=ipl3-dtet
gen g0=100*(ext>0)
gen g1=(ext/ipl3)*g0
gen g2=((ext/ipl3)^2)*g0

tabstat g0 g1 g2 [fw=hhweight*hhsize], by(milieu)
tabstat g0 g1 g2 [fw=hhweight*hhsize], by(region)


gen Bottom40 = (quintile==1|quintile==2)

save "$dataout\ehcvm_welfare_CIV2018.dta", replace
