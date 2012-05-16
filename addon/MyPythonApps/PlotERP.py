#PyRO daemon that runs in a separate instance.
#Data are passed to this object over the network
#and this object plots the data. Simple, but
#necessary to get around GUI threading issues.
import pylab
import numpy as np
import Pyro4
from BCPy2000 import SigTools

class PlotMaker(object):
    def plot_data(self,x,y):
        x_bool = x > 5
        SigTools.plot(x[x_bool],y[x_bool,:], hold = True, drawnow = True)
        print "Why isn't this rendering anymore?"
        
if __name__ == "__main__":
    plot_maker=PlotMaker()

    #daemon=Pyro4.Daemon()                 # make a Pyro daemon
    #uri=daemon.register(plot_maker)       # register the plot object as a Pyro object
    #print "Ready. Object uri =", uri      # print the uri so we can use it in the client later
    #daemon.requestLoop()                  # start the event loop of the server to wait for calls
    Pyro4.Daemon.serveSimple(
            {
                plot_maker: "plot_maker"
            },
            ns=False, port=4567)
    