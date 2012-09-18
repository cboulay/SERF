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
#===============================================================================

#===============================================================================
# #2
# from django.conf import settings
# settings.configure(
#               DEBUG=True,
#               DATABASES = {
#                            'default': {
#                                        'ENGINE': 'django.db.backends.mysql', # Add 'postgresql_psycopg2', 'mysql', 'sqlite3' or 'oracle'.
#                                        'NAME': 'EERF',                      # Or path to database file if using sqlite3.
#                                        'USER': 'root',                      # Not used with sqlite3.
#                                        }
#                            },
#               INSTALLED_APPS = ('api',)
#               )
#===============================================================================

#===============================================================================
# #3
# import os
# os.environ.setdefault("DJANGO_SETTINGS_MODULE","eerf.settings")
#===============================================================================

#===============================================================================
# # 4 - Add the path to (manage.py) to python path then os.environ
# import os
# sys.path.append(os.path.abspath('d:/tools/eerf/python/eerf'))
# os.environ.setdefault("DJANGO_SETTINGS_MODULE", "eerf.settings")
#===============================================================================

# from api.models import *
# Subject.objects.get_or_create(name='Test')[0]