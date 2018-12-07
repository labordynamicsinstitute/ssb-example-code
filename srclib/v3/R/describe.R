# describe function

describe <- function(name="", dir="", mode="") {
  proc <<- "describe"
  msg <<- ""
  path <<- ""
  test <<- ""
  datain <<- ""
  dataout <<- ""
  arguments(name, dir, mode)  # get the arguments
  if (identical(msg, "")) metadata()  # get the metadata
  if (identical(msg, "")) execute("iveset")  # execute iveset
  if (identical(msg, "")) {
    ctl <- paste(path, "ctl", sep=".")  # get the method
    if (file.exists(ctl)) {
      f <- file(ctl, "rb")
      method <- readBin(f, integer())
      close(f)
      inp <- paste(path, "inp", sep=".")  # get the data
      if (file.exists(inp)) {
        source(inp)
        if (identical(test, "")) file.remove(inp)
        if (method == 5) {  # imputation
          execute("impute")  # execute impute
          if (identical(msg, "")) {
            if (!identical(dataout, "")) {
              execute("putdata")  # execute putdata
              if (identical(msg, "")) {
                out <- paste(path, "out", sep=".")
                if (file.exists(out)) {  # write the imputed data
                  source(out)
                  if (identical(test, "")) {
                    file.remove(out)
                    file.remove(paste(path, "imp", sep="."))
                  }
                }
                else  msg <<- "Missing output file."
              }
            }
            if (identical(msg, "")) {  # execute setdata
              execute("setdata")
            }
          }
        }
        if (identical(msg, "")) {
          execute("describe")  # execute describe
          if (identical(msg, "")) {
            out <- paste(path, "out", sep=".")  # write the estimates
            if (file.exists(out)) {
              source(out)
              if (identical(mode, "")) file.remove(out)
            }
          }
        }
      }
      else msg <<- "Missing input file."
    }
    else msg <<- "Missing control file."
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

