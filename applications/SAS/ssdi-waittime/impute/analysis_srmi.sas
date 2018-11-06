
/*/ 
Example file for running analysis with data that has been completed using SRMI and 
	includes replicate weights. This example computes the average time between 
	date of disability and date of adjudication for the first disability associated 
	with an individual. The program performs each analysis separately over all 
	completed implicates (with and without replicate weights), saves the results 
	from each implicate, and combines those results into a final output for each analysis.
/*/


/*/
input files: 1) completed data implicates with replicate weights
output files: 1) sas dataset with combined estimation results 
		2) graph showing results
/*/


/*/ 
STEPS:
	1) create new variables for analysis 
	2) regression with and without repweights, then save/organize results
	3) output final results
	4) round variables to be released, then create graph
/*/

/*/
USER NEEDS TO EDIT THE DATA AND OUTPTU PATHS BELOW AND SPECIFY THE NUMBER OF MULTIPLES 
	AND REPLICATES
/*/


%let base=/rdcprojects/co/co00517/SSB;
%let version=v7.0;
%let myid=specXXX;

libname mydata "&base./programs/users/&myid./examples/mydata";
%let outpath=&base./programs/users/&myid./examples/output;

*specify number of multiples and replicates. multiples is specified in srmi program. replicates is equal to 4 for synthetic data, 1 for validation;
%let multiples=4;
%let replicates=4;





/*/ 1. CREATE ADDITIONAL VARIABLES NEEDED FOR ANALYSIS /*/
*loop through data files and create variables for the analysis;
%macro loops(ns);
%do k=1 %to &ns;
%macro loopm(nm);
%do m=1 %to &nm;

data temp&k._&m.;
set mydata.ssb_imputed_repw&k._&m.;

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





/*/ 2. MEAN WAIT TIME, BY GENDER /*/
*weighted regression without replicate weights;
proc glm data=temp&k._&m.;
class female;
model adjud_wait1 = female / solution noint;
where black=0 and otherrace=0 and hispanic=0 and panel=1996;
weight initwgt;
ods output ParameterEstimates = WaitNorepw&k._&m.;
run;

data WaitNorepw&k._&m.(keep=Parameter Estimate&k._&m. StdErr&k._&m. Var&k._&m.);
set WaitNorepw&k._&m.;
rename Estimate=Estimate&k._&m.;
rename StdErr=StdErr&k._&m.;
Var=StdErr**2;
rename Var=Var&k._&m.;
run;

proc sort data=WaitNorepw&k._&m. out=WaitNorepw&k._&m.;
by Parameter;
run;


*weighted regression with replicate weights;
proc surveyreg data=temp&k._&m. varmethod=BRR(FAY=.5);
class female;
model adjud_wait1 = female / solution noint;
where black=0 and otherrace=0 and hispanic=0 and panel=1996;
weight initwgt;
repweights repweight1-repweight108;
ods output ParameterEstimates = WaitRepw&k._&m.;
run;

data WaitRepw&k._&m.(keep=Parameter Estimate&k._&m. StdErr&k._&m. Var&k._&m.);
set WaitRepw&k._&m.;
rename Estimate=Estimate&k._&m.;
rename StdErr=StdErr&k._&m.;
Var=StdErr**2;
rename Var=Var&k._&m.;
run;

proc sort data=WaitRepw&k._&m. out=WaitRepw&k._&m.;
by Parameter;
run;

* Merge outputs from each replicate and implicate;
* Without replicate weights;
%if &k.=1 and &m.=2 %then %do;
data mydata.WaitNorepw;
merge WaitNorepw&k._1 WaitNorepw&k._&m.;
by Parameter;
run;
%end;

%else %if &k.>1 or &m>2 %then %do;
data mydata.WaitNorepw;
merge mydata.WaitNorepw WaitNorepw&k._&m.;
by Parameter;
run;
%end;
* With replicate weights;
%if &k.=1 and &m.=2 %then %do;
data mydata.Waitrepw;
merge WaitRepw&k._1 WaitRepw&k._&m.;
by Parameter;
run;
%end;

%else %if &k.>1 or &m>2 %then %do;
data mydata.WaitRepw;
merge mydata.WaitRepw WaitRepw&k._&m.;
by Parameter;
run;
%end;


%end;
%mend loopm;
%loopm(&multiples.);
%end;
%mend loops;
%loops(&replicates.);





/*/ 3. COMBINE RESULTS ACROSS IMPLICATES INTO FINAL OUTPUT /*/
* Without replicate weights;
* Combined analysis: produce point estiamtes, variance estimates, and confidence intervals;
%macro combine(replicates);
%if &replicates.=4 %then %do;
data mydata.WaitNorepw;
set mydata.WaitNorepw;
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
data mydata.WaitNorepw;
set mydata.WaitNorepw;
PointEstimate=MEAN(of Estimate1_1-Estimate1_&multiples.);

VarianceImpMeans=VAR(of Estimate1_1-Estimate1_&multiples.);
VarianceAvg=MEAN(of Var1_1-Var1_&multiples.);

TotalVariance=(1+(1/&multiples.))*VarImpMeans + VarianceAvg;

DFcomp1=VarianceAvg;
DFcomp2=(1+(1/&multiples.))*VarImpMeans;
DegreesFreedom=(&multiples.-1)*(1+(DFcomp1/DFcomp2))**2;

critval=tinv(.95,DegreesFreedom);
StdErr=SQRT(TotalVariance);
CIlower=PointEstimate-critval*StdErr;
CIupper=PointEstimate+critval*StdErr;
run;
%end;


* With replicate weights;
* Combined analysis: produce point estiamtes, variance estimates, and confidence intervals;
%if &replicates.=4 %then %do;
data mydata.WaitRepw;
set mydata.WaitRepw;

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
data mydata.WaitRepw;
set mydata.WaitRepw;
PointEstimate=MEAN(of Estimate1_1-Estimate1_&multiples.);

VarianceImpMeans=VAR(of Estimate1_1-Estimate1_&multiples.);
VarianceAvg=MEAN(of Var1_1-Var1_&multiples.);

TotalVariance=(1+(1/&multiples.))*VarImpMeans + VarianceAvg;

DFcomp1=VarianceAvg;
DFcomp2=(1+(1/&multiples.))*VarImpMeans;
DegreesFreedom=(&multiples.-1)*(1+(DFcomp1/DFcomp2))**2;

critval=tinv(.95,DegreesFreedom);
StdErr=SQRT(TotalVariance);
CIlower=PointEstimate-critval*StdErr;
CIupper=PointEstimate+critval*StdErr;
run;
%end;

%mend combine;
%combine(&replicates.);






/*/ 4. ROUND VARIABLES TO BE RELEASED, THEN GENERATE GRAPH /*/
*prepare variables for graph;
data mydata.WaitNorepw;
set mydata.WaitNorepw;
Repw='Without Replicate Weights';
Female=substr(Parameter,11,1);
Gender='      ';
if Female='1' then Gender='Female';
if Female='0' then Gender='Male';
run;
data mydata.WaitRepw;
set mydata.WaitRepw;
Repw='With Replicate Weights';
Female=substr(Parameter,8,1);
Gender='      ';
if Female='1' then Gender='Female';
if Female='0' then Gender='Male';
run;

*round variables to be released;
data mydata.WaitCombined;
set mydata.WaitNorepw
	mydata.WaitRepw;
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


ods path(prepend) work.template(update);
proc template; 
   define statgraph barchart; 
   begingraph; 
      entrytitle 'Adjudicaton Wait Time - SRMI'; 
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


ods graphics / reset=index imagename='GraphSRMI' imagefmt=png;
ods listing gpath="&outpath.";
proc sgrender data=mydata.WaitCombined template=barchart;
run;



