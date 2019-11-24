#Here are some examples of how you can run a standalone application using this project's ORM.
import sys
import django
import os


apppath = os.path.join(os.path.expanduser('~'), "django_eerf", "expdb")
sys.path.insert(0, apppath)
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "expdb.settings")
django.setup()
from eerfapp.models import *


print(Subject.objects.get_or_create(name='Test')[0])
# ft = ('HR_aaa', 'H-reflex avg abs amp')
# myFT = FeatureType.objects.filter(name=ft[0])
