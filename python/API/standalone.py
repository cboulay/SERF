# Django specific settings
#===============================================================================
# from django.conf import settings
# settings.configure(
#                   DEBUG=True,
#                   DATABASES = {
#                                'default': {
#                                            'ENGINE': 'django.db.backends.mysql', # Add 'postgresql_psycopg2', 'mysql', 'sqlite3' or 'oracle'.
#                                            'NAME': 'EERF',                      # Or path to database file if using sqlite3.
#                                            'USER': 'root',                      # Not used with sqlite3.
#                                            'PASSWORD': '',                  # Not used with sqlite3.
#                                            'HOST': '',                      # Set to empty string for localhost. Not used with sqlite3.
#                                            'PORT': '',                      # Set to empty string for default. Not used with sqlite3.
#                                            }
#                                },
#                   INSTALLED_APPS = ('db',)
#                   )
#===============================================================================

from django.core.management import setup_environ
from API import settings
setup_environ(settings)

#os.environ["DJANGO_SETTINGS_MODULE"] = "settings.py"