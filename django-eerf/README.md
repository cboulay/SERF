=====
EERFAPP
=====

eerfapp is a Django app. The core of the app is its database. The database schema is designed to provide a complete and flexible representation of epoched neurophysiological data.

![Database Schema](/models.png?raw=true "Database Schema")

TODO: Detailed documentation in the "docs" directory.

Quick start
-----------

1. In the django-eerf folder, run `pip install dist/django-eerfapp-0.8.tar.gz`

2. Add "eerfapp" to your INSTALLED_APPS setting in your Django project settings.py like this::

    INSTALLED_APPS = (
        ...
        'eerfapp',
    )

3. Include the eerfapp URLconf in your project's urls.py:
    Modify the import statement so it reads `from django.conf.urls import url, include`
    Add the following to the urlpatterns list:
    `url(r'^eerfapp/', include('eerfapp.urls', namespace="eerfapp")),`

4. Make sure the database server is running. `mysql.server start` or `mysqld_safe &`

5. Run `python manage.py migrate` to create the eerfapp models.
    This gave me a few warnings about deprecations. Copied here for now:
    ```
/usr/local/lib/python2.7/site-packages/eerfapp/models.py:33: RemovedInDjango110Warning: SubfieldBase has been deprecated. Use Field.from_db_value instead.
  class NPArrayBlobField(models.Field):

/usr/local/lib/python2.7/site-packages/eerfapp/models.py:61: RemovedInDjango110Warning: SubfieldBase has been deprecated. Use Field.from_db_value instead.
  class CSVStringField(models.TextField):

/usr/local/lib/python2.7/site-packages/eerfapp/urls.py:77: RemovedInDjango110Warning: django.conf.urls.patterns() is deprecated and will be removed in Django 1.10. Update your urlpatterns to be a list of django.conf.urls.url() instances instead.
  url(r'^import_elizan/$', views.import_elizan, name='import_elizan'),
    ```

6. Start the development server (`python manage.py runserver`) and visit `http://127.0.0.1:8000/admin/` to test that it is working (you'll need the Admin app enabled).

7. Visit `http://127.0.0.1:8000/eerfapp/` to use the web app.

If you get an error about missing sqlparse then you can either install it (`pip install sqlparse`) or turn off debugging in settings.py.

FOR CHAD
-------

Development cycle, in django-eerfapp directory.

1. `python setup.py sdist` to recreate dist.
2. `pip uninstall django-eerfapp` uninstalls what might already be there.
3. `pip install dist/django-eerfapp-0.8.tar.gz` installs new dist.

If models.py changed then you should recreate the migrations.

1. `rm /usr/local/lib/python2.7/site-packages/eerfapp/migrations/*`
2. `python ~/Documents/Django\ Projects/mysite/manage.py makemigrations eerfapp`
3. `cp /usr/local/lib/python2.7/site-packages/eerfapp/migrations/*.py eerfapp/migrations/`
4. `python setup.py sdist` to recreate dist.


TODO
----

Change the static\*.js to use relative paths.