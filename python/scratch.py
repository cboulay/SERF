#Some code for testing.
import sys
import os
sys.path.append(os.path.abspath('d:/tools/eerf/python/eerf'))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "eerf.settings")
from eerfd.models import *
#import eerfx.online
from eerfx.feature_functions import *
from scipy.optimize import curve_fit

request = lambda: None
request.POST = {"MEP_start_ms": 18.3, "MEP_stop_ms": 29.6}
pk = 532
datum = Datum.objects.get(pk=pk)
refdatum = datum if datum.span_type=='period' else datum.periods.all()[datum.periods.count()-1]
for key in request.POST:
    refdatum.update_ddv(key, request.POST[key])