import json
import numpy as np
import datetime
from django.shortcuts import render, get_object_or_404
from django.views.decorators.http import require_http_methods
from django.http import HttpResponse, HttpResponseRedirect  # , Http404
from django.contrib.sessions.models import Session
from django.core.serializers.json import DjangoJSONEncoder
from serf import models
# import pdb
# from django.core.urlresolvers import reverse
# from django.template import RequestContext, loader


def index(request):
    """
    Index. For now this is a redirect to something useful.
    :param request:
    :return: HttpResponseRedirect
    """
    # return render_to_response('eerfapp/index.html')
    # pdb.set_trace()
    request.session.flush()
    return HttpResponseRedirect('/eerfapp/subject/')


# ===============================================================================
# Helper functions (not views)
# ===============================================================================
def store_man_for_request_subject(request, pk):
    # Helper function to return a filtered DatumStore manager.
    store_man = models.DatumStore.objects.filter(datum__subject__pk=pk).filter(datum__span_type=1).filter(n_samples__gt=0)
    my_session = models.Session.objects.get(pk=request.session.session_key).get_decoded()
    if my_session.has_key('trial_start'):
        store_man = store_man.filter(datum__start_time__gte=my_session['trial_start'])
    if my_session.has_key('trial_stop'):
        store_man = store_man.filter(datum__stop_time__lte=my_session['trial_stop'])
    return store_man

# ===============================================================================
# Rendering views
# ===============================================================================

# /subject/, /subject/pk/, and /period/ are all automatic views.


def subject_list(request): # View list of subjects and option to import
    mySubjects = models.Subject.objects.all()
    context = {'subject_list': mySubjects}
    return render(request, 'eerfapp/subject_list.html', context)


def subject_import(request):
    # TODO: Get list of elizan subjects. Mark those that are already imported.
    context = {'elizan_subjects': {} }
    return render(request, 'eerfapp/subject_import.html', context)


def view_data(request, pk):  # View data for subject with pk
    subject = get_object_or_404(models.Subject, pk=pk)
    context = {'subject': subject}
    return render(request, 'eerfapp/subject_view_data.html', context)


def erps(request, trial_pk_csv='0'):
    # convert trial_pk_csv to trial_pk_list
    trial_pk_list = trial_pk_csv.split(',')
    if len(trial_pk_list[0])>0:
        trial_pk_list = [int(val) for val in trial_pk_list]
        stores = models.DatumStore.objects.filter(pk__in=trial_pk_list)
        # subject = get_object_or_404(Subject, pk=subject_id)
        data = ','.join(['"' + str(st.datum_id) + '": ' + json.dumps(st.erp.tolist()) for st in stores])
        data = '{' + data + '}'
    else:
        data = '{}'
    return render(request, 'eerfapp/erp_data.html',{'data': data})


# ===============================================================================
# API: GET or POST. Non-rendering.
# ===============================================================================
@require_http_methods(["GET", "POST"])
def set_details(request, pk):
    subject = get_object_or_404(models.Subject, pk=pk)
    my_dict = request.POST.copy()
    my_dict.pop('csrfmiddlewaretoken', None)  # Remove the token provided by the POST command
    for key in my_dict:
        subject.update_ddv(key, my_dict[key])
    # return HttpResponseRedirect(reverse('eerfapp.views.monitor', args=(pk,)))
    return HttpResponseRedirect(request.META['HTTP_REFERER'])


@require_http_methods(["GET"])
def get_detail_values(request, pk, detail_name, json_vals_only=True):
    detail_type = get_object_or_404(models.DetailType, name=detail_name)
    ddvs_man = models.DatumDetailValue.objects.filter(datum__subject__pk=pk).filter(detail_type=detail_type)
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
    feature_type = get_object_or_404(models.FeatureType, name=feature_name)
    dfvs_man = models.DatumFeatureValue.objects.filter(datum__subject__pk=pk).filter(feature_type=feature_type)
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
    trial_man = models.Datum.objects.filter(subject__pk=pk, span_type=1, store__n_samples__gt=0)
    my_session = Session.objects.get(pk=request.session.session_key).get_decoded()
    if my_session.has_key('trial_start'):
        trial_man = trial_man.filter(start_time__gte=my_session['trial_start'])
    if my_session.has_key('trial_stop'):
        trial_man = trial_man.filter(stop_time__lte=my_session['trial_stop'])
    for tr in trial_man:
        tr.calculate_value_for_feature_name(feature_name)
    return HttpResponse('success')


@require_http_methods(["GET"])
def count_trials(request, pk):  # GET number of trials for subject. Uses session variables. Non-rendering
    store_man = store_man_for_request_subject(request, pk)
    return HttpResponse(json.dumps(store_man.count()))


@require_http_methods(["GET"])
def erp_data(request, pk):  # Gets ERP data for a subject. Uses session variables. Non-rendering.
    [x_min, x_max] = [-10, 100.0]

    # Get the manager for datum_store... and reverse its order
    store_man = store_man_for_request_subject(request, pk).order_by('-pk')

    # Get the last trial_limit trials
    my_session = Session.objects.get(pk=request.session.session_key).get_decoded()
    trial_limit = int(my_session['trial_limit']) if my_session.has_key('trial_limit') and int(my_session['trial_limit'])>0 else store_man.count()
    store_man = store_man[0:trial_limit]

    # Return the channel_labels and data
    if store_man.count()>0:
        n_channels = [st.n_channels for st in store_man]
        channel_labels = store_man[np.nonzero(n_channels==np.max(n_channels))[0][0]].channel_labels
        data = dict([(chlb, [{'label': st.pk, 'data': np.column_stack((st.x_vec[np.logical_and(st.x_vec>=x_min,st.x_vec<=x_max)], st.data[channel_labels.index(chlb),np.logical_and(st.x_vec>=x_min,st.x_vec<=x_max)])).tolist()} for st in reversed(store_man)]) for chlb in channel_labels])
    else:
        channel_labels = ''
        data = {}
    return HttpResponse(json.dumps({'data': data, 'channel_labels': channel_labels}))


@require_http_methods(["GET"])
def get_xy(request):
    getter = request.GET.copy()
    my_session = Session.objects.get(pk=request.session.session_key).get_decoded()
    trial_man = models.Datum.objects.filter(subject__pk=getter['subject_pk'], span_type=1)
    trial_man = trial_man.filter(start_time__gte=my_session['trial_start']) if my_session.has_key('trial_start') else trial_man
    trial_man = trial_man.filter(stop_time__lte=my_session['trial_stop']) if my_session.has_key('trial_stop') else trial_man
    trial_man = trial_man.filter(_detail_values__detail_type__name=getter['x_name'])
    trial_man = trial_man.filter(_feature_values__feature_type__name=getter['y_name'])
    trial_man = trial_man.distinct()
    x = [float(tr._detail_values.get(detail_type__name='TMS_powerA').value) for tr in trial_man]
    y = [tr._feature_values.get(feature_type__name='MEP_p2p').value for tr in trial_man]
    data = [{"label": getter['y_name'], "data": np.column_stack((x,y)).tolist()}]
    return HttpResponse(json.dumps(data))


# GET or POST session dictionary.
@require_http_methods(["GET", "POST"])
def my_session(request):
    my_session = Session.objects.get(pk=request.session.session_key).get_decoded()
    if request.method == 'GET':
        return HttpResponse(json.dumps(my_session, cls=DjangoJSONEncoder))
    elif request.method == 'POST':
        my_post = request.POST.copy()#mutable copy of POST
        my_post.pop('csrfmiddlewaretoken', None)

        # Fix date values. %b->Sep, %d->11, %Y->2001, %X->locale time
        # Returned as '1/25/2013 6:46:03 AM'
        # date_format = '%b %d %Y %X'#date_format = '%Y-%m-%dT%H:%M:%S'
        date_format = '%m/%d/%Y %I:%M:%S %p'
        date_keys = ['trial_start', 'trial_stop']
        for key in date_keys:
            my_post[key] = datetime.datetime.strptime(my_post[key], date_format) if my_post.has_key(key) else request.session.get(key, datetime.datetime.now())

        # Other values to fix
        my_post['monitor'] = my_post.has_key('monitor') if my_post.has_key('trial_start') else True

        # Put the values back into request.session
        for key in my_post: request.session[key] = my_post[key]
        return HttpResponseRedirect(request.META['HTTP_REFERER'])


@require_http_methods(["GET"])
def detail_types(request):
    dts = models.DetailType.objects.all()
    dt_names = [dt.name for dt in dts]
    return HttpResponse(json.dumps(dt_names))


@require_http_methods(["GET"])
def feature_types(request):
    fts = models.FeatureType.objects.all()
    ft_names = [ft.name for ft in fts]
    return HttpResponse(json.dumps(ft_names))


def store_pk_check(request, pk):
    # Given a pk, return how many DatumStore objects we have with pk greater
    pk = int(pk) if len(pk)>0 else 0
    n_stores = models.DatumStore.objects.filter(pk__gte=pk).count()
    return HttpResponse(json.dumps(n_stores))

    
@require_http_methods(["POST"])
def import_elizan(request):
    my_session = Session.objects.get(pk=request.session.session_key).get_decoded()
    my_post = request.POST.copy()  # mutable copy of POST
    my_post.pop('csrfmiddlewaretoken', None)
    selected_sub = my_post.has_key('subject_select')
    subject_json = my_post['subject_json']
    # TODO: parse JSON
    # TODO: import subject.
    return HttpResponseRedirect(request.META['HTTP_REFERER'])
