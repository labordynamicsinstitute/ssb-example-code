
/* Sasmod - IVEware multiple imputation jackknnife regression macro */

%macro sasmod(name= , dir=default, setup=old, mode = );

  %let msg = ;  /* error message */
  %let path = ;  /* user working path */
  %let ldouble = 8;  /* length of double-word binary */
  %let lint = 4;  /* length of integer binary */

  %setup;  /* locate setup */

  %if (%bquote(&msg) eq ) %then %do;  /* get datain and print parameters */
    %let datain = ;  /* input data file(s) */
    %let print = ;  /* print option */
    %let keys = datain print;
    %getkeys;
    %if (%bquote(&datain) eq ) %then %let msg = No Datain file.;
    %if (%length(&print) ge 2) %then %if (%upcase(%qsubstr(&print, 1, 2)) eq NO) %then %let print = none;
  %end;

  %if (%bquote(&msg) eq ) %then %do;  /* get input variables from first input dataset */
    %let metain = %scan(%bquote(&datain), 1, ' ');
    %metadata(datain=&metain);
    %let datain = ;
  %end;

  /* set parameter defaults */
  %let nmults = ;  /* number of multiples */
  %if (%bquote(&msg) eq ) %then %do;
    %let setfile = ;  /* setup file */
    %let modfile = ;  /* module include file */
    %let lstfile = ;  /* list file */
    %let estout = ;  /* output estimates file */
    %let by = ;  /* string of by variables */
    %let nbys = ;  /* number of bys */
    %let stratum = ;  /* stratum variable */
    %let cluster = ;  /* cluster variable */
    %let weight = ;  /* weight variable */
    %let title = ;  /* run title */
    %let procid = ;  /* SAS procedure identifier */
    %let model = ;  /* model identifier */
    %setmod;  /* parse setup */
  %end;

  %if (%bquote(&msg) eq ) %then %do;  /* delete any files from previous runs */
    %if (%sysfunc(filename(delref, &path..mlt)) eq 0) %then %do;  /* delete .mlt file */
      %if (%sysfunc(fexist(&delref))) %then
        %let rc = %sysfunc(fdelete(&delref));
      %let rc = %sysfunc(filename(delref));
    %end;
    %if (%sysfunc(filename(delref, &path..rep)) eq 0) %then %do;  /* delete .rep file */
      %if (%sysfunc(fexist(&delref))) %then
        %let rc = %sysfunc(fdelete(&delref));
      %let rc = %sysfunc(filename(delref));
    %end;
    %if (%sysfunc(exist(like1)) or %sysfunc(exist(covparms)) or %sysfunc(exist(lsmeans))) %then %do;
      proc datasets nolist;  /* delete like1, etc. */
        %if (%sysfunc(exist(like1))) %then %do;
          delete like1;
        %end;
        %if (%sysfunc(exist(covparms))) %then %do;
          delete covparms;
        %end;
        %else %if (%sysfunc(exist(lsmeans))) %then %do;
          delete lsmeans;
        %end;
      run;
    %end;
  %end;

  %if (%bquote(&msg) eq ) %then %do;  /* set by variable types */
    %let msg = %str(Can%'t) access data file;
    %let dataset = %scan(%bquote(&datain), 1, ' ');  /* open first input dataset */
    %let datfile = %sysfunc(open(&dataset, i));
    %if (&datfile ne 0) %then %do;
      %let nvars = %sysfunc(attrn(&datfile, NVARS));
      %if (&by ne ) %then %do;
        %let posn = 0;  /* by(s) */
        %do %until(&byvar eq );
          %let posn = %eval(&posn + 1);
          %let byvar = %scan(%bquote(&by), &posn, ' ');
          %if (&byvar ne ) %then %do;
            %let varnum = %sysfunc(varnum(&datfile, &byvar));
            %let t_by&posn = %sysfunc(vartype(&datfile, &varnum));
          %end;
        %end;
      %end;
      %let rc = %sysfunc(close(&datfile));  /* close dataset */
      %let msg = ;
    %end;
  %end;

  %if (%bquote(&msg) eq ) %then %do;
    %let addstrat = ;  /* set dummy stratum and cluster variables names */
    %let addclust = ;
    %if (&stratum ne or &cluster ne or &weight ne ) %then %do;
      %if (&stratum eq ) %then %do;
        %let stratum = _ONE_;
        %let addstrat = Y;
      %end;
      %if (&cluster eq ) %then %do;
        %let cluster = _OBS_;
        %let addclust = Y;
      %end;
    %end;
    %let outfile = &path..rep;  /* set output file name */
  %end;

  %let mult = 0;  /* loop through multiples */
  %do %while(%bquote(&msg) eq and &mult lt &nmults);
    %let mult = %eval(&mult + 1);
    %if (&nmults gt 1) %then %put Multiple &mult;

    %let msg = %str(Can%'t) access data file;  /* open input dataset */
    %let dataset = %scan(%bquote(&datain), &mult, ' ');
    %let datfile = %sysfunc(open(&dataset, i));
    %if (&datfile ne 0) %then %do;
      %let nvars = %sysfunc(attrn(&datfile, NVARS));
      data data1;
        set &dataset end = _LAST_;
        array mdf(&nvars) $32;
        retain _MOBS_ _NOBS_ 0 mdf1 - mdf&nvars;
      %if (&by eq ) %then %do;
        %if (&addstrat eq Y) %then %do;
          retain _ONE_ 1;
        %end;
        retain _SUMWGT_ 0;
      %end;
      %if (&procid eq LIFEREG) %then %do;
        retain _WARN_ 0;
      %end;

      _KEEP_ = 1;  /* check missing data */
      %do posn = 1 %to &nvars;
        %let vname = %trim(%sysfunc(varname(&datfile, &posn)));
        %if (%sysfunc(vartype(&datfile, &posn)) eq C) %then %do;  /* character */
          if (trimn(&vname) eq '') then do;
             call vname(&vname, mdf(&posn));
            _KEEP_ = 0;
          end;
        %end;
        %else %do;  /* numeric */
          if (&vname le .Z) then do;
            %if (&procid eq LIFEREG) %then %do;
              if (&vname eq .M) then _WARN_ = 1;
              else do;
            %end;
              call vname(&vname, mdf(&posn));
              _KEEP_ = 0;
            %if (&procid eq LIFEREG) %then %do;
              end;
            %end;
          end;
        %end;
      %end;

      %if (&weight ne ) %then %do;  /* check weight */
        if (&weight le 0) then do;
          %let posn = %sysfunc(varnum(&datfile, &weight));
          call vname(&weight, mdf(&posn));
          _KEEP_ = 0;
        end;
      %end;

      if (_KEEP_ eq 0) then _MOBS_ = _MOBS_ + 1;  /* skip observation with missing data */

      else do;  /* process observation with no missing data */
        _NOBS_ = _NOBS_ + 1;  /* number of observations */
        drop _NOBS_;
        %if (&weight eq ) %then %do;  /* weight */
          _WEIGHT_ = 1;
          %if (&procid eq PHREG and &stratum ne ) %then _OFFSET_ = 0%str(;);
        %end;
        %else %do;
          _WEIGHT_ = &weight;
          %if (&procid eq PHREG) %then _OFFSET_ = log(_WEIGHT_)%str(;);
        %end;
        %if (&by eq ) %then %do;  /* no by(s) */
          %if (&addclust eq Y) %then %do;  /* add cluster */
            _OBS_ = _NOBS_;
          %end;
          _SUMWGT_ = _SUMWGT_ + _WEIGHT_;  /* sum of weights */
          drop _SUMWGT_;
        %end;
        drop _MOBS_ _KEEP_ mdf1 - mdf&nvars _i_;  /* write data */
        %if (&procid eq LIFEREG) %then %do;
          drop _WARN_;
        %end;
        output;
      end;

      if (_LAST_) then do;
        if (_MOBS_ gt 0) then do;  /* report number of observations excluded for missing data */
          put @3 _MOBS_ "observations excluded for missing data on variables:";
          do _i_ = 1 to &nvars;
            if (mdf(_i_) ne '') then put @5 mdf(_i_);
          end;
          put;
          %if (&procid eq LIFEREG) %then %do;
            if (_WARN_ eq 1) then do;
              put "  Lifereg has accepted .M missing-data values as a possible censoring indicator.";
              put "    Please check to see that you have no other .M missing data.";
              put;
            end;
          %end;
        end;
        %if (&by eq ) %then %do;  /* no by(s) */
          file "&outfile" recfm=n mod;  /* write estimates preamble */
          _MULT_ = &mult;  /* multiple */
          put _MULT_ rb&ldouble..;
          drop _MULT_;
          %if (&stratum ne ) %then %do;  /* stratum and cluster */
            _ZERO_ = 0;
            put (_ZERO_ _ZERO_) (rb&ldouble..);
            drop _ZERO_;
          %end;
          put (_NOBS_ _SUMWGT_) (rb&ldouble..);  /* number of observations, sum of weights */
          %if (&stratum eq ) %then %do;
            put _NOBS_ rb&ldouble..;  /* unadjusted degrees of freedom */
          %end;
        %end;
      end;
      run;
      %let rc = %sysfunc(close(&datfile));
      %let msg = ;
    %end;

    %if (%bquote(&msg) eq ) %then %do;  /* check number of cases */
      %let msg = %str(Can%'t) open data file;
      %let datfile = %sysfunc(open(data1, i));
      %if (&datfile ne 0) %then %do;
        %let nobs = %sysfunc(attrn(&datfile, NOBS));
        %let rc = %sysfunc(close(&datfile));
        %if (&nobs gt 0) %then %let msg = ;
      %end;
    %end;

    %if (%bquote(&msg) eq ) %then %do;

      %if (&by eq ) %then %do;  /* no bys */

        %if (&stratum eq ) %then %do;  /* no strata/clusters */
          %runmod;  /* run SAS module */
        %end;

        %else %do;  /* strata/clusters */
          %if (&addstrat eq Y or &addclust eq Y) %then %do;
            %if (&addstrat eq Y and &addclust eq Y ) %then %do;  /* no sort */
              data data2;  /* copy dataset to data2 */
                set data1;
              run;
            %end;
            %else %if (&addclust eq Y) %then %do;  /* sort data on stratum */
              proc sort data=data1 out=data2;
                by &stratum;
              run;
            %end;
            %else %do;  /* sort data on cluster */
              proc sort data=data1 out=data2;
                by &cluster;
              run;
            %end;
          %end;
          %else %do;  /* sort data on stratum, cluster */
            proc sort data=data1 out=data2;
              by &stratum &cluster;
            run;
          %end;
          %if (&syserr ne 0)  %then %let msg = Error in SAS sort. Please check log;
          %else %repmod;  /* process replicates */
        %end;
      %end;

      %else %do;  /* bys */
        %if (&stratum eq ) %then %do;  /* sort data on by(s) */
          proc sort data=data1;
            by &by;
          run;
        %end;
        %else %do;
          %if (&addstrat eq Y or &addclust eq Y) %then %do;
            %if (&addstrat eq Y and &addclust eq Y ) %then %do;  /* sort data on by(s) */
              proc sort data=data1;
                by &by;
              run;
            %end;
            %else %if (&addclust eq Y) %then %do;  /* sort data on by(s), stratum */
              proc sort data=data1;
                by &by &stratum;
              run;
            %end;
            %else %do;  /* sort data on by(s), cluster */
              proc sort data=data1;
                by &by &cluster;
              run;
            %end;
          %end;
          %else %do;  /* sort data on by(s), stratum, cluster */
            proc sort data=data1;
              by &by &stratum &cluster;
            run;
          %end;
        %end;
        run;
        %if (&syserr ne 0)  %then %let msg = Error in SAS sort. Please check log;

        %let firstobs = 1;  /* bys loop */
        %let bylevel = 0;
        %do %while(%bquote(&msg) eq and &firstobs le &nobs);
          %let bylevel = %eval(&bylevel + 1);
          %put By level &bylevel;

          data data2;  /* read data for this by level */
            %if (&addstrat eq Y) %then %do;
              retain _ONE_ 1;
            %end;
            retain _NOBS_ _SUMWGT_ 0;
            set data1(firstobs=&firstobs);
            by &by;
            _NOBS_ = _NOBS_ + 1;  /* acccumulate number of observations, sum of weights */
            %if (&addclust eq Y) %then %do;
              _OBS_ = _NOBS_;
            %end;
            _SUMWGT_ = _SUMWGT_ + _WEIGHT_;
            drop _NOBS_ _SUMWGT_;
            output;  /* write observation */
            if (last.%scan(%bquote(&by), &nbys, ' ')) then do;  /* last observation for this by level */
              call symput('bnobs', trim(left(put(_NOBS_, 12.))));
              file "&outfile" recfm=n mod;  /* write estimates preamble */
              _MULT_ = &mult;  /* multiple */
              put _MULT_ rb&ldouble..;
              drop _MULT_;
              %let posn = 0;  /* by(s) */
              %do %until(&byvar eq );
                %let posn = %eval(&posn + 1);
                %let byvar = %scan(%bquote(&by), &posn, ' ');
                %if (&byvar ne ) %then %do;
                  %let t_by = t_by&posn;
                  %if (&&&t_by eq N) %then %do;  /* numeric */
                    put &byvar rb&ldouble..;
                  %end;
                  %else %do;
                    put &byvar $&ldouble..;  /* character */
                  %end;
                %end;
              %end;
              %if (&stratum ne ) %then %do;  /* stratum and cluster */
                _ZERO_ = 0;
                put (_ZERO_ _ZERO_) (rb&ldouble..);
                drop _ZERO_;
              %end;
              put (_NOBS_ _SUMWGT_) (rb&ldouble..);  /* number of observations, sum of weights */
              %if (&stratum eq ) %then %do;
                put _NOBS_ rb&ldouble..;  /* unadjusted degrees of freedom */
              %end;
              stop;
            end;
          run;
          %let firstobs = %eval(&firstobs + &bnobs);

          %if (&stratum eq ) %then %do;  /* run SAS module */
            %runmod;
          %end;
          %else %do;  /* process replicates */
            %repmod;
          %end;

        %end;  /* end bys loop */
      %end;  /* end bys if */

    %end;  /* end no message if */
  %end;  /* end multiples loop */

  %if (%bquote(&msg) eq ) %then %do;  /* execute multreg */
    %put Combine Regressions.;
    %execute(prog=multreg);

    %if (%bquote(&msg) eq ) %then %do;
      %if (%sysfunc(filename(outref, &path..out)) eq 0) %then %do;  /* write estimates dataset */
        %let file = %sysfunc(fopen(&outref));
        %if (&file ne 0) %then %do;
          %let rc = %sysfunc(fclose(&file));
          %put Output results.;
          filename output "&path..out";
          %include output;
          %if (%upcase(&mode) ne DEBUG) %then %do;
            %if (%sysfunc(filename(delref, &path..est)) eq 0) %then %do;  /* delete estimates work files */
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
      %if (%upcase(&mode) ne DEBUG) %then %do;
        %if (%sysfunc(filename(delref, &path..mod)) eq 0) %then %do;  /* delete module work file */
          %let rc = %sysfunc(fdelete(&delref));
          %let rc = %sysfunc(filename(delref));
        %end;
      %end;
      %copylst;  /* copy list to SAS output window */
    %end;

    %copylog;  /* copy log to SAS log window */
  %end;

  %if (%bquote(&msg) ne ) %then %put %bquote(&msg);  /* write error message to SAS log window */

%mend sasmod;
