#An extension to the API's period that calculates period-specific data that are only useful
#while an online application is running.

import numpy as np
import scipy.optimize
from python_api.Eerat_sqlalchemy import Datum

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
def my_inv_sigmoid(y,x0,k,a,c):
	x = (x0 - ln(-1 + (a/(y-c))))/k
	return x
	
#Calculate and return _halfmax and _halfmax err
def _model_sigmoid(xy_array):
	#X=dat_Nerve_stim_output, y=HR_aaa
	#Should data be scaled/standardized? Probably not necessary in this case.

	#Fit a sigmoid to those values for trials in this period.
	n_trials = xy_array.shape[0]
	if n_trials>4:
		xdata=xy_array[:,0]
		ydata=xy_array[:,1]
		p0=(np.median(xdata),0.1,np.max(ydata)-np.min(ydata),np.min(ydata)) #x0, k, a, c
		popt, pcov = curve_fit(my_sigmoid, xdata, ydata, p0=p0)
		#popt = x0, k, a, c
		#diagonal pcov is variance of parameter estimates.
		perr = np.sqrt(pcov.diagonal())
		return popt,perr
	
class Datum:
	__metaclass__=ExtendInplace
	
	#variable definitions
	features_array = None
	features_names = None
	mep_detection_limit = None
	mep_halfmax = None
	mep_halfmax_err = None
	mep_thresh = None
	mep_thresh_err = None
	hr_detection_limit = None
	hr_halfmax = None
	hr_halfmax_err = None
	hr_thresh = None
	hr_thresh_err = None
	
	#method definitions
	
	#Calculate the ERP from good trials and store it. This will cause simple features to be calculated too.
	def update_store(self):
		if self.span_type=='period':
		#x_vec, erp, n_channels, n_samples, channel_labels
			pass
		
	def _get_child_features(self):
		if self.span_type=='period':
			#TODO: Get an array of all detail_values and feature_values for all trials in this period.
			#Get the session for this object.
			session = Session.object_session(self)
			#Query for the data that are children of this period.
			#Get the X and Y values from these data.
			data = session.query(Datum_detail_value.Value, Datum_feature_value.Value).filter(\
				Datum.span_type=='trial'\
				, Datum.subject_id==self.subject_id\
				, Datum.datum_type_id==self.datum_type_id\
				, Datum.IsGood==True
				, Datum.StartTime>=self.StartTime\
				, Datum.EndTime<=self.EndTime\
				, Datum_detail_value.datum_id==Datum.datum_id\
				#, Datum_detail_value.detail_type_id==Detail_type.detail_type_id\
				#, Detail_type.Name=='dat_Nerve_stim_output'\
				, Datum_feature_value.datum_id==Datum.datum_id\
				#, Datum_feature_value.feature_type_id==Feature_type.feature_type_id\
				#, Feature_type.Name=='HR_aaa'\
				, Datum_detail_value.Value != None\
				, Datum_feature_value.Value != None
				).all()
			data = np.asarray(data)
			data = data.astype(np.float)
		
	#Get the statistical detection limit for MEP, M-wave (not used?), H-reflex
		
	def _model_mep(self):
		if self.span_type=='period':
			#get xy_array as dat_TMS_powerA, MEP_aaa
			#get sigmoid parameters (and parameter errors)
			popt,perr=_model_sigmoid(self.xy_array)
			self.mep_halfmax=popt[0]#popt[0] is halfmax
			self.mep_halfmax_err=perr[0]#perr[0] is halfmax err
			#using model params, calculate model @ self.mep_detection_limit
			self.mep_thresh = my_inv_sigmoid(self.mep_detection_limit, *popt)
			#I actually have no idea how to get thresh_err. Somehow get the confidence interval?
		
	def _model_hrio(self):
		if self.span_type=='period':
			#get xy_array as dat_Nerve_stim_output, HR_aaa
			#limit to HR_aaa < max HR_aaa
			popt,perr=_model_sigmoid(self.xy_array)
			self.hr_halfmax=popt[0]#popt[0] is halfmax
			self.hr_halfmax_err=perr[0]#perr[0] is halfmax err
			self.hr_thresh = my_inv_sigmoid(self.hr_detection_limit, *popt)
			#I actually have no idea how to get thresh_err. Somehow get the confidence interval?