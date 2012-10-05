from django.template import RequestContext
from django.shortcuts import render_to_response, get_object_or_404
from eerfd.models import *
from django.http import HttpResponse, Http404
import json
import numpy as np

def index(request):
    return render_to_response('eerfd/index.html')

def store_pk_check(request, pk):
    #Given a pk, return how many DatumStore objects we have with pk greater
    pk = int(pk) if len(pk)>0 else 0
    n_stores = DatumStore.objects.filter(pk__gte=pk).count()
    return HttpResponse(json.dumps(n_stores))

def monitor(request, pk, n_erps = 5):
    [x_min,x_max] = [-10.0,100.0]
    #Shows most recent n_erps ERPs with pk greater than or equal to pk
    pk = int(pk) if len(pk)>0 else 0#pk after which to get trial data
    stores = DatumStore.objects.filter(pk__gte=pk).order_by('-pk')[0:n_erps]#trial data
    #stores = [st for st in stores]#if using iterator()
    #n_stores = len(stores)#how many trials with data were found
    n_stores = stores.count()
    #===========================================================================
    # Situations:
    # 1: We got here with pk=0 and there are no trials: no data, oldest_pk = 0. default.
    # 2: We got here with pk=0 and there are some old trials: no data, oldest_pk is future pk
    # 3: We got here with pk>0 and there are no trials (future pk): no data, oldest_pk is still future pk, also default
    # 4: We got here with pk>0 and there are some trials: data, oldest_pk is that of the oldest returned trial
    #===========================================================================
    #data = [{ "label": pk, "data": [[-50,100],[0,0]]}]
    data = []
    oldest_pk = pk
    channel_labels = []
    if pk==0:
        if n_stores==0:#1
            pass
        else:#2
            oldest_pk = stores[0].pk + 1
    else:
        if n_stores==0:#3
            pass
        else:#4
            n_channels = [st.n_channels for st in stores]
            channel_labels = stores[np.nonzero(n_channels==np.max(n_channels))[0][0]].channel_labels
            #data = [{"label": st.pk, "data": np.column_stack((st.x_vec.T,st.data.T[:,0])).tolist()} for st in stores]
            #This next line is incredibly complicated. it's the equivalent of the following loops.
            data = {}
            for chlb in channel_labels:#for each channel
                data[chlb] = []
                for i in range(n_stores):#For each returned ERP
                    st = stores[i]
                    data[chlb].append({})
                    data[chlb][i]['label'] = st.pk
                    x_bool = np.logical_and(st.x_vec>=x_min,st.x_vec<=x_max)
                    x_vals = st.x_vec[x_bool]
                    y_vals = st.data[channel_labels.index(chlb),x_bool]
                    data[chlb][i]['data'] = [x_vals, y_vals]
                data[chlb].reverse()
            data = dict([(chlb, [{'label': st.pk, 'data': np.column_stack((st.x_vec[np.logical_and(st.x_vec>=x_min,st.x_vec<=x_max)], st.data[channel_labels.index(chlb),np.logical_and(st.x_vec>=x_min,st.x_vec<=x_max)])).tolist()} for st in reversed(stores)]) for chlb in channel_labels])    
            oldest_pk = stores[n_stores-1].pk
            
    #return HttpResponse(json.dumps(data))
    return render_to_response('eerfd/monitor.html', {'oldest_pk': oldest_pk, 'data': json.dumps(data), 'channel_labels': channel_labels, 'channel_labels_s': json.dumps(channel_labels)})

def erps(request, trial_pk_csv='0'):
    #convert trial_pk_csv to trial_pk_list
    trial_pk_list = trial_pk_csv.split(',')
    if len(trial_pk_list[0])>0:
        trial_pk_list = [int(val) for val in trial_pk_list]
        stores = DatumStore.objects.filter(pk__in=trial_pk_list)
        #subject = get_object_or_404(Subject, pk=subject_id)
        data = ','.join(['"' + str(st.datum_id) + '": ' + json.dumps(st.erp.tolist()) for st in stores])
        data = '{' + data + '}'
    else:
        data = '{}'
    return render_to_response('eerfd/erp_data.html',{'data': data})
                    #,context_instance=RequestContext(request))