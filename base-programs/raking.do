
/*
This program rakes the initial weight and replicate weights, so that the available case set
        of variables for the analysis are representative of poputation control totals.
*/

/*
input files: 1) available case SSB data files with replicate weights  2) population control data in
        cross-tabulated form
output files: 1) available case SSB data files with initial weight and replicate weights that have been
        raked
*/

/*
STEPS:
	1) assign each person in the available case SSB into their category for each of the five
        	dimensions
	2) create raking macro, which rakes a given weight until either max number of iterations
        	is reached or max difference between control and observed marginal totals for each
        	dim-cat falls below pre-specified threshold
	3) rake the initial weight
	4) rake the replicate weights one-by-one
*/

***USER DOES NOT NEED TO CHANGE ANYTHING, UNLESS THEY WANT TO ADJUST THE CONVERGENCE PARAMETERS***




/*
1. ASSIGN EACH PERSON TO THEIR CATGEGORY FOR EACH DIMENSION
*/
use ${mydata}/ssb_available_repw${k}.dta, clear
keep if panel==$year
format birthdate %td
format sipp_panel_beg_date %td
gen birthyear=year(birthdate)
gen sipp_panel_year=year(sipp_panel_beg_date)
gen start_age=sipp_panel_year-birthyear


gen dim1=.
replace dim1=1 if (male==1) & (hispanic==1) & (start_age<=14)
replace dim1=2 if (male==1) & (hispanic==1) & (start_age>14 & start_age<=24)
replace dim1=3 if (male==1) & (hispanic==1) & (start_age>24 & start_age<=44) 
replace dim1=4 if (male==1) & (hispanic==1) & (start_age>44 & start_age<=64)
replace dim1=5 if (male==1) & (hispanic==1) & (start_age>64)

replace dim1=6 if (male==0) & (hispanic==1) & (start_age<=14)
replace dim1=7 if (male==0) & (hispanic==1) & (start_age>14 & start_age<=24)
replace dim1=8 if (male==0) & (hispanic==1) & (start_age>24 & start_age<=44) 
replace dim1=9 if (male==0) & (hispanic==1) & (start_age>44 & start_age<=64)
replace dim1=10 if (male==0) & (hispanic==1) & (start_age>64) 

replace dim1=11 if (male==1) & (hispanic==0) & (start_age<=14)
replace dim1=12 if (male==1) & (hispanic==0) & (start_age>14 & start_age<=24) 
replace dim1=13 if (male==1) & (hispanic==0) & (start_age>24 & start_age<=44) 
replace dim1=14 if (male==1) & (hispanic==0) & (start_age>44 & start_age<=64)
replace dim1=15 if (male==1) & (hispanic==0) & (start_age>64) 

replace dim1=16 if (male==0) & (hispanic==0) & (start_age<=14) 
replace dim1=17 if (male==0) & (hispanic==0) & (start_age>14 & start_age<=24) 
replace dim1=18 if (male==0) & (hispanic==0) & (start_age>24 & start_age<=44) 
replace dim1=19 if (male==0) & (hispanic==0) & (start_age>44 & start_age<=64) 
replace dim1=20 if (male==0) & (hispanic==0) & (start_age>64)



gen dim2=.
replace dim2=1 if (state==35) & (hispanic==1) 
replace dim2=2 if (state==35) & (hispanic==0)
replace dim2=3 if (state==34) & (hispanic==1) 
replace dim2=4 if (state==34) & (hispanic==0) 
replace dim2=5 if (state==4) & (hispanic==1) 
replace dim2=6 if (state==4) & (hispanic==0) 
replace dim2=7 if (state==17) & (hispanic==1)
replace dim2=8 if (state==17) & (hispanic==0) 
replace dim2=9 if (state==12) & (hispanic==1) 
replace dim2=10 if (state==12) & (hispanic==0)
replace dim2=11 if (state==36) & (hispanic==1) 
replace dim2=12 if (state==36) & (hispanic==0) 
replace dim2=13 if (state==48) & (hispanic==1) 
replace dim2=14 if (state==48) & (hispanic==0) 
replace dim2=15 if (state==6) & (hispanic==1) 
replace dim2=16 if (state==6) & (hispanic==0) 
replace dim2=17 if (dim2==.) & (hispanic==1) 
replace dim2=18 if (dim2==.) & (hispanic==0) 





gen dim3=.
replace dim3=1 if (state==1) & (race!=2) 
replace dim3=2 if (state==1) & (race==2) 
replace dim3=3 if (state==4) & (race!=2) 
replace dim3=4 if (state==4) & (race==2) 
replace dim3=5 if (state==5) & (race!=2) 
replace dim3=6 if (state==5) & (race==2) 
replace dim3=7 if (state==6) & (race!=2) 
replace dim3=8 if (state==6) & (race==2) 
replace dim3=9 if (state==12) & (race!=2) 
replace dim3=10 if (state==12) & (race==2)
replace dim3=11 if (state==13) & (race!=2) 
replace dim3=12 if (state==13) & (race==2) 
replace dim3=13 if (state==17) & (race!=2) 
replace dim3=14 if (state==17) & (race==2) 
replace dim3=15 if (state==18) & (race!=2)
replace dim3=16 if (state==18) & (race==2) 
replace dim3=17 if (state==21) & (race!=2) 
replace dim3=18 if (state==21) & (race==2) 
replace dim3=19 if (state==22) & (race!=2) 
replace dim3=20 if (state==22) & (race==2) 
replace dim3=21 if (state==24) & (race!=2) 
replace dim3=22 if (state==24) & (race==2) 
replace dim3=23 if (state==25) & (race!=2) 
replace dim3=24 if (state==25) & (race==2) 
replace dim3=25 if (state==26) & (race!=2) 
replace dim3=26 if (state==26) & (race==2) 
replace dim3=27 if (state==28) & (race!=2) 
replace dim3=28 if (state==28) & (race==2) 
replace dim3=29 if (state==29) & (race!=2) 
replace dim3=30 if (state==29) & (race==2) 
replace dim3=31 if (state==34) & (race!=2)
replace dim3=32 if (state==34) & (race==2) 
replace dim3=33 if (state==35) & (race!=2) 
replace dim3=34 if (state==35) & (race==2) 
replace dim3=35 if (state==36) & (race!=2)
replace dim3=36 if (state==36) & (race==2) 
replace dim3=37 if (state==37) & (race!=2) 
replace dim3=38 if (state==37) & (race==2) 
replace dim3=39 if (state==39) & (race!=2) 
replace dim3=40 if (state==39) & (race==2) 
replace dim3=41 if (state==42) & (race!=2) 
replace dim3=42 if (state==42) & (race==2) 
replace dim3=43 if (state==45) & (race!=2) 
replace dim3=44 if (state==45) & (race==2) 
replace dim3=45 if (state==47) & (race!=2) 
replace dim3=46 if (state==47) & (race==2)
replace dim3=47 if (state==48) & (race!=2)
replace dim3=48 if (state==48) & (race==2)
replace dim3=49 if (state==51) & (race!=2) 
replace dim3=50 if (state==51) & (race==2) 
replace dim3=51 if (dim3==.) & (race!=2) 
replace dim3=52 if (dim3==.) & (race==2) 





gen dim4=.
replace dim4=1 if (state==1) & (male==1) & (start_age<=14) 
replace dim4=2 if (state==1) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=3 if (state==1) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=4 if (state==1) & (male==1) & (start_age>64) 
replace dim4=5 if (state==1) & (male==0) & (start_age<=14) 
replace dim4=6 if (state==1) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=7 if (state==1) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=8 if (state==1) & (male==0) & (start_age>64) 

replace dim4=9 if (state==2) & (male==1) & (start_age<=14) 
replace dim4=10 if (state==2) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=11 if (state==2) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=12 if (state==2) & (male==1) & (start_age>64) 
replace dim4=13 if (state==2) & (male==0) & (start_age<=14) 
replace dim4=14 if (state==2) & (male==0) & (start_age>14 & start_age<9) 
replace dim4=15 if (state==2) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=16 if (state==2) & (male==0) & (start_age>64) 

replace dim4=17 if (state==4) & (male==1) & (start_age<=14) 
replace dim4=18 if (state==4) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=19 if (state==4) & (male==1) & (start_age>44 & start_age<=64)
replace dim4=20 if (state==4) & (male==1) & (start_age>64)
replace dim4=21 if (state==4) & (male==0) & (start_age<=14)
replace dim4=22 if (state==4) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=23 if (state==4) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=24 if (state==4) & (male==0) & (start_age>64) 

replace dim4=25 if (state==5) & (male==1) & (start_age<=14) 
replace dim4=26 if (state==5) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=27 if (state==5) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=28 if (state==5) & (male==1) & (start_age>64) 
replace dim4=29 if (state==5) & (male==0) & (start_age<=14) 
replace dim4=30 if (state==5) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=31 if (state==5) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=32 if (state==5) & (male==0) & (start_age>64) 

replace dim4=33 if (state==6) & (male==1) & (start_age<=14) 
replace dim4=34 if (state==6) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=35 if (state==6) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=36 if (state==6) & (male==1) & (start_age>64) 
replace dim4=37 if (state==6) & (male==0) & (start_age<=14) 
replace dim4=38 if (state==6) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=39 if (state==6) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=40 if (state==6) & (male==0) & (start_age>64) 

replace dim4=41 if (state==8) & (male==1) & (start_age<=14) 
replace dim4=42 if (state==8) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=43 if (state==8) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=44 if (state==8) & (male==1) & (start_age>64) 
replace dim4=45 if (state==8) & (male==0) & (start_age<=14) 
replace dim4=46 if (state==8) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=47 if (state==8) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=48 if (state==8) & (male==0) & (start_age>64) 

replace dim4=49 if (state==9) & (male==1) & (start_age<=14) 
replace dim4=50 if (state==9) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=51 if (state==9) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=52 if (state==9) & (male==1) & (start_age>64) 
replace dim4=53 if (state==9) & (male==0) & (start_age<=14) 
replace dim4=54 if (state==9) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=55 if (state==9) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=56 if (state==9) & (male==0) & (start_age>64) 

replace dim4=57 if (state==10) & (male==1) & (start_age<=14) 
replace dim4=58 if (state==10) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=59 if (state==10) & (male==1) & (start_age>44 & start_age<=64)
replace dim4=60 if (state==10) & (male==1) & (start_age>64)
replace dim4=61 if (state==10) & (male==0) & (start_age<=14) 
replace dim4=62 if (state==10) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=63 if (state==10) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=64 if (state==10) & (male==0) & (start_age>64) 

replace dim4=65 if (state==11) & (male==1) & (start_age<=14) 
replace dim4=66 if (state==11) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=67 if (state==11) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=68 if (state==11) & (male==1) & (start_age>64) 
replace dim4=69 if (state==11) & (male==0) & (start_age<=14) 
replace dim4=70 if (state==11) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=71 if (state==11) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=72 if (state==11) & (male==0) & (start_age>64) 

replace dim4=73 if (state==12) & (male==1) & (start_age<=14) 
replace dim4=74 if (state==12) & (male==1) & (start_age>14 & start_age<=44)
replace dim4=75 if (state==12) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=76 if (state==12) & (male==1) & (start_age>64)
replace dim4=77 if (state==12) & (male==0) & (start_age<=14) 
replace dim4=78 if (state==12) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=79 if (state==12) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=80 if (state==12) & (male==0) & (start_age>64) 

replace dim4=81 if (state==13) & (male==1) & (start_age<=14) 
replace dim4=82 if (state==13) & (male==1) & (start_age>14 & start_age<=44)
replace dim4=83 if (state==13) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=84 if (state==13) & (male==1) & (start_age>64) 
replace dim4=85 if (state==13) & (male==0) & (start_age<=14) 
replace dim4=86 if (state==13) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=87 if (state==13) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=88 if (state==13) & (male==0) & (start_age>64) 

replace dim4=89 if (state==15) & (male==1) & (start_age<=14) 
replace dim4=90 if (state==15) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=91 if (state==15) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=92 if (state==15) & (male==1) & (start_age>64) 
replace dim4=93 if (state==15) & (male==0) & (start_age<=14) 
replace dim4=94 if (state==15) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=95 if (state==15) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=96 if (state==15) & (male==0) & (start_age>64) 

replace dim4=97 if (state==16) & (male==1) & (start_age<=14) 
replace dim4=98 if (state==16) & (male==1) & (start_age>14 & start_age<=44)
replace dim4=99 if (state==16) & (male==1) & (start_age>44 & start_age<=64)
replace dim4=100 if (state==16) & (male==1) & (start_age>64)
replace dim4=101 if (state==16) & (male==0) & (start_age<=14) 
replace dim4=102 if (state==16) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=103 if (state==16) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=104 if (state==16) & (male==0) & (start_age>64)

replace dim4=105 if (state==17) & (male==1) & (start_age<=14)
replace dim4=106 if (state==17) & (male==1) & (start_age>14 & start_age<=44)
replace dim4=107 if (state==17) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=108 if (state==17) & (male==1) & (start_age>64)
replace dim4=109 if (state==17) & (male==0) & (start_age<=14)
replace dim4=110 if (state==17) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=111 if (state==17) & (male==0) & (start_age>44 & start_age<=64)
replace dim4=112 if (state==17) & (male==0) & (start_age>64)

replace dim4=113 if (state==18) & (male==1) & (start_age<=14) 
replace dim4=114 if (state==18) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=115 if (state==18) & (male==1) & (start_age>44 & start_age<=64)
replace dim4=116 if (state==18) & (male==1) & (start_age>64) 
replace dim4=117 if (state==18) & (male==0) & (start_age<=14) 
replace dim4=118 if (state==18) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=119 if (state==18) & (male==0) & (start_age>44 & start_age<=64)
replace dim4=120 if (state==18) & (male==0) & (start_age>64)

replace dim4=121 if (state==19) & (male==1) & (start_age<=14)
replace dim4=122 if (state==19) & (male==1) & (start_age>14 & start_age<=44)
replace dim4=123 if (state==19) & (male==1) & (start_age>44 & start_age<=64)
replace dim4=124 if (state==19) & (male==1) & (start_age>64)
replace dim4=125 if (state==19) & (male==0) & (start_age<=14)
replace dim4=126 if (state==19) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=127 if (state==19) & (male==0) & (start_age>44 & start_age<=64)
replace dim4=128 if (state==19) & (male==0) & (start_age>64)

replace dim4=129 if (state==20) & (male==1) & (start_age<=14)
replace dim4=130 if (state==20) & (male==1) & (start_age>14 & start_age<=44)
replace dim4=131 if (state==20) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=132 if (state==20) & (male==1) & (start_age>64) 
replace dim4=133 if (state==20) & (male==0) & (start_age<=14) 
replace dim4=134 if (state==20) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=135 if (state==20) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=136 if (state==20) & (male==0) & (start_age>64) 

replace dim4=137 if (state==21) & (male==1) & (start_age<=14) 
replace dim4=138 if (state==21) & (male==1) & (start_age>14 & start_age<=44)
replace dim4=139 if (state==21) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=140 if (state==21) & (male==1) & (start_age>64) 
replace dim4=141 if (state==21) & (male==0) & (start_age<=14) 
replace dim4=142 if (state==21) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=143 if (state==21) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=144 if (state==21) & (male==0) & (start_age>64) 

replace dim4=145 if (state==22) & (male==1) & (start_age<=14) 
replace dim4=146 if (state==22) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=147 if (state==22) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=148 if (state==22) & (male==1) & (start_age>64) 
replace dim4=149 if (state==22) & (male==0) & (start_age<=14) 
replace dim4=150 if (state==22) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=151 if (state==22) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=152 if (state==22) & (male==0) & (start_age>64) 

replace dim4=153 if (state==23) & (male==1) & (start_age<=14) 
replace dim4=154 if (state==23) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=155 if (state==23) & (male==1) & (start_age>44 & start_age<=64)
replace dim4=156 if (state==23) & (male==1) & (start_age>64)
replace dim4=157 if (state==23) & (male==0) & (start_age<=14)
replace dim4=158 if (state==23) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=159 if (state==23) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=160 if (state==23) & (male==0) & (start_age>64) 

replace dim4=161 if (state==24) & (male==1) & (start_age<=14) 
replace dim4=162 if (state==24) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=163 if (state==24) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=164 if (state==24) & (male==1) & (start_age>64) 
replace dim4=165 if (state==24) & (male==0) & (start_age<=14) 
replace dim4=166 if (state==24) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=167 if (state==24) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=168 if (state==24) & (male==0) & (start_age>64) 

replace dim4=169 if (state==25) & (male==1) & (start_age<=14)
replace dim4=170 if (state==25) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=171 if (state==25) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=172 if (state==25) & (male==1) & (start_age>64)
replace dim4=173 if (state==25) & (male==0) & (start_age<=14) 
replace dim4=174 if (state==25) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=175 if (state==25) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=176 if (state==25) & (male==0) & (start_age>64) 

replace dim4=177 if (state==26) & (male==1) & (start_age<=14) 
replace dim4=178 if (state==26) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=179 if (state==26) & (male==1) & (start_age>44 & start_age<=64)
replace dim4=180 if (state==26) & (male==1) & (start_age>64) 
replace dim4=181 if (state==26) & (male==0) & (start_age<=14) 
replace dim4=182 if (state==26) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=183 if (state==26) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=184 if (state==26) & (male==0) & (start_age>64) 

replace dim4=185 if (state==27) & (male==1) & (start_age<=14) 
replace dim4=186 if (state==27) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=187 if (state==27) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=188 if (state==27) & (male==1) & (start_age>64) 
replace dim4=189 if (state==27) & (male==0) & (start_age<=14) 
replace dim4=190 if (state==27) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=191 if (state==27) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=192 if (state==27) & (male==0) & (start_age>64) 

replace dim4=193 if (state==28) & (male==1) & (start_age<=14) 
replace dim4=194 if (state==28) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=195 if (state==28) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=196 if (state==28) & (male==1) & (start_age>64) 
replace dim4=197 if (state==28) & (male==0) & (start_age<=14) 
replace dim4=198 if (state==28) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=199 if (state==28) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=200 if (state==28) & (male==0) & (start_age>64)

replace dim4=201 if (state==29) & (male==1) & (start_age<=14) 
replace dim4=202 if (state==29) & (male==1) & (start_age>14 & start_age<=44)
replace dim4=203 if (state==29) & (male==1) & (start_age>44 & start_age<=64)
replace dim4=204 if (state==29) & (male==1) & (start_age>64) 
replace dim4=205 if (state==29) & (male==0) & (start_age<=14) 
replace dim4=206 if (state==29) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=207 if (state==29) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=208 if (state==29) & (male==0) & (start_age>64) 

replace dim4=209 if (state==30) & (male==1) & (start_age<=14)
replace dim4=210 if (state==30) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=211 if (state==30) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=212 if (state==30) & (male==1) & (start_age>64)
replace dim4=213 if (state==30) & (male==0) & (start_age<=14) 
replace dim4=214 if (state==30) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=215 if (state==30) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=216 if (state==30) & (male==0) & (start_age>64) 

replace dim4=217 if (state==31) & (male==1) & (start_age<=14) 
replace dim4=218 if (state==31) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=219 if (state==31) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=220 if (state==31) & (male==1) & (start_age>64)
replace dim4=221 if (state==31) & (male==0) & (start_age<=14) 
replace dim4=222 if (state==31) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=223 if (state==31) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=224 if (state==31) & (male==0) & (start_age>64) 

replace dim4=225 if (state==32) & (male==1) & (start_age<=14) 
replace dim4=226 if (state==32) & (male==1) & (start_age>14 & start_age<=44)
replace dim4=227 if (state==32) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=228 if (state==32) & (male==1) & (start_age>64) 
replace dim4=229 if (state==32) & (male==0) & (start_age<=14) 
replace dim4=230 if (state==32) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=231 if (state==32) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=232 if (state==32) & (male==0) & (start_age>64) 

replace dim4=233 if (state==33) & (male==1) & (start_age<=14) 
replace dim4=234 if (state==33) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=235 if (state==33) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=236 if (state==33) & (male==1) & (start_age>64)
replace dim4=237 if (state==33) & (male==0) & (start_age<=14) 
replace dim4=238 if (state==33) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=239 if (state==33) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=240 if (state==33) & (male==0) & (start_age>64) 

replace dim4=241 if (state==34) & (male==1) & (start_age<=14) 
replace dim4=242 if (state==34) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=243 if (state==34) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=244 if (state==34) & (male==1) & (start_age>64) 
replace dim4=245 if (state==34) & (male==0) & (start_age<=14) 
replace dim4=246 if (state==34) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=247 if (state==34) & (male==0) & (start_age>44 & start_age<=64)
replace dim4=248 if (state==34) & (male==0) & (start_age>64)

replace dim4=249 if (state==35) & (male==1) & (start_age<=14) 
replace dim4=250 if (state==35) & (male==1) & (start_age>14 & start_age<=44)
replace dim4=251 if (state==35) & (male==1) & (start_age>44 & start_age<=64)
replace dim4=252 if (state==35) & (male==1) & (start_age>64)
replace dim4=253 if (state==35) & (male==0) & (start_age<=14)
replace dim4=254 if (state==35) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=255 if (state==35) & (male==0) & (start_age>44 & start_age<=64)
replace dim4=256 if (state==35) & (male==0) & (start_age>64)

replace dim4=257 if (state==36) & (male==1) & (start_age<=14)
replace dim4=258 if (state==36) & (male==1) & (start_age>14 & start_age<=44)
replace dim4=259 if (state==36) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=260 if (state==36) & (male==1) & (start_age>64) 
replace dim4=261 if (state==36) & (male==0) & (start_age<=14)
replace dim4=262 if (state==36) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=263 if (state==36) & (male==0) & (start_age>44 & start_age<=64)
replace dim4=264 if (state==36) & (male==0) & (start_age>64)

replace dim4=265 if (state==37) & (male==1) & (start_age<=14) 
replace dim4=266 if (state==37) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=267 if (state==37) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=268 if (state==37) & (male==1) & (start_age>64)
replace dim4=269 if (state==37) & (male==0) & (start_age<=14)
replace dim4=270 if (state==37) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=271 if (state==37) & (male==0) & (start_age>44 & start_age<=64)
replace dim4=272 if (state==37) & (male==0) & (start_age>64)

replace dim4=273 if (state==38) & (male==1) & (start_age<=14)
replace dim4=274 if (state==38) & (male==1) & (start_age>14 & start_age<=44)
replace dim4=275 if (state==38) & (male==1) & (start_age>44 & start_age<=64)
replace dim4=276 if (state==38) & (male==1) & (start_age>64) 
replace dim4=277 if (state==38) & (male==0) & (start_age<=14)
replace dim4=278 if (state==38) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=279 if (state==38) & (male==0) & (start_age>44 & start_age<=64)
replace dim4=280 if (state==38) & (male==0) & (start_age>64) 

replace dim4=281 if (state==39) & (male==1) & (start_age<=14) 
replace dim4=282 if (state==39) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=283 if (state==39) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=284 if (state==39) & (male==1) & (start_age>64) 
replace dim4=285 if (state==39) & (male==0) & (start_age<=14) 
replace dim4=286 if (state==39) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=287 if (state==39) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=288 if (state==39) & (male==0) & (start_age>64) 

replace dim4=289 if (state==40) & (male==1) & (start_age<=14) 
replace dim4=290 if (state==40) & (male==1) & (start_age>14 & start_age<=44)
replace dim4=291 if (state==40) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=292 if (state==40) & (male==1) & (start_age>64) 
replace dim4=293 if (state==40) & (male==0) & (start_age<=14) 
replace dim4=294 if (state==40) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=295 if (state==40) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=296 if (state==40) & (male==0) & (start_age>64) 

replace dim4=297 if (state==41) & (male==1) & (start_age<=14) 
replace dim4=298 if (state==41) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=299 if (state==41) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=300 if (state==41) & (male==1) & (start_age>64) 
replace dim4=301 if (state==41) & (male==0) & (start_age<=14)
replace dim4=302 if (state==41) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=303 if (state==41) & (male==0) & (start_age>44 & start_age<=64)
replace dim4=304 if (state==41) & (male==0) & (start_age>64) 

replace dim4=305 if (state==42) & (male==1) & (start_age<=14) 
replace dim4=306 if (state==42) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=307 if (state==42) & (male==1) & (start_age>44 & start_age<=64)
replace dim4=308 if (state==42) & (male==1) & (start_age>64) 
replace dim4=309 if (state==42) & (male==0) & (start_age<=14)
replace dim4=310 if (state==42) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=311 if (state==42) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=312 if (state==42) & (male==0) & (start_age>64)

replace dim4=313 if (state==44) & (male==1) & (start_age<=14)
replace dim4=314 if (state==44) & (male==1) & (start_age>14 & start_age<=44)
replace dim4=315 if (state==44) & (male==1) & (start_age>44 & start_age<=64)
replace dim4=316 if (state==44) & (male==1) & (start_age>64)
replace dim4=317 if (state==44) & (male==0) & (start_age<=14) 
replace dim4=318 if (state==44) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=319 if (state==44) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=320 if (state==44) & (male==0) & (start_age>64) 

replace dim4=321 if (state==45) & (male==1) & (start_age<=14) 
replace dim4=322 if (state==45) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=323 if (state==45) & (male==1) & (start_age>44 & start_age<=64)
replace dim4=324 if (state==45) & (male==1) & (start_age>64) 
replace dim4=325 if (state==45) & (male==0) & (start_age<=14) 
replace dim4=326 if (state==45) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=327 if (state==45) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=328 if (state==45) & (male==0) & (start_age>64) 

replace dim4=329 if (state==46) & (male==1) & (start_age<=14)
replace dim4=330 if (state==46) & (male==1) & (start_age>14 & start_age<=44)
replace dim4=331 if (state==46) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=332 if (state==46) & (male==1) & (start_age>64) 
replace dim4=333 if (state==46) & (male==0) & (start_age<=14)
replace dim4=334 if (state==46) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=335 if (state==46) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=336 if (state==46) & (male==0) & (start_age>64) 

replace dim4=337 if (state==47) & (male==1) & (start_age<=14) 
replace dim4=338 if (state==47) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=339 if (state==47) & (male==1) & (start_age>44 & start_age<=64)
replace dim4=340 if (state==47) & (male==1) & (start_age>64)
replace dim4=341 if (state==47) & (male==0) & (start_age<=14) 
replace dim4=342 if (state==47) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=343 if (state==47) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=344 if (state==47) & (male==0) & (start_age>64) 

replace dim4=345 if (state==48) & (male==1) & (start_age<=14)
replace dim4=346 if (state==48) & (male==1) & (start_age>14 & start_age<=44)
replace dim4=347 if (state==48) & (male==1) & (start_age>44 & start_age<=64)
replace dim4=348 if (state==48) & (male==1) & (start_age>64)
replace dim4=349 if (state==48) & (male==0) & (start_age<=14)
replace dim4=350 if (state==48) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=351 if (state==48) & (male==0) & (start_age>44 & start_age<=64)
replace dim4=352 if (state==48) & (male==0) & (start_age>64)

replace dim4=353 if (state==49) & (male==1) & (start_age<=14) 
replace dim4=354 if (state==49) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=355 if (state==49) & (male==1) & (start_age>44 & start_age<=64)
replace dim4=356 if (state==49) & (male==1) & (start_age>64)
replace dim4=357 if (state==49) & (male==0) & (start_age<=14)
replace dim4=358 if (state==49) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=359 if (state==49) & (male==0) & (start_age>44 & start_age<=64)
replace dim4=360 if (state==49) & (male==0) & (start_age>64)

replace dim4=361 if (state==50) & (male==1) & (start_age<=14) 
replace dim4=362 if (state==50) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=363 if (state==50) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=364 if (state==50) & (male==1) & (start_age>64)
replace dim4=365 if (state==50) & (male==0) & (start_age<=14) 
replace dim4=366 if (state==50) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=367 if (state==50) & (male==0) & (start_age>44 & start_age<=64)
replace dim4=368 if (state==50) & (male==0) & (start_age>64)

replace dim4=369 if (state==51) & (male==1) & (start_age<=14)
replace dim4=370 if (state==51) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=371 if (state==51) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=372 if (state==51) & (male==1) & (start_age>64) 
replace dim4=373 if (state==51) & (male==0) & (start_age<=14) 
replace dim4=374 if (state==51) & (male==0) & (start_age>14 & start_age<=44) 
replace dim4=375 if (state==51) & (male==0) & (start_age>44 & start_age<=64)
replace dim4=376 if (state==51) & (male==0) & (start_age>64)

replace dim4=377 if (state==53) & (male==1) & (start_age<=14) 
replace dim4=378 if (state==53) & (male==1) & (start_age>14 & start_age<=44)
replace dim4=379 if (state==53) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=380 if (state==53) & (male==1) & (start_age>64) 
replace dim4=381 if (state==53) & (male==0) & (start_age<=14)
replace dim4=382 if (state==53) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=383 if (state==53) & (male==0) & (start_age>44 & start_age<=64)
replace dim4=384 if (state==53) & (male==0) & (start_age>64) 

replace dim4=385 if (state==54) & (male==1) & (start_age<=14)
replace dim4=386 if (state==54) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=387 if (state==54) & (male==1) & (start_age>44 & start_age<=64) 
replace dim4=388 if (state==54) & (male==1) & (start_age>64) 
replace dim4=389 if (state==54) & (male==0) & (start_age<=14)
replace dim4=390 if (state==54) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=391 if (state==54) & (male==0) & (start_age>44 & start_age<=64)
replace dim4=392 if (state==54) & (male==0) & (start_age>64)

replace dim4=393 if (state==55) & (male==1) & (start_age<=14)
replace dim4=394 if (state==55) & (male==1) & (start_age>14 & start_age<=44)
replace dim4=395 if (state==55) & (male==1) & (start_age>44 & start_age<=64)
replace dim4=396 if (state==55) & (male==1) & (start_age>64) 
replace dim4=397 if (state==55) & (male==0) & (start_age<=14) 
replace dim4=398 if (state==55) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=399 if (state==55) & (male==0) & (start_age>44 & start_age<=64)
replace dim4=400 if (state==55) & (male==0) & (start_age>64)

replace dim4=401 if (state==56) & (male==1) & (start_age<=14) 
replace dim4=402 if (state==56) & (male==1) & (start_age>14 & start_age<=44) 
replace dim4=403 if (state==56) & (male==1) & (start_age>44 & start_age<=64)
replace dim4=404 if (state==56) & (male==1) & (start_age>64) 
replace dim4=405 if (state==56) & (male==0) & (start_age<=14) 
replace dim4=406 if (state==56) & (male==0) & (start_age>14 & start_age<=44)
replace dim4=407 if (state==56) & (male==0) & (start_age>44 & start_age<=64) 
replace dim4=408 if (state==56) & (male==0) & (start_age>64) 



gen dim5=.
replace dim5=1 if (male==1) & (race==1) & (start_age>=0 & start_age<=4) 
replace dim5=2 if (male==1) & (race==1) & (start_age>=5 & start_age<=9)
replace dim5=3 if (male==1) & (race==1) & (start_age>=10 & start_age<=14) 
replace dim5=4 if (male==1) & (race==1) & (start_age>=15 & start_age<=19) 
replace dim5=5 if (male==1) & (race==1) & (start_age>=20 & start_age<=24) 
replace dim5=6 if (male==1) & (race==1) & (start_age>=25 & start_age<=29) 
replace dim5=7 if (male==1) & (race==1) & (start_age>=30 & start_age<=34) 
replace dim5=8 if (male==1) & (race==1) & (start_age>=35 & start_age<=39) 
replace dim5=9 if (male==1) & (race==1) & (start_age>=40 & start_age<=44)
replace dim5=10 if (male==1) & (race==1) & (start_age>=45 & start_age<=49)
replace dim5=11 if (male==1) & (race==1) & (start_age>=50 & start_age<=54) 
replace dim5=12 if (male==1) & (race==1) & (start_age>=55 & start_age<=59) 
replace dim5=13 if (male==1) & (race==1) & (start_age>=60 & start_age<=64) 
replace dim5=14 if (male==1) & (race==1) & (start_age>=65 & start_age<=69) 
replace dim5=15 if (male==1) & (race==1) & (start_age>=70 & start_age<=74) 
replace dim5=16 if (male==1) & (race==1) & (start_age>=75 & start_age<=79)
replace dim5=17 if (male==1) & (race==1) & (start_age>=80 & start_age<=84)
replace dim5=18 if (male==1) & (race==1) & (start_age>=85)

replace dim5=19 if (male==0) & (race==1) & (start_age>=0 & start_age<=4) 
replace dim5=20 if (male==0) & (race==1) & (start_age>=5 & start_age<=9)
replace dim5=21 if (male==0) & (race==1) & (start_age>=10 & start_age<=14) 
replace dim5=22 if (male==0) & (race==1) & (start_age>=15 & start_age<=19) 
replace dim5=23 if (male==0) & (race==1) & (start_age>=20 & start_age<=24) 
replace dim5=24 if (male==0) & (race==1) & (start_age>=25 & start_age<=29) 
replace dim5=25 if (male==0) & (race==1) & (start_age>=30 & start_age<=34) 
replace dim5=26 if (male==0) & (race==1) & (start_age>=35 & start_age<=39) 
replace dim5=27 if (male==0) & (race==1) & (start_age>=40 & start_age<=44)
replace dim5=28 if (male==0) & (race==1) & (start_age>=45 & start_age<=49)
replace dim5=29 if (male==0) & (race==1) & (start_age>=50 & start_age<=54) 
replace dim5=30 if (male==0) & (race==1) & (start_age>=55 & start_age<=59) 
replace dim5=31 if (male==0) & (race==1) & (start_age>=60 & start_age<=64) 
replace dim5=32 if (male==0) & (race==1) & (start_age>=65 & start_age<=69) 
replace dim5=33 if (male==0) & (race==1) & (start_age>=70 & start_age<=74) 
replace dim5=34 if (male==0) & (race==1) & (start_age>=75 & start_age<=79)
replace dim5=35 if (male==0) & (race==1) & (start_age>=80 & start_age<=84)
replace dim5=36 if (male==0) & (race==1) & (start_age>=85)

replace dim5=37 if (male==1) & (race==2) & (start_age>=0 & start_age<=4) 
replace dim5=38 if (male==1) & (race==2) & (start_age>=5 & start_age<=9)
replace dim5=39 if (male==1) & (race==2) & (start_age>=10 & start_age<=14) 
replace dim5=40 if (male==1) & (race==2) & (start_age>=15 & start_age<=19) 
replace dim5=41 if (male==1) & (race==2) & (start_age>=20 & start_age<=24) 
replace dim5=42 if (male==1) & (race==2) & (start_age>=25 & start_age<=29) 
replace dim5=43 if (male==1) & (race==2) & (start_age>=30 & start_age<=34) 
replace dim5=44 if (male==1) & (race==2) & (start_age>=35 & start_age<=39) 
replace dim5=45 if (male==1) & (race==2) & (start_age>=40 & start_age<=44)
replace dim5=46 if (male==1) & (race==2) & (start_age>=45 & start_age<=49)
replace dim5=47 if (male==1) & (race==2) & (start_age>=50 & start_age<=54) 
replace dim5=48 if (male==1) & (race==2) & (start_age>=55 & start_age<=64) 
replace dim5=49 if (male==1) & (race==2) & (start_age>=65) 

replace dim5=50 if (male==0) & (race==2) & (start_age>=0 & start_age<=4) 
replace dim5=51 if (male==0) & (race==2) & (start_age>=5 & start_age<=9)
replace dim5=52 if (male==0) & (race==2) & (start_age>=10 & start_age<=14) 
replace dim5=53 if (male==0) & (race==2) & (start_age>=15 & start_age<=19) 
replace dim5=54 if (male==0) & (race==2) & (start_age>=20 & start_age<=24) 
replace dim5=55 if (male==0) & (race==2) & (start_age>=25 & start_age<=29) 
replace dim5=56 if (male==0) & (race==2) & (start_age>=30 & start_age<=34) 
replace dim5=57 if (male==0) & (race==2) & (start_age>=35 & start_age<=39) 
replace dim5=58 if (male==0) & (race==2) & (start_age>=40 & start_age<=44)
replace dim5=59 if (male==0) & (race==2) & (start_age>=45 & start_age<=49)
replace dim5=60 if (male==0) & (race==2) & (start_age>=50 & start_age<=54) 
replace dim5=61 if (male==0) & (race==2) & (start_age>=55 & start_age<=64) 
replace dim5=62 if (male==0) & (race==2) & (start_age>=65) 

replace dim5=63 if (male==1) & (race==3) & (start_age>=0 & start_age<=4) 
replace dim5=64 if (male==1) & (race==3) & (start_age>=5 & start_age<=9)
replace dim5=65 if (male==1) & (race==3) & (start_age>=10 & start_age<=14) 
replace dim5=66 if (male==1) & (race==3) & (start_age>=15 & start_age<=24) 
replace dim5=67 if (male==1) & (race==3) & (start_age>=25 & start_age<=34) 
replace dim5=68 if (male==1) & (race==3) & (start_age>=35 & start_age<=44) 
replace dim5=69 if (male==1) & (race==3) & (start_age>=45 & start_age<=54) 
replace dim5=70 if (male==1) & (race==3) & (start_age>=55 & start_age<=64) 
replace dim5=71 if (male==1) & (race==3) & (start_age>=65)

replace dim5=72 if (male==0) & (race==3) & (start_age>=0 & start_age<=4) 
replace dim5=73 if (male==0) & (race==3) & (start_age>=5 & start_age<=9)
replace dim5=74 if (male==0) & (race==3) & (start_age>=10 & start_age<=14) 
replace dim5=75 if (male==0) & (race==3) & (start_age>=15 & start_age<=24) 
replace dim5=76 if (male==0) & (race==3) & (start_age>=25 & start_age<=34) 
replace dim5=77 if (male==0) & (race==3) & (start_age>=35 & start_age<=44) 
replace dim5=78 if (male==0) & (race==3) & (start_age>=45 & start_age<=54) 
replace dim5=79 if (male==0) & (race==3) & (start_age>=55 & start_age<=64) 
replace dim5=80 if (male==0) & (race==3) & (start_age>=65)

save ${mydata}/ssb_available_repw_rake${k}${year}.dta, replace


*generate cross-tabulations of population totals and merge to pop control data, for using in raking
collapse (sum) wn=initwgt (count) n=initwgt, by(dim1 dim2 dim3 dim4 dim5)
sum wn


merge 1:1 dim1 dim2 dim3 dim4 dim5 using ${mydata}/popcontrol_crosstab${year}.dta, gen(_mergePopControlTot)
keep if _mergePopControlTot==3
gen wn0=wn

save ${mydata}/ssb_availablerepw_crosstab${k}.dta, replace





/*
2. CREATE THE RAKING PROGRAM
*/
capture program drop rake
program rake
	args dim dataset var threshhold iterations
	
	local iteration=0

	use ${mydata}/`dataset'.dta, clear
	save ${mydata}/RAKED.dta, replace
	gen maxdiff=`threshhold'+1

	while `iteration'<`iterations' & maxdiff>`threshhold' {
		local iteration=`iteration'+1
		display `iteration'	
		forvalues d = 1/`dim' {
			use ${mydata}/RAKED.dta, clear
			list dim1 dim2 dim3 dim4 dim5 n wn cn in 1/2, table
			collapse (sum) ntot=n wntot=wn cntot=cn, by(dim`d')
			gen adjustmentfac`d'=cntot/wntot
			list dim`d' n wn cn ntot wntot cntot adjustmentfac`d' in 1/2, table
			sum adjustmentfac`d'
			save ${mydata}/AdjustmentFacs.dta, replace
			
			use ${mydata}/RAKED.dta, clear
			merge m:1 dim`d' using ${mydata}/AdjustmentFacs.dta, gen(_mergeAdjFacs)
			keep if _mergeAdjFacs==3
			list dim1 dim2 dim3 dim4 dim5 n wn cn adjustmentfac`d' in 1/2, table
			drop _mergeAdjFacs
			gen w`d'=wn*adjustmentfac`d'
			drop wn
			rename w`d' wn
			sum wn
			list dim1 dim2 dim3 dim4 dim5 n wn cn adjustmentfac`d' in 1/2, table
			drop adjustmentfac`d'
			save ${mydata}/RAKED.dta, replace
		}	
		
		forvalues d = 1/`dim' {
			use ${mydata}/RAKED.dta, clear
			collapse (sum) ntot=n wntot=wn cntot=cn, by(dim`d')	
			gen diff`dim'=wntot-cntot
			gen diffabs`dim'=abs(wntot-cntot)
			egen cntotall=total(cntot), by(dim`d')
			gen wpercent=wntot/cntotall
			gen cpercent=cntot/cntotall
			gen diffpercent=wpercent-cpercent
			gen diffpercentabs=abs(diffpercent)
			gen dim=`d'
			rename dim`d' dimnum
			keep dim dimnum diffpercentabs
			save ${mydata}/tottol`d'.dta, replace
		}

		use ${mydata}/tottol1.dta, clear
		append using ${mydata}/tottol2.dta ///
			${mydata}/tottol3.dta ///
			${mydata}/tottol4.dta ///
			${mydata}/tottol5.dta	
		collapse (max) maxdiff=diffpercentabs
	}			
end



/*
3. RAKE THE INITIAL WEIGHT
*/
rake 5 ssb_availablerepw_crosstab${k} initwgt .01 10

use ${mydata}/RAKED.dta, clear
gen finalaf=wn/wn0
save ${mydata}/RAKED.dta, replace


use ${mydata}/ssb_available_repw_rake${k}${year}.dta, clear
merge m:1 dim1 dim2 dim3 dim4 dim5 using ${mydata}/RAKED.dta, gen(_RAKEDaf)

gen finalinitwgt=initwgt*finalaf
save ${mydata}/ssb_available_repw_rake${k}${year}.dta, replace




/*
4. RAKE THE REPLICATE WEIGHTS
*/
forvalues i=1/128 {
	rake 5 ssb_availablerepw_crosstab${k} repweight`i' .01 10
	
	use ${mydata}/RAKED.dta, clear
	gen finalaf`i'=wn/wn0
	save ${mydata}/RAKED.dta, replace


	use ${mydata}/ssb_available_repw_rake${k}${year}.dta, clear
	merge m:1 dim1 dim2 dim3 dim4 dim5 using ${mydata}/RAKED.dta, gen(_RAKEDaf`i')

	gen finalrepweight`i'=repweight`i'*finalaf`i'
	save ${mydata}/ssb_available_repw_rake${k}${year}.dta, replace
}



save ${mydata}/ssb_available_repw_rake${k}${year}.dta, replace






