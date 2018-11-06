/*
Example program for running analysis with NON-RAKED available-case data and
        including replicate weights. The program performs the analysis separately over
        all data files, saves the results from each file, and combines
        those results into a final output for each analysis.

The analysis estimates life-cycle earnings by regressing log annual earnings on age
        dummy variables, and then plots the coefficients on the age variables.

Because the analysis includes individiuals from multiple SIPP panels, we re-weight
        the SIPP weights (replicate weights and original SIPP weight) based on the
        relative size of each panel.

Analysis with and without replicate weights is included in this file.


input files: 1) available case data with replicate weights
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
USER MUST EDIT THE DATA AND OUTPUT PATHS BELOW AND THE DATA TYPE AND REPLICATES NUMBER
*/


/*
Set paths
*/
global base /rdcprojects/co/co00517/SSB
global version v7.0
global myid specXXX

global output "${base}/programs/users/${myid}/example/output"
global mydata "${base}/programs/users/${myid}/example/mydata"

global data SSB   /* "SSB" for synthetic data, "GSF" for internal validation */
global replicates 4  /* "4" for synthetic data, "1" for internal validation */





*loop through data files
forvalues k=1/$replicates {

/* 
1. ADJUST THE PERSON WEIGHTS FOR THE RELATIVE SIZE OF EACH PANEL
*/
use ${mydata}/ssb_available_repw_rake`k'.dta, clear
fcollapse (count) panel_tot=personid, by(panel) fast
keep panel panel_tot
egen tot=total(panel_tot)
gen PanelSize=panel_tot/tot
compress
save ${mydata}/temp_panel_size.dta, replace

use ${mydata}/ssb_available_repw_rake`k'.dta, clear
merge m:1 panel using ${mydata}/temp_panel_size.dta, gen(_mergePanelSize)
gen initwgt_reweight=initwgt*(1/PanelSize)
gen finalinitwgt_reweight=finalinitwgt*(1/PanelSize)
forvalues r=1/108 {
        gen repweight_reweight`r'=repweight`r'*(1/PanelSize)
	gen finalrepweight_reweight`r'=finalrepweight`r'*(1/PanelSize)
}
compress
save ${mydata}/ssb_available_repw_reweight`k'.dta, replace





/*
2. TRANSPOSE THE DATASET FROM WIDE TO LONG
*/
forvalues i=1978/2011 {
        use total_der_fica* birthdate panel varstrat halfsamp initwgt* repweight* using ${mydata}/ssb_available_repw_reweight`k'.dta, clear
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
save ${mydata}/ssb_available_repw_long`k'.dta, replace





/*
3. CREATE ADDITIONAL VARIABLES NEEDED FOR ANALYSIS
*/
gen age=year-year(birthdate)
keep if age>=25 & age<=60
gen log_total_der_fica=log(total_der_fica)
svyset halfsamp [pw=initwgt_reweight], strata(varstrat) brrweight(repweight_reweight*) fay(0.5)
save ${mydata}/ssb_available_repw_long_reg`k'.dta, replace





/*
4. REGRESSION AND SAVE/ORGANIZE RESULTS
*/
reg log_total_der_fica ibn.age [pw=initwgt_reweight], noc
local N=e(N)
matrix beta=e(b)'
matrix varcov=e(V)
matrix var=vecdiag(varcov)'
matrix LCoutputNorake`k'=(beta,var)
matrix colnames LCoutputNorake`k' = beta`k' var`k'
preserve
{
clear
set obs 36
gen N`k'=.
replace N`k'=`N'
svmat LCoutputNorake`k', names(col)
save ${mydata}/LCoutputNorake`k'.dta, replace
}
restore


svy brr: reg log_total_der_fica ibn.age, noc
local N=e(N)
matrix beta=e(b)'
matrix varcov=e(V)
matrix var=vecdiag(varcov)'
matrix LCoutputNorakeNorepw`k'=(beta,var)
matrix colnames LCoutputNorakeNorepw`k' = beta`k' var`k'
preserve
{
clear
set obs 36
gen N`k'=.
replace N`k'=`N'
svmat LCoutputNorakeNorepw`k', names(col)
save ${mydata}/LCoutputNorakeNorepw`k'.dta, replace
}
restore

}





/*
5. COMBINE RESULTS ACROSS IMPLICATES INTO FINAL OUTPUT, AND ROUND FINAL RESULTS
*/
*loop through outcome-specification combinations
local outcomes LCoutputNorake LCoutputNorakeNorepw
foreach out of local outcomes {

        *1. MERGE RESULTS ACROSS IMPLICATES, FOR GIVEN OUTCOME-SPECIFICATION
        *load first outcome-specification and specify the remaining
        if "$data"=="GSF" {
        use ${mydata}/`out'1.dta, clear
        save ${mydata}/Combined`out'.dta, replace
	
	*2. COMBINE THE ESTIMATES
	rename beta Beta
	rename var totalvar
	gen SE=sqrt(totalvar)
	gen Tstat=Beta/SE
	gen criticalvalue95=1.96
	gen criticalvalue90=1.645
	gen criticalvalue99=2.58
        gen CIUpper95=Beta+SE*criticalvalue95
        gen CILower95=Beta-SE*criticalvalue95

        keep Beta SE Tstat N criticalvalue95 criticalvalue90 criticalvalue99 CIUpper95 CILower95
        gen age=(_n+24)
        save ${mydata}/Final`out'.dta, replace
        }


        else if "$data"=="SSB" {
        *1. MERGE RESULTS ACROSS IMPLICATES, FOR GIVEN OUTCOME-SPECIFICATION
        *load first outcome-specification and specify the remaining
        forvalues k=1/$replicates {
                if "`k'"=="1" {
                use ${mydata}/`out'`k'.dta, clear
                }
                else if "`k'"!="1" {
                merge 1:1 _n using ${mydata}/`out'`k'.dta, nogen
                }
        }
        save ${mydata}/Combined`out'.dta, replace

        *2. COMBINE THE ESTIMATES
        egen Beta=rowmean(beta1 beta2 beta3 beta4)
        egen sdmeans=rowsd(beta1 beta2 beta3 beta4)
        gen varmeans=sdmeans*sdmeans
        egen meanvar=rowmean(var1 var2 var3 var4)
        gen totalvar=meanvar+(1/$replicates)*varmeans
        gen SE=sqrt(totalvar)
        gen Tstat=Beta/SE
        egen N=rowmean(N1 N2 N3 N4)
        gen df=($replicates-1)*(1+meanvar/((1/$replicates)*varmeans))^2
        gen criticalvalue95=invttail(df,.05)
        gen criticalvalue90=invttail(df,.10)
        gen criticalvalue99=invttail(df,.01)
        gen CIUpper95=Beta+SE*criticalvalue95
        gen CILower95=Beta-SE*criticalvalue95

        keep Beta SE Tstat criticalvalue95 criticalvalue90 criticalvalue99 CIUpper95 CILower95 N
        gen age=(_n+24)
        save ${mydata}/Final`out'.dta, replace
        }





/*
6. ROUND THE FINAL ESTIMATES
*/
        *round model estimates to <=4 significant digits (note, this doesn't handle the round of estimates larger than 1,000,000 correctly)
        foreach var of varlist Beta SE Tstat criticalvalue95 criticalvalue90 criticalvalue99 CIUpper95 CILower95 {
                replace `var' = round(`var',.0001) if abs(`var')<1
                replace `var' = round(`var',.001) if abs(`var')>=1 & abs(`var')<10
                replace `var' = round(`var',.01) if abs(`var')>=10 & abs(`var')<100
                replace `var' = round(`var', .1) if abs(`var') > 100 & abs(`var') <= 999
                replace `var' = round(`var', 1) if abs(`var') >= 1000 & abs(`var') <= 9999
                replace `var' = round(`var', 10) if abs(`var') >= 10000 & abs(`var') <= 99999
                replace `var' = round(`var', 100) if abs(`var') >= 100000
        }
        *round counts to Census rules (note, this doesn't handle the round of numbers larger than 1,000,000 correctly)
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

use ${mydata}/FinalLCoutputNorakeNorepw.dta, clear
keep Beta N CIUpper95 CILower95 age
foreach var in Beta N CIUpper95 CILower95 {
	rename `var' `var'Norepw
}
merge 1:1 age using ${mydata}/FinalLCoutputNorake.dta, keepusing(Beta N CIUpper95 CILower95) gen(_mergeRepw)

twoway (rarea CIUpper95Norepw CILower95Norepw age, pstyle(ci) color(ltblue)) ///
(rarea CIUpper95 CILower95 age, pstyle(ci) color(pink) fi(15)) ///
(connected Beta age), ///
ytitle(Log Annual Earnings) xtitle(Age) ///
title("Life-Cycle Earnings - No Missing Data Adjustments", size(medium)) ///
yscale(range(9 11)) ylabel(9(.5)11) xlabel(25(5)60)
graph save ${output}/GraphNoraking.gph, replace



