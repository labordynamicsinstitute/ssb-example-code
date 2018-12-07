# execute function

import srclib
import os, string, subprocess, sys

def execute(prog, path, mode, args):
  cmd = []  # execute srchset
  cmd.append(os.path.normpath(os.path.join(srclib.__path__[0], "..", "..", "bin", prog)))
  cmd.append(path + ".set")
  cmd.append("/spss")
  if mode:
    cmd.append("/debug")
  if args:
    cmd.extend(args)
  if sys.platform.startswith("win"):  # windows
    rc = subprocess.call(cmd)
  else:  # linux
    for i in range(len(cmd)):
      if cmd[i].find(" ") >= 0:
        cmd[i] = "'{0}'".format(cmd[i])
    cmd = string.join(cmd)
    rc = os.system(cmd)
    rc = 0
  return rc

