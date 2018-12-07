
%macro impute(name= , dir=default, setup=old, mode= );

  %let msg = ;
  %let path = ;
  %setup;

  %if (%bquote(&msg) eq ) %then %do;
    %let datain = ;
    %let dataout = ;
    %let keys = datain dataout;
    %getkeys;
    %if (%bquote(&datain) eq ) %then %let msg = No Datain file.;
  %end;

  %if (%bquote(&msg) eq ) %then %do;
    %metadata(datain=&datain);
  %end;

  %if (%bquote(&msg) eq ) %then %do;
    %put Check setup.;
    %execute(prog=iveset);

    %if (%bquote(&msg) eq ) %then %do;
      %put Input data.;
      filename input "&path..inp";
      %include input;
      %put Execute Imputation.;
      %execute(prog=impute);
    %end;

    %if (%bquote(&msg) eq  ) %then %do;
      %if (%quote(&dataout) ne ) %then %putdata(name=&name, dir=&dir);
      %copylst;
    %end;

    %if (%bquote(&msg) eq  ) %then %do;
      %if (%sysfunc(filename(outref, &path..out)) eq 0) %then %do;
        %let file = %sysfunc(fopen(&outref));
        %if (&file ne 0) %then %do;
          %let rc = %sysfunc(fclose(&file));
          %put Plot the diagnostics.;
          filename output "&path..out";
          %include output;
        %end;
      %end;
    %end;

    %copylog;
  %end;

  %if (%bquote(&msg) ne ) %then %put %bquote(&msg);

%mend impute;
