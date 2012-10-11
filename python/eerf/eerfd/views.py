import json
import numpy as np
from django.template import RequestContext
from django.shortcuts import render_to_response, get_object_or_404
from django.core.urlresolvers import reverse
from django.views.decorators.http import require_http_methods
from django.http import HttpResponse, Http404, HttpResponseRedirect
from django.contrib.sessions.models import Session
from django.core.serializers.json import DjangoJSONEncoder
from eerfd.models import *

def index(request):
    #return render_to_response('eerfd/index.html')
    return HttpResponseRedirect('/eerfd/subject/')

#===============================================================================
# Helper
#===============================================================================
def store_man_for_request_subject(request, pk): #Helper function to return a filtered DatumStore manager.
    store_man = DatumStore.objects.filter(datum__subject__pk=pk).filter(datum__span_type=1).filter(n_samples__gt=0)
    my_session = Session.objects.get(pk=request.session.session_key).get_decoded()
    if my_session.has_key('trial_start'):
        store_man = store_man.filter(datum__start_time__gte=my_session['trial_start'])
    if my_session.has_key('trial_stop'):
        store_man = store_man.filter(datum__stop_time__lte=my_session['trial_stop'])
    return store_man

#===============================================================================
# Model-specific views
#===============================================================================
#/subject/, /subject/pk/, and /period/ are all automatic views.
def view_data(request, pk):#View data for subject with pk
    subject = Subject.objects.get(pk=pk)
    return render_to_response('eerfd/subject_view_data.html',
                              {'subject': subject
                               },
                              context_instance=RequestContext(request))
    
#GET or POST details for subject. Non-rendering.
@require_http_methods(["GET", "POST"])
def set_details(request, pk):
     #==========================================================================
     # return HttpResponse(json.dumps(request.POST.copy()))
     #==========================================================================
     subject = get_object_or_404(Subject, pk=pk)
     my_dict = request.POST.copy()
     my_dict.pop('csrfmiddlewaretoken', None)#Remove the token provided by the POST command
     for key in my_dict:
        subject.update_ddv(key, my_dict[key])
     #return HttpResponseRedirect(reverse('eerfd.views.monitor', args=(pk,)))
     return HttpResponseRedirect(request.META['HTTP_REFERER'])

@require_http_methods(["GET"])
def get_detail_values(request, pk, detail_name, json_vals_only=True):
    detail_type = get_object_or_404(DetailType, name=detail_name)
    ddvs_man = DatumDetailValue.objects.filter(datum__subject__pk=pk).filter(detail_type=detail_type)
    my_session = Session.objects.get(pk=request.session.session_key).get_decoded()
    if my_session.has_key('trial_start'):
        ddvs_man = ddvs_man.filter(datum__start_time__gte=my_session['trial_start'])
    if my_session.has_key('trial_stop'):
        ddvs_man = ddvs_man.filter(datum__stop_time__lte=my_session['trial_stop'])
    if json_vals_only:
        ddvs = [ddv.value for ddv in ddvs_man]
        return HttpResponse(json.dumps(ddvs))
    else:
        return ddvs_man

@require_http_methods(["GET"])
def get_feature_values(request, pk, feature_name, json_vals_only=True):
    feature_type = get_object_or_404(FeatureType, name=feature_name)
    dfvs_man = DatumFeatureValue.objects.filter(datum__subject__pk=pk).filter(feature_type=feature_type)
    my_session = Session.objects.get(pk=request.session.session_key).get_decoded()
    if my_session.has_key('trial_start'):
        dfvs_man = dfvs_man.filter(datum__start_time__gte=my_session['trial_start'])
    if my_session.has_key('trial_stop'):
        dfvs_man = dfvs_man.filter(datum__stop_time__lte=my_session['trial_stop'])
    if json_vals_only:
        dfvs = [dfv.value for dfv in dfvs_man]
        return HttpResponse(json.dumps(dfvs))
    else:
        return dfvs_man

def recalculate_feature(request, pk, feature_name):    
    trial_man = Datum.objects.filter(subject__pk=pk, span_type=1, store__n_samples__gt=0)
    my_session = Session.objects.get(pk=request.session.session_key).get_decoded()
    if my_session.has_key('trial_start'):
        trial_man = trial_man.filter(start_time__gte=my_session['trial_start'])
    if my_session.has_key('trial_stop'):
        trial_man = trial_man.filter(stop_time__lte=my_session['trial_stop'])
    for tr in trial_man:
        tr.calculate_value_for_feature_name(feature_name)
    return HttpResponse('success')

@require_http_methods(["GET"])
def count_trials(request, pk): #GET number of trials for subject. Uses session variables. Non-rendering
    store_man = store_man_for_request_subject(request, pk)
    return HttpResponse(json.dumps(store_man.count()))

@require_http_methods(["GET"])
def erp_data(request, pk): #Gets ERP data for a subject. Uses session variables. Non-rendering.
    [x_min,x_max] = [-10.0,100.0]
    
    store_man = store_man_for_request_subject(request, pk)
    n_stores = store_man.count()
    
    if n_stores>0:
        n_channels = [st.n_channels for st in store_man]
        channel_labels = store_man[np.nonzero(n_channels==np.max(n_channels))[0][0]].channel_labels
        data = dict([(chlb, [{'label': st.pk, 'data': np.column_stack((st.x_vec[np.logical_and(st.x_vec>=x_min,st.x_vec<=x_max)], st.data[channel_labels.index(chlb),np.logical_and(st.x_vec>=x_min,st.x_vec<=x_max)])).tolist()} for st in reversed(store_man)]) for chlb in channel_labels])
    else:
        channel_labels = ''
        data = {}
        
    return HttpResponse(json.dumps({'data': data, 'channel_labels': channel_labels}))

#===============================================================================
# Non-rendering views for some simple API tools
#===============================================================================
@require_http_methods(["GET"])
def get_xy(request):
    getter = request.GET.copy()
    my_session = Session.objects.get(pk=request.session.session_key).get_decoded()
    trial_man = Datum.objects.filter(subject__pk=getter['subject_pk'], span_type=1)
    trial_man = trial_man.filter(start_time__gte=my_session['trial_start']) if my_session.has_key('trial_start') else trial_man
    trial_man = trial_man.filter(stop_time__lte=my_session['trial_stop']) if my_session.has_key('trial_stop') else trial_man 
    trial_man = trial_man.filter(_detail_values__detail_type__name=getter['x_name'])
    trial_man = trial_man.filter(_feature_values__feature_type__name=getter['y_name'])
    trial_man = trial_man.distinct()
    x = [float(tr._detail_values.get(detail_type__name='TMS_powerA').value) for tr in trial_man]
    y = [tr._feature_values.get(feature_type__name='MEP_p2p').value for tr in trial_man]
    data = [{ "label": getter['y_name'], "data": np.column_stack((x,y)).tolist()}]
    return HttpResponse(json.dumps(data))

#GET or POST session dictionary.
@require_http_methods(["GET", "POST"])
def my_session(request):
    my_session = Session.objects.get(pk=request.session.session_key).get_decoded()
    if request.method == 'GET':
        return HttpResponse(json.dumps(my_session, cls=DjangoJSONEncoder))
    elif request.method == 'POST':
        my_post = request.POST.copy()#mutable copy of POST
        my_session['trial_start'] = datetime.datetime.strptime(my_post['trial_start'], '%Y-%m-%dT%H:%M:%S') if my_post.has_key('trial_start') else request.session.get('trial_start', datetime.datetime.now())
        my_session['trial_stop'] = datetime.datetime.strptime(my_post['trial_stop'], '%Y-%m-%dT%H:%M:%S') if my_post.has_key('trial_stop') else request.session.get('trial_stop', datetime.datetime.now() + datetime.timedelta(hours = 1))    
        my_session['monitor'] = my_post.has_key('monitor') if my_post.has_key('trial_start') else True
        for key in my_session: request.session[key] = my_session[key] #Put the values back into request.session
        return HttpResponseRedirect(request.META['HTTP_REFERER'])
    
@require_http_methods(["GET"])
def detail_types(request):
    dts = DetailType.objects.all()
    dt_names = [dt.name for dt in dts]
    return HttpResponse(json.dumps(dt_names))

@require_http_methods(["GET"])
def feature_types(request):
    fts = FeatureType.objects.all()
    ft_names = [ft.name for ft in fts]
    return HttpResponse(json.dumps(ft_names))

def store_pk_check(request, pk):
    #Given a pk, return how many DatumStore objects we have with pk greater
    pk = int(pk) if len(pk)>0 else 0
    n_stores = DatumStore.objects.filter(pk__gte=pk).count()
    return HttpResponse(json.dumps(n_stores))

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
                    
#===============================================================================
# Rendering views that are not specific to a model
#===============================================================================
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
            #===================================================================
            # This next line is incredibly complicated. it's the equivalent of the following loops.
            # data = {}
            # for chlb in channel_labels:#for each channel
            #    data[chlb] = []
            #    for i in range(n_stores):#For each returned ERP
            #        st = stores[i]
            #        data[chlb].append({})
            #        data[chlb][i]['label'] = st.pk
            #        x_bool = np.logical_and(st.x_vec>=x_min,st.x_vec<=x_max)
            #        x_vals = st.x_vec[x_bool]
            #        y_vals = st.data[channel_labels.index(chlb),x_bool]
            #        data[chlb][i]['data'] = [x_vals, y_vals]
            #    data[chlb].reverse()
            #===================================================================
            data = dict([(chlb, [{'label': st.pk, 'data': np.column_stack((st.x_vec[np.logical_and(st.x_vec>=x_min,st.x_vec<=x_max)], st.data[channel_labels.index(chlb),np.logical_and(st.x_vec>=x_min,st.x_vec<=x_max)])).tolist()} for st in reversed(stores)]) for chlb in channel_labels])    
            oldest_pk = stores[n_stores-1].pk
            
    #return HttpResponse(json.dumps(data))
    return render_to_response('eerfd/monitor.html', {'oldest_pk': oldest_pk, 'data': json.dumps(data), 'channel_labels': channel_labels, 'channel_labels_s': json.dumps(channel_labels)},
                              context_instance=RequestContext(request)) 