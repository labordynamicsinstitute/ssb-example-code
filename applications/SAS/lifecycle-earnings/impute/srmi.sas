
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
	categorical race hispanic foreign_born male educ_5cat; 
	mixed total_der_fica_1978 total_der_fica_1979 total_der_fica_1980 total_der_fica_1981 
		total_der_fica_1982 total_der_fica_1983 total_der_fica_1984 total_der_fica_1985 
		total_der_fica_1986 total_der_fica_1987 total_der_fica_1988 total_der_fica_1989 
		total_der_fica_1990 total_der_fica_1991 total_der_fica_1992 total_der_fica_1993 
		total_der_fica_1994 total_der_fica_1995 total_der_fica_1996 total_der_fica_1997 
		total_der_fica_1998 total_der_fica_1999 total_der_fica_2000 total_der_fica_2001 
		total_der_fica_2002 total_der_fica_2003 total_der_fica_2004 total_der_fica_2005 
		total_der_fica_2006 total_der_fica_2007 total_der_fica_2008 total_der_fica_2009 
		total_der_fica_2010 total_der_fica_2011 total_der_fica_2012 total_der_fica_2013 
		total_der_fica_2014; 
*	count ;
        transfer personid initwgt halfsamp varstrat panel sipp_panel_beg_date;
        bounds birthdate(<sipp_panel_beg_date)
		total_der_fica_1978(>=0) total_der_fica_1979(>=0) total_der_fica_1980(>=0) 
		total_der_fica_1981(>=0) total_der_fica_1982(>=0) total_der_fica_1983(>=0) 
		total_der_fica_1984(>=0) total_der_fica_1985(>=0) total_der_fica_1986(>=0) 
		total_der_fica_1987(>=0) total_der_fica_1988(>=0) total_der_fica_1989(>=0) 
		total_der_fica_1990(>=0) total_der_fica_1991(>=0) total_der_fica_1992(>=0) 
		total_der_fica_1993(>=0) total_der_fica_1994(>=0) total_der_fica_1995(>=0) 
		total_der_fica_1996(>=0) total_der_fica_1997(>=0) total_der_fica_1998(>=0) 
		total_der_fica_1999(>=0) total_der_fica_2000(>=0) total_der_fica_2001(>=0) 
		total_der_fica_2002(>=0) total_der_fica_2003(>=0) total_der_fica_2004(>=0) 
		total_der_fica_2005(>=0) total_der_fica_2006(>=0) total_der_fica_2007(>=0) 
		total_der_fica_2008(>=0) total_der_fica_2009(>=0) total_der_fica_2010(>=0) 
		total_der_fica_2011(>=0) total_der_fica_2012(>=0) total_der_fica_2013(>=0) 
		total_der_fica_2014(>=0);
*       restrict ;
        interact race*state, hispanic*state;
	iterations 5;
        multiples 4;
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
data mydata.ssb_imputed&k._&m.;
set mydata.ssb_imputed&k._&m.;
start_age=year(sipp_panel_beg_date)-year(birthdate);
if start_age<15 & SMISSeduc_5cat=0 then educ_5cat=.; *education out of universe for age<15;
run;


*drop the flag variables;
data mydata.ssb_imputed&k._&m.;
set mydata.ssb_imputed&k._&m.;
drop SMISS: MISS:;
run;



%end;
%mend loop;
%loop(4);





