#===============================================================================
# The application will not be able to exit out of the Task phase
# unless the contingency criteria are met.
# Contingency criteria are only evaluated during process.
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
            "PythonApp:Contingency    float        MVIC= 600 600 0 % // MVIC in uV",
            "PythonApp:Contingency    floatlist    ContingencyRange= {Min Max} 0.08 0.12 0 0 % //Min and Max for signal amplitude criteria",
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
            "ISIExceeded 1 0 0 0",
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
            #Convert range from %MVIC to amplitude.
            self.amprange=(self.amprange/100)*self.mvic
        
            #There is a linear transformation from amplitude to screen coordinates for the y-dimension
            #The equation is y=mx+b where y is the screen coordinates, x is the signal amplitude, b is the screen coordinate for 0-amplitude, and m is the slope.
            mgn=float(self.params['RangeMarginPcnt'].val)/100
            margin=(max(self.amprange[1],0)-min(self.amprange[0],0))*mgn    #Add a margin around the full range
            plot_max=max(self.amprange[1]+margin,0+margin)                    #With the margin, what is the new max...
            plot_min=min(self.amprange[0]-margin,0-margin)                    #... and the new min plot range.
            m=scrh/(plot_max-plot_min)                                        #From the range we can get the slope
            b=-1*m*plot_min                                                    #From the slope we can get the intercept
            #Setup the target box
            target_box = Block(position=(0,m*self.amprange[0]+b), size=(scrw,m*(self.amprange[1]-self.amprange[0])), color=(1,0,0,0.5), anchor='lowerleft')
            self.stimulus('target_box', z=1, stim=target_box)
            #Setup the feedback bar
            self.addbar(color=(0,1,0), pos=(scrw/2.0,b), thickness=scrw/10, fac=m)
            self.stimuli['bartext_1'].position=(50,50)
            self.stimuli['bartext_1'].color=[0,0,0]
            
            #######################################################
            # (Convert and) Attach contingency parameters to self #
            #######################################################
            self.ISIMin=float(self.params['ISIMin'])
            self.eegfs=self.nominal['SamplesPerSecond'] #Sampling rate
            spb=self.nominal['SamplesPerPacket'] #Samples per block/packet
            self.dmin=int(ceil(self.params['DurationMin'].val * self.eegfs / spb)) #Convert DurationMin to blocks        
            self.drand=int(ceil(self.params['DurationRand'].val * self.eegfs / spb)) #Convert DurationRand to blocks
            self.enterok=False #Init to False
            self.block_dur= 1000*spb/self.eegfs#duration (ms) of a sample block
            
            addstatemonitor(self, 'Inrange')
            #addstatemonitor(self, 'SignalEnterMet')
            #addstatemonitor(self, 'SignalCriteriaMetBlocks')
            addstatemonitor(self, 'StimulatorReady')
            addstatemonitor(self, 'ISIExceeded')
            
            self.stimuli['bartext_1'].color=[0,1,0]
        
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
                pass
                
            elif phase == 'baseline':
                pass
            
            elif phase == 'gocue':
                pass
                
            elif phase == 'task':
                pass
                
            elif phase == 'response':
                self.remember('stim_trig')
            
            elif phase == 'stopcue':
                pass
            
            self.mindur=self.dmin + randint(-1*self.drand,self.drand)#randomized EMG contingency duration
            
    
    @classmethod
    def process(cls,app,sig):
        if int(app.params['ContingencyEnable'])==1:
            ###############################################
            # Update the feedback pos based on the signal #
            ###############################################
            #Convert input signal to scalar
            x = sig[app.procchan,:].mean(axis=1)#still a matrix
            x=float(x)#single value
            #app.updatebars(x)#Update visual stimulus based on x
            #self.stimuli['target_box'].color = [1, 0, 0]
            #self.stimuli['target_box'].color = [0, 1, 0]
            
            #===================================================================
            # Update whether or not we are in range based on the signal
            #===================================================================
            now_in_range = (x >= app.amprange[0]) and (x <= app.amprange[1])
            self.states['Inrange'] = now_in_range #update state
            if app.changed('Inrange', only=1): app.remember('range_ok')
            #TODO: Check entry direction condition.
            #self.enterok = True
            #self.states['SignalEnterMet'] = self.enterok
            
            ################################
            # Update the ISIExceeded state #
            ################################
            isiok = self.since('stim_trig')['msec'] >= 1000 * self.ISIMin
            self.states['ISIExceeded'] = isiok #update state
            
            ##############################################
            # Manually change out of inrange or outrange #
            ##############################################
            #try using self.remember and self.since instead of phases.
            phase_inrange=self.in_phase('inrange')
            phase_outrange=self.in_phase('outrange')
            if phase_inrange or phase_outrange:
                if now_in_range:
                    if phase_inrange:#phase was correct
                        #if self.enterok and isiok and stim_ready and self.stimulator.armed and int(self.states['SignalCriteriaMetBlocks']) >= self.mindur:
                        if isiok and stim_ready and int(self.states['SignalCriteriaMetBlocks']) >= self.mindur:
                            self.change_phase('response')
                    else:#phase was wrong
                        self.change_phase('inrange')                    
                else:#now not in range
                    if ~phase_outrange:#phase is wrong
                        self.change_phase('outrange')

    @classmethod
    def event(cls, app, phasename, event):
        if int(app.params['ContingencyEnable'])==1: pass