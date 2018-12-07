/* get the arguments */

display "Get arguments."

/* parameters */

global msg ""

global cwd "`c(pwd)'"  /* current working directory */

if `"$srclib"' != "" {  /* srclib */
  capture cd "$srclib"
  if _rc == 0 {
    global srclib "`c(pwd)'"  /* srclib */
    capture cd "../bin"
    if _rc == 0 {
      global bin "`c(pwd)'"  /* bin */
      cd "$cwd"
    }
    else global msg "Invalid bin."
  }
  else global msg "Invalid srclib."
}

if "$msg" == "" {  /* name */
  global name = trim("$name")
  if "$name" == "" global msg "Missing name."
  else if !regexm("$name", "^[a-zA-Z0-9_ -]+$") global msg "Invalid name."
}

if "$msg" == "" {  /* dir */
  global dir = trim(`"$dir"')
  if "$dir" != "" {
    if regexm(`"$dir"', `"^"([^"]+)"$"') global dir = trim(regexs(1))
    else if regexm(`"$dir"', "^'([^']+)'$") global dir = trim(regexs(1))
    if regexm(`"$dir"', "^[~\.\\/:a-zA-Z0-9_ -]+$") {
      capture cd "$dir"
      if _rc == 0 {
        global dir "`c(pwd)'"
        if c(os) == "Windows" global dir "$dir\"
        else global dir "$dir/"
        cd `"$cwd"'
      }
      else global msg "Nonexistent dir."
    }
    else global msg "Invalid dir."
  }
}

if "$msg" == "" & "$mode" != "" {  /* mode */
  if !regexm(lower("$mode"), "^debug|test$") global msg "Invalid mode."
}

/* setup */

if "$msg" == "" {
  if "$dir" == "" global path "$name"  /* path */
  else global path "$dir$name"
  capture file open setup using "$path.set", read text  /* read text */
  if _rc != 0 global msg "Can't open $path.set"
  else {
    global setup ""
    file read setup line
    while r(eof)==0 {
      global setup "$setup`line'"
      file read setup line
    }
    file close setup
    if regexm("$setup", "(^|;) *[dD][aA][tT][aA][iI][nN] +([^;]+);") {  /* datain */
      global datain = trim(regexs(2))
      if "$proc" != "combine" {  /* not combine */
        if regexm(`"$datain"', `"^"([^"]+)""') global datain = trim(regexs(1))  /* first name double-quoted */
        else if regexm(`"$datain"', "^'([^']+)'") global datain = trim(regexs(1))  /* first name single-quoted */
        else if regexm(`"$datain"', "^([^ ]+)") global datain = trim(regexs(1))  /* first name unquoted */
        if !regexm(`"$datain"', "^[~\.\\/:a-zA-Z0-9_ -]+$") global msg "Invalid datain."  /* check */
      }
    }
    else global msg "Missing datain."
    if "$proc" != "putdata" | "$dataout" == "" {  /* dataout */
      if regexm("$setup", "(^|;) *[dD][aA][tT][aA][oO][uU][tT] +([^;]+);") global dataout = trim(regexs(2))
      else global dataout ""
    }
    if `"$dataout"' != "" {  /* remove all or concatenate */
      if regexm(`"$dataout"', "^(.+) +([aA][lL][lL]|[cC][oO][nN]|[cC][oO][nN][cC][aA][tT]|[cC][oO][nN][cC][aA][tT][eE][nN][aA][tT][eE])$") {
        global dataout = trim(regexs(1))
      }
      if regexm(`"$dataout"', `"^"([^"]+)"$"') global dataout = trim(regexs(1))  /* name double-quoted */
      else if regexm(`"$dataout"', "^'([^']+)'$") global dataout = trim(regexs(1))  /* name single-quoted */
      if !regexm(`"$dataout"', "^[~\.\\/:a-zA-Z0-9_ -]+$") global msg "Invalid dataout."  /* check */
    }
    else if "$proc" == "combine" global msg "Missing datain."
  }
}

