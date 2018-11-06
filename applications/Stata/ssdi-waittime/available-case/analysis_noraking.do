/*
Example program for running analysis with NON-RAKED available-case data and
        including replicate weights. The program performs the analysis separately over
        all replicate files, saves the results from each replicate, and combines
        those results into a final output for each analysis.

This analysis estimates the mean adjudication wait time for the first SSDI application
	seperately for males and females. This is done by regressing mean wait time 
	on a dummy variable for each gender (excluding the constant). The mean 
	wait times are then plotted in a bar graph, seperately for males vs females 
	and with vs without replicate weights for standard error construction.

Analysis with and without replicate weights is included in this file.


input files: 1) available case data with replicate weights
output files: 1) stata dataset with combined estimation results with and without replicate
        weights
              2) bar graph showing mean wait times


STEPS:
        1) create new variables for analysis
        2) run the analysis
        3) combine results across implicates
        4) rounds final estimates
        5) generate mean wait time graphs
        NOTE: step 2 is repeated for analysis with and without replicate weights
*/

/*
USER MUST EDIT THE DATA AND OUTPUT PATHS BELOW AND THE DATA TYPE AND NUMBER OF REPLICATES
*/


/*
Set paths
*/
global base /rdcprojects/co/co00517/SSB
global version v7.0
global myid specXXX

global output "${base}/programs/users/${myid}/example/output"
global mydata "${base}/programs/users/${myid}/example/mydata"

global data SSB  /* "SSB" for synthetic data, "GSF" for internal validation */
global replicates 4  /* "4" for synthetic data, "1" for internal validation */





*loop through data files
forvalues k=1/$replicates {

/*
1. CREATE ADDITIONAL VARIABLES NEEDED FOR ANALYSIS
*/
use ${mydata}/ssb_available_repw_rake`k'.dta, clear
gen black=0
replace black=1 if race==2
gen otherrace=0
replace otherrace=1 if race==2

gen female=0
replace female=1 if male==0

gen onset_age_year1=year(mbr_ssdi_ddo_1)-year(birthdate)
gen onset_age_month1=month(mbr_ssdi_ddo_1)-month(birthdate)

gen adjud_age_year1=year(mbr_ssdi_dsd_1)-year(birthdate)
gen adjud_age_month1=month(mbr_ssdi_dsd_1)-month(birthdate)

gen adjud_wait1=(adjud_age_year1-onset_age_year1)*12 + adjud_age_month1-onset_age_month1

keep if black==0 & otherrace==0 & hispanic==0 & panel==1996

svyset halfsamp [pw=initwgt], strata(varstrat) brrweight(repweight*) fay(0.5)

save ${mydata}/ssb_imputed_repw_reg`k'.dta, replace





/*
2. REGRESSION AND SAVE/ORGANIZE RESULTS
*/
svy brr: reg adjud_wait1 ibn.female, noc
local N=e(N)
matrix beta=e(b)'
matrix varcov=e(V)
matrix var=vecdiag(varcov)'
matrix SSDIoutputNorake`k'=(beta,var)
matrix colnames SSDIoutputNorake`k' = beta`k' var`k'
preserve
{
clear
set obs 2
gen N`k'=.
replace N`k'=`N'
svmat SSDIoutputNorake`k', names(col)
save ${mydata}/SSDIoutputNorake`k'.dta, replace
}
restore

reg adjud_wait1 ibn.female [pw=initwgt], noc
local N=e(N)
matrix beta=e(b)'
matrix varcov=e(V)
matrix var=vecdiag(varcov)'
matrix SSDIoutputNorakeNorepw`k'=(beta,var)
matrix colnames SSDIoutputNorakeNorepw`k' = beta`k' var`k'
preserve
{
clear
set obs 2
gen N`k'=.
replace N`k'=`N'
svmat SSDIoutputNorakeNorepw`k', names(col)
save ${mydata}/SSDIoutputNorakeNorepw`k'.dta, replace
}
restore


}





/*
3. COMBINE RESULTS ACROSS IMPLICATES INTO FINAL OUTPUT
*/
*loop through outcome-specification combinations
local outcomes SSDIoutputNorake SSDIoutputNorakeNorepw
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
        gen str6 gender="."
	replace gender="male" if _n==1
	replace gender="female" if _n==2
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
        gen df=($replicates-1)*(1+(meanvar/((1/$replicates)*varmeans)))^2
        gen criticalvalue95=invttail(df,.05)
        gen criticalvalue90=invttail(df,.10)
        gen criticalvalue99=invttail(df,.01)
        gen CIUpper95=Beta+SE*criticalvalue95
        gen CILower95=Beta-SE*criticalvalue95

        keep Beta SE Tstat criticalvalue95 criticalvalue90 criticalvalue99 CIUpper95 CILower95 N
        gen str6 gender="."
	replace gender="male" if _n==1
	replace gender="female" if _n==2
        save ${mydata}/Final`out'.dta, replace
        }





/*
*4. ROUND THE FINAL ESTIMATES
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
5. GENERATE GRAPH OF MEAN WAIT TIMES
*/
use ${mydata}/FinalSSDIoutputNorakeNorepw.dta, clear
append using ${mydata}/FinalSSDIoutputNorake.dta, gen(Repw)
gen order=.
gen female=(gender=="female")
replace order=1 if Repw==0 & female==0
replace order=2 if Repw==0 & female==1
replace order=4 if Repw==1 & female==0
replace order=5 if Repw==1 & female==1


 twoway bar  Beta order if(female==0) ///
	|| bar Beta order if(female==1) ///
	|| rcap  CILower95 CIUpper95 order ///
	,lwidth(medthick) lcolor(black) msize(huge) ///
	, yscale(range(0 40)) xscale(range(0 6))  ///
	ylabel(10(10)40) ///
	xlabel( 1.5 "Without replicate weights" 4.5 "With replicate weights", noticks) ///
	legend( ///
			cols(3) ///
			label(1 "Male") ///
			label(2 "Female") ///
			label(3 "95% CI")  ///
			)  ///
	xtitle("") ytitle("Mean Wait Time (Months)") title("Adjudication Wait Time - No Missing Data Adjustments")

graph save Graph ${output}/GraphNorake.gph, replace




