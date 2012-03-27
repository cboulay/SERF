#An extension to the API's period that calculates period-specific data that are only useful
#while an online application is running.

import numpy as np
import time, os, datetime
from scipy.optimize import curve_fit
from python_api.Eerat_sqlalchemy import System, Subject, Datum, Detail_type, Datum_detail_value, Feature_type, Datum_feature_value, get_or_create
from sqlalchemy.orm import Session, query
from sqlalchemy import desc
import BCPy2000.BCI2000Tools.FileReader as FileReader

#sigmoid function used for fitting response data
def my_sigmoid(x, x0, k, a, c):
#check scipy.optimize.leastsq or scipy.optimize.curve_fit
	#x0 = half-max, k = slope, a = max, c = min
	y = a / (1 + np.exp(-k*(x-x0))) + c
	return y

#I'm not actually using this.
def my_inv_sigmoid(y,x0,k,a,c):
	x = (x0 - ln(-1 + (a/(y-c))))/k
	return x
	
#Calculate and return _halfmax and _halfmax err
def _model_sigmoid(x,y):
	#Fit a sigmoid to those values for trials in this period.
	n_trials = x.shape[0]
	if n_trials>4:
		p0=(np.median(x),0.1,np.max(y)-np.min(y),np.min(y)) #x0, k, a, c
		popt, pcov = curve_fit(my_sigmoid, x, y, p0=p0)
		#popt = x0, k, a, c
		#diagonal pcov is variance of parameter estimates.
		perr = np.sqrt(pcov.diagonal())
		return popt,perr
	
def get_obj(name):return eval(name)
class ExtendInplace(type):#This class enables class definitions here to _extend_ parent classes.
	#http://code.activestate.com/recipes/412717-extending-classes/
    def __new__(self, name, bases, dict):
        prevclass = get_obj(name)
        del dict['__module__']
        del dict['__metaclass__']
        for k,v in dict.iteritems():
            setattr(prevclass, k, v)
        return prevclass
       
class Subject:
	__metaclass__=ExtendInplace
	last_mvic = None
	last_sic = None
	
	def _get_most_recent_period(self):
		#TODO: Hnadle absence of any periods.
		session = Session.object_session(self)
		period = session.query(Datum).filter(\
								Datum.span_type=='period',\
								Datum.subject_id==self.subject_id,\
								Datum.IsGood==True)\
								.order_by(Datum.Number.desc())\
								.first()
		return period
	
	def _get_last_mvic(self):
		period = self._get_most_recent_period()
		self.last_mvic = period._get_mvic()
		return self.last_mvic
	
class Datum:
	__metaclass__=ExtendInplace
	
	#variable definitions
	erp_detection_limit = None
	mvic = None
	
	#method definitions
	
	#get feature values from all child trials
	def _get_child_features(self, feature_name):
		#e.g., 'HR_aaa'
		if self.span_type=='period':
			session = Session.object_session(self)
			features = session.query(Datum_feature_value.Value).filter(\
				Datum.span_type=='trial'\
				, Datum.subject_id==self.subject_id\
				, Datum.datum_type_id==self.datum_type_id\
				, Datum.IsGood==True
				, Datum.StartTime>=self.StartTime\
				, Datum.EndTime<=self.EndTime\
				, Datum_feature_value.datum_id==Datum.datum_id\
				, Datum_feature_value.feature_type_id==Feature_type.feature_type_id\
				, Feature_type.Name==feature_name\
				, Datum_feature_value.Value != None)\
				.order_by(Datum.Number)\
				.all()
			return np.asarray(features).astype(np.float)
			
	#get detail values from all child trials.
	def _get_child_details(self, detail_name):
		#e.g., 'dat_Nerve_stim_output'
		#TODO: Should not include trials without a store.
		if self.span_type=='period':
			session = Session.object_session(self)
			details = session.query(Datum_detail_value.Value).filter(\
				Datum.span_type=='trial'\
				, Datum.subject_id==self.subject_id\
				, Datum.datum_type_id==self.datum_type_id\
				, Datum.IsGood==True
				, Datum.StartTime>=self.StartTime\
				, Datum.EndTime<=self.EndTime\
				, Datum_detail_value.datum_id==Datum.datum_id\
				, Datum_detail_value.detail_type_id==Detail_type.detail_type_id\
				, Detail_type.Name==detail_name\
				, Datum_detail_value.Value != None)\
				.order_by(Datum.Number)\
				.all()
			return np.asarray(details)
		
	#Get the statistical detection limit for MEP, M-wave (not used?), H-reflex
	def _get_detection_limit(self):
		if self.span_type=='period':
			dir_stub=get_or_create(System, Name='bci_dat_dir').Value
			mvic_dir=dir_stub + '/' + self.subject.Name + '999/'
			bci_stream=self._recent_stream_for_dir(mvic_dir)
			sig,states=bci_stream.decode(nsamp='all')
			sig,chan_labels=bci_stream.spatialfilteredsig(sig)
			
			if 'hr' in self.type_name:
				chan_label=self.detail_values['dat_HR_chan_label']
				x_start=float(self.detail_values['dat_HR_start_ms'])
				x_stop=float(self.detail_values['dat_HR_stop_ms'])
			elif 'mep' in self.type_name:
				chan_label=self.detail_values['dat_MEP_chan_label']
				x_start=float(self.detail_values['dat_MEP_start_ms'])
				x_stop=float(self.detail_values['dat_MEP_stop_ms'])
			
			#Only use the relevant channel	
			sig=sig[chan_labels.index(chan_label),:]
			
			#Reduce the signal to only relevant samples
			x_bool = (states['SummingBlocks']==1).squeeze()
			sig=sig[:,x_bool]
			
			#Figure out how many samples per calculation
			fs=bci_stream.samplingfreq_hz
			n_samps=np.ceil(fs*(x_stop-x_start)/1000)
			
			#Divide our sig into equal blocks of n_samps
			cut_samps=int(-1*np.shape(sig)[1] % n_samps)
			if cut_samps>0:	sig=sig[:,:(-1*cut_samps)]
			sig=sig.reshape((sig.shape[1]/n_samps,n_samps))
			sig=np.abs(sig)
			vals=np.asarray(np.average(sig,axis=1))
			vals.sort(axis=0)
			n_vals=vals.shape[0]
			self.erp_detection_limit=vals[np.ceil(n_vals*0.975),0]
			return self.erp_detection_limit
			
	def _get_mvic(self):
		if self.span_type=='period':
			dir_stub=get_or_create(System, Name='bci_dat_dir').Value
			mvic_dir=dir_stub + '/' + self.subject.Name + '888/'
			bci_stream=self._recent_stream_for_dir(mvic_dir)
			sig,states=bci_stream.decode(nsamp='all', states=['MVC','Value'])
			x_bool = (states['MVC']==1).squeeze()
			self.mvic = np.max(states['Value'][:,x_bool])
			return self.mvic
		
	def _recent_stream_for_dir(self, dir):
		dir=os.path.abspath(dir)
		files=FileReader.ListDatFiles(d=dir)
		#The returned list is in ascending order, assume the last is most recent
		best_stream = None
		for fn in files:
			temp_stream = FileReader.bcistream(fn)
			temp_date = datetime.datetime.fromtimestamp(temp_stream.datestamp)
			if temp_date >= self.StartTime and temp_date <= self.EndTime:
				best_stream=temp_stream
		return best_stream
			
	#Calculate the ERP from good trials and store it. This will cause simple features to be calculated too.
	def update_store(self):
		if self.span_type=='period':
			session = Session.object_session(self)
			#Assume x_vec, n_channels, n_samples, channel_labels are all the same.
			#Get the x_vec, n_channels, n_samples, channel_labels from the most recent trial.
			#Getting the last_trial this way is slower for the first call to update_store but is faster for subsequent calls than using the more explicit query.
			last_trial_id = session.query("datum_id")\
				.from_statement("SELECT datum.datum_id FROM datum WHERE getParentPeriodIdForDatumId(datum_id)=:period_id AND IsGood=1 ORDER BY Number DESC")\
				.params(period_id=self.datum_id).first()
			last_trial = session.query(Datum).filter(Datum.datum_id==last_trial_id[0]).one()
			
			n_channels,n_samples=[last_trial._store.n_channels,last_trial._store.n_samples]
			
			#A couple options here:
			#1) Fetch all trials, put them in an array, then avg
			#2) Fetch each trial and incrementally sum them.
			#Try 2 - uses less memory
			#Using more explicit query is faster than using stored function to get period.
			n_trials=0
			running_sum=np.zeros([n_channels,n_samples], dtype=float)
			for ds in session.query(Datum_store).join(Datum).filter(\
				Datum.span_type=='trial', \
				Datum.subject_id==self.subject_id, \
				Datum.datum_type_id==self.datum_type_id, \
				Datum.IsGood==True, \
				Datum.StartTime>=self.StartTime, \
				Datum.EndTime<=self.EndTime):
				temp_data=np.frombuffer(ds.erp, dtype=float)
				temp_data.flags.writeable=True
				temp_data=temp_data.reshape([n_channels,n_samples])
				running_sum=running_sum+temp_data
				n_trials=n_trials+1
				
			self.store={\
				'x_vec':last_trial.store['x_vec']\
				, 'data':running_sum/n_trials\
				, 'channel_labels':last_trial.store['channel_labels']}
		
	def model_erp(self,model_type='halfmax'):
		if self.span_type=='period':
			if 'hr' in self.type_name:
				stim_det_name='dat_Nerve_stim_output'
				erp_name='HR_aaa'
			elif 'mep' in self.type_name:
				stim_det_name='dat_TMS_powerA'
				erp_name='MEP_aaa'
			#get xy_array as dat_TMS_powerA, MEP_aaa
			x=self._get_child_details(stim_det_name)
			x=x.astype(np.float)
			y=self._get_child_features(erp_name)
			if model_type=='threshold':
				y=y>self.erp_detection_limit
			#Should data be scaled/standardized?
			n_trials = x.shape[0]
			if n_trials>4:
				popt,perr=_model_sigmoid(x,y)
				return popt[0],perr[0]
			else: return None,None