/* write the metadata */

capture use "$datain", clear
if _rc != 0 global msg "Can't open $datain."
else {
  capture file open meta using "$path.met", write replace text
  if _rc != 0 global msg "Can't open $path.met"
}
if "$msg" == "" {

  file write meta "standard;" _n

  /* variables */
  describe , clear replace
  capture outfile name type vallab varlab using "$path.var", comma noquote replace wide
  file open var using "$path.var", read text
  file read var line
  if !r(eof) {
    file write meta "variables" _n
    local oldtype ""
    local oldwidth ""
    while !r(eof) {
      local name ""
      local type ""
      local frame ""
      local label ""
      if regexm("`line'", "^ *([a-zA-Z0-9_]+) *, *([a-z0-9_]+) *, *([a-zA-Z0-9_]*) *,(.*)$") {
        local name = regexs(1)
        local type = regexs(2)
        if substr("`type'", 1, 3) == "str" {
          local width = substr("`type'", 4, .)
          if "`width'" == "L" local width "32767"
          local type "C"
        }
        else if "`type'" == "float" | "`type'" == "double" {
          if "`type'" == "float" local width "4"
          else local width "8"
          local type "F"
        }
        else {
          if "`type'" == "byte" local width "1"
          else if "`type'" == "int" local width "2"
          else local width "4"
          local type "I"
        }
        local frame = regexs(3)
        local label = subinstr(subinstr(trim(regexs(4)), "'", "\'", .), `"""', `""""', .)
        local line "  name=`name'"
        if "`type'" != "`oldtype'" {
          local line "`line' type=`type'"
          local oldtype "`type'"
        }
        if "`width'" != "`oldwidth'" {
          local line "`line' width=`width'"
          local oldwidth "`width'"
        }
        if "`frame'" != "" local line "`line' codeframe=`frame'"
        if "`label'" != "" local line `"`line' label="`label'""'
        file write meta (subinstr(`"`line';"', "\'", "'", .)) _n
      }
      file read var line
    }
  }
  file close var
  if "$mode" == "" rm "$path.var"

  /* codeframes */
  capture label save using "$path.lab", replace
  file open lab using "$path.lab", read text
  file read lab line
  if !r(eof) {
    file write meta "codeframes" _n
    local oldname ""
    local freq = 0
    while !r(eof) {
      if regexm(`"`line'"', "^label define +([a-zA-Z0-9_]+) +(\-?[0-9]+) (.+), modify$") {
        local name = regexs(1)
        local value = regexs(2)
        local label = regexs(3)
        if "`name'" != "`oldname'" {
          if "`oldname'" != "" file write meta "    ;" _n
          file write meta "  name=`name'" _n
          local oldname "`name'"
          local freq = 0
        }
        local freq = `freq' + 1
        if `freq' <= 100 file write meta `"    `value' = ""' `label' `"""' _n
      }
      file read lab line
    }
    file write meta "    ;" _n
  }
  file close lab
  if "$mode" == "" rm "$path.lab"

  file close meta
}

