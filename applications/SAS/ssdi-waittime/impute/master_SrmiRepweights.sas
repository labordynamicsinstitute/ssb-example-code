
/*/ 
This file serves as a shell file for using SRMI (via IVEware) to complete the data and
        create replicate weights. This file keeps the needed variables from the SSB/GSF
        and then calls the SRMI and replicate weight programs 
/*/

/*/ 
The user must specify 2 things: 
	1) paths to the input data and user data folder, dataset name, and 
		number of replicates
	2) the variables to keep from the data to be used in the SRMI program  
	***NOTE: The program "SRMI" called below needs to be edited according to the 
		imputation settings desired by the user. The other program, 
		genRepweights, does not need to be edtied.
/*/


/*/ 
STEPS:
	1) keep the variables needed for the application
	2) call the SRMI program, which imputes the data and then
		specifies post-imputation variable relationships
	3) call the replicate weight generation program
/*/ 


/*/
Input files: 4 synthetic SSB files/1 internal GSF file
Output files: multiply-imputed SSB/GSF data, with replicate weights
/*/





/*/ SET PATHS FOR SSB/GSF DATA AND USER DATA FILES /*/
***USER MUST EDIT THESE SETTINGS***;
%let base=/rdcprojects/co/co00517/SSB;
%let version=v7.0;
%let myid=specXXX;

libname inputs "&base./data/&version." access=readonly;
libname mydata "&base./programs/users/&myid./examples/mydata";

%let dataname=ssb_v7_0_synthetic; *ssb_v7_0_synthetic for SSB, ssb_v7_0_gsf_snapshot for GSF;
%let replicates=4; *"4" for synthetic data, 1 for internal;
*Set IVEware use: path to srclib folder where IVEware SAS commands are saved and sasautos line;
options set = SRCLIB ''
        sasautos = ('!SRCLIB' '!SASROOT/sasautos') mautosource;





*loop through data files;
%macro loops(n);
%do k=1 %to &n;

/*/ 1. SPECIFY VARIABLES TO KEEP FROM SSB/GSF AND HAVE IMPUTED WITH SRMI /*/
***USER MUST EDIT THE VARIABLES THEY WANT TO KEEP***;
%if &replicates.=4 %then %do;
data mydata.srmi_input&k.;
set inputs.&dataname.&k.(keep=personid male race hispanic foreign_born birthdate
        mbr_ssdi_ddo_: mbr_ssdi_dsd_: mbr_ssdi_dig_group_: educ_5cat state panel
        sipp_panel_beg_date initwgt halfsamp varstrat);
run;
%end;
%if &replicates.=1 %then %do;
data mydata.srmi_input&k.;
set inputs.&dataname.(keep=personid male race hispanic foreign_born birthdate
        mbr_ssdi_ddo_: mbr_ssdi_dsd_: mbr_ssdi_dig_group_: educ_5cat state panel
        sipp_panel_beg_date initwgt halfsamp varstrat);
run;
%end;

*(this code is needed to make use of the srmi model macros below in the srmi.sas program - it does not need to be edited);
data mydata.srmi_input_temp;
set mydata.srmi_input&k.;
run;
proc sql noprint;
%let varlist=;
select name
	into :varlist separated by ' '
from dictionary.columns
where libname='MYDATA'
	and memname='SRMI_INPUT_TEMP'
;
quit;





/*/ 2. SEND VARIABLES INTO SRMI PROGRAM TO BE IMPUTED, THEN IMPOSE POST-IMPUTATION 
	RELATIONSHIPS /*/
%include "srmi.sas";





/*/ 3. SEND VARIABLES INTO REPLICATE WEIGHTS GENERATION PROGRAM /*/
%include "genRepweightsSRMI.sas";



%end;
%mend loops;
%loops(&replicates.);


