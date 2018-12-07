
%macro metadata(datain= , form=standard, delim='09'x);

  %put Get metadata.;
  %put;

  %if (not %sysfunc(exist(&datain, data))) %then %let msg = Dataset &datain not found.;

  %else %do;  /* get the metadata */

    proc datasets nolist;  /* delete vars1, codes1 */
      delete vars1 codes1 / memtype=data;
      delete vars1 codes1 / memtype=view;
    run;

    data variables;  /* create the variables dataset */
      attrib
        Name label="Variable name"
        Type label="Variable type"
        Frame label="Variable codeframe"
        Label label="Variable label"
        ;
      datafile = open("&datain", "i");
      nvars = attrn(datafile, "nvars");
      do Var = 1 to nvars;
        Name = varname(datafile, var);
        if (vartype(datafile, var) eq "C") then Type = "char";
        else Type = "num";
        Frame = varfmt(datafile, var);
        if (substr(Frame, length(Frame), 1) eq ".") then Frame = substr(Frame, 1, length(Frame)-1);
        Label = varlabel(datafile, var);
        keep Var Name Type Frame Label;
        output;
      end;
      rc = close(datafile);
    run;

    %if (&syserr ne 0)  %then %let msg = Error in reading the SAS dataset;
  %end;

  %if (%bquote(&msg) eq ) %then %do;  /* get the formats */

    %let frames = ;
    %if (%sysfunc(libref(library)) eq 0) %then %do;
      %if (%sysfunc(exist(library.formats, catalog))) %then %do;

        proc format library=library cntlout=formats;  /* create the formats dataset */
        run;

        proc sql noprint;  /* keep the matched formats */
          create view vars1 as
            select distinct Var, Name, variables.Type, fmtname as Frame, variables.Label
              from variables
              left join formats
              on frame = fmtname and Start <> '';  /* vars1 view */
          create view codes1 as
            select distinct fmtname as Frame, start as Value, formats.Label
              from variables
              inner join formats
              on frame = fmtname and Start <> '';  /* codes1 view */
          select count(*)
            into :frames
            from codes1;
        quit;

        %if (&syserr ne 0)  %then %let msg = Error in processing the SAS formats;
      %end;
    %end;
  %end;

  %if (%bquote(&msg) eq ) %then %do;

    %if (&frames eq ) %then %do;  /* no referenced codeframes */

      data vars1;  /* set vars1 frame to missing */
        set variables;
        frame = "";
      run;

    %end;
    %else %if (&frames eq 0) %then %let frames = ;

    %if (%lowcase(&form) eq standard or %lowcase(&form) eq text) %then %do;  /* standard or text output */

      data _null_;  /* write metadata file */
        %if (&frames eq ) %then %do;
          set vars1;
        %end;
        %else %do;
          set vars1(in=_var_) codes1 end=_end_;
        %end;
        %if (&sysver eq 6.12) %then %do;
          length line $ 200 oldframe $ 8;
        %end;
        %else %do;
          length line $ 1024;
          %if (%sysevalf(&sysver lt 9)) %then %do;
            length oldframe $ 8;
          %end;
          %else %do;
            length oldframe $ 32;
          %end;
        %end;
        length oldtype $ 8;
        retain oldtype oldframe '' _code_ 0;
        file "&path..met";
        if (_n_ eq 1) then do;  /* write header */
          %if (&form eq standard) %then %do;
            put 'standard;';
          %end;
          %else %if (&delim eq ) %then %do;
            put 'delim " ";';
          %end;
          %else %if (&delim eq '09'x) %then %do;
            put 'delim "\t";';
          %end;
          %else %do;
            put 'delim "' "&delim" '";';
          %end;
          put 'variables';
        end;
        %if (&frames ne ) %then %do;  /* write variable lines */
          if (_var_) then do;
        %end;
            line = 'name=' || name;
            if (label ne '') then line = trim(line) || ' label="' || tranwrd(trim(label), '"', '""') || '"';
            type = trim(type);
            if (type ne oldtype) then do;
              oldtype = type;
              if (type eq 'char') then line = trim(line) || ' type=char';
              %if (&form eq standard) %then %do;
                else line = trim(line) || ' type=float';
              %end;
              %else %do;
                else line = trim(line) || ' type=num';
              %end;
            end;
            %if (&form eq standard) %then %do;
              if (_n_ eq 1) then line = trim(line) || ' width=8';
            %end;
            %if (&frames ne ) %then %do;
              if (frame ne ' ') then line = trim(line) || ' codeframe=' || trim(frame);
            %end;
            line = trim(line) || ';';
            put @3 line;
        %if (&frames ne ) %then %do;  /* write codeframe lines */
          end;
          else do;
            if (frame ne ' ') then do;
              if (frame ne oldframe) then do;
                oldframe = frame;
                if (_code_ eq 0) then do;
                  _code_ = 1;
                  put 'codeframes';
                end;
                else put '    ;';
                put @3 'name=' frame;
              end;
              line = trim(value) || ' = "' || tranwrd(trim(label), '"', '""') || '"';
               put @5 line;
            end;
            if (_end_ and _code_) then put '    ;';
          end;
        %end;
      run;

    %end;
  %end;

%mend metadata;
