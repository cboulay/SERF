=====
EERFAPP
=====

eerfapp is a Django app. The core of the app is its database. The database schema is designed to provide a complete and flexible representation of epoched neurophysiological data.

![Database Schema](/models.png?raw=true "Database Schema")

# Setup Instructions
Before proceeding, consult our guide for [Installing Python and Django and Databases](https://github.com/cboulay/EERF/blob/master/INSTALL.md).
Ensure that you have already run `python setup.py install` in the `eerf/django-eerf`.
  - From `eerf/django-eerf/build/lib`, copy `eerfapp` and `eerfhelper` folders into your python environment's `site-packages` folder.

## Installing the Django EERF Web Application     
1. Navigate inside your expdb project
  - If you haven't created it already, `django-admin startproject expdb`
1. Include the eerfapp URL configurations in your project's `urls.py`:
  - Add this to your import statements `from django.conf.urls import url, include`
  - Add the following under `urlpatterns` list:
    - `url(r'^eerfapp/', include(('eerfapp.urls','eerfapp'), namespace="eerfapp")),`
1. Open `settings.py` and apply the following changes:
  - Under `INSTALLED_APPS` add `eerfapp,` to the list
  - Double check that you have these changes under `DATABASES`:
    - `'ENGINE': 'django.db.backends.mysql'`
    - `'NAME': 'expdb'`
    - Credentials defined here must be correct
      - [Create a MySQL OPTIONS file](https://docs.djangoproject.com/en/2.2/ref/databases/#connecting-to-the-database) and assign an username and password

1. Activate your conda environment (e.g. environment name sql)
   - Linux/Mac: `source ~/miniconda3/bin/activate && conda activate sql`
   - Windows: Open Anaconda Prompt and type `conda activate sql`
1. Run `python manage.py makemigrations eerfapp` in your expdb project
1. You should see the following output:
 ```
Migrations for 'eerfapp':
  /Users/mikkeyboi/miniconda3/envs/sql/lib/python3.6/site-packages/eerfapp/migrations/0001_initial.py
    - Create model Datum
    - Create model DatumFeatureValue
    - Create model DetailType
    - Create model FeatureType
    - Create model Subject
    - Create model System
    - Create model DatumFeatureStore
    - Create model DatumStore
    - Create model SubjectLog
    - Add field feature_type to datumfeaturevalue
    - Add field subject to datum
    - Add field trials to datum
    - Create model SubjectDetailValue
    - Alter unique_together for datumfeaturevalue (1 constraint(s))
    - Create model DatumDetailValue
    - Alter unique_together for datum (1 constraint(s))

 ```

1. Run `python manage.py migrate`, and it should `Applying eerfapp.0001_initial... OK`
1. Create a superuser for administrative control on the django side `python manage.py createsuperuser`
   - Take note of these credentials. The username will default as your account name
1. Test your server `python manage.py runserver` and go to `localhost:8000/admin`


## Developing in Django
Django has a [good tutorial](https://docs.djangoproject.com/en/3.0/intro/tutorial01/) to familiarize you with the structure of the project you just built.
To send commands to your server, run `python manage.py shell` in your expdb project. [Here are some commands you can try](https://docs.djangoproject.com/en/3.0/intro/tutorial02/#playing-with-the-api).
Running commands like this in REPL may not be ideal for development. If you wish to run scripts that call and write to the database, you have to include the following in the script you wish to run:
 ``` python
from django.core.management import execute_from_command_line
os.environ['DJANGO_SETTINGS_MODULE'] = 'expdb.settings'
execute_from_command_line()
 ```
Below is an example where I pass some multidimensional random data into the server, retrieve it, and compare the their values (sent as a blob, retrieved in bytes).

``` python
import os
import pdb
import numpy as np
from django.core.management import execute_from_command_line
os.environ['DJANGO_SETTINGS_MODULE'] = 'expdb.settings'
execute_from_command_line()
from eerfapp.models import *

# Retrieve sample subject created with django admin
subj1 = Subject.objects.all()[0]
# Create if Datum doesn't exist
if len(Datum.objects.all()) == 0:
    data1 = Datum(datum_id=1, subject=subj1, number=1)
    data1.span_type = 'trial'
    data1.save()
# Retrieve sample Datum
data1 = Datum.objects.filter(subject=subj1)[0]
# Create Sample data
ch_names = ['Cz', 'FCz', 'FP1', 'FP2', 'OZ']
samples = [np.random.rand(512) for x in np.arange(0, len(ch_names))]
orig = np.swapaxes(samples, 0, 0)
# Create entry if doesn't exist
if len(DatumStore.objects.all()) == 0:
    data_pkt = DatumStore(datum=data1)
else:
    data_pkt = DatumStore.objects.all()[0]
# Modify entry and save
data_pkt.set_data(orig)
data_pkt.save()
# Retrieve sample DatumStore
data_pkt = DatumStore.objects.filter(datum=data1)[0]
# Compare orig between local and server
print("Notice that retrieved data is in bytes.", np.frombuffer(data_pkt.erp).shape)
# Reshape it to stored sample
retrieved_data = np.frombuffer(data_pkt.erp).reshape(orig.shape)
# Compare if retrieved data is the same as generated data
print("The retrieved data and sent data are equal: ", np.array_equal(retrieved_data, orig))
print("The dtypes are equal: ", retrieved_data.dtype == orig.dtype)
print("The nbytes are equal: ", retrieved_data.nbytes == orig.nbytes)
```


## Troubleshooting

  * `FileNotFoundError: [WinError 3] The system cannot find the path specified...` or `URL pattern for eerfapp.views is invalid`
    * For both these types of errors, ensure you have eerfapp and eerfhelper folders in your site-packages.
      * You can get these folders by running `python setup.py install` in `eerf/django-eerf` and navigating to `.../build/lib`
  * `caching_sha2_password cannot be loaded`
    * You may need to manually modify your password using this command:
      * ALTER USER 'youruser'@'localhost' IDENTIFIED WITH mysql_native_password BY 'yourpassword';
  * Ensure MySQL is setup properly (ie: `pip install mysqlclient`)
    * Linux and Mac requires MySQL development headers and libraries.
      * Ubuntu: `sudo apt-get install python-dev default-libmysqlclient-dev`
      * Arch: via [AUR](https://aur.archlinux.org/packages/libmysqlclient/), makepkg
    * On Windows, there are binary wheels you can install without MySQLConnector/C or MSVC

If you get an error about missing sqlparse then you can either install it (`pip install sqlparse`) or turn off debugging in settings.py.


FOR CHAD
-------

Development cycle, in django-eerfapp directory.

1. `pip uninstall django-eerfapp` uninstalls what might already be there.
3. `pip install -e .` installs new dist.

If models.py changed then you should recreate the migrations.

1. `python ~/Documents/Django\ Projects/expdb/manage.py makemigrations eerfapp`

TODO
----

Change the static\*.js to use relative paths.
