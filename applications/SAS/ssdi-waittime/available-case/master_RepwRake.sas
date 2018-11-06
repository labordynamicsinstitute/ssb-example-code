
/*/ 
This file serves as a shell file for creating replicate weights and raking. This file 
	specifies the year(s) to which weights will be raked and prepares the control 
	data for raking, specifies the variables from the SSB/GSF needed for the 
	application and keeps only the available cases, then calls the files to create 
	replicate weights and rake the weights 
/*/ 


/*/
The user must specify 3 things: 
	1) paths to the input data and user data folder
	2) the year(s) to which the weights will be raked
	3) the variables and sample to be used in the analysis
	***NOTE: None of the other files called within this file (prepPopControlTotals,
		genRepweights, raking) needed be edited. The only exception is if the 
		user wants to change the convergence parameters in the raking program)
/*/


/*/ 
STEPS:
	1) specify the year(s) to which population totals will be raked and call the file 
		that prepares the data for raking
	  ***NOTE: because this application uses individuals from many SIPP panels, each
		panel must be raked individually; that is, each panel is independently 
		raked such that marginal population totals for the given panel are 
		representative of the U.S. population totals at that point in time
	2) specify the variables needed for the analysis and keep only the available cases
	3) call the replicate weights generation file
	4) call the file to rake the initial and replicate weights
/*/


/*/
Input files: population control data, 4 synthetic SSB files/1 GSF file
Output files: available-case dataset of variables for each data file, with 
	raked replicate and initial weights
/*/





/*/ SET PATHS FOR SSB/GSF DATA AND USER DATA FILES /*/
***USER MUST SPECIFY THESE LOCATIONS***;
%let base=/rdcprojects/co/co00517/SSB;
%let version=v7.0;
%let myid=specXXX;

libname inputs "&base./data/&version." access=readonly;
libname mydata "&base./programs/users/&myid./examples/mydata";

%let dataname=ssb_v7_0_synthetic; *ssb_v7_0_synthetic for SSB, ssb_v7_0_gsf_snapshot for GSF;
%let replicates=4; *"4" for SSB data, "1" for internal GSF;




/*/ 1. SPECIFY THE YEAR TO WHICH THE WEIGHTS WILL BE RAKED AND CALL THE PROGRAM THAT WILL 
	RE-FORMAT CONTROL POPULATION DATA FOR USE WITH RAKING /*/
*NOTE: this process should be performed for each SIPP panel included in the analysis;
*NOTE: population control data is the SEER population data from the NBER website. This;
*	provides annual population data by detailed state and demographic characteristics;
*	beginning in 1990.;
%let year=1990;
%include "prepPopControlTotals.sas";
%let year=1991;
%include "prepPopControlTotals.sas";
%let year=1992;
%include "prepPopControlTotals.sas";
%let year=1993;
%include "prepPopControlTotals.sas";
%let year=1996;
%include "prepPopControlTotals.sas";
%let year=2001;
%include "prepPopControlTotals.sas";
%let year=2004;
%include "prepPopControlTotals.sas";
%let year=2008;
%include "prepPopControlTotals.sas";





*loop through data files;
%macro loops(n);
%do k=1 %to &n;

/*/ 2. SPECIFY THE VARIABLES TO KEEP FROM SSB/GSF AND KEEP ONLY THE AVAILABLE CASES FOR RAKING /*/
***THE USER MUST SPECIFY THE VARIABLES TO BE KEPT***;
%if &replicates.=4 %then %do;
data mydata.ssb_availablecase&k.;
set inputs.&dataname.&k.(keep=personid male race hispanic foreign_born birthdate
        mbr_ssdi_ddo_1 mbr_ssdi_dsd_1 mbr_ssdi_dig_group_1 educ_5cat state panel
        sipp_panel_beg_date initwgt halfsamp varstrat
	where=(panel>=1990));
run;
%end;
%if &replicates.=1 %then %do;
data mydata.ssb_availablecase&k.;
set inputs.&dataname.(keep=personid male race hispanic foreign_born birthdate
        mbr_ssdi_ddo_1 mbr_ssdi_dsd_1 mbr_ssdi_dig_group_1 educ_5cat state panel
        sipp_panel_beg_date initwgt halfsamp varstrat
	where=(panel>=1990));
run;
%end;

*keep only the available cases. i.e., drop individuals with missing data;
data mydata.ssb_availablecase&k.;
set mydata.ssb_availablecase&k.;
if nmiss(of _NUMERIC_)=0;
run;




/*/ 3. CREATE REPLICATE WEIGHTS /*/
%include "genRepweights.sas";





/*/ 4. RAKE THE INITIAL WEIGHT AND REPLICATE WEIGHTS /*/
%let year=1990;
%include "raking.sas";
%let year=1991;
%include "raking.sas";
%let year=1992;
%include "raking.sas";
%let year=1993;
%include "raking.sas";
%let year=1996;
%include "raking.sas";
%let year=2001;
%include "raking.sas";
%let year=2004;
%include "raking.sas";
%let year=2008;
%include "raking.sas";

*append all of the raked panels into one dataset;
data mydata.ssb_available_repw_rake&k.;
set ssb_available_repw_rake&k.1990
        ssb_available_repw_rake&k.1991
        ssb_available_repw_rake&k.1992
        ssb_available_repw_rake&k.1993
        ssb_available_repw_rake&k.1996
        ssb_available_repw_rake&k.2001
        ssb_available_repw_rake&k.2004
        ssb_available_repw_rake&k.2008;
run;



%end;
%mend loops;
%loops(&replicates.);


