/*
Example program for running analysis with data that has been completed using SRMI and
        includes replicate weights. The program performs the analysis separately over
        all completed data files, saves the results from each file, and combines
        those results into a final output for each analysis.

This analysis estimates the mean adjudication wait time for the first SSDI application
        seperately for males and females. This is done by regressing mean wait time
        on a dummy variable for each gender (excluding the constant). The mean
        wait times are then plotted in a bar graph, seperately for males vs females
        and with vs without replicate weights for standard error construction.

Analysis with and without replicate weights is included in this file.

input files: 1) completed data files with replicate weights
output files: 1) stata dataset with combined estimation results with and without replicate
        weights
              2) bar graph showing mean wait times


STEPS:
        1) create new variables for analysis
        2) run the analysis
        3) combine results across implicates
	4) round final estimates
        5) generates lifecycle earnings graph
        NOTE: step 4 is repeated for analysis with and without replicate weights
*/

/*
USER MUST EDIT THE DATA AND OUTPUT PATHS BELOW AND THE DATATYPE AND REPLICATE AND MULTIPLES NUMBER
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
1. CREATE ADDITIONAL VARIABLES NEEDED FOR ANALYSIS
*/
use ${mydata}/ssb_imputed_repw`k'_`m'.dta, clear
gen black=0
replace black=1 if race==2
gen otherrace=0
replace otherrace=1 if race==3

gen female=0
replace female=1 if male==0

gen onset_age_year1=year(mbr_ssdi_ddo_1)-year(birthdate)
gen onset_age_month1=month(mbr_ssdi_ddo_1)-month(birthdate)

gen adjud_age_year1=year(mbr_ssdi_dsd_1)-year(birthdate)
gen adjud_age_month1=month(mbr_ssdi_dsd_1)-month(birthdate)

gen adjud_wait1=(adjud_age_year1-onset_age_year1)*12 + adjud_age_month1-onset_age_month1

keep if black==0 & otherrace==0 & hispanic==0 & panel==1996

svyset halfsamp [pw=initwgt], strata(varstrat) brrweight(repweight*) fay(0.5)





/*
2. REGRESSION AND SAVE/ORGANIZE RESULTS
*/
svy brr: reg adjud_wait1 ibn.female, noc
local N=e(N)
matrix beta=e(b)'
matrix varcov=e(V)
matrix var=vecdiag(varcov)'
matrix SSDIoutput`k'_`m'=(beta,var)
matrix colnames SSDIoutput`k'_`m' = beta`k'_`m' var`k'_`m'
preserve
{
clear
set obs 2
gen N`k'_`m'=.
replace N`k'_`m'=`N'
svmat SSDIoutput`k'_`m', names(col)
save ${mydata}/SSDIoutput`k'_`m'.dta, replace
}
restore

reg adjud_wait1 ibn.female [pw=initwgt], noc
local N=e(N)
matrix beta=e(b)'
matrix varcov=e(V)
matrix var=vecdiag(varcov)'
matrix SSDIoutputNorepw`k'_`m'=(beta,var)
matrix colnames SSDIoutputNorepw`k'_`m' = beta`k'_`m' var`k'_`m'
preserve
{
clear
set obs 2
gen N`k'_`m'=.
replace N`k'_`m'=`N'
svmat SSDIoutputNorepw`k'_`m', names(col)
save ${mydata}/SSDIoutputNorepw`k'_`m'.dta, replace
}
restore

}
}





/*
3. COMBINE RESULTS ACROSS IMPLICATES INTO FINAL OUTPUT, AND ROUND FINAL RESULTS
*/
*loop through outcome-specification combinations
local outcomes SSDIoutput SSDIoutputNorepw
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
        gen str6 gender="."
	replace gender="male" if _n==1
	replace gender="female" if _n==2
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
        gen df=($replicates-1)*((1+dfcomp1/dfcomp2)^2)
        gen criticalvalue95=invttail(df,.025)
        gen criticalvalue90=invttail(df,.05)
        gen criticalvalue99=invttail(df,.005)
        gen CIUpper95=Beta+SE*criticalvalue95
        gen CILower95=Beta-SE*criticalvalue95

        keep Beta SE Tstat criticalvalue95 criticalvalue90 criticalvalue99 CIUpper95 CILower95 N
        gen str6 gender="."
	replace gender="male" if _n==1
	replace gender="female" if _n==2
	save ${mydata}/Final`out'.dta, replace
        }



/*
4. ROUND THE FINAL ESTIMATES
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
5. GENERATE GRAPH OF LIFE-CYCLE EARNINGS
*/
use ${mydata}/FinalSSDIoutputNorepw.dta, clear
append using ${mydata}/FinalSSDIoutput.dta, gen(Repw)
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
	xtitle("") ytitle("Mean Wait Time (Months)") title("Adjudication Wait Time - SRMI")

graph save Graph ${output}/GraphSRMI.gph, replace




