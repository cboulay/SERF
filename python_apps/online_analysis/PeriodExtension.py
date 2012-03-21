#An extension to the API's period that calculates period-specific data that are only useful
#while an online application is running.

import numpy as np
import time
from scipy.optimize import curve_fit
from python_api.Eerat_sqlalchemy import Datum_feature_value, Feature_type, Datum, Datum_detail_value, Detail_type
from sqlalchemy.orm import Session, query
from sqlalchemy import desc

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

#sigmoid function used for fitting response data
def my_sigmoid(x, x0, k, a, c):
#check scipy.optimize.leastsq or scipy.optimize.curve_fit
	#x0 = half-max, k = slope, a = max, c = min
	y = a / (1 + np.exp(-k*(x-x0))) + c
	return y

#Calculate and return _thresh and _thresh_err
#Using sigmoid... but that might not be best.
#Maybe sigmoid should be fit to x=intensity, y=0,1
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
	
class Datum:
	__metaclass__=ExtendInplace
	
	#variable definitions
	erp_detection_limit = None
	
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
	def _calc_detection_limit(self):
		if self.span_type=='period':
			#Load the raw data for the isometric contraction
			#Pull out the useful segments
			#Get the response window depending on datum_type
			#Calculate the response size for each segment.
			#Get the 97.5% CI for the response sizes.
			#Save the upper limit as the detection_limit
			self.erp_detection_limit=0
			
	#Calculate the ERP from good trials and store it. This will cause simple features to be calculated too.
	def update_store(self, IsGood=True):
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
		
	def model_mep_halfmax(self):
		if self.span_type=='period':
			#get xy_array as dat_TMS_powerA, MEP_aaa
			x=self._get_child_details('dat_TMS_powerA')
			x=x.astype(np.float)
			y=self._get_child_features('MEP_aaa')
			#Should data be scaled/standardized?
			popt,perr=_model_sigmoid(x,y)
			return popt[0],perr[0]
			
	def model_mep_thresh(self):
		if self.span_type=='period':
			x=self._get_child_details('dat_TMS_powerA')
			x=x.astype(np.float)
			y=self._get_child_features('MEP_aaa')
			y = y>self.erp_detection_limit
			#Should data be scaled/standardized?
			popt,perr=_model_sigmoid(x,y)
			return popt[0],perr[0]
		
	def model_hr_halfmax(self):
		if self.span_type=='period':
			#get xy_array as dat_Nerve_stim_output, HR_aaa
			x=self._get_child_details('dat_Nerve_stim_output')
			x=x.astype(np.float)
			y=self._get_child_features('HR_aaa')
			y_max_ix = y.argmax()#Limit x to x<x_at_y_max
			x_bool=x<=x[y_max_ix]
			#Should data be scaled/standardized?
			popt,perr=_model_sigmoid(x[x_bool],y[x_bool])
			return popt[0],perr[0]
			
	def model_hr_thresh(self):
		if self.span_type=='period':
			x=self._get_child_details('dat_Nerve_stim_output')
			x=x.astype(np.float)
			y=self._get_child_features('HR_aaa')
			y_max_ix = y.argmax()#Limit x to x<x_at_y_max
			x_bool=x<=x[y_max_ix]
			x=x[x_bool]
			y = y[x_bool]>self.erp_detection_limit
			#Should data be scaled/standardized?
			popt,perr=_model_sigmoid(x,y)
			return popt[0],perr[0]