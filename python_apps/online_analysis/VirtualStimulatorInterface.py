class Virtual(object):
    def __init__(self, trigbox=None):
        """
        This is a simple interface to a virtual stimulator.
        It is meant to mimic the MagstimInterface thus the same properties
        and methods must be exposed.
        We may want to also set the channel and width of the TTL but those
        must be accessed through stim_instance.trigbox
        If I weren't so lazy I would turn this into a DS5 ctypes interface
        Methods:
            stim_instance.trigger()
                Sends a trigger through trigbox.
                If this is instantiated without a trigbox, it uses Caio by default.
                
        Properties:
            stim_instance.stim_intensity
                Set the stimulator intensity. Units are in V
            stim_instance.stim_ready = True
                Always true since there is no way to know if it is not ready.
        """
        self.V2mA = 5 #10V:50mA
        if not trigbox:
            from Caio import TriggerBox
            trigbox = TriggerBox.TTL()
        self.trigbox = trigbox
        
    def _get_stimi(self):
        return self.trigbox.amplitude * self.V2mA
    def _set_stimi(self, mamps):
        #Since I am detecting triggers on the trigger channel
        #There must be a minimum stimulus, which I set to 0.5mA or about 50mV on the output.
        mamps = max([mamps,0.5])
        self.trigbox.amplitude=mamps / self.V2mA
    stim_intensity = property(_get_stimi, _set_stimi)
    
    def _get_stim_ready(self): return True
    def _set_stim_ready(self): pass #Always True
    stim_ready = property(_get_stim_ready, _set_stim_ready)
    
    def trigger(self):
        self.trigbox.trigger()