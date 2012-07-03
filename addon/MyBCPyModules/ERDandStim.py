# Each trial has 7 phases:
# 1 - intertrial (100 ms)
# 2 - baseline (3000 ms)
# 3 - startcue (1000 ms)
# 4 - gap (400 ms)
# 5 - imagine (3000 +/- 500 ms; no feedback)
# 6 - response (1000 ms; includes stimulus at beginning of response)
# 7 - endcue (1000 ms)
# The cue is provided as text on the screen
from __future__ import print_function
import numpy as np
from random import randint
import time
from AppTools.Boxes import box
from AppTools.Displays import fullscreen
from AppTools.Shapes import PolygonTexture, Disc, Block
from AppTools.StateMonitors import addstatemonitor, addphasemonitor
import SigTools
import WavTools
from EeratAPI.API import *
from MyPythonApps.OnlineAPIExtension import *
from MyBCPyModules.StimExtension import MEP, HR, MAPPING, IOCURVE, SICI
import pygame, pygame.locals

class BciApplication(BciGenericApplication):

    def Description(self):
        return "Cue motor imagery trials and stimulate during imagery."

    def Construct(self):
        params = [
            "PythonApp:Design     int            ExperimentType= 0 0 0 2 // Experiment Type: 0 MEPRecruitment, 1 MEPSICI, 2 HRRecruitment (enumeration)",
            "PythonApp:Design     float          StimIntensity= 30 30 0 100 // 0-50 for DS5, 0-100 for Single-Pulse, 0-100 for Bistim Cond",
            "PythonApp:Design     list           TriggerInputChan= 1 TMSTrig % % % // Name of channel used to monitor trigger / control ERP window",
            "PythonApp:Design     float          TriggerThreshold= 100000 1 0 % // If monitoring trigger, use this threshold to determine ERP time 0",
            "PythonApp:Design     list           ERPChan= 1 EDC % % % // Name of channel used for ERP",
            "PythonApp:Design     floatlist      ERPWindow= {Start Stop} -500 500 0 % % // ERP window, relative to trigger onset, in millesconds",
            "PythonApp:Design     int            ShowFixation= 0     0     0   1  // show a fixation point in the center (boolean)",
            "PythonApp:Screen     int            ScreenId= -1    -1     %   %  // on which screen should the stimulus window be opened - use -1 for last",
            "PythonApp:Screen     float          WindowSize= 0.8   1.0   0.0 1.0 // size of the stimulus window, proportional to the screen",
            "PythonApp:Stimuli    matrix         CueWavs= 1 1 900hz.wav % % % // Cue wav",
		]
        params.extend(MEP.params)
        params.extend(SICI.params)
        params.extend(IOCURVE.params)
        
        states = [
			"Baseline   1 0 0 0",
			"StartCue   1 0 0 0",
            "Imagine    1 0 0 0",
            "Response 1 0 0 0",
			"StopCue    1 0 0 0",
            "StimulatorIntensity 16 0 0 0", #So it is saved off-line analysis
            "StimulatorReady 1 0 0 0", #Whether or not stimulator is ready to trigger.
            "Trigger 1 0 0 0",
		]
        states.extend(MEP.states)
        states.extend(SICI.states)
        
        return params,states

    def Preflight(self, sigprops):
        siz = float(self.params['WindowSize'])
        screenid = int(self.params['ScreenId'])  # ScreenId 0 is the first screen, 1 the second, -1 the last
        fullscreen(scale=siz, id=screenid, frameless_window=(siz==1))
        # only use a borderless window if the window is set to fill the whole screen
        
        #############
        # ERP CHECK #
        #############
        chn = self.inchannels()
        self.trigchan = None
        tch = self.params['TriggerInputChan']
        if len(tch) != 0:
            if False in [isinstance(x, int) for x in tch]:
                nf = filter(lambda x: not str(x) in chn, tch)
                if len(nf): raise EndUserError, "TriggerChannel %s not in module's list of input channel names" % str(nf)
                self.trigchan = [chn.index(str(x)) for x in tch]
            else:
                nf = [x for x in tch if x < 1 or x > len(chn) or x != round(x)]
                if len(nf): raise EndUserError, "Illegal TriggerChannel: %s" %str(nf)
                self.trigchan = [x-1 for x in tch]
        if self.trigchan:
            trigthresh=self.params['TriggerThreshold'].val
            self.tch=tch #This is used for storing the channel labels.
            self.trigthresh=trigthresh
        
        #Check the ERP channel.
        erpch = self.params['ERPChan'].val
        if len(erpch) != 0:
            if False in [isinstance(x, int) for x in erpch]:
                nf = filter(lambda x: not str(x) in chn, erpch)
                if len(nf): raise EndUserError, "ERPChan %s not in module's list of input channel names" % str(nf)
                self.erpchan = [chn.index(str(x)) for x in erpch]
            else:
                nf = [x for x in erpch if x < 1 or x > len(chn) or x != round(x)]
                if len(nf): raise EndUserError, "Illegal ERPChan: %s" % str(nf)
                self.erpchan = [x-1 for x in erpch]
        else:
            raise EndUserError, "Must supply ERPChan"
        
        #Get the list of stored channel ids
        self.stored_chan_ids = self.trigchan + self.erpchan if self.trigchan else self.erpchan
            
        #Check the ERP window.
        erpwin = self.params['ERPWindow'].val
        if len(erpwin)!=2: raise EndUserError, "ERPWindow must have 2 values"
        if erpwin[0]>erpwin[1]: raise EndUserError, "ERPWindow must be in increasing order"
        if erpwin[1]<0: raise EndUserError, "ERPWindow must include up to at least 0 msec after stimulus onset"
        self.erpwin=erpwin
        
        
        if self.params['ExperimentType'].val in [0,2]: IOCURVE.preflight(self)

    def Initialize(self, indim, outdim):
        
        ######################
        # PREPARE THE SCREEN #
        ######################
        
        # compute how big everything should be
        scrw,scrh = self.screen.size
        scrsiz = min(scrw,scrh)
        siz = (scrsiz, scrsiz)
        
        # use a handy AppTools.Boxes.box object as the coordinate frame for the screen
        b = box(size=siz, position=(scrw/2.0,scrh/2.0), sticky=True)
        center = b.map((0.5,0.5), 'position')
        self.positions = {'origin': np.matrix(center)}
        
        #Use that same box, but manipulate its properties to get positional information for the other items.
        # and the arrow
        b.scale(x=0.25,y=0.4)#How big should the arrow be, relative to the screen size
        arrow = PolygonTexture(frame=b, vertices=((0.22,0.35),(0,0.35),(0.5,0),(1,0.35),(0.78,0.35),(0.78,0.75),(0.22,0.75),), color=(1,1,1), on=False, position=center)
        
        #reset b
        b.scale(x=4.0, y=2.5)
        b.anchor='center'
       
        # let's have a black background
        self.screen.color = (0,0,0)
        
        # OK, now register all those stimuli, plus a few more, with the framework
        self.stimulus('arrow',    z=4.5, stim=arrow)
        self.stimuli['arrow'].color = [0, 1, 0]
        self.stimuli['arrow'].angle = 180
        self.stimulus('cue',      z=5,   stim=VisualStimuli.Text(text='?', position=center, anchor='center', color=(1,1,1), font_size=50, on=False))
        self.stimulus('fixation', z=4.2, stim=Disc(position=center, radius=5, color=(1,1,1), on=False))
        
        # set up the strings that are going to be presented in the 'cue' stimulus
        self.cuetext = ['pause', 'imagery']

        # load, and silently start, the sounds
        # They will be used for cues and maybe for feedback.
        self.sounds = []
        wavmat = self.params['CueWavs']
        for i in range(len(wavmat)):
            wavlist = wavmat[i]
            if len(wavlist) != 1: raise EndUserError, 'CueWavs matrix should have 1 column'
            try: snd = WavTools.player(wavlist[0])
            except IOError: raise EndUserError, 'failed to load "%s"'%wavlist[0]
            self.sounds.append(snd)
            snd.vol = 0
            snd.play(-1)
        
        self.subject=get_or_create(Subject, Name=self.params['SubjectName'], species_type='human')
        #Determine period_type from ExperimentType 0 MEPMapping, 1 MEPRecruitment, 2 MEPSICI, 3 HRHunting, 4 HRRecruitment
        period_type_name={0:'mep_io', 1:'mep_sici', 2:'hr_io'}.get(int(self.params['ExperimentType']))
        my_period_type=get_or_create(Datum_type, Name=period_type_name)
        self.period = self.subject.get_most_recent_period(datum_type=my_period_type,delay=0)#Will create period if it does not exist.
                
        ##########################
        # PREPARE THE STIMULATOR #
        ##########################
        #Initialize the stimulator. It depends on the ExperimentType
        #from ExperimentType 0 MEPMapping, 1 MEPRecruitment, 2 MEPSICI, 3 HRHunting, 4 HRRecruitment
        exp_type = int(self.params['ExperimentType'])
        if True:#Set this to false for testing.
            if exp_type in [0,1]: MEP.initialize(self)#Stimulator
            elif exp_type == 2: HR.initialize(self)
        else:
            self.stimulator = lambda: None
            self.stimulator.trigger = lambda: print("trigger at " + str(self.stimulator.intensity))
            self.intensity_detail_name = 'dat_TMS_powerA'
            self.stimulator.ready = True
            
        if exp_type == 1: 
            SICI.initialize(self)
        if exp_type in [0,2]: IOCURVE.initialize(self)#Detection limit and baseline trials
        self.stimulator.intensity = self.params['StimIntensity'].val#This might be overwritten in inter-trial (e.g. by IOCURVE)
        
        ##########################
        # PREPARE THE ERP BUFFER #
        ##########################
        self.eegfs=self.nominal['SamplesPerSecond'] #Sampling rate
        self.post_stim_samples = SigTools.msec2samples(self.erpwin[1], self.eegfs)
        self.pre_stim_samples = SigTools.msec2samples(np.abs(self.erpwin[0]), self.eegfs)
        #Initialize the ring buffer. It will be passed the raw data (relabeled as EDC) and the erp.
        self.leaky_trap=SigTools.Buffering.trap(4*(self.pre_stim_samples + self.post_stim_samples), len(self.stored_chan_ids), leaky=True)
        
        self.x_vec=np.arange(self.erpwin[0],self.erpwin[1],1000/self.eegfs,dtype=float)
        self.chlbs = self.params['TriggerInputChan'] if self.trigchan else []
        self.chlbs.extend(self.params['ERPChan'])
                
        # finally, some fancy stuff from AppTools.StateMonitors, for the developer to check
        # that everything's working OK
        if int(self.params['ShowSignalTime']):
            # turn on state monitors iff the packet clock is also turned on
            addstatemonitor(self, 'Running', showtime=True)
            addstatemonitor(self, 'CurrentBlock')
            addstatemonitor(self, 'CurrentTrial')
            addstatemonitor(self, 'Trigger')
            addstatemonitor(self, 'StimulatorReady')
            
            addphasemonitor(self, 'phase', showtime=True)

            m = addstatemonitor(self, 'fs_reg')
            m.func = lambda x: '% 6.1fHz' % x._regfs.get('SamplesPerSecond', 0)
            m.pargs = (self,)
            m = addstatemonitor(self, 'fs_avg')
            m.func = lambda x: '% 6.1fHz' % x.estimated.get('SamplesPerSecond',{}).get('global', 0)
            m.pargs = (self,)
            m = addstatemonitor(self, 'fs_run')
            m.func = lambda x: '% 6.1fHz' % x.estimated.get('SamplesPerSecond',{}).get('running', 0)
            m.pargs = (self,)
            m = addstatemonitor(self, 'fr_run')
            m.func = lambda x: '% 6.1fHz' % x.estimated.get('FramesPerSecond',{}).get('running', 0)
            m.pargs = (self,)
            
    def Halt(self):#Undo initialization
        if hasattr(self,'stimulator'):
            exp_type = int(self.params['ExperimentType'])
            if exp_type == 1: SICI.halt(self)
            del self.stimulator

    def StartRun(self):
        if int(self.params['ShowFixation']):
			self.stimuli['fixation'].on = True
        self.triggered = False
        self.transient("Trigger")
        self.trailingsample = None#Used for trigger monitoring
        
        if int(self.params['ExperimentType']) in [0,2]: IOCURVE.startrun(self)

    def Phases(self):
        self.phase(name='intertrial',   next='baseline',    duration=700)
        self.phase(name='baseline',     next='startcue',    duration=3000)
        self.phase(name='startcue',     next='gap',         duration=1000)
        self.phase(name='gap',          next='imagine',     duration=300)
        self.phase(name='imagine',      next='armed',       duration=3500+np.random.randint(400))
        self.phase(name='armed',        next='response',    duration=None)
        self.phase(name='response',     next='stopcue',     duration=1000)
        self.phase(name='stopcue',      next='intertrial',  duration=1000)
        
        self.design(start='intertrial', new_trial='baseline', interblock='idle')

    def Transition(self, phase):
        
        self.states['Baseline'] = int(phase in ['baseline'])
        self.states['StartCue'] = int(phase in ['startcue'])
        self.states['StopCue']  = int(phase in ['stopcue'])
        
        if phase == 'intertrial':
            pass

        if phase == 'baseline':
            if int(self.params['ExperimentType']) in [0,1]: self.stimulator.armed = True
            
        #Visual Cues
        self.stimuli['cue'].on = (phase in ['startcue', 'stopcue'])
        self.stimuli['arrow'].on = (phase in ['startcue'])
        self.stimuli['cue'].text = self.cuetext[self.states['StartCue']]     
        #Auditory Cue
        self.sounds[0].vol = self.states['StartCue']
                
        if phase == 'gap':
            pass
        
        if phase == 'imagine':
            pass
        
        if phase == 'response':
            self.stimulator.trigger()
            self.states['Trigger'] = 1
            self.triggered = True
            self.states['StimulatorIntensity'] = self.stimulator.intensity
            
        if phase == 'stopcue':
            pass #handled by cues statements
        
        if int(self.params['ExperimentType']) in [0,1]: MEP.transition(self,phase)
        if int(self.params['ExperimentType']) == 1: SICI.transition(self,phase)
        if int(self.params['ExperimentType']) in [0,2]: IOCURVE.transition(self,phase)

    def Process(self, sig):
        
        if self.in_phase('armed') and (int(self.params['ExperimentType']) == 2 or self.stimulator.ready):
            self.change_phase('response')
        
        stim_ready = True if not self.params['ReqStimReady'].val else self.stimulator.ready
        self.states['StimulatorReady'] = stim_ready
        self.leaky_trap.process(sig[self.stored_chan_ids,:]) #Debug trigger timing
        
        if self.triggered:#Only search for a trigger response if we have sent a trigger
            startx = None
            
            #
            # Find the Trigger #
            ####################
            tr = np.asarray(sig[self.trigchan, :]).ravel() #flatten the trigger channel(s).
            prev = self.trailingsample #The last sample from the previous packet
            if prev == None: prev = [self.trigthresh - 1.0] #If we don't have a last sample, assume it was less than the threshold
            self.trailingsample = tr[[-1]] #Keep the last sample of this packet for next time
            tr = np.concatenate((prev,tr)) #prepend this packet with the last sample of the previous packet
            tr = np.asarray(tr > self.trigthresh, np.int8) #booleans representing whether or not the trigger was above threshold
            tr = np.argwhere(np.diff(tr) > 0)  #find any indices where the trigger crossed threshold
            if len(tr): #If we have a crossing
                startx = tr[0,0] #n_samples when the trigger first crossed threshold
                
            #
            # Forget any ERP before startx + pre_stim_samples #
            ###################################################
            if startx:
                samps_in_trap = self.leaky_trap.collected()
                samps_this_packet = sig.shape[1]
                samps_to_forget = samps_in_trap - ( samps_this_packet + (self.pre_stim_samples - startx)) - 1
                self.leaky_trap.ring.forget(samps_to_forget)
                
            #
            # Extract the ERP #
            ###################
            n_erp_samples=self.pre_stim_samples + self.post_stim_samples
            if self.leaky_trap.collected() >= n_erp_samples:
                #The ERP buffer should begin at precisely the pre-stim window so read n_erp_samples
                x=self.leaky_trap.ring.read(nsamp=n_erp_samples, remove=False)
                self.triggered = False #We do not need to look for the ERP anymore.
                self.period.trials.append(Datum(subject_id=self.subject.subject_id\
                                            , datum_type_id=self.period.datum_type_id\
                                            , span_type='trial'\
                                            , parent_datum_id=self.period.datum_id\
                                            , IsGood=1, Number=0))
                my_trial=self.period.trials[-1]
                my_trial.detail_values[self.intensity_detail_name]=str(self.stimulator.intensity)
                if int(self.params['ExperimentType']) == 1:#SICI intensity
                    my_trial.detail_values['dat_TMS_powerB']=str(self.stimulator.intensityb)
                    my_trial.detail_values['dat_TMS_ISI']=str(self.stimulator.ISI)
                #The fature calculation should be asynchronous.
                my_trial.store={'x_vec':self.x_vec, 'data':x, 'channel_labels': self.chlbs}
                self.period.EndTime = datetime.datetime.now() + datetime.timedelta(minutes = 5)
    
    def Frame(self, phase):
        # update stimulus parameters if they need to be animated on a frame-by-frame basis
        pass
        
    #############################################################
    
    def Event(self, phase, event):
        if event.type == pygame.locals.KEYDOWN:
            if event.key in [pygame.K_UP, pygame.K_LEFT, pygame.K_DOWN, pygame.K_RIGHT]:
                if event.key == pygame.K_UP: self.stimulator.intensity = self.stimulator.intensity + 1
                if event.key == pygame.K_LEFT: self.stimulator.intensity = self.stimulator.intensity + 0.1
                if event.key == pygame.K_DOWN: self.stimulator.intensity = self.stimulator.intensity - 1
                if event.key == pygame.K_RIGHT: self.stimulator.intensity = self.stimulator.intensity - 0.1
            print ("stim intensity " + str(self.stimulator.intensity))
    #############################################################
    
    def StopRun(self):
        self.stimuli['cue'].on = False
        self.stimuli['arrow'].on = False
        self.stimuli['fixation'].on = False
        for snd in self.sounds: snd.vol = 0.0
        self.period.EndTime = datetime.datetime.now() + datetime.timedelta(minutes = 5)