
/*/ 
This file uses IVEWARE to multiply impute the SSB based on SRMI 
/*/


/*/
input files: 1) 4 files of synthetic SSB variables specified in the master file
output files: 1) completed synthetic SSB implicates (number of multiples per synthetic 
	SSB file specified in the imputation settings below - total output files 
	equals 4*multiples)
/*/

/*/
User must specify 2 things:
	1) IVEWare model settings
	2) Post-imputation variable relationships
/*/

/*/ 
STEPS:
	1) RUN IVEWARE - use the IVEware command "IMPUTE" to impute missing values based 
		on SRMI
	2) GENERATE STRUCTURALLY MISSING FLAGS - will be used in next step to return 
		structurally missing values
	2) EXTRACT IMPLICATES, RETURN STRUCTURALLY MISSING VALUES, IMPOSE POST-IMPUTATION 
		RELATIONSHIPS - IVEware imputes both . and .Z variables. This step 
		merges the flags from step 1 onto the completed implicates, and then returns 
		the . values for the structurally missing observations, based on these flags
/*/





/*/ 1. RUN IVEWARE /*/
***USER MUST EDIT THESE MODEL SETTINGS TO THEIR PREFERENCES***;
data _null_;
	infile datalines; 
	filename setup "imputeSSB.set";
        file setup;
        input;
	put _infile_;
datalines4;
        title SSB Multiple Imputation;
        datain mydata.srmi_input_temp;
        dataout mydata.ssb_imputed&k.;
        default continuous;
*	continuous ;
	categorical race hispanic foreign_born male educ_5cat state mbr_ssdi_dig_group_1 
		mbr_ssdi_dig_group_2 mbr_ssdi_dig_group_3 mbr_ssdi_dig_group_4; 
*	mixed ;
*	count ;
        transfer personid initwgt halfsamp varstrat panel sipp_panel_beg_date;
        bounds birthdate(<sipp_panel_beg_date) mbr_ssdi_ddo_1(>birthdate) 
		mbr_ssdi_ddo_2(>birthdate) mbr_ssdi_ddo_3(>birthdate) mbr_ssdi_ddo_4(>birthdate) 
		mbr_ssdi_dsd_1(>mbr_ssdi_ddo_1) mbr_ssdi_dsd_2(>mbr_ssdi_ddo_2) 
		mbr_ssdi_dsd_3(>mbr_ssdi_ddo_3) mbr_ssdi_dsd_4(>mbr_ssdi_ddo_4);
*       restrict ;
        interact race*male, hispanic*male, foreign_born*male; 
	iterations 5;
        multiples 4;
	seed 2001;
run;
;;;;
%impute(name=imputeSSB, dir=.);





/*/ 2. CREATE INDICATOR VARIABLES FOR MISSING TYPES /*/
* create structurally-missing flag to return structurally missing values - this does not need to be edited;
%macro smiss(vars);
%local i next_name;
data srmi_flags&k.;
set mydata.srmi_input&k.;
%let i=1;
%do i=1 %to %sysfunc(countw(&vars));
        %let next_name = %scan(&vars, &i);
        SMISS&next_name=0;
        if &next_name=. then SMISS&next_name=1;
%end;
run;
%mend smiss;
%smiss(&varlist);
* create missing-to-be-replaced flag for variables that have missing-to-be-replaced values;
**these flags can be used to compare imputed values to observed values;
%macro miss(vars);
%local i next_name;
data srmi_flags&k.(keep=personid SMISS: MISS:);
set srmi_flags&k.;
%let i=1;
%do i=1 %to %sysfunc(countw(&vars));
        %let next_name = %scan(&vars, &i);
        MISS&next_name=0;
        if &next_name=.Z then MISS&next_name=1;
%end;
run;
%mend miss;
%miss(&varlist);





/*/ 3. EXTRACT COMPELTED IMPLICATES, RETURN STRUCTURALLY-MISSING VALUES, AND IMPOSE POST-IMPUTATION RELATIONSHIPS /*/
* loop through and extract each of the implicates, merge the missing flags onto the completed;
*	implicates, and return the structurally-missing values for;
*	variables with structurally-missing values;
%macro loop(n);
%do m=1 %to &n;

%putdata(name=imputeSSB, dir=., mult=&m., dataout=mydata.ssb_imputed&k._&m.);

proc sort data=mydata.ssb_imputed&k._&m. out=ssb_imputed&k._&m.;
by personid;
run;

proc sort data=srmi_flags&k. out=srmi_flags&k.;
by personid;
run;

data mydata.ssb_imputed&k._&m.;
merge ssb_imputed&k._&m. srmi_flags&k.;
by personid;
run;

%macro smissreplace(vars);
%local i next_name;
data mydata.ssb_imputed&k._&m.;
set mydata.ssb_imputed&k._&m.;
%let i=1;
%do i=1 %to %sysfunc(countw(&vars));
        %let next_name = %scan(&vars, &i);
        if SMISS&next_name=1 then &next_name=.;
%end;
run;
%mend smissreplace;
%smissreplace(&varlist);


*loop through completed implicates and impose post-imputation relationsihps;
***USER MUST EDIT THESE BASED ON THEIR SAMPLE. I.E., EDUCATION SET TO . FOR AGE LESS THAN 15***;
data mydata.ssb_imputed&k._&m.;
set mydata.ssb_imputed&k._&m.;
start_age=year(sipp_panel_beg_date)-year(birthdate);
if start_age<15 & MISSeduc_5cat=0 then educ_5cat=.; *education out of universe for age<15;

run;


*drop the flag variables;
data mydata.ssb_imputed&k._&m.;
set mydata.ssb_imputed&k._&m.;
drop SMISS: MISS:;
run;



%end;
%mend loop;
%loop(4);





