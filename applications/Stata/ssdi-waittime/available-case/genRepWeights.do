
/*
This program creates replicate weights. First, a Hadamard matrix
	is created, which is used to select half-samples within each stratum for a particular 
	replicate. Then, the replicate factors and replicate weights are created, given the
	Hadamard values. 128 replicates are created.

Input files: synthetic SSB data files
Output files: synthetic SSB data files, with replicate weights attached

Steps:
	1) Create Hadamard matrix
	2) Merge Hadamard values to the multiply-imputed SSB by merging on stratum
	3) Create replicate factors and the resulting replicate weights
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
*create stratum variable, for merging with GSF
gen varstrat=_n
save ${mydata}/hadamard.dta, replace





/*
2. MERGE HADAMARD MATRIX TO THE SSB
*/
use ${mydata}/ssb_available${k}.dta, clear
merge m:1 varstrat using ${mydata}/hadamard.dta, gen(_mergeHada) 
drop if _mergeHada==2 //drop hadamard rows which didn't match to data, because hadamard has to create more rows than there are strata





/*
3. CREATE REPLICATE FACTORS AND WEIGHTS
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
save ${mydata}/ssb_available_repw${k}.dta, replace





