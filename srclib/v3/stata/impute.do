set output error

/* impute command */

global proc "impute"

/* arguments */
if "$srclib" == "" run arguments
else if regexm("$srclib", "[\/]$") run "${srclib}arguments"
else run "$srclib/arguments"

/* metadata */
if "$msg" == "" run "$srclib/metadata"

/* execute */
if "$msg" == "" {
  run "$srclib/execute" iveset  /* execute iveset */
  if "$msg" == "" {
    run "$path.inp"  /* input data */
    run "$srclib/execute" impute  /* execute impute */
    if "$msg" == "" {
      capture confirm file "$path.out"
      if _rc == 0 {
        run "$path.out"  /* plot the diagnostics */
        if "$mode" == "" rm "$path.out"
      }
    }
    if "$msg" == "" {
      if "$dataout" != "" run "$srclib/putdata"  /* run putdata */
    }
  }
}

run "$srclib/results"  /* results */

set output proc

