*******************************************************************************
*       Enquete harmonisee sur les conditions de vie des menages - UEMOA      *
*    Creation du fichier des caractéristiques sociodemographiques             *
*                                                                             *
*                 Programme adapté pour la Côte d'Ivoire                      *
*******************************************************************************

clear
capture log close
set more off
/*
global data "C:\EHCVM_CIV_200416"

global datain "$data\Datain"
global datain_men "$datain\Menage"
global datain_com "$datain\Commune"
global datain_aux "$datain\Auxiliaire"

*/
/*
global datain "C:\Users\wb324658\OneDrive - WBG\FY18\CI\HDataCIV\Data_CIV\EHCVM032020\CIV\Datain"
global datain_men "$datain\Menage"
global datain_com "$datain\Commune"
global datain_aux "$datain\Auxiliaire"
*/


***********
********************* Lecture des fichiers au niveau individuel **************************
***********

use "$datain_men\s01_me_CIV2018.dta", clear 
/*
use "$datain_men\s02_me_CIV2018.dta", clear 
merge m:1 grappe menage using "$datain_men/s00_me_CIV2018.dta", keepusing(vague) 
drop _merge
save "$datain_men\s02_me_CIV2018.dta", replace
*/
merge 1:1 vague grappe menage s01q00a using "$datain_men\s02_me_CIV2018.dta", nogen
merge 1:1 vague grappe menage s01q00a using "$datain_men\s03_me_CIV2018.dta", nogen
merge 1:1 vague grappe menage s01q00a using "$datain_men\s04_me_CIV2018.dta", nogen
merge 1:1 vague grappe menage s01q00a using "$datain_men\s06_me_CIV2018.dta", nogen

merge m:1 vague grappe menage using "$datain_men\s00_me_CIV2018.dta", ///
  keepusing(s00q00 s00q01 s00q02  s00q04 s00q08 s00q23a s00q27) nogen
// s00q03
tab s00q08 s01q01, m 
tab s00q08 s01q02, m 

drop if s00q08!=1 & s00q08!=2  /* Conserver les ménages avec un questionnaire valide */

***********
********************* Informations générales
***********

gen str country="CIV"
gen year=2018 if vague==1
replace year=2019 if vague==2
destring grappe, replace
gen hhid=grappe*100+menage 

rename s01q00a numind
rename s00q01 region
rename s00q02 departement
// rename s00q03 sousprefecture
rename s00q04 milieu

recode region (4 7 11 21 29 33=1 "CENTRE") (2 6 12 18 27=2 "CENTRE-OUEST")  ///
            (3 8 10 14 19 20 22 23 24 28 32=3 "NORD") (1 5 13 16 26 30=4 "SUD-EST") ///
			(9 15 17 25 31=5 "SUD-OUEST") (0=6 "ABIDJAN"), gen(zae)
replace zae=6 if region==1 & milieu==1 

label var country "Pays" 
label var year "Annee enquete"
label var hhid "Idenfiant menage"
label var grappe "Numero de grappe"
label var menage "Numero du menage"
label var numind "Numero individu"
label var zae "Zone agroecologique"
label var region "Region de residence"
label var departement "departement de residence"
// label var sousprefecture "sous-prefecture de residence"
label var milieu "Milieu residence"

sort grappe menage numind

tab1 region milieu zae, m 

******
****** Caractéristiques sociodemographiques de base ****************************
******

drop if missing(numind)  /* individus inexistant créés artificiellement */

preserve
  collapse (count) hhsize=numind (first) milieu, by(grappe menage)
  sum hhsize
restore

tab1 s01q01 s01q02, m

rename s01q01 sexe
rename s01q02 lien
tab lien, m

tab1 s01q11 s01q12 s01q13, m

gen resid=0
replace resid=1 if s01q12==1 | (s01q12==2 & s01q13==1)
lab def ouinon 1"Oui" 0"Non"
lab val resid ouinon

tab resid s01q11, m
tab resid s01q12, m
tab lien resid, m

gen cm=(lien==1)
egen ncm=total(cm), by(grappe menage)
gen flag=(ncm!=1)
list grappe menage numind ncm lien if flag==1 
drop flag ncm cm

gen flag=(lien==1 & resid!=1)
list grappe menage numind lien resid if flag==1 
drop flag

*** calcul de l'age utilisant les dates de naissance et celle debut enquete
tab1 s01q03a s01q03b s01q03c, m

replace s01q03a=15 if inlist(s01q03a,9999, ., .a, .b, .n) & !inlist(s01q03c, ., .a, .b, .n, 9999) /* impute day=15 if NR, but year valid */
replace s01q03b=6 if inlist(s01q03b, 9999, ., .a, .b, .n) & !inlist(s01q03c, ., .a, .b, .n, 9999) /* impute month=6, if NR but year valid */ 
replace s01q03a=30 if s01q03a==31 & inlist(s01q03b, 4, 6, 9, 11) /* corige le dernier jour des mois de trente jours */

** Convert date of birth in string
recode s01q03a (9999 .a .b .n =.)
recode s01q03b (9999 .a .b .n =.)
recode s01q03c (9999 .a .b .n =.)

tostring s01q03a, gen(nj) 
tostring s01q03b, gen(nm) 
tostring s01q03c, gen(na) 
egen dob=concat(nm nj na), punc(" ")
gen ddn=date(dob, "MDY") 
format ddn %tdMon_DD_CCYY 
list ddn in 1/30
list s00q23 in 1/30

** Convert date of survey
gen ea=substr(s00q23,1,4)
gen em=substr(s00q23,6,2)
gen ej=substr(s00q23,9,2)
egen dd1=concat(em ej ea)
gen dde=date(dd1, "MDY") 
format dde %tdMon_DD_CCYY 
list dde in 1/30

** compute age
gen age=int((dde-ddn)/365)
replace age=s01q04a if missing(age) 
sum age   /*   l'écart entre l'age de l'enquête et l'age calculé s'explique par la date de référence (01-janv pour survey contre date de la première visite) */

*
tab s01q07, m
clonevar mstat=s01q07
replace mstat=1 if age<10
tab mstat, m
			  
recode mstat (.a .b .n=.)
**** imputation du statut matrimonial selon l'âge
replace mstat=1 if mstat==. & age <=16
replace mstat=5 if mstat==. & age >=80  
replace mstat=2 if mstat==. & age==26 /* kondo ramata */

*
`sleeping_line' tab1 s01q14 s01q15 s01q16, m
clonevar religion=s01q14
clonevar nation=s01q15
`sleeping_line' clonevar ethnie=s01q16

tab religion resid, m
tab nation resid, m
`sleeping_line' tab ethnie resid, m

**** imputation de l'ethnie
`sleeping_line' egen ethm=mode(ethnie), by(grappe menage)
`sleeping_line' replace ethnie=ethm if missing(ethnie) & resid==1

gen agemar=s01q10

lab var sexe Genre
lab var age "Age en annees"
lab var lien "Lien de parente"
lab var mstat "Situation de famille"
lab var resid "Statut de résidence"
lab var religion Religion
lab var nation "Nationalité"
`sleeping_line' lab var ethnie Ethnie
lab var agemar "Age premier marriage"

lab var ej "jour de l'interview"
lab var em "mois de l'interview"
lab var ea "année de l'interview"
tab1 ej em ea, m
destring ej em ea, replace

`sleeping_line' tab1 sexe lien resid mstat religion nation ethnie, m
sum age agemar

******
******  Caracteristiques de l'education  **************************************
****** 

tab1 s02q01__1 s02q01__2 s02q01__3, m 
tab1 s02q02__1 s02q02__2 s02q02__3, m

gen alfab=(s02q01__1==1 & s02q02__1==1) | ///
          (s02q01__2==1 & s02q02__2==1) | ///
		  (s02q01__3==1 & s02q02__3==1) 
label var alfab "Alphabetisation"
label val alfab ouinon
tab alfab resid, m

gen scol=(s02q12==1)
lab var scol "Freq. ecole 2017/18"
lab val scol ouinon

clonevar educ_scol=s02q14
tab educ_scol scol, m
lab var educ_scol "Niv. educ. actuel"

recode s02q29 (.a .b .n=.)
gen educ_hi=s02q29+1 if s02q29>=1 & s02q29<.
replace educ_hi=1 if s02q29==. & scol==0
replace educ_hi=educ_scol+1 if educ_hi==. & scol==1
lab var educ_hi "Niv. educ. acheve"
lab def educl 1"Aucun" 2"Maternelle" 3"Primaire" 4"Second. gl 1" 5"Second. tech. 1" 6"Second. gl 2" ///
              7"Second. tech. 2" 8"Postsecondaire" 9"Superieur"
lab val educ_hi educl
tab educ_hi  scol, m

clonevar diplome=s02q33
recode diplome (. .a .b .n=0)
lab var diplome "Diplome plus eleve"

gen telpor=s01q36==1
gen internet=(s01q39__1==1 | s01q39__2==1 | s01q39__3==1 | s01q39__4==1 | s01q39__5==1)
lab var telpor "Individu a un telephone portable"
lab var internet "Individu a acces à internet"
lab val telpor internet ouinon

tab1 alfa scol educ_scol educ_hi diplome telpor internet, m 

******
******  Caracteristiques sante *************************************************
****** 

gen mal30j=(s03q01==1) 
replace mal30j=0 if mal30j==1 & s03q05==.
lab var mal30j "Prob. sante 30 dern. jours"
tab mal30j s03q05, m

gen con30j=1 if mal30j==1 & s03q05==1 
replace con30j=0 if mal30j==1 & s03q05!=1
lab var con30j "Consulte 30 dern. jours"

clonevar aff30j=s03q02
tab aff30j mal30j, m
lab var aff30j "probleme sante"

gen arrmal=(s03q03==1)
lab var arrmal "Arret d'activité pour maladie"

clonevar durarr=s03q04
lab var durarr "Durée de l'arrêt d'activité pour maladie"

gen moustiq=(s03q39==1 | s03q39==2)
lab var moustiq "Dormi moustiquire nuit dern."
lab val moustiq ouinon

gen couvmal=(s03q32==1)
lab var couvmal "Indivu avec une couverture maladie"
lab val arrmal couvmal ouinon

gen hos12m=s03q19==1
lab var hos12m "Hospitalisation 12 der. mois"

tab1 s03q41 s03q42 s03q43 s03q44 s03q45 s03q46, m  
tab1 s03q41 s03q42 s03q43 s03q44 s03q45 s03q46 if age>=5, m  

gen handit=((s03q41>=2 & s03q41<=4) | (s03q42>=2 & s03q42<=4) |  ///
             (s03q43>=2 & s03q43<=4) | (s03q44>=2 & s03q44<=4) |  ///
             (s03q45>=2 & s03q45<=4) | (s03q46>=2 & s03q46<=4)) &  ///
			 (age >= 5) 
replace handit=. if age<5

gen handig=((s03q41>=3 & s03q41<=4) | (s03q42>=3 & s03q42<=4) |  ///
             (s03q43>=3 & s03q43<=4) | (s03q44>=3 & s03q44<=4) |  ///
             (s03q45>=3 & s03q45<=4) | (s03q46>=3 & s03q46<=4)) &  ///
			 (age >= 5) 
replace handig=. if age<5

lab var handit "Handicap tout niveau"
lab var handig "Handicap majeur seul"
lab val mal30j con30j hos12m handit handig ouinon

tab1 mal30j con30j aff30j arrmal durarr moustiq couvmal hos12m handit handig, m

******
******  Caracteristiques du marché du travail *********************************
****** 

*** Participation et caracteristiques des emplois
gen activ7j=6 if age<5
replace activ7j=5 if age>=5
replace activ7j=1 if age>=5 & (s04q06==1 | s04q07==1 | s04q08==1 | s04q09==1) 
replace activ7j=1 if age>=5 & s04q11==1
replace activ7j=3 if age>=5 & s04q13==1 & s04q15==1
replace activ7j=4 if age>=5 & s04q13==1 & s04q15==2
replace activ7j=3 if age>=5 & activ7j==5 & s04q14==1 & s04q15==1
replace activ7j=4 if age>=5 & activ7j==5 & s04q14==1 & s04q15==2
replace activ7j=2 if age>=5 & activ7j==5 & s04q17==1 

lab var activ7j "Sit. activite 7 derniers jours"
lab def activl 1"Occupe" 2"Chomeur" 3"TF cherchant emploi" 4"TF ne cherchant pas" 5"Inactif" 6"Moins de 5 ans"
lab val activ7j activl
tab lien activ7j, m    

* prise en compte de la disponibilité de travailler
replace activ7j=5 if age>=5 & activ7j==2 & (s04q19==2 & s04q20==4)
tab lien activ7j if age>15, m

gen activ12m=4 if age<5
replace activ12m=3 if age>=5
replace activ12m=2 if activ7j==3 | activ7j==4
replace activ12m=1 if activ7j==1 
replace activ12m=1 if activ7j!=1 & s04q27==1
lab var activ12m "Sit. activite 12 derniers mois"
lab def activl2 1"Occupe" 2"Trav. fam." 3"Non occupe" 4"Moins de 5 ans"
lab val activ12m activl2
tab lien activ12m, m    

gen branch=s04q30d /* if activ==1 */
lab var branch "Branche activite empl. prin."

recode branch (11/23=1) (31/53=2) (100/143=3) (151/410=4) (451/457=5) (503/526=6) ///
              (551/560=7) (601/649=8) (801/853=9) (930=10) ///
			  (501/502 527 650/760 900/924 940/990=11) 
lab def brl 1"Agriculture" 2"Elevage/peche" 3"Indust. extr." 4"Autr. indust." 5"BTP" ///
            6"Commerce" 7"Restaurant/Hotel" 8"Trans./Comm." 9"Education/Sante" ///
			10"Services perso." 11"Aut. services" 
lab val branch brl
tab branch activ12m, m /* il y a 3 cas avec ND, on impute */

replace branch=1 if branch==. & activ12m==1 & milieu==2
replace branch=6 if branch==. & activ12m==1 & milieu==1
tab branch activ12m, m 

clonevar sectins=s04q31
lab var sectins "Sect. institutionnel empl. prin."
tab sectins activ12m, m /* il y a 1 cas avec ND, on impute */
replace sectins=3 if sectins==.a & activ12m==1
tab sectins activ12m, m 
/* voir les 15 domestiques du ménage ayant pour employeur entreprise privé */

clonevar csp=s04q39
lab var csp "CSP empl. prin."
tab csp activ12m, m /* il y a 0 cas avec ND, on impute */

replace csp=8 if csp==. & activ12m==1 & lien!=1
replace csp=9 if csp==. & activ12m==1 & lien==1

tab csp activ12m, m 

replace csp=8 if csp==.a
tab csp sectins if activ12m==1, m
tab csp sectins if activ12m==2, m

tab1 activ7j activ12m branch sectins csp, m 
tab em, m

*** Volume horaire de travail et salaires

sum s04q32 s04q33 s04q34 s04q36 s04q37 if activ12m==1
/* s04q32 : Nbre de mois d'exer de l'emploi
   s04q33 : Congés payés
   s04q34 : Nbre de jrs de congés
   s04q36 : Nbre de jours consacrés habituellement à l'emploi
   s04q37 : Nbre d'heures habitelles consacrées à l'emploi
   csp dans l'emploi : s04q39
*/
egen med_s04q32=median(s04q32), by(csp)
count if s04q32==0 & activ12m==1  // Juste pour vérifier
replace s04q32=med_s04q32 if activ12m==1 & s04q32==0

egen med_s04q37=median(s04q37), by(csp)
count if s04q37==0 & activ12m==1  // Juste pour vérifier
replace s04q37=med_s04q37 if activ12m==1 & s04q37==0

tab s04q33 activ12m, m
gen conge=12*s04q34/360 if s04q33==1
replace conge=0 if s04q33==2
sum conge

gen moistrav=s04q32-conge
gen volhor=moistrav*s04q36*s04q37 if activ12m==1 
sum volhor 
lab var volhor "Horaire an. travail empl. prin."

sum s04q43 s04q43_unite s04q44 s04q45 s04q45_unite s04q46 s04q47 s04q47_unite ///
    s04q48 s04q49 s04q49_unite if csp>=1 & csp<=6
*
recode s04q43 s04q45 s04q47 s04q49 (. .a=0)
local numb 43 45 47 49
foreach x of local numb {
  gen unite`x'=52 if s04q`x'_unite==1
  replace unite`x'=12 if s04q`x'_unite==2
  replace unite`x'=4 if s04q`x'_unite==3
  replace unite`x'=1 if s04q`x'_unite==4
  gen sal`x'=s04q`x'*unite`x'
}
*	
sum sal43 sal45 sal47 sal49 if csp>=1 & csp<=6	
recode sal43 sal45 sal47 sal49 (.=0)	
gen salaire=sal43+sal45+sal47+sal49 if csp>=1 & csp<=6
replace salaire=. if csp>=7
lab var salaire "Salaire an. empl. prin." 	
sum salaire

*** Caracteristiques emploi secondaire

gen emploi_sec=s04q50==1
lab var emploi_sec "A un emploi secondaire 12 mois"
lab val emploi_sec ouinon

clonevar sectins_sec=s04q53
lab var sectins_sec "Secteur instit. emploi sec."
tab sectins_sec emploi_sec, m 

clonevar csp_sec=s04q57
lab var csp_sec "CSP emploi sec."
tab csp_sec sectins_sec, m /* il y a 3 cas avec ND, on impute */

replace sectins_sec=3 if (sectins_sec==1 | sectins_sec==2) & (csp_sec==9)  /* 3 cas */
replace sectins_sec=3 if (sectins_sec==5) & (csp_sec==8 | csp_sec==9)  /* 7 cas */
tab csp_sec sectins_sec, m 

*** Volume horaire et salaire en emploi secondaire
sum s04q54 s04q55 s04q56 if emploi_sec==1
egen med_s04q54=median(s04q54), by(csp_sec)
replace s04q54=med_s04q54 if emploi_sec==1 & s04q54==0 /* il ya 0 cas */

replace s04q55=30 if s04q55==31 /* il ya 1 cas */
gen volhor_sec=s04q54*s04q55*s04q56 if emploi_sec==1 
sum volhor_sec 
lab var volhor_sec "Horaire an. travail emploi sec."
*
sum s04q58 s04q58_unite s04q59 s04q60 s04q60_unite s04q61 s04q62 s04q62_unite ///
    s04q63 s04q64 s04q64_unite if csp_sec>=1 & csp_sec<=6
*
recode s04q58 s04q60 s04q62 s04q64 (. .a=0)
local numb2 58 60 62 64
foreach x of local numb2 {
  gen unite`x'=52 if s04q`x'_unite==1
  replace unite`x'=12 if s04q`x'_unite==2
  replace unite`x'=4 if s04q`x'_unite==3
  replace unite`x'=1 if s04q`x'_unite==4
  gen sal`x'=s04q`x'*unite`x'
}
*
sum sal58 sal60 sal62 sal64 if csp_sec>=1 & csp_sec<=6
recode sal58 sal60 sal62 sal64 (.=0)	

gen salaire_sec=sal58+sal60+sal62+sal64 if csp_sec>=1 & csp_sec<=6
replace salaire_sec=. if csp_sec>=7
lab var salaire_sec "Salaire an. emploi sec." 	
sum salaire_sec

gen bank=(s06q01__1==1 | s06q01__2==1  | s06q01__3==1)
lab var bank "compte banque ou autre"
lab val bank ouinon
tab bank, m
*
merge m:1 grappe using "$datain_aux\ehcvm_ponderations_CIV2018.dta", keepusing(grappe hhweight)
*merge m:1 grappe using "$datain_aux\EHCVM_GrappeWeightData24Jan2020.dta", keepusing(grappe hhweight)

drop if _merge==2
drop _merge

lab var hhweight "Ponderation menage"

******
******   Sauvegarde fichier individuel ****************************************
****** 

// keep hhid numind vague grappe menage ej em ea ///
//      country year zae region departement sousprefecture milieu ///
//      hhweight resid sexe age lien mstat religion nation ethnie agemar ///
// 	 mal30j aff30j arrmal durarr con30j hos12m couvmal moustiq handit handig ///
// 	 alfa scol educ_scol educ_hi diplome telpor internet   ///
// 	 activ7j activ12m branch sectins csp ///
// 	 volhor salaire emploi_sec sectins_sec csp_sec volhor_sec salaire_sec bank 
keep hhid numind vague grappe menage ej em ea ///
     country year zae region departement  milieu ///
     hhweight resid sexe age lien mstat religion nation  agemar ///
	 mal30j aff30j arrmal durarr con30j hos12m couvmal moustiq handit handig ///
	 alfa scol educ_scol educ_hi diplome telpor internet   ///
	 activ7j activ12m branch sectins csp ///
	 volhor salaire emploi_sec sectins_sec csp_sec volhor_sec salaire_sec bank 


order country year hhid numind grappe menage hhweight ///
     vague zae region departement  ej em ea ///
     resid sexe age lien mstat religion nation  agemar ///
	 mal30j aff30j arrmal durarr con30j hos12m couvmal moustiq handit handig ///
	 alfa scol educ_scol educ_hi diplome telpor internet   ///
	 activ7j activ12m branch sectins csp ///
	 volhor salaire emploi_sec sectins_sec csp_sec volhor_sec salaire_sec bank 	 
	 
sort hhid numind
compress
des
sum
save "$dataout\ehcvm_individu_CIV2018.dta", replace 


*********************************** Chocs *************************************
use "$datain_men\s14_me_CIV2018.dta", clear 

sort grappe menage s14q01
destring grappe, replace
gen hhid=grappe*1000+menage 
sort hhid s14q01
gen sh_id_demo=(s14q01>=101 & s14q01<=103) & (s14q02==1)
gen sh_co_natu=((s14q01>=104 & s14q01<=108) | (s14q01>=120 & s14q01<=121)) & (s14q02==1)
gen sh_co_eco=(s14q01>=109 & s14q01<=111) & (s14q02==1) 
gen sh_id_eco=(s14q01>=112 & s14q01<=117) & (s14q02==1)
gen sh_co_vio=(s14q01==118 | s14q01==119) & (s14q02==1) 
gen sh_co_oth=(s14q01==122) & (s14q02==1)   

collapse (sum) sh_id_demo sh_co_natu sh_co_eco sh_id_eco sh_co_vio sh_co_oth, by(hhid) 
recode sh_id_demo sh_co_natu sh_co_eco sh_id_eco sh_co_vio sh_co_oth (0=0) (1/9=1) 
lab var sh_id_demo "Choc idio démographique"
lab var sh_co_natu "Choc covariant naturel"
lab var sh_co_eco "Choc covariant économique"
lab var sh_id_eco "Choc idio économique"
lab var sh_co_vio "Choc covariant violence"
lab var sh_co_oth "Autres Chocs"     

lab val sh_id_demo sh_co_natu sh_co_eco sh_id_eco sh_co_vio sh_co_oth ouinon  
tab1 sh_id_demo sh_co_natu sh_co_eco sh_id_eco sh_co_vio sh_co_oth , m 

sort hhid 
save "$dataout_temp\ehcvm_menage0_CIV2018.dta", replace 
*
*
****************************** Taille du cheptel *******************************
use "$datain_men\s17_me_CIV2018.dta", clear 

sort grappe menage s17q02 
destring grappe, replace
gen hhid=grappe*1000+menage 

sum s17q05
recode s17q05 (.=0)
gen grosrum=s17q05 if s17q02==1 | s17q02==4 | s17q02==5 | s17q02==6 
gen petitrum=s17q05 if s17q02==2 | s17q02==3 
gen porc=s17q05 if s17q02==7 
gen lapin=s17q05 if s17q02==8 
gen volail=s17q05 if s17q02==9 | s17q02==10 | s17q02==11 

collapse (sum) grosrum petitrum porc lapin volail, by(hhid)
sum grosrum petitrum porc lapin volail
lab var grosrum "Nbr gros ruminants"
lab var petitrum "Nbr petits ruminants"
lab var porc "Nbr porcs"
lab var lapin "Nbr lapins"
lab var volail "Nbr volailles"

merge 1:1 hhid using "$dataout_temp\ehcvm_menage0_CIV2018.dta"
drop _merge
sort hhid 
save "$dataout_temp\ehcvm_menage0_CIV2018.dta", replace 
*
*
****************************** Superficies agricoles **************************
use "$datain_men\s16a_me_CIV2018.dta", clear 

sort grappe menage s16aq02 s16aq03
destring grappe, replace
drop if s16aq02==. & s16aq03==. & s16aq04==.
gen hhid=grappe*1000+menage 
recode s16aq09a s16aq47 (.=0)
replace s16aq47=s16aq47/10000 if s16aq47>=116 & s16aq47<.  /* correction, erreur d'unité */ 
gen sup_dec=s16aq09a if s16aq09b==1
replace sup_dec=s16aq09a/10000 if s16aq09b==2
gen sup_mes=s16aq47
sum sup_dec if sup_dec>0 & sup_dec<.
sum sup_mes if sup_me>0 & sup_mes<.

gen fl0=(sup_dec>0 & sup_dec<.) & (sup_mes>0 & sup_mes<.)
gen fl1=(sup_dec>0 & sup_dec<.) & (sup_mes==0 | sup_mes==.)
gen fl2=(sup_dec==0 | sup_dec==.) & (sup_mes>0 & sup_mes<.)

tab1 fl0 fl1 fl2, m

clonevar numind=s16aq04
sort grappe menage numind 
merge m:1 grappe menage numind using "$dataout\ehcvm_individu_CIV2018.dta", ///
          keepusing(region milieu sexe age alfa educ_hi) 
drop if _merge==2
drop _merge
gen age2=age^2          
regress sup_mes sup_dec i.sexe age age2 i.educ_hi i.region i.milieu if fl0==1
predict sup_mes_pred if fl1==1, xb
sum sup_mes_pred if fl1==1
replace sup_mes_pred=0.1 if sup_mes_pred<0 /* deux cas avec prédiction négative */

gen superf=sup_mes if fl0==1 | fl2==1
replace superf=sup_mes_pred if fl1==1
sum superf

collapse (sum) superf, by(hhid)
sum superf
lab var superf "Superficie agricole"

merge 1:1 hhid using "$dataout_temp\ehcvm_menage0_CIV2018.dta"
drop _merge
sort hhid 
save "$dataout_temp\ehcvm_menage0_CIV2018.dta", replace 
*
*
*************************** Elements de confort *******************************
use "$datain_men\s12_me_CIV2018.dta", clear 

destring grappe, replace
gen hhid=grappe*1000+menage 
sort hhid s12q01
gen tv=s12q01==20 & s12q02==1
gen fer=s12q01==7 & s12q02==1
gen frigo=(s12q01==16 | s12q01==17) & (s12q02==1)
gen cuisin=s12q01==9 & s12q02==1
gen ordin=s12q01==37 & s12q02==1
gen decod=s12q01==22 & s12q02==1
gen car=s12q01==28 & s12q02==1

collapse (sum) tv fer frigo cuisin ordin decod car, by(hhid)
recode tv fer frigo cuisin ordin decod car (0=0) (1/9=1)

lab var tv "Menage a TV"
lab var fer "Menage a fer electrique"
lab var frigo "Menage a frigo/congel"
lab var cuisin "Menage a cuisiniere elec/gaz"
lab var ordin "Menage a ordinateur"
lab var decod "Menage a decodeur/antenne"
lab var car "Menage a voiture"
lab val tv fer frigo cuisin ordin decod car ouinon
tab1 tv fer frigo cuisin ordin decod car, m

merge 1:1 hhid using "$dataout_temp\ehcvm_menage0_CIV2018.dta"
drop _merge
sort hhid 
save "$dataout_temp\ehcvm_menage0_CIV2018.dta", replace 
*
*
*************************** Caractéristiques de logement ***********************
use "$datain_men\s11_me_CIV2018.dta", clear 

destring grappe, replace
gen hhid=grappe*1000+menage 
drop if hhid==.

recode s11q04 (1 3=1) (2 4=2) (5=3) (6/8=4), gen(logem)
lab def logeml 1"Proprietaire titre" 2"Proprietaire sans titre" 3"Locataire" 4"Autre"
lab var logem "Occupation logement"
lab val logem logeml
tab1 logem, m  /* Une valeur ND, à corriger */
gen mur=s11q19>=1 & s11q19<=4
gen toit=s11q20>=1 & s11q20<=3
gen sol=s11q21>=1 & s11q21<=2
lab var mur "Mur en materiaux definitifs"
lab var toit "toit en materiaux definitifs"
lab var sol "Sol en materiaux definitifs"
lab val mur toit sol ouinon
tab1 mur toit sol, m
*
gen eauboi_ss=(s11q27a>=1 & s11q27a<=4) | (s11q27a>=7 & s11q27a<=10) 
replace eauboi_ss=0 if (s11q27a==7 | s11q27a==8) & (s11q32!=1)
gen eauboi_sp=(s11q27b>=1 & s11q27b<=4) | (s11q27b>=7 & s11q27b<=10) 
replace eauboi_ss=0 if (s11q27b==7 | s11q27b==8) & (s11q32!=1)
lab var eauboi_ss "eau potable saison seche"
lab var eauboi_sp "eau potable saison pluie"
lab val eauboi_ss eauboi_sp ouinon
tab1 eauboi_ss eauboi_sp, m
*
gen elec_ac=s11q34==1
gen elec_ur=s11q38==1
gen elec_ua=s11q38==2 | s11q38==6
lab var elec_ac "Acces reseau electrique"
lab var elec_ur "Utilise elec. reseau"
lab var elec_ua "Utilise elec. solaire/groupe"
lab val elec_ac elec_ur elec_ua ouinon
tab1 elec_ac elec_ur elec_ua, m
*
gen ordure=s11q54>=1 & s11q54<=2
gen toilet=s11q55>=1 & s11q55<=7
gen eva_toi=s11q58>=1 & s11q58<=3
gen eva_eau=s11q60==1 | s11q60==2
lab var ordure "Déchets évacués sainement"
lab var toilet "Toilettes saines"
lab var eva_toi "Excréments évacués sainement"
lab var eva_eau "Eaux usées évacuées sainement"
lab val ordure toilet eva_toi eva_eau ouinon
tab1 ordure toilet eva_toi eva_eau, m 
lab var hhid "Identifiant menage"
*
keep hhid grappe menage logem mur toit sol eauboi_ss eauboi_sp elec_ac elec_ur elec_ua ///
     ordure toilet eva_toi eva_eau 
order hhid logem mur toit sol eauboi_ss eauboi_sp elec_ac elec_ur elec_ua ///
      ordure toilet eva_toi eva_eau 

merge 1:1 hhid using "$dataout_temp\ehcvm_menage0_CIV2018.dta"
drop _merge
compress
des
sort hhid 
save "$dataout_temp\ehcvm_menage0_CIV2018.dta", replace 
