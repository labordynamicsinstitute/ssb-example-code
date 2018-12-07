# regress function

import srclib
import os, spss, struct

def regress(name=None, dir=None, mode=None):
  proc = "regress"
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
  rc = srclib.execute("iveset", path, mode, None)  # execute iveset
  if rc != 0:
    msg = "Abnormal termination of iveset"
  else:
    if not os.path.exists(path + ".ctl"):  # get the method
      msg = "Missing " + path + ".ctl file"
    else:
      f = open(path + ".ctl", "rb")
      method = struct.unpack('i', f.read(4))[0]
      f.close()
      if not os.path.exists(path + ".inp"):  # get the data
        msg = "Missing " + path + ".inp file"
      else:
        f = open(path + ".inp", "r")
        cmd = f.read()
        f.close()
        spss.Submit(cmd)
        if not mode:
          os.remove(path + ".inp")
        if method & 1:  # imputation
          rc = srclib.execute("impute", path, mode, None)  # execute impute
          if rc != 0:
            msg = "Abnormal termination of impute"
          else:
            if dataout:  # output the imputed data
              rc = srclib.execute("putdata", path, mode, None)  # execute putdata
              if rc != 0:
                msg = "Abnormal termination of putdata"
              else:
                if not os.path.exists(dataout + ".out"):  # write the imputed data
                  msg = "Missing " + dataout + ".out file"
                else:
                  f = open(dataout + ".out", "r")
                  cmd = f.read()
                  f.close()
                  spss.Submit(cmd)  # execute the command
                  if not mode:
                    os.remove(dataout + ".imp")
                    os.remove(dataout + ".out")
            if not msg:
              rc = srclib.execute("setdata", path, mode, None)  # execute setdata
              if rc != 0:
                msg = "Abnormal termination of setdata"
        else:  # no imputation
          if os.path.exists(path + ".agg"):  # remove the .agg file
            os.remove(path + ".agg")
        if not msg:
          rc = srclib.execute("regress", path, mode, None)  # execute regress
          if rc != 0:
            msg = "Abnormal termination of regress"
          else:
            if os.path.exists(path + ".out"):  # write the estimates, etc.
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

