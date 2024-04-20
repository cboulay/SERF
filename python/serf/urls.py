from django.conf.urls import include, url
from django.views.generic import DetailView, ListView
from serf import models, views


# ===============================================================================
# urlpatterns = patterns('api.views',
#    url(r'^monitor/$', 'monitor'),
#    url(r'^subject/$', 'subject_index'),
#    url(r'^subject/(?P<subject_id>\d+)/$', 'subject_detail'), #calls subject_detail(request=<HttpRequest object>, subject_id='123')
#    url(r'^period/(?P<period_id>\d+)/$', 'period_detail'),
# )
# ===============================================================================


urlpatterns = [

    # /eerfapp/ ==> a redirect to /eerfapp/subjects/
    url(r'^$', views.index, name='index'),
    
    # ===========================================================================
    # Some URLs for a basic API.
    # ===========================================================================
    
    # /eerfapp/my_session/ ==> #GET session info in JSON or POST session details (trial_start, trial_stop, monitor)
    url(r'^my_session/$', views.my_session, name='my_session'),
    
    # /eerfapp/detail_types/ ==> JSON of detail_types names
    url(r'^detail_types/$', views.detail_types),
    
    # /eerfapp/feature_types/ ==> JSON of feature_types names
    url(r'^feature_types/$', views.feature_types),
    
    # /eerfapp/get_xy/ ==> GET data of detail (x) and feature (y) for subject_pk. Uses session for trial_start and trial_stop
    url(r'^get_xy/$', views.get_xy),
    
    # url(r'^erps/(?P<trial_pk_csv>(?:\d+,*)*)', 'erps'),
    # url(r'^store_pk_check/(?P<pk>\d*)', 'store_pk_check'),
    
    # ===========================================================================
    # URLs with rendered views.
    # ===========================================================================
    url(r'^subject/$',  # List all the subjects.
        ListView.as_view(
            queryset=models.Subject.objects.all(),
            # context_object_name='subject_list', #default
            # template_name='eerfapp/subject_list.html' #default
        ),
        name='subject'
    ),
    url(r'^subject_import/$', views.subject_import, name='subject_import'),
    url(r'^subject/(?P<pk>\d+)/$',  # Give details about a specific subject.
        DetailView.as_view(
            model=models.Subject,
            # template_name='api/subject_detail.html'
        ),
        name='subject_item'
    ),
    url(r'^subject/(?P<pk>\d+)/view_data/$', views.view_data, name='view_data'),  # Show trial data for a specific subject.
    url(r'^subject/(?P<pk>\d+)/set_details/$', views.set_details, name='set_details'),  # POST a dict of detail kvps for subject pk
    url(r'^subject/(?P<pk>\d+)/detail_values/(?P<detail_name>\w*)/$', views.get_detail_values),  # GET the values for a detail name
    url(r'^subject/(?P<pk>\d+)/feature_values/(?P<feature_name>\w*)/$', views.get_feature_values),  # GET the values for a feature name
    url(r'^subject/(?P<pk>\d+)/count_trials/$', views.count_trials),  # GET the number of trials, filtered by session variables.
    url(r'^subject/(?P<pk>\d+)/erp_data/$', views.erp_data),  # GET the erp_data for this subject, filtered by session variables.
    url(r'^subject/(?P<pk>\d+)/recalculate_feature/(?P<feature_name>\w+)/$', views.recalculate_feature),  # Recalculate feature values
    url(r'^period/(?P<pk>\d+)/$',
        DetailView.as_view(
            model=models.Datum,
            template_name='eerfapp/period_detail.html',
            context_object_name='period',
        ),
        name='period_detail'
    ),
                       
    # ===========================================================================
    # Other URLs
    # ===========================================================================
    url(r'^import_elizan/$', views.import_elizan, name='import_elizan'),
]
