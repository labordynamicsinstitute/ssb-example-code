
/*  
This file serves as a shell file for using SRMI (via IVEware) to complete the data and
        create replicate weights. This file keeps the needed variables from the SSB/GSF
        and then calls the SRMI and replicate weight programs

The user must specify 2 things:
        1) paths to the SSB/GSF input data ("inputs"), user data folder ("mydata"),
		user programs folder ("prorgrams"), dataset name, and number of 
		replicates
        2) the variables to keep from the SSB/GSF to be used in the SRMI program
        ***NOTE: The program "SRMI" called below and the imputeSSB.set file it calls 
		need to be edited according to the
                imputation settings desired by the user. The other program,
                genRepweights, does not need to be edtied.


STEPS:
        1) keep the SSB variables needed for the application
        2) call the SRMI program, which imputes the data and then
                specifies post-imputation variable relationships
        3) call the replicate weight generation program


Input files: 4 synthetic SSB files/1 GSF file
Output files: multiply-imputed SSB/GSF data, with replicate weights
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
global replicates 4 /* "4" for synthetic data, "1" for internal */
*Set IVEware use: path to srclib folder where IVEware Stata commands are saved
global srclib "/rdcprojects/co/co00517/SSB/programs/ssb-example-code/srclib/v3/stata/"





*loop through data files
forvalues k=1/$replicates {
global k `k'
/*
1. SPECIFY VARIABLES TO KEEP FROM SSB/GSF AND HAVE IMPUTED WITH SRMI
*/
***USER MUST EDIT THE VARIABLES THEY WANT TO KEEP***
if "$replicates"=="4" {
use ${inputs}/${dataname}${k}.dta, clear
keep personid male race hispanic foreign_born birthdate total_der_fica* educ_5cat state panel ///
	sipp_panel_beg_date initwgt halfsamp varstrat
save ${mydata}/srmi_input${k}.dta, replace
}
if "$replicates"=="1" {
use ${inputs}/${dataname}.dta, clear
keep personid male race hispanic foreign_born birthdate total_der_fica* educ_5cat state panel ///
	sipp_panel_beg_date initwgt halfsamp varstrat
save ${mydata}/srmi_input${k}.dta, replace
}




/*
2. SEND VARIABLES INTO SRMI PROGRAM TO BE IMPUTED, THEN IMPOSE POST-IMPUTATION RELATIONSHIPS
*/
do ${programs}/srmi.do





/*
3. SEND VARIABLES INTO REPLICATE WEIGHTS GENERATION PROGRAM
*/
clear
do ${programs}/genRepWeightsSRMI.do


}



