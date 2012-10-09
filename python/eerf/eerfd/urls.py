from django.conf.urls import patterns, include, url
from django.views.generic import DetailView, ListView
from eerfd.models import *

#===============================================================================
# urlpatterns = patterns('api.views',
#    url(r'^monitor/$', 'monitor'),
#    url(r'^subject/$', 'subject_index'),
#    url(r'^subject/(?P<subject_id>\d+)/$', 'subject_detail'), #calls subject_detail(request=<HttpRequest object>, subject_id='123')
#    url(r'^period/(?P<period_id>\d+)/$', 'period_detail'),
# )
#===============================================================================

urlpatterns = patterns('eerfd.views',
   url(r'^subject/$',
       ListView.as_view(
            queryset=Subject.objects.all(),
            #context_object_name='subject_list',
            #template_name='api/subject_list.html'
        )
   ),
   url(r'^subject/(?P<pk>\d+)/$',
       DetailView.as_view(
          model=Subject,
          #template_name='api/subject_detail.html'
      )
   ),
   url(r'^period/(?P<pk>\d+)/$',
       DetailView.as_view(
          model=Datum,
          template_name='eerfd/period_detail.html',
          context_object_name='period',
      ),
       name='period_detail'
   ),
   url(r'^erps/(?P<trial_pk_csv>(?:\d+,*)*)', 'erps'),
   url(r'^$', 'index'),
   url(r'^store_pk_check/(?P<pk>\d*)', 'store_pk_check'),
   url(r'^monitor/(?P<pk>\d*)', 'monitor'),
   url(r'^set_details/(?P<pk>\d+)/$', 'set_details'),
)