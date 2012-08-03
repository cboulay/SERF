#===============================================================================
# Triggers the stimulus as soon as the response phase is entered.
# Sets the stimulus parameters during the intertrial phase.
#===============================================================================

import numpy as np
import random
import time
import pygame, pygame.locals

class DigitimerApp(object):
    params = [
            "PythonApp:Digitimer        int        DigitimerEnable= 1 1 0 1 // Enable: 0 no, 1 yes (boolean)",
            "PythonApp:Digitimer        int        DigiTriggerType= 0 0 0 1 // Trigger through: 0 Contec1, 1 Contec2 (enumeration)",
        ]
    states = [
            #"SpecificState 1 0 0 0", #Define states that are specific to this extension.
        ]
    
    @classmethod
    def preflight(cls, app, sigprops):
        if int(app.params['DigitimerEnable'])==1:
            if app.params.has_key('MSEnable') and int(app.params['MSEnable']) and int(app.params['MSTriggerType'])>0:#TMS is also using contec
                print "Warning: Magstim and Digitimer both set to trigger from Contec but Digitimer requires both channels. Magstim trigger will be overwritten."
    
    @classmethod
    def initialize(cls, app, indim, outdim):
        if int(app.params['DigitimerEnable'])==1:
            trigType = int(app.params['DigiTriggerType'])
            if not hasattr(app,'trigbox') or not app.trigbox:
                from Caio.TriggerBox import TTL
                app.trigbox = TTL()
            #Digitimer requires both channels.
            app.trigbox.set_TTL(channel = trigType+1, amplitude=1.0, width=1.0, offset=0.0)
            app.trigbox.set_TTL(channel = 2-trigType, amplitude=5.0, width=2.5, offset=0.0)
            from Caio.VirtualStimulatorInterface import Virtual
            app.digistim = Virtual(trigbox=app.trigbox)
            
    @classmethod
    def halt(cls,app):
        pass
    
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
                app.digistim.trigger()
            
            elif phase == 'stopcue':
                pass
    
    @classmethod
    def process(cls,app,sig):
        if int(app.params['DigitimerEnable'])==1: return sig
    
    @classmethod
    def event(cls, app, phasename, event):
        if int(app.params['DigitimerEnable'])==1 and event.type == pygame.locals.KEYDOWN and event.key in [pygame.K_UP, pygame.K_LEFT, pygame.K_DOWN, pygame.K_RIGHT]:
            if event.key == pygame.K_UP: app.digistim.intensity = app.digistim.intensity + 1
            if event.key == pygame.K_LEFT: app.digistim.intensity = app.digistim.intensity + 0.1
            if event.key == pygame.K_DOWN: app.digistim.intensity = app.digistim.intensity - 1
            if event.key == pygame.K_RIGHT: app.digistim.intensity = app.digistim.intensity - 0.1
            print ("digitimer intensity " + str(app.digistim.intensity) + "\n")