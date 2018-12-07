
/* Repmod - IVEware sasmod replicate macro */

%macro repmod;

  %if (%bquote(&msg) eq ) %then %do;  /* run SAS module for total sample */
    %put Full sample;
    %runmod; 
  %end;

  %if (%bquote(&msg) eq ) %then %do;  /* count strata and clusters */
    data clust1 (keep = nclusts);
      set data2 end = _LAST_;
      by &stratum &cluster;
      retain nstrata nclusts 0;
      if (first.&cluster) then nclusts = nclusts + 1;
      if (last.&stratum) then do;
        nstrata = nstrata + 1;
        if (nclusts lt 2) then do;
          msg = "Fewer than two clusters for stratum " || trim(left(put(nstrata, &ldouble..)));
          call symput('msg', msg);
          stop;
        end;
        output;
        nclusts = 0;
      end;
      if (_LAST_) then call symput('nstrata', trim(left(put(nstrata, &ldouble..))));
    run;
  %end;

  %if (%bquote(&msg) eq ) %then %do;  /* open clusters file */
    %let clsfile = %sysfunc(open(clust1, i));
    %if (&clsfile eq 0) %then %let msg = %str(Can%'t) open clusters file;
  %end;

  %if (%bquote(&msg) eq ) %then %do;  /* run SAS module for replicates */
    %let strat = 0;
    %let replicat = 0;
    %do %while(%bquote(&msg) eq and %sysfunc(fetch(&clsfile)) eq 0);  /* strata loop */
      %let strat = %eval(&strat + 1);
      %let nclusts = %sysfunc(getvarn(&clsfile, 1));

      %let clust = 0;
      %do %while(%bquote(&msg) eq and &clust lt &nclusts);  /* clusters loop */
        %let clust = %eval(&clust + 1);

        /* read data */
        data data3 (drop = _MULT_ _STRAT_ _CLUST_ _ADJUST_ _NOBS_ _SUMWGT_);
          set data2 end = _LAST_ ;
          by &stratum &cluster;
          retain _STRAT_ _CLUST_ _ADJUST_ _NOBS_ _SUMWGT_ 0;
          if (first.&stratum) then do;  /* increment strata count */
            _STRAT_ = _STRAT_ + 1;
            _CLUST_ = 1;
            _ADJUST_ =  (&nclusts - 1) / &nclusts;
          end;
          else if (first.&cluster) then _CLUST_ = _CLUST_ + 1;  /* increment cluster count */

          if (_STRAT_ eq &strat) then do;  /* current stratum */
            if (_CLUST_ eq &clust) then do;  /* current cluster */
              _WEIGHT_ = 0;  /* signal delete observation */
            end;
            else do;  /* not current cluster */
              %if (&weight eq ) %then %do;  /* weight data as one or weight value */
                _WEIGHT_ = 1;
              %end;
              %else %do;
                _WEIGHT_ = &weight;
              %end;
            end;
          end;

          else do;  /* not current stratum */
            %if (&nstrata eq 1) %then %do;  /* one stratum */
              %if (&weight eq ) %then %do;  /* weight data as one or weight value */
                _WEIGHT_ = 1;
              %end;
              %else %do;
                _WEIGHT_ = &weight;
              %end;
            %end;
            %else %do;  /* multiple strata */
              %if (&weight eq ) %then %do;  /* adjust the weight for the missing cluster */
                _WEIGHT_ = _ADJUST_;
              %end;
              %else %do;
                _WEIGHT_ = _ADJUST_ * &weight;
              %end;
            %end;
          end;

          if (_WEIGHT_ gt 0) then do;
            _NOBS_ = _NOBS_ + 1;  /* acccumulate number of observations, sum of weights */
            _SUMWGT_ = _SUMWGT_ + _WEIGHT_;
            %if (&procid eq PHREG) %then _OFFSET_ = log(_WEIGHT_)%str(;);
            output;  /* output observation */
          end;

          if (_LAST_) then do;  /* write estimates preamble */
            file "&outfile" recfm=n mod;
            _MULT_ = &mult;  /* multiple */
            put _MULT_ rb&ldouble..;
            %if (&by ne ) %then %do;  /* by(s) */
              %let posn = 0;
              %do %until(&byvar eq );
                %let posn = %eval(&posn + 1);
                %let byvar = %scan(%bquote(&by), &posn, " ");
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
            %end;
            /* stratum number, cluster number, number of observations, sum of weights */
            _STRAT_ = &strat;
            _CLUST_ = &clust;
            put (_STRAT_ _CLUST_ _NOBS_ _SUMWGT_) (rb&ldouble..);
          end;

        run;

        %if (&syserr ne 0) %then %let msg = Error in SAS data step. Please check log;

        %else %do;  /* run SAS module for replicate */
          %let replicat = %eval(&replicat + 1);
          %put Replicate &replicat;
          %runmod;
        %end;

      %end;  /* end clusters loop */
    %end;  /* end strata loop */

    %let rc = %sysfunc(close(&clsfile));  /* close clusters file */
  %end;

%mend repmod;
