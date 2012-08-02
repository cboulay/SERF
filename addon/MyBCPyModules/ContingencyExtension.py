#===============================================================================
# The application will not be able to exit out of the Task phase
# unless the contingency criteria are met.
# Contingency criteria are only evaluated during process.
# Expects ContingentChannel's signal to be scaled so 1.0 means something (variance, maximum, baseline)
#  -e.g., isometric contraction: EMG input between 0 and 1, and 1=MVC
#  -e.g., ERD threshold: channel input has mean 0 and variance=1
#===============================================================================


import numpy as np
import random
import time

class Template(object):
    params = [
              #"Tab:SubSection DataType Name= Value DefaultValue LowRange HighRange // Comment (identifier)",
              #See further details http://bci2000.org/wiki/index.php/Technical_Reference:Parameter_Definition
            "PythonApp:Contingency    int            ContingencyEnable= 1 1 0 1 // Enable: 0 no, 1 yes (boolean)",
            "PythonApp:Contingency    float        ISIMin= 5 5 2 % // Minimum time s between stimuli",
            "PythonApp:Contingency    list            ContingentChannel= 1 EDC % % % // Processed-channel on which the trigger is contingent",
            "PythonApp:Contingency    float        DurationMin= 2.6 2.6 0 % // Duration s which signal must continuously meet criteria before triggering",
            "PythonApp:Contingency    float        DurationRand= 0.3 0.3 0 % // Randomization s around the duration",
            "PythonApp:Contingency    floatlist    ContingencyRange= {Min Max} 0.07 0.13 0 0 % //Min and Max for signal amplitude criteria",
            #"PythonApp:Contingency     int         RangeEnter= 0 0 0 2 // Signal must enter range from: 0 either, 1 below, 2 above (enumeration)",
            "PythonApp:Contingency     string     CriteriaMetColor= 0x00FF00 0xFFFFFF 0x000000 0xFFFFFF // Color of feedback when signal criteria met (color)",
            "PythonApp:Contingency     string     CriteriaOutColor= 0xCBFFCF 0xFFFFFF 0x000000 0xFFFFFF // Color of feedback when signal criteria not met (color)",
            "PythonApp:Contingency     string     BGColor= 0x000000 0x000000 0x000000 0xFFFFFF // Color of background (color)",
            "PythonApp:Contingency     string    InRangeBGColor= 0x000000 0x000000 0x000000 0xFFFFFF // Color of background indicating target range (color)",
            "PythonApp:Contingency     int        FeedbackType= 0 0 0 2 // Feedback type: 0 bar, 1 trace, 2 cursor (enumeration)",#Only supports bar for now
            "PythonApp:Contingency     int        RangeMarginPcnt= 20 20 0 % // Percent of the display to use as a margin around the range",
            
        ]
    states = [
            "Inrange 2 0 0 0", #1 for Inrange, 0 for Outrange. This is not a phase state, but actually reflects the signal.
        ]
    
    @classmethod
    def preflight(cls, app, sigprops):
        if int(app.params['ContingencyEnable'])==1:
            #Not yet supported
            #if self.params['RangeEnter'].val: raise EndUserError, "RangeEnter not yet supported"
            
            # Make sure ContingentChannel is in the list of channels.
            chn = app.inchannels()
            pch = app.params['ContingentChannel'].val
            use_process = len(pch) != 0
            if use_process:
                if False in [isinstance(x, int) for x in pch]:
                    nf = filter(lambda x: not str(x) in chn, pch)
                    if len(nf): raise EndUserError, "ContingentChannel %s not in module's list of input channel names" % str(nf)
                    app.procchan = [chn.index(str(x)) for x in pch]
                else:
                    nf = [x for x in pch if x < 1 or x > len(chn) or x != round(x)]
                    if len(nf): raise EndUserError, "Illegal ContingentChannel: %s" % str(nf)
                    app.procchan = [x-1 for x in pch]        
            else:
                raise EndUserError, "Must supply ContingentChannel"
            
            #Check that the amplitude range makes sense.
            amprange=app.params['AmplitudeRange'].val
            if len(amprange)!=2: raise EndUserError, "AmplitudeRange must have 2 values"
            if amprange[0]>amprange[1]: raise EndUserError, "AmplitudeRange must be in increasing order"
            app.amprange=np.asarray(amprange,dtype='float64')
    
    @classmethod
    def initialize(cls, app, indim, outdim):
        if int(app.params['ContingencyEnable'])==1:
            #Target box:
        
            #There is a linear transformation from amplitude to screen coordinates for the y-dimension
            #The equation is y=mx+b where y is the screen coordinates, x is the signal amplitude, b is the screen coordinate for 0-amplitude, and m is the slope.
            mgn=float(app.params['RangeMarginPcnt'].val)/100
            margin=(max(app.amprange[1],0)-min(app.amprange[0],0))*mgn    #Add a margin around the full range
            plot_max=max(app.amprange[1]+margin,0+margin)                    #With the margin, what is the new max...
            plot_min=min(app.amprange[0]-margin,0-margin)                    #... and the new min plot range.
            m=app.scrh/(plot_max-plot_min)                                        #From the range we can get the slope
            b=-1*m*plot_min                                                    #From the slope we can get the intercept
            #Setup the target box
            target_box = Block(position=(0,m*app.amprange[0]+b), size=(app.scrw,m*(app.amprange[1]-app.amprange[0])), color=(1,0,0,0.5), anchor='lowerleft')
            app.stimulus('target_box', z=1, stim=target_box)
            #Setup the feedback bar
            app.addbar(color=(0,1,0), pos=(app.scrw/2.0,b), thickness=app.scrw/10, fac=m)
            app.stimuli['bartext_1'].position=(50,50)
            app.stimuli['bartext_1'].color=[0,0,0]
            app.stimuli['bartext_1'].color=[0,1,0]
            
            app.dmin=int(ceil(app.params['DurationMin'].val * app.eegfs / app.spb)) #Convert DurationMin to blocks        
            app.drand=int(ceil(app.params['DurationRand'].val * app.eegfs / app.spb)) #Convert DurationRand to blocks
            
            addstatemonitor(self, 'Inrange')
            
        
    @classmethod
    def halt(cls,app):
        if int(app.params['ContingencyEnable'])==1: pass
    
    @classmethod
    def startrun(cls,app):
        if int(app.params['ContingencyEnable'])==1:
            self.forget('stim_trig')#Pretend that there was a stimulus at time 0 so that the min ISI check works on the first trial.
            self.forget('range_ok')
    
    @classmethod
    def stoprun(cls,app):
        if int(app.params['ContingencyEnable'])==1: pass
    
    @classmethod
    def transition(cls,app,phase):
        if int(app.params['ContingencyEnable'])==1:
            if phase == 'intertrial':
                app.mindur = app.dmin + randint(-1*app.drand,app.drand)#randomized EMG contingency duration
                
            elif phase == 'baseline':
                pass
            
            elif phase == 'gocue':
                pass
                
            elif phase == 'task':
                app.remember('range_ok')
                
            elif phase == 'response':
                self.remember('stim_trig')
            
            elif phase == 'stopcue':
                pass
            
            
            
    
    @classmethod
    def process(cls,app,sig):
        if int(app.params['ContingencyEnable'])==1:
            #Convert input signal to scalar
            x = sig[app.procchan,:].mean(axis=1)#still a matrix
            x=float(x)#single value
            
            #===================================================================
            # Update whether or not we are in range based on the signal
            #===================================================================
            now_in_range = (x >= app.amprange[0]) and (x <= app.amprange[1])
            self.states['Inrange'] = now_in_range #update state
            if app.changed('Inrange', only=1): app.remember('range_ok')
            rangeok = app.since('range_ok')['msec'] >= app.mindur
            isiok = app.since('stim_trig')['msec'] >= 1000.0 * float(self.params['ISIMin'])
            enterok = True #TODO: Check entry direction condition.
            app.contingency_met = rangeok and isiok and enterok
            
            #app.updatebars(x)#Update visual stimulus based on x
            app.stimuli['target_box'].color = [1-rangeok, rangeok, 0]
            

    @classmethod
    def event(cls, app, phasename, event):
        if int(app.params['ContingencyEnable'])==1: pass