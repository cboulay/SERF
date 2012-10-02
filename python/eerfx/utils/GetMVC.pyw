from Tkinter import *
from tkFileDialog import askopenfilename
import BCPy2000.BCI2000Tools.FileReader as FileReader
import pyperclip
import numpy as np
#from eerfx.online import *

#===============================================================================
# #http://stackoverflow.com/questions/3346124/how-do-i-force-django-to-ignore-any-caches-and-reload-data
# from django.db import transaction
# @transaction.commit_manually
#===============================================================================

class App:
    def __init__(self, master):        
        new_button = Button (master, text="Load File", command = self.get_mvc)
        new_button.pack(side=TOP, fill=X)
        
        self.v = StringVar()
        res_label = Label(master, textvariable=self.v)
        res_label.pack(side=TOP, fill=X)
        self.v.set("MVC will appear here.")
        
    def get_mvc(self):
        filename = askopenfilename()
        print filename
        bci_stream = FileReader.bcistream(filename)
        sig,states=bci_stream.decode(nsamp='all', states=['FBValue'])
        x = np.int16(states['FBValue']) / 10000.0
        x = x * 3
        x = x / bci_stream.params['OutputScaleFactor']
        x = np.max(x)
        self.v.set("MVC: %f, 10/MVC: %f" % (x, 10/x))
        pyperclip.copy(10/x)
        
if __name__ == "__main__":
    #engine = create_engine("mysql://root@localhost/eerat", echo=False)#echo="debug" gives a ton.
    #Session = scoped_session(sessionmaker(bind=engine, autocommit=True))
    root = Tk() #Creating the root widget. There must be and can be only one.
    app = App(root)
    root.mainloop() #Event loops