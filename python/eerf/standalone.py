#Here are some examples of how you can run a standalone application using this project's ORM.
#Choose one of the 3 below methods to get the settings,
#http://www.b-list.org/weblog/2007/sep/22/standalone-django-scripts/
#then import the models.

#1==============================================================================
# from django.core.management import setup_environ
# from eerf.eerf import settings
# setup_environ(settings)
# from eerf.api.models import *
#===============================================================================

#2==============================================================================
from django.conf import settings
settings.configure(
                  DEBUG=True,
                  DATABASES = {
                               'default': {
                                           'ENGINE': 'django.db.backends.mysql', # Add 'postgresql_psycopg2', 'mysql', 'sqlite3' or 'oracle'.
                                           'NAME': 'EERF',                      # Or path to database file if using sqlite3.
                                           'USER': 'root',                      # Not used with sqlite3.
                                           }
                               },
                  INSTALLED_APPS = ('api',)
                  )
from api.models import *

#3==============================================================================
# import os
# os.environ["DJANGO_SETTINGS_MODULE"] = 'eerf.eerf.settings'
# from api.models import *
#===============================================================================