%macro execute(prog= , args= );
  %let lib = %sysget(SRCLIB);
  %if (&sysscp eq WIN) %then %do;
    %if (%bquote(&lib) eq ) %then %let lib = ..\bin;
    %else %if (%substr(&lib, %length(&lib) - 2) eq sas) %then %do;
      %let lib = %substr(&lib, 1, %length(&lib) - 3);
      %let lib = &lib.bin;
    %end;
    %else %let lib = &lib\bin;
    %let program = &lib\&prog;
    %if (%index(&program, %str( )) ne 0) %then %let program = %str(%")&program%str(%");
    %let setup = &path..set;
    %if (%index(&setup, %str( )) ne 0) %then %let setup = %str(%")&setup%str(%");
    %let parms = /sas;
    %if (&mode ne ) %then %let parms = &parms /&mode;
    %if (%bquote(&args) ne ) %then %let parms = &parms &args;
    options noxwait;
    data _null_;
    call system("color F8 %str(&) title &program %str(&) &program &setup &parms")%str(;);
    run;
  %end;
  %else %do;
    %if (%bquote(&lib) eq ) %then %let lib = ../bin;
    %else %if (%substr(&lib, %length(&lib) - 2) eq sas) %then %do;
      %let lib = %substr(&lib, 1, %length(&lib) - 3);
      %let lib = &lib.bin;
    %end;
    %else %let lib = &lib/bin;
    %let program = &lib/&prog;
    %if (%index(&program, %str( )) ne 0) %then %let program = %str(%")&program%str(%");
    %let setup = &path..set;
    %if (%index(&setup, %str( )) ne 0) %then %let setup = %str(%")&setup%str(%");
    %if (&mode eq and &sysenv eq BACK) %then %let mode = batch;
    %let parms = /sas;
    %if (&mode ne ) %then %let parms = &parms /&mode;
    %if (%bquote(&args) ne ) %then %let parms = &parms &args;
    data _null_;
    call system("&program &setup &parms")%str(;);
    run;
  %end;
  %if (&sysrc gt 1) %then %let msg = Abnormal termination of &prog.. Check log.;
%mend execute;

