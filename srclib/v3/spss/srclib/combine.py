# combine function

import srclib
import re, spss, sys

def combine(name=None, dir=None, mode=None):

  proc = "combine"

  args = srclib.arguments(name, dir, mode, proc)  # get the arguments
  if not args:
    return 1
  path = args[0]
  datain = args[1]
  dataout = args[2]
  setup = args[3]

  var = None  # variable list
  m = re.search(r"(^|;)\s*var[\w]*\s+([^;]+);", setup, flags=re.IGNORECASE)  # supplied?
  if m:
    var = m.group(2).strip()
    var = var.strip()
    if not re.match(r"^[\w -]+$", var):  # check it
      sys.Exit("Invalid variable list.")  # invalid

  filenames = datain.strip()  # build the file names list
  filelist = []
  while filenames != "":  # loop through file names
    m = re.match(r'^"([^"]+)"(\s+.*)?$', filenames)  # double quotes
    if not m:
      m = re.match(r"^'([^']+)'(\s+.*)?$", filenames)  # single quotes
      if not m:
        m = re.match(r"^([^\s]+)(\s+.*)?$", filenames)  # no quotes
    if m.group(2):
      filenames = m.group(2).strip()  # trim the remaining names
    else:
      filenames = ""
    file = m.group(1).strip()  # extract the file name
    m = re.match(r"^[~\.\\/:\w -]+$", file)  # check it
    if not m:
      sys.Exit("Invalid datain.")  # invalid
    if not re.match(r"\.sav$", file, flags=re.IGNORECASE):  # add .sav
      file += ".sav"
    filelist.append(file)  # append it to the list

  #dataout
  if not re.match(r"\.sav$", dataout, flags=re.IGNORECASE):  # add .sav
    dataout += ".sav"

  beg = 0  # merge the files
  count = 0
  for file in filelist:  # loop through the input files
    if count > 0:  # not the first file
      cmd = "save outfile='{0}'.\n".format(dataout)  # save the intermediate file
      spss.Submit(cmd)
    cmd = "get file='{0}'.\n".format(file)  # get the input file
    spss.Submit(cmd)
    cmd = "compute OBS_ = $casenum.\n"  # compute the observation number
    cmd += "compute OBS_ = OBS_ + {0}.\n".format(beg)
    cmd += "execute.\n"
    spss.Submit(cmd)
    beg += spss.GetCaseCount()  # increment the case count
    if count > 0:  # not the first file
      cmd = "match files file=* /file='{0}' /by OBS_.\n".format(dataout)  # match the input and intermediate files
      spss.Submit(cmd)
    count += 1

  if var:  # variable list
    cmd = "save outfile='{0}' /keep={1}.\n".format(dataout, var)  # subset variables and save
  else:
    cmd = "save outfile='{0}'.\n".format(dataout)  # save the output file
  spss.Submit(cmd)

