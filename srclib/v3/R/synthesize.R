# synthesize function

synthesize <- function(name="", dir="", mode="") {
  proc <<- "synthesize"
  msg <<- ""
  path <<- ""
  test <<- ""
  datain <<- ""
  dataout <<- ""
  arguments(name, dir, mode)  # get the arguments
  if (identical(msg, "")) metadata()  # get the metadata
  if (identical(msg, "")) execute("iveset")  # execute iveset
  if (identical(msg, "")) {
    inp <- paste(path, "inp", sep=".")  # get the data
    if (file.exists(inp)) {
      source(inp)
      if (identical(test, "")) file.remove(inp)
      execute("impute")  # execute impute
      if (identical(msg, "")) {
        if (!identical(dataout, "")) {
          execute("putdata", "")  # execute putdata
          if (identical(msg, "")) {
            out <- paste(dataout, "out", sep=".")
            if (file.exists(out)) {  # write the synthesized data
              source(out)
              if (identical(test, "")) {
                file.remove(out)
                file.remove(paste(dataout, "imp", sep="."))
              }
            }
            else  msg <<- "Missing output file."
          }
        }
      }
    }
    else msg <<- "Missing input file."
  }
  if (!identical(msg, "")) {
    log <- paste(path, "log", sep=".")  # copy the log
    if (file.exists(log)) cat(readLines(log), sep="\n")
    cat(msg)  # print the error message
  }
  else {
    lst <- paste(path, "lst", sep=".")  # copy the listing
    if (file.exists(lst)) cat(readLines(lst), sep="\n")
  }
}

