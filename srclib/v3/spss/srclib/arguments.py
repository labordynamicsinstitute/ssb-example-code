# arguments function

import os, re, spssaux, sys

def arguments(name, dir, mode, proc):
  msg = None
  if not name:  # name
    msg = "Missing run name."
  else:
    name = name.strip()
    m = re.match(r"^[\w -]+$", name)  # check name
    if not m:
      msg = "Invalid name."
  if not msg:
    cwd = spssaux.getShow("DIRECTORY")  # spss current working directory
    if not dir:
      path = os.path.join(cwd, name)  # spss current working directory
    else:  # specified directory
      dir = dir.strip()
      m = re.match(r'^"([^"]+)"$', dir)  # remove double quotes
      if m:
        dir = m.group(1).strip()
      else:
        m = re.match(r"^'([^']+)'$", dir) # remove single quotes
        if m:
          dir = m.group(1).strip()
      m = re.match(r"^[~\.\\/:\w -]+$", dir)  # check dir
      if not m:
        msg = "Invalid directory."
      if not msg:
        path = os.path.join(os.path.normpath(dir), name)
  if not msg:
    if mode:
      mode = mode.strip()
      if not re.match(r"^(debug|test)$", mode, flags=re.IGNORECASE):  # mode
        msg = "Mode error."
  if not msg:
    setup = ""  # get the setup
    with open(path + ".set", "r") as f:
      for line in f:
        setup += line
    if not setup:
      msg = "Missing setup."
  if not msg:
    m = re.search(r"(^|;)\s*datain\s+([^;]+);", setup, flags=re.IGNORECASE)  # datain
    if m:
      datain = m.group(2).strip()
      if proc != "combine":
        m = re.match(r'^"([^"]+)"', datain)  # remove double quotes
        if m:
          datain = m.group(1).strip()
        else:
          m = re.match(r"^'([^']+)'", datain)  # remove single quotes
          if m:
            datain = m.group(1).strip()
          else:
            m = re.match(r"^([^ ]+)", datain)  # remove subsequent file names
            if m:
              datain = m.group(1).strip()
        m = re.match(r"^[~\.\\/:\w -]+$", datain)  # check name
        if not m:
          msg = "Invalid datain."
    else:
      msg = "Missing datain."
  if not msg:
    m = re.search(r"(^|;)\s*dataout\s+([^;]+);", setup, flags=re.IGNORECASE)  # dataout
    if m:
      dataout = m.group(2).strip()
      m = re.match(r"^(.+)\s+(all|con|concat|concatenate)$", dataout, flags=re.IGNORECASE)  # rmove all or concatenate
      if m:
        dataout = m.group(1).strip()
      m = re.match(r'^"([^"]+)"$', dataout)  # remove double quotes
      if m:
        dataout = m.group(1).strip()
      else:
        m = re.match(r"^'([^']+)'$", dataout)  # remove single quotes
        if m:
          dataout = m.group(1).strip()
      m = re.match(r"^[~\.\\/:\w -]+$", dataout)  # check name
      if not m:
        msg = "Invalid dataout."
      if not msg:
        if sys.platform.startswith("win"):  # windows
          m = re.match(r"^([a-zA-Z]:|[\\/])", dataout)
        else:  # linux
          m = re.match("^(~|/)", dataout)
        if not m:  # not full path
          dataout = os.path.join(cwd, dataout)  # prefix the current working directory
        dataout = os.path.normpath(dataout)  # normalize the path
    else:
      dataout = None  # no dataout
      if proc == "combine":
        msg = "Missing dataout."
  if msg:
    print msg  # print the error message
    return None
  return [path, datain, dataout, setup]

