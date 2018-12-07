
/* Setmod - IVEware sasmod setup parsing macro */

%macro setmod;

  %if (%bquote(&msg) eq ) %then %do;  /* open log output file */
    %let msg = %str(Can%'t) open log file;
    %if (%sysfunc(filename(logref, &path..log)) eq 0) %then %do;
      %let logfile = %sysfunc(fopen(&logref, o));
      %if (&logfile ne 0) %then %let msg = ;
    %end;
  %end;

  %if (%bquote(&msg) eq ) %then %do;  /* write log introduction */
    %let msg = %str(Can%'t) write log file;
    %let line = %str(                 Iveware Multiple Imputation Regression Program);
    %if (%sysfunc(fput(&logfile, &line)) eq 0) %then %do;
      %if (%sysfunc(fwrite(&logfile)) eq 0) %then %do;
        %let line = %str(             Survey Research Center, Institute for Social Research);
        %let rc = %sysfunc(fput(&logfile, &line));
        %let rc = %sysfunc(fwrite(&logfile));
        %let line = %str(                             University of Michigan);
        %let rc = %sysfunc(fput(&logfile, &line));
        %let rc = %sysfunc(fwrite(&logfile));
        %let line = %str(                        Version 2.0, Copyright (c) 2005);
        %let rc = %sysfunc(fput(&logfile, &line));
        %let rc = %sysfunc(fwrite(&logfile));
        %let rc = %sysfunc(fput(&logfile, ));
        %let rc = %sysfunc(fwrite(&logfile));
        %let line = %sysfunc(date(), weekdate17.), &systime;
        %let rc = %sysfunc(fput(&logfile, %bquote(&line)));
        %let rc = %sysfunc(fwrite(&logfile));
        %let rc = %sysfunc(fput(&logfile, %str(  Process setup)));
        %let rc = %sysfunc(fwrite(&logfile));
        %let msg = ;
      %end;
    %end;
  %end;

  %if (%bquote(&msg) eq ) %then %do;  /* write intermediate setup file */
    %let list = 1;
    %if (&print eq none) %then %let list = 0;
    %let print = ;
    %let lsmeans = 0;
    %let repeated = 0;
    data _null_;
      %if (&list) %then %do;  /* write setup listing introduction */
        file "&path..lst";
        date = date();
        time = time();
        put "IVEware Setup Checker, " date date. ", " time time.;
        put;
        put "Setup listing:";
      %end;
      do while(1);  /* loop through the setup lines */
        %getset;
        file "&path..con";  /* write output file */
        put line;
        if (upcase(scan(line, 1)) eq 'LSMEANS') then call symput('lsmeans', '1');
        if (upcase(scan(line, 1)) eq 'REPEATED') then call symput('repeated', '1');
      end;
    run;
  %end;

  %if (%bquote(&msg) eq ) %then %do;  /* open intermediate setup file */
    %let msg = %str(Can%'t) open intermediate setup file;
    %if (%sysfunc(filename(setref, &path..con)) eq 0) %then %do;
      %if (%sysfunc(fileref(&setref)) eq 0) %then %do;
        %let setfile = %sysfunc(fopen(&setref, i));
        %if (&setfile ne 0) %then %let msg = ;
      %end;
    %end;
  %end;

  %if (%bquote(&msg) eq ) %then %do;  /* open module output file */
    %let msg = %str(Can%'t) open module file;
    %if (%sysfunc(filename(modref, &path..mod)) eq 0) %then %do;
      %let modfile = %sysfunc(fopen(&modref, o));
      %if (&modfile ne 0) %then %let msg = ;
    %end;
  %end;

  %if (%bquote(&msg) eq ) %then %do;  /* process setup file */
    %let key = ;
    %let line = ;
    %let model = ;
    %let result = ;
    %let response = ;
    %do %while(%bquote(&msg) eq and %bquote(%upcase(&key)) ne RUN);  /* setup line loop */

      %let msg = %str(Can%'t) read setup file;  /* read setup line */
      %if (%sysfunc(fread(&setfile)) eq 0) %then %if (%sysfunc(fget(&setfile, line, 32767)) eq 0) %then %do;
        %let msg = ;

        %let key = %scan(%bquote(&line), 1, %str( =.;));  /* get keyword */

        %if (%bquote(%upcase(&key)) eq DATAIN) %then %do;  /* datain file(s) */
          %if (&datain ne ) %then %let msg = Repeated datain statement;
          %else %if (&procid ne ) %then %let msg = Datain must precede procedure;
          %else %do;
            %let count = 100;
            %params;
            %let datain = &result;
            %let nmults = &count;
          %end;
        %end;

        %else %if (%bquote(%upcase(&key)) eq ESTOUT) %then %do;  /* estout file */
          %if (&estout ne ) %then %let msg = Repeated estout statement;
          %else %if (&procid ne ) %then %let msg = Estout must precede procedure;
          %else %do;
            %let count = 1;
            %params;
            %let estout = &result;
          %end;
        %end;

        %else %if (%bquote(%upcase(&key)) eq BY) %then %do;  /* by variable(s) */
          %if (&by ne ) %then %let msg = Repeated by statement;
          %else %if (&procid ne ) %then %let msg = By must precede procedure;
          %else %do;
            %let count = 100;
            %params;
            %let by = &result;
            %let nbys = &count;
          %end;
        %end;

        %else %if (%bquote(%upcase(&key)) eq STRATUM) %then %do;  /* stratum variable */
          %if (&stratum ne ) %then %let msg = Repeated stratum statement;
          %else %if (&procid ne ) %then %let msg = Stratum must precede procedure;
          %else %do;
            %let count = 1;
            %params;
            %let stratum = &result;
          %end;
        %end;

        %else %if (%bquote(%upcase(&key)) eq CLUSTER) %then %do;  /* cluster variable */
          %if (&cluster ne ) %then %let msg = Repeated cluster statement;
          %else %if (&procid ne ) %then %let msg = Cluster must precede procedure;
          %else %do;
            %let count = 1;
            %params;
            %let cluster = &result;
          %end;
        %end;

        %else %if (%bquote(%upcase(&key)) eq WEIGHT) %then %do;  /* weight variable */
          %if (&weight ne ) %then %let msg = Repeated weight statement;
          %else %if (&procid ne ) %then %let msg = Weight must precede procedure;
          %else %do;
            %let count = 1;
            %params;
            %let weight = &result;
          %end;
        %end;

        %else %if (%bquote(%upcase(&key)) eq TITLE) %then %do;  /* title */
          %if (%bquote(&title) ne ) %then %let msg = Repeated title statement;
          %else %if (&procid ne ) %then %let msg = Title must precede procedure;
          %else %do;
            %let title = %qsubstr(%bquote(&line), 7, %length(%bquote(&line)) - 7);
            %let title = %qleft(%bquote(&title));
            %let title = %qtrim(&title);
          %end;
        %end;

        %else %if (%bquote(%upcase(&key)) eq PRINT) %then %do;  /* print */
          %if (%bquote(&print) ne ) %then %let msg = Repeated print statement;
          %else %if (&procid ne ) %then %let msg = Print must precede procedure;
          %else %do;
            %let print = %qsubstr(&line, 7, %length(%bquote(&line)) - 7);
            %let print = %qleft(%bquote(&print));
            %let print = %qtrim(&print);
            %let print = %upcase(%qsubstr(&print, 1, 2));
            %if (&print eq NO) %then %let print = none;
            %else %if (&print eq ST) %then %let print = standard;
            %else %if (&print eq DE or &print eq AL) %then %let print = details;
            %else %let msg = Print parameter not recognized;
          %end;
        %end;

        %else %if (%bquote(%upcase(&key)) eq PROC) %then %do;  /* procedure statement */

          %if (&procid ne ) %then %let msg = Repeated procedure statement;
          %else %if (&datain eq ) %then %let msg = Datain must precede procedure;
          %else %do;  /* check subsequent parameters for "data=" */
            %let end = %index(&line, %str(/));
            %if (&end eq 0) %then %let end = %length(%bquote(&line));
            %let subline = %qupcase(%qcmpres(%qsubstr(&line, 1, &end)));
            %if %index(&subline, %str( DATA=)) gt 0 or %index(&subline, %str( DATA =)) gt 0 %then
              %let msg = Sasmod %str(doesn%'t) accept proc statement "data=" parameter;
          %end;

          %if (&msg eq ) %then %do;

            %let procid = %scan(%bquote(&line), 2, %str( ;));  /* get procedure name */

            %if (%bquote(%upcase(&procid)) eq CALIS) %then %do;  /* proc calis */
              %let line = %qsubstr(&line, 1, %length(%bquote(&line)) - 1);
              %let line = %qtrim(&line);
              %let line = %bquote(&line) outest=est1 noprint%str(;);
            %end;

            %else %if (%bquote(%upcase(&procid)) eq CATMOD) %then %do;  /* proc catmod */
              %if (&sysver eq 6.12) %then
                %let msg = Sasmod %str(doesn%'t) support proc catmod in SAS V6.12;
              %else %do;
                %let ods = ods select none%str(;);
                %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                %let rc = %sysfunc(fwrite(&modfile));
                %let ods = ods output Estimates = est1%str(;);
                %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                %let rc = %sysfunc(fwrite(&modfile));
                %if (&cluster eq and &stratum eq and &weight eq ) %then %do;
                  %let ods = ods output CovB = covb1%str(;);
                  %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                  %let rc = %sysfunc(fwrite(&modfile));
                %end;
                %let ods = ods output MaxLikelihood = like1%str(;);
                %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                %let rc = %sysfunc(fwrite(&modfile));
              %end;
            %end;

            %else %if (%bquote(%upcase(&procid)) eq GENMOD) %then %do;  /* proc genmod */
              %if (&sysver eq 6.12) %then
                %let msg = Sasmod %str(doesn%'t) support proc genmod in SAS V6.12;
              %else %do;
                %let ods = ods select none%str(;);
                %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                %let rc = %sysfunc(fwrite(&modfile));
                %if (&repeated) %then %let ods = ods output GEEEmpPEst = est1%str(;);
                %else %let ods = ods output ParameterEstimates = est1%str(;);
                %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                %let rc = %sysfunc(fwrite(&modfile));
                %if (&lsmeans) %then %do;
                  %let ods = ods output LSMeans = lsmeans%str(;);
                  %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                  %let rc = %sysfunc(fwrite(&modfile));
                %end;
                %if (&cluster eq and &stratum eq and &weight eq ) %then %do;
                  %if (&repeated) %then %let ods = ods output GEERCov = covb1%str(;);
                  %else %let ods = ods output CovB = covb1%str(;);
                  %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                  %let rc = %sysfunc(fwrite(&modfile));
                %end;
                %if (not &repeated) %then %do;
                  %let ods = ods output ModelFit = like1%str(;);
                  %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                  %let rc = %sysfunc(fwrite(&modfile));
                %end;
              %end;
            %end;

            %else %if (%bquote(%upcase(&procid)) eq LIFEREG) %then %do;  /* proc lifereg */
              %let line = %qsubstr(&line, 1, %length(%bquote(&line)) - 1);
              %let line = %qtrim(&line);
              %let line = %bquote(&line) covout outest=est1 noprint%str(;);
            %end;

            %else %if (%bquote(%upcase(&procid)) eq MIXED) %then %do;  /* proc mixed */
              %if (&sysver eq 6.12) %then
                %let msg = Sasmod %str(doesn%'t) support proc mixed in SAS V6.12;
              %else %do;
                %let ods = ods select none%str(;);
                %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                %let rc = %sysfunc(fwrite(&modfile));
                %let ods = ods output SolutionF = est1%str(;);
                %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                %let rc = %sysfunc(fwrite(&modfile));
                %let ods = ods output CovParms = covparms%str(;);
                %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                %let rc = %sysfunc(fwrite(&modfile));
                %if (&cluster eq and &stratum eq and &weight eq ) %then %do;
                  %let ods = ods output CovB = covb1%str(;);
                  %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                  %let rc = %sysfunc(fwrite(&modfile));
                %end;
                %let ods = ods output FitStatistics = like1%str(;);
                %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                %let rc = %sysfunc(fwrite(&modfile));
              %end;
            %end;

            %else %if (%bquote(%upcase(&procid)) eq NLIN) %then %do;  /* proc nlin */
              %let line = %qsubstr(&line, 1, %length(%bquote(&line)) - 1);
              %let line = %qtrim(&line);
              %let line = %bquote(&line) outest=est1 noprint%str(;);
            %end;

            %else %if (%bquote(%upcase(&procid)) eq PHREG) %then %do;  /* proc phreg */
              %if (&sysver eq 6.12) %then
                %let msg = Sasmod %str(doesn%'t) support proc phreg in SAS V6.12;
              %else %do;
                %let ods = ods select none%str(;);
                %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                %let rc = %sysfunc(fwrite(&modfile));
                %let ods = ods output ParameterEstimates = est1%str(;);
                %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                %let rc = %sysfunc(fwrite(&modfile));
                %if (&cluster eq and &stratum eq and &weight eq ) %then %do;
                  %let ods = ods output CovB = covb1%str(;);
                  %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                  %let rc = %sysfunc(fwrite(&modfile));
                %end;
                %let ods = ods output FitStatistics = like1%str(;);
                %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                %let rc = %sysfunc(fwrite(&modfile));
              %end;
            %end;

            %else %if (%bquote(%upcase(&procid)) eq PROBIT) %then %do;  /* proc probit */
              %let line = %qsubstr(&line, 1, %length(%bquote(&line)) - 1);
              %let line = %qtrim(&line);
              %let line = %bquote(&line) covout outest=est1 noprint%str(;);
            %end;

            %else %if (%bquote(%upcase(&procid)) eq ROBUSTREG) %then %do;  /* proc robustreg */
              %if (&sysver eq 6.12) %then
                %let msg = Sasmod %str(doesn%'t) support proc robustreg in SAS V6.12;
              %else %do;
                %let ods = ods select none%str(;);
                %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                %let rc = %sysfunc(fwrite(&modfile));
                %let ods = ods output ParameterEstimates = est1%str(;);
                %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                %let rc = %sysfunc(fwrite(&modfile));
                %if (&cluster eq and &stratum eq and &weight eq ) %then %do;
                  %let ods = ods output CovB = covb1%str(;);
                  %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                  %let rc = %sysfunc(fwrite(&modfile));
                %end;
              %end;
            %end;

            %else %if (%bquote(%upcase(&procid)) eq SYSLIN) %then %do;  /* proc syslin */
              %if (&sysver eq 6.12) %then
                %let msg = Sasmod %str(doesn%'t) support proc syslin in SAS V6.12;
              %else %do;
                %let ods = ods select none%str(;);
                %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                %let rc = %sysfunc(fwrite(&modfile));
                %let ods = ods output ParameterEstimates = est1%str(;);
                %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                %let rc = %sysfunc(fwrite(&modfile));
                %if (&cluster eq and &stratum eq and &weight eq ) %then %do;
                  %let ods = ods output CovB = covb1%str(;);
                  %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
                  %let rc = %sysfunc(fwrite(&modfile));
                %end;
              %end;
            %end;

            %else %let msg = Sasmod %str(doesn%'t) support procedure %bquote(&procid);  /* unsupported proc */
          %end;

          %if (%bquote(&msg) eq ) %then %do;
            %let procid = %upcase(&procid);  /* procedure name upper case for recognition */
            %let rc = %sysfunc(fput(&modfile, %bquote(&line)));  /* write proc statement */
            %let rc = %sysfunc(fwrite(&modfile));
            %if (&cluster ne or &stratum ne or &weight ne ) %then %do;  /* write freq/weight statement */
              %if (&procid ne NLIN and &procid ne PHREG) %then %do;
                %if (&procid eq GENMOD) %then %let line = freq _WEIGHT_%str(;);
                %else %let line = weight _WEIGHT_%str(;);
                %let rc = %sysfunc(fput(&modfile, %bquote(&line)));
                %let rc = %sysfunc(fwrite(&modfile));
              %end;
            %end;
          %end;
        %end;

        %else %if (&procid eq ) %then %let msg = Sasmod %str(doesn%'t) recognize &key statement;

        %else %if (%bquote(%upcase(&key)) eq CLASS) %then %do;  /* class statement */
          %if (&procid eq LIFEREG and &sysver eq 6.12) %then
            %let msg = Sasmod %str(doesn%'t) support class statements with proc lifereg in SAS V6.12;
          %else %if (&procid eq PROBIT and &sysver eq 6.12) %then
            %let msg = Sasmod %str(doesn%'t) support class statements with proc probit in SAS V6.12;
          %else %do;
            %let rc = %sysfunc(fput(&modfile, %bquote(&line)));
            %let rc = %sysfunc(fwrite(&modfile));
          %end;
        %end;

        %else %if (%bquote(%upcase(&key)) eq FREQ) %then %do;
          %let msg = Sasmod %str(doesn%'t) support freq statements%str(;) use weight instead;
        %end;

        %else %if (%bquote(%upcase(&key)) eq MODEL) %then %do;  /* model statement */
          %if (&procid eq ) %then
            %let msg = Model statement must follow procedure;
          %else %if (&model ne ) %then
            %let msg = Repeated model statement;
          %else %do;
            %let model = yes;

            %if (&procid eq CATMOD) %then %do;  /* proc catmod, request covariances */
              %let line = %qsubstr(&line, 1, %length(%bquote(&line)) - 1);
              %let line = %qtrim(&line);
              %if (%index(%bquote(&line), %str(/)) eq 0) %then
                %let line = %bquote(&line) /;
              %if (%sysevalf(&sysver ge 9)) %then
                %let line = %bquote(&line) covb itprint%str(;);
              %else
                %let line = %bquote(&line) covb%str(;);
            %end;

            %else %if (&procid eq GENMOD) %then %do;  /* proc genmod, request covariances */
              %let line = %qsubstr(&line, 1, %length(%bquote(&line)) - 1);
              %let line = %qtrim(&line);
              %if (%index(%bquote(&line), %str(/)) eq 0) %then
                %let line = %bquote(&line) / covb%str(;);
              %else
                %let line = %bquote(&line) covb%str(;);
            %end;

            %else %if (&procid eq MIXED) %then %do;  /* proc mixed, request solution and covariances */
              %let line = %qsubstr(&line, 1, %length(%bquote(&line)) - 1);
              %let line = %qtrim(&line);
              %if (%index(%bquote(&line), %str(/)) eq 0) %then
                %let line = %bquote(&line) / s covb%str(;);
              %else
                %let line = %bquote(&line) s covb%str(;);
            %end;

            %else %if (&procid eq PHREG) %then %do;  /* proc phreg, request covariances and possibly offset */
              %let line = %qsubstr(&line, 1, %length(%bquote(&line)) - 1);
              %let line = %qtrim(&line);
              %if (%index(%bquote(&line), %str(/)) eq 0) %then
                %let line = %bquote(&line) / covb;
              %else
                %let line = %bquote(&line) covb;
              %if (&cluster ne or &stratum ne or &weight ne ) %then
                %let line = %bquote(&line) offset=_OFFSET_%str(;);
              %else
                %let line = %bquote(&line)%str(;);
            %end;

            %else %if (&procid eq ROBUSTREG) %then %do;  /* proc robustreg, request covariances */
              %let line = %qsubstr(&line, 1, %length(%bquote(&line)) - 1);
              %let line = %qtrim(&line);
              %if (%index(%bquote(&line), %str(/)) eq 0) %then
                %let line = %bquote(&line) / covb%str(;);
              %else
                %let line = %bquote(&line) covb%str(;);
            %end;

            %else %if (&procid eq SYSLIN) %then %do;  /* proc syslin, request covariances */
              %let line = %qsubstr(&line, 1, %length(%bquote(&line)) - 1);
              %let line = %qtrim(&line);
              %if (%index(%bquote(&line), %str(/)) eq 0) %then
                %let line = %bquote(&line) / covb%str(;);
              %else
                %let line = %bquote(&line) covb%str(;);
            %end;

            %let rc = %sysfunc(fput(&modfile, %bquote(&line)));  /* write model statement */
            %let rc = %sysfunc(fwrite(&modfile));

          %end;
        %end;

        %else %if (%bquote(%upcase(&key)) eq OUTPUT) %then %do;  /* output statement */
          %let msg = Sasmod %str(doesn%'t) support output statements;
        %end;

        %else %if (%bquote(%upcase(&key)) eq REPEATED) %then %do;  /* repeated statement */
          %if (&procid eq ) %then
            %let msg = Repeated statement must follow procedure;
          %else %do;

            %if (&procid eq GENMOD) %then %do;  /* proc genmod, request gee covariances */
              %let line = %qsubstr(&line, 1, %length(%bquote(&line)) - 1);
              %let line = %qtrim(&line);
              %if (%index(%bquote(&line), %str(/)) eq 0) %then
                %let line = %bquote(&line) / ecovb%str(;);
              %else
                %let line = %bquote(&line) ecovb%str(;);
            %end;

            %let rc = %sysfunc(fput(&modfile, %bquote(&line)));  /* write repeated statement */
            %let rc = %sysfunc(fwrite(&modfile));

          %end;
        %end;

        %else %if (%bquote(%upcase(&key)) eq RUN) %then %do;  /* run statement */
          %let rc = %sysfunc(fput(&modfile, %bquote(&line)));
          %let rc = %sysfunc(fwrite(&modfile));
          %if (&procid ne CALIS and &procid ne LIFEREG and &procid ne NLIN and &procid ne PROBIT) %then %do;
            %let line = quit%str(;);  /* quit the step */
            %let rc = %sysfunc(fput(&modfile, %bquote(&line)));
            %let rc = %sysfunc(fwrite(&modfile));
            %let ods = ods select all%str(;);  /* end ods output */
            %let rc = %sysfunc(fput(&modfile, %bquote(&ods)));
            %let rc = %sysfunc(fwrite(&modfile));
          %end;
        %end;

        %else %do;  /* other statements */
          %let rc = %sysfunc(fput(&modfile, %bquote(&line)));
          %let rc = %sysfunc(fwrite(&modfile));
        %end;

        %let line = ;  /* line processed, blank it out */

      %end;  /* end no error message if */
    %end;  /* end setup line loop */
  %end;  /* end no error message if */

  %if (%bquote(&msg) eq ) %then %do;  /* check for valid proc statement */
    %if (&procid eq ) %then %let msg = No proc statement;
    %else %if (&procid ne CALIS and &model eq ) %then %let msg = No model statement;
  %end;

  %if (&setfile ne ) %then %do;  /* close setup file */
    %let rc = %sysfunc(fclose(&setfile));
    %let rc = %sysfunc(filename(setref));
    %let setfile = ;
  %end;

  %if (&modfile ne ) %then %do;  /* close module file */
    %let rc = %sysfunc(fclose(&modfile));
    %let rc = %sysfunc(filename(modref));
    %let modfile = ;
  %end;

  %if (&logfile ne ) %then %do;  /* close log file */
    %let rc = %sysfunc(fclose(&logfile));
    %let rc = %sysfunc(filename(logref));
    %let logfile = ;
  %end;

%mend setmod;

%macro params;  /* get parameters */

  %let posn = 0;
  %let result = ;
  %do %until(&posn eq &count);
    %let key = %scan(%bquote(&line), &posn + 2, %str( =;));  /* get next paramter */
    %if (&key ne ) %then %do;
      %if (&result eq ) %then %let result = &key;  /* if parameter exists, concatenate it */
      %else %let result = &result &key;
      %let posn = %eval(&posn + 1);
    %end;
    %else %let count = &posn;
  %end;  /* if parameter doesn't exist or no more parameters desired, quit */

%mend params;
