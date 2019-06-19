
/*/ 
Example file for running analysis with data that has been completed using SRMI and 
	includes replicate weights. The program performs the analysis separatly over 
	all completed implicates, saves the results from each implicate, and combines 
	those results into a final output for each analysis.
The analysis estimates life-cycle earnings by regressing log annual earnings on age 
	dummy variables, and then plots the coefficients on the age variables.
Because the analysis includes individuals from multiple SIPP panels, we re-weight 
	the SIPP weights (replicate weights and original SIPP weight) based on the 
	relative size of each panel.
Analysis with and without replicate weights is included in this file.
/*/


/*/
input files: 1) completed data implicates, via SRMI, with replicate weights
output files: 1) sas dataset with combined estimation results with and without 
		replicate weights
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
USER NEEDS TO EDIT THE DATA AND OUTPUT PATHS BELOW AND THE NUMBER OF MULTIPLES AND REPLICATES
/*/


%let base=/rdcprojects/co/co00517/SSB;
%let version=v7.0;
%let myid=specXXX;

libname mydata "&base./programs/users/&myid./examples/mydata";
%let outpath=&base./programs/users/&myid./examples/output;
*specify number of multiples and replicates. multiples is specified in srmi program. replicates is 4 for synthetic data and 1 for validation;
%let multiples=4;
%let replicates=4;




*loop through each data file to reweight, reshape, create new variables, and run analysis;
%macro loops(ns);
%do k=1 %to &ns;
%macro loopm(nm);
%do m=1 %to &nm;

/*/ 1. ADJUST THE PERSON WEIGHTS FOR THE RELATIVE SIZE OF EACH PANEL /*/
data ssb_imputed_repw&k._&m.;
set mydata.ssb_imputed_repw&k._&m.;
run;

proc summary data= ssb_imputed_repw&k._&m.;
class panel;
var personid;
output out=mydata.temp_panel_size(keep=panel panel_tot) n=panel_tot;
run;

proc summary data= ssb_imputed_repw&k._&m.;
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

proc sort data=ssb_imputed_repw&k._&m.;
by panel;
run;

data mydata.ssb_imputed_repw_reweight&k._&m.;
merge ssb_imputed_repw&k._&m. mydata.relative_size;
by panel;
run;

data mydata.ssb_imputed_repw_reweight&k._&m.;
set mydata.ssb_imputed_repw_reweight&k._&m.;
initwgt_reweight=initwgt*(1/PanelSize);

data mydata.ssb_imputed_repw_reweight&k._&m.;
set mydata.ssb_imputed_repw_reweight&k._&m.;
array repws {108} repweight1-repweight108;
array repws_rew {108} repweight_reweight1-repweight_reweight108;
	do i=1 to 108;
	repws_rew[i]=repws[i]*(1/PanelSize);
	end;
run;





/*/ 2. TRANSPOSE THE DATASET FROM WIDE TO LONG /*/
data temp_long_a;
set mydata.ssb_imputed_repw_reweight&k._&m.(keep=personid total_der_fica:);
run;

data temp_long_b;
set mydata.ssb_imputed_repw_reweight&k._&m.(keep= personid male race hispanic foreign_born birthdate educ_5cat state panel 
	sipp_panel_beg_date initwgt_reweight repweight_reweight: halfsamp varstrat);
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

data temp&k._&m.;
merge temp_long_a temp_long_b;
by personid;
run;





/*/ 3. CREATE ADDITIONAL VARIABLES NEEDED FOR ANALYSIS /*/
data temp&k._&m.;
set temp&k._&m.;
age=year-year(birthdate);
if male=1 and race=1 and hispanic=0 and foreign_born=0 and panel>=1990 and panel<=1993 and age>=25 and age<=60 then output;
run;





/*/ 4. REGRESSION AND SAVE/ORGANIZE RESULTS /*/
*weighted regression with replicate weights;
proc surveyreg data=temp&k._&m. varmethod=BRR(FAY=.5);
class age;
model log_total_der_fica_ = age / solution noint;
weight initwgt_reweight;
repweights repweight_reweight1-repweight_reweight108;
ods output ParameterEstimates = LCoutput&k._&m.;
run;

data LCoutput&k._&m.(keep=Parameter Estimate&k._&m. StdErr&k._&m. Var&k._&m.);
set LCoutput&k._&m.;
rename Estimate=Estimate&k._&m.;
rename StdErr=StdErr&k._&m.;
Var=StdErr**2;
rename Var=Var&k._&m.;
run;

proc sort data=LCoutput&k._&m. out=LCoutput&k._&m.;
by Parameter;
run;


*weighted regression without replicate weights;
proc glm data=temp&k._&m.;
class age;
model log_total_der_fica_ = age / solution noint;
weight initwgt_reweight;
ods output ParameterEstimates = LCoutputNorepw&k._&m.;
run;

data LCoutputNorepw&k._&m.(keep=Parameter Estimate&k._&m. StdErr&k._&m. Var&k._&m.);
set LCoutputNorepw&k._&m.;
rename Estimate=Estimate&k._&m.;
rename StdErr=StdErr&k._&m.;
Var=StdErr**2;
rename Var=Var&k._&m.;
run;

proc sort data=LCoutputNorepw&k._&m. out=LCoutputNorepw&k._&m.;
by Parameter;
run;

* Merge outputs from each replicate and implicate;
* With replicate weights;
%if &k.=1 and &m.=2 %then %do;
data mydata.LCoutput;
merge LCoutput&k._1 LCoutput&k._&m.;
by Parameter;
run;
%end;

%else %if &k.>1 or &m>2 %then %do;
data mydata.LCoutput;
merge mydata.LCoutput LCoutput&k._&m.;
by Parameter;
run;
%end;
* Without replicate weights;
%if &k.=1 and &m.=2 %then %do;
data mydata.LCoutputNorepw;
merge LCoutputNorepw&k._1 LCoutputNorepw&k._&m.;
by Parameter;
run;
%end;

%else %if &k.>1 or &m>2 %then %do;
data mydata.LCoutputNorepw;
merge mydata.LCoutputNorepw LCoutputNorepw&k._&m.;
by Parameter;
run;
%end;

%end;
%mend loopm;
%loopm(&multiples.);
%end;
%mend loops;
%loops(&replicates.);





/*/ 5. COMBINE RESULTS ACROSS IMPLICATES INTO FINAL OUTPUT /*/
* With replicate weights;
* Combined analysis: produce point estiamtes, variance estimates, and confidence intervals;
%macro combine(replicates);
%if &replicates.=4 %then %do;
data mydata.LCoutput;
set mydata.LCoutput;

Mean1=MEAN(of Estimate1_1-Estimate1_&multiples.);
Mean2=MEAN(of Estimate2_1-Estimate2_&multiples.);
Mean3=MEAN(of Estimate3_1-Estimate3_&multiples.);
Mean4=MEAN(of Estimate4_1-Estimate4_&multiples.);
Var1=VAR(of Estimate1_1-Estimate1_&multiples.);
Var2=VAR(of Estimate2_1-Estimate2_&multiples.);
Var3=VAR(of Estimate3_1-Estimate3_&multiples.);
Var4=VAR(of Estimate4_1-Estimate4_&multiples.);
MeanVar1=MEAN(of Var1_1-Var1_&multiples.);
MeanVar2=MEAN(of Var2_1-Var2_&multiples.);
MeanVar3=MEAN(of Var3_1-Var3_&multiples.);
MeanVar4=MEAN(of Var4_1-Var4_&multiples.);

VarianceSynthMeans=VAR(of Mean1-Mean4);
MeanSynthVariance=MEAN(of Var1-Var4);
VarianceAvg=MEAN(of MeanVar1-MeanVar4);

PointEstimate=MEAN(of Mean1-Mean4);

TotalVariance=(1/4)*VarianceSynthMeans + MeanSynthVariance*(1+(1/&multiples.)) + VarianceAvg;

DFcomp1=(1+(1/&multiples.))*MeanSynthVariance+VarianceAvg;
DFcomp2=(1/4)*VarianceSynthMeans;
DegreesFreedom=3*(1+(DFcomp1/DFcomp2))**2;

critval=tinv(.95,DegreesFreedom);
StdErr=SQRT(TotalVariance);
CIlower=PointEstimate-critval*StdErr;
CIupper=PointEstimate+critval*StdErr;
run;
%end;


%else %if &replicates.=1 %then %do;
data mydata.LCoutput;
set mydata.LCoutput;
PointEstimate=MEAN(of Estimate1_1-Estimate1_&multiples.);

VarianceImpMeans=VAR(of Estimate1_1-Estimate1_&multiples.);
VarianceAvg=MEAN(of Var1_1-Var1_&multiples.);

TotalVariance=(1+(1/&multiples.))*VarianceImpMeans + VarianceAvg;

DFcomp1=VarianceAvg;
DFcomp2=(1+(1/&multiples.))*VarianceImpMeans;
DegreesFreedom=(&multiples.-1)*(1+(DFcomp1/DFcomp2))**2;

critval=tinv(.95,DegreesFreedom);
StdErr=SQRT(TotalVariance);
CIlower=PointEstimate-critval*StdErr;
CIupper=PointEstimate+critval*StdErr;
run;
%end;


* Without replicate weights;
* Combined analysis: produce point estiamtes, variance estimates, and confidence intervals;
%if &replicates.=4 %then %do;
data mydata.LCoutputNorepw;
set mydata.LCoutputNorepw;

Mean1=MEAN(of Estimate1_1-Estimate1_&multiples.);
Mean2=MEAN(of Estimate2_1-Estimate2_&multiples.);
Mean3=MEAN(of Estimate3_1-Estimate3_&multiples.);
Mean4=MEAN(of Estimate4_1-Estimate4_&multiples.);
Var1=VAR(of Estimate1_1-Estimate1_&multiples.);
Var2=VAR(of Estimate2_1-Estimate2_&multiples.);
Var3=VAR(of Estimate3_1-Estimate3_&multiples.);
Var4=VAR(of Estimate4_1-Estimate4_&multiples.);
MeanVar1=MEAN(of Var1_1-Var1_&multiples.);
MeanVar2=MEAN(of Var2_1-Var2_&multiples.);
MeanVar3=MEAN(of Var3_1-Var3_&multiples.);
MeanVar4=MEAN(of Var4_1-Var4_&multiples.);

VarianceSynthMeans=VAR(of Mean1-Mean4);
MeanSynthVariance=MEAN(of Var1-Var4);
VarianceAvg=MEAN(of MeanVar1-MeanVar4);

PointEstimate=MEAN(of Mean1-Mean4);

TotalVariance=(1/4)*VarianceSynthMeans + MeanSynthVariance*(1+(1/&multiples.)) + VarianceAvg;

DFcomp1=(1+(1/&multiples.))*MeanSynthVariance+VarianceAvg;
DFcomp2=(1/4)*VarianceSynthMeans;
DegreesFreedom=3*(1+(DFcomp1/DFcomp2))**2;

critval=tinv(.95,DegreesFreedom);
StdErr=SQRT(TotalVariance);
CIlower=PointEstimate-critval*StdErr;
CIupper=PointEstimate+critval*StdErr;
run;
%end;


%else %if &replicates.=1 %then %do;
data mydata.LCoutputNorepw;
set mydata.LCoutputNorepw;
PointEstimate=MEAN(of Estimate1_1-Estimate1_&multiples.);

VarianceImpMeans=VAR(of Estimate1_1-Estimate1_&multiples.);
VarianceAvg=MEAN(of Var1_1-Var1_&multiples.);

TotalVariance=(1+(1/&multiples.))*VarianceImpMeans + VarianceAvg;

DFcomp1=VarianceAvg;
DFcomp2=(1+(1/&multiples.))*VarianceImpMeans;
DegreesFreedom=(&multiples.-1)*(1+(DFcomp1/DFcomp2))**2;

critval=tinv(.95,DegreesFreedom);
StdErr=SQRT(TotalVariance);
CIlower=PointEstimate-critval*StdErr;
CIupper=PointEstimate+critval*StdErr;
run;
%end;

%mend combine;
%combine(&replicates.);





/*/ 6. ROUND VARIABLES TO BE RELEASED, THEN GENERATE GRAPH /*/
*first, combine results with and without replicate weights into one dataset;
*prepare with replicate weights dataset and round variables to be released;
data temp_LCoutput(keep=Parameter Age PointEstimate CIlower CIupper);
set mydata.LCoutput;
Age=substr(Parameter,5,2);
run;

data temp_LCoutput;
set temp_LCoutput;
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

proc sort data=temp_LCoutput out=temp_LCoutput;
by Age;
run;

*prepare without replicate weights dataset and round variables to be released;
data temp_LCoutputNorepw(keep=ParameterNorepw Age PointEstimateNorepw CIlowerNorepw CIupperNorepw);
set mydata.LCoutputNorepw;
rename PointEstimate=PointEstimateNorepw;
rename CIlower=CIlowerNorepw;
rename CIupper=CIupperNorepw;
Age=substr(Parameter,11,2);
rename Parameter=ParameterNorepw;
run;

data temp_LCoutputNorepw;
set temp_LCoutputNorepw;
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

proc sort data=temp_LCoutputNorepw out=temp_LCoutputNorepw;
by Age;
run;

data mydata.LCoutput_merged;
merge temp_LCoutput temp_LCoutputNorepw;
by Age;
run;

*create graph;
ods path(prepend) work.templat(update);
ods graphics / reset=index imagename='GraphSRMI' imagefmt=png;
ods listing gpath="&outpath.";

title "Life-Cycle Earnings - SRMI";
proc sgplot data=mydata.LCoutput_merged noautolegend;
band x=Age lower=CIlower_4sigdigit upper=CIupper_4sigdigit/
        legendlabel='Replicate Weights CI' name='CIrepw';
band x=Age lower=CIlowerNorepw_4sigdigit upper=CIupperNorepw_4sigdigit/
        legendlabel='Normal CI' name='CInorm';
band x=Age lower=CIlower_4sigdigit upper=CIupper_4sigdigit/
        fillattrs=GraphConfidence2
        legendlabel='Replicate Weights CI' name='CIrepw';
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

