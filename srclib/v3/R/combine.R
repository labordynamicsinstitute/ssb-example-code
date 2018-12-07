
# function to combine R datasets

combine <- function(name="", dir="", mode="") {
  proc <<- "combine"
  msg <<- ""
  path <<- ""
  setup <<- ""
  test <<- ""
  datain <<- ""
  dataout <<- ""
  vars <<- as.null()
  arguments(name, dir, mode)  # get the arguments

  if (identical(msg, "")) {  # datain
    datain <<- gsub("(\\s+\"[^\"]+\"|\\s+'[^']+'|\\s+[^\\s]+)", ",\\1", datain)  # add commas
    datain <<- gsub("(\"|')", "", datain)  # remove quotes
    datain <<- gsub("(\\s*,\\s*)", ",", datain)  # remove spaces around commas
    datain <<- strsplit(datain, ",")  # convert to list
    datain <<- datain[[1]]
  }

  if (identical(msg, "")) {  # variable list
    if (grepl("(^|;)\\s*var\\s+[^;]+;", setup, ignore.case=TRUE)) {
      vars <<- sub("^(.*;)*\\s*var\\s+([^;]+);.*$", "\\2", setup, ignore.case=TRUE)  # variable names
      vars <<- sub("\\s\\s+", " ", sub("^\\s+", "", sub("\\s+$", "", vars)))  # trim
      if (!grepl("^[[:alnum:]_ -]+$", vars))  msg <<- "Invalid variable list."
      else {
        vars <<- unlist(strsplit(vars, " "))  # convert to vector
      }
    }
  }

  if (identical(msg, "")) {  # combine the files
    beg <<- 0
    dslist = lapply(datain, function(x) { dsread(x) })
    ds <<- Reduce(function(x, y) { merge(x, y, all=TRUE) }, dslist)

    if (!is.null(vars)) {  # variable list
      ds <<- ds[vars]  # subset
    }

    # save dataout
    if (!grepl("\\.rda$", dataout, ignore.case=TRUE)) dataout <- paste(dataout, "rda", sep=".")  # add the suffix
    save(ds, file=dataout)  # save
  }
}

dsread <- function(file) {  # read the data file
  type <- ""  # get the type
  if (grepl(".+\\.[[:alnum:]]+$", file)) type <- tolower(sub(".+\\.([[:alnum:]]+)$", "\\1", file))
  if (identical(type, "csv")) {  # csv
    ds <- read.csv(file)
  }
  else if (identical(type, "dta")) {  # dta
    library(foreign)
    ds <- read.dta(file)
  }
  else if (identical(type, "rda") || identical(type, "rdata")) {  # rda
    ds <- get(load(file))
  }
  else if (identical(type, "sav")) {  # sav
    library(foreign)
    ds <- read.spss(file, to.data.frame = TRUE)
  }
  else if (identical(type, "txt")) {  # txt
    ds <- read.delim(file)
  }
  else if (identical(type, "xpt")) {  # xpt
    library(foreign)
    ds <- read.xport(file)
  }
  else {  # default
    ds <- get(load(paste(file, "rda", sep=".")))
  }
  ds$OBS_ <- 1 : nrow(ds)  # add observation number in the combined dataset
  ds$OBS_ <- ds$OBS_ + beg
  beg <<- beg + nrow(ds)
  return (ds)
}

