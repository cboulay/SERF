### Instructions

Get a period object.

```python

cd D:\Tools/EERAT/ #Useful for my testing with IPython
from python_api.Eerat_sqlalchemy import *
my_subj_type=get_or_create(Subject_type, Name='BCPy healthy')
my_subject=get_or_create(Subject, Name='CHAD_TEST', subject_type=my_subj_type, species_type='human')
my_dat_type=get_or_create(Datum_type, Name='hr_baseline')
now_per=my_subject.get_now_period_of_type(my_dat_type)
```

Update the period's stored ERP so it is the average of all its good trials.
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