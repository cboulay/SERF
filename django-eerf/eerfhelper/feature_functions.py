import numpy as np
from scipy.optimize import curve_fit
#import statsmodels.api as sm

#helper functions
def get_submat_for_datum_start_stop_chans(datum,x_start,x_stop,chan_label):
	if isinstance(x_start,unicode): x_start=float(x_start)
	if isinstance(x_stop,unicode): x_stop=float(x_stop)
	temp_store=datum.store
	x_vec=temp_store.x_vec
	y_mat=temp_store.data
	chan_list=temp_store.channel_labels
	chan_bool=np.asarray([cl==chan_label for cl in chan_list])
	y_mat = y_mat[chan_bool,:]
	for cc in range(0,y_mat.shape[0]):
		y_mat[cc,:]=y_mat[cc,:]-np.mean(y_mat[cc,x_vec<-5])
	x_bool=np.logical_and(x_vec>=x_start,x_vec<=x_stop)
	return y_mat[:,x_bool] if not isinstance(y_mat,basestring) else None
	
def get_aaa_for_datum_start_stop(datum,x_start,x_stop,chan_label):
	sub_mat=get_submat_for_datum_start_stop_chans(datum,x_start,x_stop,chan_label)
	if not np.any(sub_mat):
		return None
	sub_mat=np.abs(sub_mat)
	ax_ind = 1 if sub_mat.ndim==2 else 0
	return np.average(sub_mat,axis=ax_ind)[0]
	
def get_p2p_for_datum_start_stop(datum,x_start,x_stop,chan_label):
	sub_mat=get_submat_for_datum_start_stop_chans(datum,x_start,x_stop,chan_label)
	if not np.any(sub_mat):
		return None
	ax_ind = 1 if sub_mat.ndim==2 else 0
	p2p = np.nanmax(sub_mat,axis=ax_ind)-np.nanmin(sub_mat,axis=ax_ind)
	return p2p[0]

def get_ddvs(datum, refdatum=None, keys=None):
	if keys:
		if refdatum is None: 
			ddvs = datum.subject.detail_values_dict()
		else:
			ddvs = refdatum.detail_values_dict()
		values = [ddvs[key] for key in keys]
		return values
	else:
		return None

#feature_functions
def BEMG_aaa(datum, refdatum=None):
	my_keys = ['BG_start_ms','BG_stop_ms','BG_chan_label']
	x_start,x_stop,chan_label = get_ddvs(datum, refdatum, my_keys)
	return get_aaa_for_datum_start_stop(datum,x_start,x_stop,chan_label)
	
def MR_aaa(datum, refdatum=None):
	my_keys = ['MR_start_ms','MR_stop_ms','MR_chan_label']
	x_start,x_stop,chan_label = get_ddvs(datum, refdatum, my_keys)
	return get_aaa_for_datum_start_stop(datum,x_start,x_stop,chan_label)
	
def HR_aaa(datum, refdatum=None):
	my_keys = ['HR_start_ms','HR_stop_ms','HR_chan_label']
	x_start,x_stop,chan_label = get_ddvs(datum, refdatum, my_keys)
	return get_aaa_for_datum_start_stop(datum,x_start,x_stop,chan_label)

def MEP_aaa(datum, refdatum=None):
	my_keys = ['MEP_start_ms','MEP_stop_ms','MEP_chan_label']
	x_start,x_stop,chan_label = get_ddvs(datum, refdatum, my_keys)
	return get_aaa_for_datum_start_stop(datum,x_start,x_stop,chan_label)

def MEP_p2p(datum, refdatum=None):
	my_keys = ['MEP_start_ms','MEP_stop_ms','MEP_chan_label']
	x_start,x_stop,chan_label = get_ddvs(datum, refdatum, my_keys)
	return get_p2p_for_datum_start_stop(datum,x_start,x_stop,chan_label)

def HR_res(datum, refdatum=None):
	print ("TODO: HR_res")
	
def sig_func(x, x0, k):
	return 1 / (1 + np.exp(-k*(x-x0)))
	   
def MEP_res(datum, refdatum=None):
	#===========================================================================
	# The MEP residual is the amplitude of the MEP after subtracting the effects
	# of the background EMG and the stimulus amplitude.
	#===========================================================================
	mep_feat = 'MEP_p2p' #Change this to 'MEP_aaa' if preferred.
	prev_trial_limit = 100
	
	# Residuals only make sense when calculating for a single trial.
	if datum.span_type=='period':
		return None
	
	#TODO: Add a check for enough trials to fill the model.
		
	
	#Get the refdatum
	if refdatum is None or refdatum.span_type=='trial':
		refdatum = datum.periods.order_by('-datum_id').all()[0]
		
	#Get the X and Y for this trial
	my_bg, my_mep = [datum.calculate_value_for_feature_name(fname, refdatum=refdatum) for fname in ['BEMG_aaa', mep_feat]]
	my_stim = datum.detail_values_dict()['TMS_powerA']
	
	#Get background EMG, stimulus amplitude, and MEP_p2p for all trials (lim 100?) for this period.
	stim_ddvs = DatumDetailValue.objects.filter(datum__periods__pk=refdatum.datum_id, detail_type__name__contains='TMS_powerA').order_by('-id').all()[:prev_trial_limit]
	dd_ids = [temp.datum_id for temp in stim_ddvs]
	stim_vals = np.array([temp.value for temp in stim_ddvs],dtype=float)
	
	all_dfvs = DatumFeatureValue.objects.filter(datum__periods__pk=refdatum.datum_id)
	bg_dfvs = all_dfvs.filter(feature_type__name__contains='BEMG_aaa').order_by('-id').all()[:prev_trial_limit]
	df_ids = [temp.datum_id for temp in bg_dfvs]
	bg_vals = np.array([temp.value for temp in bg_dfvs])
	mep_dfvs = all_dfvs.filter(feature_type__name__contains=mep_feat).order_by('-id').all()[:prev_trial_limit]
	mep_vals = np.array([temp.value for temp in mep_dfvs])
	
	#Restrict ourselves to trials where dd_ids and df_ids match.
	uids = np.intersect1d(dd_ids,df_ids,assume_unique=True)
	stim_vals = stim_vals[np.in1d(dd_ids, uids)]
	bg_vals = bg_vals[np.in1d(df_ids, uids)]
	mep_vals = mep_vals[np.in1d(df_ids, uids)]

	#Transform stimulus amplitude into a linear predictor of MEP size.
	p0=((np.max(stim_vals)-np.min(stim_vals))/2,0.1) #x0, k for sig_func
	y = mep_vals - np.min(mep_vals)
	mep_scale = np.max(y)
	y = y / mep_scale
	popt, pcov = curve_fit(sig_func, stim_vals, y, p0)
	stim_vals_sig = np.min(mep_vals) + (mep_scale * sig_func(stim_vals, popt[0], popt[1]))
	my_stim_sig = np.min(mep_vals) + (mep_scale * sig_func(my_stim, popt[0], popt[1]))
	
	return get_residual(np.column_stack((my_bg, my_stim_sig)), np.array(my_mep), np.column_stack((bg_vals, stim_vals_sig)), np.array(mep_vals))[0]

def get_residual(test_x, test_y, train_x, train_y):
	#Convert the input into z-scores
	x_means = np.mean(train_x,0)
	x_std = np.std(train_x,0)
	zx = (train_x-x_means)/x_std #Built-in broadcasting
	
	#Calculate the coefficients for zy = a zx. Prepend zx with column of ones
	coeffs = np.linalg.lstsq(np.column_stack((np.ones(zx.shape[0],),zx)),train_y)[0]
	
	#Calculate expected_y using the coefficients and test_x
	test_zx = (test_x - x_means)/x_std
	expected_y = dot(coeffs, np.column_stack((np.ones(test_zx.shape[0]),test_zx)).T)

	return test_y - expected_y