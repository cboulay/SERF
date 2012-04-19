# Each trial has 6 phases:
# 1 - intertrial
# 2 - baseline
# 3 - startcue
# 4 - gap
# 5 - imagine (with feedback)
# 6 - endcue
# The cue is provided as:
# 1 - a target on the screen
# 2 - an auditory tone
# This application gives feedback about the input as:
# 1 - vertical position of a cursor
# 2 - degree extension of a motorized hand extension box
# 3 - auditory tone

import numpy
from random import randint

from AppTools.Boxes import box
from AppTools.Displays import fullscreen
from AppTools.Shapes import PolygonTexture, Disc, Block
from AppTools.StateMonitors import addstatemonitor, addphasemonitor

# from pygame import mixer; from pygame.mixer import Sound
# from WavTools.FakePyGame import mixer, Sound # would provide a workalike interface to the line above
                                               #
import WavTools                                # but let's get into the habit of using WavTools.player
                                               # explicitly, since it is more flexible, and its timing
                                               # is now more reliable than that of pygame.mixer.Sound

class BciApplication(BciGenericApplication):

    def Description(self):
        return "Cursor or handbox control."

    def Construct(self):
        self.define_param(
			"PythonApp:Design   int    AlternateTargets=    0     0     0   1  // alternate target classes rather than choosing randomly (boolean)",
			"PythonApp:Design   int    ShowFixation=        0     0     0   1  // show a fixation point in the center (boolean)",
			"PythonApp:Screen   int    ScreenId=            -1    -1     %   %  // on which screen should the stimulus window be opened - use -1 for last",
	        "PythonApp:Screen   float  WindowSize=          0.8   1.0   0.0 1.0 // size of the stimulus window, proportional to the screen",
			"PythonApp:Stimuli  float  TargetSize=          0.08   0.08   0.0 0.5 // thickness of the target rectangles relative to the screen height",
			"PythonApp:Feedback int    CursorFeedback=      1     1     0   1  // show online feedback cursor (boolean)",
			"PythonApp:Feedback int    AudioFeedback=       1     0     0   1  // play continuous sounds? (boolean)",
            "PythonApp:Feedback matrix FeedbackWavs=        3 1 feedback-drums.wav feedback-piano.wav feedback-strings.wav % % % // feedback wavs",
            "PythonApp:Feedback int    HandboxFeedback=     1     0     0   1  // move handbox? (boolean)",
            "PythonApp:Feedback string SerialPort=          COM7 % % %         // Serial port for controlling Magstim",
            "PythonApp:Feedback float  FeedbackDuration=    8    8    1 20 // Feedback duration in seconds",
			
		)
        self.define_state(
			"Baseline   1 0 0 0",
			"StartCue   1 0 0 0",
			"Feedback   1 0 0 0",   # bells? whistles?
			"StopCue    1 0 0 0",
			"TargetCode	2 0 0 0",   # should the subject be imagining feet (1), left hand (2), right hand (3), or resting (0 during 'baseline' phase) ?
            "Value     16 0 0 0", #in blocks, 16-bit is max 65536
		)

    def Preflight(self, sigprops):

        self.nclasses = 2

        if int(self.params['AudioFeedback']) and len(self.params['FeedbackWavs']) != self.nclasses:
			raise EndUserError, 'FeedbackWavs matrix should have %d rows' % self.nclasses

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
        self.positions = {'origin': numpy.matrix(center)}
        
        #Use that same box, but manipulate its properties to get positional information for the other items.
        
        # the red target rectangle
        b.anchor='bottom'
        b.scale(y=targth)
        self.positions['red'] = numpy.matrix(b.position)
        red = Block(position=b.position, size=b.size, color=(1,0.1,0.1))#, on=False
        
        #reset b
        b.scale(y=1.0/targth)
        b.anchor='center'
        
        # the green target rectangle
        b.anchor='top'
        b.scale(y=targth)
        self.positions['green'] = numpy.matrix(b.position)
        green = Block(position=b.position, size=b.size, color=(0.1,1,0.1))#, on=False
        
        #reset b
        b.scale(y=1.0/targth)
        b.anchor='center'
        
        # and the arrow
        b.scale(x=0.25,y=0.4)#How big should the arrow be, relative to the screen size
        arrow = PolygonTexture(frame=b, vertices=((0.22,0.35),(0,0.35),(0.5,0),(1,0.35),(0.78,0.35),(0.78,0.75),(0.22,0.75),), color=(1,1,1), on=False, position=center)
        
        #reset b
        b.scale(x=4.0, y=2.5)
        b.anchor='center'
        		
        # store the significant points on the screen for later use
        self.p = numpy.concatenate((self.positions['red'],self.positions['green']), axis=0)
        
        # let's have a black background
        self.screen.color = (0,0,0)
        
        # OK, now register all those stimuli, plus a few more, with the framework
        self.stimulus('red',      z=2,   stim=red)
        self.stimulus('green',    z=2,   stim=green)
        self.stimulus('cursor1',  z=3,   stim=Disc(radius=10, color=(1,1,1), on=False))
        self.stimulus('arrow',    z=4.5, stim=arrow)
        self.stimulus('cue',      z=5,   stim=VisualStimuli.Text(text='?', position=center, anchor='center', color=(1,1,1), font_size=50, on=False))
        self.stimulus('fixation', z=4.2, stim=Disc(position=center, radius=5, color=(1,1,1), on=False))
        
        # set up the strings that are going to be presented in the 'cue' stimulus
        self.cuetext = ['pause', 'rest', 'imagery']
        
        # load, and silently start, the continuous feedback sounds
        self.sounds = []
        if int(self.params['AudioFeedback']):
        	wavmat = self.params['FeedbackWavs']
        	for i in range(len(wavmat)):
        		wavlist = wavmat[i]
        		if len(wavlist) != 1: raise EndUserError, 'FeedbackWavs matrix should have 1 column'
        		try: snd = WavTools.player(wavlist[0])
        		except IOError: raise EndUserError, 'failed to load "%s"'%wavlist[0]
        		self.sounds.append(snd)
        		snd.vol = 0
        		snd.play(-1)

        eegfs=self.nominal['SamplesPerSecond'] #Sampling rate
        spb=self.nominal['SamplesPerPacket'] #Samples per block
        fbdur = self.params['FeedbackDuration'].val #feedback duration
        fbblks = fbdur * eegfs / spb #feedback blocks
        
        if int(self.params['HandboxFeedback']):
            from Handbox.HandboxInterface import Handbox
            serPort=self.params['SerialPort'].val
            self.handbox=Handbox(port=serPort)
            #When x is +1, we have ERD relative to baseline
            #It should take fbblks at x=+1 to travel from 90 to 0
            self.hand_speed = -90 / fbblks #hand speed in degrees per block when x=+1
            
        #Set cursor speed so that it takes entire feedback duration to go from bottom to top at amplitude 1
        top_t = self.p[1,1]
        bottom_t = self.p[0,1]
        self.curs_speed = (top_t - bottom_t) / fbblks #pixels per block
        
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
        self.phase(name='imagine',      next='stopcue',     duration=1000*self.params['FeedbackDuration'].val) # The 'Learn' state won't be set just yet...
        self.phase(name='stopcue',      next='intertrial',  duration=800)
        
        self.design(start='intertrial', new_trial='baseline', interblock='idle')

    def Transition(self, phase):
        # record what's going
        self.states['Baseline'] = int(phase in ['baseline'])
        self.states['StartCue'] = int(phase in ['startcue'])
        self.states['StopCue']  = int(phase in ['stopcue'])
        self.states['Feedback'] = int(phase in ['imagine'])
        
        self.stimuli['cue'].on = (phase in ['startcue', 'stopcue'])
        self.stimuli['arrow'].on = (phase in ['startcue'])

        if phase == 'baseline':
            self.states['TargetCode'] = 0

        if phase == 'startcue':
            if int(self.params['AlternateTargets']): self.states['TargetCode'] = 1 + self.states['CurrentTrial'] % self.nclasses
            else: self.states['TargetCode'] = randint(1,self.nclasses)
            t = self.states['TargetCode']
            self.stimuli['cue'].text = self.cuetext[t]
            self.stimuli['arrow'].color = map(lambda x:int(x==t), [1,2,3])
            self.stimuli['arrow'].angle = 180*(t - 1)

        if phase == 'stopcue':
            self.stimuli['cue'].text = self.cuetext[0]

    def Process(self, sig):
        #Normalizer is set such that sig will be mean 0 and variance = 1 relative to baseline
        #Convert x to a measure of excitability (ERD) from -3 to +3 SDs.
        x = -1*sig.A.ravel()[0]/3
        
        #TODO: audio volume for each sound
        
        fdbk = int(self.states['Feedback']) != 0
        if int(self.params['CursorFeedback']):
            self.stimuli['cursor1'].on = fdbk
            new_pos = self.stimuli['cursor1'].position
            new_pos[1] = new_pos[1] + self.curs_speed * x#speed is pixels per block
            new_pos[1] = min(new_pos[1],self.p[1,1])
            new_pos[1] = max(new_pos[1],self.p[0,1])
            self.stimuli['cursor1'].position = new_pos if fdbk else self.positions['origin'].A.ravel().tolist()
        #if int(self.params['AudioFeedback']):
        #    for i in range(min(len(self.sounds), len(col))):
        #        self.sounds[i].vol = col[i]
        if int(self.params['HandboxFeedback']):
            angle = self.handbox.position
            angle = angle + self.hand_speed * x
            self.handbox.position = angle if fdbk else 45


    def StopRun(self):
		
		self.states['Feedback'] = 0
		self.stimuli['cue'].on = False
		self.stimuli['arrow'].on = False
		self.stimuli['cursor1'].on = False
		self.stimuli['cursor1'].position = self.positions['origin'].A.ravel().tolist()
		self.stimuli['fixation'].on = False
		for snd in self.sounds: snd.vol = 0.0