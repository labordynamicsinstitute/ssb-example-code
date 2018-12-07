set output error

/* putdata command */

global proc "putdata"

/* arguments */

if "$srclib" == "" run arguments
else if regexm("$srclib", "[\/]$") run "${srclib}arguments"
else run "$srclib/arguments"

if "$msg" == "" & "$dataout" == "" global msg "Missing dataout."  /* dataout */

if "$msg" == "" & "$impl" != "" {  /* implicate */
  if !regexm("$impl", "^([aA][lL][lL]|[0-9]+)$") global msg "Invalid implicate."
}

if "$msg" == "" & "$mult" != "" {  /* multiple */
  if !regexm("$mult", "^([aA][lL][lL]|[0-9]+)$") global msg "Invalid multiple."
}

/* execute */

if "$msg" == "" {
  /* collect arguments */
  global args "/dataout=$dataout"
  if strpos("$args", " ") != 0 global args `""$args""'
  if "$impl" != "" global args `"$args /impl=$impl"'
  if "$mult" != "" global args `"$args /mult=$mult"'
  run "$srclib/execute" putdata  /* execute putdata */

  /* results */

  if "$msg" == "" {
    capture confirm file "$dataout.out"
    if _rc == 0 {
      run "$dataout.out"  /* run output program */
      if "$mode" == "" {  /* remove files */
        rm "$dataout.imp"
        rm "$dataout.out"
      }
    }
  }
}

/* results */
if "$msg" != "" {
  set output proc
  display "$msg"
  set output error
}

set output proc

