# metadata function

metadata <- function() {

  # read the data file
  type <- ""  # get the type
  if (grepl(".+\\.[[:alnum:]]+$", datain)) type <- tolower(sub(".+\\.([[:alnum:]]+)$", "\\1", datain))
  if (identical(type, "csv")) {  # csv
    ds <<- read.csv(datain)
  }
  else if (identical(type, "dta")) {  # dta
    library(foreign)
    ds <<- read.dta(datain)
  }
  else if (identical(type, "rda") || identical(type, "rdata")) {  # rda
    ds <<- get(load(datain))
  }
  else if (identical(type, "sav")) {  # sav
    library(foreign)
    ds <<- read.spss(datain, to.data.frame = TRUE)
  }
  else if (identical(type, "txt")) {  # txt
    ds <<- read.delim(datain)
  }
  else if (identical(type, "xpt")) {  # xpt
    library(foreign)
    ds <<- read.xport(datain)
  }
  else {  # default
    ds <<- get(load(paste(datain, "rda", sep=".")))
  }

  f = file(paste(path, "met", sep="."), "w")  # write the metadata file
  writeLines("standard;", con=f)
  writeLines("variables", con=f)
  vnames <- names(ds)
  vnumerics <- lapply(ds, is.numeric)
  vnumeric <- -1
  for (i in 1:length(vnames)) {
    if (vnumerics[[i]] & vnumeric != 1) {
      vnumeric <- 1
      cat("  name=", vnames[i], " type=num;\n", file=f, sep="")
    } else if (!vnumerics[[i]] & vnumeric != 0) {
      vnumeric <- 0
      cat("  name=", vnames[i], " type=char;\n", file=f, sep="")
    } else {
      cat("  name=", vnames[i], ";\n", file=f, sep="")
    }
  }
  close(f)
}

