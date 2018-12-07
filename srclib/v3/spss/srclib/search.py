# search function

import srclib
import os, spss

def search(name=None, dir=None, mode=None):
  proc = "search"
  args = srclib.arguments(name, dir, mode, proc)  # get the arguments
  if not args:
    return 1
  path = args[0]
  datain = args[1]
  dataout = args[2]
  rc = srclib.metadata(datain, path)  # get the metadata
  if rc != 0:
    return rc
  msg = None
  rc = srclib.execute("srchset", path, mode, None)  # execute srchset
  if rc != 0:
    msg = "Abnormal termination of srchset"
  else:
    if not os.path.exists(path + ".inp"):  # get the data
      msg = "Missing " + path + ".inp file"
    else:
      f = open(path + ".inp", "r")
      cmd = f.read()
      f.close()
      spss.Submit(cmd)
      if not mode:
        os.remove(path + ".inp")
      rc = srclib.execute("search", path, mode, None)  # execute search
      if rc != 0:
        msg = "Abnormal termination of search"
      else:
        if dataout:
          srclib.residuals(datain, dataout, path, mode)  # output the residuals
  if msg:
    if os.path.exists(path + ".log"):  # copy the log
      print
      f = open(path + ".log", "r")
      print f.read()
      f.close()
    print msg  # print the error message
  else:
    if not os.path.exists(path + ".lst"):  # copy the listing
      msg = "Missing " + path + ".lst file"
    else:
      print
      f = open(path + ".lst", "r")
      print f.read()
      f.close()

