
%macro bbdesign(name= , dir=default, setup=old, mode= );
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
    %execute(prog=bbdesign, args=/setup);

    %if (%bquote(&msg) eq ) %then %do;
      %put Input data.;
      filename input "&path..inp";
      %include input;
      %put Execute bbdesign.;
      %execute(prog=bbdesign);
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
            %if (%sysfunc(filename(delref, &path..out)) eq 0) %then %do;
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

%mend bbdesign;

