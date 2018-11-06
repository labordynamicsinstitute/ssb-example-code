
/*
This file creates the replicate weights and adds them to each of the completed
        implicates

input files: 1) a single completed data implicate
output files: 1) completed data implicate with replicate weights added

STEPS:
        1) create hadamard matrix, used to select half-samples for construction of replicate
                weights
        2) match hadamard matrix to completed data implicates
        3) create replicate factors and replicate weights
*/

***USER DOES NOT NEED TO CHANGE ANYTHING***





/*
1. CREATE HADAMARD MATRIX, for use in creating replicate weights (start with h2, then multiply until
	the needed size is reached. The Hadamard matrix should have at least as many columns as number
	of strata (there are 104 stratum in the 1996 SIPP panel)
*/
clear
matrix h2 = (-1, 1 \ 1, 1)
matrix had = h2
forvalues i = 1/6 {
	matrix had = h2 # had
}
*convert matrix to variables
svmat double had
*create stratum variable, for merging with multiply-imputed SSB
gen varstrat=_n
save ${mydata}/Hadamard.dta, replace





*loop through implicates
forvalues m=1/4 {
global m `m'

/*
2. Merge Hadamard matrix to the imputed datset
*/
use ${mydata}/ssb_imputed${k}_${m}.dta, clear
merge m:1 varstrat using ${mydata}/Hadamard.dta, gen(_mergeHada) 
drop if _mergeHada==2 //drop hadamard rows which didn't match to data, because hadamard has to create more rows than there are strata
save $mydata/ssb_imputed_repw${k}_${m}.dta, replace





/*
3. Create replicate factors and weights
*/
forvalues i = 1/128 {
	replace had`i'=2 if had`i'==-1
	
	gen halfrepfac`i'=.
	replace halfrepfac`i'=1.5 if had`i'==halfsamp
	replace halfrepfac`i'=0.5 if had`i'!=halfsamp

	gen repweight`i'=.
	replace repweight`i'=initwgt*halfrepfac`i'
}
drop had* halfrepfac*
save ${mydata}/ssb_imputed_repw${k}_${m}.dta, replace


}




