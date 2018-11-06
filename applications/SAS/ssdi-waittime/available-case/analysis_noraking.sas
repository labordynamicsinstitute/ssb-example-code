
/*/ 
Example file for running analysis with available case data and no missing data adjustments 
	and includes replicate weights. This example computes the average time between 
	date of disability and date of adjudication for the first disability associated 
	with an individual. The program performs each analysis separately over all synthetic 
	file, saves the results, and combines those results into a final output.
/*/


/*/
input files: 1) available case SSB/GSF data files with replicate weights
output files: 1) sas dataset with combined estimation results and graph
/*/


/*/ 
STEPS:
	1) create new variables for analysis
	2) regression with and without repweights, then save/organize results
	3) combine results and output final results
	4) round the results to be released, then create graph
/*/

/*/
USERS NEED TO EDIT THE DATA AND OUTPUT PATHS BELOW AND THE NUMBER OF REPLICATES
/*/


%let base=/rdcprojects/co/co00517/SSB;
%let version=v7.0;
%let myid=specXXX;

libname mydata "&base./programs/users/&myid./examples/mydata";
%let outpath=&base./programs/users/&myid./examples/output;
*specify number of replicates - equal to 4 for synthetic data, 1 for validation;
%let replicates=4;





/*/ 1. CREATE ADDITIONAL VARIABLES NEEDED FOR ANALYSIS /*/
*loop through each data file and create variables for the analysis;
%macro loops(ns);
%do k=1 %to &ns;

data temp&k.;
set mydata.ssb_available_repw_rake&k.;

educyears=.;
if (educ_5cat=1) then educyears=10;
if (educ_5cat=2) then educyears=12;
if (educ_5cat=3) then educyears=14;
if (educ_5cat=4) then educyears=16;
if (educ_5cat=5) then educyears=18;

start_age=year(sipp_panel_beg_date)-year(birthdate);

black=0;
if (race=2) then black=1;
otherrace=0;
if (race=3) then otherrace=1;

female=0;
if male=0 then female=1;

onset_age_year1=year(mbr_ssdi_ddo_1)-year(birthdate);
onset_age_month1=month(mbr_ssdi_ddo_1)-month(birthdate);

adjud_age_year1=year(mbr_ssdi_dsd_1)-year(birthdate);
adjud_age_month1=month(mbr_ssdi_dsd_1)-month(birthdate);

adjud_wait1=(adjud_age_year1-onset_age_year1)*12 + adjud_age_month1-onset_age_month1;
run;





/*/ 2. MEAN WAIT TIME, BY GENDER /*/
*weighted regression without replicate weights;
proc glm data=temp&k.;
class female;
model adjud_wait1 = female / solution noint;
where black=0 and otherrace=0 and hispanic=0 and panel=1996;
weight initwgt;
ods output ParameterEstimates = WaitNorepwNorake&k.;
run;

data WaitNorepwNorake&k.(keep=Parameter Estimate&k. StdErr&k. Var&k.);
set WaitNorepwNorake&k.;
rename Estimate=Estimate&k.;
rename StdErr=StdErr&k.;
Var=StdErr**2;
rename Var=Var&k.;
run;

proc sort data=WaitNorepwNorake&k. out=WaitNorepwNorake&k.;
by Parameter;
run;


*weighted regression with replicate weights;
proc surveyreg data=temp&k. varmethod=BRR(FAY=.5);
class female;
model adjud_wait1 = female / solution noint;
where black=0 and otherrace=0 and hispanic=0 and panel=1996;
weight initwgt;
repweights repweight1-repweight108;
ods output ParameterEstimates = WaitRepwNorake&k.;
run;

data WaitRepwNorake&k.(keep=Parameter Estimate&k. StdErr&k. Var&k.);
set WaitRepwNorake&k.;
rename Estimate=Estimate&k.;
rename StdErr=StdErr&k.;
Var=StdErr**2;
rename Var=Var&k.;
run;

proc sort data=WaitRepwNorake&k. out=WaitRepwNorake&k.;
by Parameter;
run;


%end;
%mend loops;
%loops(&replicates.);





/*/ 3. COMBINE RESULTS INTO FINAL OUTPUT /*/
* Without replicate weights;
* Merge outputs from each implicate;
%macro combine(replicates);
%if &replicates.=4 %then %do;
data mydata.WaitNorepwNorake;
merge WaitNorepwNorake1 WaitNorepwNorake2 WaitNorepwNorake3 WaitNorepwNorake4;
by Parameter;
run;
%end;

%else %if &replicates.=1 %then %do;
data mydata.WaitNorepwNorake;
set WaitNorepwNorake1;
run;
%end;


* Combined analysis: produce point estiamtes, variance estimates, and confidence intervals;
%if &replicates.=4 %then %do;
data mydata.WaitNorepwNorake;
set mydata.WaitNorepwNorake;
PointEstimate=MEAN(of Estimate1-Estimate4);
VarianceAvg=MEAN(of Var1-Var4);
VarianceAcross=VAR(of Estimate1-Estimate4);
TotalVariance=(.25)*VarianceAcross + VarianceAvg;
DF=3*(1+(VarianceAvg/(0.25*VarianceAcross)))**2;
critval=tinv(.95,DF);
StdErr=SQRT(TotalVariance);
CIlower=PointEstimate-critval*StdErr;
CIupper=PointEstimate+critval*StdErr;
run;
%end;

%else %if &replicates.=1 %then %do;
data mydata.WaitNorepwNorake;
set mydata.WaitNorepwNorake;
PointEstimate=Estimate1;
TotalVariance=Var1;
StdErr=SQRT(TotalVariance);
CIlower=PointEstimate-1.96*StdErr;
CIupper=PointEstimate+1.96*StdErr;
run;
%end;



* With replicate weights;
* Merge outputs from each implicate;
%if &replicates.=4 %then %do;
data mydata.WaitRepwNorake;
merge WaitRepwNorake1 WaitRepwNorake2 WaitRepwNorake3 WaitRepwNorake4;
by Parameter;
run;
%end;

%else %if &replicates.=1 %then %do;
data mydata.WaitRepwNorake;
set WaitRepwNorake1;
run;
%end;


* Combined analysis: produce point estiamtes, variance estimates, and confidence intervals;
%if &replicates.=4 %then %do;
data mydata.WaitRepwNorake;
set mydata.WaitRepwNorake;
PointEstimate=MEAN(of Estimate1-Estimate4);
VarianceAvg=MEAN(of Var1-Var4);
VarianceAcross=VAR(of Estimate1-Estimate4);
TotalVariance=(.25)*VarianceAcross + VarianceAvg;
DF=3*(1+(VarianceAvg/(0.25*VarianceAcross)))**2;
critval=tinv(.95,DF);
StdErr=SQRT(TotalVariance);
CIlower=PointEstimate-critval*StdErr;
CIupper=PointEstimate+critval*StdErr;
run;
%end;

%else %if &replicates.=1 %then %do;
data mydata.WaitRepwNorake;
set mydata.WaitRepwNorake;
PointEstimate=Estimate1;
TotalVariance=Var1;
StdErr=SQRT(TotalVariance);
CIlower=PointEstimate-1.96*StdErr;
CIupper=PointEstimate+1.96*StdErr;
run;
%end;

%mend combine;
%combine(&replicates.);





/*/ ROUND THE RESULTS TO BE RELEASED, THEN CREATE GRAPH /*/
*prep variables for graph;
data mydata.WaitNorepwNorake;
set mydata.WaitNorepwNorake;
Repw='Without Replicate Weights';
Female=substr(Parameter,11,1);
Gender='      ';
if Female='1' then Gender='Female';
if Female='0' then Gender='Male';
run;
data mydata.WaitRepwNorake;
set mydata.WaitRepwNorake;
Repw='With Replicate Weights';
Female=substr(Parameter,8,1);
Gender='      ';
if Female='1' then Gender='Female';
if Female='0' then Gender='Male';
run;

*round the variables to be used in released output;
data mydata.WaitCombinedNorake;
set mydata.WaitNorepwNorake
        mydata.WaitRepwNorake;
if int(PointEstimate) ne 0 then do;
    PointEstimate_4sigdigit=round(PointEstimate,10**(int(log10(abs(PointEstimate)))-3));
    end;
else do;
    PointEstimate_4sigdigit=round(PointEstimate,10**(-1*(abs(int(log10(abs(PointEstimate))))+4)));
    end;
if int(CIupper) ne 0 then do;
    CIupper_4sigdigit=round(CIupper,10**(int(log10(abs(CIupper)))-3));
    end;
else do;
    CIupper_4sigdigit=round(CIupper,10**(-1*(abs(int(log10(abs(CIupper))))+4)));
    end;
if int(CIlower) ne 0 then do;
    CIlower_4sigdigit=round(CIlower,10**(int(log10(abs(CIlower)))-3));
    end;
else do;
    CIlower_4sigdigit=round(CIlower,10**(-1*(abs(int(log10(abs(CIlower))))+4)));
    end;
run;

*produce graph;
ods path(prepend) work.templat(update);
proc template;
   define statgraph barchart;
   begingraph;
      entrytitle 'Adjudicaton Wait Time - No Missing Data Adjustments';
      layout gridded / border=false;
         layout datalattice columnvar=Repw / headerlabeldisplay=value cellwidthmin=50
                            columnheaders=bottom border=false columndatarange=union
                            columnaxisopts=(display=(line tickvalues))
                            rowaxisopts=(offsetmin=0 linearopts=(tickvaluepriority=true
                                viewmax=40)
                            label='Wait Time (Months)' griddisplay=on);
            layout prototype / walldisplay=(fill);
               barchart x=Gender y=PointEstimate_4sigdigit / group=Repw barlabel=true
                                              name='bar' outlineattrs=(color=black);
               scatterplot x=Gender y=PointEstimate_4sigdigit / group=Repw yerrorlower=CIlower_4sigdigit
                                                 yerrorupper=CIupper_4sigdigit
                                                 markerattrs=(size=0) name='scatter'
                                                 errorbarattrs=(thickness=2) 
						 datatransparency=0.6;
            endlayout;
         endlayout;
      endlayout;
   endgraph;
   end;
run;


ods graphics / reset=index imagename='GraphNone' imagefmt=png;
ods listing gpath="&outpath.";
proc sgrender data=mydata.WaitCombinedNorake template=barchart;
run;

