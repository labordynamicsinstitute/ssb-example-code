set output error

/* synthesize command */

global proc "synthesize"

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
    run "$srclib/execute" impute  /* execute synthesize */
    if "$msg" == "" {
      if "$dataout" != "" run "$srclib/putdata"  /* run putdata */
    }
  }
}

run "$srclib/results"  /* results */

set output proc

