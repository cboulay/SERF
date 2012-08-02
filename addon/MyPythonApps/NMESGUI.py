from Tkinter import *

import numpy as np
import time

def reset_frame(frame):
    for ww in frame.pack_slaves():
        ww.pack_forget()
    #frame.grid_forget()
    return frame

class App:
    
    def __init__(self, master):
        #master is the root Tk element
        button_frame = Frame(master)#Simple container
        button_frame.pack(side = LEFT, fill = Y)
        
        self.dat_frame = Frame(master)
        self.dat_frame.pack(side = LEFT, fill = Y)
        
        digitimer_button = Button(button_frame, text="DIGITIMER >>", command=self.digitimer)
        digitimer_button.pack(side=TOP)
        
        digiring_button = Button(button_frame, text="DIGIRING >>", command=self.digiring)
        digiring_button.pack(side=TOP)
        
        hands_button = Button(button_frame, text="HANDS >>", command = self.hands)
        hands_button.pack(side = TOP)
        
    def hands(self):
        self.dat_frame=reset_frame(self.dat_frame)
        HandsFrame(frame = self.dat_frame)
    
    def digitimer(self):
        self.dat_frame=reset_frame(self.dat_frame)
        DigitimerFrame(frame = self.dat_frame)
        
    def digiring(self):
        self.dat_frame=reset_frame(self.dat_frame)
        DigitimerFrame(frame = self.dat_frame, type='RING')
        
class HandsFrame:
    def __init__(self, frame=None):
        if not frame: frame=Toplevel()
        self.frame = frame
        
        from Handbox.NMESInterface import NMES
        self.frame.nmes = NMES(port='COM11')
        self.frame.nmes.width = 1.0
        
        stop_button = Button(self.frame, text="STOP", command=self.frame.nmes.stop)
        stop_button.pack(side = TOP, fill = X)
        
        GenericFrame(frame = self.frame)
        
class DigitimerFrame:
    def __init__(self, frame=None, type='FIFO'):
        if not frame: frame=Toplevel()
        self.frame = frame
        
        from Caio.NMES import NMESFIFO, NMESRING
        self.frame.nmes = NMESFIFO() if type=='FIFO' else NMESRING()
        self.frame.nmes.running = True
        
        GenericFrame(frame = self.frame)
        
class GenericFrame:
    def __init__(self, frame = None):
        
        if not frame: frame=Toplevel()
        self.frame = frame
        
        self._int = StringVar()
        self._int.set(str(self.frame.nmes.intensity))
        
        button_frame = Frame(self.frame)#Simple container
        button_frame.pack(side = TOP, fill = X)
        
        ppb = Button(button_frame, text="+1", command=self.plus_one)
        ppb.pack(side = RIGHT)
        pb = Button(button_frame, text="+0.1", command=self.plus_tenth)
        pb.pack(side = RIGHT)
        mb = Button(button_frame, text="-0.1", command=self.minus_tenth)
        mb.pack(side = RIGHT)
        mmb = Button(button_frame, text="-1", command=self.minus_one)
        mmb.pack(side = RIGHT)
        
        amp_label = Label(self.frame, textvariable = self._int)
        amp_label.pack(side = TOP, fill = X)
        
        zero_button = Button(self.frame, text="0", command=self.zero)
        zero_button.pack(side = BOTTOM, fill = X)
        
        #for i in np.arange(30):
        #    self.plus_tenth()
        #    time.sleep(0.1)
    
    def _change_int(self, value):
        intensity_was = self.frame.nmes.intensity
        self.frame.nmes.intensity = intensity_was + float(value)
        time.sleep(0.1)
        self._int.set(str(self.frame.nmes.intensity))
    def plus_one(self): self._change_int(1)
    def plus_tenth(self): self._change_int(0.1)
    def minus_tenth(self): self._change_int(-0.1)
    def minus_one(self): self._change_int(-1)
    def zero(self): self._change_int(-1*self.frame.nmes.intensity)
        
        #from Handbox.NMESInterface import NMES
        
if __name__ == "__main__":
    root = Tk() #Creating the root widget. There must be and can be only one.
    app = App(root)
    root.mainloop() #Event loops