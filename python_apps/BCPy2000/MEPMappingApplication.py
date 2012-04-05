#   This file is a BCPy2000 application developer file, 
#	for use with BCPy2000
#	http://bci2000.org/downloads/BCPy2000/BCPy2000.html
# 
#	Author:	Chadwick Boulay
#   chadwick.boulay@gmail.com
#   
#   This program is free software: you can redistribute it
#   and/or modify it under the terms of the GNU General Public License
#   as published by the Free Software Foundation, either version 3 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# This application provides feedback about the amplitude of a specific
# (processed) input channel. Whenever some criteria are met, then
# a trigger is sent out through a stimulator. The evoked response
# is trapped and passed off to an external application.
import numpy as np
from random import randint, uniform
from math import ceil
import VisionEgg
import SigTools
from AppTools.Displays import fullscreen
from AppTools.StateMonitors import addstatemonitor, addphasemonitor
from AppTools.Shapes import Block
import AppTools.Meters
from EeratAPI.API import Subject_type, Datum_type, get_or_create
from EeratAPI.OnlineAPIExtension import Subject, Datum

class BciApplication(BciGenericApplication):
	
	#############################################################
	
	def Description(self):
		return "Provides instantaneous feedback about 1 channel and generates a trigger when some criteria are met."
		
	#############################################################
	
	def Construct(self):
		# supply any BCI2000 definition strings for parameters and
		# states needed by this module
		#See here for already defined params and states http://bci2000.org/wiki/index.php/Contributions:BCPy2000#CurrentBlock
		params = [
			#"Tab:SubSection DataType Name= Value DefaultValue LowRange HighRange // Comment (identifier)",
			#See further details http://bci2000.org/wiki/index.php/Technical_Reference:Parameter_Definition
			
			"PythonApp:Design float ISIMin= 4.5 4.5 2 % // Minimum time s between stimuli",
			
			"PythonApp:Contingency 	list 		ContingentChannel= 1 EDC % % % // Processed-channel on which the trigger is contingent.",
			"PythonApp:Contingency 	float 		DurationMin= 2.6 2.6 0 % // Duration s which signal must continuously meet criteria before triggering",
			"PythonApp:Contingency 	float 		DurationRand= 0.3 0.3 0 % // Randomization s around the duration",
			"PythonApp:Contingency 	floatlist 	AmplitudeRange= {Min Max} 05 15 0 0 % //Min and Max as pcnt MVIC for signal amplitude criteria",
			"PythonApp:Contingency 	int 		RangeEnter= 0 0 0 2 // Signal must enter range from: 0 either, 1 below, 2 above (enumeration)",
						
			"PythonApp:Display 	string 	CriteriaMetColor= 0x00FF00 0xFFFFFF 0x000000 0xFFFFFF // Color of feedback when signal criteria met (color)",
			"PythonApp:Display 	string 	CriteriaOutColor= 0xCBFFCF 0xFFFFFF 0x000000 0xFFFFFF // Color of feedback when signal criteria not met (color)",
			"PythonApp:Display 	string 	BGColor= 0x000000 0x000000 0x000000 0xFFFFFF // Color of background (color)",
			"PythonApp:Display 	string	InRangeBGColor= 0x000000 0x000000 0x000000 0xFFFFFF // Color of background indicating target range (color)",
			"PythonApp:Display 	int		FeedbackType= 0 0 0 2 // Feedback type: 0 bar, 1 trace, 2 cursor (enumeration)",#Only supports bar for now
			"PythonApp:Display 	int		RangeMarginPcnt= 20 20 0 % // Percent of the display to use as a margin around the range",
			
			"PythonApp:Magstim	string		SerialPort= COM4 % % % // Serial port for controlling Magstim",
			"PythonApp:Magstim	int			TriggerType= 0 0 0 2 // Send stimulus as: 0 Contec AIO, 1 soundcard, 2 serial command (enumeration)",
			"PythonApp:Magstim	int 		ReqStimReady= 1 1 0 1 // Require ready response: 0 no, 1 yes (boolean)",
			
			"PythonApp:ERP	float		TriggerThreshold= 10000 1 0 % // If monitoring trigger, use this threshold to determine ERP time 0",
            "PythonApp:ERP	list		ERPChan= 1 EDC % % % // Name of channel used for ERP",
			"PythonApp:ERP	floatlist	ERPWindow= {Start Stop} -500 500 0 % % // ERP window, relative to trigger onset, in millesconds",
			
			"PythonApp:Screen   int    ScreenId=           -1    -1     %   %  // on which screen should the stimulus window be opened - use -1 for last",
			"PythonApp:Screen   float  WindowSize=         0.8   1.0   0.0 1.0 // size of the stimulus window, proportional to the screen",
			
			#SubjectType is necessary for identifying subjects with common names.
			"PythonApp:Analysisdb 	int		SubjectType= 0 0 0 2 	// Subject type: 0 BCPy_healthy, 1 BCPy_stroke, 2 E3rat_emg_eeg (enumeration)",
			
		]
		states = [
			#Name Length(nBits up to 32) Value ByteLocation(in state vector) BitLocation(0 to 7) CRLF
			#http://bci2000.org/wiki/index.php/Technical_Reference:State_Definition
			#Typically, state values change once per block or once per trial.
			#State values are saved per block.
			
			"Intertrial 1 0 0 0",
			"Inrange 1 0 0 0", #1 for Inrange, 0 for Outrange. This is not a phase state, but actually reflects the signal.
			"SignalEnterMet 1 0 0 0",
			"SignalCriteriaMetBlocks 16 0 0 0", #in blocks, 16-bit is max 65536
			"ISIExceeded 1 0 0 0",
			"StimulatorReady 1 0 0 0", #Whether or not the stimulator returns ready
			#TODO: "StimulatorIntensity 16 0 0 0", #So it is saved off-line analysis
			#"Trigger 1 0 0 0",
			"Response 1 0 0 0",
			"Feedback 1 0 0 0",
		]
		
		return params,states
		
	#############################################################
	
	def Preflight(self, sigprops):

		#Not yet supported
		if self.params['RangeEnter'].val: raise EndUserError, "RangeEnter not yet supported"
		
		#TODO: TrialsPerBlock -> Inf
		
		##############################################
		# http://visionegg.org/manual/visionegg.html #
		##############################################
		# Here is where you would set VisionEgg.config parameters,
		# either using self.screen.setup(), or (for more advanced
		# options) directly like, e.g. this to make the window draggable:
		#VisionEgg.config.VISIONEGG_FRAMELESS_WINDOW = 0  # gives the window a title bar
		siz = float(self.params['WindowSize'])
		screenid = int(self.params['ScreenId'])  # ScreenId 0 is the first screen, 1 the second, -1 the last
		fullscreen(scale=siz, id=screenid, frameless_window=(siz==1)) # only use a borderless window if the window is set to fill the whole screen
		
		###############################
		# CONTINGENCY PARAMETER CHECK #
		###############################

		# Make sure ContingentChannel is in the list of channels.
		chn = self.inchannels()
		pch = self.params['ContingentChannel'].val
		use_process = len(pch) != 0
		if use_process:
			if False in [isinstance(x, int) for x in pch]:
				nf = filter(lambda x: not str(x) in chn, pch)
				if len(nf): raise EndUserError, "ContingentChannel %s not in module's list of input channel names" % str(nf)
				self.procchan = [chn.index(str(x)) for x in pch]
			else:
				nf = [x for x in pch if x < 1 or x > len(chn) or x != round(x)]
				if len(nf): raise EndUserError, "Illegal ContingentChannel: %s" % str(nf)
				self.procchan = [x-1 for x in pch]		
		else:
			raise EndUserError, "Must supply ContingentChannel"

		#Check that the amplitude range makes sense.
		amprange=self.params['AmplitudeRange'].val
		if len(amprange)!=2: raise EndUserError, "AmplitudeRange must have 2 values"
		if amprange[0]>amprange[1]: raise EndUserError, "AmplitudeRange must be in increasing order"
		self.amprange=np.asarray(amprange,dtype='float64')
				
		#############
		# ERP CHECK #
		#############
		self.trigchan=None
		self.tch = ['TMSTrig']
		if False in [isinstance(x, int) for x in tch]:
			nf = filter(lambda x: not str(x) in chn, tch)
			if len(nf): raise EndUserError, "TriggerChannel %s not in module's list of input channel names" % str(nf)
			self.trigchan = [chn.index(str(x)) for x in tch]
		self.trigthresh=self.params['TriggerThreshold'].val
		
		#Check the ERP channel.
		erpch = self.params['ERPChan'].val
		erpch = [ec + "_RAW" for ec in erpch]
		#Append _RAW to each erpchan
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
			
		#Check the ERP window.
		erpwin = self.params['ERPWindow'].val
		if len(erpwin)!=2: raise EndUserError, "ERPWindow must have 2 values"
		if erpwin[0]>erpwin[1]: raise EndUserError, "ERPWindow must be in increasing order"
		if erpwin[1]<0: raise EndUserError, "ERPWindow must include up to at least 0 msec after stimulus onset"
		self.erpwin=erpwin
		
		####################
		# STIMULATOR CHECK #
		####################
		if int(self.params['TriggerType'])==1:
			raise EndUserError, "Audio Trigger not yet supported."
		
	#############################################################
	
	def Initialize(self, indim, outdim):
		
		######################
		# ANALYSIS INTERFACE #
		######################
		subj_type_name={0:'BCPy_healthy', 1:'BCPy_stroke', 2:'E3rat_emg_eeg'}.get(int(self.params['SubjectType']))
		my_subj_type=get_or_create(Subject_type, Name=subj_type_name)
		self.subject=get_or_create(Subject, Name=self.params['SubjectName'], subject_type=my_subj_type, species_type='human')
		
		period_type_name='mep_mapping'
		my_period_type=get_or_create(Datum_type, Name=period_type_name)
		#Find the period for this subject x type
		self.period = self.subject._get_most_recent_period(datum_type=my_period_type,delay=12)
		
		############
		# GET MVIC #
		############
		#This is a little slow because it loads a full BCI2000.dat file
		self.mvic = self.subject._get_last_mvic()
		
		##########
		# SCREEN #
		##########
		self.screen.color = (0,0,0) #let's have a black background
		scrw,scrh = self.screen.size #Get the screen dimensions.
		
		#Target box:
		#Convert range from %MVIC to amplitude.
		self.amprange=(self.amprange/100)*self.mvic
		
		#There is a linear transformation from amplitude to screen coordinates for the y-dimension
		#The equation is y=mx+b where y is the screen coordinates, x is the signal amplitude, b is the screen coordinate for 0-amplitude, and m is the slope.
		mgn=float(self.params['RangeMarginPcnt'].val)/100
		margin=(max(self.amprange[1],0)-min(self.amprange[0],0))*mgn	#Add a margin around the full range
		plot_max=max(self.amprange[1]+margin,0+margin)					#With the margin, what is the new max...
		plot_min=min(self.amprange[0]-margin,0-margin)					#... and the new min plot range.
		m=scrh/(plot_max-plot_min)										#From the range we can get the slope
		b=-1*m*plot_min													#From the slope we can get the intercept
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
		
		##############
		# Stimulator #
		##############
		if int(self.params['TriggerType'])==0: #If we are using the CONTEC device to trigger
			from Caio.TriggerBox import TTL
			trigbox=TTL()#Initializing this trigbox also sends out a 0V TTL on channel1
		else: trigbox=None
		from Magstim.MagstimInterface import Magstim
		serPort=self.params['SerialPort'].val
		self.stimulator=Magstim(port=serPort, trigbox=trigbox)
		self.stimulator.remocon=False
		#Then we can use self.stimulator.trigger()
		
		##################
		# Buffer the ERP #
		##################
		self.post_stim_samples = SigTools.msec2samples(self.erpwin[1], self.eegfs)
		self.pre_stim_samples = SigTools.msec2samples(np.abs(self.erpwin[0]), self.eegfs)
		#Initialize the ring buffer. It will be passed the raw data (relabeled as EDC) and the erp.
		self.leaky_trap=SigTools.Buffering.trap(4*(self.pre_stim_samples + self.post_stim_samples), 2, leaky=True)
			
		################################
		# State monitors for debugging #
		################################
		if int(self.params['ShowSignalTime']):
			# turn on state monitors iff the packet clock is also turned on
			addstatemonitor(self, 'Running', showtime=True)
			addstatemonitor(self, 'CurrentBlock')
			addstatemonitor(self, 'CurrentTrial')
			addstatemonitor(self, 'Intertrial')
			addstatemonitor(self, 'Inrange')
			addstatemonitor(self, 'SignalEnterMet')
			addstatemonitor(self, 'SignalCriteriaMetBlocks')
			addstatemonitor(self, 'ISIExceeded')
			#addstatemonitor(self, 'Trigger')
			addstatemonitor(self, 'Response')
			addstatemonitor(self, 'Feedback')
						
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

			self.stimuli['bartext_1'].color=[0,1,0]
		
	#############################################################
	
	def StartRun(self):
		#Pretend that there was a stimulus at time 0 so that the min ISI check works on the first trial.
		self.forget('stim_trig')
		self.trailingsample = None#Used for trigger monitoring
		self.erp_parms = {"halfmax": {"est":np.nan, "err": np.nan}, "threshold": {"est":np.nan, "err": np.nan}}
		self.triggered = False #each new trial has not yet been triggered.
		
	#############################################################
	
	def Phases(self):
		# define phase machine using calls to self.phase and self.design
		self.phase(name='intertrial', next='outrange', duration=500)#TODO Replace this duration with some parameter
		self.phase(name='outrange', next='inrange', duration=None)
		self.phase(name='inrange', next='response', duration=None)
		#self.phase(name='trigger', next='response', duration=1)#This will lead to multiple transitions per packet... but that's OK!
		
		self.phase(name='response', next='feedback'\
				, duration=self.params['ERPWindow'].val[1]+(2*self.block_dur)+1)
				#Includes trigger onset. Extra 2 blocks to make sure the response has been captured.
		self.phase(name='feedback', next='intertrial', duration=1000)#TODO Replace this duration with some parameter
		self.design(start='intertrial', new_trial='intertrial')
		#Note that only Process can change phase from outrange, from inrange, and therefore into response
		
	#############################################################
	
	def Transition(self, phase):
		# present stimuli and update state variables to record what is going on
		#Update some states
		self.states['Intertrial'] = int(phase in ['intertrial'])
		#self.states['Trigger'] = int(phase in ['trigger'])
		self.states['Response']  = int(phase in ['response'])
		self.states['Feedback']  = int(phase in ['feedback'])
		#The Inrange state depends on the signal, not on the phase.
		
		if phase == 'response':#Move trigger to the top so it is processed first.
			self.stimulator.trigger()
			self.remember('stim_trig')
			self.states['SignalCriteriaMetBlocks']=0#Reset the number of blocks
			self.triggered = True #Used to make sure we only process the trigger input when it is relevant to do so.
		elif phase == 'outrange':
			self.stimuli['target_box'].color = [1, 0, 0]
			self.states['SignalEnterMet'] = False
		elif phase == 'inrange':
			self.stimuli['target_box'].color = [0, 1, 0]
			#TODO: Check entry direction condition.
			self.enterok = True
			self.states['SignalEnterMet'] = self.enterok
			#Turn on remocon, make sure it is armed, turn off remocon
			self.stimulator.remocon=True
			self.stimulator.armed=True
			self.stimulator.remocon=False
			
		elif phase == 'intertrial':
			self.mindur=self.dmin + randint(-1*self.drand,self.drand)#randomized EMG contingency duration
			self.triggered = False #each new trial has not yet been triggered.
			
		elif phase == 'feedback':
			pass
					
	#############################################################
	
	def Process(self, sig):
		#Process is called on every packet
		#Phase transitions occur independently of packets
		#Therefore it is not desirable to use phases for application logic in Process
		
		###############################################
		# Update the feedback pos based on the signal #
		###############################################
		#Convert input signal to scalar
		x = sig[self.procchan,:].mean(axis=1)#still a matrix
		x=float(x)#single value
		self.updatebars(x)#Update visual stimulus based on x

		##############################################################
		# Update whether or not we are in range based on the signal  #
		# Note that the Inrange state is not related to the inrange  #
		# phase as it is possible to be Inrange while in other phases#
		##############################################################
		now_in_range = (x >= self.amprange[0]) and (x <= self.amprange[1])
		self.states['Inrange'] = now_in_range #update state
		self.states['SignalCriteriaMetBlocks'] = self.states['SignalCriteriaMetBlocks'] +1 if now_in_range else 0#increment the state tracking for how many blocks we are in range.
		#this state also gets reset to 0 when triggering
		
		################################
		# Update the ISIExceeded state #
		################################
		isiok = self.since('stim_trig')['msec'] >= 1000 * self.ISIMin
		self.states['ISIExceeded'] = isiok #update state
		
		####################################
		# Update the StimulatorReady state #
		####################################
		stim_ready = True if not self.params['ReqStimReady'].val else self.stimulator.ready
		self.states['StimulatorReady'] = stim_ready
		
		########################################
		# Write the ERP data to our leaky trap #
		# Do this every block, no matter what. #
		########################################
		#self.leaky_trap.process(sig[self.erpchan,:])
		self.leaky_trap.process(sig[np.hstack((self.trigchan,self.erpchan)),:]) #Debug trigger timing
		
		##############################################
		# Manually change out of inrange or outrange #
		##############################################
		phase_inrange=self.in_phase('inrange')
		phase_outrange=self.in_phase('outrange')
		if phase_inrange or phase_outrange:
			if now_in_range:
				if phase_inrange:#phase was correct
					if self.enterok and isiok and stim_ready and self.stimulator.armed and int(self.states['SignalCriteriaMetBlocks']) >= self.mindur:
						self.change_phase('response')
				else:#phase was wrong
					self.change_phase('inrange')					
			else:#now not in range
				if ~phase_outrange:#phase is wrong
					self.change_phase('outrange')
		
		####################
		# Trigger Response #
		####################
		if self.triggered:#Only bother wasting CPU cycles if we have sent a trigger
			startx = None
			
			#
			# Find the Trigger #
			####################
			if self.trigchan:# Hardware trigger:
				tr = np.asarray(sig[self.trigchan, :]).ravel() #flatten the trigger channel(s).
				prev = self.trailingsample #The last sample from the previous packet
				if prev == None: prev = [self.trigthresh - 1.0] #If we don't have a last sample, assume it was less than the threshold
				self.trailingsample = tr[[-1]] #Keep the last sample of this packet for next time
				tr = np.concatenate((prev,tr)) #prepend this packet with the last sample of the previous packet
				tr = np.asarray(tr > self.trigthresh, np.int8) #booleans representing whether or not the trigger was above threshold
				tr = np.argwhere(np.diff(tr) > 0)  #find any indices where the trigger crossed threshold
				if len(tr):
					startx = tr[0,0] #n_samples when the trigger first crossed threshold
			elif self.changed('Response', 1):# Software trigger:
				#Trigger onset was when we changed phase to Response
				startx = self.detect_event() if self.detect_event() else self.nominal.SamplesPerPacket
				#I still have quite a bit of jitter in the software trigger. 
				
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
				
				per_end = datetime.datetime.now() + datetime.timedelta(minutes=1)
				self.period.EndTime = self.period.EndTime if self.period.EndTime > per_end else per_end
				
				my_trial = get_or_create(Datum\
				    , subject=self.subject\
				    , datum_type=self.period.datum_type\
				    , span_type='trial'\
				    , IsGood=1\
				    , Number=0)
				
				#Stim intensity will be taken from the stimulator.
				#Coil positions from exported Brainsight session will be inserted by offline mapping tool
				my_trial.detail_values['dat_TMS_powerA']=str(self.stimulator.intensity)
				
				x_vec=np.arange(self.erpwin[0],self.erpwin[1],1000/self.eegfs,dtype=float)
				my_trial.store={'x_vec':x_vec, 'data':x, 'channel_labels': [self.tch[0],self.params['ERPChan'][0]]}
		
		elif self.in_phase('feedback'):
			#Since we don't have the coil locations, it's impossible to show a map in real-time.
			pass			
			
	#############################################################
	
	def Frame(self, phase):
		# update stimulus parameters if they need to be animated on a frame-by-frame basis
		pass
		
	#############################################################
	
	def Event(self, phase, event):
		# respond to pygame keyboard and mouse events
		import pygame.locals
		if event.type == pygame.locals.KEYDOWN:
			if event.key == ord('r'): self.color[:] = [1,0,0]
			if event.key == ord('g'): self.color[:] = [0,1,0]
			if event.key == ord('b'): self.color[:] = [0,0,1]
		
	#############################################################
	
	def StopRun(self):
		pass
	
#################################################################
#################################################################