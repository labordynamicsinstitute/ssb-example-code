# putdata function

import os, re, spss, spssaux, srclib, sys


def putdata(name=None, dir=None, mode=None, dataout=None, impl=None, mult=None):
  msg = None
  if not name:  # name
    msg = "Missing run name."
  else:
    m = re.match(r"^\s*(\w[\w\-]*)\s*$", name)
    if m:
      name = m.group(1)
    else:
      msg = "Run name error."
  if not msg:
    cwd = spssaux.getShow("DIRECTORY")  # spss current working directory
    if not dir:
      path = os.path.join(cwd, name)  # spss current working directory
    else:  # specified directory
      m = re.match(r'^\s*"([~\.\\/:\w\- ]*)"\s*$', dir)   # double quotes
      if m:
        dir = m.group(1).strip()
      else:
        m = re.match(r"^\s*'([~\.\\/:\w\- ]*)'\s*$", dir)   # single quotes
        if m:
          dir = m.group(1).strip()
        else:
          m = re.match(r"^\s*([~\.\\/:\w\-]*)\s*", dir)   # no quotes
          if m:
            dir = m.group(1)
          else:
            msg = "Invalid directory."
      if not msg:
        path = os.path.join(os.path.normpath(dir), name)
  if not msg:  # mode
    if mode:
      m = re.match(r"^\s*(debug|test)\s*$", mode, flags=re.IGNORECASE)
      if m:
        mode = m.group(1).lower()
      else:
        msg = "Mode error."
  if not msg:  # dataout
    if not dataout:
      msg = "Missing dataout."
    else:
      m = re.match(r'^\s*"([~\.\\/:\w\- ]*)"\s*$', dataout)   # double quotes
      if m:
        dataout = m.group(1).strip()
      else:
        m = re.match(r"^\s*'([~\.\\/:\w\- ]*)'\s*$", dataout)   # single quotes
        if m:
          dataout = m.group(1).strip()
        else:
          m = re.match(r"^\s*([~\.\\/:\w\-]*)\s*", dataout)   # no quotes
          if m:
            dataout = m.group(1)
          else:
            msg = "Invalid dataout."
      if not msg:
        if sys.platform.startswith("win"):  # windows
          m = re.match(r"^([a-zA-Z]:|[\\/])", dataout)
        else:  # linux
          m = re.match("^(~|/)", dataout)
        if not m:  # not full path
          dataout = os.path.join(cwd, dataout)  # prefix the current working directory
        dataout = os.path.normpath(dataout)  # normalize the path
  if not msg:  # impl
    if impl:
      m = re.match(r"^\s*(all|\d+)\s*$", impl, flags=re.IGNORECASE)
      if m:
        impl = m.group(1).lower()
      else:
        msg = "Invalid implicate."
  if not msg:  # mult
    if mult:
      m = re.match(r"^\s*(all|\d+)\s*$", mult, flags=re.IGNORECASE)
      if m:
        mult = m.group(1).lower()
      else:
        msg = "Invalid multiple."
  if not msg:
    args = []  # execute putdata
    args.append("/dataout={0}".format(dataout))
    if impl:
      args.append("/impl={0}".format(impl))
    if mult:
      args.append("/mult={0}".format(mult))
    rc = srclib.execute("putdata", path, mode, args)
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
  if msg:
    print msg  # print the error message

