#Some code for testing.
import sys
import os
sys.path.append(os.path.abspath('d:/tools/eerf/python/eerf'))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "eerf.settings")
from api.models import *
#import eerfx.online
from eerfx.feature_functions import *
from scipy.optimize import curve_fit
import statsmodels.api as sm

sub = Subject.objects.filter(name='Test').get()# Get our subject from the DB API.
refdatum = sub.get_or_create_recent_period(delay=999)
datum = refdatum.trials.order_by('-datum_id').all()[0]
mep_feat = 'MEP_p2p' #Change this to 'MEP_aaa' if preferred.
prev_trial_limit = 100
my_bg, my_mep = [datum.calculate_value_for_feature_name(fname, refdatum=refdatum) for fname in ['BEMG_aaa', mep_feat]]
my_stim = float(datum.detail_values_dict()['TMS_powerA'])

#Get background EMG, stimulus amplitude, and MEP_p2p for all trials (lim 100?) for this period.
stim_ddvs = DatumDetailValue.objects.filter(datum__periods__pk=refdatum.datum_id, detail_type__name__contains='TMS_powerA').order_by('-id').all()[:prev_trial_limit]
dd_ids = [temp.datum_id for temp in stim_ddvs]
stim_vals = np.array([temp.value for temp in stim_ddvs],dtype=float)

all_dfvs = DatumFeatureValue.objects.filter(datum__periods__pk=refdatum.datum_id)
bg_dfvs = all_dfvs.filter(feature_type__name__contains='BEMG_aaa').order_by('-id').all()[:prev_trial_limit]
df_ids = [temp.datum_id for temp in bg_dfvs]
bg_vals = np.array([temp.value for temp in bg_dfvs])
mep_dfvs = all_dfvs.filter(feature_type__name__contains=mep_feat).order_by('-id').all()[:prev_trial_limit]
mep_vals = np.array([temp.value for temp in mep_dfvs])

#Restrict ourselves to trials where dd_ids and df_ids match.
uids = np.intersect1d(dd_ids,df_ids,assume_unique=True)
stim_vals = stim_vals[np.in1d(dd_ids, uids)]
bg_vals = bg_vals[np.in1d(df_ids, uids)]
mep_vals = mep_vals[np.in1d(df_ids, uids)]


#Fit a sigmoid to the relationship between stim_vals and mep_vals
def sig_func(x, x0, k):
    return 1 / (1 + np.exp(-k*(x-x0)))

#===============================================================================
# #Fake data
# stim_vals = np.linspace(0,100,1000)
# bg_vals = 100*np.random.rand(1000)
# mep_vals = 1000*sig_func(stim_vals, 50, 0.1) + bg_vals
#===============================================================================

p0=((np.max(stim_vals)-np.min(stim_vals))/2,0.1) #x0, k
y = mep_vals - np.min(mep_vals)
mep_scale = np.max(y)
y = y / mep_scale
popt, pcov = curve_fit(sig_func, stim_vals, y, p0)
stim_vals_sig = np.min(mep_vals) + (mep_scale * sig_func(stim_vals, popt[0], popt[1]))
my_stim_sig = np.min(mep_vals) + (mep_scale * sig_func(my_stim, popt[0], popt[1]))
    
#Do a multiple regression (y=MEP_p2p, X=BEMG_aaa,stim_vals_sig) to identify the coefficients
x = np.column_stack((bg_vals,stim_vals_sig))
x = sm.add_constant(x, prepend=True)
res = sm.OLS(y,x).fit()

#Calculate expected y given this trial's BEMG_aaa and stim_amp
expected_y = 0

# For debugging online ERPExtension

# Use these next few lines to help with debugging.
self = lambda: None
self.app = lambda: None
self.app.params = {'SubjectName':'Test', 'ERPChan':['C3','EDC'], 'ERPFeedbackFeature': 'MEP_p2p'}
self.app.x_vec = np.arange(-500,500,1000.0/2400,dtype=float)
value = np.random.rand(2,2400)
self.app.subject = Subject.objects.get_or_create(name=self.app.params['SubjectName'])[0]# Get our subject from the DB API.
self.app.period = self.app.subject.get_or_create_recent_period(delay=0)# Get our period from the DB API.

#Add detail values to period
self.app.period.update_ddv('MEP_start_ms', '20.0')
self.app.period.update_ddv('MEP_stop_ms', '30.0')
self.app.period.update_ddv('MEP_chan_label', 'EDC')
self.app.period.update_ddv('BG_start_ms', '-500.0')
self.app.period.update_ddv('BG_stop_ms', '-1.0')
self.app.period.update_ddv('BG_chan_label', 'EDC')

#Create a new trial, add it to the period, then add data to the trial.
my_trial = Datum.objects.create(subject=self.app.subject,
            span_type='trial'
            )
self.app.period.trials.add(my_trial)
my_store = DatumStore(datum=my_trial,
             x_vec=self.app.x_vec,
             channel_labels=self.app.params['ERPChan'])
my_store.data = value #this will also set n_channels and n_samples

#my_trial should == last_trial, but let's pull it from the db anyway.
last_trial = self.app.period.trials.order_by('-datum_id').all()[0] if self.app.period.trials.count()>0 else None
feature_name = self.app.params['ERPFeedbackFeature']
last_trial.update_ddv('Conditioned_feature_name', feature_name)

#Import detail values from parent --> Write a function to do this
last_trial.copy_details_from(self.app.period)

#Calculate feature value. Need the option of using a reference datum or None (self)
last_trial.calculate_value_for_feature_name(feature_name)
feature_value = last_trial.feature_values_dict()[feature_name]
last_trial.update_ddv('Conditioned_result',True)