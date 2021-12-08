*******************************************************************************
*       Enquete harmonisee sur les conditions de vie des menages - UEMOA      *
*                          Analyse de la pauvrete                             *
* Ce programme va creer un fichier menage/produits/mode d'acquisition         *
* Pour chaque menage, on a un enregitrement par menage/produits/acquisition   *
* Par exemple pour un menage et le mil: on a un enreg pour le mil achat,      *
* un autre mil autoconsomme , un autre pour mil cadeau. Ce fichier permet     *
*               ensuite de construire l'agregat de consommation               *
*                 Programme écrit en Janvier 2019 par Prospère Backiny Yetna  *
*                 								                              *
*******************************************************************************

clear
set more off



***********
*********** Partie 1: Consommation alimentaire - Sections 7B, 7A et 9C *********
***********

/* Pour commencer, on conserve seulement les menages valides, ceux qui sont dans    
  le fichier individuel crees precedemment par le pgm01 */

preserve
  use "$dataout\ehcvm_individu_CIV2018.dta", clear
  keep if resid==1
  collapse (count) hhsize=numind (first) grappe menage region milieu zae, by(hhid) 
  sort hhid 
  compress
  save "$dataout_temp\ehcvm_men_temp.dta", replace
restore

**** Section 7B : consommation alimentaire des 7 derniers jours
use "$datain_men\s07b_me_CIV2018.dta", clear 
destring grappe, replace
keep if s07bq02==1
drop if missing(s07bq03a) | s07bq03a==0

merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta"
keep if _merge==3
drop _merge

/* La consommation alimentaire est déclarée en quantité, et comprend les achats,
  l'autoconsommation et les cadeaux. On va traiter separement chacune de ces 
  composantes. Comme on dispose de quantites, on valorise en utilisant le prix 
  unitaire quand il y a eu achat dans le menage. S'il n'y a pas eu achat, on 
  calcule la mediane des valeurs unitaires declarees dans la grappe, ou 
  dans le milieu de residence, ou la region ou au niveau national. 
  Si les valeurs unitaires n'existent pas pour le produit, on utilise 
  les medianes des  collectees sur le marche, grappe, milieu de residence, 
  region, national, jusqu'a ce qu'on trouve l'information */
*

rename s07bq01 codpr
gen unite1=s07bq03b*10+s07bq03c  
gen unite2=s07bq07b*10+s07bq07c  

gen sit=1 if (unite1>0 & unite1<.) & (unite2>0 & unite2<.) & (unite1==unite2)  
replace sit=2 if (unite1>0 & unite1<.) & (unite2>0 & unite2<.) & (unite1!=unite2)  
replace sit=3 if (unite1>0 & unite1<.) & (unite2==.) 

tab sit, m

drop if sit==.

gen p0=s07bq08/s07bq07a if sit==1

/* poids region pour valorisation de la consommation
clonevar unite=unite1 
sort region milieu codpr unite
merge m:1 region milieu codpr unite using "$dataout_nsu\ehcvm_nsu_regmil_CIV2018.dta", keepusing(poids)
drop if _merge==2
drop _merge 

sort zae milieu codpr unite
merge m:1 zae milieu codpr unite using "$dataout_nsu\ehcvm_nsu_zaemil_CIV2018.dta", keepusing(poids) update 
drop if _merge==2
drop _merge 

sort milieu codpr unite
merge m:1 milieu codpr unite using "$dataout_nsu\ehcvm_nsu_milieu_CIV2018.dta", keepusing(poids) update 
drop if _merge==2
drop _merge 

sort codpr unite
merge m:1 codpr unite using "$dataout_nsu\ehcvm_nsu_nat_CIV2018.dta", keepusing(poids) update 
drop if _merge==2
drop _merge 
*/

* probablement des missing
recode s07bq03a s07bq04 s07bq05 (99 999 9999 99999 .=0)

** Nbr observations attendu  
sum s07bq03a if s07bq03a>0 & s07bq03a<.
sum s07bq04 if s07bq04>0 & s07bq04<.
sum s07bq05 if s07bq05>0 & s07bq05<.

recode s07bq04 (.=0)
gen conso1=s07bq03a-s07bq04-s07bq05 
gen conso2=s07bq04 
gen conso3=s07bq05 

/*gen conso1=s07bq03a-s07bq04-s07bq05 if sit==1
gen conso2=s07bq04 if sit==1
gen conso3=s07bq05 if sit==1

replace conso1=(s07bq03a-s07bq04-s07bq05)*poids/1000 if sit!=1
replace conso2=s07bq04*poids/1000 if sit!=1
replace conso3=s07bq05*poids/1000 if sit!=1 */

** Nbr observations à traiter _ difference du absence variable poids (NSU)  
sum conso1 if conso1>0 & conso1<.
sum conso2 if conso2>0 & conso2<.
sum conso3 if conso3>0 & conso3<.

preserve
  keep if conso1==. & conso2==. & conso3==.
  count /* 25 cas sur 292741 négligeable */
restore  

/*
merge m:1 vague region milieu codpr using "$dataout_p\ehcvm_pu_regmil_CIV2018.dta"
drop if _merge==2
drop _merge

merge m:1 vague zae milieu codpr using "$dataout_p\ehcvm_pu_zaemil_CIV2018.dta"
drop if _merge==2
drop _merge

merge m:1 vague milieu codpr using "$dataout_p\ehcvm_pu_milieu_CIV2018.dta"
drop if _merge==2
drop _merge

merge m:1 vague region codpr using "$dataout_p\ehcvm_pu_region_CIV2018.dta"
drop if _merge==2
drop _merge

merge m:1 vague zae codpr using "$dataout_p\ehcvm_pu_zae_CIV2018.dta"
drop if _merge==2
drop _merge

merge m:1 vague codpr using "$dataout_p\ehcvm_pu_nat_CIV2018.dta"
drop if _merge==2
drop _merge
*/
clonevar unite=unite1 
sort vague zae milieu codpr unite
merge m:1 zae milieu vague codpr unite using "$dataout_p/ehcvm_pu_merge_CIV2018_unit.dta"

drop if _merge==2
drop _merge

forvalues x=1/3 {
  gen depan`x'=conso`x'*p0*365/7 if sit==1
  replace depan`x'=conso`x'*vu_mean*365/7 if sit!=1 
  disp "résidu non valorisé"
  count if missing(depan`x') /* 1240 observations non valorisées, mois de 0.5% */
}

keep vague zae region milieu grappe menage codpr depan1 depan2 depan3
reshape long depan, i(vague zae region milieu grappe menage codpr) j(modep)

lab def modepl 1"Achat" 2"Autoconso" 3"Don" 4"Valeur usage BD" 5"Loyer imputee" 
lab val modep modepl

drop if depan==0 | depan==.
sum depan
tab modep /* Nbr observations valides, difference, absence  */ 
sort grappe menage codpr modep
save "$dataout_temp\Dep_Alim1.dta", replace  
*

**** Section 7A : repas pris hors ménage au cours des 7 derniers jours
use "$datain_men\s07a1_me_CIV2018.dta", clear 

rename s07aq*b s07aq*
gen s01q00a=98
gen s01q00b=" "

append using "$datain_men\s07a2_me_CIV2018.dta"

recode s07aq02 s07aq05 s07aq08 s07aq11 s07aq14 s07aq17 s07aq20 ///
       s07aq03 s07aq06 s07aq09 s07aq12 s07aq15 s07aq18 s07aq21 (. .a=0)
	   
/* Conso annuelle repas acheté à l'extérieur */
gen depan1=(s07aq02+s07aq05+s07aq08+s07aq11+s07aq14+s07aq17+s07aq20)*365/7
/* Conso annuelle repas extérieur reçu en cadeau */
gen depan3=(s07aq03+s07aq06+s07aq09+s07aq12+s07aq15+s07aq18+s07aq21)*365/7

recode depan1 depan3 (.=0)
destring grappe, replace
merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta", keepusing(zae region milieu grappe menage)
keep if _merge==3    
drop _merge

collapse (sum) depan1 depan3, by(vague grappe menage zae region milieu)
gen codpr=151

reshape long depan, i(vague grappe menage codpr zae region milieu) j(modep)

drop if depan==0 | depan==.
sort grappe menage codpr modep
save "$dataout_temp\Dep_Alim2.dta", replace  
*

**** Section 9C : vins modernes et liqueurs
use "$datain_men\s09c_me_CIV2018.dta", clear 
keep if s09cq02==1
rename s09cq01 codpr
keep if codpr==301 | codpr==302
sum s09cq03
gen depan=s09cq03*12
gen modep=1
destring grappe, replace
merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta", keepusing(zae region milieu grappe menage)
keep if _merge==3    /* ajout personnel */
drop _merge
sum depan
keep if depan>0 & depan<.
keep vague grappe menage codpr modep depan zae region milieu
order grappe menage vague codpr modep
sort grappe menage codpr modep
save "$dataout_temp\Dep_Alim3.dta", replace  
*
*
********* Depenses alimentaires et habit, lors des fêtes, section 9a 

use "$datain_men\s09a_me_CIV2018.dta", clear
destring grappe, replace

merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta", keepusing(grappe menage zae region milieu)
keep if _merge==3
drop _merge

keep if s09aq02==1

rename s09aq01 codpr

drop if codpr>=9    /* On ne garde que les fêtes religieuses  */
drop s09aq06 s09aq07    /* On garde seulement l'alimentation et l'habillement */

sum s09aq03 s09aq04 s09aq05 
recode s09aq03 s09aq04 s09aq05 (.=0)  

gen depan1=s09aq03+s09aq04
gen depan2=s09aq05

collapse (sum) depan1 depan2, by(vague grappe menage zae region milieu) 
reshape long depan, i(vague grappe menage zae region milieu) j(codpr)

recode codpr (1=152) (2=521) 
drop if depan==0 | depan==.

gen modep=1
sum depan
keep if depan>0 & depan<.
keep vague grappe menage codpr modep depan zae region milieu
order grappe menage codpr modep
sort grappe menage codpr modep
save "$dataout_temp\Dep_Fetes.dta", replace  
*
*
use "$dataout_temp\Dep_Fetes.dta", clear

keep if codpr==152 /* le seul produit alimentaire des fêtes */

append using "$dataout_temp\Dep_Alim1.dta" ///
             "$dataout_temp\Dep_Alim2.dta" ///
             "$dataout_temp\Dep_Alim3.dta" 
sum depan
sort grappe menage codpr modep
merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta", keepusing(region milieu zae hhsize)
keep if _merge==3    /* tous les ménages y sont  */
drop _merge  
		 
drop if depan==0 | depan==.
sum depan  /*  Il y a des valeurs anormalement élevées, corrections nécessaires */
gsort -depan
lis grappe menage codpr modep depan if depan>=10000000, sep(200)

************************************* Correction valeurs aberrantes

preserve
  collapse (sum) depant=depan (first) hhsize vague region zae milieu, by(grappe menage codpr)
  gen const=depant/hhsize
  gen lconst=ln(const)
  egen dom1=group(vague zae)
  egen dom2=group(dom1 milieu)
  egen domcod=group(dom2 codpr) 
  egen lconstmd=median(lconst), by(domcod)
  egen liqr=iqr(lconst), by(domcod)
  gen lconstmax=lconstmd+(2.5*liqr)
  gen flag=lconst>lconstmax & lconst<. /* log conso par tête > log median+2.5*iqr */  
  tab region flag 
  gen depant_e=exp(lconstmax)*hhsize if flag==1  /* imputation par le max, trimming */
  keep grappe menage codpr flag depant depant_e
  sort grappe menage codpr
  save "$dataout_temp\Cor_Dep_Alim.dta", replace
restore
******************************************************************** 

sort grappe menage codpr
merge m:1 grappe menage codpr using "$dataout_temp\Cor_Dep_Alim.dta"
drop _merge

lab var codpr"Code produit"
lab var depan"Depense annuelle"
lab var modep"Mode d'acquisition"

*lab def modepl 1"Achat" 2"Autoconso" 3"Don" 4"Valeur usage BD" 5"Loyer imputee" 
lab val modep modepl

preserve
  keep vague grappe menage region milieu zae codpr modep depan
  order grappe menage region milieu zae codpr modep
  sort grappe menage codpr modep
  save "$dataout_temp\Dep_Alim_Sans_Cor.dta", replace 
restore

replace depan=(depan/depant)*depant_e if flag==1 /* Impute, reallocate total consumption by  original share */
drop hhsize flag depant depant_e 

sum depan
compress
order grappe menage region milieu zae codpr modep
sort grappe menage codpr modep
save "$dataout_temp\Dep_Alim.dta", replace 

erase "$dataout_temp\Dep_Alim1.dta"
erase "$dataout_temp\Dep_Alim2.dta" 
erase "$dataout_temp\Dep_Alim3.dta"
erase "$dataout_temp\Cor_Dep_Alim.dta"

***********
*********** Partie 2: Conso non-alim. monétaire - Sections 9b à 9f, 2, 3 et 11 *****
***********
 
****** Dépenses non alimentaires de la section 9
*
foreach x in b c d e f {
  use "$datain_men\s09`x'_me_CIV2018.dta", clear
  keep if s09`x'q02==1
  rename s09`x'q01 codpr
  rename s09`x'q03 s09q03
  drop s09`x'q02
  save "$dataout_temp\s09`x'.dta", replace
}
*	
use "$dataout_temp\s09b.dta", clear
append using "$dataout_temp\s09c.dta" ///
             "$dataout_temp\s09d.dta" ///
             "$dataout_temp\s09e.dta" ///
             "$dataout_temp\s09f.dta"

drop if codpr==301 | codpr==302  /* vins et liqueurs, alimentaire */
drop if codpr==641 // Suppression des frais de pélérinnage
drop if (codpr>=603 & codpr<=607) | (codpr>=610 & codpr<=613) | ///
        (codpr==616) | (codpr>=623 & codpr<=624) | ///
        (codpr>=633 & codpr<=635)  /* Investissement en logement et biens durables */
*
sum s09q03
gen depan=s09q03*365/7 if codpr>=201 & codpr<=217 /* Dépenses 7 jours */
replace depan=s09q03*12 if codpr>=301 & codpr<=322 /* Dépenses 30 jours */
replace depan=s09q03*4 if codpr>=401 & codpr<=418 /* Dépenses 3 mois */
replace depan=s09q03*2 if codpr>=501 & codpr<=512 /* Dépenses 6 mois */
replace depan=s09q03 if codpr>=601 & codpr<=653 /* Dépenses 12 mois */
gen modep=1

destring grappe, replace
merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta", keepusing(grappe menage hhsize zae region milieu)
keep if _merge==3

drop _merge hhsize

sum depan
keep if depan>0 & depan<.
keep vague grappe menage codpr modep depan vague zae region milieu
order grappe menage codpr modep
sort grappe menage codpr modep
save "$dataout_temp\Dep_Nalim_S9.dta", replace  
*
erase "$dataout_temp\s09b.dta"
erase "$dataout_temp\s09c.dta" 
erase "$dataout_temp\s09d.dta" 
erase "$dataout_temp\s09e.dta" 
erase "$dataout_temp\s09f.dta"
*
*********************** Depenses de telephonie mobile, section 1

use "$datain_men\s01_me_CIV2018.dta", clear
drop if s01q00a==.  /* individus inexistant créés artificiellement */

destring grappe, replace
merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta"
keep if _merge==3
drop _merge  

sum s01q38
recode s01q38 (. =0)
gen depan=s01q38*365/7
collapse (sum) depan (first) vague zae region milieu, by(grappe menage )
drop if depan==0 | depan==.
gen codpr=338
gen modep=1
order grappe menage codpr modep
sort grappe menage codpr
compress
save "$dataout_temp\Dep_Tmob.dta", replace
*
*********************** Depenses education, section 2

use "$datain_men\s02_me_CIV2018.dta", clear
drop if s01q00a==.  /* individus inexistant créés artificiellement */

destring grappe, replace
merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta"
keep if _merge==3
drop _merge  

sum s02q20 s02q21 s02q22 s02q23 s02q24 s02q25 s02q26 s02q27
recode s02q20 s02q21 s02q22 s02q23 s02q24 s02q25 s02q26 s02q27 (.a =0)

tab s02q14, m
drop if s02q14==.
recode s02q14 (1 2=1) (3 4=2) (5 6=3) (7 8=4), gen(niv)

forval num=1/4 {
  gen frais`num'=s02q20+s02q21 if niv==`num'
  gen fourn`num'=s02q22+s02q23+s02q24+s02q25+s02q26 if niv==`num'
  gen fsout`num'=s02q27 if niv==`num'
}
*
recode frais1 fourn1 fsout1 frais2 fourn2 fsout2 frais3 fourn3 fsout3 ///
       frais4 fourn4 fsout4 (.=0)
collapse (sum) frais1 fourn1 fsout1 frais2 fourn2 fsout2 frais3 fourn3 fsout3 ///
               frais4 fourn4 fsout4, by(grappe menage vague zae region milieu)

rename (frais1 fourn1 fsout1 frais2 fourn2 fsout2 frais3 fourn3 fsout3 ///
        frais4 fourn4 fsout4) ///
	   (depan1 depan2 depan3 depan4 depan5 depan6 depan7 depan8 depan9 ///
	    depan10 depan11 depan12)
reshape long depan, i(grappe menage vague zae region milieu) j(codpr)

recode codpr (1=661) (2=662) (3=663) (4=664) (5=665) (6=666) (7=667) (8=668) ///
             (9=669) (10=670) (11=671) (12=672) 
drop if depan==0 | depan==.
gen modep=1
order grappe menage codpr modep
sort grappe menage codpr
compress
save "$dataout_temp\Dep_Educ.dta", replace

*********************** Depenses de santé, section 3

use "$datain_men\s03_me_CIV2018.dta", clear
drop if s01q00a==.  /* individus inexistant créés artificiellement */

destring grappe, replace
merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta"
keep if _merge==3
drop _merge  

sum s03q13 s03q14 s03q15 s03q16 s03q17 s03q18 s03q24 s03q29 s03q30 s03q31
recode s03q13 s03q14 s03q15 s03q16 s03q17 s03q18 s03q20 s03q24 s03q29 s03q30 s03q31 (. .a =0)
tab1 s03q05 s03q12 s03q20 

gen depan1=s03q13*4
gen depan2=s03q14*4
gen depan3=s03q15*4
gen depan4=s03q16*4
gen depan5=s03q17*4
gen depan6=s03q18*4
gen depan7=s03q24*s03q20
gen depan8=s03q29+s03q30+s03q31

recode depan1 depan2 depan3 depan4 depan5 depan6 depan7 depan8 (.=0)

collapse (sum) depan1 depan2 depan3 depan4 depan5 depan6 depan7 depan8 ///
         (first) vague zae region milieu, by(grappe menage)

reshape long depan, i(grappe menage vague zae region milieu) j(codpr)

recode codpr (1=681) (2=682) (3=683) (4=684) (5=685) (6=686) (7=691) (8=692)  
drop if depan==0 | depan==.
gen modep=1
order grappe menage codpr modep
sort grappe menage codpr
compress
save "$dataout_temp\Dep_Sante.dta", replace

*********************** Depenses de Logement, section 11

use "$datain_men\s11_me_CIV2018.dta", clear

drop if s11q01==. | s11q01==.a /* keep only households with valid questionnaire */
destring grappe, replace
merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta"
keep if _merge==3
drop _merge  

* s11q04 s11q05 (locataire et loyer); s11q24a s11q24b (facture eau et périodicité)
* s11q26 (eau revendeur); s11q37a s11q37b (facture elec. et périod.) 
* s11q45a s11q45b (telephone fixe et périod.); s1148a et s1148b (internet et period.) 
* s11q52a s11q45b (cable et périod.) 

sum s11q05 s11q24a s11q26 s11q37a s11q45a s11q48a s11q52a
recode s11q05 s11q24a s11q26 s11q37a s11q45a s11q48a s11q52a (. .a =0)

clonevar s11q5a=s11q05
clonevar s11q26a=s11q26
gen s11q5b=2
gen s11q26b=2

foreach x in 5 24 26 37 45 48 52 {
 gen depan`x'=s11q`x'a*52 if s11q`x'b==1
 replace depan`x'=s11q`x'a*12 if s11q`x'b==2
 replace depan`x'=s11q`x'a*6 if s11q`x'b==3
 replace depan`x'=s11q`x'a*4 if s11q`x'b==4
   }
*
keep grappe menage depan5 depan24 depan26 depan37 depan45 depan48 depan52 vague zae region milieu
reshape long depan, i(grappe menage vague zae region milieu) j(codpr)

recode codpr (5=331) (24=332) (26=333) (37=334) (45=335) (48=336) (52=337)
drop if depan==0 | depan==.
gen modep=1
order grappe menage codpr modep
sort grappe menage codpr
compress
save "$dataout_temp\Dep_Logement.dta", replace

********* Ensemble consommation monétaire non alimentaire 

use "$dataout_temp\Dep_Fetes.dta", clear

keep if codpr==521 /* Le seul item non-alimentaire de ce fichier */

append using "$dataout_temp\Dep_Nalim_S9.dta" ///
			 "$dataout_temp\Dep_Tmob.dta" ///
             "$dataout_temp\Dep_Educ.dta" ///
			 "$dataout_temp\Dep_Sante.dta" ///
             "$dataout_temp\Dep_Logement.dta" 
*
lab var codpr "Code produit"
lab var depan "Depense annuelle"
lab var modep "Mode d'acquisition"

lab val modep modepl

sum depan  /*  Il y a des valeurs anormalement élevées, corrections nécessaires */
sort grappe menage codpr modep
merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta", keepusing(zae region milieu hhsize)
keep if _merge==3
drop _merge  

drop if depan==0 | depan==.
tab codpr, m

preserve
  keep grappe menage zae region milieu codpr modep depan
  order grappe menage region milieu codpr modep depan
  compress
  sort grappe menage codpr modep depan
  save "$dataout_temp\Dep_Nalim_Sans_Cor.dta", replace
restore

********************** Correction valeurs aberrantes ********************************
gen ldepan=ln(depan)
egen dom1=group(vague zae)
egen dom2=group(dom1 milieu)
egen domcod=group(dom2 codpr) 
egen ldepanmn=median(ldepan), by(domcod)
egen liqr=iqr(ldepan), by(domcod)
gen ldepanmax=ldepanmn+(2.5*liqr) 
gen flag=ldepan>ldepanmax & ldepan<.  /* anormale si log conso > log median+2.5*iqr */ 
tab region flag
replace depan=exp(ldepanmax) if flag==1    /* imputation par valeur max, trimming */

sum depan
keep vague grappe menage region milieu codpr modep depan
order grappe menage vague region milieu codpr modep
compress
sort grappe menage codpr modep
save "$dataout_temp\Dep_Nalim.dta", replace
*
erase "$dataout_temp\Dep_Fetes.dta"
erase "$dataout_temp\Dep_Nalim_S9.dta" 
erase "$dataout_temp\Dep_Tmob.dta" 
erase "$dataout_temp\Dep_Educ.dta" 
erase "$dataout_temp\Dep_Sante.dta" 
erase "$dataout_temp\Dep_Logement.dta"

***********
*********** Partie 3: Valeur d’usage des biens durables - Section 12 *********
***********

use "$datain_men\s12_me_CIV2018.dta", clear

keep if s12q02==1
rename s12q01 codpr
sort grappe menage codpr
tab codpr, m
destring grappe, replace
merge m:1 grappe menage using "$dataout_temp/ehcvm_men_temp.dta", keepusing(grappe menage zae region milieu)
keep if _merge==3  /* 102 ménages sans biens durables */
drop _merge  

drop if codpr==44 | codpr==45 | codpr==40 | codpr==41 /* Immeubles, non biens durables */
replace codpr=800+codpr 
sum s12q07 s12q08 s12q09
replace s12q07=2 if s12q07==-2 /* Valeur négative, probablement erreur */

ta s12q07 if s12q02==1,m // 2,41% des biens sont concernés

**************************************
gen age=s12q07 
replace age=0.5 if s12q07==0 
replace age=20 if age>=20 & age<.

gen vacqui=s12q08 if s12q08!=. & s12q08!=0
gen vrempla=s12q09 if s12q09!=. & s12q09!=0 
replace vacqui=. if s12q08<=s12q09
replace vrempla=. if s12q08<=s12q09

gen depret=1-(vrempla/vacqui)^(1/age) if (s12q09>0 & s12q09<.) & (s12q08>0 & s12q08<.)

egen mdpret=median(depret), by(codpr) 
tabstat mdpret, by(codpr)

/* Avant de calculer la valeur d'usage, on impute la quantite (dg3) 
   et la valeur d'acquisition (dg8) quand elles sont ND. De plus, 
   on corrige les valeurs aberrantes de ces 2 variables */

tab codpr s12q03, m 
egen Ms12q03 = mode(s12q03), by (codpr)
replace s12q03=Ms12q03 if missing(s12q03) // Aucun cas concerné

egen Mes12q03=median(s12q03), by(codpr)
egen Ets12q03=iqr(s12q03), by(codpr)
gen Maxs12q03=Mes12q03+(3*Ets12q03)
gen Cor=s12q03>Maxs12q03
tab codpr Cor // 2,76% d'observations sont concernées. 
replace s12q03=Maxs12q03 if Cor==1
drop Cor   
*   
gen ls12q08=ln(s12q08)
sum s12q08 ls12q08
egen mdg8=median(ls12q08), by(codpr)
egen idg8=iqr(ls12q08), by(codpr)
sum s12q08
replace s12q08=exp(mdg8) if missing(s12q08) | s12q08==0
sum s12q08
gen mdg8max=mdg8+(2.5*idg8)
gen didi=ls12q08>mdg8max 
tab codpr didi
replace s12q08=exp(mdg8max) if didi==1
sum s12q08
drop didi

gen depan=s12q03*s12q08*((1.01)^age)*(mdpret+0.02)   /*correction 6/12 */
gen modep=4
tab codpr, m
			 
drop if depan==0 | depan==.
sum depan

preserve 
  keep vague grappe menage zae region milieu codpr modep depan 
  order grappe menage region milieu codpr modep depan
  compress
  sort grappe menage codpr modep
  save "$dataout_temp\Dep_Bdur_Sans_Cor.dta", replace
restore

gen ldepan=ln(depan)
egen ldepanmn=median(ldepan), by(codpr)
egen liqr=iqr(ldepan), by(codpr)
gen ldepanmax=ldepanmn+(2.5*liqr) 
gen flag=ldepan>ldepanmax & ldepan<.   
tab codpr flag
replace depan=exp(ldepanmax) if flag==1    /* imputation par la valeur max, plus logique pour le non-alim */
drop flag ldepanmn ldepanmax liqr

sum depan

preserve
keep vague grappe menage zae region milieu codpr modep depan s12q03 s12q09
order grappe menage region milieu codpr modep depan s12q03 s12q09
save "$dataout_temp\Dep_Bdur4model.dta", replace
restore

keep vague grappe menage zae region milieu codpr modep depan 
order grappe menage region milieu codpr modep depan
compress
sort grappe menage codpr modep
tab codpr 

save "$dataout_temp\Dep_Bdur.dta", replace

***********
*********** Partie 4: loyer impute (propro et gratuit) - Section 11 ************
***********
/*
use "$datain_com\s01_co_CIV2018.dta", clear

keep grappe s01q06 s01q08__1 s01q08__2 s01q08__3 s01q08__4 s01q11 s01q12 s01q13a__1 s01q13a__2 s01q13a__3

tab1 s01q06 s01q08__1 s01q08__2 s01q08__3 s01q08__4 s01q11 s01q12 s01q13a__1 s01q13a__2 s01q13a__3, m	 

gen route_goud=s01q06==1	
gen route_late=s01q06==2
gen trans_moto=s01q08__1==1	
gen trans_voit=s01q08__2==1
gen reseau_elec=s01q11==1
gen reseau_eau=s01q12==1
gen reseau_tel=s01q13a__1==1 | s01q13a__2==1 |  s01q13a__3==1	 

keep grappe route_goud route_late trans_moto trans_voit reseau_elec reseau_eau reseau_tel
sort grappe
save  "$dataout_temp\Infra_com.dta", replace
*/
*	 
use "$datain_men\s11_me_CIV2018.dta", clear

drop if s11q01==. | s11q01==.a /* keep only households with valid questionnaire */
destring grappe, replace
merge 1:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta", keepusing (zae region milieu hhsize)
keep if _merge==3
drop _merge  

preserve
  use "$dataout_temp\Dep_Nalim.dta", clear
  keep if codpr==331  /* On récupère le montant du loyer payé */
  rename depan loyer
  keep grappe menage loyer
  sort grappe menage
  save "$dataout_temp\Loyer.dta", replace
restore

merge 1:1 grappe menage using "$dataout_temp\Loyer.dta"
drop _merge
erase "$dataout_temp\Loyer.dta"

merge m:1 grappe using "$datain_aux\ehcvm_ponderations_CIV2018.dta", keepusing (hhweight)
tab _m
drop _m

merge 1:1 grappe menage using "$datain_men\s00_me_CIV2018.dta", keepusing (s00q03 s00q05)
tab _m
drop _m

* Les codes localités (s00q05) des vagues 1 et 2 sont indépendants
* en attendant la fin de la mise en cohérence, les ajustement ci-après sont faits pour la zae Abidjan

numlabel, add
tab s00q05 if s00q03 ==201 & vague==1
/*
replace s00q05="ABOBO" 			if vague==1 & s00q05=="AGBOVILLE"
replace s00q05="ADJAME" 		if vague==1 & s00q05=="GRAND-YAPO"
replace s00q05="ATTECOUBE" 		if vague==1 & s00q05=="ATTOBROU"
replace s00q05="COCODY" 		if vague==1 & s00q05=="ABBE BEGNINI CAMPEMENTS"
replace s00q05="KOUMASSI" 		if vague==1 & s00q05=="ARRAGUIE"
replace s00q05="MARCORY" 		if vague==1 & s00q05=="AVOCATIER"
replace s00q05="PORT-BOUET" 	if vague==1 & s00q05=="AMANGBEU"
replace s00q05="TREICHVILLE" 	if vague==1 & s00q05=="YAOBOU"
replace s00q05="YOPOUGON" 		if vague==1 & s00q05=="ELIBOU"
replace s00q05="ANYAMA" 		if vague==1 & s00q05=="LELEBLE CAMPEMENTS"
*/
/*
replace s00q05=17 			if vague==1 & s00q05==1
replace s00q05=18			if vague==1 & s00q05==2
replace s00q05=19		if vague==1 & s00q05==3
replace s00q05=20 		if vague==1 & s00q05==4
replace s00q05=21 		if vague==1 & s00q05==5
replace s00q05="MARCORY" 		if vague==1 & s00q05==6
replace s00q05=23 	if vague==1 & s00q05==7
replace s00q05=24 	if vague==1 & s00q05==8
replace s00q05=25		if vague==1 & s00q05==9
replace s00q05=26 		if vague==1 & s00q05==11
*/
replace s00q05=17 if vague==1 & s00q05==1
replace s00q05=18 if vague==1 & s00q05==2
replace s00q05=19 if vague==1 & s00q05==3
replace s00q05=20 if vague==1 & s00q05==4
replace s00q05=21 if vague==1 & s00q05==5
replace s00q05=888 if vague==1 & s00q05==6
replace s00q05=23 if vague==1 & s00q05==7
replace s00q05=24 if vague==1 & s00q05==8
replace s00q05=25 if vague==1 & s00q05==9
replace s00q05=26 if vague==1 & s00q05==11


ren s00q03 sous_prefecture
ren s00q05 quartier 


tab quartier if region==1 & milieu==1, gen(quartier)  
tab sous_prefecture if region==1 & milieu==1, gen(sous_prefect)
*
recode loyer (.=0)
tabulate region, gen(region)
tabulate zae, gen(zae)
gen urbain=(milieu==1)

tab1 s11q01 s11q04 s11q03__1 s11q03__2 s11q03__3 s11q19 s11q20 s11q21 ///
     s11q22 s11q34 s11q54 s11q55 s11q56 s11q58 s11q59 s11q60, m 
sum s11q02 

gen locat=(s11q04==5)
gen flag=(locat==1 & loyer==0)  /* Identification de locataires sans loyer */
tab flag     /* aucun cas dans cette situation */
drop flag
gen flag=(locat!=1 & loyer>0 & loyer<.) /* Identification de non locataires avec loyer */
tab flag   /* aucun cas dans cette situation */
*list grappe menage locat loyer if flag==1
*replace locat=0 if locat==1 & loyer==0

gen lnloyer=ln(loyer) if locat==1

recode s11q01 (1 2=1) (3 4=2) (5=3) (6=4) (7 8 9=5), gen(typlog)
label define typlog 1 "Maison moderne" 2 "Bande de maison" 3 "Cour commune" 4 "Maison isolée" 5 "Autre"
label val typlog typlog
tab typlog, m

gen lnpiece=ln(s11q02)

clonevar clim=s11q03__1
clonevar chauffe=s11q03__2
clonevar ventilo=s11q03__3

gen eau=(s11q22==1)
gen elec=(s11q34!=4)

recode s11q19 (1 3=1) (2=2) (4=3) (5 6 7 8=4), gen(mur) 
label define mur 1 "Ciment/Béton/Pierres de taille" 2 "Briques cuites" 3 "Banco amélioré/ semi-dur" 4 "Autre"
label val mur mur

gen toitdef=s11q20>=1 & s11q20<=3

recode s11q21 (1=1) (2=2) (3/5 .a=3), gen(sol) 

recode s11q54 (1=1) (2=2) (5=3) (3 4 6 .a=4), gen(ordures)
label define ordures 1 "Dépotoir public" 2 "Ramassage" 3 "Dépotoir sauvage" 4 "Autre"
label val ordures ordures

recode s11q55 (1/4=1) (5=2) (6=3) (7=4) (8=5) (9=6) (11=7) (10 12=8), gen(toilet) 

clonevar excre=s11q59 
replace excre=6 if excre==. & inlist(s11q55, 10, 11) // ligne modifiée

recode s11q60 (1/2=1) (3=2) (4/5=3) , gen(eausee)

tabulate typlog, gen(typlog)
tabulate mur, gen(mur)
tabulate sol, gen(sol)
tabulate toilet, gen(toilet)
tabulate ordures, gen(ordures)
tabulate excre, gen(excre)
tabulate eausee, gen(eausee)

merge m:1 grappe using "$dataout_temp\Infra_com.dta"
drop _merge

recode route_goud route_late trans_moto trans_voit reseau_elec reseau_eau reseau_tel (.=0)

gen zone=milieu+1
replace zone=1 if region==1 & milieu==1

// comparing housing characteristics of owners and renters 

*** Capital

sum lnloyer locat lnpiece typlog* clim chauffe ventilo eau elec mur* toitdef sol* ///
	toilet* ordures* excre* eausee* route_goud route_late ///
	trans_moto trans_voit reseau_elec reseau_eau reseau_tel [w=hhweight*hhsize] ///
	if zone==1 & locat==0   // owner in Abijan
		
sum lnloyer locat lnpiece typlog* clim chauffe ventilo eau elec mur* toitdef sol* ///
	toilet* ordures* excre* eausee* route_goud route_late ///
	trans_moto trans_voit reseau_elec reseau_eau reseau_tel [w=hhweight*hhsize] ///
	if zone==1 & locat==1   // renter in Abijan

reg lnpiece locat [w=hhweight*hhsize] if zone == 1  // p=0.000	
	
*** Urban	

sum lnloyer locat lnpiece typlog* clim chauffe ventilo eau elec mur* toitdef sol* ///
	toilet* ordures* excre* eausee* route_goud route_late ///
	trans_moto trans_voit reseau_elec reseau_eau reseau_tel [w=hhweight*hhsize] ///
	if zone==2 & locat==0   // owner in urban areas
		
sum lnloyer locat lnpiece typlog* clim chauffe ventilo eau elec mur* toitdef sol* ///
	toilet* ordures* excre* eausee* route_goud route_late ///
	trans_moto trans_voit reseau_elec reseau_eau reseau_tel [w=hhweight*hhsize] ///
	if zone==2 & locat==1   // renter in urban areas
	
reg lnpiece locat [w=hhweight*hhsize] if zone == 2 // p=0.000	
	
*** Rural 

sum lnloyer locat lnpiece typlog* clim chauffe ventilo eau elec mur* toitdef sol* ///
	toilet* ordures* excre* eausee* route_goud route_late ///
	trans_moto trans_voit reseau_elec reseau_eau reseau_tel [w=hhweight*hhsize] ///
	if zone==3 & locat==0   // owner in rural areas
		
sum lnloyer locat lnpiece typlog* clim chauffe ventilo eau elec mur* toitdef sol* ///
	toilet* ordures* excre* eausee* route_goud route_late ///
	trans_moto trans_voit reseau_elec reseau_eau reseau_tel [w=hhweight*hhsize] ///
	if zone==3 & locat==1   // renter in rural areas
	
reg lnpiece locat [w=hhweight*hhsize] if zone == 3  // p=0.000	

*	
*
******** Regresssion Capital

// drop RHS variables that are not significant (p>.10)
// include quartier dummies 
																				// ADAPTER la liste des varaiables !!!!!!!!!!!!!!!!
stepwise, pr(.0501) pe(.05) forward : reg lnloyer lnpiece clim chauffe ventilo typlog2-typlog5  ///
				quartier2-quartier12 ///
                eau elec mur2-mur4 toitdef sol2 sol3 ///
				toilet2-toilet6 toilet8 /// 
				ordures2-ordures4 eausee2 eausee3 /// 
				excre2-excre6 route_goud route_late ///
				trans_moto trans_voit reseau_elec reseau_eau reseau_tel if zone==1
				
* store the var list produced from stepwise
mat list e(b)
mat A_capital = e(b)  
scalar col_cap = colsof(A_capital)
local nvar_cap = col_cap -1
matselrc A_capital A_vars_cap1, c(1/`nvar_cap')  // excluding _cons term
local var1: colnames A_vars_cap1

reg 	lnloyer `var1' if zone==1 
predlog loyer `var1' if zone==1 

rename YHTSMEAR CAP_YHTSMEAR_new1   // with all quartier 
drop YH*

// compare imputation approaches - Capital

gen loyer_imp1=CAP_YHTSMEAR_new1 if locat==0 & zone==1
gen loyer_eff=loyer if locat==1 & zone==1

tabstat loyer_eff loyer_imp1 if zone==1, stat(count min p25 mean median p75 max)  

twoway (kdensity CAP_YHTSMEAR_new1 if locat==0 & zone==1, title(Capital) legend(label (1 "impute w/ quartier dummies"))) ///
(kdensity loyer if locat==1 & zone==1, legend(label (2 "actual rent")))

graph export "$prog\rent_cap.tif", replace
*
*
******** Regresssion Intérieur du pays - URBAN

// REVISED imputation
// Drop RHS that are not significant (p>.1)

																				// ADAPTER la liste des varaiables !!!!!!!!!!!!!!!!

stepwise, pr(.0501) pe(.05) forward : reg lnloyer lnpiece clim chauffe ventilo typlog2 typlog3 typlog4 typlog5 ///
                eau elec mur2 mur3 mur4 toitdef sol2 sol3 ///
				toilet2 toilet3 toilet4 toilet5 toilet6 toilet7 toilet8 /// 
				ordures2 ordures3 ordures4 eausee2 eausee3 /// 
				excre2 excre3 excre4 excre5 excre6 ///
				route_goud route_late trans_moto trans_voit reseau_elec reseau_eau reseau_tel ///
                region2 region3 region4 region5 region6 region7 region8	///
				region9 region10 region11 region12 region13 region14 region15 region16 ///
                region17 region18 region19 region20 region21 region22 region23 ///
                region25 region26 region27 region28 region29 region30 region31 region32 region33  if zone==2

* store the var list produced from stepwise
mat list e(b) 
mat A_urb = e(b)  
scalar col_urb = colsof(A_urb)
local nvar_urb = col_urb -1
matselrc A_urb A_vars_urb, c(1/`nvar_urb')  // excluding _cons term
local var_urb: colnames A_vars_urb

reg 	lnloyer `var_urb' if zone==2
predlog loyer `var_urb' if zone==2 

rename YHTSMEAR URB_YHTSMEAR_new
drop YH*

// compare imputation approaches - URBAN

replace loyer_imp1=URB_YHTSMEAR_new if locat==0 & zone==2
replace loyer_eff=loyer if locat==1 & zone==2

tabstat loyer_eff loyer_imp1 if zone==2, stat(count min p25 mean median p75 max)  

twoway (kdensity URB_YHTSMEAR_new if locat==0 & zone==2, title(Urban) legend(label (1 "revised imputation"))) ///
(kdensity loyer if locat==1 & zone==2, legend(label (2 "actual rent")))

graph export "$prog\rent_urb.tif", replace
*
*
******** Regresssion Intérieur du pays - Rural

// drop insignificant RHS variables (p>.10)
																				// ADAPTER la liste des varaiables !!!!!!!!!!!!!!!!!!!!!!!


stepwise, pr(.0501) pe(.05) forward : reg lnloyer lnpiece ventilo typlog2 typlog3 typlog4 typlog5 eau elec ///
				mur2 mur3 mur4 toitdef sol2 sol3 ///
				toilet2 toilet3 toilet4 toilet5 toilet6 toilet7 toilet8 /// 
				ordures2 ordures3 ordures4 eausee2 eausee3 /// 
				excre2 excre3 excre4 excre5 excre6 ///
				route_goud route_late trans_moto trans_voit reseau_elec reseau_eau reseau_tel ///
                region2 region3 region4 region5 region6 region7 region8 ///
				region9 region10 region11 region12 region13 region14 region15 region16 ///
                region17 region18 region19 region20 region21 region22 region23 region24 ///
                region25 region26 region27 region28 region29 region30 region31 region32 region33 if zone==3

mat list e(b) 
mat A_rurb = e(b)  
scalar col_rurb = colsof(A_rurb)
local nvar_rurb = col_rurb -1
matselrc A_rurb A_vars_rurb, c(1/`nvar_rurb')  // excluding _cons term
local var_rurb: colnames A_vars_rurb

reg 	lnloyer `var_rurb' if zone==3
predlog loyer `var_rurb' if zone==3 

rename YHTSMEAR RUR_YHTSMEAR_new
drop YH*

// compare imputation approaches - Rural

replace loyer_imp1=RUR_YHTSMEAR_new if locat==0 & zone==3
replace loyer_eff=loyer if locat==1 & zone==3

tabstat loyer_eff loyer_imp1 if zone==3, stat(count min p25 mean median p75 max)  

twoway (kdensity RUR_YHTSMEAR_new if locat==0 & zone==3, title(Rural) legend(label (1 "revised imputation"))) ///
(kdensity loyer if locat==1 & zone==3, legend(label (2 "actual rent")))

graph export "$prog\rent_rur.tif", replace

gen depan=loyer_imp1 if locat==0
gen codpr=331
gen modep=5
sum depan

drop if depan==.
tab codpr, m

lab var codpr "Code produit"
lab var depan "Depense annuelle"
lab var modep "Mode d'acquisition"

lab val modep modepl

keep if locat==0
keep vague grappe menage codpr modep depan zae region milieu locat
order grappe menage region milieu codpr modep depan locat
compress
sort grappe menage codpr modep
save "$dataout_temp\Dep_Loyer.dta", replace 

***********
*********** Partie 5: Agrégat de consommation et quelques tests ************
***********
ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp
use "$dataout_temp\Dep_Alim.dta", clear

append using "$dataout_temp\Dep_Nalim.dta" ///
             "$dataout_temp\Dep_Bdur.dta" ///
             "$dataout_temp\Dep_Loyer.dta"
*
lab def mill 1"Urbain" 2"Rural"
lab val milieu mill


monprog_lab_region		  

gen str country=`"$pays"'
lab var country "Pays"
gen year="2018"
gen hhid=grappe*100+menage
lab var year "Annee enquete"
lab var hhid "Identifiant unique menage"
lab var grappe "Numero grappe"
lab var menage "Numero menage"
lab var region "Region residence"
lab var milieu "Milieu residence"		 
lab var codpr  "Code produit"
lab var modep  "Mode d'acquisition"
lab var depan  "Depense annuelle"

lab val modep modepl
run "$prog\codpr_label.do"
lab val codpr codprl


merge m:1 grappe using "$datain_aux\ehcvm_ponderations_CIV2018.dta", keepusing(grappe hhweight)
keep if _merge==3
drop _merge 
lab var hhweight "Ponderation"

keep country year hhid vague grappe menage region milieu hhweight codpr modep depan
compress
order country year hhid vague grappe menage region milieu hhweight codpr modep
sort hhid codpr modep
save "$dataout\ehcvm_conso_CIV2018.dta", replace
*
*
****** 
********************************************************************************
***               Tests de validation et sensibilite                           *
********************************************************************************

******************** T1: Coefficients budgétaires ******************* **********
use "$dataout\ehcvm_conso_CIV2018.dta", clear
drop if codpr>=152 & codpr<=164  /* Produits inclus seulement pour tests */
gen co_ali=((codpr>=1 & codpr<=136) |  (codpr>=139 & codpr<=151))
lab def co_ali_l 0"Code depenses non-alim." 1"Code depenses alim." 
lab val co_ali co_ali_l 
gen dali=depan if co_ali==1 
gen dnal=depan if co_ali==0
recode dali dnal (.=0)
gen dali1=depan if co_ali==1 & modep==1
gen dali2=depan if co_ali==1 & modep==2
gen dali3=depan if co_ali==1 & modep==3

lab var dali1 "Dep Ali Achat"
lab var dali2 "Dep Ali Auto-consommation"
lab var dali3 "Dep Ali Cadeaux recus"

*** Test Coeff. budgétaire cons. alim sans et avec repas pris à l'extérieur
gen cobu1=depan if (codpr>=1 & codpr<=136)
gen cobu2=depan if codpr==151
gen cobu3=depan if codpr==137 | codpr==138 | codpr==301 | codpr==302
gen cobu4=depan if (codpr>=201 & codpr<=217) | (codpr>=303 & codpr<=322) | ///
 (codpr==331 & modep==1) | (codpr>=332 & codpr<=338) | (codpr>=401 & codpr<=418) | ///
 (codpr>=501 & codpr<=512) | codpr==521 | (codpr>=601 & codpr<=602) | ///
 (codpr>=608 & codpr<=609) | (codpr>=614 & codpr<=615) | ///
 (codpr>=617 & codpr<=622) | (codpr>=625 & codpr<=632) | (codpr>=636 & codpr<=653) | ///
 (codpr>=661 & codpr<=672) | (codpr>=681 & codpr<=686) | (codpr>=691 & codpr<=692)
gen cobu5=depan if (codpr>=801 & codpr<=839) | (codpr==842 | codpr==843)
gen cobu6=depan if codpr==331 & modep==5

collapse (sum) dali1 dali2 dali3 dali dnal cobu1 cobu2 cobu3 cobu4 cobu5 cobu6 (first) hhweight, by(hhid)
lab var dali1 "Dep Ali Achat"
lab var dali2 "Dep Ali Auto-consommation"
lab var dali3 "Dep Ali Cadeaux recus"

preserve 
  use "$dataout\ehcvm_individu_CIV2018.dta", clear
  keep if resid==1   /*  membres du menage   */
  egen hhsize=count(numind), by(hhid)
  keep if lien==1
  save "$dataout_temp\ehcvm_temp.dta", replace
restore  

merge 1:1 hhid using  "$dataout_temp\ehcvm_temp.dta"
drop _merge

gen dtot=dali+dnal

forval i = 1/6 { 
  replace cobu`i'=cobu`i'/dtot 
  }

gen hhwt=round(hhweight*dtot)
gen dtet=dtot/hhsize
xtile ndtet=dtet [pw=hhweight*hhsize], nq(10)

tabstat cobu1 cobu2 cobu3 cobu4 cobu5 cobu6 [fw=hhwt], by(ndtet)

gen ldtet=ln(dtet) 
kdensity ldtet, normal
erase "$dataout_temp\ehcvm_temp.dta"
save "$dataout\ehcvm_conso_CIV2018_hh.dta", replace
