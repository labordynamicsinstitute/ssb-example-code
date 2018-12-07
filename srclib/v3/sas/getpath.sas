
%macro getpath;  /* macro to get the path name */

  %if (%bquote(&name) eq ) %then %let name = temp;  /* no name */
  %else %do;  /* name specified */
    %if (%qsubstr(&name, 1, 1) eq %str(%") or %qsubstr(&name, 1, 1) eq %str(%')) %then
      %let name = %qsubstr(&name, 2, %length(&name)-2);  /* remove quotes */
  %end;
  %if (%bquote(&dir) eq ) %then %let path = &name;  /* no directory */
  %else %if (%bquote(%upcase(&dir)) eq DEFAULT) %then %do;  /* default directory */
    %if (&sysscp eq WIN) %then %do;  /* Windows */
      %let dir = ;
      %if (&sysver ne 6.12) %then %let dir = %sysget(MYSASFILES);
      %if (%bquote(&dir) eq ) %then %let dir = %sysfunc(getoption(SASUSER));
      %if (%bquote(&dir) eq ) %then %let path = &name;  /* just name */
      %else %if (%qsubstr(&dir, %length(&dir)) eq %str(\)) %then
        %let path = &dir.&name;
      %else %let path = &dir\&name;  /* concatenate directory and name */
    %end;
    %else %do;  /* Unix */
      %let dir = %sysfunc(getoption(SASUSER));
      %if (%bquote(&dir) eq ) %then %let path = &name;  /* just name */
      %else %let path = &dir/&name;  /* concatenate directory and name */
    %end;
  %end;
  %else %do;  /* directory specified */
    %if (%qsubstr(&dir, 1, 1) eq %str(%") or %qsubstr(&dir, 1, 1) eq %str(%')) %then
      %let dir = %qsubstr(&dir, 2, %length(&dir)-2);  /* remove quotes */
    %if (&sysscp eq WIN) %then %do;  /* Windows */
      %if (%qsubstr(&dir, %length(&dir)) eq %str(\)) %then
        %let path = &dir.&name;
      %else %let path = &dir\&name;  /* concatenate directory and name */
    %end;
    %else %do;  /* Unix */
      %if (%qsubstr(&dir, %length(&dir)) eq %str(/)) %then
        %let path = &dir.&name;
      %else %let path = &dir/&name;  /* concatenate directory and name */
    %end;
  %end;

%mend getpath;
