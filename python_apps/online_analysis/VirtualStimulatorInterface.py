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
        self.stim_ready = True
        
        if not trigbox:
            from Caio import TriggerBox
            trigbox = TriggerBox.TTL()
        self.trigbox = trigbox
        
    def get_stimi(self): return self.trigbox.amplitude
    def set_stimi(self, value): self.trigbox.amplitude=value
    stim_intensity = property(get_stimi, set_stimi)
    
    def trigger(self):
        self.trigbox.trigger()