# bbdesign function

bbdesign <- function(name="", dir="", mode="") {
  proc <<- "bbdesign"
  msg <<- ""
  path <<- ""
  test <<- ""
  datain <<- ""
  dataout <<- ""
  arguments(name, dir, mode)  # get the arguments
  if (identical(msg, "")) metadata()  # get the metadata
  if (identical(msg, "")) execute("bbdesign", "/setup")  # execute bbdesign setup
  if (identical(msg, "")) {
    inp <- paste(path, "inp", sep=".")  # get the data
    if (file.exists(inp)) {
      source(inp)
      if (identical(test, "")) file.remove(inp)
      execute("bbdesign")  # execute bbdesign go
      if (identical(msg, "")) {
        out <- paste(path, "out", sep=".")  # write the samples
        if (file.exists(out)) {
          source(out)
          if (identical(mode, "")) file.remove(out)
        }
      }
    }
    else msg <- "Missing input file."
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

