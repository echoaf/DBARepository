import commands

def runShell(c):
    status, text = commands.getstatusoutput(c)
    return status, text

