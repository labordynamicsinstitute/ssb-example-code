/*
This program serves as a shell file for creating replicate weights and raking. This file
        specifies the year(s) to which weights will be raked and prepares the control
        data for raking, specifies the variables from the SSB/GSF needed for the
        application and keeps only the available cases ("pairwise deletion"), then 
	calls the programs to create replicate weights and rake the weights.


The user must specify 3 things:
        1) paths to the SSB input data ("inputs"), user data folder ("mydata"), user 
		programs ("programs"), dataset name, and number of replicates
        2) the year(s) to which the weights will be raked
        3) the variables and sample to be used in the analysis
        ***NOTE: None of the other files called within this file (prepPopControlTotals,
                genRepweights, raking) needed be edited. The only exception is if the
                user wants to change the convergence parameters in the raking program.


STEPS:
        1) specify the paths to the SSB/GSF data and user data folder
        2) specify the year(s) to which population totals will be raked and call the program
                that prepares the data for raking
          ***NOTE: because this application uses individuals from many SIPP panels, each
                panel must be raked individually; that is, each panel is independently
                raked such that marginal population totals for the given panel are
                representative of the U.S. population totals at that point in time
        3) specify the SSB/GSF variables needed for the analysis and keep only the available cases
        4) call the replicate weights generation program
        5) call the program to rake the initial and replicate weights


Input files: population control data, SSB/GSF data files
Output files: available-case dataset of SSB/GSF variables for each data file, with
        raked replicate and initial weights
*/


/*
SET PATHS FOR SSB/GSF DATA AND USER DATA FILES
*/
***USER MUST EDIT THESE SETTINGS***
global base /rdcprojects/co/co00517/SSB
global version v7.0
global myid specXXX

global programs "${base}/programs/users/${myid}/example/programs"
global mydata "${base}/programs/users/${myid}/example/mydata"
global inputs "${base}/data/${version}"

global dataname ssb_v7_0_synthetic /* ssb_v7_0_synthetic for SSB, ssb_v7_0_gsf_snapshot for GSF */
global replicates 4 /*  "4" for synthetic data, "1" for internal GSF */





/*
1. SPECIFY THE YEAR TO WHICH THE WEIGHTS WILL BE RAKED AND CALL THE PROGRAM THAT WILL
        RE-FORMAT CONTROL POPULATION DATA FOR USE WITH RAKING 
NOTE: this process should be performed for each SIPP panel included in the analysis
NOTE: population control data is the SEER population data from the NBER website. This
	provides annual population data by detailed state and demographic characteristics
	beginning in 1990
*/
local years 1990 1991 1992 1993 1996 2001 2004 2008
foreach year of local years {
global year `year'
do ${programs}/prepPopControlTotals.do
}





*loop through data files
forvalues k=1/$replicates {
global k `k'
/*
2. SPECIFY THE VARIABLES TO KEEP FROM SSB/GSF AND KEEP ONLY THE AVAILABLE CASES FOR RAKING
*/
***THE USER MUST SPECIFY THE VARIABLES TO BE KEPT***
if "$replicates"=="4" {
use ${inputs}/${dataname}${k}.dta, clear
gen no_miss = !missing(personid, male, race, hispanic, foreign_born, birthdate, ///
	mbr_ssdi_ddo_1, mbr_ssdi_dsd_1, mbr_ssdi_dig_group_1, ///
	educ_5cat, state, panel, sipp_panel_beg_date, initwgt, halfsamp, varstrat)
keep if no_miss==1 & panel>=1990
save ${mydata}/ssb_available${k}.dta, replace
}
if "$replicates"=="1" {
use ${inputs}/${dataname}.dta, clear
gen no_miss = !missing(personid, male, race, hispanic, foreign_born, birthdate, ///
	mbr_ssdi_ddo_1, mbr_ssdi_dsd_1, mbr_ssdi_dig_group_1, ///
	educ_5cat, state, panel, sipp_panel_beg_date, initwgt, halfsamp, varstrat)
keep if no_miss==1 & panel>=1990
save ${mydata}/ssb_available${k}.dta, replace
}




/*
3. CREATE REPLICATE WEIGHTS
*/
do ${programs}/genRepWeights.do





/*
4. RAKE THE INITIAL WEIGHT AND REPLICATE WEIGHTS
*/
local years 1990 1991 1992 1993 1996 2001 2004 2008
foreach year of local years {
global year `year'
do ${programs}/raking.do
}

*append all of the raked panels into one datset
use ${mydata}/ssb_available_repw_rake${k}1990.dta, clear
append using ${mydata}/ssb_available_repw_rake${k}1991.dta ///
	${mydata}/ssb_available_repw_rake${k}1992.dta ///
	${mydata}/ssb_available_repw_rake${k}1993.dta ///
	${mydata}/ssb_available_repw_rake${k}1996.dta ///
	${mydata}/ssb_available_repw_rake${k}2001.dta ///
	${mydata}/ssb_available_repw_rake${k}2004.dta ///
	${mydata}/ssb_available_repw_rake${k}2008.dta, gen(_appendYears)
save ${mydata}/ssb_available_repw_rake${k}.dta, replace

}


