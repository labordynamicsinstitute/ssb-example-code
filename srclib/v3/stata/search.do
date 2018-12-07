set output error

/* search command */

global proc "search"

/* arguments */
if "$srclib" == "" run arguments
else if regexm("$srclib", "[\/]$") run "${srclib}arguments"
else run "$srclib/arguments"

/* metadata */
if "$msg" == "" run "$srclib/metadata"

/* execute */
if "$msg" == "" {
  run "$srclib/execute" srchset  /* execute srchset */
  if "$msg" == "" {
    run "$path.inp"  /* input data */
    run "$srclib/execute" search  /* execute search */
    if "$msg" == "" {
      if "$dataout" != "" {
        capture confirm file "$path.res"
        if _rc == 0 run "$srclib/residuals"  /* run residuals */
      }
    }
  }
}

run "$srclib/results"  /* results */

set output proc

