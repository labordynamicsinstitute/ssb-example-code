
%macro regress(name= , dir=default, setup=old, mode= );

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
    %let metain = %scan(%bquote(&datain), 1, ' ');
    %metadata(datain=&metain);
  %end;

  %if (%bquote(&msg) eq ) %then %do;
    %put Check setup.;
    %execute(prog=iveset);

    %if (%bquote(&msg) eq ) %then %do;
      %put Input data.;
      filename input "&path..inp";
      %include input;
      %if (%sysfunc(filename(impref, &path..imp)) eq 0) %then %do;
        %let file = %sysfunc(fopen(&impref));
        %if (&file ne 0) %then %do;
          %let rc = %sysfunc(fclose(&file));
          %put Execute Imputation.;
          %execute(prog=impute);
          %if (%bquote(&msg) eq ) %then %do;
            %if (%quote(&dataout) ne ) %then %putdata(name=&name, dir=&dir);
            %put Input imputed data.;
            filename input "&path..imp";
            %include input;
          %end;  
        %end;
      %end;
    %end;

    %if (%bquote(&msg) eq ) %then %do;
      %put Execute Regressions.;
      %execute(prog=regress);
    %end;

    %if (%bquote(&msg) eq ) %then %do;
      %if (%sysfunc(filename(outref, &path..out)) eq 0) %then %do;
        %let file = %sysfunc(fopen(&outref));
        %if (&file ne 0) %then %do;
          %let rc = %sysfunc(fclose(&file));
          %put Output results.;
          filename output "&path..out";
          %include output;
          %if (%upcase(&mode) ne DEBUG) %then %do;
            %if (%sysfunc(filename(delref, &path..est)) eq 0) %then %do;
              %let rc = %sysfunc(fdelete(&delref));
              %let rc = %sysfunc(filename(delref));
            %end;
            %if (%sysfunc(filename(delref, &path..inf)) eq 0) %then %do;
              %let rc = %sysfunc(fdelete(&delref));
              %let rc = %sysfunc(filename(delref));
            %end;
            %if (%sysfunc(filename(delref, &path..out)) eq 0) %then %do;
              %let rc = %sysfunc(fdelete(&delref));
              %let rc = %sysfunc(filename(delref));
            %end;
            %if (%sysfunc(filename(delref, &path..pre)) eq 0) %then %do;
              %let rc = %sysfunc(fdelete(&delref));
              %let rc = %sysfunc(filename(delref));
            %end;
            %if (%sysfunc(filename(delref, &path..rep)) eq 0) %then %do;
              %let rc = %sysfunc(fdelete(&delref));
              %let rc = %sysfunc(filename(delref));
            %end;
            %if (%sysfunc(filename(delref, &path..rnk)) eq 0) %then %do;
              %let rc = %sysfunc(fdelete(&delref));
              %let rc = %sysfunc(filename(delref));
            %end;
          %end;
        %end;
      %end;    
      %copylst;
    %end;

    %copylog;
  %end;

  %if (%bquote(&msg) ne ) %then %put %bquote(&msg);

%mend regress;
