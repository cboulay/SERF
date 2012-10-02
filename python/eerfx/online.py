#An extension to the API's period that calculates period-specific data that are only useful
#while an online application is running.

import numpy as np
import time, os, datetime
from scipy.optimize import curve_fit
#from EERF.API import *
#from sqlalchemy.orm import query
#from sqlalchemy import desc
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
	
def _recent_stream_for_dir(dir, maxdate=None):
		dir=os.path.abspath(dir)
		files=FileReader.ListDatFiles(d=dir)
		#The returned list is in ascending order, assume the last is most recent
		best_stream = None
		for fn in files:
			temp_stream = FileReader.bcistream(fn)
			temp_date = datetime.datetime.fromtimestamp(temp_stream.datestamp)
			if not best_stream\
				or (maxdate and temp_date<=maxdate)\
				or (not maxdate and temp_date > datetime.datetime.fromtimestamp(best_stream.datestamp)):
				best_stream=temp_stream
		return best_stream
	
#http://code.activestate.com/recipes/412717-extending-classes/
def get_obj(name):return eval(name)
class ExtendInplace(type):#This class enables class definitions here to _extend_ parent classes.
    def __new__(self, name, bases, dict):
        prevclass = get_obj(name)
        del dict['__module__']
        del dict['__metaclass__']
        for k,v in dict.iteritems():
            setattr(prevclass, k, v)
        return prevclass
       
class Subject:
	__metaclass__=ExtendInplace
        	
class Datum:
	__metaclass__=ExtendInplace
		
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
				y=y>self.detection_limit
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
				
	def add_trials_from_file(self, filename):
		if self.span_type=='period' and filename:
			bci_stream=FileReader.bcistream(filename)
			sig,states=bci_stream.decode(nsamp='all')
			sig,chan_labels=bci_stream.spatialfilteredsig(sig)
			erpwin = [int(bci_stream.msec2samples(ww)) for ww in bci_stream.params['ERPWindow']]
			x_vec = np.arange(bci_stream.params['ERPWindow'][0],bci_stream.params['ERPWindow'][1],1000/bci_stream.samplingfreq_hz,dtype=float)
			trigchan = bci_stream.params['TriggerInputChan']
			trigchan_ix = find(trigchan[0] in chan_labels)
			trigthresh = bci_stream.params['TriggerThreshold']
			trigdetect = find(np.diff(np.asmatrix(sig[trigchan_ix,:]>trigthresh,dtype='int16'))>0)+1			
			intensity_detail_name = 'dat_TMS_powerA' if self.detail_values.has_key('dat_TMS_powerA') else 'dat_Nerve_stim_output'
			#Get approximate data segments for each trial
			trig_ix = find(np.diff(states['Trigger'])>0)+1
			for i in np.arange(len(trigdetect)):
				ix = trigdetect[i]
				dat = sig[:,ix+erpwin[0]:ix+erpwin[1]]
				self.trials.append(Datum(subject_id=self.subject_id\
                                            , datum_type_id=self.datum_type_id\
                                            , span_type='trial'\
                                            , parent_datum_id=self.datum_id\
                                            , IsGood=1, Number=0))
				my_trial=self.trials[-1]
				my_trial.detail_values[intensity_detail_name]=str(states['StimulatorIntensity'][0,trig_ix[i]])
				if int(bci_stream.params['ExperimentType']) == 1:#SICI intensity
					my_trial.detail_values['dat_TMS_powerB']=str(bci_stream.params['StimIntensityB'])#TODO: Use the state.
					my_trial.detail_values['dat_TMS_ISI']=str(bci_stream.params['PulseInterval'])
				my_trial.store={'x_vec':x_vec, 'data':dat, 'channel_labels': chan_labels}
			Session.commit()