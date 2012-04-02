#cd D:/tools/eerat/python_apps/online_analysis
#import test_gui
from Tkinter import *

class App:
    
    def __init__(self, master):
        #master is the root
        
        frame = Frame(master)#Simple container
        frame.pack()
        
        #Insert other widgets into frame
        self.button = Button(frame, text="QUIT", fg="red", command=frame.quit)
        self.button.pack(side=LEFT)
        
        self.hi_there = Button(frame, text="Hello", command=self.say_hi)
        self.hi_there.pack(side=LEFT)
        
    def say_hi(selfself):
        print "hi there, everyone!"
        
root = Tk() #Creating the root widget. There must be and can be only one.
app = App(root)
root.mainloop() #Event loops