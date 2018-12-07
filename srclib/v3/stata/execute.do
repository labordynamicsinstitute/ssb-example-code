/* execute a command */

/* program */
local prog "`1'"
if c(os) == "Windows" {
  if "$bin" != "" local prog "$bin\\`prog'"
  local prog "`prog'.exe"
}
else {
  if "$bin" != "" local prog "$bin/`prog'"
}
if strpos("`prog'", " ") local prog `""`prog'""'

/* args */
local args "$path.set"
if strpos("`args'", " ") local args `""`args'""'
local args "`args' /stata"
if "$mode" != "" local args "`args' /debug"
if c(mode) == "batch" local args "`args' /batch"
if "$args" != "" local args "`args' $args"

/* execute */
/* display `"`prog' `args'"' */
capture shell `prog' `args'

/* error */
if _rc > 0 global msg "Abnormal termination of `1'. Check log."

