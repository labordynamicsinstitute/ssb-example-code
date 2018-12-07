
%macro setup;  /* macro to get the setup file */

  %getpath;  /* get the file path */

  %let sysin1 = %sysfunc(getoption(SYSIN));  /* check for log/lst file name conflict */
  %if (%bquote(&sysin1) ne ) %then %do;
    %let sysin2 = &path..sas;
    %if (%qsubstr(&sysin2, 1, 1) eq %str(~)) %then
      %let sysin2 = %sysget(HOME)/%qsubstr(&sysin2, 3, %length(&sysin2)-2);
    %if (%bquote(&sysin1) eq %bquote(&sysin2)) %then
      %let msg = SAS and SRCware log/lst file name conflict;
  %end;

  %if (%bquote(&msg) eq ) %then %do;
    %if (%lowcase(&setup) eq new or %lowcase(&setup) eq old) %then %do;
      %if (%bquote(&name) eq ) %then %let setup = new;  /* unnamed new (inline) setup file */
      %let msg = %str(Can%'t find setup file.);  /* assume error */
      %if (%sysfunc(filename(setref, &path..set)) eq 0) %then %do;
        %if (%sysfunc(fileref(&setref)) le 0) %then %do;
          %let path = %sysfunc(pathname(&setref));
          %let path = %qsubstr(&path, 1, %length(&path)-4);

          %if (%lowcase(&setup) eq new) %then %do;  /* new (inline) setup file */
            %let msg = ;  /* assume no error */

            %if (&sysscp eq WIN) %then %do;  /* check Windows errors */
              %if (%bquote(%sysfunc(getoption(SYSIN))) ne ) %then
                %let msg = %str(The "setup=new" option works only in interactive mode.);
              %else %if (&sysver ne 6.12) %then %do;
                %if (%sysevalf(&sysver ge 9)) %then %do;
                  %if (%bquote(%sysget(SAS_EXECFILEPATH)) ne ) %then
                    %let msg = %str(The "setup=new" option requires the Program Editor.);
                %end;
              %end;
            %end;

            %else %do;  /* check Unix errors */
              %if (%bquote(%sysfunc(getoption(SYSIN))) ne ) %then
                %let msg = %str(The "setup=new" option works only in interactive mode.);
            %end;

            %if (%bquote(&msg) eq ) %then %do;  /* write file */
              %let msg = %str(Can%'t write setup file.);
              %let file = %sysfunc(fopen(&setref, o));
              %if (&file ne 0) %then %do;
                %do %until(%bquote(%upcase(&key)) eq RUN);
                  %input;
                  %let key = %scan(%bquote(&sysbuffr), 1, " =;");
                  %let rc = %sysfunc(fput(&file, %bquote(&sysbuffr)));
                  %let rc = %sysfunc(fwrite(&file));
                %end;
                %if (%sysfunc(fclose(&file)) eq 0) %then %let msg = ;  /* file written */
              %end;
            %end;
          %end;

          %else %do;  /* old setup file */
            %if (%sysfunc(fexist(&setref)) eq 1) %then %let msg = ;  /* file exists */
          %end;

          %let rc = %sysfunc(filename(setref));
        %end;
      %end;
    %end;

    %else %let msg = Setup parameter "&setup" not recognized.;
  %end;

%mend setup;

%macro getset;  /* macro to get a setup line */

  %if (&sysver eq 6.12) %then %do;  /* set the line and key lengths */
    length line $ 200;
    retain maxlen 200;
  %end;
  %else %do;
    length line $ 32767;
    retain maxlen 32767;
  %end;
  retain reclen 0 recptr 1 quote "";

  comment = 0;
  complete = 0;
  line = "";
  linelen = 0;
  do until (complete);  /* character loop */

    if (recptr gt reclen) then do;  /* need a new input record */
      if (linelen gt 0) then do;  /* will be a continuation record */
        if (substr(line, linelen, 1) ne ' ') then do;  /* insert a blank */
          linelen = linelen + 1;
          substr(line, linelen, 1) = ' ';
        end;
      end;
      do while (recptr gt reclen);  /* physical record loop */
        if (end) then do; /* end of file */
          if (linelen gt 0) then call symput("msg", "Setup line incomplete");
          stop;
        end;
        infile "&path..set" _infile_=record end=end lrecl=32767;  /* read record */
        input;
        %if (&list) %then %do;  /* list the setup record */
          file "&path..lst";
          put record;
        %end;
        if (record ne "") then do;
          reclen = length(record);
          recptr = 1;
          do while (recptr le reclen and substr(record, recptr, 1) le ' ');  /* skip leading whitespace */
            recptr = recptr + 1;
          end;
        end;
      end;
    end;

    if (comment) then do;
      if (recptr + 1 le reclen) then do;
        if (substr(record, recptr, 2) eq "*/") then do;  /* end comment */
          recptr = recptr + 1;
          substr(record, recptr, 1) = ' ';
          comment = 0;
        end;
      end;
      if (comment) then recptr = recptr + 1;
    end;
    else if (recptr + 1 le reclen) then do;
      if (substr(record, recptr, 2) eq "/*") then do;  /* begin comment */
        recptr = recptr + 2;
        comment = 1;
      end;
    end;
    if (not comment) then do;
      if (quote ne "") then do;
        if (substr(record, recptr, 1) eq quote) then quote = "";  /* end quote */
        linelen = linelen + 1;
        substr(line, linelen, 1) = substr(record, recptr, 1);
      end;
      else if (substr(record, recptr, 1) eq "'" or substr(record, recptr, 1) eq '"') then do;  /* begin quote */
        quote = substr(record, recptr, 1);
        linelen = linelen + 1;
        substr(line, linelen, 1) = substr(record, recptr, 1);
      end;
      else if (substr(record, recptr, 1) eq ';') then do;  /* semicolon */
        if (substr(line, 1, 1) eq '*') then linelen = 0;  /* comment line */
        else do;  /* non-comment line */
          if (linelen eq 0) then do;  /* setup line empty */
            call symput("msg", "Setup line empty");
            stop;
          end;
          if (substr(line, linelen, 1) ne ' ') then linelen = linelen + 1;
          substr(line, linelen, 1) = ';';  /* append semicolon */
          complete = 1;
        end;
      end;
      else if (substr(record, recptr, 1) gt ' ') then do;  /* keep non-whitespace character */
        linelen = linelen + 1;
        substr(line, linelen, 1) = substr(record, recptr, 1);
      end;
      else do;  /* whitespace character */
        if (linelen gt 0) then do;  /* not a leading whitespace character */
          if (substr(line, linelen, 1) ne ' ') then do;  /* not a repeated whitespace character */
            linelen = linelen + 1;  /* keep it as a blank */
            substr(line, linelen, 1) = ' ';
          end;
        end;
      end;
      recptr = recptr + 1;
    end;

  end;

  line = trim(substr(line, 1, linelen));  /* return the logical line */

%mend getset;

%macro getkeys;  /* macro to get keyword/value pairs */

  %if (&keys ne ) %then %do;

    data _null_;

      array keys(*) $ 32
        %let count = 0;  /* fill the keys array from the keys macro variable */
        %do %until(&key eq );
          %let count = %eval(&count + 1);
          %let key = %scan(&keys, &count, " ");
          %if (&key ne ) %then %do;
            key&count
          %end;
        %end;
        (
        %let count = 0;
        %do %until(&key eq );
          %let count = %eval(&count + 1);
          %let key = %scan(&keys, &count, " ");
          %if (&key ne ) %then %do;
            %if (&count gt 1) %then ,;
            "%upcase(&key)"
          %end;
        %end;
        );
      length key $ 32;

      do while (1);  /* loop through the setup lines */

        %let list = 0;  /* get a setup line */
        %getset;

        key = scan(line, 1, " ");  /* get its key */
        key = upcase(key);
        keylen = length(key);
        do _i_ = 1 to dim(keys);  /* check the key */
          if (keylen ge length(keys(_i_))) then do;
            if (substr(key, 1, length(keys(_i_))) eq keys(_i_)) then do;  /* key matches */
              line = left((substr(line, keylen+1)));  /* extract its value */
              line = substr(line, 1, length(line) - 1);
              call symput(keys(_i_), trimn(line));  /* set the macro */
              leave;
            end;
          end;
        end;

      end;

    run;
  %end;

%mend getkeys;
