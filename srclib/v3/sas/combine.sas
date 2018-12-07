
/* macro to combine sas datasets */

%macro combine(name= , dir=default, setup=old, mode= );

  %let msg = ;  /* get the parameters */
  %let path = ;
  %setup;
  %if (%bquote(&msg) eq ) %then %do;
    %let datain = ;
    %let dataout = ;
    %let var = ;
    %let keys = datain dataout var;
    %getkeys;
    %if (%bquote(&datain) eq ) %then %let msg = No Datain file.;
    %if (%bquote(&dataout) eq ) %then %let msg = No Dataout file.;
  %end;

  %if (%bquote(&msg) eq ) %then %do;  /* check the parameters */
    %let pos = %index(&datain,  %str(%"));  /* datain */
    %if &pos > 0 %then %let msg = Invalid datain;  /* quotes disallowed */
    %else %do;
      %let pos = %index(&dataout, %str(%"));  /* datain */
      %if &pos > 0 %then %let msg = Invalid dataout;  /* quotes disallowed */
    %end;
  %end;
  %if &msg = %then %do;

    data _null_;
      _pattern_ = prxparse('/^[\w\. ]+$/');  /* datain */
      if not prxmatch(_pattern_, "&datain") then call symput('msg', 'Invalid datain');  /* names, periods and spaces only */
      else do;
        _pattern_ = prxparse('/^[\w\.]+$/');  /* dataout */
        if not prxmatch(_pattern_, "&dataout") then call symput('msg', 'Invalid dataout');  /* names and period only */
    %if (&var ne ) %then %do;  /* variable list */
        else do;
          _pattern_ = prxparse('/^[\w ]+$/');  /* variable list */
          if not prxmatch(_pattern_, "&var") then call symput('msg', 'Invalid variable list');  /* names and spaces only */
        end;
    %end;
      end;
    run;

  %end;

  %if &msg = %then %do;

    %put &var;

    data &dataout;  /* combine the satasets */
      set &datain;
    %if (&var ne ) %then %do;  /* variable list */
      keep &var;  /* subset */
    %end;
    run;

  %end;
  %else %put &msg;  /* error */

%mend combine;

