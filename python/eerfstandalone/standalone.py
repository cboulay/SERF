#Here are some examples of how you can run a standalone application using this project's ORM.
#Choose one of the 3 below methods to get the settings,
#http://www.b-list.org/weblog/2007/sep/22/standalone-django-scripts/
#then import the models.

#===============================================================================
# #1
# #import os
# import sys
# from django.core.management import setup_environ
# from eerf.eerf import settings
# path_out = setup_environ(settings)
# sys.path.append(path_out)
# # from eerf.eerfapi.models import *
#===============================================================================

#2
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
               INSTALLED_APPS = ('eerfapi',)
               )

#===============================================================================
# #3
# import os
# os.environ.setdefault("DJANGO_SETTINGS_MODULE","eerfstandalone.settings")
# #from eerf.eerfapi.models import *
#===============================================================================
