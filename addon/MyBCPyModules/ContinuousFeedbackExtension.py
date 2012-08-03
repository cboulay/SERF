import numpy as np
import random
import time

class FeedbackApp(object):
    params = [
              #"Tab:SubSection DataType Name= Value DefaultValue LowRange HighRange // Comment (identifier)",
              #See further details http://bci2000.org/wiki/index.php/Technical_Reference:Parameter_Definition
            "PythonApp:Feedback    int    ContFeedbackEnable= 1 1 0 1 // Enable: 0 no, 1 yes (boolean)",
            "PythonApp:Feedback    int    CursorFeedback=      1     1     0   1  // show online feedback cursor (boolean)",
            "PythonApp:Feedback    int    AudioFeedback=       1     0     0   1  // play continuous sounds? (boolean)",
            "PythonApp:Feedback    matrix FeedbackWavs=        2 1 300hz.wav 900hz.wav % % % // feedback wavs",
            "PythonApp:Feedback    int    HandboxFeedback=     1     0     0   1  // move handbox? (boolean)",
            "PythonApp:Feedback    string HBPort=              COM7 % % %         // Serial port for controlling Handbox",
            "PythonApp:Feedback    int    NMESFeedback=       0 % % %         // Enable neuromuscular stim feedback? (boolean)",
            "PythonApp:Feedback    floatlist    NMESRange=     {Mid Max} 7 15 0 0 % //Midpoint and Max stim intensities",
            "PythonApp:Feedback    string NMESPort=            COM10 % % %         // Serial port for controlling NMES",
            "PythonApp:Feedback    int    BaselineFeedback=    0 % % %         // Should constant feedback be provided during baseline? (boolean)",
            "PythonApp:Feedback    int    FakeFeedback=        0 % % % // Make feedback contingent on an external file (boolean)",
            "PythonApp:Feedback    string FakeFile=            % % % % // Path to fake feedback csv file (inputfile)",
        ]
    states = [
              #Name Length(nBits up to 32) Value ByteLocation(in state vector) BitLocation(0 to 7) CRLF
            #http://bci2000.org/wiki/index.php/Technical_Reference:State_Definition
            #Typically, state values change once per block or once per trial.
            #State values are saved per block.
            #"SpecificState 1 0 0 0", #Define states that are specific to this extension.
            "FBValue     16 0 0 0", #in blocks, 16-bit is max 65536
            "FbBlock   16 0 0 0", #Number of blocks that feedback has been on. Necessary for fake feedback.
        ]
    
    @classmethod
    def preflight(cls,app):
        if int(app.params['ContFeedbackEnable'])==1: pass
    
    @classmethod
    def initialize(cls,app):
        if int(app.params['ContFeedbackEnable'])==1:
            fbdur = app.params['TaskDur'].val #feedback duration
            fbblks = fbdur * app.eegfs / app.spb #feedback blocks
            #Set cursor speed so that it takes entire feedback duration to go from bottom to top at amplitude 1
            if int(app.params['CursorFeedback']):
                top_t = app.p[1,1]
                bottom_t = app.p[0,1]
                app.curs_speed = (top_t - bottom_t) / fbblks #pixels per block
                
            # load, and silently start, the sounds
            # They will be used for cues and maybe for feedback.
            app.sounds = []
            wavmat = app.params['FeedbackWavs']
            for i in range(len(wavmat)):
                wavlist = wavmat[i]
                if len(wavlist) != 1: raise EndUserError, 'FeedbackWavs matrix should have 1 column'
                try: snd = WavTools.player(wavlist[0])
                except IOError: raise EndUserError, 'failed to load "%s"'%wavlist[0]
                app.sounds.append(snd)
                snd.vol = 0
                snd.play(-1)
            #Set the speed at which the fader can travel from -1 (ERS) to +1 (ERD)
            app.fader_speed = 2 / fbblks
            
            if int(app.params['HandboxFeedback']):
                from Handbox.HandboxInterface import Handbox
                serPort=app.params['HBPort'].val
                app.handbox=Handbox(port=serPort)
                #When x is +1, we have ERD relative to baseline
                #It should take fbblks at x=+1 to travel from 90 to 0
                app.hand_speed = -90 / fbblks #hand speed in degrees per block when x=+1
                
            if int(app.params['NMESFeedback']):
                
                stimrange=np.asarray(app.params['NMESRange'].val,dtype='float64')#midpoint and max
                stim_min = 2*stimrange[0] - stimrange[1]
                
                from Handbox.NMESInterface import NMES
                serPort=app.params['NMESPort'].val
                app.nmes=NMES(port=serPort)
                app.nmes.width = 1.0
                #app.nmes=NMES(port='COM11')
                
                #from Caio.NMES import NMESFIFO
                ##from Caio.NMES import NMESRING
                #app.nmes = NMESFIFO()
                ##app.nmes = NMESRING()
                #app.nmes.running = True
                
                #It should take fbblks at x=+1 to get intensity from min to max
                app.nmes_baseline = stimrange[0]
                app.nmes_max = stimrange[1]
                app.nmes_i = app.nmes.intensity
                app.nmes_speed = (stimrange[1]-stim_min) / float(fbblks) #nmes intensity rate of change per block when x=+1
                
                #app.nmes_baseline = stimrange[0]
                #app.nmes_max = stimrange[1]
                #for i in np.arange(0.1,2*app.nmes_baseline-app.nmes_max,0.1):
                #    app.nmes.amplitude = i
                #    time.sleep(0.1)
                #app.nmes_speed = float(2) * (app.nmes_max - app.nmes_baseline) / float(fbblks)
                
            if int(app.params['FakeFeedback']):
                import csv
                fp=app.params['FakeFile']
                app.fake_data = np.genfromtxt(fp, delimiter=',')
                np.random.shuffle(app.fake_data)
        
    @classmethod
    def halt(cls,app):
        if int(app.params['ContFeedbackEnable'])==1: pass
    
    @classmethod
    def startrun(cls,app):
        if int(app.params['ContFeedbackEnable'])==1:
            app.stimuli['cursor1'].position = app.positions['origin'].A.ravel().tolist()
            if int(app.params['NMESFeedback']):
                app.nmes_i = 0
                app.nmes.intensity = 0
    
    @classmethod
    def stoprun(cls,app):
        if int(app.params['ContFeedbackEnable'])==1:
            app.states['Feedback'] = 0
            app.stimuli['cue'].on = False
            app.stimuli['arrow'].on = False
            app.stimuli['cursor1'].on = False
            app.stimuli['cursor1'].position = app.positions['origin'].A.ravel().tolist()
            app.stimuli['fixation'].on = False
            for snd in app.sounds: snd.vol = 0.0
            if int(app.params['NMESFeedback']):
                app.nmes.stop()
    
    @classmethod
    def transition(cls,app,phase):
        if int(app.params['ContFeedbackEnable'])==1:
            
            #===================================================================
            # app.sounds[0].vol = 0
            # app.sounds[1].vol = 0
            # app.states['FbBlock']=0
            #===================================================================
                    
            if phase == 'intertrial':
                #TODO: Set cursor speed.
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
        if int(app.params['ContFeedbackEnable'])==1:
            #Normalizer is set such that sig will be mean 0 and variance = 1 relative to baseline
            #Transform x to a measure from -3 to +3 SDs.
            x = sig.A.ravel()[0]/3
            x = min(x, 3.2768)
            x = max(x, -3.2767)
            
            fdbk = int(app.states['Feedback']) != 0
            if int(app.params['FakeFeedback']) and fdbk:
                trial_i = app.states['CurrentTrial']-1 if app.states['CurrentTrial'] < app.fake_data.shape[0] else random.uniform(0,app.params['TrialsPerBlock'])
                fake_block_ix = np.min((app.fake_data.shape[1],app.states['FbBlock']))
                x = app.fake_data[trial_i,fake_block_ix]
                x = -1 * x / 3
                x = min(x, 3.2768)
                x = max(x, -3.2767)
                
            #Save x to a state of uint16
            temp_x = x * 10000
            app.states['FBValue']=np.uint16(temp_x)
            
            if fdbk: app.states['FbBlock'] = app.states['FbBlock'] + 1
            
            if int(app.params['CursorFeedback']):
                #Cursor is always moving but only visible during feedback.
                app.stimuli['cursor1'].on = fdbk
                new_pos = app.stimuli['cursor1'].position
                new_pos[1] = new_pos[1] + app.curs_speed * x#speed is pixels per block
                new_pos[1] = min(new_pos[1],app.p[1,1])
                new_pos[1] = max(new_pos[1],app.p[0,1])
                app.stimuli['cursor1'].position = new_pos if fdbk else app.positions['origin'].A.ravel().tolist()
            
            if int(app.params['AudioFeedback']):
                #app.sounds[0] is drums = ERS. app.sounds[1] is piano = ERD
                #app.fader_val from -1 to +1
                #can increment or decrement at app.fader_speed
                if fdbk: #Only let the fader change during fdbk
                    app.fader_val = app.fader_val + app.fader_speed * x
                    app.fader_val = min(1, app.fader_val)
                    app.fader_val = max(-1, app.fader_val)
                else: app.fader_val = 0
                if (fdbk or int(app.params['BaselineFeedback'])) and not int(app.states['StartCue']):
                    app.sounds[0].vol = 0.5 * (1 - app.fader_val)
                    app.sounds[1].vol = 0.5 * (1 + app.fader_val)
            
            if int(app.params['HandboxFeedback']):
                if fdbk: #Only allow the angle to change during feedback
                    angle = app.handbox.position
                    angle = angle + app.hand_speed * x
                else: angle = 45
                app.handbox.position = angle
                
            if int(app.params['NMESFeedback']):
                if fdbk: #Only allow nmes_i to change during feedback
                    app.nmes_i = app.nmes_i + app.nmes_speed * x
                    app.nmes_i = min(app.nmes_i, app.nmes_max)
                    app.nmes_i = max(app.nmes_i, 2*app.nmes_baseline - app.nmes_max, 0)
                elif abs(app.nmes_i-app.nmes_baseline)<1: app.nmes_i = app.nmes_baseline
                elif app.nmes_i > app.nmes_baseline: app.nmes_i = app.nmes_i - app.nmes_speed
                elif app.nmes_i < app.nmes_baseline: app.nmes_i = app.nmes_i + app.nmes_speed
                if fdbk or int(app.params['BaselineFeedback']):
                    if not (app.nmes.intensity==int(app.nmes_i)): app.nmes.intensity = int(app.nmes_i)
                else: app.nmes.intensity = 0
                #print app.nmes.intensity

    @classmethod
    def event(cls, app, phasename, event):
        if int(app.params['ContFeedbackEnable'])==1: pass