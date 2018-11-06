
/*/ 
This file creates the replicate weights and adds them to each of the available-case datasets 
/*/


/*/ 
input files: 1) available-case dataset for each synthetic SSB file
output files: 1) available-case datasets, with replicate weights added 
/*/


/*/ 
STEPS:
	1) create hadamard matrix, used to select half-samples for construction of replicate
        	weights
	2) match hadamard matrix to available-case dataset
	3) create replicate factors and replicate weights
/*/

***NOTHING NEEDS TO BE EDITED***;



/*/ 1. CREATE HADAMARD MATRIX /*/
proc iml;
H=HADAMARD(108); /*/ 108 because the program is going to make 105 replicate weights and the
        HADAMARD number has to be a multilpe of 4 - 108 is the smallest multiple of 4 at
        least as large as 105 /*/
H=H[,2:106]`; /*/ The first column is a throw-away in the creation of replicate weights.
        Then, keep the first 105 columns /*/
stratanum=j(1,105); /*/ create varstrat id variables, to combine with the HADAMARD matrix /*/
stratanum[1,]=1:105;
stratanum=stratanum`;
Hlabels=j(105,109); /*/ place HADAMARD and varstrat id together in new matrix /*/
Hlabels[,1:108]=H;
Hlabels[,109]=stratanum;
create Hlabels from Hlabels; /*/ save the matrix /*/
append from Hlabels;
save;

* Edit HADAMARD matrix column names and change -1/1 values to 2/1 in order to match to;
        *half-sample ids;
data mydata.H (keep=halfselect1-halfselect108 varstrat);
set Hlabels;
rename col109=varstrat;
array col[*] col1-col108;
array halfselect[*] halfselect1-halfselect108;
        do i=1 to dim(halfselect);
        if col[i]=1 then halfselect[i]=1;
        if col[i]=-1 then halfselect[i]=2;
        end;
run;





/*/ 2. MATCH HADAMARD HALF-SAMPLE SELECTION MATRIX TO GSF /*/
proc sort data=mydata.ssb_availablecase&k. out=mydata.ssb_availablecase&k.;
by varstrat;
run;

proc sort data=mydata.H out=mydata.H;
by varstrat;
run;

data mydata.ssb_available_repw&k.;
merge mydata.ssb_availablecase&k.(in=g) mydata.H(in=h);
by varstrat;
if g=1 and h=1;
run;





/*/ 3. CREATE REPLICATION FACTORS AND WEIGHTS /*/
data mydata.ssb_available_repw&k.;
set  mydata.ssb_available_repw&k.;
        array halfselect[*] halfselect1-halfselect108;
        array halfrepfac[*] halfrepfac1-halfrepfac108;
        do i=1 to dim(halfselect);
        if halfsamp=halfselect[i] then halfrepfac[i]=1.5;
        else halfrepfac[i]=0.5;
        end;
drop halfselect:;
run;


data mydata.ssb_available_repw&k. (drop=halfselect1-halfselect108 halfrepfac1-halfrepfac108);
set mydata.ssb_available_repw&k.;
        array halfrepfac[*] halfrepfac1-halfrepfac108;
        array repweight[*] repweight1-repweight108;
        do i=1 to dim(halfrepfac);
        repweight[i]=initwgt*halfrepfac[i];
        end;
drop halfrepfac:;
run;




