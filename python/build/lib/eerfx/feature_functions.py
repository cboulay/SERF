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
	return np.average(sub_mat,axis=ax_ind)
	
def get_p2p_for_datum_start_stop(datum,x_start,x_stop,chan_label):
	sub_mat=get_submat_for_datum_start_stop_chans(datum,x_start,x_stop,chan_label)
	if not np.any(sub_mat):
		return None
	ax_ind = 1 if sub_mat.ndim==2 else 0
	return np.nanmax(sub_mat,axis=ax_ind)-np.nanmin(sub_mat,axis=ax_ind)

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