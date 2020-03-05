=====
EERFAPP
=====

eerfapp is a Django app. The core of the app is its database. The database schema is designed to provide a complete and flexible representation of epoched neurophysiological data.

![Database Schema](/models.png?raw=true "Database Schema")

# Setup Instructions
Before proceeding, consult our guide for [Installing Python and Django and Databases](https://github.com/cboulay/EERF/blob/master/INSTALL.md).
Ensure that you have already run `python setup.py install` in the `eerf/django-eerf`.
  * From `eerf/django-eerf/build/lib`, copy `eerfapp` and `eerfhelper` folders into your python environment's `site-packages` folder.

## Installing the Django EERF Web Application     
1. Navigate inside your expdb project
  * If you haven't created it already, `django-admin startproject expdb`
1. Include the eerfapp URL configurations in your project's `urls.py`:
  * Add this to your import statements `from django.conf.urls import url, include`
    * `url(r'^eerfapp/', include(('eerfapp.urls','eerfapp'), namespace="eerfapp")),`
1. Open `settings.py` and change the following:
  * Under `INSTALLED_APPS` add `eerfapp,`
  * Double check that you have these changes under `DATABASES`:
    * `'ENGINE': 'django.db.backends.mysql'`
    * `'NAME': 'expdb'`
    * Credentials defined here must be correct
      * [Create a MySQL OPTIONS file](https://docs.djangoproject.com/en/2.2/ref/databases/#connecting-to-the-database) and assign an username and password

1. Make sure you are in the same directory as `manage.py`, and run `python manage.py makemigrations eerfapp`
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
1. Test your server `python manage.py runserver` and go to `localhost:8000/admin`


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
