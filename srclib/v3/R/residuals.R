# residuals function

residuals <- function() {
  grpvar <- ""  # build the r command
  estvar <- ""
  resvar <- ""
  genvars <- character()
  type <- ""
  if (grepl(".+\\.[[:alnum:]]+$", datain)) type <- tolower(sub(".+\\.([[:alnum:]]+)$", "\\1", datain))
  if (identical(type, "rda") || identical(type, "rdata")) {
    cmd <- paste("\nds <- get(load(\"", datain, "\"))\n", sep="")
  } else cmd <- paste("\nds <- get(load(\"", datain, ".rda\"))\n", sep="")
  cmd <- paste(cmd, "attach(ds)\n", sep="")
  res <- paste(path, "res", sep=".")
  f <- file(res, "r")  # read the residuals file
  while (length(line <- readLines(f, n = 1, warn = FALSE)) > 0) {
    if (identical(grpvar, "") && grepl("^\\s*[[:alnum:]]+\\s*=\\s*[[:digit:]]+\\s*;*\\s*$", line)) {
      grpvar <- sub("^\\s*([[:alnum:]]+)\\s*=\\s*[[:digit:]]+\\s*;*\\s*$", "\\1", line)
      grpval <- sub("^\\s*[[:alnum:]]+\\s*=\\s*([[:digit:]]+)\\s*;*\\s*$", "\\1", line)
      cmd <- paste(cmd, "ds$", grpvar, " <- ", grpval, "\n", sep="")
    }
    else if (grepl("^\\s*IF\\s+[[:alnum:]]+\\s+EQ\\s+[[:digit:]]+\\s*THEN*\\s*$", line, ignore.case=TRUE)) {
      grpvar <- sub("^\\s*IF\\s+([[:alnum:]]+)\\s+EQ\\s+[[:digit:]]+\\s*THEN*\\s*$", "\\1", line, ignore.case=TRUE)
      grpval <- sub("^\\s*IF\\s+[[:alnum:]]+\\s+EQ\\s+([[:digit:]]+)\\s*THEN*\\s*$", "\\1", line, ignore.case=TRUE)
      cmd <- paste(cmd, "ds$", grpvar, " <- ifelse(ds$", grpvar, " == ", grpval, ", ", sep="")
    }
    else if (grepl(paste("^\\s*IF\\s+[[:alnum:]]+\\s+IN\\([[:digit:],]+\\)\\s+THEN\\s+", grpvar, "\\s*=\\s*[[:digit:]]+\\s*;*\\s*$",
        sep=""), line, ignore.case=TRUE)) {
      spltvar <- sub(paste("^\\s*IF\\s+([[:alnum:]]+)\\s+IN\\([[:digit:],]+\\)\\s+THEN\\s+", grpvar, "\\s*=\\s*[[:digit:]]+\\s*;*\\s*$",
        sep=""), "\\1", line, ignore.case=TRUE)
      spltvals <- sub(paste("^\\s*IF\\s+[[:alnum:]]+\\s+IN\\(([[:digit:],]+)\\)\\s+THEN\\s+", grpvar, "\\s*=\\s*[[:digit:]]+\\s*;*\\s*$",
        sep=""), "\\1", line, ignore.case=TRUE)
      grpval <- sub(paste("^\\s*IF\\s+[[:alnum:]]+\\s+IN\\([[:digit:],]+\\)\\s+THEN\\s+", grpvar, "\\s*=\\s*([[:digit:]]+)\\s*;*\\s*$",
        sep=""), "\\1", line, ignore.case=TRUE)
      if (identical(grpval, "2")) {
        cmd <- paste(cmd, "ds$", grpvar, " <- ifelse(", spltvar, " %in% c(", spltvals, "), ", grpval, sep="")
      } else  cmd <- paste(cmd, "ifelse(", spltvar, " %in% c(", spltvals, "), ", grpval, sep="")
    }
    else if (grepl(paste("^\\s*ELSE\\s+", grpvar, "\\s*=\\s*[[:digit:]]+\\s*;*\\s*$", sep=""), line, ignore.case=TRUE)) {
      grpval <- sub(paste("^\\s*ELSE\\s+", grpvar, "\\s*=\\s*([[:digit:]]+)\\s*;*\\s*$", sep=""), "\\1", line, ignore.case=TRUE)
      if (identical(grpval, "3")) {
        cmd <- paste(cmd, ", ", grpval, ")\n", sep="")
      } else cmd <- paste(cmd, ", ", grpval, "), ds$", grpvar, ")\n", sep="")
      ifelseclose <- "))\n"
    }
    else if (grepl(paste("^\\s*IF\\s+", grpvar, "\\s+EQ\\s+[[:digit:]]+\\s+THEN\\s+[[:alnum:]]+\\s*=\\s*[[:alnum:]_\\.*+ -]+\\s*;*\\s*$", sep=""),
      line, ignore.case=TRUE)) {
      grpval <- sub(paste("^\\s*IF\\s+", grpvar, "\\s+EQ\\s+([[:digit:]]+)\\s+THEN\\s+[[:alnum:]]+\\s*=\\s*[[:alnum:]_\\.*+ -]+\\s*;*\\s*$", sep=""),
        "\\1", line, ignore.case=TRUE)
      estvar <- sub(paste("^\\s*IF\\s+", grpvar, "\\s+EQ\\s+[[:digit:]]+\\s+THEN\\s+([[:alnum:]]+)\\s*=\\s*[[:alnum:]_\\.*+ -]+\\s*;*\\s*$", sep=""),
        "\\1", line, ignore.case=TRUE)
      estexp <- sub(paste("^\\s*IF\\s+", grpvar, "\\s+EQ\\s+[[:digit:]]+\\s+THEN\\s+[[:alnum:]]+\\s*=\\s*([[:alnum:]_\\.*+ -]+)\\s*;*\\s*$", sep=""),
        "\\1", line, ignore.case=TRUE)
      if (!(estvar %in% genvars)) {
        genvars <- c(genvars, estvar)
        cmd <- paste(cmd, "ds$", estvar, " <- as.double(NA)\n", sep = "")
      }
      cmd <- paste(cmd, "ds$", estvar, " <- ", "ifelse(ds$", grpvar, " == ", grpval, ", ", estexp, ", ds$", estvar, ")\n", sep="")
    }
    else if (grepl("^\\s*[[:alnum:]]+\\s*=\\s*[[:alnum:]]+\\s*-\\s*[[:alnum:]]+\\s*;*\\s*$", line)) {
      resvar <- sub("^\\s*([[:alnum:]]+)\\s*=\\s*[[:alnum:]]+\\s*-\\s*[[:alnum:]]+\\s*;*\\s*$", "\\1", line)
      depvar <- sub("^\\s*[[:alnum:]]+\\s*=\\s*([[:alnum:]]+)\\s*-\\s*[[:alnum:]]+\\s*;*\\s*$", "\\1", line)
      estvar <- sub("^\\s*[[:alnum:]]+\\s*=\\s*[[:alnum:]]+\\s*-\\s*([[:alnum:]]+)\\s*;*\\s*$", "\\1", line)
      cmd <- paste(cmd, "ds$", resvar, " <- ", depvar, " - ds$", estvar, "\n", sep="")
    }
    else if (grepl(paste("^\\s*IF\\s+", grpvar, "\\s+EQ\\s+[[:digit:]]+\\s+THEN\\s+DO\\s*;*\\s*$", sep=""), line, ignore.case=TRUE)) {
      grpval <- sub(paste("^\\s*IF\\s+", grpvar, "\\s+EQ\\s+([[:digit:]]+)\\s+THEN\\s+DO\\s*;*\\s*$", sep=""), "\\1", line, ignore.case=TRUE)
    }
    else if (grepl("^\\s*[[:alnum:]]+\\s*=\\s*[[:digit:]\\.*+ -]+\\s*;*\\s*$", line)) {
      estvar <- sub("^\\s*([[:alnum:]]+)\\s*=\\s*[[:digit:]\\.*+ -]+\\s*;*\\s*$", "\\1", line)
      estexp <- sub("^\\s*[[:alnum:]]+\\s*=\\s*([[:digit:]\\.*+ -]+)\\s*;*\\s*$", "\\1", line)
      if (!(estvar %in% genvars)) {
        genvars <- c(genvars, estvar)
        cmd <- paste(cmd, "ds$", estvar, " <- as.double(NA)\n", sep = "")
      }
      cmd <- paste(cmd, "ds$", estvar, " <- ", "ifelse(ds$", grpvar, " == ", grpval, ", ", estexp, ", ds$", estvar, ")\n", sep="")
    }
    else if (grepl("^\\s*END\\s*;*\\s*$", line, ignore.case=TRUE)) {
    }
    else if (grepl("^\\s*IF\\s+[[:alnum:]]+\\s+EQ\\s+[[:digit:]]+\\s+THEN\\s+[[:alnum:]]+\\s*=\\s*[[:digit:]\\.*+ -]+\\s*;*\\s*$", line,
      ignore.case=TRUE)) {
      depvar <- sub("^\\s*IF\\s+([[:alnum:]]+)\\s+EQ\\s+[[:digit:]]+\\s+THEN\\s+[[:alnum:]]+\\s*=\\s*[[:digit:]\\.*+ -]+\\s*;*\\s*$", "\\1", line,
        ignore.case=TRUE)
      depval <- sub("^\\s*IF\\s+[[:alnum:]]+\\s+EQ\\s+([[:digit:]]+)\\s+THEN\\s+[[:alnum:]]+\\s*=\\s*[[:digit:]\\.*+ -]+\\s*;*\\s*$", "\\1", line,
        ignore.case=TRUE)
      resvar <- sub("^\\s*IF\\s+[[:alnum:]]+\\s+EQ\\s+[[:digit:]]+\\s+THEN\\s+([[:alnum:]]+)\\s*=\\s*[[:digit:]\\.*+ -]+\\s*;*\\s*$", "\\1", line,
        ignore.case=TRUE)
      resexp <- sub("^\\s*IF\\s+[[:alnum:]]+\\s+EQ\\s+[[:digit:]]+\\s+THEN\\s+[[:alnum:]]+\\s*=\\s*([[:digit:]\\.*+ -]+)\\s*;*\\s*$", "\\1", line,
        ignore.case=TRUE)
      if (!(resvar %in% genvars)) {
        genvars <- c(genvars, resvar)
        cmd <- paste(cmd, "ds$", resvar, " <- as.double(NA)\n", sep = "")
      }
      cmd <- paste(cmd, "ds$", resvar, " <- ", "ifelse(ds$", depvar, " == ", depval, ", ", resexp, ", ds$", resvar, ")\n", sep="")
    }
    else if (grepl("^\\s*IF\\s+[[:alnum:]]+\\s+EQ\\s+[[:digit:]\\.]+\\s+THEN\\s+[[:alnum:]]+\\s*=\\s*1\\s*-\\s*[[:alnum:]]+\\s*;*\\s*$", line,
      ignore.case=TRUE)) {
      depvar <- sub("^\\s*IF\\s+([[:alnum:]]+)\\s+EQ\\s+[[:digit:]\\.]+\\s+THEN\\s+[[:alnum:]]+\\s*=\\s*1\\s*-\\s*[[:alnum:]]+\\s*;*\\s*$", "\\1", line,
        ignore.case=TRUE)
      depval <- sub("^\\s*IF\\s+[[:alnum:]]+\\s+EQ\\s+([[:digit:]\\.]+)\\s+THEN\\s+[[:alnum:]]+\\s*=\\s*1\\s*-\\s*[[:alnum:]]+\\s*;*\\s*$", "\\1", line,
        ignore.case=TRUE)
      resvar <- sub("^\\s*IF\\s+[[:alnum:]]+\\s+EQ\\s+[[:digit:]\\.]+\\s+THEN\\s+([[:alnum:]]+)\\s*=\\s*1\\s*-\\s*[[:alnum:]]+\\s*;*\\s*$", "\\1", line,
        ignore.case=TRUE)
      if (identical(depval, ".")) {
        cmd <- paste(cmd, "ds$", resvar, " <- ", "ifelse(lapply(ds$", depvar, ", is.na), 1 - ds$", resvar, ", - ds$", resvar, ")\n", sep="")
      }
      else {
        cmd <- paste(cmd, "ds$", resvar, " <- ", "ifelse(lapply(ds$", depvar, ", is.na), - ds$", resvar, ", ifelse(ds$", depvar, " == ", depval, ", 1 - ds$", resvar,
          ", - ds$", resvar, "))\n", sep="")
      }
    }
    else if (grepl("^\\s*ELSE\\s+[[:alnum:]]+\\s*=\\s*[[:digit:]\\.*+ -]+\\s*;*\\s*$", line, ignore.case=TRUE)) {
      resvar <- sub("^\\s*ELSE\\s+([[:alnum:]]+)\\s*=\\s*[[:digit:]\\.*+ -]+\\s*;*\\s*$", "\\1", line, ignore.case=TRUE)
      resexp <- sub("^\\s*ELSE\\s+[[:alnum:]]+\\s*=\\s*([[:digit:]\\.*+ -]+)\\s*;*\\s*$", "\\1", line, ignore.case=TRUE)
      cmd <- paste(cmd, " else ", resvar, " <- ", resexp, "\n", sep="")
    }
    else if (grepl("^\\s*ELSE\\s+[[:alnum:]]+\\s*=\\s*-\\s*[[:alnum:]]+\\s*;*\\s*$", line, ignore.case=TRUE)) {
    }
    else {
      cat("Unrecognized line:", line, sep=" ")
      break
    }
  }
  close(f)
  type <- ""
  if (grepl(".+\\.[[:alnum:]]+$", dataout)) type <- tolower(sub(".+\\.([[:alnum:]]+)$", "\\1", dataout))
  if (identical(type, "rda") || identical(type, "rdata")) {
    cmd <- paste(cmd, "save(ds, file=\"", dataout, "\")\n", sep="")
  } else cmd <- paste(cmd, "save(ds, file=\"", dataout, ".rda\")\n\n", sep="")
  out <- paste(path, "out", sep=".")
  f <- file(out, "wb")  # write the residuals file
  writeChar(cmd, f, nchars = nchar(cmd, type = "chars"), eos = NULL)
  close(f)
  source(out)
}

