#An extension to the API's period that calculates period-specific data that are only useful
#while an online application is running.

import numpy as np
import time, os, datetime
from scipy.optimize import curve_fit
from EeratAPI.API import *
from sqlalchemy.orm import query
from sqlalchemy import desc
import BCPy2000.BCI2000Tools.FileReader as FileReader
from matplotlib.mlab import find

#sigmoid function used for fitting response data
def my_sigmoid(x, x0, k, a, c): return a / (1 + np.exp(-1*k*(x-x0))) + c
#x0 = half-max, k = slope, a = max, c = min
def my_simp_sigmoid(x, x0, k): return 1 / (1 + np.exp(-1*k*(x-x0)))
	
#Calculate and return _halfmax and _halfmax err
def model_sigmoid(x,y, mode=None):
	#Fit a sigmoid to those values for trials in this period.
	n_trials = x.shape[0]
	if n_trials>4:
		if not mode or mode=='halfmax':
			sig_func = my_sigmoid
			p0=(np.median(x),0.1,np.max(y)-np.min(y),np.min(y)) #x0, k, a, c
			nvars = 4
		elif mode=="threshold":
			sig_func = my_simp_sigmoid
			p0=(np.median(x),0.1) #x0, k
			nvars = 2
		try: popt, pcov = curve_fit(sig_func, x, y, p0=p0)
		except RuntimeError:
			print("Error - curve_fit failed")
			popt=np.empty((nvars,))
			popt.fill(np.NAN)
			pcov = np.Inf #So the err is set to nan
		#popt = x0, k, a, c
		#diagonal pcov is variance of parameter estimates.
		if np.isinf(pcov).all():
			perr=np.empty((nvars,))
			perr.fill(np.NAN)
		else: perr = np.sqrt(pcov.diagonal())
		return popt,perr
	
def _recent_stream_for_dir(dir):
		dir=os.path.abspath(dir)
		files=FileReader.ListDatFiles(d=dir)
		#The returned list is in ascending order, assume the last is most recent
		best_stream = None
		for fn in files:
			temp_stream = FileReader.bcistream(fn)
			temp_date = datetime.datetime.fromtimestamp(temp_stream.datestamp)
			if not best_stream or temp_date > datetime.datetime.fromtimestamp(best_stream.datestamp): 
				best_stream=temp_stream
		return best_stream
	
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
	
	def get_most_recent_period(self, datum_type=None, delay=99999):
		#delay specifies how far back, in hours, we will accept a period. Default is ~11 years
		session = Session.object_session(self)
		td = datetime.timedelta(hours=delay)
		
		query = session.query(Datum).filter(\
					Datum.span_type=='period',\
					Datum.subject_id==self.subject_id,\
					Datum.IsGood==True,\
					Datum.EndTime >= datetime.datetime.now()-td)
		if datum_type: query=query.filter(Datum.datum_type_id==datum_type.datum_type_id)
		period = query.order_by(Datum.Number.desc()).first()#Does this return None if there are none?
		if not period and datum_type:
			#If we did not find a period, then create one with default settings, including StartTime and EndTime
			period = get_or_create(Datum, sess=session, span_type='period', subject=self, datum_type=datum_type, IsGood=1, Number=0)
		return period
	
	def _get_last_mvic(self):
		#Online analysis assumes most recent MVIC is relevant. Offline analysis may require date-specific MVIC.
		#TODO: Make sure the muscle is correct.
		session = Session.object_session(self)
		dir_stub=get_or_create(System, sess=session, Name='bci_dat_dir').Value
		mvic_dir=dir_stub + '/' + self.Name + '/' + self.Name + '888/'
		bci_stream=_recent_stream_for_dir(mvic_dir)
		sig,states=bci_stream.decode(nsamp='all', states=['MVC','Value'])
		x_bool = (states['MVC']==1).squeeze()
		#TODO: Filter/smooth states['Value'] so we only look for sustained contraction, not one-offs.
		self.last_mvic = np.max(states['Value'][:,x_bool])
		return self.last_mvic
	
class Datum:
	__metaclass__=ExtendInplace
	
	#variable definitions. Do these attach to self?
	erp_detection_limit = None
	mvic = None
	
	#get feature values from all child trials
	def _get_child_features(self, feature_name):
		#e.g., 'HR_aaa'
		if self.span_type=='period':
			session = Session.object_session(self)
			features = session.query(Datum_feature_value.Value).filter(\
				Datum.span_type=='trial'\
				, Datum.subject_id==self.subject_id\
				, Datum.datum_type_id==self.datum_type_id\
				, Datum.IsGood==True\
				, Datum.parent_datum_id==self.datum_id\
				, Datum_feature_value.datum_id==Datum.datum_id\
				, Datum_feature_value.feature_type_id==Feature_type.feature_type_id\
				, Feature_type.Name==feature_name\
				, Datum_feature_value.Value != None)\
				.order_by(Datum.Number)\
				.all()
				#, Datum.StartTime>=self.StartTime\
				#, Datum.EndTime<=self.EndTime\
			return np.squeeze(np.asarray(features).astype(np.float))
			
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
				, Datum.IsGood==True\
				, Datum.parent_datum_id==self.datum_id\
				, Datum_detail_value.datum_id==Datum.datum_id\
				, Datum_detail_value.detail_type_id==Detail_type.detail_type_id\
				, Detail_type.Name==detail_name\
				, Datum_detail_value.Value != None)\
				.order_by(Datum.Number)\
				.all()
			return np.squeeze(np.asarray(details))
		
	#Get the statistical detection limit for MEP, M-wave (not used?), H-reflex
	def _get_detection_limit(self):
		if self.span_type=='period':
			session = Session.object_session(self)
			dir_stub=get_or_create(System, sess=session, Name='bci_dat_dir').Value
			sic_dir=dir_stub + '/' + self.subject.Name + '/' + self.subject.Name + '999/'
			bci_stream=_recent_stream_for_dir(sic_dir)
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
			n_samps=int(np.ceil(fs*(x_stop-x_start)/1000))
			
			#Divide our sig into equal blocks of n_samps
			cut_samps=int(np.shape(sig)[1] % n_samps)
			if cut_samps>0:	sig=sig[:,:(-1*cut_samps)]
			sig=sig.reshape((sig.shape[1]/n_samps,n_samps))
			
			#aaa or p2p
			fts = self.datum_type.feature_types
			isp2p = any([ft for ft in fts if 'p2p' in ft.Name])
			
			if isp2p:
				vals = np.asarray(np.max(sig,axis=1)-np.min(sig,axis=1))
			else:
				sig=np.abs(sig)#abs value
				vals=np.asarray(np.average(sig,axis=1))#average across n_samps to get null erp equivalent
			
			vals.sort(axis=0)#sort by size
			n_vals=vals.shape[0]
			self.erp_detection_limit=vals[np.ceil(n_vals*0.99),0]#97.5% is the cutoff
			return self.erp_detection_limit
			
	#Calculate the ERP from good trials and store it. This will cause simple features to be calculated too.
	def update_store(self):
		if self.span_type=='period':
			#session = Session.object_session(self)
			  #Assume x_vec, n_channels, n_samples, channel_labels are all the same across trials.
			  #Get the x_vec, n_channels, n_samples, channel_labels from the most recent trial.
			  #Getting the last_trial this way is slower for the first call to update_store but is faster for subsequent calls than using the more explicit query.
			#last_trial_id = session.query("datum_id")\
			#	.from_statement("SELECT datum.datum_id FROM datum WHERE getParentPeriodIdForDatumId(datum_id)=:period_id AND IsGood=1 AND span_type=1 ORDER BY Number DESC")\
			#	.params(period_id=self.datum_id).first()
			#last_trial = session.query(Datum).filter(Datum.datum_id==last_trial_id[0]).one()
			last_trial=self.trials[-1]
			
			#n_channels,n_samples=[last_trial._store.n_channels,last_trial._store.n_samples]
			
			#A couple options here:
			#1) Fetch all trials, put them in an array, then avg
			#2) Fetch each trial and incrementally sum them.
			#Try 2 - uses less memory
			#Using more explicit query is faster than using stored function to get period.
			n_trials=0
			running_sum=np.zeros([last_trial._store.n_channels,last_trial._store.n_samples], dtype=float)
			#for ds in session.query(Datum_store).join(Datum).filter(\
			#	Datum.span_type=='trial', \
			#	Datum.subject_id==self.subject_id, \
			#	Datum.datum_type_id==self.datum_type_id, \
			#	Datum.IsGood==True, \
			#	Datum.StartTime>=self.StartTime, \
			#	Datum.EndTime<=self.EndTime):
			for ds in self.trials:
				#temp_data=np.frombuffer(ds.erp, dtype=float)
				#temp_data.flags.writeable=True
				#temp_data=temp_data.reshape([n_channels,n_samples])
				#TODO: Only use IsGood trials. self.trials does not discriminate (I don't think, check API).
				running_sum=running_sum+ds.store['data']
				n_trials=n_trials+1
			avg_data = running_sum/n_trials
			
			last_store=last_trial.store
			
			self.store={\
				'x_vec':last_store['x_vec']\
				, 'data':avg_data\
				, 'channel_labels':last_store['channel_labels']}
		
	def model_erp(self,model_type='halfmax'):
		if self.span_type=='period':
			
			fts = self.datum_type.feature_types
			isp2p = any([ft for ft in fts if 'p2p' in ft.Name])
			
			if 'hr' in self.type_name:
				stim_det_name='dat_Nerve_stim_output'
				erp_name= 'HR_p2p' if isp2p else 'HR_aaa'
			elif 'mep' in self.type_name:
				stim_det_name='dat_TMS_powerA'
				erp_name= 'MEP_p2p' if isp2p else 'MEP_aaa'
			#get xy_array as dat_TMS_powerA, MEP_aaa
			x=self._get_child_details(stim_det_name)
			x=x.astype(np.float)
			x_bool = ~np.isnan(x)
			y=self._get_child_features(erp_name)
			if model_type=='threshold':
				if not self.erp_detection_limit: self._get_detection_limit()
				y=y>self.erp_detection_limit
				y=y.astype(int)
			elif 'hr' in self.type_name:#Not threshold, and hr, means cut off trials > h-max
				h_max = np.max(y)
				y_max_ind = find(y==h_max)[0]
				x_at_h_max = x[y_max_ind]
				x_bool = x <= x_at_h_max
			n_trials = 1 if x.size==1 else x[x_bool].shape[0]
			#Should data be scaled/standardized?
			if n_trials>4:
				return model_sigmoid(x[x_bool],y[x_bool],mode=model_type) + (x,) + (y,)
			else: return None,None,None,None
			
	def assign_coords(self, space='brainsight'):
		if self.span_type=='period' and self.datum_type.Name=='mep_mapping':
			#Find and load the brainsight file
			dir_stub=get_or_create(System, Name='bci_dat_dir').Value
			bs_file_loc=dir_stub + '/' + self.subject.Name + '/mapping/' + str(self.Number) + '_' + space + '.txt'
			#Parse the brainsight file for X-Y coordinates
			data = [line.split('\t') for line in file(bs_file_loc)]
			data = [line for line in data if 'Sample' in line[0]]
			starti = find(['#' in line[0] for line in data])[0]
			data = data[starti:]
			headers = data[0]
			data = data[1:]
			x_ind = find(['Loc. X' in col for col in headers])[0]
			y_ind = find(['Loc. Y' in col for col in headers])[0]
			z_ind = find(['Loc. Z' in col for col in headers])[0]
			
			i = 0
			for tt in self.trials:
				tt.detail_values['dat_TMS_coil_x']=float(data[i][x_ind])
				tt.detail_values['dat_TMS_coil_y']=float(data[i][y_ind])
				tt.detail_values['dat_TMS_coil_z']=float(data[i][z_ind])
				i = i+1