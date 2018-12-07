
%macro putdata(name=, dir=default, dataout= , impl= , mult= );

  %let msg = ;  /* get the setup */
  %let path = ;
  %let setup = old;
  %setup;

  %if (%bquote(&msg) eq ) %then %do;  /* parse the setup */
    %let datain = ;
    %let implicates = ;
    %let multiples = ;
    %let synthesize = ;
    %let keys = datain implicates multiples synthesize;
    %if (&dataout eq ) %then %let keys = &keys dataout;
    %getkeys;

    %if (%bquote(&datain) eq ) %then %let msg = No Datain file.;  /* check the setup */
    %else %if (%bquote(&dataout) eq ) %then %let msg = No Dataout file.;
    %else %do;
      %if (&implicates eq and &synthesize ne ) %then %let implicates = 1;
      %else %if (&implicates eq and &multiples eq ) %then %let multiples = 1;
      %let all = %scan(&dataout, 2, " ");
      %let dataout = %scan(&dataout, 1, " ");
      %if (&impl eq and &mult eq ) %then %do;  /* no impl or mult specified */
        %if (%length(&all) ge 3) %then %do;
          %let all = %upcase(%substr(&all, 1, 3));
          %if (&all eq ALL or &all eq CON) %then %do;
            %if (&implicates ne ) %then %let impl = all;
            %if (&multiples ne ) %then %let mult = all;
          %end;
        %end;
        %if (&implicates ne and &impl ne all) %then %let impl = 1;
        %if (&multiples ne and &mult ne all) %then %let mult = 1;
      %end;
      %else %do;  /* impl or mult specified */
        %if (&implicates eq ) %then %let impl = ;  /* check impl */
        %else %if (&impl eq ) %then %let impl = 1;
        %else %if (%upcase(&impl) eq ALL) %then %let impl = all;
        %else %if (&impl le 0 or &impl gt &implicates) %then %let msg = Invalid implicate.;
        %if (&multiples eq ) %then %let imult = ;  /* check mult */
        %else %if (&mult eq ) %then %let mult = 1;
        %else %if (%upcase(&mult) eq ALL) %then %let mult = all;
        %else %if (&mult le 0 or &mult gt &multiples) %then %let msg = Invalid multiple.;
      %end;
      %if (&implicates ne and &multiples ne ) %then %do;  /* both imputate and synthesize */
        %if (%sysfunc(filename(logref, &path..log)) eq 0) %then %do;  /* check the log */
          %if (%sysfunc(fileref(&logref)) le 0) %then %do;
            %let logfile = %sysfunc(fopen(&logref, i));
            %if (&logfile ne 0) %then %do;
              %let posn = 0;
              %do %until(&posn gt 0);
                %let posn = 1;
                %if (%sysfunc(fread(&logfile)) eq 0) %then %do;
                  %let posn = 0;
                  %if (%sysfunc(fget(&logfile, line, 32767)) eq 0) %then %do;
                    %let posn = %index(%bquote(&line), Imputation canceled);
                    %if (&posn gt 0) %then %do;  /* the imputation has been canceled */
                      %let multiples = ;
                      %let mult = ;
                    %end;
                    %else %let posn = %index(%bquote(&line), Imputate);
                  %end;
                %end;
              %end;
              %let rc = %sysfunc(fclose(&logfile));
            %end;
          %end;
        %end;
      %end;
    %end;
  %end;

  %if (%bquote(&msg) eq ) %then %do;  /* output the imputed/synthesized data */

    %put Output data.;
    %let llong = 8;
    %let lshort = 2;
    %let ldouble = 8;
    %updata(mult=&mult, impl=&impl, dataout=&dataout);  /* output the data */

  %end;

  %if (%bquote(&msg) ne ) %then %put &msg;  /* copy an error message to the sas log window */

%mend putdata;

%macro updata(dataout= , impl= , mult= );

  data &dataout;
    set &datain;
    array _vcor_(32767) _temporary_;
    retain
    %if (&multiples ne ) %then %do;
      _cmult_
    %end;
    %if (&implicates ne ) %then %do;
      _cimpl_
    %end;
      _cobs_
      _crecl_;
    infile "&path..cor" recfm=n;

    if (_n_ eq 1) then do;  /* get the first correction record header */
      input _crecl_ ib&llong..;
      if (_crecl_ gt 0) then do;  /* observation number */
        input _cobs_ ib&llong..;
        _crecl_ = _crecl_ - 2 * &llong;
        %if (&multiples ne ) %then %do;  /* multiple */
          input _cmult_ ib&lshort..;
          _crecl_ = _crecl_ - &lshort;
        %end;
        %if (&implicates ne ) %then %do;  /* implicate */
          input _cimpl_ ib&lshort..;
          _crecl_ = _crecl_ - &lshort;
        %end;
      end;
      else _cobs_ = .;  /* no more corrections */
    end;

    %if (&multiples ne ) %then %do;  /* multiples */
      %if (&mult eq all) %then %do;
        do _mult_ = 1 to &multiples;
      %end;
      %else %do;
        _mult_ = &mult;
      %end;
    %end;
    %if (&implicates ne ) %then %do;  /* implicates */
      %if (&impl eq all) %then %do;
        do _impl_ = 1 to &implicates;
      %end;
      %else %do;
        _impl_ = &impl;
      %end;
    %end;

    do while (_cobs_ ne .);  /* impute/synthesize the record */

      _keep_ = 0;  /* make the correction? */
      if (_n_ lt _cobs_) then leave;
      if (_n_ eq _cobs_) then do;
        %if (&multiples ne ) %then %do;
          if (_mult_ lt _cmult_) then leave;
          if (_mult_ eq _cmult_) then do;
        %end;
        %if (&implicates ne ) %then %do;
          if (_impl_ lt _cimpl_) then leave;
          if (_impl_ eq _cimpl_ or _cimpl_ eq 0) then do;
        %end;
        _keep_ = 1;
        %if (&implicates ne ) %then %do;
          end;
        %end;
        %if (&multiples ne ) %then %do;
          end;
        %end;
      end;

      if (_keep_) then do;  /* make the correction */
        do while (_crecl_ gt 0);
          input _vnum_ ib&lshort..;
          _crecl_ = _crecl_ - &lshort;
          filename imvars "&path..imv";
          %include imvars;
          _crecl_ = _crecl_ - &ldouble;
        end;
      end;
      else input +_crecl_;  /* skip the correction */

      input _crecl_ ib&llong..;  /* get the next correction record header */
      if (_crecl_ gt 0) then do;
        input _cobs_ ib&llong..;
        _crecl_ = _crecl_ - 2 * &llong;
        %if (&multiples ne ) %then %do;
          input _cmult_ ib&lshort..;
          _crecl_ = _crecl_ - &lshort;
        %end;
        %if (&implicates ne ) %then %do;
          input _cimpl_ ib&lshort..;
          _crecl_ = _crecl_ - &lshort;
        %end;
      end;
      else _cobs_ = .;  /* no more corrections */
    end;

    filename kpvars "&path..kpv";  /* output the record */
    %include kpvars;
    output;

    %if (&impl eq all) %then %do;
      end;
    %end;
    %if (&mult eq all) %then %do;
      end;
    %end;

  run;

%mend updata;
