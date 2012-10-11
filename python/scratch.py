
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

subject = Subject.objects.all()[2]
my_session = Session.objects.get(pk='c4dcbc9da853b56882cbf6be6fd665cb').get_decoded()
store_man = DatumStore.objects.filter(datum__subject__pk=subject.pk).filter(datum__span_type=1).filter(n_samples__gt=0)
store_man = store_man.filter(datum__start_time__gte=my_session['trial_start']) if my_session.has_key('trial_start') else store_man
store_man = store_man.filter(datum__stop_time__lte=my_session['trial_stop']) if my_session.has_key('trial_stop') else store_man
n_channels = [st.n_channels for st in store_man]
channel_labels = store_man[np.nonzero(n_channels==np.max(n_channels))[0][0]].channel_labels
[x_min,x_max] = [-10.0,100.0]
data = dict([(chlb, [{'label': st.pk, 'data': np.column_stack((st.x_vec[np.logical_and(st.x_vec>=x_min,st.x_vec<=x_max)], st.data[channel_labels.index(chlb),np.logical_and(st.x_vec>=x_min,st.x_vec<=x_max)])).tolist()} for st in reversed(store_man)]) for chlb in channel_labels])
    