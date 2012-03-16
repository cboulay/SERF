# Evoked Electrophysiological Response Analysis Toolbox (EERAT)

## Python data API

### Installing Python and the API's dependencies

### Interacting with the data

```python

cd D:\Tools/EERAT/
from python-api.Eerat_sqlalchemy import *
my_subj_type=get_or_create(Subject_type, Name='BCPy healthy')
my_subject=get_or_create(Subject, Name='CHAD_TEST', subject_type=my_subj_type, species_type='human')
my_dat_type=get_or_create(Datum_type, Name='hr_baseline')
now_per=my_subject.get_now_period_of_type(my_dat_type)
#SET period's details (e.g. dat_ERP_channel_label, dat_ERP_channel_id)

#Make a new trial. The trial must be persisted so that the SQL triggers create its details and default feature values.
#I would like to use the following but this does not persist the trial until we do a db operation for it.
#new_trial = Datum(subject=my_subject, datum_type=my_dat_type, span_type='trial', IsGood=1)
#Instead we can use get_or_create which will also persist. Using get_or_create, we need to provide a unique key. Since we don't know which datum_ids are available, we will provide the other key (subject, datum_type, Number, span_type), but set Number=0 so we know that this will not match anything.
my_trial = get_or_create(Datum, subject=my_subject, datum_type=my_dat_type, span_type='trial', IsGood=1, Number=0)
my_trial.store={'x_vec':numpy.arange(-500,500, dtype=float), 'data':numpy.array(100*numpy.random.ranf((2,1000)), dtype=float), 'channel_labels':'Trig, EDC'}
#This should kick off the feature calculation

#Load an old trial.
my_trial = my_subject.data[-1]

my_trial.feature_values

import numpy as np
import scipy.optimize
p0 = (50, 0.1, 1000-100, 100)#x0, k, a, c
x = np.linspace(1, 100)
y = feature_functions.my_sigmoid(x, *p0)
y = y + 20*np.random.rand(50,)
popt, pcov = scipy.optimize.curve_fit(feature_functions.my_sigmoid, x, y, p0)
y_est = feature_functions.my_sigmoid(x, *popt)
import pylab
pylab.plot(x, y, 'o', label='data')
pylab.plot(x,y_est, label='fit')
pylab.legend(loc='upper left')
pylab.grid(True)
pylab.show()

```