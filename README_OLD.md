## Dofile that process Cote d'Ivoire survey individual modules

The dofiles were shared by Franck M. Adoho on November 9 2021


The files came with their own folder data structure. I added the *run_modules.do* dofile that runs them in order.
- I added to this dofile the general paths that used to be in the individual do files. This makes that the do file shave to be run sequentially 

```
**Gitub**
├── ceq_cdi
│   ├── do_files
│   │   ├── Programs
│   │   ├── Menage poverty_module_aggregate
│   │       ├── run_modules.do
│   │           ├── EHCVM_civ_monprog.do
│   │           ├── ehcvm_ci_pgm00_mars2020.do
│   │           ├── ehcvm_ci_pgm01_mars2020.do
│   │           ├── ehcvm_ci_pgm02_mars2020.do
│   │           ├── KEEP GOING AS I FINISH CHECKING
│   │           ├── 
│   │
│   ├── Dataout (all processed data) (NOT PUBLIC)
│   │   ├── dataout_nsu (non-standard units)
│   │   ├── dataout_p
│   │   ├── dataout_temp



**OneDrive (not public)**
│   ├── data_raw
│   │   ├── survey_data_2018
│   │   │   ├── Menage
│   │   │   ├── Auxiliare
│



```


### 0. EHCVM_civ_monprog.do

Has several programs defined

The program asks variable s00q03 that is not in the dataset s00_me_CIV2018

#### 1. ehcvm_ci_pgm00_mars2020.do 

*Creation de fichiers NSU a differents niveaux geographiques*

**Calculates local prices and unit prices**

The files came with their own folder data structure

```
Creates:
- Exports to ${dataout_nsu}
    - ehcvm_nsu_*_CIV2018

- Exports to ${dataout_p}
  - ehcvm_pu_*_CIV2018_unit
  - mode_nat_ag_max
  - mode_nat_max
  - mode_*_vague_max   
  - ehcvm_pu_*_CIV2018_mode
  - ehcvm_pu_merge_CIV2018_mode
```

Files needed:
- nsu2017_civ_releve_corr.dta but ehcvm_nsu_CIV2018_19 seems to work but it is called ehcvm_nsu_CIV2018

### 2. ehcvm_ci_pgm01_mars2020.do

*Lecture des fichiers au niveau individuel*
**ehcvm_individu_CIV2018.dta y  ehcvm_menage_CIV2018.dta**

Datsets renamed to drop _19

```
Creates:
- Exports to ${dataout_temp}
    - ehcvm_individu_CIV2018.dta
    - ehcvm_menage0_CIV2018.dta
    - ehcvm_menage0_CIV2018.dta	
    - ehcvm_menage0_CIV2018.dta
    - ehcvm_menage0_CIV2018.dta
    - ehcvm_menage0_CIV2018.dta

- Exports to ${dataout}
    - ehcvm_individu_CIV2018.dta
```

### 3. ehcvm_ci_pgm02_mars2020.do

*Partie 1: Consommation alimentaire - Sections 7B, 7A et 9C*

```
Creates:
- Exports to ${dataout_temp}
    - ehcvm_men_temp.dta
    - Dep_Alim1.dta
    - Dep_Alim2.dta
    - Dep_Alim3.dta
    - Dep_Fetes.dta
    - Cor_Dep_Alim.dta
    - Dep_Alim_Sans_Cor.dta
    - Dep_Alim.dta
```

*Partie 2: Conso non-alim. monétaire - Sections 9b à 9f, 2, 3 et 11*

```
Creates:
- Exports to ${dataout_temp}
    - s09*.dta
    - Dep_Nalim_S9.dta
    - Dep_Tmob.dta
    - Dep_Educ.dta
    - Dep_Sante.dta
    - Dep_Logement.dta
    - Dep_Nalim_Sans_Cor.dta
    - Dep_Nalim.dta
```

*Partie 3: Valeur d’usage des biens durables - Section 12*

```
Creates:
- Exports to ${dataout_temp}
    - Dep_Bdur_Sans_Cor.dta
    - Dep_Bdur4model.dta
    - Dep_Bdur.dta
```

*Partie 4: loyer impute (propro et gratuit) - Section 11*

```
Creates:
- Exports to ${dataout_temp}
    - Infra_com.dta
    - s11_me_CIV2018.dta
    - Loyer.dta
    - Dep_Loyer.dta
```

*Partie 5: Agrégat de consommation et quelques tests*

```
Creates:
- Exports to ${dataout_temp}
    - Infra_com.dta
    - s11_me_CIV2018.dta
    - Loyer.dta
    - Dep_Loyer.dta
```
