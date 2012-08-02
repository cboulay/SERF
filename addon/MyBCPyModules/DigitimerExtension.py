#===============================================================================
# Triggers the stimulus as soon as the response phase is entered.
# Sets the stimulus parameters during the intertrial phase.
#===============================================================================

import numpy as np
import random
import time

class Template(object):
    params = [
            "PythonApp:Digitimer        int        DigitimerEnable= 1 1 0 1 // Enable: 0 no, 1 yes (boolean)",
            "PythonApp:Digitimer        int        DigiTriggerType= 0 0 0 2 // Trigger by: 0 Contec1, 1 Contec2 (enumeration)",
        ]
    states = [
            #"SpecificState 1 0 0 0", #Define states that are specific to this extension.
        ]
    
    @classmethod
    def preflight(cls, app, sigprops):
        if int(app.params['DigitimerEnable'])==1: pass
    
    @classmethod
    def initialize(cls, app, indim, outdim):
        if int(app.params['DigitimerEnable'])==1:
            trigType = int(app.params['DigiTriggerType'])
            if app.trigbox: app.trigbox.set_TTL(channel=trigType+1, amplitude=5, width=1, offset=0.0)
            else:
                from Caio.TriggerBox import TTL
                app.trigbox = TTL(channel=trigType)
            from Caio.VirtualStimulatorInterface import Virtual
            app.digistim = Virtual(trigbox=app.trigbox)
            #app.intensity_detail_name = 'dat_Nerve_stim_output'
            
    @classmethod
    def halt(cls,app):
        if int(app.params['DigitimerEnable'])==1: pass
    
    @classmethod
    def startrun(cls,app):
        if int(app.params['DigitimerEnable'])==1: pass
    
    @classmethod
    def stoprun(cls,app):
        if int(app.params['DigitimerEnable'])==1: pass
        
    @classmethod
    def transition(cls,app,phase):
        if int(app.params['DigitimerEnable'])==1:
            if phase == 'intertrial':
                pass
                
            elif phase == 'baseline':
                pass
            
            elif phase == 'gocue':
                pass
                
            elif phase == 'task':
                pass
                
            elif phase == 'response':
                pass
            
            elif phase == 'stopcue':
                pass
    
    @classmethod
    def process(cls,app,sig):
        if int(app.params['DigitimerEnable'])==1: return sig
    
    @classmethod
    def event(cls, app, phasename, event):
        if int(app.params['DigitimerEnable'])==1: pass