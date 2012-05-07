# Each trial has 7 phases:
# 1 - intertrial (100 ms)
# 2 - baseline (3000 ms)
# 3 - startcue (1000 ms)
# 4 - gap (400 ms)
# 5 - imagine (3000 +/- 500 ms; no feedback)
# 6 - response (1000 ms; includes stimulus at beginning of response)
# 7 - endcue (1000 ms)
# The cue is provided as text on the screen

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
from EeratAPI.OnlineAPIExtension import *
from StimExtension import MEP, HR, MAPPING, IOCURVE, SICI

class BciApplication(BciGenericApplication):

    def Description(self):
        return "Cue motor imagery trials and stimulate during imagery."

    def Construct(self):
        self.define_param(
            "PythonApp:Design     int            ExperimentType= 0 0 0 4 // Experiment Type: 0 MEPMapping, 1 MEPRecruitment, 2 MEPSICI, 3 HRHunting, 4 HRRecruitment (enumeration)",
            "PythonApp:Design     float          StimIntensity= 30 30 0 100 // 0-50 for DS5, 0-100 for Single-Pulse, 0-100 for Bistim Cond",
            "PythonApp:Design     list           TriggerInputChan= 1 TMSTrig % % % // Name of channel used to monitor trigger / control ERP window",
            "PythonApp:Design     float          TriggerThreshold= 10000 1 0 % // If monitoring trigger, use this threshold to determine ERP time 0",
            "PythonApp:Design     list           ERPChan= 1 EDC % % % // Name of channel used for ERP",
            "PythonApp:Design     floatlist      ERPWindow= {Start Stop} -500 500 0 % % // ERP window, relative to trigger onset, in millesconds",
            "PythonApp:Design     int            ShowFixation= 0     0     0   1  // show a fixation point in the center (boolean)",
            "PythonApp:Screen     int            ScreenId= -1    -1     %   %  // on which screen should the stimulus window be opened - use -1 for last",
            "PythonApp:Screen     float          WindowSize= 0.8   1.0   0.0 1.0 // size of the stimulus window, proportional to the screen",
            "PythonApp:Stimuli    float          TargetSize= 0.08   0.08   0.0 0.5 // thickness of the target rectangles relative to the screen height",
            "PythonApp:Stimuli    matrix         CueWavs= 1 1 900hz.wav % % % // Cue wav",
		)
        params.extend(MEP.params)
        params.extend(SICI.params)
        params.extend(IOCURVE.params)
        
        self.define_state(
			"Baseline   1 0 0 0",
			"StartCue   1 0 0 0",
			"Feedback   1 0 0 0",
			"StopCue    1 0 0 0",
			"TargetCode	2 0 0 0", # should the subject be imagining feet (1), left hand (2), right hand (3), or resting (0 during 'baseline' phase) ?
            "Value     16 0 0 0", #in blocks, 16-bit is max 65536
            "StimulatorIntensity 16 0 0 0", #So it is saved off-line analysis
            "StimulatorReady 1 0 0 0", #Whether or not stimulator is ready to trigger.
            "Trigger 1 0 0 0",
            "Response 1 0 0 0",
		)
        states.extend(MEP.states)
        states.extend(SICI.states)

    def Preflight(self, sigprops):

        
        #if not self.in_signal_dim[0] in (self.nclasses, self.nclasses+1):
		#	raise EndUserError,'%d- or %d-channel input expected' % (self.nclasses,self.nclasses+1)

        siz = float(self.params['WindowSize'])
        screenid = int(self.params['ScreenId'])  # ScreenId 0 is the first screen, 1 the second, -1 the last
        fullscreen(scale=siz, id=screenid, frameless_window=(siz==1))
        # only use a borderless window if the window is set to fill the whole screen

    def Initialize(self, indim, outdim):
        
        # compute how big everything should be
        scrw,scrh = self.screen.size
        scrsiz = min(scrw,scrh)
        siz = (scrsiz, scrsiz)
        targth = float(self.params['TargetSize'])
        
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
        		
        # store the significant points on the screen for later use
        self.p = np.concatenate((self.positions['red'],self.positions['green']), axis=0)
        
        # let's have a black background
        self.screen.color = (0,0,0)
        
        # OK, now register all those stimuli, plus a few more, with the framework
        self.stimulus('arrow',    z=4.5, stim=arrow)
        self.stimulus('cue',      z=5,   stim=VisualStimuli.Text(text='?', position=center, anchor='center', color=(1,1,1), font_size=50, on=False))
        self.stimulus('fixation', z=4.2, stim=Disc(position=center, radius=5, color=(1,1,1), on=False))
        
        # set up the strings that are going to be presented in the 'cue' stimulus
        self.cuetext = ['pause', 'imagery']

        eegfs=self.nominal['SamplesPerSecond'] #Sampling rate
        spb=self.nominal['SamplesPerPacket'] #Samples per block
        #fbdur = self.params['FeedbackDuration'].val #feedback duration
        fbblks = 3 * eegfs / spb #feedback blocks
            
        # load, and silently start, the sounds
        # They will be used for cues and maybe for feedback.
        self.sounds = []
        wavmat = self.params['FeedbackWavs']
        for i in range(len(wavmat)):
            wavlist = wavmat[i]
            if len(wavlist) != 1: raise EndUserError, 'FeedbackWavs matrix should have 1 column'
            try: snd = WavTools.player(wavlist[0])
            except IOError: raise EndUserError, 'failed to load "%s"'%wavlist[0]
            self.sounds.append(snd)
            snd.vol = 0
            snd.play(-1)
        
        # finally, some fancy stuff from AppTools.StateMonitors, for the developer to check
        # that everything's working OK
        if int(self.params['ShowSignalTime']):
            # turn on state monitors iff the packet clock is also turned on
            addstatemonitor(self, 'Running', showtime=True)
            addstatemonitor(self, 'CurrentBlock')
            addstatemonitor(self, 'CurrentTrial')
            addstatemonitor(self, 'TargetCode')
            addstatemonitor(self, 'Value')

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

    def StartRun(self):
        self.stimuli['cursor1'].position = self.positions['origin'].A.ravel().tolist()
        if int(self.params['ShowFixation']):
			self.stimuli['fixation'].on = True

    def Phases(self):
        self.phase(name='intertrial',   next='baseline',    duration=randint(1000,3000))
        self.phase(name='baseline',     next='startcue',    duration=3000)
        self.phase(name='startcue',     next='gap',         duration=1000)
        self.phase(name='gap',          next='imagine',     duration=800)
        self.phase(name='imagine',      next='stopcue',     duration=1000*self.params['FeedbackDuration'].val)
        self.phase(name='stopcue',      next='intertrial',  duration=1000)
        
        self.design(start='intertrial', new_trial='baseline', interblock='idle')

    def Transition(self, phase):
        # record what's going
        self.states['Baseline'] = int(phase in ['baseline'])
        self.states['StartCue'] = int(phase in ['startcue'])
        self.states['StopCue']  = int(phase in ['stopcue'])
        self.states['Feedback'] = int(phase in ['imagine'])
        
        self.stimuli['cue'].on = (phase in ['startcue', 'stopcue'])
        self.stimuli['arrow'].on = (phase in ['startcue'])
        
        if phase == 'intertrial':
            pass

        if phase == 'baseline':
            self.states['TargetCode'] = 0

        if phase != 'imagine' and not int(self.params['BaselineFeedback']):
            self.sounds[0].vol = 0
            self.sounds[1].vol = 0
        
        if phase == 'startcue':
            if int(self.params['AlternateTargets']): self.states['TargetCode'] = 1 + self.states['CurrentTrial'] % self.nclasses
            else: self.states['TargetCode'] = randint(1,self.nclasses)
            t = self.states['TargetCode']
            self.stimuli['cue'].text = self.cuetext[t]
            self.stimuli['arrow'].color = map(lambda x:int(x==t), [1,2,3])
            self.stimuli['arrow'].angle = 180*(t - 1)
            self.sounds[t-1].vol = 1
            self.sounds[2-t].vol = 0
        
        if phase == 'gap':
            #Turn off the audio cue.
            self.sounds[0].vol = 0
            self.sounds[1].vol = 0
        
        if phase == 'imagine':
            pass
            
        if phase == 'stopcue':
            self.stimuli['cue'].text = self.cuetext[0]

    def Process(self, sig):
        #Normalizer is set such that sig will be mean 0 and variance = 1 relative to baseline
        #Convert x to a measure of excitability (ERD) from -3 to +3 SDs.
        x = -1*sig.A.ravel()[0]/3
        
        #These max/min bounds are due to the number of bits the state can store.
        x = min(x, 3.2768)
        x = max(x, -3.2767)
        #Save x to a state of uint16
        temp_x = x * 10000
        self.states['Value']=np.uint16(temp_x)
            
    def StopRun(self):
        self.states['Feedback'] = 0
        self.stimuli['cue'].on = False
        self.stimuli['arrow'].on = False
        self.stimuli['cursor1'].on = False
        self.stimuli['cursor1'].position = self.positions['origin'].A.ravel().tolist()
        self.stimuli['fixation'].on = False
        for snd in self.sounds: snd.vol = 0.0
        #if self.nmes: self.nmes.amplitude = 0