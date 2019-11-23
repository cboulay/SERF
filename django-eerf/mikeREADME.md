# Introduction
This folder contains the framework for the real-time data retrieval in our experiments using MySQL (database). The schema is imported from Chad's old repo and we will be adopting it to change it for our use case.

# Quick Setup
Copy `eerfapp` and `eerfhelper` folders into your python environment's `site-packages` folder.

Then follow the [instructions below after the fixes](#setting-up-django-and-mysql).

The fixes below are if you install the dist, and contains instructions on how to do a successful migration.

# Sample Instructions

These instructions are more of a record-keeping tool than a tutorial
* Setup conda environment
  * `conda create -n sql python=3.6 django numpy scipy pyqt qtpy pyqtgraph`
  * `conda activate sql`
* Find an empty directory and clone Chad's EERF repository
        `git clone https://github.com/mikkeyboi/eerf`
  * Navigate to `EERF/django-eerf` and install the dist
    * pip install `pip install dist/django-eerfapp-0.8.tar.gz`
    
There will be a lot of errors since this used an old version of django and python. Apply the following fixes
  * Fixes:
    * `/site-packages/eerfhelper/feature_functions.py` linum 74 print statement
    * `/site-packages/eerfapp/models.py` 
      * Erase `__metaclass__ = models.SubfieldBase` on the following classes:
        * `NPArrayBlobField` linum 33, and change class declaration to use `models.BinaryField`
        * `CSVStringField` linum 62
      * Declare on_delete argument for `ForeignKey` on the following classes:
        * `SubjectDetailValue` linum 182 `detail_type = models.ForeignKey(DetailType, on_delete=models.CASCADE`
        * `Datum` linum 194 `subject = models.ForeignKey(Subject, on_delete=models.CASCADE, related_name="data")`
        * `DatumFeatureType` linum 296 `feature_type = models.ForeignKey(FeatureType, on_delete=models.CASCADE)`
        * `DatumDetailValue` linum 331 `detail_type = models.ForeignKey(DetailType, on_delete=models.CASCADE)`
    * `/site-packages/eerfapp/urls.py`
      * Remove `patterns` from the `django.conf.urls` imports
      * Change `urlpatterns` parentheses into a list, with `[]`
        
### Setting up django and MySQL      
  * Navigate back and create a new django project
    * `django-admin startproject expdb`
  * Include the eerfapp URL conf in your project's urls.py
    * Add this to your import statements `from django.conf.urls import url, include`
      * `url(r'^eerfapp/', include(('eerfapp.urls','eerfapp'), namespace="eerfapp")),`
  * Open `settings.py` and change ENGINE to `django.db.backends.mysql`, and NAME to `expdb` rather than sqlite3
  * [Create a MySQL OPTIONS file](https://docs.djangoproject.com/en/2.2/ref/databases/#connecting-to-the-database) and assign an username and password
    * Name your database `expdb` 
  * Before continuing, ensure MySQL is setup properly (ie: `pip install mysqlclient`)
    * Linux and Mac requires MySQL development headers and libraries.
      * Ubuntu: `sudo apt-get install python-dev default-libmysqlclient-dev`
      * Arch: via [AUR](https://aur.archlinux.org/packages/libmysqlclient/), makepkg
    * On Windows, there are binary wheels you can install without MySQLConnector/C or MSVC
  * Windows: Install MySQL Server, Workbench, and Shell
    * Go through installation instructions and use the same names as you did when you set up the MySQL OPTIONS
    * In Workbench, make a new schema called `expdb`
  * Make sure you are in the same directory as `manage.py`, and run `python manage.py makemigrations eerfapp`
  * You should see the following output:
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

  * Run `python manage.py migrate`, and it should `Applying eerfapp.0001_initial... OK`
  * Create a superuser for administrative control on the django side `python manage.py createsuperuser`
  * Test your server `python manage.py runserver` and go to `localhost:8000/admin`
  
 

    
