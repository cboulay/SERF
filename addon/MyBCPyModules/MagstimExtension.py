#===============================================================================
# Sets the stimulus parameters during the intertrial phase.
# Application cannot advance to response from task if MSReqStimReady and it isn't ready.
# Triggers the stimulus as soon as the response phase is entered.
#===============================================================================

import numpy as np
import random
import time

class MagstimApp(object):
    params = [
            "PythonApp:Magstim        int        MSEnable= 1 1 0 1 // Enable: 0 no, 1 yes (boolean)",
            "PythonApp:Magstim        string    MSSerialPort= COM4 % % % // Serial port for controlling Magstim",
            "PythonApp:Magstim        int        MSTriggerType= 0 0 0 2 // Trigger by: 0 SerialPort, 1 Contec1, 2 Contec2 (enumeration)",
            "PythonApp:Magstim        int        MSReqStimReady= 0 0 0 1 // (Buggy) Require ready response to trigger: 0 no, 1 yes (boolean)",
            "PythonApp:Magstim        int        MSIntensityA= 50 50 0 100 // TS for single, CS for double",
            "PythonApp:Magstim        int        MSIntensityB= 0 0 0 100 // TS for double",
            "PythonApp:Magstim        float    MSPulseInterval= 0 0 0 999 // Double-pulse interval in ms",
            "PythonApp:Magstim        int        MSSICIType= 0 0 0 2 // Two-pulses: 0 Always, 1 Alternate, 2 Pseudorandom (enumeration)",
        ]
    states = [
            "StimulatorReady 1 0 0 0", #Whether or not the stimulator returns ready
            "MSIntensityA 16 0 0 0", #Intensity of StimA
            "MSIntensityB 16 0 0 0", #Intensity of StimA
            "ISIx10 16 0 0 0", #Double-pulse ISI in 0.1ms
        ]
    
    @classmethod
    def preflight(cls, app, sigprops):
        if int(app.params['MSEnable'])==1:
            pass
    
    @classmethod
    def initialize(cls, app, indim, outdim):
        if int(app.params['MSEnable'])==1:
            from Magstim.MagstimInterface import Bistim
            serPort=app.params['MSSerialPort'].val
            trigType=int(app.params['MSTriggerType'])
            if trigType==0: trigbox=None
            else:
                if app.trigbox: app.trigbox.set_TTL(channel=trigType, amplitude=5, width=2.5, offset=0.0)
                else:
                    from Caio.TriggerBox import TTL
                    app.trigbox=TTL(channel=trigType)
            app.magstim=Bistim(port=serPort, trigbox=app.trigbox)
            #app.intensity_detail_name = 'dat_TMS_powerA'
            app.magstim.remocon = True
            app.magstim.intensity = app.params['MSIntensityA'].val
            app.magstim.intensityb = app.params['MSIntensityB'].val
            app.magstim.ISI = app.params['MSPulseInterval'].val
            app.magstim.armed = True
            
            if app.magstim.ISI > 0:
                n_trials = app.params['TrialsPerBlock'].val
                sici_type = int(app.params['MSSICIType'])
                app.sici_bool = np.ones(n_trials, dtype=np.bool)
                if sici_type>0: app.sici_bool[range(0,n_trials,2)]=False
                if sici_type==2: random.shuffle(app.sici_bool)
    
    @classmethod
    def halt(cls,app):
        if int(app.params['MSEnable'])==1:
            app.magstim.ISI = 0.0
            app.magstim.intensityb = 0
            app.magstim.armed = False
            app.magstim.remocon = False
            #Clear magstim from memory, which will also clear the serial port.
            del app.magstim
    
    @classmethod
    def startrun(cls,app):
        if int(app.params['MSEnable'])==1: pass
        
    @classmethod
    def stoprun(cls,app):
        if int(app.params['MSEnable'])==1: pass
    
    @classmethod
    def transition(cls,app,phase):
        if int(app.params['MSEnable'])==1:
            if phase == 'intertrial':
                app.stimulator.armed = True
                
            elif phase == 'baseline':
                pass
            
            elif phase == 'gocue':
                pass
                
            elif phase == 'task':
                pass
                
            elif phase == 'response':
                self.stimulator.trigger()
                self.states['MSIntensityA'] = app.stimulator.intensity
                self.states['MSIntensityB'] = app.stimulator.intensityb
                self.states['ISIx10'] = app.stimulator.ISI
                
            elif phase == 'stopcue':
                pass
    
    @classmethod
    def process(cls,app,sig):
        if int(app.params['MSEnable'])==1:
            ####################################
            # Update the StimulatorReady state #
            ####################################
            if not app.stimulator.armed: app.stimulator.armed = True
            stim_ready = True if not app.params['ReqStimReady'].val else (app.stimulator.ready and app.stimulator.armed)
            app.states['StimulatorReady'] = stim_ready
    
    @classmethod
    def event(cls, app, phasename, event):
        if int(app.params['MSEnable'])==1:
            if event.type == pygame.locals.KEYDOWN:
                if event.key in [pygame.K_UP, pygame.K_DOWN]:
                    if event.key == pygame.K_UP: app.magstim.intensity = app.magstim.intensity + 1
                    if event.key == pygame.K_DOWN: app.magstim.intensity = app.magstim.intensity - 1
                print ("magstim intensity " + str(app.magstim.intensity))