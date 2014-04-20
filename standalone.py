#Here are some examples of how you can run a standalone application using this project's ORM.
import os, sys, django
try:
    apppath = os.path.dirname(__file__)
except NameError:
    apppath = os.path.join("/", "Users", "chadwickboulay", "Documents", "newEERF", "mysite")
sys.path.insert(0, apppath)
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "mysite.settings")
django.setup()
from eerfapp.models import *

ft = ('HR_aaa','H-reflex avg abs amp')
myFT = FeatureType.objects.filter(name=ft[0])

# Subject.objects.get_or_create(name='Test')[0]