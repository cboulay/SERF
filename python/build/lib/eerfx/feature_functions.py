import numpy as np

#helper functions
def get_submat_for_datum_start_stop_chans(datum,x_start,x_stop,chan_label):
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
		if refdatum is None: refdatum=datum
		ddvs = refdatum.detail_values_dict()
		x_start = float(ddvs[keys[0]])
		x_stop = float(ddvs[keys[1]])
		chan_label = ddvs[keys[2]]
		return x_start, x_stop, chan_label
	else:
		return None, None, None

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
	print "TODO: HR_res"
	
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
	
	#Get the refdatum
	if refdatum is None or refdatum.span_type=='trial':
		refdatum = datum.periods.order_by('-datum_id').all()[0]
	
	#We will eventually need the BG, MEP, and stim for this trial.
	output = [datum.calculate_value_for_feature_name(fname, refdatum=refdatum) for fname in ['BEMG_aaa', mep_feat]]
	my_stim = datum.detail_values_dict()['TMS_powerA']
	
	#===========================================================================
	# #Get background EMG, stimulus amplitude, and MEP_p2p for all trials (lim 100?) for this period.
	# stim_ddvs = DatumDetailValue.objects.filter(datum__periods__pk=refdatum.datum_id, detail_type__name__contains='TMS_powerA').order_by('-id').all()[:prev_trial_limit]
	# stim_did,stim_val = [ for stim_ddv in stim_ddvs]
	# all_dfvs = DatumFeatureValue.objects.filter(datum__periods__pk=refdatum.datum_id) #Build a query set for all feature_values belonging to previous trials in the period.
	# 
	#===========================================================================
	
	
	#Transform stimulus amplitude into something linearly related to MEP size.
	
	#Do a multiple regression (y=MEP_p2p, X=BEMG_aaa,stim_amp) to identify the coefficients
	
	#Calculate expected y given this trial's BEMG_aaa and stim_amp
	expected_y = 0
	#Get actual y for this trial
	this_y = MEP_p2p(datum, refdatum)
	
	#return the residual (this trial's MEP_p2p - expected y)
	return this_y - expected_y