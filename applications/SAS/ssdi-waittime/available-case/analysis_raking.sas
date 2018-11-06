
/*/ 
Example file for running analysis with available case data with raking and includes replicate
	weights. This example computes the average time between date of disability and 
	date of adjudication for the first disability associated with an individual. The 
	program performs each analysis separately over all synthetic files, saves the results,
	and combines those results into a final output for each analysis.
/*/


/*/
input files: 1) raked available-case SSB/GSF data files with replicate weights
output files: 1) sas dataset with combined estimation results and graph
/*/


/*/ 
STEPS:
	1) create new variables for analysis 
	2) regression with and without repweights, then save/organize results 
	3) combine results and output final results
	4) round variables for output, then generate graph
/*/

/*/
USER NEEDS TO EDIT THE DATA AND OUTPUT PATHS BELOW AND THE NUMBER OF REPLICATES
/*/



%let base=/rdcprojects/co/co00517/SSB;
%let version=v7.0;
%let myid=specXXX;

libname mydata "&base./programs/users/&myid./examples/mydata";
%let outpath=&base./programs/users/&myid./examples/output;
*specify number of replicates - equal to 4 for synthetic files, 1 for validation;
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
weight finalinitwgt;
ods output ParameterEstimates = WaitNorepwRake&k.;
run;

data WaitNorepwRake&k.(keep=Parameter Estimate&k. StdErr&k. Var&k.);
set WaitNorepwRake&k.;
rename Estimate=Estimate&k.;
rename StdErr=StdErr&k.;
Var=StdErr**2;
rename Var=Var&k.;
run;

proc sort data=WaitNorepwRake&k. out=WaitNorepwRake&k.;
by Parameter;
run;


*weighted regression with replicate weights;
proc surveyreg data=temp&k. varmethod=BRR(FAY=.5);
class female;
model adjud_wait1 = female / solution noint;
where black=0 and otherrace=0 and hispanic=0 and panel=1996;
weight finalinitwgt;
repweights finalrepwgt1-finalrepwgt108;
ods output ParameterEstimates = WaitRepwRake&k.;
run;

data WaitRepwRake&k.(keep=Parameter Estimate&k. StdErr&k. Var&k.);
set WaitRepwRake&k.;
rename Estimate=Estimate&k.;
rename StdErr=StdErr&k.;
Var=StdErr**2;
rename Var=Var&k.;
run;

proc sort data=WaitRepwRake&k. out=WaitRepwRake&k.;
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
data mydata.WaitNorepwRake;
merge WaitNorepwRake1 WaitNorepwRake2 WaitNorepwRake3 WaitNorepwRake4;
by Parameter;
run;
%end;

%else %if &replicates.=1 %then %do;
data mydata.WaitNorepwRake;
set WaitNorepwRake1;
run;
%end;


* Combined analysis: produce point estiamtes, variance estimates, and confidence intervals;
%if &replicates.=4 %then %do;
data mydata.WaitNorepwRake;
set mydata.WaitNorepwRake;
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
data mydata.WaitNorepwRake;
set mydata.WaitNorepwRake;
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
data mydata.WaitRepwRake;
merge WaitRepwRake1 WaitRepwRake2 WaitRepwRake3 WaitRepwRake4;
by Parameter;
run;
%end;

%else %if &replicates.=1 %then %do;
data mydata.WaitRepwRake;
set WaitRepwRake1;
run;
%end;

* Combined analysis: produce point estiamtes, variance estimates, and confidence intervals;
%if &replicates.=4 %then %do;
data mydata.WaitRepwRake;
set mydata.WaitRepwRake;
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
data mydata.WaitRepwRake;
set mydata.WaitRepwRake;
PointEstimate=Estimate1;
TotalVariance=Var1;
StdErr=SQRT(TotalVariance);
CIlower=PointEstimate-1.96*StdErr;
CIupper=PointEstimate+1.96*StdErr;
run;
%end;

%mend combine;
%combine(&replicates.);





/*/ 4. ROUND VARIABLES FOR OUTPUT, THEN GENERATE GRAPH /*/
*prep variables for graph;
data mydata.WaitNorepwRake;
set mydata.WaitNorepwRake;
Repw='Without Replicate Weights';
Female=substr(Parameter,11,1);
Gender='      ';
if Female='1' then Gender='Female';
if Female='0' then Gender='Male';
run;
data mydata.WaitRepwRake;
set mydata.WaitRepwRake;
Repw='With Replicate Weights';
Female=substr(Parameter,8,1);
Gender='      ';
if Female='1' then Gender='Female';
if Female='0' then Gender='Male';
run;

*round variables;
data mydata.WaitCombinedRake;
set mydata.WaitNorepwRake
        mydata.WaitRepwRake;
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
ods path(prepend) work.template(update);
proc template;
   define statgraph barchart;
   begingraph;
      entrytitle 'Adjudicaton Wait Time - Raking';
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
                                                 errorbarattrs=(thickness=2) datatransparency=0.6;
            endlayout;
         endlayout;
      endlayout;
   endgraph;
   end;
run;


ods graphics / reset=index imagename='GraphRake' imagefmt=png;
ods listing gpath="&outpath.";
proc sgrender data=mydata.WaitCombinedRake template=barchart;
run;

