### Dependencies

numpy
scipy
SQLAlchemy

### Instructions

Get a period object.

```python

#cd D:\Tools/EERAT/
from python_api.Eerat_sqlalchemy import *
from python_apps.online_analysis.PeriodExtension import *
my_subj_type=get_or_create(Subject_type, Name='BCPy_healthy')
my_subject=get_or_create(Subject, Name='CHAD_TEST', subject_type=my_subj_type, species_type='human')
my_dat_type=get_or_create(Datum_type, Name='hr_baseline')
now_per=my_subject.get_now_period_of_type(my_dat_type)
```

_FOR TESTING/DEBUGGING ONLY_
We need some trial data. Create some trials if they do not already exist.

```python
my_trial = get_or_create(Datum\
    , subject=my_subject\
    , datum_type=my_dat_type\
    , span_type='trial'\
    , IsGood=1\
    , Number=0)
	
my_trial.store={\
    'x_vec':numpy.arange(-500,500, dtype=float)\
    , 'data':numpy.array(100*numpy.random.ranf((2,1000)), dtype=float)\
    , 'channel_labels':'Trig, EDC'}
```

Update the period's stored ERP so it is the average of all its good trials.

```python
now_per.update_store()
```
This should automatically kick off calculations of the period's features that are common with trials.

Calculate period-specific features. These will not be persisted.
Some examples:

* M_max
* HR_thresh
* HR_thresh_err
* HR_halfmax
* HR_halfmax_err
* MEP_thresh
* MEP_thresh_err
* MEP_halfmax
* MEP_halfmax_err
* MEP_max

It wouldn't be efficient to calculate these independently so there are some more efficient methods provided in this module.




ignore me for now

```python
#import pylab
#import numpy as np
#import scipy.optimize
#p0 = (50, 0.1, 1000-100, 100)#x0, k, a, c
#x = np.linspace(1, 100)
#y = feature_functions.my_sigmoid(x, *p0)
#y = y + 20*np.random.rand(50,)
#popt, pcov = scipy.optimize.curve_fit(feature_functions.my_sigmoid, x, y, p0)
#y_est = feature_functions.my_sigmoid(x, *popt)
#pylab.plot(x, y, 'o', label='data')
#pylab.plot(x,y_est, label='fit')
#pylab.legend(loc='upper left')
#pylab.grid(True)
#pylab.show()
```