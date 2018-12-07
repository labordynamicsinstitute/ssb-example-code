
%macro synthesize(name= , dir=default, setup=old, mode= );

  %let msg = ;  /* get the setup */
  %let path = ;
  %setup;

  %if (%bquote(&msg) eq ) %then %do;  /* parse the setup */
    %let datain = ;
    %let dataout = ;
    %let keys = datain dataout;
    %getkeys;
    %if (%bquote(&datain) eq ) %then %let msg = No Datain file.;  /* check the setup */
  %end;

  %if (%bquote(&msg) eq ) %then %do;  /* get the metadata */
    %metadata(datain=&datain);
  %end;

  %if (%bquote(&msg) eq ) %then %do;  /* process the setup */
    %put Check setup.;
    %execute(prog=iveset);

    %if (%bquote(&msg) eq ) %then %do;  /* impute/synthesize the data */
      %put Input data.;
      filename input "&path..inp";
      %include input;
      %put Execute Synthesize.;
      %execute(prog=impute);
    %end;

    %if (%bquote(&msg) eq  ) %then %do;

      %if (%quote(&dataout) ne ) %then %putdata(name=&name, dir=&dir);  /* output the sas dataset */

      %copylst;  /* copy the list to the sas output window */
    %end;

    %copylog;  /* copy the log to the sas log window */
  %end;

  %if (%bquote(&msg) ne ) %then %put %bquote(&msg);  /* copy an error message to the sas log window */

%mend synthesize;
