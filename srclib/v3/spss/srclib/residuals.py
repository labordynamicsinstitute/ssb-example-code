# residuals function

import os, re, spss

def residuals(datain, dataout, path, mode):
  grpvar = ""  # build the spss command
  estvar = ""
  resvar = ""
  if not re.match(r"\.sav$", datain, flags=re.IGNORECASE):  # get datain
    datain += ".sav"  # add .sav
  cmd = "get file='{0}'.\n".format(datain)
  hold = 0
  with open(path + ".res", "r") as file:  # read the residuals file
    for line in file:
      if grpvar == "":
        m = re.match("^ *(\\w+) *= *(\\d+) *; *$", line)
        if m:
          grpvar = m.group(1)
          grpval = m.group(2)
          cmd += "compute {0} = {1}.\n".format(grpvar, grpval)
      else:
        m = re.match("^ *IF *{0} *EQ *(\\d+) *THEN *$".format(grpvar), line)
        if m:
          grpval = m.group(1)
          cmd += "do if ({0} eq {1}).\n".format(grpvar, grpval)
        else:
          m = re.match("^ *IF *([\\w]+) *IN\\(([\\d,]+)\\) *THEN *{0} *= *([\\d]+) *; *$".format(grpvar), line)
          if m:
            spltvar = m.group(1)
            spltvals = m.group(2)
            grpval = m.group(3)
            cmd += "recode {0} ({1} = {2})".format(spltvar, spltvals, grpval)
          else:
            m = re.match("^ *ELSE *{0} *= *([\\d]+) *; *$".format(grpvar), line)
            if m:
              grpval = m.group(1)
              cmd += " (else = {0}) into {1}.\n".format(grpval, grpvar)
              if grpval != "3":
                cmd += "end if.\n"
            else:
              m = re.match("^ *IF *{0} *EQ *([\\d]+) *THEN *([\\w]+) *= *(.+) *; *$".format(grpvar), line)
              if m:
                grpval = m.group(1)
                estvar = m.group(2)
                estexp = m.group(3)
                cmd += "if ({0} eq {1}) {2} = {3}.\n".format(grpvar, grpval, estvar, estexp)
              else:
                m = re.match("^ *([\\w]+) *= *([\\w]+) *\- *([\\w]+) *; *$")
                if m:
                  resvar = m.group(1)
                  depvar = m.group(2)
                  estvar = m.group(3)
                  if resvar == estvar:
                    cmd += "recode {0} = {1} - {2}.\n".format(resvar, depvar, estvar)
                  else:
                    cmd += "compute {0} = {1} - {2}.\n".format(resvar, depvar, estvar)
                else:
                  m = re.match("^ *IF *{0} *EQ *([\\d]+) *THEN *DO *; *$".format(grpvar), line)
                  if m:
                    grpval = m.group(1)
                    if hold == 0:
                      hold = 1
                      value = "do if ({0} eq {1}).\n".format(grpvar, grpval)
                    else:
                      if hold == 1:
                        hold = 2
                        cmd += value
                      cmd += "do if ({0} eq {1}).\n".format(grpvar, grpval)
                  else:
                    m = re.match("^ *([\\w]+) *= *(.+) *; *$")
                    if m:
                      estvar = m.group(1)
                      estexp = m.group(2)
                      if hold == 1:
                        cmd += "recode {0} = $sysmis.\n".format(estvar)
                        value += "recode {0} = {1}.\n".format(estvar, estexp)
                      else:
                        cmd += "recode {0} = {1}.\n".format(estvar, estexp)
                    else:
                      m = re.match("^ *IF *([\\w]+) *EQ *([\\d]+|.) *THEN *([\\w]+) *= *(.+) *; *$")
                      if m:
                        depvar = m.group(1)
                        depval = m.group(2)
                        resvar = m.group(3)
                        resexp = m.group(4)
                        cmd += "do if ({0} eq {1}).\nrecode {2} = {3}.\n".format(depvar, depval, resvar, resexp)
                      else:
                        m = re.match("^ *ELSE *([\\w]+) *= *(.+) *; *$")
                        if m:
                          resvar = m.group(1)
                          resexp = m.group(2)
                          cmd += "else.\nrecode {0} = {1}.\nend if.\n".format(resvar, resexp)
  if not re.match(r"\.sav$", dataout):
    dataout += ".sav"  # add .sav
  cmd += "save outfile='{0}'.\n".format(dataout)
  if mode:
    print cmd  # print the command
  spss.Submit(cmd)  # execute the command

