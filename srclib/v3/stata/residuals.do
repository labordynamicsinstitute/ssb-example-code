/* write the residuals */

/* build */
capture file open out using "$path.out", write replace text
if _rc != 0 global msg "Can't open $path.out"
if "$msg" == "" {
  capture file open res using "$path.res", read text
  if _rc != 0 global msg "Can't open $path.res"
  else {
    file read res line
    if !r(eof) {
      file write out `"use "$datain", clear"' _n
      while !r(eof) {
        if "`grpvar'" == "" & regexm("`line'", "^ *([a-zA-Z0-9_]+) *= *([0-9]+) *; *$") {
          local grpvar = regexs(1)
          local oldval = regexs(2)
          file write out "generate `grpvar' = `oldval'" _n
        }
        else if regexm("`line'", "^ *IF *`grpvar' *EQ *([0-9]+) *THEN *$") {
          local oldval = regexs(1)
        }
        else if regexm("`line'", "^ *IF *([a-zA-Z0-9_]+) *IN\(([0-9,]+)\) *THEN *`grpvar' *= *([0-9]+) *; *$") {
          local spltvar = regexs(1)
          local spltvals = regexs(2)
          local grpval = regexs(3)
          file write out "replace `grpvar' = `grpval' if `grpvar' == `oldval' & inlist(`spltvar',`spltvals')" _n
        }
        else if regexm("`line'", "^ *ELSE *`grpvar' *= *([0-9]+) *; *$") {
          local grpval = regexs(1)
          file write out "replace `grpvar' = `grpval' if `grpvar' == `oldval'" _n
        }
        else if regexm("`line'", "^ *IF *`grpvar' *EQ *([0-9]+) *THEN *([a-zA-Z0-9_]+) *= *(.+) *; *$") {
          local grpval = regexs(1)
          local estvar = regexs(2)
          local estexp = regexs(3)
          if !regexm("`genvars'", " `estvar' ") {
            local genvars "`genvars' `estvar' "
            file write out "generate `estvar' = ." _n
          }
          file write out "replace `estvar' = `estexp' if `grpvar' == `grpval'" _n
        }
        else if regexm("`line'", "^ *([a-zA-Z0-9_]+) *= *([a-zA-Z0-9_]+) *\- *([a-zA-Z0-9_]+) *; *$") {
          local resvar = regexs(1)
          local depvar = regexs(2)
          local estvar = regexs(3)
          if "`resvar'" == "`estvar'" file write out "replace `resvar' = `depvar' - `estvar'" _n
          else file write out "generate `resvar' = `depvar' - `estvar'" _n
        }
        else if regexm("`line'", "^ *IF *`grpvar' *EQ *([0-9]+) *THEN *DO *; *$") {
          local grpval = regexs(1)
        }
        else if regexm("`line'", "^ *([a-zA-Z0-9_]+) *= *(.+) *; *$") {
          local estvar = regexs(1)
          local estexp = regexs(2)
          if !regexm("`genvars'", " `estvar' ") {
            local genvars "`genvars' `estvar' "
            file write out "generate `estvar' = ." _n
          }
          file write out "replace `estvar' = `estexp' if `grpvar' == `grpval'" _n
        }
        else if regexm("`line'", "^ *IF *([a-zA-Z0-9_]+) *EQ *([0-9]+|.) *THEN *([a-zA-Z0-9_]+) *= *(.+) *; *$") {
          local depvar = regexs(1)
          local depval = regexs(2)
          local resvar = regexs(3)
          local resexp = regexs(4)
          if !regexm("`genvars'", " `resvar' ") {
            local genvars "`genvars' `resvar' "
            file write out "generate `resvar' = ." _n
          }
          file write out "replace `resvar' = `resexp' if `depvar' == `depval'" _n
        }
        else if regexm("`line'", "^ *ELSE *([a-zA-Z0-9_]+) *= *(.+) *; *$") {
          local resvar = regexs(1)
          local resexp = regexs(2)
          file write out "replace `resvar' = `resexp' if `depvar' != `depval'" _n
        }
        file read res line
      }
      file write out `"save "$dataout", replace"' _n
    }
    file close res
    if "$mode" == "" rm "$path.res"
  }
  file close out

  /* run */
  capture run $path.out
  if _rc != 0 global msg "Can't run $path.out"
}

