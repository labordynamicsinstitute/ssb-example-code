
%macro search(name= , dir=default, setup=old, mode= );
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
    %execute(prog=srchset);

    %if (%bquote(&msg) eq ) %then %do;
      %put Input data.;
      filename input "&path..inp";
      %include input;
      %put Execute Search.;
      %execute(prog=search);
    %end;

    %if (%bquote(&msg) eq ) %then %do;
      %if (%quote(&dataout) ne ) %then %do;
        %if (%sysfunc(filename(resref, &path..res)) eq 0) %then %do;
          %let file = %sysfunc(fopen(&resref));
          %if (&file ne 0) %then %do;
            %let rc = %sysfunc(fclose(&file));
            %put Output residuals.;
            data &dataout;
              set &datain;
              filename resid "&path..res";
              %include resid;
            run;
          %end;
        %end;
      %end;
      %copylst;
    %end;

    %copylog;
  %end;

  %if (%bquote(&msg) ne ) %then %put %bquote(&msg);

%mend search;
