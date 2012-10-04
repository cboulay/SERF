from django.template import RequestContext
from django.shortcuts import render_to_response, get_object_or_404
from eerfd.models import *
from django.http import HttpResponse, Http404
import json
import numpy as np

def index(request):
    return render_to_response('eerfd/index.html')

def store_pk_check(request, pk):
    pk = int(pk) if len(pk)>0 else 0
    stores = DatumStore.objects.filter(pk__gt=pk).order_by('-pk')
    n_stores = stores.count()
    new_pk = stores[0].pk
    result = [new_pk, n_stores]
    return HttpResponse(json.dumps(result))

def monitor(request, pk):
    #Shows n_erps most recent ERPs greater than pk.
    n_erps = 5
    pk = int(pk) if len(pk)>0 else None
    if not pk:
        pk = DatumStore.objects.order_by('-pk')[0].pk
        data = '{}'
    else:
        stores = DatumStore.objects.filter(pk__gt=pk).order_by('-pk')[:5]#The first one is the newest
        #=======================================================================
        # Data should be transformed into the following JSON
        # data = [{ label: pk, data: [[x,y],[x,y] ...]]}, {}...]
        #=======================================================================
        data = [{'label': st.pk, 'data': np.column_stack((st.x_vec.T,st.data.T[:,0])).tolist()} for st in stores]
        #Don't need to remove the baseline.
        #But should limit x.
        pk = stores[stores.count()-1].pk
        #Need the javascript to autorefresh whenever store_pk_check returns a value greater than pk
    #return HttpResponse(json.dumps(data))
    return render_to_response('eerfd/monitor.html', {'pk': pk, 'data': json.dumps(data)})

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