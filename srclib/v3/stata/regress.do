set output error

/* regress command */

global proc "regress"

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
    if $impute == 1 {
      run "$srclib/execute" impute  /* execute impute */
      if "$msg" == "" {
        if "$dataout" != "" run "$srclib/putdata"  /* run putdata */
        run "$srclib/execute" setdata  /* execute setdata */
      }
    }
    if "$msg" == "" {
      run "$srclib/execute" regress  /* execute regress */
      if "$msg" == "" {
        capture confirm file "$path.out"
        if _rc == 0 {
          run "$path.out"  /* output estimates, etc. */
          if "$mode" == "" rm "$path.out"
        }
      }
    }
  }
}

run "$srclib/results"  /* results */

set output proc

