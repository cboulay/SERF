import numpy as np
import random
from AppTools.StateMonitors import addstatemonitor
from AppTools.Boxes import box
from AppTools.Shapes import PolygonTexture, Disc, Block
import WavTools

class FeedbackApp(object):
    params = [
              #"Tab:SubSection DataType Name= Value DefaultValue LowRange HighRange // Comment (identifier)",
              #See further details http://bci2000.org/wiki/index.php/Technical_Reference:Parameter_Definition
            "Feedback:Design    int          ContFeedbackEnable=  1 1 0 1 // Enable: 0 no, 1 yes (boolean)",
            "Feedback:Design    list         FeedbackChannels=    1 EDC % % % // Channel for feedback (max 1 channel for now)",
            #Sometimes we want to save some data (via ERPExtension) that is not fed back,
            #so the signal processing module will pass in more data than we need for feedback. Thus we need to select FeedbackChannels.
            "Feedback:Design    int          BaselineFeedback=    0 % % % // Should feedback be provided outside task? (boolean)",
            "Feedback:Design    int          BaselineConstant=    0 % % % // Should baseline feedback be constant? (boolean)",
            "Feedback:Design    int          FakeFeedback=        0 % % % // Make feedback contingent on an external file (boolean)",
            "Feedback:Design    string       FakeFile=            % % % % // Path to fake feedback csv file (inputfile)",
            "Feedback:Visual    int          VisualFeedback=      1 1 0 1 // Show online feedback? (boolean)",
            "Feedback:Visual    int          VisualType=          0 0 0 2 // Feedback type: 0 bar, 1 cursor, 2 none (enumeration)",
            "Feedback:Visual    int          UseContForColor=     0 0 0 1 // Feedback color follows contingency: 0 no, 1 yes (boolean)",
            "Feedback:Audio     int          AudioFeedback=       1 0 0 1 // Play continuous sounds? (boolean)",
            "Feedback:Audio     matrix       AudioWavs=           2 1 300hz.wav 900hz.wav % % % // feedback wavs",
            "Feedback:Handbox   int          HandboxFeedback=     1 0 0 1 // Move handbox? (boolean)",
            "Feedback:Handbox   string       HandboxPort=         COM7 % % % // Serial port for controlling Handbox",
            "Feedback:NMES      int          NMESFeedback=        0 % 0 1 // Enable neuromuscular stim feedback? (boolean)",
            "Feedback:NMES      floatlist    NMESRange=           {Mid Max} 7 15 0 0 % //Midpoint and Max stim intensities",
            "Feedback:NMES      string       NMESPort=            COM10 % % % // Serial port for controlling NMES",
        ]
    states = [
              #Name Length(nBits up to 32) Value ByteLocation(in state vector) BitLocation(0 to 7) CRLF
            #http://bci2000.org/wiki/index.php/Technical_Reference:State_Definition
            #Typically, state values change once per block or once per trial.
            #State values are saved per block.
            #"SpecificState 1 0 0 0", #Define states that are specific to this extension.
            "FBValue    16 0 0 0", #in blocks, 16-bit is max 65536
            "FBBlock   16 0 0 0", #Number of blocks that feedback has been on. Necessary for fake feedback.
            "FeedbackOn 1 0 0 0", #Whether or not stimuli are currently presented.
        ]
    
    @classmethod
    def preflight(cls, app, sigprops):
        if int(app.params['ContFeedbackEnable'])==1:
            
            # Check FeedbackChannels
            chn = app.inchannels()
            fch = app.params['FeedbackChannels'].val
            if len(fch)==0: raise EndUserError, "Must supply FeedbackChannel"
            if False in [isinstance(x, int) for x in fch]:
                nf = filter(lambda x: not str(x) in chn, fch)
                if len(nf): raise EndUserError, "FeedbackChannel %s not in module's list of input channel names" % str(nf)
                app.fbchan = [chn.index(str(x)) for x in fch]
            else:
                nf = [x for x in pch if x < 1 or x > len(chn) or x != round(x)]
                if len(nf): raise EndUserError, "Illegal FeedbackChannel: %s" % str(nf)
                app.fbchan = [x-1 for x in fch]      
            
            #TODO: Check if FollowContingency is set that ContingencyEnable is a param and is set.
    
    @classmethod
    def initialize(cls, app, indim, outdim):
        if int(app.params['ContFeedbackEnable'])==1:
            if int(app.params['ShowSignalTime']): addstatemonitor(app, 'FeedbackOn')
            
            #===================================================================
            # Load fake data if we will be using fake feedback.
            #===================================================================
            if int(app.params['FakeFeedback']):
                import csv
                fp=app.params['FakeFile']
                app.fake_data = np.genfromtxt(fp, delimiter=',')
                np.random.shuffle(app.fake_data)
            
            #===================================================================
            # We need to know how many blocks per feedback period
            # so feedback can be scaled appropriately.
            #===================================================================
            fbdur = app.params['TaskDur'].val #feedback duration
            fbblks = fbdur * app.eegfs / app.spb #feedback blocks
            
            #===================================================================
            # Visual Feedback
            #===================================================================
            if app.params['VisualFeedback'].val:
                #===================================================================
                # Set a coordinate frame for the screen.
                #===================================================================
                scrsiz = min(app.scrw,app.scrh)
                siz = (scrsiz, scrsiz)
                b = box(size=siz, position=(app.scrw/2.0,app.scrh/2.0), sticky=True)
                center = b.map((0.5,0.5), 'position')
                #===================================================================
                # Arrow stimulus for pointing toward the target during gocue.
                #===================================================================
                b.scale(x=0.25,y=0.4)#How big should the arrow be, relative to the screen size
                arrow = PolygonTexture(frame=b, vertices=((0.22,0.35),(0,0.35),(0.5,0),(1,0.35),(0.78,0.35),(0.78,0.75),(0.22,0.75),),\
                                    color=(1,1,1), on=False, position=center)
                app.stimulus('arrow', z=4.5, stim=arrow)#Register the arrow stimulus.
                b.scale(x=4.0, y=2.5)#Reset the box
                b.anchor='center'#Reset the box
                
                #===============================================================
                # Target stimuli.
                # Targets are rectangles 8% the screen height and the entire width
                # of the screen, at the top and bottom.
                #===============================================================
                targth = 0.08#float(app.params['TargetSize'])
                
                # the green target rectangle
                b.anchor='top'
                b.scale(y=targth)
                app.positions['green'] = np.matrix(b.position)
                green = Block(position=b.position, size=b.size, color=(0.1,1,0.1))#, on=False
                app.stimulus('green', z=2, stim=green)
                b.scale(y=1.0/targth)#reset b
                b.anchor='center'#reset b
            
                # the red target rectangle
                b.anchor='bottom'
                b.scale(y=targth)
                app.positions['red'] = np.matrix(b.position)
                red = Block(position=b.position, size=b.size, color=(1,0.1,0.1))#, on=False
                app.stimulus('red', z=2, stim=red)
                b.scale(y=1.0/targth)#reset b
                b.anchor='center'#reset b
                
                #===============================================================
                # The feedback bar.
                #===============================================================
                if int(app.params['VisualType'])==0:
                    #===========================================================
                    # The input signal will vary from -10 to +10, where 1 is the variance (spectral) or 10 is MVC
                    # The contingency parameter operates in this range (-10 +10)
                    # However, the feedback app operates in the range -3.2767 to +3.2767
                    # So, for feedback, the input signal gets divided by 3 (and is clipped)
                    #===========================================================
                    plot_min=-3.2767#The input signal will vary from -3.2767 to +3.2767
                    plot_max=3.2767
                    m=app.scrh/(plot_max-plot_min)#Conversion factor from signal amplitude to pixels.
                    b_offset=app.scrh/2.0 #Input 0.0 should be at this pixel value.
                    app.addbar(color=(0,1,0), pos=(app.scrw/2.0,b_offset), thickness=app.scrw/10, fac=m)
                    app.stimuli['bartext_1'].position=(50,50)
                    #app.stimuli['bartext_1'].color=[1,1,1]
                    app.stimuli['bartext_1'].color=[0,0,0]
                    if app.params.has_key('ContingencyEnable') and app.params['ContingencyEnable'].val:
                        target_box = Block(position=(app.scrw/2 - app.scrw/10,m*app.amprange[0]/3.0+b_offset), size=(app.scrw/5,m*(app.amprange[1]-app.amprange[0])/3.0), color=(1,0,0,0.5), anchor='lowerleft')
                        app.stimulus('target_box', z=1, stim=target_box)
                
                #===============================================================
                # The feedback cursor.
                #===============================================================
                elif int(app.params['VisualType'])==1:
                    app.stimulus('cursor1', z=3, stim=Disc(radius=10, color=(1,1,1), on=False))
                    #Set cursor speed so that it takes entire feedback duration to go from bottom to top at amplitude 1
                    top_t = app.p[1,1]
                    bottom_t = app.p[0,1]
                    app.curs_speed = (top_t - bottom_t) / fbblks #pixels per block

            #===================================================================
            # Audio Feedback
            #===================================================================
            if app.params['AudioFeedback'].val:    
            # load, and silently start, the sounds
            # They will be used for cues and for feedback.
                app.sounds = []
                wavmat = app.params['AudioWavs']
                for i in range(len(wavmat)):
                    wavlist = wavmat[i]
                    if len(wavlist) != 1: raise EndUserError, 'FeedbackWavs matrix should have 1 column'
                    try: snd = WavTools.player(wavlist[0])
                    except IOError: raise EndUserError, 'failed to load "%s"'%wavlist[0]
                    app.sounds.append(snd)
                    snd.vol = 0
                    snd.play(-1)
                #Set the speed at which the fader can travel from -1 (sounds[0]) to +1 (sounds[1])
                app.fader_speed = 2 / fbblks
            
            #===================================================================
            # Handbox Feedback
            #===================================================================
            if app.params['HandboxFeedback'].val:
                from Handbox.HandboxInterface import Handbox
                serPort=app.params['HandboxPort'].val
                app.handbox=Handbox(port=serPort)
                #When x is +1, we have ERD relative to baseline
                #It should take fbblks at x=+1 to travel from 90 to 0
                app.hand_speed = -90 / fbblks #hand speed in degrees per block when x=+1
                
            #===================================================================
            # Neuromuscular Electrical Stimulation Feedback
            #===================================================================
            if app.params['NMESFeedback'].val:
                stimrange=np.asarray(app.params['NMESRange'].val,dtype='float64')#midpoint and max
                stim_min = 2*stimrange[0] - stimrange[1]
                from Handbox.NMESInterface import NMES
                serPort=app.params['NMESPort'].val
                app.nmes=NMES(port=serPort)
                app.nmes.width = 1.0
                
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
        
    @classmethod
    def halt(cls,app):
        if int(app.params['ContFeedbackEnable'])==1:
            #TODO: Delete app.nmes, app.handbox, remove the meters.
            pass
    
    @classmethod
    def startrun(cls,app):
        if int(app.params['ContFeedbackEnable'])==1:
            if app.params['VisualFeedback'].val and int(app.params['VisualType'])==1:
                app.stimuli['cursor1'].position = app.positions['origin'].A.ravel().tolist()
            if int(app.params['NMESFeedback']):
                app.nmes_i = 0
                app.nmes.intensity = 0
    
    @classmethod
    def stoprun(cls,app):
        if int(app.params['ContFeedbackEnable'])==1:
            if app.params['AudioFeedback'].val:
                for snd in app.sounds: snd.vol = 0.0
            if int(app.params['NMESFeedback']):
                app.nmes.stop()
    
    @classmethod
    def transition(cls,app,phase):
        if app.params['ContFeedbackEnable'].val:
            app.states['FeedbackOn'] = phase=='task' or app.params['BaselineFeedback'].val
            #===================================================================
            # Turn transient (i.e. visual) stimuli on/off
            # The other stimuli are not turned on/off so easily.
            # Instead their amplitudes are set by process()
            #===================================================================
            if app.params['VisualFeedback'].val:
                app.stimuli['arrow'].on = phase == 'gocue'
                app.stimuli['red'].on = app.states['FeedbackOn']
                app.stimuli['green'].on = app.states['FeedbackOn']
                if int(app.params['VisualType'])==0:
                    for bar in app.bars: bar.rectobj.parameters.on = app.states['FeedbackOn']
                    if app.params.has_key('ContingencyEnable') and app.params['ContingencyEnable'].val:
                        app.stimuli['target_box'].on = app.states['FeedbackOn']
                elif int(app.params['VisualType'])==1:
                    app.stimuli['cursor1'].on = app.states['FeedbackOn']
            
            if not app.states['FeedbackOn']:        
                if app.params['AudioFeedback'].val:
                    for snd in app.sounds: snd.vol=0.0
                if int(app.params['NMESFeedback']): app.nmes.intensity = 0
                if int(app.params['HandboxFeedback']): app.handbox.position = 45

            if phase == 'intertrial':
                app.states['FBBlock']=0
                
            elif phase == 'baseline':
                pass
            
            #Visual and/or auditory cues.
            elif phase == 'gocue':
                t = app.states['TargetCode']
                if app.params['VisualFeedback'].val:
                    app.stimuli['arrow'].color = map(lambda x:int(x==t), [2,1,3])
                    app.stimuli['arrow'].angle = 180*(2 - t)
                if app.params['AudioFeedback'].val:
                    app.sounds[1-t].vol=0.0
                    app.sounds[t].vol=1.0
                
            elif phase == 'task':
                pass
                
            elif phase == 'response':
                pass
            
            elif phase == 'stopcue':
                pass
    
    @classmethod
    def process(cls,app,sig):
        if int(app.params['ContFeedbackEnable'])==1 and app.states['FeedbackOn']:
            if app.params['FakeFeedback'].val:
                trial_i = app.states['CurrentTrial']-1 if app.states['CurrentTrial'] < app.fake_data.shape[0] else random.uniform(0,app.params['TrialsPerBlock'])
                fake_block_ix = np.min((app.fake_data.shape[1],app.states['FBBlock']))
                x = app.fake_data[trial_i,fake_block_ix]
                x = -1 * x / 3
                x = min(x, 3.2768)
                x = max(x, -3.2767)
            else:
                #Input signals should have mean=0, variance=1. Most signals will have extremes of -10 and +10
                x = sig[app.fbchan,:].mean(axis=1)#Extract the feedback channels.
                x = x.A.ravel()[0]/3#Transform x to a measure from -3 to +3 SDs.
                x = min(x, 3.2768)
                x = max(x, -3.2767)
            
            #Save x to a state of uint16
            temp_x = x * 10000
            app.states['FBValue'] = np.uint16(temp_x)
            app.states['FBBlock'] = app.states['FBBlock'] + 1
            
            #Pull x back from the state. This is useful in case enslave states is used.
            x = np.int16(app.states['FBValue']) / 10000.0
            
            if app.params['VisualFeedback'].val:
                if int(app.params['VisualType'])==0:#bar
                    app.updatebars(0.0 if (app.states['Baseline'] and app.params['BaselineConstant']) else x)
                    #for bar in app.bars: bar.rectobj.parameters.color = [1-app.states['InRange'], app.states['InRange'], 0]
                elif int(app.params['VisualType'])==1:#cursor
                    new_pos = app.stimuli['cursor1'].position
                    new_pos[1] = new_pos[1] + app.curs_speed * x#speed is pixels per block
                    new_pos[1] = min(new_pos[1],app.p[1,1])
                    new_pos[1] = max(new_pos[1],app.p[0,1])
                    app.stimuli['cursor1'].position = app.positions['origin'].A.ravel().tolist()\
                        if app.states['Baseline'] and app.params['BaselineConstant'] else new_pos
                        
                #===============================================================
                # Modify the color of the visual cues if we know the range.
                #===============================================================
                if app.params['UseContForColor'].val and app.states.has_key('InRange'):
                    if app.stimuli.has_key('target_box'): app.stimuli['target_box'].color = [1-app.states['InRange'], app.states['InRange'], 0]
                    app.stimuli['fixation'].color = [1-app.states['InRange'], app.states['InRange'], 0]
                    
            if app.params['AudioFeedback'].val:
                #app.fader_val from -1 to +1
                #can increment or decrement at app.fader_speed
                app.fader_val = app.fader_val + app.fader_speed * x
                app.fader_val = min(1, app.fader_val)
                app.fader_val = max(-1, app.fader_val)
                if app.states['Baseline'] and app.params['BaselineConstant']: app.fader_val = 0
                app.sounds[0].vol = 0.5 * (1 - app.fader_val)
                app.sounds[1].vol = 0.5 * (1 + app.fader_val)
            
            if app.params['HandboxFeedback'].val:
                angle = app.handbox.position
                angle = angle + app.hand_speed * x
                if app.states['Baseline'] and app.params['BaselineConstant']: angle = 45
                app.handbox.position = angle
                
            if app.params['NMESFeedback'].val:
                app.nmes_i = app.nmes_i + app.nmes_speed * x
                app.nmes_i = min(app.nmes_i, app.nmes_max)
                app.nmes_i = max(app.nmes_i, 2*app.nmes_baseline - app.nmes_max, 0)
                if app.states['Baseline'] and app.params['BaselineConstant']:
                    if abs(app.nmes_i-app.nmes_baseline)<1: app.nmes_i = app.nmes_baseline
                    elif app.nmes_i > app.nmes_baseline: app.nmes_i = app.nmes_i - app.nmes_speed
                    elif app.nmes_i < app.nmes_baseline: app.nmes_i = app.nmes_i + app.nmes_speed
                elif not (app.nmes.intensity==int(app.nmes_i)): app.nmes.intensity = int(app.nmes_i)

    @classmethod
    def event(cls, app, phasename, event):
        if int(app.params['ContFeedbackEnable'])==1: pass