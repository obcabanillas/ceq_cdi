# CEQ for Cote d'Ivoire

The repository contains the code to produce the CEQ for Cote d'Ivoire


# Index

  
# General outline of the folders

All the data files are in a One Drive Folder while this repository deals with code to produce the report: **data_raw**
(see C:\Users\wb434633\OneDrive - WBG\wb434633\fiscal_incidence\cote_d_ivory)

*Complete as project grows*

```
**GitHub repository**
├── do_files
│   ├── adofiles 
│



**One Drive**
├── Documentation
│
├── data_raw
│   ├── survey_data_2018
│   │   ├── Auxiliaire-Commune-Menage-Questionnaire        
│   │   ├── Combined (combines all modules)
│   │
│   ├── administrative_info 
│
├── data_out
│   ├──        
│
├── project_report
│
│
│



```

We expect that all the output files and auxiliary files being located at: 

# Sources of raw information 

There are three main sources of data

## 1.  Survey data: EHCVM 2018 

Contains the differnt survey modules: Auxiliere, Commune, and Menage. The Questionnaires are available in the folder

```
The files in the **folder Combined** have an aggregate of the data
    ├── ehcvm_conso_CIV2018.dta
    ├── ehcvm_individu_CIV2018.dta
    ├── ehcvm_menage_CIV2018.dta
    ├── ehcvm_welfare_CIV2018.dta (reproduces official poverty line)
```

## 2.  Adminstrative data

Following the CEQ guidelines we divide these files in two

### 2.1 Programs administrative data

[] Budget, number of beneficiaries/payers,   benefits per participant

### 2.2 Information about fiscal interventions

For specifics on each program see CEQ requirements [data_requirements](https://tulane.app.box.com/s/0rfftm6b01jpct2wx5j4pbpfii5yk112/file/847659550242)

[] Direct taxes 
[] Social contributions 
[] Direct transfers and subsidies
[] Indirect taxes
[] Education
[] Health

### 2.3 Executed budget for the General Government

With information about revenues and expenditures for the year of the analysis, making explicit if it refers to the General, Central or other government unit.



# Data Cleaning

Here we document the dofiles that take the info from **data_raw**. The format is a brief explanation and the child files it creates.

All intermediaty files export to data_out


```
Replicates the official poverty numbers
CIV_2018_POV_CALC.do
    ├── child_file_1
    ├── child_file_1
```

Also explain any adofiles


# Final report

The report is in the OneDrive folder **project_report**