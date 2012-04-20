import threading
import MyGUIs
from Tkinter import *

class GUIThread(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
        self.root = Tk() #Creating the root widget. There must be and can be only one.
        #app = FrameClass(self.root)
        
    def run(self):
        self.root.mainloop() #Event loops