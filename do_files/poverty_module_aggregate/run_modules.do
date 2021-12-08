
clear all
set trace off

global root = "C:\Users\wb434633\Documents\GitHub\ceq_cdi\"





*********************************************************************************
* Path
*********************************************************************************
global data "C:\Users\wb434633\Documents\GitHub\ceq_cdi\data_out_modules"
global datain_men "C:\Users\wb434633\OneDrive - WBG\wb434633\fiscal_incidence\cote_d_ivoire\data_raw\survey_data_2018/Menage"
global datain_aux "C:\Users\wb434633\OneDrive - WBG\wb434633\fiscal_incidence\cote_d_ivoire\data_raw\survey_data_2018/Auxiliaire"


* Make forlders with outcomes
loc folders = "dataout_p dataout_nsu dataout_temp" 
foreach f of loc folders {
  cap mkdir "${data}/Dataout/`f'"
}

loc sleeping_line = "*"
*********************************************************************************
*********************************************************************************
*********************************************************************************
*********************************************************************************

/*
global datain "C:\Users\wb324658\OneDrive - WBG\FY18\CI\HDataCIV\Data_CIV\EHCVM032020\CIV\Datain"
global datain_men "$datain\Menage"
global datain_com "$datain\Commune"
global datain_aux "$datain\Auxiliaire"
*/
global dataout "$data\Dataout"
global dataout_p "$data\Dataout\dataout_p"
global dataout_nsu "$data\Dataout\dataout_nsu" 
global dataout_temp "$data\Dataout\dataout_temp"  
global datain_com "$datain_men\Commune"

global prog "${root}/do_files/poverty_module_aggregate/Programs"


** Load programs
include "${root}/do_files/EHCVM_civ_monprog.do"

*** Creation de fichiers NSU a differents niveaux geographiques
include "${root}/do_files/ehcvm_ci_pgm00_mars2020.do"

*** Lecture des fichiers au niveau individuel
include "${root}/do_files/ehcvm_ci_pgm01_mars2020.do"

*** fichier menage/produits/mode d'acquisition
*******Partie 1: Consommation alimentaire - Sections 7B, 7A et 9C*
*******Partie 2: Conso non-alim. monétaire - Sections 9b à 9f, 2, 3 et 11*
*******Partie 3: Valeur d'usage des biens durables - Section 12*
*******Partie 4: loyer impute (propro et gratuit) - Section 11*
*******Partie 5: Agrégat de consommation et quelques tests*
include "${root}/do_files/ehcvm_ci_pgm02_mars2020.do"
adasd555

"${root}/ehcvm_ci_pgm02_mars2020.do"
"${root}/ehcvm_ci_pgm03_mars2020.do"
"${root}/EHCVM_civ_monprog.do"




s01_co_CIV2018.dta in the Partie 4: loyer impute (propro et gratuit) - Section 11 is missing

s00q03 s00q05