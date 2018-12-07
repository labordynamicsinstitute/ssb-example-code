/* display the results */

set more off
if "$msg" == "" {
  capture confirm file "$path.lst"
  if _rc == 0 {
    set output proc
    type "$path.lst"
    set output error
    }
}
else {
  capture confirm file "$path.log"
  if _rc == 0 {
    set output proc
    type "$path.lst"
    set output error
    }
  set output proc
  display "$msg"
  set output error
}

