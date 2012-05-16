from Tkinter import *
from Caio.NMES import NMESFIFO
import numpy as np
import time

class App:
    
    def __init__(self, master):
        #master is the root Tk element
        self.nmes = NMESFIFO()
        self.nmes.running = True
            
        self._amp = StringVar()
        self._amp.set(str(self.nmes.amplitude))
        
        button_frame = Frame(master)#Simple container
        button_frame.pack(side = TOP, fill = X)
        
        ppb = Button(button_frame, text="+1", command=self.plus_one)
        ppb.pack(side = RIGHT)
        pb = Button(button_frame, text="+0.1", command=self.plus_tenth)
        pb.pack(side = RIGHT)
        mb = Button(button_frame, text="-0.1", command=self.minus_tenth)
        mb.pack(side = RIGHT)
        mmb = Button(button_frame, text="-1", command=self.minus_one)
        mmb.pack(side = RIGHT)
        
        amp_label = Label(master, textvariable = self._amp)
        amp_label.pack(side = TOP, fill = X)
        
        zero_button = Button(master, text="0", command=self.zero)
        zero_button.pack(side = BOTTOM, fill = X)
        
        for i in np.arange(30):
            self.plus_tenth()
            time.sleep(0.1)
    
    def _change_amp(self, value):
        self.nmes.amplitude = self.nmes.amplitude + float(value)
        self._amp.set(str(self.nmes.amplitude))
    def plus_one(self): self._change_amp(1)
    def plus_tenth(self): self._change_amp(0.1)
    def minus_tenth(self): self._change_amp(-0.1)
    def minus_one(self): self._change_amp(-1)
    def zero(self):
        self.nmes.amplitude = 0
        self._amp.set(str(self.nmes.amplitude))
        
if __name__ == "__main__":
    root = Tk() #Creating the root widget. There must be and can be only one.
    app = App(root)
    root.mainloop() #Event loops