# CEQ for Cote d'Ivoire

The repository contains the code to produce the CEQ for Cote d'Ivoire


# Index

  
# General outline of the folders

All the data files are in a One Drive Folder while this repository deals with code to produce the report: **data_raw**
(see C:\Users\wb434633\OneDrive - WBG\wb434633\fiscal_incidence\cote_d_ivoire)

*Complete as project grows*

```
**GitHub repository**
├── do_files
│   ├── adofiles 
│



**One Drive**
├── Documentation (CEQ manuals)
│
├── data_raw
│   ├── survey_data_2018
│   │   ├── datasets: Auxiliaire-Commune-Menage-Questionnaire        
│   │   ├── Combined (all modules combined)
│   │
│   ├── administrative_info 
│
│
├── workbooks
│
│
├── data_out
│   ├── intermediary        
│   │
│   │
│   │
│   ├── final        
│
├── project_report
│   ├──        
│
│


```

We expect that all the output files and auxiliary files being located in the OneDrive to avoid overrunning the GitHub repository space limits.

# Sources of raw information 

There are three main sources of data

## 1.  Survey data: EHCVM 2018 

Contains the differnt survey modules: Auxiliere, Commune, and Menage. The Questionnaires are available in the folder

The file ddi-documentation-french-45.pdf in documentations details the content of each module (pages 1-3)
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

**Direct taxes**

    1.[]	A list of existing tax regimes.
    2.[]	Whether an individual can choose a specific tax regime or the individual is obliged to pay under a specific tax regime.
    3.[]	The characteristics that must be met for someone to fall under a specific tax regime. 
    4.[]	Income tax rates and bands, and existing allowances by tax regime are necessities. 
    5.[]	Information on tax evasion, such as the characteristics of individuals who do not pay taxes. For example, one common characteristic of individuals who do not pay taxes is that they work in the informal sector. 
    6.[]	Estimation of Tax Expenditures.

**Social contributions**

    1.[]	A list of existing social security systems.
    2.[]	Whether an individual can choose a specific social security system or the individual is obliged to be affiliated with a specific social security system.
    3.[]	The characteristics that must be met for someone to fall under a specific social security system.
    4.[]	Income rates that affiliated must pay by service covered by the social security system. Contributions to pensions need to be estimated separately from health, unemployment, etc.  

**Direct transfers and subsidies**

    1.[] A list of existing direct transfers and subsidies.
    2.[] The conditions that need to be met for someone to be beneficiary. 
    3.[] Identify whether the beneficiary is an individual or a household. 
    4.[] The targeting mechanisms used to select the beneficiaries. 
    5.[] Amount of the benefit if it is fixed or how the amount is determined if it is variable. 
    6.[] In the case of subsidies, it is important to know if it subsidizes the supply or the demand. 

**Indirect taxes**

    1.[]	Value added and excises tax rates.
    2.[]	Existing exemptions. 
    3.[]	Estimation of tax expenditures.
    4.[]	Information on tax evasion. 
    5.[]	If the main survey used for constructing the CEQ Income concepts does not have information on consumption you will need a secondary source. Please see Chapter 6 of this handbook. 
    6.[]	Input-output table, SAM (Social Accounting Matrix), or SUT (Supply and Use table) for estimating indirect effects. For more details about Indirect Effects see Chapter 7 of this Handbook. 

**Education**

    1.[]	Information on what type of schools receive resources from the government, if it is only public schools, semi private schools, and/or private schools.
    2.[]	Information on co-pays.
    3.[]	If the survey does not report who attends public schools, then individual characteristics that allow the identification of which individuals are more likely to attend a public school is necessary. 

**Health**

    1.[]	Information on existing health systems. 
    2.[]	Information on what health systems receive resources from the government.
    3.[]	Information on usage.
    4.[]	Information on co-pays or other payments from households that are required to access public health services. Additionally, information on spending channeled through health insurance schemes, including the payments by households to participate in these schemes are desirable. 

### 2.3 Executed budget for the General Government

With information about revenues and expenditures for the year of the analysis, making explicit if it refers to the General, Central or other government unit.


# Do files guide

## Imputations 

**Labor**
describe why, method, and challenges

## Data Cleaning

Here we document the dofiles that take the info from **data_raw**. For each do file, provide a brief explanation of what it does, the input files it uses and what files it creates (child files).

All intermediaty files export to **data_out**

Also explain any adofiles

```
Replicates the official poverty numbers
CIV_2018_POV_CALC.do
    ├── child_file_1
    ├── child_file_1

Uses information from : 
```

```
Description
.do
    ├── child_file_1
    ├── child_file_1

Uses information from : 
```


## Additional data processing 

# Final report

The report is in the OneDrive folder **project_report**