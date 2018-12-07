set output error

/* bbdesign command */

global proc "bbdesign"

/* arguments */
if "$srclib" == "" run arguments
else if regexm("$srclib", "[\/]$") run "${srclib}arguments"
else run "$srclib/arguments"

/* metadata */
if "$msg" == "" run "$srclib/metadata"

/* execute */
if "$msg" == "" {
  global args "/setup"
  run "$srclib/execute" bbdesign  /* execute bbdesign setup */
  if "$msg" == "" {
    run "$path.inp"  /* input data */
    global args ""
    run "$srclib/execute" bbdesign  /* execute bbdesign go */
    if "$msg" == "" {
      capture confirm file "$path.out"
      if _rc == 0 {
        run "$path.out"  /* output the samples */
        if "$mode" == "" rm "$path.out"
      }
    }
  else global msg "Missing input file."
  }
}

run "$srclib/results"  /* results */

set output proc

