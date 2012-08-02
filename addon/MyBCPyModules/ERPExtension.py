#===============================================================================
# Application will not be able to exit response phase until
# the ERP has been collected.
#===============================================================================

import numpy as np
import random
import time
from EeratAPI.API import *
from MyPythonApps.OnlineAPIExtension import *

class Template(object):
    params = [
            "PythonApp:ERPDatabase    int        ERPDatabaseEnable= 1 1 0 1 // Enable: 0 no, 1 yes (boolean)",
            "PythonApp:ERPDatabase    list        TriggerInputChan= 1 Trig % % % // Name of channel used to monitor trigger / control ERP window",
            "PythonApp:ERPDatabase    float        TriggerThreshold= 1 1 0 % // Use this threshold to determine ERP time 0",
            #"PythonApp:ERPDatabase   int            UseSoftwareTrigger= 0 0 0 1  // Use phase change to determine trigger onset (boolean)",
            "PythonApp:ERPDatabase    list        ERPChan= 1 EDC_RAW % % % // Channels to store in database (in addition to trigger)",
            "PythonApp:ERPDatabase    floatlist    ERPWindow= {Start Stop} -500 500 0 % % // Stored window, relative to trigger onset, in millesconds",
            #Experiment type, mapping, IO, 
            #"PythonApp:ERPDatabase  int        ShowLastERP=  1 1 0 1  // plot the last trial's ERP (boolean)",
        ]
    states = [
            #"SpecificState 1 0 0 0", #Define states that are specific to this extension.
        ]
    
    @classmethod
    def preflight(cls, app, sigprops):
        if int(app.params['ERPDatabaseEnable'])==1:
            #############
            # ERP CHECK #
            #############
            
            #Trigger
            app.trigchan=None
            #tch = app.params['TriggerInputChan'].val
            tch = app.params['TriggerInputChan']
            if len(tch) != 0:
                if False in [isinstance(x, int) for x in tch]:
                    nf = filter(lambda x: not str(x) in chn, tch)
                    if len(nf): raise EndUserError, "TriggerChannel %s not in module's list of input channel names" % str(nf)
                    app.trigchan = [chn.index(str(x)) for x in tch]
                else:
                    nf = [x for x in tch if x < 1 or x > len(chn) or x != round(x)]
                    if len(nf): raise EndUserError, "Illegal TriggerChannel: %s" %str(nf)
                    app.trigchan = [x-1 for x in tch]
            if app.trigchan:
                trigthresh=app.params['TriggerThreshold'].val
                app.tch=tch #This is used for storing the channel labels.
                app.trigthresh=trigthresh
                
            #Check the ERP channel.
            erpch = app.params['ERPChan'].val
            #erpch = [ec + "_RAW" for ec in erpch]#Append _RAW to each erpchan
            if len(erpch) != 0:
                if False in [isinstance(x, int) for x in erpch]:
                    nf = filter(lambda x: not str(x) in chn, erpch)
                    if len(nf): raise EndUserError, "ERPChan %s not in module's list of input channel names" % str(nf)
                    app.erpchan = [chn.index(str(x)) for x in erpch]
                else:
                    nf = [x for x in erpch if x < 1 or x > len(chn) or x != round(x)]
                    if len(nf): raise EndUserError, "Illegal ERPChan: %s" % str(nf)
                    app.erpchan = [x-1 for x in erpch]
            else:
                raise EndUserError, "Must supply ERPChan"
            
            #Get the list of stored channel ids
            app.stored_chan_ids = app.trigchan + app.erpchan if app.trigchan else app.erpchan
                
            #Check the ERP window.
            erpwin = app.params['ERPWindow'].val
            if len(erpwin)!=2: raise EndUserError, "ERPWindow must have 2 values"
            if erpwin[0]>erpwin[1]: raise EndUserError, "ERPWindow must be in increasing order"
            if erpwin[1]<0: raise EndUserError, "ERPWindow must include up to at least 0 msec after stimulus onset"
            app.erpwin=erpwin
    
    @classmethod
    def initialize(cls, app, indim, outdim):
        if int(app.params['ERPDatabaseEnable'])==1:
            #######################################################
            # Get our subject and its current period from the ORM #
            #######################################################
            my_subject_type=get_or_create(Subject_type, Name='BCPy_healthy')
            app.subject=get_or_create(Subject, Name=app.params['SubjectName'], species_type='human')
            if not app.subject.subject_type_id:
                app.subject.subject_type_id=my_subject_type.subject_type_id
            #Determine period_type from ExperimentType 0 MEPMapping, 1 MEPRecruitment, 2 MEPSICI, 3 HRHunting, 4 HRRecruitment
            period_type_name={0:'mep_mapping', 1:'mep_io', 2:'mep_sici', 3:'hr_hunting', 4:'hr_io'}.get(int(app.params['ExperimentType']))
            my_period_type=get_or_create(Datum_type, Name=period_type_name)
            app.period = app.subject.get_most_recent_period(datum_type=my_period_type,delay=0)#Will create period if it does not exist.
            
            ##################
            # Buffer the ERP #
            ##################
            self.post_stim_samples = SigTools.msec2samples(self.erpwin[1], self.eegfs)
            self.pre_stim_samples = SigTools.msec2samples(np.abs(self.erpwin[0]), self.eegfs)
            #Initialize the buffer that contains the full (pre and post) erp.
            #This buffer must contain at least pre_stim_samples + post_stim_samples + 2*spb... but we'll add a few blocks for safety.
            self.leaky_trap=SigTools.Buffering.trap(self.pre_stim_samples + self.post_stim_samples + 5*spb, len(self.stored_chan_ids), leaky=True)
            #We will use a trap buffer that will monitor the trigger. This may only be large enough to store the post-stim erp.
            self.erp_trap = SigTools.Buffering.trap(self.post_stim_samples, len(self.stored_chan_ids),\
                                                trigger_channel=self.stored_chan_ids.index(self.trigchan[0]), trigger_threshold=self.trigthresh)
            
            self.x_vec=np.arange(self.erpwin[0],self.erpwin[1],1000/self.eegfs,dtype=float)
            self.chlbs = self.params['TriggerInputChan'] if self.trigchan else []
            add_names = [ch_name[0:-4] if ch_name.endswith('_RAW') else ch_name for ch_name in self.params['ERPChan']]
            self.chlbs.extend(add_names)
        
    @classmethod
    def halt(cls,app):
        if int(app.params['ERPDatabaseEnable'])==1: pass
    
    @classmethod
    def startrun(cls,app):
        if int(app.params['ERPDatabaseEnable'])==1: pass
        
    @classmethod
    def stoprun(cls,app):
        if int(app.params['ERPDatabaseEnable'])==1: pass
    
    @classmethod
    def transition(cls,app,phase):
        if int(app.params['ERPDatabaseEnable'])==1:
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
        if int(app.params['ERPDatabaseEnable'])==1:
            ########################################
            # Write the ERP data to our trap.      #
            # Do this every block, no matter what. #
            ########################################
            self.leaky_trap.process(sig[self.stored_chan_ids,:])
            self.erp_trap.process(sig[self.stored_chan_ids,:])
            
            if self.erp_trap.full():
                n_excess = (self.erp_trap.nseen-self.erp_trap.sprung_at)-self.erp_trap.nsamples
                self.erp_trap.reset()
                data = self.leaky_trap.read()
                data = data[:,-1*(self.pre_stim_samples+self.post_stim_samples+n_excess):-1*n_excess]
                self.period.trials.append(Datum(subject_id=self.subject.subject_id\
                                                , datum_type_id=self.period.datum_type_id\
                                                , span_type='trial'\
                                                , parent_datum_id=self.period.datum_id\
                                                , IsGood=1, Number=0))
                my_trial=self.period.trials[-1]
                my_trial.detail_values[self.intensity_detail_name]=str(self.stimulator.intensity)
                if int(self.params['ExperimentType']) == 2:#SICI intensity
                    my_trial.detail_values['dat_TMS_powerB']=str(self.stimulator.intensityb)
                #The fature calculation should be asynchronous.
                if isinstance(data,basestring): self.dbstop()
                
                my_trial.store={'x_vec':self.x_vec, 'data':data, 'channel_labels': self.chlbs}
                self.period.EndTime = datetime.datetime.now() + datetime.timedelta(minutes = 5)
            
    @classmethod
    def event(cls, app, phasename, event):
        if int(app.params['ERPDatabaseEnable'])==1: pass