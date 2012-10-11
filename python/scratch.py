
#I use this file for quick testing of code.

import sys
import os
sys.path.append(os.path.abspath('d:/tools/eerf/python/eerf'))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "eerf.settings")
from eerfd.models import *
#import eerfx.online
from eerfx.feature_functions import *
#from scipy.optimize import curve_fit
from django.contrib.sessions.models import Session

subject = Subject.objects.get(name='Test')
my_session = Session.objects.get(pk='c4dcbc9da853b56882cbf6be6fd665cb').get_decoded()

trial_man = Datum.objects.filter(subject__pk=subject.pk, span_type=1, store__n_samples__gt=0)
trial_man = trial_man.filter(start_time__gte=my_session['trial_start']) if my_session.has_key('trial_start') else trial_man
trial_man = trial_man.filter(stop_time__lte=my_session['trial_stop']) if my_session.has_key('trial_stop') else trial_man 
trial_man = trial_man.filter(_detail_values__detail_type__name='TMS_powerA')
trial_man = trial_man.filter(_feature_values__feature_type__name='MEP_p2p')
x = [float(tr._detail_values.get(detail_type__name='TMS_powerA').value) for tr in trial_man]
y = [tr._feature_values.get(feature_type__name='MEP_p2p').value for tr in trial_man]

ddvs_man = DatumDetailValue.objects.filter(datum__subject=subject, detail_type__name='TMS_powerA')
ddvs_man = ddvs_man.filter(datum__start_time__gte=my_session['trial_start'])
ddvs_man = ddvs_man.filter(datum__stop_time__lte=my_session['trial_stop'])
ddvs = [ddv.value for ddv in ddvs_man]

dfvs_man = DatumFeatureValue.objects.filter(datum__subject=subject, feature_type__name='MEP_p2p')
dfvs_man = dfvs_man.filter(datum__start_time__gte=my_session['trial_start'])
dfvs_man = dfvs_man.filter(datum__stop_time__lte=my_session['trial_stop'])
dfvs = [dfv.value for dfv in dfvs_man]






#===============================================================================
# store_man = DatumStore.objects.filter(datum__subject__pk=subject.pk).filter(datum__span_type=1).filter(n_samples__gt=0)
# store_man = store_man.filter(datum__start_time__gte=my_session['trial_start']) if my_session.has_key('trial_start') else store_man
# store_man = store_man.filter(datum__stop_time__lte=my_session['trial_stop']) if my_session.has_key('trial_stop') else store_man
# n_channels = [st.n_channels for st in store_man]
# channel_labels = store_man[np.nonzero(n_channels==np.max(n_channels))[0][0]].channel_labels
# [x_min,x_max] = [-10.0,100.0]
# data = dict([(chlb, [{'label': st.pk, 'data': np.column_stack((st.x_vec[np.logical_and(st.x_vec>=x_min,st.x_vec<=x_max)], st.data[channel_labels.index(chlb),np.logical_and(st.x_vec>=x_min,st.x_vec<=x_max)])).tolist()} for st in reversed(store_man)]) for chlb in channel_labels])
#    
#===============================================================================