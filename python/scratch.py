#Some code for testing.
import sys
import os
sys.path.append(os.path.abspath('d:/tools/eerf/python/eerf'))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "eerf.settings")
from eerfd.models import *
#import eerfx.online
from eerfx.feature_functions import *
from scipy.optimize import curve_fit


#===============================================================================
# Calculate residual
#===============================================================================
#Fit a sigmoid to the relationship between stim_vals and mep_vals
def sig_func(x, x0, k):
    return 1 / (1 + np.exp(-k*(x-x0)))

#===============================================================================
# #Fake data
# stim_vals = np.linspace(0,100.0,1000.0)
# bg_vals = 100.0*np.random.randn(1000)
# mep_vals = -120 + 1000.0*sig_func(stim_vals, 50.0, 0.1) + 1.2*bg_vals
# my_bg, my_stim, my_mep = (100.0, 50.0, 1000.0*sig_func(50.0, 50.0, 0.1) + 1.2*100.0)
#===============================================================================

p0=((np.max(stim_vals)-np.min(stim_vals))/2,0.1) #x0, k
y = mep_vals - np.min(mep_vals)
mep_scale = np.max(y)
y = y / mep_scale
popt, pcov = curve_fit(sig_func, stim_vals, y, p0)
stim_vals_sig = np.min(mep_vals) + (mep_scale * sig_func(stim_vals, popt[0], popt[1]))
my_stim_sig = np.min(mep_vals) + (mep_scale * sig_func(my_stim, popt[0], popt[1]))

#Simulate passing these variables off to another function
test_x = np.column_stack((my_bg, my_stim_sig))
test_y = np.array(my_mep)
train_x = np.column_stack((bg_vals, stim_vals_sig))
train_y = np.array(mep_vals)

x_means = np.mean(train_x,0)
x_std = np.std(train_x,0)
zx = (train_x-x_means)/x_std #Built-in broadcasting

#Calculate the coefficients for zy = a zx. Prepend zx with column of ones
coeffs = np.linalg.lstsq(np.column_stack((np.ones(zx.shape[0],),zx)),train_y)[0]

#Calculate expected_y using the coefficients and test_x
test_zx = (test_x - x_means)/x_std
expected_y = dot(coeffs, np.column_stack((np.ones(test_zx.shape[0]),test_zx)).T)
residual = test_y - expected_y #Should be about 120 if using fake data.
    

#===============================================================================
# For debugging online ERPExtension 
#===============================================================================

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