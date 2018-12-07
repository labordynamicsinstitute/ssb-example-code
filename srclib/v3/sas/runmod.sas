
/* Runmod - IVEware sasmod module invocation macro */

%macro runmod;

  %if (%bquote(&msg) eq ) %then %do;

    filename modfile "&path..mod";  /* SAS procedure file */
    %include modfile;  /* process SAS procedure file */
    quit;

    %if (&syserr ne 0 and &syserr ne 4) %then
      %let msg = Error in SAS module run. Please check log;

    %else %do;  /* write parameter names, log-likelihood, parameter estimates,
                   end covariances (if needed) */

      %if (&procid eq CALIS) %then %do;  /* proc calis */
        data _null_;
          set est1 end=_end_;
          array x(*) _numeric_;
          length _vname_ $ 32;
          file "&outfile" mod recfm=n; 
          if (_n_ eq 1) then do;  /* write loglikelihood */
            _like_ = 0;
            put _like_ rb&ldouble..;
          end;
          if (_ITER_ eq .) then do;
            if (_TYPE_ eq 'PARMS') then do;  /* write parameter estimates */
              _coefs_ = 0;
              do _i_ = 1 to dim(x);
                call vname(x(_i_), _vname_);
                if (_vname_ not in('_ITER_', '_RHS_')) then _coefs_ = _coefs_ + 1;
              end;
              put _coefs_ ib&lint..;
              do _i_ = 1 to dim(x);
                call vname(x(_i_), _vname_);
                if (_vname_ not in('_ITER_', '_RHS_')) then put _vname_ $32. x(_i_) rb&ldouble..;
              end;
            end;
            %if (&stratum eq ) %then %do;
              else if (_TYPE_ eq 'COV') then do _i_ = 1 to dim(x);  /* write covariances */
                call vname(x(_i_), _vname_);
                if (_vname_ not in('_ITER_', '_RHS_')) then put x(_i_) rb&ldouble..;
              end;
            %end;
          end;
          if (_end_) then do;  /* write no auxiliary parameters */
            _xparms_ = 0;
            put _xparms_ ib&lint..;
          end;
        run;
        %if (&syserr ne 0) %then %let msg = Estimates file error;
      %end;

      %else %if (&procid eq CATMOD) %then %do;  /* proc catmod */

        %if (%sysfunc(exist(like1))) %then %do;  /* write loglikelihood */
          data _null_;
            set like1 end = _last_;
            if (_last_) then do;
              file "&outfile" mod recfm=n;
              LogLikelihood = LogLikelihood / -2;
              put LogLikelihood rb&ldouble..;
            end;
          run;
        %end;
        %else %do;
          data _null_;  /* no likelihood */
            file "&outfile" mod recfm=n;
            LogLikelihood = 0;
            put LogLikelihood rb&ldouble..;
          run;
        %end;
        %if (&syserr ne 0) %then %let msg = Log likelihood file error;

        %if (%bquote(&msg) eq ) %then %do;  /* write parameter estimates */
          data _null_;
            length pname $ 200;
            estfile = open("est1", "i");
            if (estfile eq 0) then do;
              call symput("msg", "Parameters file error");
              stop;
            end;
            nobs = attrn(estfile, "nobs");
            fvar = varnum(estfile, "Parameter");
            lvar = fvar;
            if (varnum(estfile, "FunctionNumber") gt lvar) then lvar = varnum(estfile, "FunctionNumber");
            if (varnum(estfile, "ClassValue") gt lvar) then lvar = varnum(estfile, "ClassValue");
            evar = varnum(estfile, "Estimate");
            if (nobs eq 0 or fvar eq 0 or lvar lt fvar or evar eq 0) then do;
              call symput("msg", "Parameters file error");
              stop;
            end;
            file "&outfile" mod recfm=n;
            put nobs ib&lint..;
            do while (fetch(estfile) eq 0);
              pname = "";
              do var = fvar to lvar;
                pname = trim(pname) || " " || left(getvarc(estfile, var));
              end;
              pname = trim(left(pname));
              est = getvarn(estfile, evar);
              if (est le .Z) then est = 0;
              put pname $32. est rb&ldouble..;
            end;
          run;
        %end;

        %if (%bquote(&msg) eq and &stratum eq ) %then %do;  /* write covariances */
          data _null_;
            set covb1;
            array x(*) _numeric_;
            file "&outfile" mod recfm=n;
            _keep_ = 0;
            do _i_ = 1 to dim(x);
              if (vname(x(_i_)) eq 'Col1') then _keep_ = 1;
              if (_keep_ eq 1) then do;
                if (x(_i_) le .Z) then x(_i_) = 0;
                put x(_i_) rb&ldouble..;
              end;
            end;
          run;
          %if (&syserr ne 0) %then %let msg = Covariances file error;
        %end;

        %if (%bquote(&msg) eq ) %then %do;  /* write no more auxiliary parameters */
          data _null_;
            file "&outfile" mod recfm=n;
            _xparms_ = 0;
            put _xparms_ ib&lint..;
          run;
        %end;
      %end;

      %else %if (&procid eq GENMOD) %then %do;  /* proc genmod */

        %if (%sysfunc(exist(like1))) %then %do;  /* write loglikelihood */
          data _null_;
            set like1 end = _last_;
            retain _like_ 0;
            if (index(upcase(Criterion), 'LOG') > 0) then _like_ = Value;
            if (_last_) then do;
              file "&outfile" mod recfm=n;
              put _like_ rb&ldouble..;
            end;
          run;
        %end;
        %else %do;
          data _null_;  /* no likelihood */
            file "&outfile" mod recfm=n;
            _like_ = 0;
            put _like_ rb&ldouble..;
          run;
        %end;
        %if (&syserr ne 0) %then %let msg = Log likelihood file error;

        %if (%bquote(&msg) eq ) %then %do;  /* write parameter estimates */
          data _null_;
            length pname $ 200;
            estfile = open("est1", "i");
            if (estfile eq 0) then do;
              call symput("msg", "Parameters file error");
              stop;
            end;
            nobs = attrn(estfile, "nobs");
            dvar = varnum(estfile, "DF");
            evar = varnum(estfile, "Estimate");
            fvar = varnum(estfile, "Parameter");
            if (fvar eq 0) then do;
              fvar = varnum(estfile, "Parm");
              lvar = evar - 1;
              df = 1;
            end;
            else lvar = dvar - 1;
            if (nobs eq 0 or fvar eq 0 or lvar lt fvar or evar eq 0) then do;
              call symput("msg", "Parameters file error");
              stop;
            end;
            count = 0;
            do while (fetch(estfile) eq 0);
              if (dvar gt 0) then df = getvarn(estfile, dvar);
              if (df gt 0) then count = count + 1;
            end;
            rc = rewind(estfile);
            file "&outfile" mod recfm=n;
            put count ib&lint..;
            do while (fetch(estfile) eq 0);
              if (dvar gt 0) then df = getvarn(estfile, dvar);
              if (df gt 0) then do;
                pname = "";
                do var = fvar to lvar;
                  if (vartype(estfile, var) eq 'C') then pname = trim(pname) || " " || left(getvarc(estfile, var));
                  else pname = trim(pname) || " " || left(getvarn(estfile, var));
                end;
                pname = trim(left(pname));
                est = getvarn(estfile, evar);
                put pname $32. est rb&ldouble..;
              end;
            end;
          run;
        %end;

        %if (%bquote(&msg) eq and &stratum eq ) %then %do;  /* write covariances */
          data _null_;
            set covb1;
            array x(*) _numeric_;
            file "&outfile" mod recfm=n;
            put (x(*)) (rb&ldouble..);
          run;
          %if (&syserr ne 0) %then %let msg = Covariances file error;
        %end;

        %if (%bquote(&msg) eq ) %then %do;
          %if( %sysfunc(exist(lsmeans))) %then %do;  /* write least square means estimates */
            data _null_;
              length pname $ 200;
              estfile = open("lsmeans", "i");
              if (estfile eq 0) then do;
                call symput("msg", "LSMeans file error");
                stop;
              end;
              nobs = attrn(estfile, "nobs");
              fvar = varnum(estfile, "Effect");
              evar = varnum(estfile, "Estimate");
              lvar = evar - 1;
              if (nobs eq 0 or fvar eq 0 or lvar lt fvar or evar eq 0) then do;
                call symput("msg", "LSMeans file error");
                stop;
              end;
              file "&outfile" mod recfm=n;
              put nobs ib&lint..;
              do while (fetch(estfile) eq 0);
                pname = "";
                do var = fvar to lvar;
                  if (vartype(estfile, var) eq 'C') then pname = trim(pname) || " " || left(getvarc(estfile, var));
                  else pname = trim(pname) || " " || left(getvarn(estfile, var));
                end;
                pname = trim(left(pname));
                est = getvarn(estfile, evar);
                put pname $32. est rb&ldouble..;
              end;
            run;
            %if (&syserr ne 0) %then %let msg = LSMeans file error;
          %end;

          %else %do;  /* write no auxiliary parameters */
            data _null_;
              file "&outfile" mod recfm=n;
              _xparms_ = 0;
              put _xparms_ ib&lint..;
            run;
          %end;
        %end;
      %end;

      %else %if (&procid eq LIFEREG) %then %do;  /* proc lifereg */
        data _null_;
          set est1 end=_end_;
          array x(*) _numeric_;
          length _vname_ $ 32;
          file "&outfile" mod recfm=n;
          if (_n_ eq 1) then put _LNLIKE_ rb&ldouble..;  /* write loglikelihood */
          if (_TYPE_ eq 'PARMS') then do;  /* write parameter estimates */
            _coefs_ = 0;
            _keep_ = 0;
            do _i_ = 1 to dim(x);
              call vname(x(_i_), _vname_);
              %if (&sysver eq 6.12) %then %do;
                if (_vname_ eq 'INTERCEP') then _vname_ = 'Intercept';
              %end;
              if (_vname_ not in('_LNLIKE_', '_SHAPE1_')) then do;
                if (_vname_ eq 'Intercept' or _keep_) then _coefs_ = _coefs_ + 1;
                else _keep_ = 1;
              end;
            end;
            put _coefs_ ib&lint..;
            _keep_ = 0;
            do _i_ = 1 to dim(x);
              call vname(x(_i_), _vname_);
              %if (&sysver eq 6.12) %then %do;
                if (_vname_ eq 'INTERCEP') then _vname_ = 'Intercept';
              %end;
              if (_vname_ not in('_LNLIKE_', '_SHAPE1_')) then do;
                if (_vname_ eq 'Intercept' or _keep_) then put _vname_ $32. x(_i_) rb&ldouble..;
                else _keep_ = 1;
              end;
            end;
          end;
          %if (&stratum eq ) %then %do;  /* write covariances */
            else if (_TYPE_ eq 'COV') then do;
              _keep_ = 0;
              do _i_ = 1 to dim(x);
                call vname(x(_i_), _vname_);
                %if (&sysver eq 6.12) %then %do;
                  if (_vname_ eq 'INTERCEP') then _vname_ = 'Intercept';
                %end;
                if (_vname_ not in('_LNLIKE_', '_SHAPE1_')) then do;
                  if (_vname_ eq 'Intercept' or _keep_) then put x(_i_) rb&ldouble..;
                  else _keep_ = 1;
                end;
              end;
            end;
          %end;
          if (_end_) then do;  /* write no auxiliary parameters */
            _xparms_ = 0;
            put _xparms_ ib&lint..;
          end;
        run;
        %if (&syserr ne 0) %then %let msg = Estimates file error;
      %end;

      %else %if (&procid eq MIXED) %then %do;  /* proc mixed */

        data _null_;  /* write loglikelihood */
          set like1;
          if (index(upcase(Descr), 'LOG') > 0) then do;
            file "&outfile" mod recfm=n;
            Value = Value / -2;
            put Value rb&ldouble..;
          end;
        run;
        %if (&syserr ne 0) %then %let msg = Log likelihood file error;

        %if (%bquote(&msg) eq ) %then %do;  /* write parameter estimates */
          data _null_;
            length pname $ 200;
            estfile = open("est1", "i");
            if (estfile eq 0) then do;
              call symput("msg", "Parameters file error");
              stop;
            end;
            nobs = attrn(estfile, "nobs");
            fvar = varnum(estfile, "Effect");
            evar = varnum(estfile, "Estimate");
            lvar = evar - 1;
            if (nobs eq 0 or fvar eq 0 or lvar lt fvar or evar eq 0) then do;
              call symput("msg", "Parameters file error");
              stop;
            end;
            file "&outfile" mod recfm=n;
            put nobs ib&lint..;
            do while (fetch(estfile) eq 0);
              pname = "";
              do var = fvar to lvar;
                if (vartype(estfile, var) eq 'C') then pname = trim(pname) || " " || left(getvarc(estfile, var));
                else pname = trim(pname) || " " || left(getvarn(estfile, var));
              end;
              pname = trim(left(pname));
              if (substr(pname, 1, 9) eq "Intercept") then pname = "Intercept";
              est = getvarn(estfile, evar);
              put pname $32. est rb&ldouble..;
            end;
          run;
        %end;

        %if (%bquote(&msg) eq and &stratum eq ) %then %do;  /* write covariances */
          data _null_;
            set covb1;
            array x(*) _numeric_;
            file "&outfile" mod recfm=n;
            _keep_ = 0;
            do _i_ = 1 to dim(x);
              if (vname(x(_i_)) eq 'Col1') then _keep_ = 1;
              if (_keep_) then put x(_i_) rb&ldouble..;
            end;
          run;
          %if (&syserr ne 0) %then %let msg = Covariances file error;
        %end;

        %if (%bquote(&msg) eq ) %then %do;
          %if (%sysfunc(exist(covparms))) %then %do;  /* write covariance parameter estimates */
            data _null_;
              length pname $ 200;
              estfile = open("covparms", "i");
              if (estfile eq 0) then do;
                call symput("msg", "Covariance parameters file error");
                stop;
              end;
              nobs = attrn(estfile, "nobs");
              pvar = varnum(estfile, "CovParm");
              evar = varnum(estfile, "Estimate");
              if (nobs eq 0 or pvar eq 0 or evar eq 0) then do;
                call symput("msg", "Estimates file error");
                stop;
              end;
              file "&outfile" mod recfm=n;
              put nobs ib&lint..;
              do while (fetch(estfile) eq 0);
                pname = getvarc(estfile, pvar);
                pname = trim(left(pname));
                est = getvarn(estfile, evar);
                put pname $32. est rb&ldouble..;
              end;
            run;
            %if (&syserr ne 0) %then %let msg = Covariance parameters file error;
          %end;

          %else %do;  /* write no more auxiliary parameters */
            data _null_;
              file "&outfile" mod recfm=n;
              _xparms_ = 0;
              put _xparms_ ib&lint..;
            run;
          %end;
        %end;
      %end;

      %else %if (&procid eq NLIN) %then %do;  /* proc nlin */
        data _null_;
          set est1 end=_end_;
          array x(*) _numeric_;
          length _vname_ $ 32;
          file "&outfile" mod recfm=n;
          if (_n_ eq 1) then do;  /* write loglikelihood */
            _like_ = 0;
            put _like_ rb&ldouble..;
          end;
          if (_TYPE_ eq 'FINAL') then do;  /* write parameter estimates */
            _coefs_ = 0;
            do _i_ = 1 to dim(x);
              call vname(x(_i_), _vname_);
              if (_vname_ not in('_ITER_', '_SSE_')) then _coefs_ = _coefs_ + 1;
            end;
            put _coefs_ ib&lint..;
            do _i_ = 1 to dim(x);
              call vname(x(_i_), _vname_);
              if (_vname_ not in('_ITER_', '_SSE_')) then put _vname_ $32. x(_i_) rb&ldouble..;
            end;
          end;
          %if (&cluster eq ) %then %do;  /* write covariances */
            if (_TYPE_ eq 'COVB') then do _i_ = 1 to dim(x);
              call vname(x(_i_), _vname_);
              if (_vname_ not in('_ITER_', '_SSE_')) then put x(_i_) rb&ldouble..;
            end;
          %end;
          if (_end_) then do;  /* write no auxiliary parameters */
            _xparms_ = 0;
            put _xparms_ ib&lint..;
          end;
        run;
        %if (&syserr ne 0) %then %let msg = Estimates file error;
      %end;

      %else %if (&procid eq PHREG) %then %do;  /* proc phreg */

        data _null_;  /* write loglikelihood */
          set like1;
          where (index(upcase(Criterion), 'LOG') > 0);
          file "&outfile" mod recfm=n;
          WithCovariates = WithCovariates / -2;
          put WithCovariates rb&ldouble..;
        run;
        %if (&syserr ne 0) %then %let msg = Log likelihood file error;

        %if (%bquote(&msg) eq ) %then %do;  /* write number of parameters */
          data _null_;
            estfile = open("est1", "i");
            if (estfile eq 0) then do;
              call symput("msg", "Parameters file error");
              stop;
            end;
            nobs = attrn(estfile, "nobs");
            if (nobs eq 0) then do;
              call symput("msg", "Parameters file error");
              stop;
            end;
            file "&outfile" mod recfm=n;
            put nobs ib&lint..;
          run;
        %end;

        %if (%bquote(&msg) eq ) %then %do;  /* write parameter estimates */
          data _null_;
            set est1;
            file "&outfile" mod recfm=n;
            %if (&sysver ge 7 and &sysver lt 9.2) %then %do;
              put Variable $32. Estimate rb&ldouble..;
            %end;
            %else %do;
              put Parameter $32. Estimate rb&ldouble..;
            %end;
          run;
        %end;

        %if (%bquote(&msg) eq and &cluster eq ) %then %do;  /* write covariances */
          data _null_;
            set covb1;
            array x(*) _numeric_;
            file "&outfile" mod recfm=n;
            put (x(*)) (rb&ldouble..);
          run;
        %end;

        %if (%bquote(&msg) eq ) %then %do;  /* write no auxiliary parameters */
          data _null_;
            file "&outfile" mod recfm=n;
            _xparms_ = 0;
            put _xparms_ ib&lint..;
          run;
        %end;
      %end;

      %else %if (&procid eq PROBIT) %then %do;  /* proc probit */
        data _null_;
          set est1 end=_end_;
          array x(*) _numeric_;
          length _vname_ $ 32;
          file "&outfile" mod recfm=n;
          if (_n_ eq 1) then do;  /* write loglikelihood */
            put _LNLIKE_ rb&ldouble..;
          end;
          if (_TYPE_ eq 'PARMS') then do;  /* write parameter estimates */
            _coefs_ = 0;
            _keep_ = 0;
            do _i_ = 1 to dim(x);
              call vname(x(_i_), _vname_);
              %if (&sysver eq 6.12) %then %do;
                if (_vname_ eq 'INTERCEP') then _vname_ = 'Intercept';
              %end;
              if (_vname_ not in('_LNLIKE_', '_C_')) then do;
                if (_vname_ eq 'Intercept' or _keep_) then _coefs_ = _coefs_ + 1;
                else _keep_ = 1;
              end;
            end;
            put _coefs_ ib&lint..;
            _keep_ = 0;
            do _i_ = 1 to dim(x);
              call vname(x(_i_), _vname_);
              %if (&sysver eq 6.12) %then %do;
                if (_vname_ eq 'INTERCEP') then _vname_ = 'Intercept';
              %end;
              if (_vname_ not in('_LNLIKE_', '_C_')) then do;
                if (_vname_ eq 'Intercept' or _keep_) then put _vname_ $32. x(_i_) rb&ldouble..;
                else _keep_ = 1;
              end;
            end;
          end;
          %if (&cluster eq ) %then %do;  /* write covariances */
            if (_TYPE_ eq 'COV') then do;
              _keep_ = 0;
              do _i_ = 1 to dim(x);
                call vname(x(_i_), _vname_);
                %if (&sysver eq 6.12) %then %do;
                  if (_vname_ eq 'INTERCEP') then _vname_ = 'Intercept';
                %end;
                if (_vname_ not in('_LNLIKE_', '_C_')) then do;
                  if (_vname_ eq 'Intercept' or _keep_) then put x(_i_) rb&ldouble..;
                  else _keep_ = 1;
                end;
              end;
            end;
          %end;
          if (_end_) then do;  /* write no auxiliary parameters */
            _xparms_ = 0;
            put _xparms_ ib&lint..;
          end;
        run;
      %end;

      %else %if (&procid eq ROBUSTREG) %then %do;  /* proc robustreg */

        data _null_;  /* write loglikelihood and number of parameters */
          file "&outfile" mod recfm=n;
          LogLikelihood = 0;
          put LogLikelihood rb&ldouble..;
          estfile = open("est1", "i");
          if (estfile eq 0) then do;
            call symput("msg", "Parameters file error");
            stop;
          end;
          dvar = varnum(estfile, "Parameter");
          count = 0;
          do while (fetch(estfile) eq 0);
            if (getvarc(estfile, dvar) ne "Scale") then count = count + 1;
          end;
          file "&outfile" mod recfm=n;
          put count ib&lint..;
        run;

        %if (%bquote(&msg) eq ) %then %do;  /* write parameter estimates */
          data _null_;
            set est1;
            file "&outfile" mod recfm=n;
            if (Parameter ne "Scale") then put Parameter $32. Estimate rb&ldouble..;
          run;
        %end;

        %if (%bquote(&msg) eq and &cluster eq ) %then %do;  /* write covariances */
          data _null_;
            set covb1;
            array x(*) _numeric_;
            file "&outfile" mod recfm=n;
            put (x(*)) (rb&ldouble..);
          run;
        %end;

        %if (%bquote(&msg) eq ) %then %do;  /* write no auxiliary parameters */
          data _null_;
            file "&outfile" mod recfm=n;
            _xparms_ = 0;
            put _xparms_ ib&lint..;
          run;
        %end;
      %end;

      %else %if (&procid eq SYSLIN) %then %do;  /* proc syslin */

        data _null_;  /* write loglikelihood and number of parameters */
          file "&outfile" mod recfm=n;
          LogLikelihood = 0;
          put LogLikelihood rb&ldouble..;
          estfile = open("est1", "i");
          if (estfile eq 0) then do;
            call symput("msg", "Parameters file error");
            stop;
          end;
          nobs = attrn(estfile, "nobs");
          if (nobs eq 0) then do;
            call symput("msg", "Parameters file error");
            stop;
          end;
          file "&outfile" mod recfm=n;
          put nobs ib&lint..;
        run;

        %if (%bquote(&msg) eq ) %then %do;  /* write parameter estimates */
          data _null_;
            set est1;
            file "&outfile" mod recfm=n;
            put Variable $32. Estimate rb&ldouble..;
          run;
        %end;

        %if (%bquote(&msg) eq and &cluster eq ) %then %do;  /* write covariances */
          data _null_;
            set covb1;
            array x(*) _numeric_;
            file "&outfile" mod recfm=n;
            put (x(*)) (rb&ldouble..);
          run;
        %end;

        %if (%bquote(&msg) eq ) %then %do;  /* write no auxiliary parameters */
          data _null_;
            file "&outfile" mod recfm=n;
            _xparms_ = 0;
            put _xparms_ ib&lint..;
          run;
        %end;
      %end;

    %end;  /* end procedure error if */
  %end;  /* end previous error if */

%mend runmod;
