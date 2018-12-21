
import logging

def printLog(self, content=None, normal_log=None, color='normal'):
    if normal_log:
        try:
            logging.basicConfig(level = logging.DEBUG,
                    format = '[%(asctime)s %(filename)s]:%(message)s',
                    datefmt = '%Y-%m-%d %H:%M:%S',
                    filename = normal_log,
                    filemode = 'a'
            )
            logging.info(content)
            content = str(content)
        except Exception,e:
            pass
    codeCodes = {
            'black':'0;30',
            'green':'0;32',
            'cyan':'0;36',
            'red':'0;31',
            'purple':'0;35',
            'normal':'0'
    }
    print("\033["+codeCodes[color]+"m"+'[%s] %s'%(time.strftime('%F %T',time.localtime()),content)+"\033[0m")

