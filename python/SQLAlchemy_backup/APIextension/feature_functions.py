import numpy as np

#helper functions
def get_submat_for_datum_start_stop_chans(datum,x_start,x_stop,chan_label):
	temp_store=datum.store
	x_vec=temp_store['x_vec']
	y_mat=temp_store['data']
	nchans = np.size(temp_store['channel_labels'])
	for cc in range(0,nchans):
		y_mat[cc,:]=y_mat[cc,:]-np.mean(y_mat[cc,x_vec<-5])
	x_bool=np.logical_and(x_vec>=x_start,x_vec<=x_stop)
	chan_list=temp_store['channel_labels']
	chan_bool=np.asarray([cl==chan_label for cl in chan_list])
	return y_mat[chan_bool,x_bool] if not isinstance(y_mat,basestring) else False
	
def get_aaa_for_datum_start_stop(datum,x_start,x_stop,chan_label):
	sub_mat=get_submat_for_datum_start_stop_chans(datum,x_start,x_stop,chan_label)
	if isinstance(sub_mat,basestring):
		return false
	sub_mat=np.abs(sub_mat)
	ax_ind = 1 if sub_mat.ndim==2 else 0
	return np.average(sub_mat,axis=ax_ind)
	
def get_p2p_for_datum_start_stop(datum,x_start,x_stop,chan_label):
	sub_mat=get_submat_for_datum_start_stop_chans(datum,x_start,x_stop,chan_label)
	if not isinstance(sub_mat,np.ndarray): return False
	ax_ind = 1 if sub_mat.ndim==2 else 0
	return np.nanmax(sub_mat,axis=ax_ind)-np.nanmin(sub_mat,axis=ax_ind)

#feature_functions
def BEMG_aaa(datum, refdatum=None):
	if refdatum is None: refdatum=datum
	#the parent period can be supplied as refdatum to use it for feature calculation.
	x_start=float(refdatum.detail_values['dat_BG_start_ms'])
	x_stop=float(refdatum.detail_values['dat_BG_stop_ms'])
	chan_label=refdatum.detail_values['dat_BG_chan_label']
	return get_aaa_for_datum_start_stop(datum,x_start,x_stop,chan_label)
	
def MR_aaa(datum, refdatum=None):
	if refdatum is None: refdatum=datum
	#the parent period can be supplied as refdatum to use it for feature calculation.
	x_start=float(refdatum.detail_values['dat_MR_start_ms'])
	x_stop=float(refdatum.detail_values['dat_MR_stop_ms'])
	chan_label=refdatum.detail_values['dat_MR_chan_label']
	return get_aaa_for_datum_start_stop(datum,x_start,x_stop,chan_label)
	
def HR_aaa(datum, refdatum=None):
	if refdatum is None: refdatum=datum
	#the parent period can be supplied as refdatum to use it for feature calculation.
	x_start=float(refdatum.detail_values['dat_HR_start_ms'])
	x_stop=float(refdatum.detail_values['dat_HR_stop_ms'])
	chan_label=refdatum.detail_values['dat_HR_chan_label']
	return get_aaa_for_datum_start_stop(datum,x_start,x_stop,chan_label)

def MEP_aaa(datum, refdatum=None):
	if refdatum is None: refdatum=datum
	#the parent period can be supplied as refdatum to use it for feature calculation.
	x_start=float(refdatum.detail_values['dat_MEP_start_ms'])
	x_stop=float(refdatum.detail_values['dat_MEP_stop_ms'])
	chan_label=refdatum.detail_values['dat_MEP_chan_label']
	temp = get_aaa_for_datum_start_stop(datum,x_start,x_stop,chan_label)
	#bg = BEMG_aaa(datum, refdatum=refdatum)
	#temp = temp-bg
	return temp

def MEP_p2p(datum, refdatum=None):
	if refdatum is None: refdatum=datum
	x_start=float(refdatum.detail_values['dat_MEP_start_ms'])
	x_stop=float(refdatum.detail_values['dat_MEP_stop_ms'])
	chan_label=refdatum.detail_values['dat_MEP_chan_label']
	return get_p2p_for_datum_start_stop(datum,x_start,x_stop,chan_label)

def HR_res(datum, refdatum=None):
	print "TODO: HR_res"