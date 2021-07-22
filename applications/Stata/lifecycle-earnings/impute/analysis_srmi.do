/*
Example program for running analysis with data that has been completed using SRMI and
        includes replicate weights. The program performs the analysis separately over
        all completed implicates, saves the results from each implicate, and combines
        those results into a final output for each analysis.

The analysis estimates life-cycle earnings by regressing log annual earnings on age
        dummy variables, and then plots the coefficients on the age variables.

Because the analysis includes individiuals from multiple SIPP panels, we re-weight
        the SIPP weights (replicate weights and original SIPP weight) based on the
        relative size of each panel.

Analysis with and without replicate weights is included in this file.


input files: 1) completed data implicates with replicate weights
output files: 1) stata dataset with combined estimation results with and without replicate
        weights
              2) graph showing life-cycle earnings


STEPS:
        1) re-weight weights based on relative size of each panel
        2) convert the dataset form wide to long
        3) create new variables for analysis
        4) run the analysis
        5) combine results across implicates 
	6) rounds final estimates
        7) generates lifecycle earnings graph
        NOTE: step 4 is repeated for analysis with and without replicate weights
*/

/*
USER MUST EDIT THE DATA AND OUTPUT PATHS BELOW AND THE NUMBER OF MULTIPLES AND REPLICATES
*/


/*
Set paths and data settings
*/
global base /rdcprojects/co/co00517/SSB
global version v7.0
global myid specXXX

global output "${base}/programs/users/${myid}/example/output"
global mydata "${base}/programs/users/${myid}/example/mydata"

global data SSB /* "SSB" for synthetic data, "GSF" for validation */
global multiples 4 /* number of multiples chosen in imputeSSB.set */
global replicates 4 /* "4" for synthetic, "1" for validation */





*loop through SSB/GSF data files
forvalues k=1/$replicates {
*loop through completed files
forvalues m=1/$multiples {


/* 
1. ADJUST THE PERSON WEIGHTS FOR THE RELATIE SIZE OF EACH PANEL
*/
use male race hispanic foreign_born personid panel using ${mydata}/ssb_imputed_repw`k'_`m'.dta, clear
keep if male==1 & race==1 & hispanic==0 & foreign_born==0 & panel>=1990 & panel<=1993
drop male race hispanic foreign_born
fcollapse (count) panel_tot=personid, by(panel) fast
keep panel panel_tot
egen tot=total(panel_tot)
gen PanelSize=panel_tot/tot
compress
save ${mydata}/temp_panel_size.dta, replace

use ${mydata}/ssb_imputed_repw`k'_`m'.dta, clear
keep if male==1 & race==1 & hispanic==0 & foreign_born==0 & panel>=1990 & panel<=1993
drop male race hispanic foreign_born
merge m:1 panel using ${mydata}/temp_panel_size.dta, gen(_mergePanelSize) keepusing(PanelSize)
gen initwgt_reweight=initwgt*(1/PanelSize)
forvalues r=1/108 {
	gen repweight_reweight`r'=repweight`r'*(1/PanelSize)
}
compress
save ${mydata}/ssb_imputed_repw_reweight`k'_`m'.dta, replace





/*
2. TRANSPOSE THE DATASET FROM WIDE TO LONG AND KEEP ONLY VARIABLES NEEDED FOR ANALYSIS
*/
forvalues i=1978/2011 {
	use total_der_fica* birthdate panel varstrat halfsamp initwgt* repweight* using ${mydata}/ssb_imputed_repw_reweight`k'_`m'.dta, clear
	keep if panel>=1990
	drop panel
	rename total_der_fica_`i' total_der_fica
	gen int year=`i'
	di "Saving year `i'"
	tempfile year`i'
	compress
	qui save `year`i''
}
local counter=0
forvalues i=1978/2011 {
	local counter=`counter'+1
	di "Loading year `i'"
	if `counter'==1 use `year`i'', clear
	else append using `year`i''
}
compress
save ${mydata}/ssb_imputed_repw_long`k'_`m'.dta, replace





/*
3. CREATE ADDITIONAL VARIABLES NEEDED FOR ANALYSIS
*/
use ${mydata}/ssb_imputed_repw_long`k'_`m'.dta, clear
gen age=year-year(birthdate)
keep if age>=25 & age<=60
gen log_total_der_fica=log(total_der_fica)
svyset halfsamp [pw=initwgt_reweight], strata(varstrat) brrweight(repweight_reweight*) fay(0.5)
compress
save ${mydata}/ssb_imputed_repw_long_reg`k'_`m'.dta, replace





/*
4. REGRESSION AND SAVE/ORGANIZE RESULTS
*/
reg log_total_der_fica ibn.age [pw=initwgt_reweight], noc
local N=e(N)
matrix beta=e(b)'
matrix varcov=e(V)
matrix var=vecdiag(varcov)'
matrix LCoutput`k'_`m'=(beta,var)
matrix colnames LCoutput`k'_`m' = beta`k'_`m' var`k'_`m'

clear
set obs 36
gen N`k'_`m'=.
replace N`k'_`m'=`N'
svmat LCoutput`k'_`m', names(col)
save ${mydata}/LCoutput`k'_`m'.dta, replace

use ${mydata}/ssb_imputed_repw_long_reg`k'_`m'.dta, clear
svy brr: reg log_total_der_fica ibn.age, noc
local N=e(N)
matrix beta=e(b)'
matrix varcov=e(V)
matrix var=vecdiag(varcov)'
matrix LCoutputNorepw`k'_`m'=(beta,var)
matrix colnames LCoutputNorepw`k'_`m' = beta`k'_`m' var`k'_`m'

clear
set obs 36
gen N`k'_`m'=.
replace N`k'_`m'=`N'
svmat LCoutputNorepw`k'_`m', names(col)
save ${mydata}/LCoutputNorepw`k'_`m'.dta, replace


}
}





/*
5. COMBINE RESULTS ACROSS IMPLICATES INTO FINAL OUTPUT, AND ROUND FINAL RESULTS
*/
*loop through outcome-specification combinations
local outcomes LCoutput LCoutputNorepw
foreach out of local outcomes {

        *1. MERGE RESULTS ACROSS IMPLICATES, FOR GIVEN OUTCOME-SPECIFICATION
        *load first outcome-specification and specify the remaining
        if "$data"=="GSF" {
        forvalues m=1/$multiples {
                if "`m'"=="1" {
                use ${mydata}/`out'1_`m'.dta, clear
                }
                else if "`m'"!="1" {
                merge 1:1 _n using ${mydata}/`out'1_`m'.dta, nogen
                }
        }
        save ${mydata}/Combined`out'.dta, replace

        *2. COMBINE THE ESTIMATES
        egen Beta=rowmean(beta1_1 beta1_2 beta1_3 beta1_4)
        egen betasd=rowsd(beta1_1 beta1_2 beta1_3 beta1_4)
        gen betavar=betasd*betasd
        egen meanvar=rowmean(var1_1 var1_2 var1_3 var1_4)
        gen totalvar=meanvar + (1+(1/$multiples))*betavar
        gen SE=sqrt(totalvar)
        gen Tstat=Beta/SE
        egen N=rowmean(N1_1 N1_2 N1_3 N1_4)
        gen df=($multiples-1)*(1+(meanvar)/((1+(1/$multiples))*betavar))^2
        gen criticalvalue95=invttail(df,.025)
        gen criticalvalue90=invttail(df,.05)
        gen criticalvalue99=invttail(df,.005)
        gen CIUpper95=Beta+SE*criticalvalue95
        gen CILower95=Beta-SE*criticalvalue95

        keep Beta SE Tstat N criticalvalue95 criticalvalue90 criticalvalue99 CIUpper95 CILower95
        gen age=(_n+24)
	save ${mydata}/Final`out'.dta, replace
        }


        else if "$data"=="SSB" {
        *1. MERGE RESULTS ACROSS IMPLICATES, FOR GIVEN OUTCOME-SPECIFICATION
        *load first outcome-specification and specify the remaining
        forvalues m=1/$multiples {
	forvalues k=1/$replicates {
                if "`m'"=="1" & "`k'"=="1" {
                use ${mydata}/`out'`k'_`m'.dta, clear
                }
                else if "`m'"!="1" | "`k'"!="1" {
                merge 1:1 _n using ${mydata}/`out'`k'_`m'.dta, nogen
                }
        }
	}
        save ${mydata}/Combined`out'.dta, replace

        *2. COMBINE THE ESTIMATES
        egen Beta=rowmean(beta1_1 beta1_2 beta1_3 beta1_4 beta2_1 beta2_2 beta2_3 beta2_4 beta3_1 beta3_2 beta3_3 beta3_4 beta4_1 beta4_2 beta4_3 beta4_4)
        egen meanbeta1=rowmean(beta1_1 beta1_2 beta1_3 beta1_4)
        egen meanbeta2=rowmean(beta2_1 beta2_2 beta2_3 beta2_4)
        egen meanbeta3=rowmean(beta3_1 beta3_2 beta3_3 beta3_4)
        egen meanbeta4=rowmean(beta4_1 beta4_2 beta4_3 beta4_4)
        egen sdmeans=rowsd(meanbeta1 meanbeta2 meanbeta3 meanbeta4)
        gen varmeans=sdmeans*sdmeans
        egen meanvar=rowmean(var1_1 var1_2 var1_3 var1_4 var2_1 var2_2 var2_3 var2_4 var3_1 var3_2 var3_3 var3_4 var4_1 var4_2 var4_3 var4_4)
        egen sd1=rowsd(beta1_1 beta1_2 beta1_3 beta1_4)
        egen sd2=rowsd(beta2_1 beta2_2 beta2_3 beta2_4)
        egen sd3=rowsd(beta3_1 beta3_2 beta3_3 beta3_4)
        egen sd4=rowsd(beta4_1 beta4_2 beta4_3 beta4_4)
        gen var1=sd1*sd1
        gen var2=sd2*sd2
        gen var3=sd3*sd3
        gen var4=sd4*sd4
        egen meanvars=rowmean(var1 var2 var3 var4)
        gen totalvar=meanvar+(1/$replicates)*varmeans+(1+1/$multiples)*meanvars
        gen SE=sqrt(totalvar)
        gen Tstat=Beta/SE
        egen N=rowmean(N1_1 N1_2 N1_3 N1_4 N2_1 N2_2 N2_3 N2_4 N3_1 N3_2 N3_3 N3_4 N4_1 N4_2 N4_3 N4_4)
        gen dfcomp1=(1+1/$multiples)*meanvars+meanvar
        gen dfcomp2=(1/$replicates)*varmeans
        gen df=($replicates-1)*(1+dfcomp1/dfcomp2)^2
        gen criticalvalue95=invttail(df,.025)
        gen criticalvalue90=invttail(df,.05)
        gen criticalvalue99=invttail(df,.005)
        gen CIUpper95=Beta+SE*criticalvalue95
        gen CILower95=Beta-SE*criticalvalue95

        keep Beta SE Tstat criticalvalue95 criticalvalue90 criticalvalue99 CIUpper95 CILower95 N
        gen age=(_n+24)
	save ${mydata}/Final`out'.dta, replace
        }





/*
6. ROUND THE FINAL ESTIMATES
*/
        *round model estimates to <=4 significant digits (note, this doesn't handle the rounding of estimates larger than 1,000,000 correctly)
        foreach var of varlist Beta SE Tstat criticalvalue95 criticalvalue90 criticalvalue99 CIUpper95 CILower95 {
                replace `var' = round(`var',.0001) if abs(`var')<1
                replace `var' = round(`var',.001) if abs(`var')>=1 & abs(`var')<10
                replace `var' = round(`var',.01) if abs(`var')>=10 & abs(`var')<100
                replace `var' = round(`var', .1) if abs(`var') > 100 & abs(`var') <= 999
                replace `var' = round(`var', 1) if abs(`var') >= 1000 & abs(`var') <= 9999
                replace `var' = round(`var', 10) if abs(`var') >= 10000 & abs(`var') <= 99999
                replace `var' = round(`var', 100) if abs(`var') >= 100000
        }
        *round counts to Census rules (note, this doesn't handle the rounding of numbers larger than 1,000,000 correctly)
        foreach var of varlist N {
                replace `var' = . if `var' <15
                replace `var' = round(`var',10) if `var' >=15 & `var'<=99
                replace `var' = round(`var', 50) if `var' >= 100 & `var' <= 999
                replace `var' = round(`var', 100) if `var' >= 1000 & `var' <= 9999
                replace `var' = round(`var', 500) if `var' >= 10000 & `var' <= 99999
                replace `var' = round(`var', 1000) if `var' >= 100000
        }
        save ${mydata}/Final`out'.dta, replace
}





/*
7. GENERATE GRAPH OF LIFE-CYCLE EARNINGS
*/
use ${mydata}/FinalLCoutputNorepw.dta, clear
keep Beta N CIUpper95 CILower95 age
foreach var in Beta N CIUpper95 CILower95 {
	rename `var' `var'Norepw
}
merge 1:1 age using ${mydata}/FinalLCoutput.dta, keepusing(Beta N CIUpper95 CILower95) gen(_mergeRepw)

twoway (rarea CIUpper95Norepw CILower95Norepw age, pstyle(ci) color(ltblue)) ///
(rarea CIUpper95 CILower95 age, pstyle(ci) color(pink) fi(15)) ///
(connected Beta age), ///
ytitle(Log Annual Earnings) xtitle(Age) ///
title("Life-Cycle Earnings - SRMI", size(medium)) ///
yscale(range(9 11)) ylabel(9(.5)11) xlabel(25(5)60)
graph save ${output}/GraphSRMI.gph, replace




