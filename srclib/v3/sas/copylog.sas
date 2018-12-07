%macro copylog;
  %if (%sysfunc(filename(logref, &path..log)) eq 0) %then %do;
    %let file = %sysfunc(fopen(&logref));
    %if (&file ne 0) %then %do;
      %let rc = %sysfunc(fclose(&file));
      %put Copy log.;
      data _null_;
        infile "&path..log" length=len end=test;
        do until (test eq 1);
          input line $varying133. len;
          put line $varying133. len;
        end;
        put;
        output;
      run;
    %end;
  %end;
%mend copylog;

