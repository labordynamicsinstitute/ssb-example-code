# putdata function

putdata <- function(name="", dir="", mode="", dataout="", impl="", mult="") {
  msg <<- ""
  path <<- ""
  test <<- ""
  name <<- sub("^\\s+", "", sub("\\s+$", "", name))  # name
  if (identical(name, "")) msg <<- "Missing name."
  else {
    if (!grepl("^[[:alnum:]][[:alnum:]_-]*$", name)) msg <<- "Invalid name."
  }
  if (identical(msg, "")) {  # path
    dir <- sub("^\\s+", "", sub("\\s+$", "", dir))
    if (identical(dir, "")) path <<- name  # no directory specified, use just name
    else {  # specified directory
      if (grepl('^"[^"]*"$', dir)) dir <<- sub('^"\\s*(.*)\\s*"$', "\\1", dir)  # double quotes
      else if (grepl("^'[^']*'$", dir)) dir <<- sub("^'\\s*(.*)\\s*'$", "\\1", dir)  # single quotes
      if (!grepl("^[~\\.\\\\/:[:alnum:]_ -]+$", dir))  msg <<- "Invalid directory."
      else path <<- file.path(dir, name, fsep=.Platform$file.sep)
     }
  }
  if (identical(msg, "")) {  # test
    test <<- sub("^\\s+", "", sub("\\s+$", "", mode))
    if (!identical(test, "")) {
      if (!grepl("^(debug|test)$", test, ignore.case=TRUE)) msg <<- "Invalid test."
    }
  }
  if (identical(msg, "")) {   # dataout
  dataout <<- sub("^\\s+", "", sub("\\s+$", "", dataout))
  if (identical(dataout, "")) msg <<- "Missing dataout."
  else {
    if (grepl('^"[^"]*"$', dataout)) dataout <<- sub('^"\\s*(.*)\\s*"$', "\\1", dataout)  # double quotes
    else if (grepl("^'[^']*'$", dataout)) dataout <<- sub("^'\\s*(.*)\\s*'$", "\\1", dataout)  # single quotes
    if (!grepl("^[~\\.\\\\/:[:alnum:]_ -]+$", dataout))  msg <<- "Invalid dataout."
    }
  }
  if (identical(msg, "")) {   # impl
    impl <<- sub("^\\s+", "", sub("\\s+$", "", impl))
    if (!identical(impl, "")) {
      if (!grepl("^(all|[[:digit:]]+)$", impl, ignore.case=TRUE))  msg <<- "Invalid implicate."
    }
  }
  if (identical(msg, "")) {   # mult
    mult <<- sub("^\\s+", "", sub("\\s+$", "", mult))
    if (!identical(mult, "")) {
      if (!grepl("^(all|[[:digit:]]+)$", mult, ignore.case=TRUE))  msg <<- "Invalid multiple."
    }
  }
  if (identical(msg, "")) {  # execute putdata
    args <- paste("/dataout=", dataout, sep="")
    if (regexpr(" ", args, fixed=TRUE) >= 0) args <- dQuote(args)
    if (!identical(impl, "")) args <- paste(args, " /impl=", impl, sep="")
    if (!identical(mult, "")) args <- paste(args, " /mult=", mult, sep="")
    execute("putdata", args)
    if (identical(msg, "")) {  # write the imputed data
      out <- paste(dataout, "out", sep=".")
      if (file.exists(out)) {
        source(out)
        if (identical(test, "")) {
          file.remove(out)
          file.remove(paste(dataout, "imp", sep="."))
        }
      }
      else  msg <<- "Missing output file."
    }
  }
  if (!identical(msg, "")) {
    cat(msg)  # print the error message
  }
}

