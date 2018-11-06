
/*/ 
This file rakes the initial weight and replicate weights, so that the available case set 
	of variables for the analysis are representative of poputation control totals 
/*/


/*/
input files: 1) available-case SSB data with replicate weights  2) population control data in 
	cross-tabulated form
output files: 1) available-case data with initial weight and replicate weights that have been 
	raked
/*/


/*/ 
STEPS:
	1) assign each person in the available case SSB into their category for each of 
	the five dimensions
	2) create raking macro, which rakes a given weight until either max number 
	of iterations is reached or max difference between control and observed marginal 
	totals for each dim-cat falls below pre-specified threshold
	3) rake the initial weight
	4) rake the replicate weights one-by-one
/*/

***NOTHING NEEDS TO BE EDITED***;



/*/ 1. ASSIGN EACH PERSON IN AVAILABLE-CASE GSF WITH REP WEIGHTS TO THEIR DIM-CAT /*/
data ssb_available_repw_rake&k.&year.;
set mydata.ssb_available_repw&k.(where=(panel=&year.));
start_age = year(sipp_panel_beg_date) - year(birthdate);

dim1=.;
if (male=1) and (hispanic=1) and (start_age<=14) then dim1=1;
if (male=1) and (hispanic=1) and (start_age>14 and start_age<=24) then dim1=2;
if (male=1) and (hispanic=1) and (start_age>24 and start_age<=44) then dim1=3;
if (male=1) and (hispanic=1) and (start_age>44 and start_age<=64) then dim1=4;
if (male=1) and (hispanic=1) and (start_age>64) then dim1=5;

if (male=0) and (hispanic=1) and (start_age<=14) then dim1=6;
if (male=0) and (hispanic=1) and (start_age>14 and start_age<=24) then dim1=7;
if (male=0) and (hispanic=1) and (start_age>24 and start_age<=44) then dim1=8;
if (male=0) and (hispanic=1) and (start_age>44 and start_age<=64) then dim1=9;
if (male=0) and (hispanic=1) and (start_age>64) then dim1=10;

if (male=1) and (hispanic=0) and (start_age<=14) then dim1=11;
if (male=1) and (hispanic=0) and (start_age>14 and start_age<=24) then dim1=12;
if (male=1) and (hispanic=0) and (start_age>24 and start_age<=44) then dim1=13;
if (male=1) and (hispanic=0) and (start_age>44 and start_age<=64) then dim1=14;
if (male=1) and (hispanic=0) and (start_age>64) then dim1=15;

if (male=0) and (hispanic=0) and (start_age<=14) then dim1=16;
if (male=0) and (hispanic=0) and (start_age>14 and start_age<=24) then dim1=17;
if (male=0) and (hispanic=0) and (start_age>24 and start_age<=44) then dim1=18;
if (male=0) and (hispanic=0) and (start_age>44 and start_age<=64) then dim1=19;
if (male=0) and (hispanic=0) and (start_age>64) then dim1=20;


dim2=.;
if (state=35) and (hispanic=1) then dim2=1;
if (state=35) and (hispanic=0) then dim2=2;
if (state=34) and (hispanic=1) then dim2=3;
if (state=34) and (hispanic=0) then dim2=4;
if (state=4) and (hispanic=1) then dim2=5;
if (state=4) and (hispanic=0) then dim2=6;
if (state=17) and (hispanic=1) then dim2=7;
if (state=17) and (hispanic=0) then dim2=8;
if (state=12) and (hispanic=1) then dim2=9;
if (state=12) and (hispanic=0) then dim2=10;
if (state=36) and (hispanic=1) then dim2=11;
if (state=36) and (hispanic=0) then dim2=12;
if (state=48) and (hispanic=1) then dim2=13;
if (state=48) and (hispanic=0) then dim2=14;
if (state=6) and (hispanic=1) then dim2=15;
if (state=6) and (hispanic=0) then dim2=16;
if (dim2=.) and (hispanic=1) then dim2=17;
if (dim2=.) and (hispanic=0) then dim2=18;


dim3=.;
if (state=1) and (race^=2) then dim3=1;
if (state=1) and (race=2) then dim3=2;
if (state=4) and (race^=2) then dim3=3;
if (state=4) and (race=2) then dim3=4;
if (state=5) and (race^=2) then dim3=5;
if (state=5) and (race=2) then dim3=6;
if (state=6) and (race^=2) then dim3=7;
if (state=6) and (race=2) then dim3=8;
if (state=12) and (race^=2) then dim3=9;
if (state=12) and (race=2) then dim3=10;
if (state=13) and (race^=2) then dim3=11;
if (state=13) and (race=2) then dim3=12;
if (state=17) and (race^=2) then dim3=13;
if (state=17) and (race=2) then dim3=14;
if (state=18) and (race^=2) then dim3=15;
if (state=18) and (race=2) then dim3=16;
if (state=21) and (race^=2) then dim3=17;
if (state=21) and (race=2) then dim3=18;
if (state=22) and (race^=2) then dim3=19;
if (state=22) and (race=2) then dim3=20;
if (state=24) and (race^=2) then dim3=21;
if (state=24) and (race=2) then dim3=22;
if (state=25) and (race^=2) then dim3=23;
if (state=25) and (race=2) then dim3=24;
if (state=26) and (race^=2) then dim3=25;
if (state=26) and (race=2) then dim3=26;
if (state=28) and (race^=2) then dim3=27;
if (state=28) and (race=2) then dim3=28;
if (state=29) and (race^=2) then dim3=29;
if (state=29) and (race=2) then dim3=30;
if (state=34) and (race^=2) then dim3=31;
if (state=34) and (race=2) then dim3=32;
if (state=35) and (race^=2) then dim3=33;
if (state=35) and (race=2) then dim3=34;
if (state=36) and (race^=2) then dim3=35;
if (state=36) and (race=2) then dim3=36;
if (state=37) and (race^=2) then dim3=37;
if (state=37) and (race=2) then dim3=38;
if (state=39) and (race^=2) then dim3=39;
if (state=39) and (race=2) then dim3=40;
if (state=42) and (race^=2) then dim3=41;
if (state=42) and (race=2) then dim3=42;
if (state=45) and (race^=2) then dim3=43;
if (state=45) and (race=2) then dim3=44;
if (state=47) and (race^=2) then dim3=45;
if (state=47) and (race=2) then dim3=46;
if (state=48) and (race^=2) then dim3=47;
if (state=48) and (race=2) then dim3=48;
if (state=51) and (race^=2) then dim3=49;
if (state=51) and (race=2) then dim3=50;
if (dim3=.) and (race^=2) then dim3=51;
if (dim3=.) and (race=2) then dim3=52;


dim4=.;
if (state=1) and (male=1) and (start_age<=14) then dim4=1;
if (state=1) and (male=1) and (start_age>14 and start_age<=44) then dim4=2;
if (state=1) and (male=1) and (start_age>44 and start_age<=64) then dim4=3;
if (state=1) and (male=1) and (start_age>64) then dim4=4;
if (state=1) and (male=0) and (start_age<=14) then dim4=5;
if (state=1) and (male=0) and (start_age>14 and start_age<=44) then dim4=6;
if (state=1) and (male=0) and (start_age>44 and start_age<=64) then dim4=7;
if (state=1) and (male=0) and (start_age>64) then dim4=8;

if (state=2) and (male=1) and (start_age<=14) then dim4=9;
if (state=2) and (male=1) and (start_age>14 and start_age<=44) then dim4=10;
if (state=2) and (male=1) and (start_age>44 and start_age<=64) then dim4=11;
if (state=2) and (male=1) and (start_age>64) then dim4=12;
if (state=2) and (male=0) and (start_age<=14) then dim4=13;
if (state=2) and (male=0) and (start_age>14 and start_age<=44) then dim4=14;
if (state=2) and (male=0) and (start_age>44 and start_age<=64) then dim4=15;
if (state=2) and (male=0) and (start_age>64) then dim4=16;

if (state=4) and (male=1) and (start_age<=14) then dim4=17;
if (state=4) and (male=1) and (start_age>14 and start_age<=44) then dim4=18;
if (state=4) and (male=1) and (start_age>44 and start_age<=64) then dim4=19;
if (state=4) and (male=1) and (start_age>64) then dim4=20;
if (state=4) and (male=0) and (start_age<=14) then dim4=21;
if (state=4) and (male=0) and (start_age>14 and start_age<=44) then dim4=22;
if (state=4) and (male=0) and (start_age>44 and start_age<=64) then dim4=23;
if (state=4) and (male=0) and (start_age>64) then dim4=24;

if (state=5) and (male=1) and (start_age<=14) then dim4=25;
if (state=5) and (male=1) and (start_age>14 and start_age<=44) then dim4=26;
if (state=5) and (male=1) and (start_age>44 and start_age<=64) then dim4=27;
if (state=5) and (male=1) and (start_age>64) then dim4=28;
if (state=5) and (male=0) and (start_age<=14) then dim4=29;
if (state=5) and (male=0) and (start_age>14 and start_age<=44) then dim4=30;
if (state=5) and (male=0) and (start_age>44 and start_age<=64) then dim4=31;
if (state=5) and (male=0) and (start_age>64) then dim4=32;

if (state=6) and (male=1) and (start_age<=14) then dim4=33;
if (state=6) and (male=1) and (start_age>14 and start_age<=44) then dim4=34;
if (state=6) and (male=1) and (start_age>44 and start_age<=64) then dim4=35;
if (state=6) and (male=1) and (start_age>64) then dim4=36;
if (state=6) and (male=0) and (start_age<=14) then dim4=37;
if (state=6) and (male=0) and (start_age>14 and start_age<=44) then dim4=38;
if (state=6) and (male=0) and (start_age>44 and start_age<=64) then dim4=38;
if (state=6) and (male=0) and (start_age>64) then dim4=40;

if (state=8) and (male=1) and (start_age<=14) then dim4=41;
if (state=8) and (male=1) and (start_age>14 and start_age<=44) then dim4=42;
if (state=8) and (male=1) and (start_age>44 and start_age<=64) then dim4=43;
if (state=8) and (male=1) and (start_age>64) then dim4=44;
if (state=8) and (male=0) and (start_age<=14) then dim4=45;
if (state=8) and (male=0) and (start_age>14 and start_age<=44) then dim4=46;
if (state=8) and (male=0) and (start_age>44 and start_age<=64) then dim4=47;
if (state=8) and (male=0) and (start_age>64) then dim4=48;

if (state=9) and (male=1) and (start_age<=14) then dim4=49;
if (state=9) and (male=1) and (start_age>14 and start_age<=44) then dim4=50;
if (state=9) and (male=1) and (start_age>44 and start_age<=64) then dim4=51;
if (state=9) and (male=1) and (start_age>64) then dim4=52;
if (state=9) and (male=0) and (start_age<=14) then dim4=53;
if (state=9) and (male=0) and (start_age>14 and start_age<=44) then dim4=54;
if (state=9) and (male=0) and (start_age>44 and start_age<=64) then dim4=55;
if (state=9) and (male=0) and (start_age>64) then dim4=56;

if (state=10) and (male=1) and (start_age<=14) then dim4=57;
if (state=10) and (male=1) and (start_age>14 and start_age<=44) then dim4=58;
if (state=10) and (male=1) and (start_age>44 and start_age<=64) then dim4=59;
if (state=10) and (male=1) and (start_age>64) then dim4=60;
if (state=10) and (male=0) and (start_age<=14) then dim4=61;
if (state=10) and (male=0) and (start_age>14 and start_age<=44) then dim4=62;
if (state=10) and (male=0) and (start_age>44 and start_age<=64) then dim4=63;
if (state=10) and (male=0) and (start_age>64) then dim4=64;

if (state=11) and (male=1) and (start_age<=14) then dim4=65;
if (state=11) and (male=1) and (start_age>14 and start_age<=44) then dim4=66;
if (state=11) and (male=1) and (start_age>44 and start_age<=64) then dim4=67;
if (state=11) and (male=1) and (start_age>64) then dim4=68;
if (state=11) and (male=0) and (start_age<=14) then dim4=69;
if (state=11) and (male=0) and (start_age>14 and start_age<=44) then dim4=70;
if (state=11) and (male=0) and (start_age>44 and start_age<=64) then dim4=71;
if (state=11) and (male=0) and (start_age>64) then dim4=72;

if (state=12) and (male=1) and (start_age<=14) then dim4=73;
if (state=12) and (male=1) and (start_age>14 and start_age<=44) then dim4=74;
if (state=12) and (male=1) and (start_age>44 and start_age<=64) then dim4=75;
if (state=12) and (male=1) and (start_age>64) then dim4=76;
if (state=12) and (male=0) and (start_age<=14) then dim4=77;
if (state=12) and (male=0) and (start_age>14 and start_age<=44) then dim4=78;
if (state=12) and (male=0) and (start_age>44 and start_age<=64) then dim4=79;
if (state=12) and (male=0) and (start_age>64) then dim4=80;

if (state=13) and (male=1) and (start_age<=14) then dim4=81;
if (state=13) and (male=1) and (start_age>14 and start_age<=44) then dim4=82;
if (state=13) and (male=1) and (start_age>44 and start_age<=64) then dim4=83;
if (state=13) and (male=1) and (start_age>64) then dim4=84;
if (state=13) and (male=0) and (start_age<=14) then dim4=85;
if (state=13) and (male=0) and (start_age>14 and start_age<=44) then dim4=86;
if (state=13) and (male=0) and (start_age>44 and start_age<=64) then dim4=87;
if (state=13) and (male=0) and (start_age>64) then dim4=88;

if (state=15) and (male=1) and (start_age<=14) then dim4=91;
if (state=15) and (male=1) and (start_age>14 and start_age<=44) then dim4=90;
if (state=15) and (male=1) and (start_age>44 and start_age<=64) then dim4=91;
if (state=15) and (male=1) and (start_age>64) then dim4=92;
if (state=15) and (male=0) and (start_age<=14) then dim4=93;
if (state=15) and (male=0) and (start_age>14 and start_age<=44) then dim4=94;
if (state=15) and (male=0) and (start_age>44 and start_age<=64) then dim4=95;
if (state=15) and (male=0) and (start_age>64) then dim4=96;

if (state=16) and (male=1) and (start_age<=14) then dim4=97;
if (state=16) and (male=1) and (start_age>14 and start_age<=44) then dim4=98;
if (state=16) and (male=1) and (start_age>44 and start_age<=64) then dim4=99;
if (state=16) and (male=1) and (start_age>64) then dim4=100;
if (state=16) and (male=0) and (start_age<=14) then dim4=101;
if (state=16) and (male=0) and (start_age>14 and start_age<=44) then dim4=102;
if (state=16) and (male=0) and (start_age>44 and start_age<=64) then dim4=103;
if (state=16) and (male=0) and (start_age>64) then dim4=104;

if (state=17) and (male=1) and (start_age<=14) then dim4=105;
if (state=17) and (male=1) and (start_age>14 and start_age<=44) then dim4=106;
if (state=17) and (male=1) and (start_age>44 and start_age<=64) then dim4=107;
if (state=17) and (male=1) and (start_age>64) then dim4=108;
if (state=17) and (male=0) and (start_age<=14) then dim4=109;
if (state=17) and (male=0) and (start_age>14 and start_age<=44) then dim4=110;
if (state=17) and (male=0) and (start_age>44 and start_age<=64) then dim4=111;
if (state=17) and (male=0) and (start_age>64) then dim4=112;

if (state=18) and (male=1) and (start_age<=14) then dim4=113;
if (state=18) and (male=1) and (start_age>14 and start_age<=44) then dim4=114;
if (state=18) and (male=1) and (start_age>44 and start_age<=64) then dim4=115;
if (state=18) and (male=1) and (start_age>64) then dim4=116;
if (state=18) and (male=0) and (start_age<=14) then dim4=117;
if (state=18) and (male=0) and (start_age>14 and start_age<=44) then dim4=118;
if (state=18) and (male=0) and (start_age>44 and start_age<=64) then dim4=119;
if (state=18) and (male=0) and (start_age>64) then dim4=120;

if (state=19) and (male=1) and (start_age<=14) then dim4=121;
if (state=19) and (male=1) and (start_age>14 and start_age<=44) then dim4=122;
if (state=19) and (male=1) and (start_age>44 and start_age<=64) then dim4=123;
if (state=19) and (male=1) and (start_age>64) then dim4=124;
if (state=19) and (male=0) and (start_age<=14) then dim4=125;
if (state=19) and (male=0) and (start_age>14 and start_age<=44) then dim4=126;
if (state=19) and (male=0) and (start_age>44 and start_age<=64) then dim4=127;
if (state=19) and (male=0) and (start_age>64) then dim4=128;

if (state=20) and (male=1) and (start_age<=14) then dim4=129;
if (state=20) and (male=1) and (start_age>14 and start_age<=44) then dim4=130;
if (state=20) and (male=1) and (start_age>44 and start_age<=64) then dim4=131;
if (state=20) and (male=1) and (start_age>64) then dim4=132;
if (state=20) and (male=0) and (start_age<=14) then dim4=133;
if (state=20) and (male=0) and (start_age>14 and start_age<=44) then dim4=134;
if (state=20) and (male=0) and (start_age>44 and start_age<=64) then dim4=135;
if (state=20) and (male=0) and (start_age>64) then dim4=136;

if (state=21) and (male=1) and (start_age<=14) then dim4=137;
if (state=21) and (male=1) and (start_age>14 and start_age<=44) then dim4=138;
if (state=21) and (male=1) and (start_age>44 and start_age<=64) then dim4=139;
if (state=21) and (male=1) and (start_age>64) then dim4=140;
if (state=21) and (male=0) and (start_age<=14) then dim4=141;
if (state=21) and (male=0) and (start_age>14 and start_age<=44) then dim4=142;
if (state=21) and (male=0) and (start_age>44 and start_age<=64) then dim4=143;
if (state=21) and (male=0) and (start_age>64) then dim4=144;

if (state=22) and (male=1) and (start_age<=14) then dim4=145;
if (state=22) and (male=1) and (start_age>14 and start_age<=44) then dim4=146;
if (state=22) and (male=1) and (start_age>44 and start_age<=64) then dim4=147;
if (state=22) and (male=1) and (start_age>64) then dim4=148;
if (state=22) and (male=0) and (start_age<=14) then dim4=149;
if (state=22) and (male=0) and (start_age>14 and start_age<=44) then dim4=150;
if (state=22) and (male=0) and (start_age>44 and start_age<=64) then dim4=151;
if (state=22) and (male=0) and (start_age>64) then dim4=152;

if (state=23) and (male=1) and (start_age<=14) then dim4=153;
if (state=23) and (male=1) and (start_age>14 and start_age<=44) then dim4=154;
if (state=23) and (male=1) and (start_age>44 and start_age<=64) then dim4=155;
if (state=23) and (male=1) and (start_age>64) then dim4=156;
if (state=23) and (male=0) and (start_age<=14) then dim4=157;
if (state=23) and (male=0) and (start_age>14 and start_age<=44) then dim4=158;
if (state=23) and (male=0) and (start_age>44 and start_age<=64) then dim4=159;
if (state=23) and (male=0) and (start_age>64) then dim4=160;

if (state=24) and (male=1) and (start_age<=14) then dim4=161;
if (state=24) and (male=1) and (start_age>14 and start_age<=44) then dim4=162;
if (state=24) and (male=1) and (start_age>44 and start_age<=64) then dim4=163;
if (state=24) and (male=1) and (start_age>64) then dim4=164;
if (state=24) and (male=0) and (start_age<=14) then dim4=165;
if (state=24) and (male=0) and (start_age>14 and start_age<=44) then dim4=166;
if (state=24) and (male=0) and (start_age>44 and start_age<=64) then dim4=167;
if (state=24) and (male=0) and (start_age>64) then dim4=168;

if (state=25) and (male=1) and (start_age<=14) then dim4=169;
if (state=25) and (male=1) and (start_age>14 and start_age<=44) then dim4=170;
if (state=25) and (male=1) and (start_age>44 and start_age<=64) then dim4=171;
if (state=25) and (male=1) and (start_age>64) then dim4=172;
if (state=25) and (male=0) and (start_age<=14) then dim4=173;
if (state=25) and (male=0) and (start_age>14 and start_age<=44) then dim4=174;
if (state=25) and (male=0) and (start_age>44 and start_age<=64) then dim4=175;
if (state=25) and (male=0) and (start_age>64) then dim4=176;

if (state=26) and (male=1) and (start_age<=14) then dim4=177;
if (state=26) and (male=1) and (start_age>14 and start_age<=44) then dim4=178;
if (state=26) and (male=1) and (start_age>44 and start_age<=64) then dim4=179;
if (state=26) and (male=1) and (start_age>64) then dim4=180;
if (state=26) and (male=0) and (start_age<=14) then dim4=181;
if (state=26) and (male=0) and (start_age>14 and start_age<=44) then dim4=182;
if (state=26) and (male=0) and (start_age>44 and start_age<=64) then dim4=183;
if (state=26) and (male=0) and (start_age>64) then dim4=184;

if (state=27) and (male=1) and (start_age<=14) then dim4=185;
if (state=27) and (male=1) and (start_age>14 and start_age<=44) then dim4=186;
if (state=27) and (male=1) and (start_age>44 and start_age<=64) then dim4=187;
if (state=27) and (male=1) and (start_age>64) then dim4=188;
if (state=27) and (male=0) and (start_age<=14) then dim4=189;
if (state=27) and (male=0) and (start_age>14 and start_age<=44) then dim4=190;
if (state=27) and (male=0) and (start_age>44 and start_age<=64) then dim4=191;
if (state=27) and (male=0) and (start_age>64) then dim4=192;

if (state=28) and (male=1) and (start_age<=14) then dim4=193;
if (state=28) and (male=1) and (start_age>14 and start_age<=44) then dim4=194;
if (state=28) and (male=1) and (start_age>44 and start_age<=64) then dim4=195;
if (state=28) and (male=1) and (start_age>64) then dim4=196;
if (state=28) and (male=0) and (start_age<=14) then dim4=197;
if (state=28) and (male=0) and (start_age>14 and start_age<=44) then dim4=198;
if (state=28) and (male=0) and (start_age>44 and start_age<=64) then dim4=199;
if (state=28) and (male=0) and (start_age>64) then dim4=200;

if (state=29) and (male=1) and (start_age<=14) then dim4=201;
if (state=29) and (male=1) and (start_age>14 and start_age<=44) then dim4=202;
if (state=29) and (male=1) and (start_age>44 and start_age<=64) then dim4=203;
if (state=29) and (male=1) and (start_age>64) then dim4=204;
if (state=29) and (male=0) and (start_age<=14) then dim4=205;
if (state=29) and (male=0) and (start_age>14 and start_age<=44) then dim4=206;
if (state=29) and (male=0) and (start_age>44 and start_age<=64) then dim4=207;
if (state=29) and (male=0) and (start_age>64) then dim4=208;

if (state=30) and (male=1) and (start_age<=14) then dim4=209;
if (state=30) and (male=1) and (start_age>14 and start_age<=44) then dim4=210;
if (state=30) and (male=1) and (start_age>44 and start_age<=64) then dim4=211;
if (state=30) and (male=1) and (start_age>64) then dim4=212;
if (state=30) and (male=0) and (start_age<=14) then dim4=213;
if (state=30) and (male=0) and (start_age>14 and start_age<=44) then dim4=214;
if (state=30) and (male=0) and (start_age>44 and start_age<=64) then dim4=215;
if (state=30) and (male=0) and (start_age>64) then dim4=216;

if (state=31) and (male=1) and (start_age<=14) then dim4=217;
if (state=31) and (male=1) and (start_age>14 and start_age<=44) then dim4=218;
if (state=31) and (male=1) and (start_age>44 and start_age<=64) then dim4=219;
if (state=31) and (male=1) and (start_age>64) then dim4=220;
if (state=31) and (male=0) and (start_age<=14) then dim4=221;
if (state=31) and (male=0) and (start_age>14 and start_age<=44) then dim4=222;
if (state=31) and (male=0) and (start_age>44 and start_age<=64) then dim4=223;
if (state=31) and (male=0) and (start_age>64) then dim4=224;

if (state=32) and (male=1) and (start_age<=14) then dim4=225;
if (state=32) and (male=1) and (start_age>14 and start_age<=44) then dim4=226;
if (state=32) and (male=1) and (start_age>44 and start_age<=64) then dim4=227;
if (state=32) and (male=1) and (start_age>64) then dim4=228;
if (state=32) and (male=0) and (start_age<=14) then dim4=229;
if (state=32) and (male=0) and (start_age>14 and start_age<=44) then dim4=230;
if (state=32) and (male=0) and (start_age>44 and start_age<=64) then dim4=231;
if (state=32) and (male=0) and (start_age>64) then dim4=232;

if (state=33) and (male=1) and (start_age<=14) then dim4=233;
if (state=33) and (male=1) and (start_age>14 and start_age<=44) then dim4=234;
if (state=33) and (male=1) and (start_age>44 and start_age<=64) then dim4=235;
if (state=33) and (male=1) and (start_age>64) then dim4=236;
if (state=33) and (male=0) and (start_age<=14) then dim4=237;
if (state=33) and (male=0) and (start_age>14 and start_age<=44) then dim4=238;
if (state=33) and (male=0) and (start_age>44 and start_age<=64) then dim4=239;
if (state=33) and (male=0) and (start_age>64) then dim4=240;

if (state=34) and (male=1) and (start_age<=14) then dim4=241;
if (state=34) and (male=1) and (start_age>14 and start_age<=44) then dim4=242;
if (state=34) and (male=1) and (start_age>44 and start_age<=64) then dim4=243;
if (state=34) and (male=1) and (start_age>64) then dim4=244;
if (state=34) and (male=0) and (start_age<=14) then dim4=245;
if (state=34) and (male=0) and (start_age>14 and start_age<=44) then dim4=246;
if (state=34) and (male=0) and (start_age>44 and start_age<=64) then dim4=247;
if (state=34) and (male=0) and (start_age>64) then dim4=248;

if (state=35) and (male=1) and (start_age<=14) then dim4=249;
if (state=35) and (male=1) and (start_age>14 and start_age<=44) then dim4=250;
if (state=35) and (male=1) and (start_age>44 and start_age<=64) then dim4=251;
if (state=35) and (male=1) and (start_age>64) then dim4=252;
if (state=35) and (male=0) and (start_age<=14) then dim4=253;
if (state=35) and (male=0) and (start_age>14 and start_age<=44) then dim4=254;
if (state=35) and (male=0) and (start_age>44 and start_age<=64) then dim4=255;
if (state=35) and (male=0) and (start_age>64) then dim4=256;

if (state=36) and (male=1) and (start_age<=14) then dim4=257;
if (state=36) and (male=1) and (start_age>14 and start_age<=44) then dim4=258;
if (state=36) and (male=1) and (start_age>44 and start_age<=64) then dim4=259;
if (state=36) and (male=1) and (start_age>64) then dim4=260;
if (state=36) and (male=0) and (start_age<=14) then dim4=261;
if (state=36) and (male=0) and (start_age>14 and start_age<=44) then dim4=262;
if (state=36) and (male=0) and (start_age>44 and start_age<=64) then dim4=263;
if (state=36) and (male=0) and (start_age>64) then dim4=264;

if (state=37) and (male=1) and (start_age<=14) then dim4=265;
if (state=37) and (male=1) and (start_age>14 and start_age<=44) then dim4=266;
if (state=37) and (male=1) and (start_age>44 and start_age<=64) then dim4=267;
if (state=37) and (male=1) and (start_age>64) then dim4=268;
if (state=37) and (male=0) and (start_age<=14) then dim4=269;
if (state=37) and (male=0) and (start_age>14 and start_age<=44) then dim4=270;
if (state=37) and (male=0) and (start_age>44 and start_age<=64) then dim4=271;
if (state=37) and (male=0) and (start_age>64) then dim4=272;

if (state=38) and (male=1) and (start_age<=14) then dim4=273;
if (state=38) and (male=1) and (start_age>14 and start_age<=44) then dim4=274;
if (state=38) and (male=1) and (start_age>44 and start_age<=64) then dim4=275;
if (state=38) and (male=1) and (start_age>64) then dim4=276;
if (state=38) and (male=0) and (start_age<=14) then dim4=277;
if (state=38) and (male=0) and (start_age>14 and start_age<=44) then dim4=278;
if (state=38) and (male=0) and (start_age>44 and start_age<=64) then dim4=279;
if (state=38) and (male=0) and (start_age>64) then dim4=280;

if (state=39) and (male=1) and (start_age<=14) then dim4=281;
if (state=39) and (male=1) and (start_age>14 and start_age<=44) then dim4=282;
if (state=39) and (male=1) and (start_age>44 and start_age<=64) then dim4=283;
if (state=39) and (male=1) and (start_age>64) then dim4=284;
if (state=39) and (male=0) and (start_age<=14) then dim4=285;
if (state=39) and (male=0) and (start_age>14 and start_age<=44) then dim4=286;
if (state=39) and (male=0) and (start_age>44 and start_age<=64) then dim4=287;
if (state=39) and (male=0) and (start_age>64) then dim4=288;

if (state=40) and (male=1) and (start_age<=14) then dim4=289;
if (state=40) and (male=1) and (start_age>14 and start_age<=44) then dim4=290;
if (state=40) and (male=1) and (start_age>44 and start_age<=64) then dim4=291;
if (state=40) and (male=1) and (start_age>64) then dim4=292;
if (state=40) and (male=0) and (start_age<=14) then dim4=293;
if (state=40) and (male=0) and (start_age>14 and start_age<=44) then dim4=294;
if (state=40) and (male=0) and (start_age>44 and start_age<=64) then dim4=295;
if (state=40) and (male=0) and (start_age>64) then dim4=296;

if (state=41) and (male=1) and (start_age<=14) then dim4=297;
if (state=41) and (male=1) and (start_age>14 and start_age<=44) then dim4=298;
if (state=41) and (male=1) and (start_age>44 and start_age<=64) then dim4=299;
if (state=41) and (male=1) and (start_age>64) then dim4=300;
if (state=41) and (male=0) and (start_age<=14) then dim4=301;
if (state=41) and (male=0) and (start_age>14 and start_age<=44) then dim4=302;
if (state=41) and (male=0) and (start_age>44 and start_age<=64) then dim4=303;
if (state=41) and (male=0) and (start_age>64) then dim4=304;

if (state=42) and (male=1) and (start_age<=14) then dim4=305;
if (state=42) and (male=1) and (start_age>14 and start_age<=44) then dim4=306;
if (state=42) and (male=1) and (start_age>44 and start_age<=64) then dim4=307;
if (state=42) and (male=1) and (start_age>64) then dim4=308;
if (state=42) and (male=0) and (start_age<=14) then dim4=309;
if (state=42) and (male=0) and (start_age>14 and start_age<=44) then dim4=310;
if (state=42) and (male=0) and (start_age>44 and start_age<=64) then dim4=311;
if (state=42) and (male=0) and (start_age>64) then dim4=312;

if (state=44) and (male=1) and (start_age<=14) then dim4=313;
if (state=44) and (male=1) and (start_age>14 and start_age<=44) then dim4=314;
if (state=44) and (male=1) and (start_age>44 and start_age<=64) then dim4=315;
if (state=44) and (male=1) and (start_age>64) then dim4=316;
if (state=44) and (male=0) and (start_age<=14) then dim4=317;
if (state=44) and (male=0) and (start_age>14 and start_age<=44) then dim4=318;
if (state=44) and (male=0) and (start_age>44 and start_age<=64) then dim4=319;
if (state=44) and (male=0) and (start_age>64) then dim4=320;

if (state=45) and (male=1) and (start_age<=14) then dim4=321;
if (state=45) and (male=1) and (start_age>14 and start_age<=44) then dim4=322;
if (state=45) and (male=1) and (start_age>44 and start_age<=64) then dim4=323;
if (state=45) and (male=1) and (start_age>64) then dim4=324;
if (state=45) and (male=0) and (start_age<=14) then dim4=325;
if (state=45) and (male=0) and (start_age>14 and start_age<=44) then dim4=326;
if (state=45) and (male=0) and (start_age>44 and start_age<=64) then dim4=327;
if (state=45) and (male=0) and (start_age>64) then dim4=328;

if (state=46) and (male=1) and (start_age<=14) then dim4=329;
if (state=46) and (male=1) and (start_age>14 and start_age<=44) then dim4=330;
if (state=46) and (male=1) and (start_age>44 and start_age<=64) then dim4=331;
if (state=46) and (male=1) and (start_age>64) then dim4=332;
if (state=46) and (male=0) and (start_age<=14) then dim4=333;
if (state=46) and (male=0) and (start_age>14 and start_age<=44) then dim4=334;
if (state=46) and (male=0) and (start_age>44 and start_age<=64) then dim4=335;
if (state=46) and (male=0) and (start_age>64) then dim4=336;

if (state=47) and (male=1) and (start_age<=14) then dim4=337;
if (state=47) and (male=1) and (start_age>14 and start_age<=44) then dim4=338;
if (state=47) and (male=1) and (start_age>44 and start_age<=64) then dim4=339;
if (state=47) and (male=1) and (start_age>64) then dim4=340;
if (state=47) and (male=0) and (start_age<=14) then dim4=341;
if (state=47) and (male=0) and (start_age>14 and start_age<=44) then dim4=342;
if (state=47) and (male=0) and (start_age>44 and start_age<=64) then dim4=343;
if (state=47) and (male=0) and (start_age>64) then dim4=344;

if (state=48) and (male=1) and (start_age<=14) then dim4=345;
if (state=48) and (male=1) and (start_age>14 and start_age<=44) then dim4=346;
if (state=48) and (male=1) and (start_age>44 and start_age<=64) then dim4=347;
if (state=48) and (male=1) and (start_age>64) then dim4=348;
if (state=48) and (male=0) and (start_age<=14) then dim4=349;
if (state=48) and (male=0) and (start_age>14 and start_age<=44) then dim4=350;
if (state=48) and (male=0) and (start_age>44 and start_age<=64) then dim4=351;
if (state=48) and (male=0) and (start_age>64) then dim4=352;

if (state=49) and (male=1) and (start_age<=14) then dim4=353;
if (state=49) and (male=1) and (start_age>14 and start_age<=44) then dim4=354;
if (state=49) and (male=1) and (start_age>44 and start_age<=64) then dim4=355;
if (state=49) and (male=1) and (start_age>64) then dim4=356;
if (state=49) and (male=0) and (start_age<=14) then dim4=357;
if (state=49) and (male=0) and (start_age>14 and start_age<=44) then dim4=358;
if (state=49) and (male=0) and (start_age>44 and start_age<=64) then dim4=359;
if (state=49) and (male=0) and (start_age>64) then dim4=360;

if (state=50) and (male=1) and (start_age<=14) then dim4=361;
if (state=50) and (male=1) and (start_age>14 and start_age<=44) then dim4=362;
if (state=50) and (male=1) and (start_age>44 and start_age<=64) then dim4=363;
if (state=50) and (male=1) and (start_age>64) then dim4=364;
if (state=50) and (male=0) and (start_age<=14) then dim4=365;
if (state=50) and (male=0) and (start_age>14 and start_age<=44) then dim4=366;
if (state=50) and (male=0) and (start_age>44 and start_age<=64) then dim4=367;
if (state=50) and (male=0) and (start_age>64) then dim4=368;

if (state=51) and (male=1) and (start_age<=14) then dim4=369;
if (state=51) and (male=1) and (start_age>14 and start_age<=44) then dim4=370;
if (state=51) and (male=1) and (start_age>44 and start_age<=64) then dim4=371;
if (state=51) and (male=1) and (start_age>64) then dim4=372;
if (state=51) and (male=0) and (start_age<=14) then dim4=373;
if (state=51) and (male=0) and (start_age>14 and start_age<=44) then dim4=374;
if (state=51) and (male=0) and (start_age>44 and start_age<=64) then dim4=375;
if (state=51) and (male=0) and (start_age>64) then dim4=376;

if (state=53) and (male=1) and (start_age<=14) then dim4=377;
if (state=53) and (male=1) and (start_age>14 and start_age<=44) then dim4=378;
if (state=53) and (male=1) and (start_age>44 and start_age<=64) then dim4=379;
if (state=53) and (male=1) and (start_age>64) then dim4=380;
if (state=53) and (male=0) and (start_age<=14) then dim4=381;
if (state=53) and (male=0) and (start_age>14 and start_age<=44) then dim4=382;
if (state=53) and (male=0) and (start_age>44 and start_age<=64) then dim4=383;
if (state=53) and (male=0) and (start_age>64) then dim4=384;

if (state=54) and (male=1) and (start_age<=14) then dim4=385;
if (state=54) and (male=1) and (start_age>14 and start_age<=44) then dim4=386;
if (state=54) and (male=1) and (start_age>44 and start_age<=64) then dim4=387;
if (state=54) and (male=1) and (start_age>64) then dim4=388;
if (state=54) and (male=0) and (start_age<=14) then dim4=389;
if (state=54) and (male=0) and (start_age>14 and start_age<=44) then dim4=390;
if (state=54) and (male=0) and (start_age>44 and start_age<=64) then dim4=391;
if (state=54) and (male=0) and (start_age>64) then dim4=392;

if (state=55) and (male=1) and (start_age<=14) then dim4=393;
if (state=55) and (male=1) and (start_age>14 and start_age<=44) then dim4=394;
if (state=55) and (male=1) and (start_age>44 and start_age<=64) then dim4=395;
if (state=55) and (male=1) and (start_age>64) then dim4=396;
if (state=55) and (male=0) and (start_age<=14) then dim4=397;
if (state=55) and (male=0) and (start_age>14 and start_age<=44) then dim4=398;
if (state=55) and (male=0) and (start_age>44 and start_age<=64) then dim4=399;
if (state=55) and (male=0) and (start_age>64) then dim4=400;

if (state=56) and (male=1) and (start_age<=14) then dim4=401;
if (state=56) and (male=1) and (start_age>14 and start_age<=44) then dim4=402;
if (state=56) and (male=1) and (start_age>44 and start_age<=64) then dim4=403;
if (state=56) and (male=1) and (start_age>64) then dim4=404;
if (state=56) and (male=0) and (start_age<=14) then dim4=405;
if (state=56) and (male=0) and (start_age>14 and start_age<=44) then dim4=406;
if (state=56) and (male=0) and (start_age>44 and start_age<=64) then dim4=407;
if (state=56) and (male=0) and (start_age>64) then dim4=408;

if (dim4=.) and (male=1) and (start_age<=14) then dim4=409;
if (dim4=.) and (male=1) and (start_age>14 and start_age<=44) then dim4=410;
if (dim4=.) and (male=1) and (start_age>44 and start_age<=64) then dim4=411;
if (dim4=.) and (male=1) and (start_age>64) then dim4=412;
if (dim4=.) and (male=0) and (start_age<=14) then dim4=413;
if (dim4=.) and (male=0) and (start_age>14 and start_age<=44) then dim4=414;
if (dim4=.) and (male=0) and (start_age>44 and start_age<=64) then dim4=415;
if (dim4=.) and (male=0) and (start_age>64) then dim4=416;


dim5=.;
if (male=1) and (race=1) and (start_age>=0 and start_age<=4) then dim5=1;
if (male=1) and (race=1) and (start_age>=5 and start_age<=9) then dim5=2;
if (male=1) and (race=1) and (start_age>=10 and start_age<=14) then dim5=3;
if (male=1) and (race=1) and (start_age>=15 and start_age<=19) then dim5=4;
if (male=1) and (race=1) and (start_age>=20 and start_age<=24) then dim5=5;
if (male=1) and (race=1) and (start_age>=25 and start_age<=29) then dim5=6;
if (male=1) and (race=1) and (start_age>=30 and start_age<=34) then dim5=7;
if (male=1) and (race=1) and (start_age>=35 and start_age<=39) then dim5=8;
if (male=1) and (race=1) and (start_age>=40 and start_age<=44) then dim5=9;
if (male=1) and (race=1) and (start_age>=45 and start_age<=49) then dim5=10;
if (male=1) and (race=1) and (start_age>=50 and start_age<=54) then dim5=11;
if (male=1) and (race=1) and (start_age>=55 and start_age<=59) then dim5=12;
if (male=1) and (race=1) and (start_age>=60 and start_age<=64) then dim5=13;
if (male=1) and (race=1) and (start_age>=65 and start_age<=69) then dim5=14;
if (male=1) and (race=1) and (start_age>=70 and start_age<=74) then dim5=15;
if (male=1) and (race=1) and (start_age>=75 and start_age<=79) then dim5=16;
if (male=1) and (race=1) and (start_age>=80 and start_age<=84) then dim5=17;
if (male=1) and (race=1) and (start_age>=85) then dim5=18;

if (male=0) and (race=1) and (start_age>=0 and start_age<=4) then dim5=19;
if (male=0) and (race=1) and (start_age>=5 and start_age<=9) then dim5=20;
if (male=0) and (race=1) and (start_age>=10 and start_age<=14) then dim5=21;
if (male=0) and (race=1) and (start_age>=15 and start_age<=19) then dim5=22;
if (male=0) and (race=1) and (start_age>=20 and start_age<=24) then dim5=23;
if (male=0) and (race=1) and (start_age>=25 and start_age<=29) then dim5=24;
if (male=0) and (race=1) and (start_age>=30 and start_age<=34) then dim5=25;
if (male=0) and (race=1) and (start_age>=35 and start_age<=39) then dim5=26;
if (male=0) and (race=1) and (start_age>=40 and start_age<=44) then dim5=27;
if (male=0) and (race=1) and (start_age>=45 and start_age<=49) then dim5=28;
if (male=0) and (race=1) and (start_age>=50 and start_age<=54) then dim5=29;
if (male=0) and (race=1) and (start_age>=55 and start_age<=59) then dim5=30;
if (male=0) and (race=1) and (start_age>=60 and start_age<=64) then dim5=31;
if (male=0) and (race=1) and (start_age>=65 and start_age<=69) then dim5=32;
if (male=0) and (race=1) and (start_age>=70 and start_age<=74) then dim5=33;
if (male=0) and (race=1) and (start_age>=75 and start_age<=79) then dim5=34;
if (male=0) and (race=1) and (start_age>=80 and start_age<=84) then dim5=35;
if (male=0) and (race=1) and (start_age>=85) then dim5=36;

if (male=1) and (race=2) and (start_age>=0 and start_age<=4) then dim5=37;
if (male=1) and (race=2) and (start_age>=5 and start_age<=9) then dim5=38;
if (male=1) and (race=2) and (start_age>=10 and start_age<=14) then dim5=39;
if (male=1) and (race=2) and (start_age>=15 and start_age<=19) then dim5=40;
if (male=1) and (race=2) and (start_age>=20 and start_age<=24) then dim5=41;
if (male=1) and (race=2) and (start_age>=25 and start_age<=29) then dim5=42;
if (male=1) and (race=2) and (start_age>=30 and start_age<=34) then dim5=43;
if (male=1) and (race=2) and (start_age>=35 and start_age<=39) then dim5=44;
if (male=1) and (race=2) and (start_age>=40 and start_age<=44) then dim5=45;
if (male=1) and (race=2) and (start_age>=45 and start_age<=49) then dim5=46;
if (male=1) and (race=2) and (start_age>=50 and start_age<=54) then dim5=47;
if (male=1) and (race=2) and (start_age>=55 and start_age<=64) then dim5=48;
if (male=1) and (race=2) and (start_age>=65) then dim5=49;

if (male=0) and (race=2) and (start_age>=0 and start_age<=4) then dim5=50;
if (male=0) and (race=2) and (start_age>=5 and start_age<=9) then dim5=51;
if (male=0) and (race=2) and (start_age>=10 and start_age<=14) then dim5=52;
if (male=0) and (race=2) and (start_age>=15 and start_age<=19) then dim5=53;
if (male=0) and (race=2) and (start_age>=20 and start_age<=24) then dim5=54;
if (male=0) and (race=2) and (start_age>=25 and start_age<=29) then dim5=55;
if (male=0) and (race=2) and (start_age>=30 and start_age<=34) then dim5=56;
if (male=0) and (race=2) and (start_age>=35 and start_age<=39) then dim5=57;
if (male=0) and (race=2) and (start_age>=40 and start_age<=44) then dim5=58;
if (male=0) and (race=2) and (start_age>=45 and start_age<=49) then dim5=59;
if (male=0) and (race=2) and (start_age>=50 and start_age<=54) then dim5=60;
if (male=0) and (race=2) and (start_age>=55 and start_age<=64) then dim5=61;
if (male=0) and (race=2) and (start_age>=65) then dim5=62;

if (male=1) and (race=3) and (start_age>=0 and start_age<=4) then dim5=63;
if (male=1) and (race=3) and (start_age>=5 and start_age<=9) then dim5=64;
if (male=1) and (race=3) and (start_age>=10 and start_age<=14) then dim5=65;
if (male=1) and (race=3) and (start_age>=15 and start_age<=24) then dim5=66;
if (male=1) and (race=3) and (start_age>=25 and start_age<=34) then dim5=67;
if (male=1) and (race=3) and (start_age>=35 and start_age<=44) then dim5=68;
if (male=1) and (race=3) and (start_age>=45 and start_age<=54) then dim5=69;
if (male=1) and (race=3) and (start_age>=55 and start_age<=64) then dim5=70;
if (male=1) and (race=3) and (start_age>=65) then dim5=71;

if (male=0) and (race=3) and (start_age>=0 and start_age<=4) then dim5=72;
if (male=0) and (race=3) and (start_age>=5 and start_age<=9) then dim5=73;
if (male=0) and (race=3) and (start_age>=10 and start_age<=14) then dim5=74;
if (male=0) and (race=3) and (start_age>=15 and start_age<=24) then dim5=75;
if (male=0) and (race=3) and (start_age>=25 and start_age<=34) then dim5=76;
if (male=0) and (race=3) and (start_age>=35 and start_age<=44) then dim5=77;
if (male=0) and (race=3) and (start_age>=45 and start_age<=54) then dim5=78;
if (male=0) and (race=3) and (start_age>=55 and start_age<=64) then dim5=79;
if (male=0) and (race=3) and (start_age>=65) then dim5=80;

run;





/*/ 2. CREATE RAKING MACRO /*/
%macro rake(n,dataset,variable); /*/ n=number of dimensions within the dataset to rake, 
	dataset=name of dataset sent into macro below, variable=name of weight variable /*/

%let m=0; /*/ set iteration counter /*/
%let maxdiff=201; /*/ set max diff between control and observed marginal total /*/

%do %while (&maxdiff.>0.001 and &m.<10);
%let m=&m.+1;


*2a. loop through each dimension and rake separately;
%do d=1 %to &n.; 

* create adjustment factor for each dimension;
proc summary data=&dataset;
class dim&d.;
var n wn cn;
output out=dimtot&d. sum=ntot wntot cntot;
run;

data dimtotaf&d.;
set dimtot&d.;
adjustmentfac&d.=cntot/wntot;
run;

* merge back to cross tabulation input dataset and update weights;
proc sort data=&dataset out=&dataset;
by dim&d.;
run;

proc sort data=dimtotaf&d. out=dimtotaf&d.;
by dim&d.;
run;

data &dataset(drop=ntot wntot cntot);
merge &dataset dimtotaf&d.;
by dim&d.;
run;

data &dataset(drop=adjustmentfac&d.);
set &dataset;
w&d.=wn*adjustmentfac&d.;
drop wn;
rename w&d.=wn;
run;

%end; /*/ finish looping through each dimension, for the given input dataset /*/


* 2b. calculate the difference between the control marginal total and weighted marginal total in the data after raking each dimension for the given iteration, separately for each dimension;
%do d=1 %to &n; 
* calculate raw, absolute, and percentage diffs between control and weighted marginal totals;
proc summary data=&dataset;
class dim&d.;
var n wn cn;
output out=dimtot&d. sum=ntot wntot cntot;
run;

data dimtot&d.;
set dimtot&d.;
if (dim&d.=.) then delete;
run;

data dimtottol&d.;

set dimtot&d.;
diff&d.=wntot-cntot;
diffabs&d.=abs(wntot-cntot);
run;

proc sql;
create table dimtottol&d. as
select dim&d., ntot, wntot, cntot, diff&d., diffabs&d., sum(cntot) as cntotall
from dimtottol&d.;
quit;

data dimtottol&d.;
set dimtottol&d.;
wpercent=wntot/cntotall;
cpercent=cntot/cntotall;
diffpercent=wpercent-cpercent;
diffpercentabs=abs(diffpercent);
run; 

*print a raking performance (differences, for each dimension and iteration) in the .lst output;
proc print data=dimtottol&d.;
title "Raking &variable., dim&d.,  iteration &m.";
run;

*combine the percentage differences across dimensions, for use in convergence check below;
*data dimtottol2&d.(keep=diffabs dim dimnum);
data dimtottol2&d.(keep=diffpercentabs dim dimnum);
set dimtottol&d.;
*rename diffabs&d.=diffabs;
dim=&d.;
rename dim&d.=dimnum;
run;

%end;

data dimtottol2;
set dimtottol21 dimtottol22 dimtottol23 dimtottol24 dimtottol25;
run;


* 2c. find the maximum difference between control and weighted marginal totals across all the dim-cat cross-tabs and update the maxdiff variable;
proc iml;
use dimtottol2;
read all var {diffpercentabs} into X[c=varNames];
close dimtottol2;
max=X[<>, ];
create max from max[colname={"max"}];
append from max;
close max;

data max;
set max;
call symput ('maxdiff1',trim(left(put(max,8.4))));
run;
%let maxdiff=&maxdiff1.;


%put m=&m.;
%put maxdiff=&maxdiff.;
%end; /*/ if max iterations not reached and max diff between control and observed marginal totals too large, go back to the top and re-rake the updated weights /*/
%mend rake;





/*/ 3. RAKE THE INITIAL WEIGHT /*/
* 3a. get sample and weighted counts by dim-cat cross tabulations;
proc summary data=ssb_available_repw_rake&k.&year.;
class dim1 dim2 dim3 dim4 dim5;
var initwgt;
output out=crosstotinit n=n sum=wn;
run;

* drop the observations that are sums across dims or dim-cats;
data crosstotinit;
set crosstotinit;
if (dim1=.) or (dim2=.) or (dim3=.) or (dim4=.) or (dim5=.) then delete;
run;

* 3b. merge population control totals;
proc sort data=crosstotinit out=crosstotinit;
by dim1 dim2 dim3 dim4 dim5;
run;

proc sort data=popcontrol_crosstab&year. out=popcontroltot;
by dim1 dim2 dim3 dim4 dim5;
run;

data crosstotinit;
merge crosstotinit(in=c) popcontroltot(in=p);
by dim1 dim2 dim3 dim4 dim5;
if c=1 and p=1;
run;

* 3c. create original weighted pop variable;
data crosstotinit;
set crosstotinit;
wn0=wn;
run;

* 3d. Run the raking macro to loop through dimensions, create adjustment factors, merge back to cross tabulations;
%rake(5,crosstotinit,initwgt);

proc print data=crosstotinit(obs=15);
run;

* 3e. create final adjusted person weights;
data crosstotinit;
set crosstotinit;
finalaf=wn/wn0;
run;

proc sort data=crosstotinit out=crosstot_initwgt&k.;
by dim1 dim2 dim3 dim4 dim5;
run;

proc sort data=ssb_available_repw_rake&k.&year. out=ssb_available_repw_rake&k.&year.;
by dim1 dim2 dim3 dim4 dim5;
run;

data ssb_available_repw_rake&k.&year.;
merge ssb_available_repw_rake&k.&year.(in=g) crosstot_initwgt&k.(in=r);
by dim1 dim2 dim3 dim4 dim5;
if g=1 and r=1;
run;

proc print data=ssb_available_repw_rake&k.&year.(obs=15);
run;

data ssb_available_repw_rake&k.&year.;
set ssb_available_repw_rake&k.&year.;
finalinitwgt=initwgt*finalaf;
run;





/*/ 4. RAKE REPLICATE WEIGHTS /*/
%macro looprakerepw(n);
%do r=1 %to &n;

* 4a. get counts by dim-cat cross tabulations;
proc summary data=ssb_available_repw_rake&k.&year.;
class dim1 dim2 dim3 dim4 dim5;
var repweight&r.;
output out=crosstotrepw&r. n=n sum=wn;
run;

* drop the observations that sum across dims or dim-cats;
data crosstotrepw&r.;
set crosstotrepw&r.;
if (dim1=.) or (dim2=.) or (dim3=.) or (dim4=.) or (dim5=.) then delete;
run;

* 4b. merge population control totals;
proc sort data=crosstotrepw&r. out=crosstotrepw&r.;
by dim1 dim2 dim3 dim4 dim5;
run;

proc sort data=popcontrol_crosstab&year. out=popcontroltot;
by dim1 dim2 dim3 dim4 dim5;
run;

data crosstotrepw&r.;
merge crosstotrepw&r.(in=c) popcontroltot(in=p);
by dim1 dim2 dim3 dim4 dim5;
if c=1 and p=1;
run;

* 4c. create original weighted pop variable;
data crosstotrepw&r.;
set crosstotrepw&r.;
wn0=wn;
run;

* 4d. run raking macro to loop through dimensions, create adjustment factors, merge back to cross tabulations;
%rake(5,crosstotrepw&r.,repweight&r.);

* 4e. create final adjusted person weights;
data crosstotrepw&r.(drop=diffabs1 diffabs2 diffabs3 diffabs4 diffabs5);
set crosstotrepw&r.;
finalaf&r.=wn/wn0;
run;

proc sort data=crosstotrepw&r. out=crosstotrepw&r.;
by dim1 dim2 dim3 dim4 dim5;
run;

proc sort data=ssb_available_repw_rake&k.&year. out=ssb_available_repw_rake&k.&year.;
by dim1 dim2 dim3 dim4 dim5;
run;

data ssb_available_repw_rake&k.&year.;
merge ssb_available_repw_rake&k.&year.(in=g) crosstotrepw&r.(in=r);
by dim1 dim2 dim3 dim4 dim5;
if g=1 and r=1;
run;

data ssb_available_repw_rake&k.&year.;
set ssb_available_repw_rake&k.&year.;
finalrepwgt&r.=repweight&r.*finalaf&r.;
run;


%end;
%mend looprakerepw;



%looprakerepw(108);





proc means data=ssb_available_repw_rake&k.&year.;
var initwgt finalrepwgt1-finalrepwgt108;
run;


