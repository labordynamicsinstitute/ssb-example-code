# execute function

execute <- function(prog="", args="") {
  cmd <- file.path(srclib, "..", "bin", prog, fsep=.Platform$file.sep)
  if (regexpr(" ", srclib, fixed=TRUE) >= 0) 
    cmd <- dQuote(cmd)
  if (regexpr(" ", path, fixed=TRUE) < 0) cmd <- paste(cmd, paste(path, ".set", sep=""), sep=" ")
  else cmd <- paste(cmd, dQuote(paste(path, ".set", sep="")), sep=" ")
  cmd <- paste(cmd, "/r", sep=" ")
  if (!identical(test, "")) cmd <- paste(cmd, "/debug", sep=" ")
  if (!identical(args, "")) cmd <- paste(cmd, args, sep=" ")
  if (system(cmd) != 0)
    msg <<- paste("Abnormal termination of ", prog)
}

