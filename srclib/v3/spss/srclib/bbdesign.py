# bbdesign function

import srclib
import os, spss

def bbdesign(name=None, dir=None, mode=None):
  proc = "bbdesign"
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
  args = []  # execute putdata
  args.append("/setup")
  rc = srclib.execute("bbdesign", path, mode, args)  # execute bbdesign setup
  if rc != 0:
    msg = "Abnormal termination of bbdesign"
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
      rc = srclib.execute("bbdesign", path, mode, None)  # execute bbdesign go
      if rc != 0:
        msg = "Abnormal termination of bbdesign"
      else:
        if os.path.exists(path + ".out"):  # write the samples
          f = open(path + ".out", "r")
          cmd = f.read()
          f.close()
          spss.Submit(cmd)  # execute the command
          if not mode:
            os.remove(path + ".out")
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

