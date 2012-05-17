import numpy as np
import random
import time

class MEP(object):
	params = [
			"PythonApp:Magstim		string	SerialPort= COM4 % % % // Serial port for controlling Magstim",
			"PythonApp:Magstim		int 	ReqStimReady= 1 1 0 1 // Require ready response: 0 no, 1 yes (boolean)",
			"PythonApp:Magstim		int 	SerialTrigger= 0 0 0 1 // Use serial port to trigger: 0 no, 1 yes (boolean)",
		]
	states = [
			"StimulatorReady 1 0 0 0", #Whether or not the stimulator returns ready
			#TOOD: SICI
		]
	@classmethod
	def initialize(cls,app):
		if int(app.params['SerialTrigger'])==0: #Not using a serial trigger
			from Caio.TriggerBox import TTL
			trigbox=TTL()#Initializing this trigbox also sends out a 0V TTL on channel1
		else: trigbox=None
		from Magstim.MagstimInterface import Bistim
		serPort=app.params['SerialPort'].val
		app.stimulator=Bistim(port=serPort, trigbox=trigbox)
		app.intensity_detail_name = 'dat_TMS_powerA'
	@classmethod
	def transition(cls,app,phase):
		if phase == 'inrange':
			app.stimulator.armed=True

class SICI(object):
	params = [
			"PythonApp:Magstim		int 	StimIntensityB= 0 0 0 100 // Test stimulus intensity",
			"PythonApp:Magstim		float 	PulseInterval= 0 0 0 100 // Double-pulse interval in ms",
		]
	states = [
			"StimulatorIntensityB 16 0 0 0", #Intensity of StimB for Bistim
			"ISIx10 16 0 0 0", #Double-pulse ISI in 0.1ms
		]
	@classmethod
	def initialize(cls,app):
		time.sleep(1)#Stimulator isn't ready for ISI command just yet.
		app.stimulator.ISI = float(app.params['PulseInterval'].val)
		app.stimulator.intensityb = app.params['StimIntensityB'].val
		n_trials = app.params['TrialsPerBlock'].val
		true_array = np.ones(np.ceil(n_trials/2.0), dtype=np.bool)
		false_array = np.zeros(np.floor(n_trials/2.0), dtype=np.bool)
		app.sici_bool = np.hstack((true_array, false_array))
		random.shuffle(app.sici_bool)
	@classmethod
	def halt(cls,app):
		app.stimulator.ISI = 0
		app.stimulator.intensityb = 0
	@classmethod
	def transition(cls,app,phase):
		if phase == 'intertrial':
			trial_i = app.states['CurrentTrial']-1
			app.stimulator.intensity = app.params['StimIntensity'].val if app.sici_bool[trial_i] else 0
			app.stimulator.intensityb = app.params['StimIntensityB'].val
			
class HR(object):
	params = []
	states = []
	@classmethod
	def initialize(cls,app):
		from Caio.TriggerBox import TTL
		trigbox=TTL()#Initializing this trigbox also sends out a 0V TTL on channel1
		from Caio.VirtualStimulatorInterface import Virtual
		trigbox._caio.fs=10000
		trigbox.set_TTL(width=1, channel=2)#Use a shorter TTL width, since the TTL drives the stimulator.
		app.stimulator=Virtual(trigbox=trigbox)
		app.intensity_detail_name = 'dat_Nerve_stim_output'
		
class MAPPING(object):
	params = []
	states = []
	@classmethod
	def initialize(cls,app):
		app.stimulator.remocon = False#Turn off remocon so stimulator can be manually controlled.
	@classmethod
	def transition(cls,app,phase):
		if phase == 'inrange':
			app.stimulator.remocon = True
			app.stimulator.armed=True
			app.stimulator.remocon = False
	
class IOCURVE(object):
	params = [
			"PythonApp:IOCurve 	floatlist 	BaselineRange= {Min Max} 5 80 0 0 % //Min and Max of range to test before adaptive parameterization",#Units depend on mode.
			"PythonApp:IOCurve 	int			BaselineTrials= 5 5 0 % // N trials spread over range",
		]
	states = []
	@classmethod
	def preflight(cls,app):
		#Check that the baseline range makes sense.
		baseline_range=app.params['BaselineRange'].val
		if len(baseline_range)!=2: raise EndUserError, "BaselineRange must have 2 values"
		if baseline_range[0]>baseline_range[1]: raise EndUserError, "BaselineRange must be in increasing order"
		app.baseline_range=np.asarray(baseline_range,dtype='float64')
		app.baseline_trials=app.params['BaselineTrials'].val		
		
	@classmethod
	def initialize(cls,app):
		#Calculate the erp detection limit now so we don't have to calculate it during data acquisition
		temp = app.period.detection_limit #We can access the calculated value directly with app.period._detection_limit			
		
		#Setup the stimulus intensities for the first baseline trials
		#self.baseline_range#self.baseline_trials
		start = app.baseline_range[0]
		stop = app.baseline_range[1]
		n_start = app.baseline_trials
		app.starting_intensities = np.r_[start:stop:n_start+0j]
		np.random.shuffle(app.starting_intensities)
			
	@classmethod
	def startrun(cls,app):
		app.erp_parms = {"halfmax": {"est":np.nan, "err": np.nan}, "threshold": {"est":np.nan, "err": np.nan}}
	
	@classmethod
	def transition(cls,app,phase):
		if phase == 'intertrial':
			#Set this trial's stim intensity
			trial_ix = app.states['CurrentTrial']
			if trial_ix <= app.baseline_trials:
				stimi = app.starting_intensities[trial_ix-1]
			else:
				#Determine whether this is a threshold (default) or halfmax trial
				_th=app.erp_parms['threshold']
				_hm=app.erp_parms['halfmax']
				if np.isnan(_th['err']) or _th['err']>=(0.05*_th['est']):
					model_type="threshold"
				elif np.isnan(_hm['err']) or _hm['err']>=(0.05*_hm['est']):
					model_type="halfmax"
				else: #We have finished
					model_type="threshold"
					app.states['CurrentTrial']=500
				stimi = app.erp_parms[model_type]['est']
				if (not stimi) or np.isnan(stimi):#In case NaN or None
					#Choose a random intensity in baseline_range
					stimi=random.uniform(app.baseline_range[0],app.baseline_range[1])
			stimi=min(app.baseline_range[1],stimi)#stimi should not exceed the max range
			stimi=max(0,stimi)#TODO: Change this if we want a negative stimulus.
			app.stimulator.intensity = stimi
			app.states['StimulatorIntensity']=int(round(stimi))
			
		elif phase == 'stopcue' or phase == 'feedback':
			#Request the estimate of (threshold | halfmax) and the stderr of the est from the API
			#TODO: I don't need the stimi and stimerr until the next trial begins, 
			#can these requests be made asynchronous?
			trial_ix = app.states['CurrentTrial']
			if trial_ix >= app.baseline_trials:
				for model_type in ['threshold','halfmax']:
					app.period._detection_limit = None#Forces _detection_limit to be obtained from db instead of using in-memory value.
					popt, perr, x, y=app.period.model_erp(model_type=model_type)
					stimi = popt[0]
					stimerr = perr[0]
					app.erp_parms[model_type]['est']=stimi
					app.erp_parms[model_type]['err']=stimerr
					print "%(model_type)s : %(stimi)s" % {"model_type":model_type, "stimi":str(stimi)}