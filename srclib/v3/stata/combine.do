
/* function to combine stata datasets */

global proc "combine"

/* arguments */
if "$srclib" == "" run arguments
else if regexm("$srclib", "[\/]$") run "${srclib}arguments"
else run "$srclib/arguments"
if "$msg" == "" {  /* variable list */
  if regexm("$setup", "(^|;) *[vV][aA][rR][^ ]* +([^;]+);") {
    global var = trim(regexs(2))
    if !regexm(`"$var"', "^[a-zA-Z0-9_ -]+$") global msg "Invalid variable list."  /* check */
  }
}

if "$msg" == "" {  /* combine the datasets */
  clear
  global filenames `"$datain"'
  while `"$filenames"' != "" {  /* loop through file names */
    if regexm(`"$filenames"', `"^"([^"]+)""') {  /* first name double-quoted */
      display "double quotes"
      global file = trim(regexs(1))
      global filenames = trim(substr(`"$filenames"', strlen(regexs(1)) + 1, .))
    }
    else if regexm(`"$filenames"', "^'([^']+)'") {  /* first name single-quoted */
      global file = trim(regexs(1))
      global filenames = trim(substr(`"$filenames"', strlen(regexs(1)) + 1, .))
    }
    else if regexm(`"$filenames"', "^([^ ]+)") {  /* first name unquoted */
      global file = trim(regexs(1))
      global filenames = trim(substr(`"$filenames"', strlen(regexs(1)) + 1, .))
    }
    if !regexm("$file", "^[~\.\\/:a-zA-Z0-9_ -]+$") global msg "Invalid datain."  /* check */
    append using "$file"
  }
  if "$var" != "" {  /* variable list */
    keep $var  /* subset */
  }
  save "$dataout", replace  /* save the output dataset */
}

