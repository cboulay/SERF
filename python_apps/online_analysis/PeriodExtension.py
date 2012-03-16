#An extension to the API's period that calculates period-specific data that are only useful
#while an online application is running.

import numpy as np
import scipy.optimize

#check scipy.optimize.leastsq or scipy.optimize.curve_fit
def my_sigmoid(x, x0, k, a, c):
	#x0 = half-max, k = slope, a = max, c = min
	y = a / (1 + np.exp(-k*(x-x0))) + c
	return y


def M_max(datum):
	if datum.span_type=='period':
		print "TODO: M_max"
	
def HR_thresh(datum):
	if datum.span_type=='period':
		print "TODO: HR_thresh"
		#X=dat_Nerve_stim_output, y=presence of H-reflex
		session = Session.object_session(datum)
		data = session.query(Datum_detail_value.Value, Datum_feature_value.Value).filter(\
			Datum.span_type=='trial'\
			, Datum.subject_id==datum.subject_id\
			, Datum.datum_type_id==datum.datum_type_id\
			, Datum.IsGood==True
			, Datum.StartTime>=datum.StartTime\
			, Datum.EndTime<=datum.EndTime\
			, Datum_detail_value.datum_id==Datum.datum_id\
			, Datum_detail_value.detail_type_id==Detail_type.detail_type_id\
			, Detail_type.Name=='dat_Nerve_stim_output'\
			, Datum_feature_value.datum_id==Datum.datum_id\
			, Datum_feature_value.feature_type_id==Feature_type.feature_type_id\
			, Feature_type.Name=='HR_aaa'\
			, Datum_detail_value.Value != None\
			, Datum_feature_value.Value != None
			).all()
		data = np.asarray(data)
		data = data.astype(np.float)
		
		#Determining whether or not an H-reflex was present can be done automatically if we have an actual threshold value. Calculation of this threshold is done externally using data collected for coherence testing.

def HR_thresh_err(datum):
	if datum.span_type=='period':
		print "TODO: HR_thresh_err"
		
def HR_halfmax(datum):
	if datum.span_type=='period':
		#X=dat_Nerve_stim_output, y=HR_aaa
		#Get the session for this object.
		session = Session.object_session(datum)
		#Query for the data that are children of this period.
		#Get the X and Y values from these data.
		data = session.query(Datum_detail_value.Value, Datum_feature_value.Value).filter(\
			Datum.span_type=='trial'\
			, Datum.subject_id==datum.subject_id\
			, Datum.datum_type_id==datum.datum_type_id\
			, Datum.IsGood==True
			, Datum.StartTime>=datum.StartTime\
			, Datum.EndTime<=datum.EndTime\
			, Datum_detail_value.datum_id==Datum.datum_id\
			, Datum_detail_value.detail_type_id==Detail_type.detail_type_id\
			, Detail_type.Name=='dat_Nerve_stim_output'\
			, Datum_feature_value.datum_id==Datum.datum_id\
			, Datum_feature_value.feature_type_id==Feature_type.feature_type_id\
			, Feature_type.Name=='HR_aaa'\
			, Datum_detail_value.Value != None\
			, Datum_feature_value.Value != None
			).all()
		data = np.asarray(data)
		data = data.astype(np.float)
		#Should data be scaled/standardized? Probably not necessary in this case.
		
		#Fit a sigmoid to those values for trials in this period.
		n_trials = data.shape[0]
		if n_trials>4:
			xdata=data[:,0]
			ydata=data[:,1]
			p0=(np.median(xdata),0.1,np.max(ydata)-np.min(ydata),np.min(ydata)) #x0, k, a, c
			popt, pcov = curve_fit(my_sigmoid, xdata, ydata, p0=p0)
			#popt = x0, k, a, c
			datum.feature_values['HR_halfmax']=popt[0]
			
			#diagonal pcov is variance of parameter estimates.
			parm_error = np.sqrt(pcov.diagonal())
			datum.feature_values['HR_halfmax_err']=parm_error[0]
	
def HR_halfmax_err(datum):
	pass #Should get from HR_halfmax
	
def MEP_halfmax(datum):
	if datum.span_type=='period':
		print "TODO: MEP_halfmax"
	
def MEP_halfmax_err(datum):
	if datum.span_type=='period':
		print "TODO: MEP_halfmax_err"
	
def MEP_thresh(datum):
	if datum.span_type=='period':
		print "TODO: MEP_thresh"
	
def MEP_thresh_err(datum):
	if datum.span_type=='period':
		print "TODO: MEP_thresh_err"
	
def MEP_max(datum):
	if datum.span_type=='period':
		print "TODO: MEP_max"