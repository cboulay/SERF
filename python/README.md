# Evoked Electrophysiological Response Feedback (EERF)

## Python data API

This project createts a data store for use with EERF.
This data store may be accessed through a simple web interface or directly from within Python.

### Installing Python and the API's dependencies

Dependencies include Numpy, ?Scipy, Django, and MySQL-python.
Numpy, Scipy, and Django all have extensive documentation on how to install those packages. Please consult their respective pages.
MySQL-python is a little tricky to install on OSX and the information is difficult to find.
Try the code below after changing the mysql directory to match your installed version.

```

>sudo -i
#export PATH=$PATH:/usr/local/mysql-5.5.17-osx10.6-x86_64/bin
#export DYLD_LIBRARY_PATH=/usr/local/mysql/lib/
#export ARCHFLAGS='-arch i386 -arch x86_64'
#export CC=gcc-4.2
#export PATH="/Library/Frameworks/Python.framework/Versions/2.7/bin:${PATH}"
#easy_install mysql-python
#sudo pip install MySQL-python==1.2.3c1

```

### Interacting with the data

In a terminal or command-prompt, change to the EERF/python/eerf directory, and execute
`python manage.py syncdb`
Go through the steps to create your admin account. Now, at the same prompt, type
`python manage.py runserver`
Open a browser and navigate to the specified page, and append `/admin/` to the end of the URL.
This will provide you with basic access to the database models.

To access the ORM from within a separate Python app, we have to install this django project as a regular python package (i.e. in site-packages).
In a terminal or command-prompt, change to the EERF/python directory, and execute
`python setup.py install`
Then your custom python script could have the following:

```python

import os
os.environ["DJANGO_SETTINGS_MODULE"] = 'eerf.eerf.settings'
from eerf import eerfapi
from eerf.eerfapi.models import *
sub = Subject.objects.all()[0]
trial = sub.periods[0].trials.all()[0]

```

#### Everything below is out of date.

Beyond plotting single trials there are futher analyses built-in to the OnlineAPIExtension.
Many of these are for analyzing periods and the trials within them.

```python

from EeratAPI.API import *
from EeratAPI.OnlineAPIExtension import *
my_subj_type=get_or_create(Subject_type, Name='BCPy_healthy')
my_subject=get_or_create(Subject, Name='CBB_TEST', subject_type=my_subj_type, species_type='human')
my_dat_type=get_or_create(Datum_type, Name='mep_baseline')
my_det_type=get_or_create(Detail_type, Name='dat_TMS_powerB')
my_dat_type.detail_types.append(my_det_type)
now_per = my_subject.get_most_recent_period(datum_type=my_dat_type,delay=12)
#This will create a period if it does not find a match.

```

now_per is a Datum (period) instance for the provided Datum_type (my_dat_type).
We can update the period store as the average of its (good) trials:

```python
now_per.update_store()
temp_store = now_per.store
x=temp_store['x_vec']
y=temp_store['data']
chan_labels=temp_store['channel_labels']
plots=plot(x,y.T,label=chan_labels)
legend(plots,chan_labels)
```

Or we can model the ERP's input-output curve for this period and get estimates of its parameters.

```python

#If you want changed the ERP window and want to recalculate. It's a bit slow.
#for t in now_per.trials:
#	t.calculate_all_features()
	
#Possible values of model_type are 'halfmax' (default) and 'threshold' 
parms,parms_err = now_per.model_erp()

x = now_per._get_child_details('dat_TMS_powerA')
x = x.astype(np.float)
y = now_per._get_child_features('MEP_aaa')
#parms,parms_err = now_per.model_erp(model_type='threshold')
#y=y>now_per.erp_detection_limit
#y=y.astype(int)
x_est = np.arange(min(x),max(x),(max(x)-min(x))/100)
y_est = my_sigmoid(x_est,*list(parms))
pylab.plot(x, y, 'o', label='data')
pylab.plot(x_est,y_est, label='fit')
legend(loc='upper left')
```

### Creating data

Creating a trial requires the presence of its parent period (above). Any new trials created during the
time defined by this period will inherit the period's details by default.
When creating a new trial, the SQL database has triggers to create the trial's
default details (from the period) and feature values (usually NULL by default), 
but these triggers only fire when the trial is persisted. Thus we use the API's >get_or_create method. 
To be sure the >get_or_create method does not match any existing trials, 
we have to provide it with a unique key that definitely does not exist, i.e. with Number=0.

```python
#This does not persist the trial immediately, and therefore does not create detail and feature entries until after a flush.
new_trial = Datum(subject=my_subject, datum_type=my_dat_type, span_type='trial', IsGood=1)

#This creates a new trial and persists immediately, generating its default details and features.
my_trial = get_or_create(Datum\
	, subject=my_subject\
	, datum_type=my_dat_type\
	, span_type='trial'\
	, IsGood=1\
	, Number=0)

#Or we can load an old trial with the following
my_trial = my_subject.data[-1]
```

We can then store some data in the trial. Storing data will typically kick off feature calculation for the datum.

```python
my_trial.store={\
	'x_vec':numpy.arange(-500,500, dtype=float)\
	, 'data':numpy.array(100*numpy.random.ranf((2,1000)), dtype=float)\
	, 'channel_labels':'Trig, EDC'}
print(my_trial.feature_values)
```

Further [online analysis apps](https://github.com/cboulay/EERAT/tree/master/python_apps/online_analysis) 
are needed for more complicated features and for getting features specific to our period object.