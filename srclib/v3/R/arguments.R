# arguments function

arguments <- function(name, dir, mode) {
  name <<- sub("^\\s+", "", sub("\\s+$", "", name))  # name
  if (identical(name, "")) msg <<- "Missing name."
  else {
    if (!grepl("^[[:alnum:]][[:alnum:]_ -]*$", name)) msg <<- "Invalid name."
  }
  if (identical(msg, "")) {  # path
    dir <- sub("^\\s+", "", sub("\\s+$", "", dir))
    if (identical(dir, "")) path <<- name  # no directory specified, use just name
    else {  # specified directory
      if (grepl('^"([^"]*)"$', dir)) {  # double quotes
        dir <- sub('^"([^"]*)"$', "\\1", dir)
        dir <- sub("^\\s+(.*)", "\\1", sub("\\s+$", "", dir))
      }
      else if (grepl("^'([^']*)'$", dir)) {  # single quotes
        dir <- sub("^'([^']*)'$", "\\1", dir)
        dir <- sub("^\\s+(.*)", "\\1", sub("\\s+$", "", dir))
      }
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
  if (identical(msg, "")) {  # get the setup
    setup <<- ""
    set <- paste(path, "set", sep=".")
    if (file.exists(set)) setup <<- readChar(set, file.info(set)$size)
    if (identical(setup, "")) msg <<- "Missing setup."
  }
  if (identical(msg, "")) {  # datain
    if (grepl("(^|;)\\s*datain\\s+[^;]+;", setup, ignore.case=TRUE)) {
      datain <<- sub("^(.*;)*\\s*datain\\s+([^;]+);.*$", "\\2", setup, ignore.case=TRUE)  # files
      datain <<- sub("^\\s+", "", sub("\\s+$", "", datain))  # trim
      if (identical(proc, "combine")) {  # combine
        if (!grepl("^[\"'~\\.\\\\/:[:alnum:]_ -]+$", datain))  msg <- "Invalid datain."
      }
      else {  # other prodedures
        datain <<- gsub('\\s+"([^"]*)"', "", datain)  # remove double quoted names after the first
        datain <<- gsub("\\s+'([^']*)'", "", datain)  # ditto single quoted
        datain <<- gsub("\\s+([^\\s]*)", "", datain)  # ditto unquoted
        if (grepl('^"[^"]*"$', datain)) datain <<- sub('^"\\s*(.*)\\s*"$', "\\1", datain)  # remove double quotes
        else if (grepl("^'[^']*'$", datain)) datain <<- sub("^'\\s*(.*)\\s*'$", "\\1", datain)  # remove single quotes
        if (!grepl("^[~\\.\\\\/:[:alnum:]_ -]+$", datain))  msg <<- "Invalid datain."  # check name
      }
    }
    else msg <<- "Missing datain."
  }
  if (identical(msg, "")) {  # dataout
    if (grepl("(^|;)\\s*dataout\\s+[^;]+;", setup, ignore.case=TRUE)) {
      dataout <<- sub("^(.*;)*\\s*dataout\\s+([^;]+);.*$", "\\2", setup, ignore.case=TRUE)  # file
      if (grepl("\\s+(all|con|concat|concatenate)\\s*$", dataout, ignore.case=TRUE)) {  # remove all or concatenate
        dataout <<- sub("\\s+(all|con|concat|concatenate)\\s*$", "", dataout, ignore.case=TRUE)
      }
      dataout <<- sub("^\\s+", "", sub("\\s+$", "", dataout))  # trim
      if (grepl('^"[^"]*"$', dataout)) dataout <<- sub('^"\\s*(.*)\\s*"$', "\\1", dataout)  # remove double quotes
      else if (grepl("^'[^']*'$", dataout)) dataout <<- sub("^'\\s*(.*)\\s*'$", "\\1", dataout)  # remove single quotes
      if (!grepl("^[~\\.\\\\/:[:alnum:]_ -]+$", dataout))  msg <<- "Invalid dataout."  # check name
    }
    else if (identical(proc, "combine")) msg <<- "Missing dataout."
  }
}

