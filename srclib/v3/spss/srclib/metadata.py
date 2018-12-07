# metadata function

import os, re, spss

def metadata(datain, path):
  f = open(path + ".met", "w")  # open the metadata file
  f.write("standard;\n")
  f.write("variables\n")  # write the variable metadata
  if not re.match(r"\.sav$", datain, flags=re.IGNORECASE):  # get datain
    datain += ".sav"  # add .sav
  spss.Submit("get file='{0}'.".format(datain))
  spss.StartDataStep()
  ds = spss.Dataset()
  type = -1
  frames = 0
  for var in ds.varlist:
    line = "  name={0}".format(var.name)  # name
    if var.label:
      line += ' label="{0}"'.format(var.label.replace('"', '"'))  # label
    if var.type != type:
      if var.type == 0:  # type and width
        line += " type=float width=8"
      else:
        line += " type=char width={0}".format(var.type)
      type = var.type
    if var.valueLabels:  # codeframe
      line += ' codeframe="{0}"'.format(var.name)
      frames = 1
    line += ";\n"
    f.write(line)
  if frames:  # write the codeframe metadata
    f.write("codeframes\n")
    for var in ds.varlist:
      if var.valueLabels:
        f.write("  name={0}\n".format(var.name))
        for val, lab in var.valueLabels.data.iteritems():
          f.write('    {0} = "{1}"\n'.format(val, lab))
        f.write("  ;\n")
  ds.close()
  spss.EndDataStep()
  f.close()
  return 0

