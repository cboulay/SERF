# Segmented Electrophys Recordings and Features Database

SERF-DB is a database schema, designed to facilitate collection and analysis of segmented electrophysiological recordings and features. ![Database Schema](models.png?raw=true "Database Schema")

- In the `python` folder we provide a python package `serf` comprising a [Django](https://www.djangoproject.com/) application to administer the database and act as an object relational map (ORM), and a `tools` module to help with feature calculation and data analysis. Using this schema, and interfacing with the Django ORM, it is easy to work with the data in real-time in Python.
- The [matlab](matlab/README.md) folder contains some (very outdated) code for interfacing with the database in Matlab.
- serf.sql is some SQL to add some functionality when using non-Django API.

> Django applications are typically run in conjunction with a Django **project**, but in this case we are mostly only interested in the ORM. Therefore, we default to the standalone approach, but we do provide some untested guidance below on how to use the application with a Django webserver.

## Installation and setup

1. install serf
    * Option 1: Download the `serf` wheel from the [releases page](https://github.com/cboulay/SERF/releases) and install it with `pip install {name of wheel.whl}`.
    * Option 2: `pip install git+https://github.com/cboulay/SERF.git#subdirectory=python`
1. Install MySql.
    * See [INSTALL_MYSQL.md](./INSTALL_MYSQL.md) for how I do it (Mac / Linux / Win)
1. Make sure MySQL server is running.
    * Win: `mysqld` or `mysqld_safe --defaults-file=/etc/my.cnf &` 
    * macOS: `mysqld` or `brew services start mysql`
1. Install the serf schema
    1. Copy [my_serf.cnf](https://raw.githubusercontent.com/cboulay/SERF/master/my_serf.cnf) to where Python thinks is the home directory. The easiest way to check this is to open a command prompt in the correct python environment and run `python -c "import os; print(os.path.expanduser('~'))"`.
    1. Edit the copied file to make sure its database settings are correct. `[client]` `user` and `password` are important.
    ```
    $ serf-makemigrations
    $ serf-migrate
    ```
   You should get output like the following:
    ```
     Migrations for 'serf':
     SERF\python\serf\migrations\0001_initial.py
       - Create model Datum
       - Create model DatumFeatureValue
       - Create model DetailType
       - Create model FeatureType
       - Create model Subject
       - Create model System
       - Create model DatumFeatureStore
       - Create model DatumStore
       - Create model SubjectLog
       - Create model Procedure
       - Add field feature_type to datumfeaturevalue
       - Add field procedure to datum
       - Add field trials to datum
       - Create model SubjectDetailValue
       - Alter unique_together for datumfeaturevalue (1 constraint(s))
       - Create model DatumDetailValue
       - Alter unique_together for datum (1 constraint(s))
     ```
    `Applying serf.0001_initial... OK`

## Using SERF

* Make sure MySQL server is running.
    * Win: `mysqld` or `mysqld_safe --defaults-file=/etc/my.cnf &` 
    * macOS: `brew services start mysql`

### ...In a custom Python program

```python
import serf
serf.boot_django()
from serf.models import *
print(Subject.objects.get_or_create(name='Test')[0])
```

> [BCPyElectrophys](https://github.com/cboulay/BCPyElectrophys) would normally now be able to use this ORM, except it is out of date. I have some work to do there to get it working again.

### ...In a web browser (i.e., in a Django project)

We assume you have already created your Django project using instructions similar to [the online tutorial up until "Creating the Polls app"](https://docs.djangoproject.com/en/3.1/intro/tutorial01/#creating-a-project).

Instead of continuing the tutorial to create a new app, edit your Django project to add the pip-installed serf app.

In settings.py, make sure the database info is correct ([online documentation](https://docs.djangoproject.com/en/3.1/ref/databases/#connecting-to-the-database)) and `'serf'` is in the list of INSTALLED_APPS:
```Python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        # 'NAME': 'serf',
        # 'HOST': '127.0.0.1',
        # 'USER': 'username',
        # 'PASSWORD': 'password',
        # above options can also be defined in config file
        'OPTIONS': {'read_default_file': '/path/to/my_serf.cnf'},
    }
}

INSTALLED_APPS = [
    ...
    'serf',
]
```

Edit urls.py
```Python
from django.urls import include, path
url_patterns = [
    ...
    path('serf/', include('serf.urls')),
    #url(r'^serf/', include(('serf.urls','serf'), namespace="serf")),
]
```

Test your server: `python manage.py runserver` and go to `localhost:8000/serf`

### ...In a custom non-Python program

e.g. [Matlab](eerfmatlab/README.md)

Note that I cannot currently get non-Django interfaces to do CASCADE ON DELETE.
This is because Django creates foreign keys with a unique hash, and I cannot
use custom SQL (e.g., via migrations) to access the key name, drop it, then
add a new foreign key constraint with CASCADE ON DELETE set to on.

Thus, to delete using an API other than Django, you'll have to delete items
in order so as not to violate foreign key constraints.
For example, to delete a subject, you'll have to delete all of its data in this order:

DatumFeatureValue > DatumDetailValue > DatumStore > Datum > SubjectDetailValue > SubjectLog > Subject
