/*
This program uses IVEWARE to multiply impute the SSB based on SRMI


input files: 1) synthetic SSB data files with variables specified in the master file
output files: 1) completed synthetic SSB implicates (number of multiples per synthetic
        SSB file specified in the imputation settings below

User must specify 2 things:
        1) IVEWare model settings [these are specified in the imputeSSB.set file, which 
		is called below]
        2) Post-imputation variable relationships

STEPS:
        1) RUN IVEWARE - use the IVEware command "IMPUTE" to impute missing values based
                on SRMI
        2) GENERATE STRUCTURALLY MISSING FLAGS - will be used in next step to return
                structurally missing values
        3) EXTRACT IMPLICATES, RETURN STRUCTURALLY MISSING VALUES, IMPOSE POST-IMPUTATION
                RELATIONSHIPS - IVEware imputes both . and .Z variables. This step
                merges the flags from step 2 onto the completed implicates, and then returns
                the . values for the structurally missing observations, based on these flags
*/



/*
1. RUN IVEWARE
*/
***THE IMPUTATION MODEL SETTINGS ARE SPECIFIED IN THE imputeSSB.set FILE, WHICH THE USER MUST EDIT
global name "imputeSSB"
do ${srclib}/impute





/*
2. CREATE INDICATOR VARIABLES FOR MISSING TYPES
*/
* create structurally-missing flag to return structurally missing values - this does not need to be edited
use ${mydata}/srmi_input${k}.dta, clear
foreach var of varlist _all {
	gen SMISS`var'=0
	replace SMISS`var'=1 if `var'==.
	gen MISS`var'=0
	replace MISS`var'=1 if `var'==.z
	}
keep personid SMISS* MISS*
save ${mydata}/srmi_flags${k}.dta, replace
clear





/*
3. EXTRACT COMPLETED IMPLICATES, RETURN STRUCTURALLY-MISSING VALUES, AND IMPOST-POST-IMPUTATION 
*/
* loop through and extract each of the implicates, merge the missing flags, and return structurally missing values
forvalues m = 1/4 {
	global m `m'
	global mult "${m}"
	global dataout "../mydata/ssb_imputed${k}_${m}"
	do "${srclib}/putdata"


use ${mydata}/ssb_imputed${k}_${m}, clear

unab all: _all

merge 1:1 personid using "${mydata}/srmi_flags${k}.dta", gen(_mergeFlags)

foreach var of local all {
        replace `var'=. if SMISS`var'==1
}

save ${mydata}/ssb_imputed${k}_${m}.dta, replace

*loop through completed implicates and impost post-imputation relationships
format birthdate %td
format sipp_panel_beg_date %td
gen birthyear=year(birthdate)
gen sipp_panel_year=year(sipp_panel_beg_date)
gen start_age=sipp_panel_year-birthyear
replace educ_5cat=. if start_age<15 & SMISSeduc_5cat==0

*drop the flag variables
drop SMISS* MISS* 
save ${mydata}/ssb_imputed${k}_${m}.dta, replace

}


