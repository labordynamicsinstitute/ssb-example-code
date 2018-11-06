
/*/
Example file for running analysis with available case data that includes no 
	adjustments for missing data, with and without replicate weights. The program 
	performs the analysis separately over all four synthetic files, 
	saves the results from each file, and combines
        those results into a final output for each analysis.
The analysis estimates life-cycle earnings by regressing log annual earnings on age
        dummy variables, and then plots the coefficients on the age variables.
Because the analysis includes individuals from multiple SIPP panels, we re-weight
        the SIPP weights (replicate weights and original SIPP weight) based on the
        relative size of each panel.
Analysis with and without replicate weights is included in this file.
/*/


/*/
input files: 1) raked available-case SSB/GSF files with replicate weights
output files: 1) sas dataset with combined estimation results with and without replicate
        weights
             2) graph showing life-cycle earnings
/*/


/*/
STEPS:
        1) re-weight weights based on relative size of each panel
        2) convert the dataset form wide to long
        3) create new variables for analysis
        4) run the analysis
        5) combine results across implicates
        6) round variables to be released, then generate lifecycle earnings graph
        NOTE: step 4 is repeated for analysis with and without replicate weights
/*/

/*/
USER NEEDS TO EDIT THE DATA AND OUTPUT PATHS BELOW AND THE NUMBER OF REPLICATES
/*/


%let base=/rdcprojects/co/co00517/SSB;
%let version=v7.0;
%let myid=specXXX;

libname mydata "&base./programs/users/&myid./examples/mydata";
%let outpath=&base./programs/users/&myid./examples/output;

*specify number of replicates - equal to 4 for synthetic data, 1 for validation;
%let replicates=4;





*loop through each data file to reweight, reshape, create new variables, and run analysis;
%macro loops(ns);
%do k=1 %to &ns;

/*/ 1. ADJUST THE PERSON WEIGHTS FOR THE RELATIVE SIZE OF EACH PANEL /*/
proc summary data= mydata.ssb_available_repw_rake&k.;
class panel;
var personid;
output out=mydata.temp_panel_size(keep=panel panel_tot) n=panel_tot;
run;

proc summary data= mydata.ssb_available_repw_rake&k.;
var personid;
output out=mydata.temp_total_size(keep=panel tot) n=tot;
run;

proc sort data=mydata.temp_panel_size;
by panel;
run;

data mydata.relative_size;
if _n_=1 then set mydata.temp_total_size;
set mydata.temp_panel_size;
run;

data mydata.relative_size;
set mydata.relative_size;
PanelSize=panel_tot/tot;
run;

proc sort data=mydata.ssb_available_repw_rake&k.;
by panel;
run;

data mydata.ssb_available_repw_rake_rew&k.;
merge mydata.ssb_available_repw_rake&k. mydata.relative_size;
by panel;
run;

data mydata.ssb_available_repw_rake_rew&k.;
set mydata.ssb_available_repw_rake_rew&k.;
finalinitwgt_reweight=finalinitwgt*(1/PanelSize);
initwgt_reweight=initwgt*(1/PanelSize);
if initwgt=0 then delete;
run;

data mydata.ssb_available_repw_rake_rew&k.;
set mydata.ssb_available_repw_rake_rew&k.;
array finalrepws {108} finalrepwgt1-finalrepwgt108;
array finalrepws_rew {108} finalrepwgt_reweight1-finalrepwgt_reweight108;
	do i=1 to 108;
	finalrepws_rew[i]=finalrepws[i]*(1/PanelSize);
	end;
array repws {108} repweight1-repweight108;
array repws_rew {108} repweight_reweight1-repweight_reweight108;
	do i=1 to 108;
	repws_rew[i]=repws[i]*(1/PanelSize);
	end;
run;





/*/ 2. TRANSPOSE THE DATASET FROM WIDE TO LONG /*/
data temp_long_a;
set mydata.ssb_available_repw_rake_rew&k.(keep=personid total_der_fica:);
run;

data temp_long_b;
set mydata.ssb_available_repw_rake_rew&k.(keep= personid male race hispanic foreign_born birthdate educ_5cat state panel 
	sipp_panel_beg_date finalinitwgt_reweight finalrepwgt_reweight: 
	initwgt_reweight repweight_reweight: halfsamp varstrat);
run;

proc sort data=temp_long_a out=temp_long_a;
by personid;
run;

proc sort data=temp_long_b out=temp_long_b;
by personid;
run;

proc transpose data=temp_long_a  out=temp_long_a prefix=total_der_fica_;
by personid;
run;

data temp_long_a;
set temp_long_a (rename=(total_der_fica_1=total_der_fica_));
year=input(substr(_name_,16),5.);
log_total_der_fica_=log(total_der_fica_);
drop _name_;
run;

data temp&k.;
merge temp_long_a temp_long_b;
by personid;
run;





/*/ 3. CREATE ADDITIONAL VARIABLES NEEDED FOR ANALYSIS /*/
data temp&k.;
set temp&k.;
age=year-year(birthdate);
run;





/*/ 4. REGRESSION AND SAVE/ORGANIZE RESULTS /*/
*weighted regression without replicate weights;
proc glm data=temp&k.;
class age;
model log_total_der_fica_ = age / solution noint;
where age>=25 & age<=60 & panel>=1990;
weight initwgt_reweight;
ods output ParameterEstimates = LCoutput_NorepwNorake&k.;
run;

data LCoutput_NorepwNorake&k.(keep=Parameter Estimate&k. StdErr&k. Var&k.);
set LCoutput_NorepwNorake&k.;
rename Estimate=Estimate&k.;
rename StdErr=StdErr&k.;
Var=StdErr**2;
rename Var=Var&k.;
run;

proc sort data=LCoutput_NorepwNorake&k. out=LCouput_NorepwNorake&k.;
by Parameter;
run;


*weighted regression with replicate weights;
proc surveyreg data=temp&k. varmethod=BRR(FAY=.5);
class age;
model log_total_der_fica_ = age / solution noint;
where age>=25 & age<=60 & panel>=1990;
weight initwgt_reweight;
repweights repweight_reweight1-repweight_reweight108;
ods output ParameterEstimates = LCoutput_RepwNorake&k.;
run;

data LCoutput_RepwNorake&k.(keep=Parameter Estimate&k. StdErr&k. Var&k.);
set LCoutput_RepwNorake&k.;
rename Estimate=Estimate&k.;
rename StdErr=StdErr&k.;
Var=StdErr**2;
rename Var=Var&k.;
run;

proc sort data=LCoutput_RepwNorake&k. out=LCoutput_RepwNorake&k.;
by Parameter;
run;



%end;
%mend loops;
%loops(&replicates.);





/*/ 5. COMBINE RESULTS ACROSS IMPLICATES INTO FINAL OUTPUT /*/
* Without replicate weights;
* Merge outputs from each implicate;
%macro combine(replicates);
%if &replicates.=4 %then %do;
data mydata.LCoutput_NorepwNorake;
merge LCoutput_NorepwNorake1 LCoutput_NorepwNorake2 LCoutput_NorepwNorake3 LCoutput_NorepwNorake4; 
by Parameter;
run;
%end;

%else %if &replicates.=1 %then %do;
data mydata.LCoutput_NorepwNorake;
set LCoutput_NorepwNorake1; 
run;
%end;


* Combined analysis: produce point estiamtes, variance estimates, and confidence intervals;
%if &replicates.=4 %then %do;
data mydata.LCoutput_NorepwNorake;
set mydata.LCoutput_NorepwNorake;
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
data mydata.LCoutput_NorepwNorake;
set mydata.LCoutput_NorepwNorake;
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
data mydata.LCoutput_RepwNorake;
merge LCoutput_RepwNorake1 LCoutput_RepwNorake2 LCoutput_RepwNorake3 LCoutput_RepwNorake4;
by Parameter;
run;
%end;

%else %if &replicates.=1 %then %do;
data mydata.LCoutput_RepwNorake;
set LCoutput_RepwNorake1;
run;
%end;

* Combined analysis: produce point estiamtes, variance estimates, and confidence intervals;
%if &replicates.=4 %then %do;
data mydata.LCoutput_RepwNorake;
set mydata.LCoutput_RepwNorake;
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
data mydata.LCoutput_RepwNorake;
set mydata.LCoutput_RepwNorake;
PointEstimate=Estimate1;
TotalVariance=Var1;
StdErr=SQRT(TotalVariance);
CIlower=PointEstimate-1.96*StdErr;
CIupper=PointEstimate+1.96*StdErr;
run;
%end;

%mend combine;
%combine(&replicates.);





/*/ 6. ROUND VARIABLES TO BE RELEASED, THEN GENERATE GRAPHS /*/
*first, combine with vs without replicate weights results into one dataset;
*prepare with replicate weights for combination - generate new variables and round output variables;
data temp_LCoutput_RepwNorake(keep=Parameter Age PointEstimate CIlower CIupper);
set mydata.LCoutput_RepwNorake;
Age=substr(Parameter,5,2);

data temp_LCoutput_RepwNorake;
set temp_LCoutput_RepwNorake;
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

proc sort data=temp_LCoutput_RepwNorake out=temp_LCoutput_RepwNorake;
by Age;
run;

*prepare without replicate weight dataset - generate new variables and round variables for output;
data temp_LCoutput_NorepwNorake(keep=ParameterNorepw Age PointEstimateNorepw CIlowerNorepw CIupperNorepw);
set mydata.LCoutput_NorepwNorake;
rename PointEstimate=PointEstimateNorepw;
rename CIlower=CIlowerNorepw;
rename CIupper=CIupperNorepw;
Age=substr(Parameter,11,2);
rename Parameter=ParameterNorepw;
run;

data temp_LCoutput_NorepwNorake;
set temp_LCoutput_NorepwNorake;
if int(PointEstimateNorepw) ne 0 then do;
    PointEstimateNorepw_4sigdigit=round(PointEstimateNorepw,10**(int(log10(abs(PointEstimateNorepw)))-3));
    end;
else do;
    PointEstimateNorepw_4sigdigit=round(PointEstimateNorepw,10**(-1*(abs(int(log10(abs(PointEstimateNorepw))))+4)));
    end;
if int(CIupperNorepw) ne 0 then do;
    CIupperNorepw_4sigdigit=round(CIupperNorepw,10**(int(log10(abs(CIupperNorepw)))-3));
    end;
else do;
    CIupperNorepw_4sigdigit=round(CIupperNorepw,10**(-1*(abs(int(log10(abs(CIupperNorepw))))+4)));
    end;
if int(CIlowerNorepw) ne 0 then do;
    CIlowerNorepw_4sigdigit=round(CIlowerNorepw,10**(int(log10(abs(CIlowerNorepw)))-3));
    end;
else do;
    CIlowerNorepw_4sigdigit=round(CIlowerNorepw,10**(-1*(abs(int(log10(abs(CIlowerNorepw))))+4)));
    end;
run;


proc sort data=temp_LCoutput_NorepwNorake out=temp_LCoutput_NorepwNorake;
by Age;
run;

data mydata.LCoutput_Norake_merged;
merge temp_LCoutput_RepwNorake temp_LCoutput_NorepwNorake;
by Age;
run;

*generate graph;
ods path(prepend) work.templat(update);
ods graphics / reset=index imagename='GraphNoraking' imagefmt=png;
ods listing gpath="&outpath.";

title "Life-Cycle Earnings - No Missing Data Adjustments";
proc sgplot data=mydata.LCoutput_Norake_merged noautolegend;
band x=Age lower=CIlower_4sigdigit upper=CIupper_4sigdigit/
        legendlabel='Replicate Weights CI' name='CIrepw';
band x=Age lower=CIlowerNorepw_4sigdigit upper=CIupperNorepw_4sigdigit/
        fillattrs=GraphConfidence2
        legendlabel='Normal CI' name='CInorm';
scatter x=Age y=PointEstimate_4sigdigit/
        markerattrs=(symbol=CircleFilled)
        legendlabel='Point Estimate' name='PE';
series x=Age y=PointEstimate_4sigdigit/
        lineattrs=(pattern=solid);
yaxis label='Log Annual Earnings'
        max=11
        min=9;
xaxis label='Age';
keylegend 'PE' 'CIrepw' 'CInorm'/
        location=outside
        position=bottom
        across=3;
run;
title;

