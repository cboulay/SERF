import numpy as np

#helper functions
def get_aaa_for_datum_start_stop(datum,x_start,x_stop,chan_label):
	x_vec=datum.store['x_vec']
	y_mat=datum.store['data']
	x_bool=np.logical_and(x_vec>=x_start,x_vec<=x_stop)
	chan_list=datum.store['channel_labels'].split(',')
	chan_bool=np.asarray([cl==chan_label for cl in chan_list])
	sub_mat=y_mat[chan_bool,x_bool]
	sub_mat=np.abs(sub_mat)
	if sub_mat.ndim==2:
		return np.average(sub_mat,axis=1)
	else:
		return np.average(sub_mat)

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
	return get_aaa_for_datum_start_stop(datum,x_start,x_stop,chan_label)

def HR_res(datum, refdatum=None):
	print "TODO: HR_res"