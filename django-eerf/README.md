=====
EERFAPP
=====

eerfapp is a Django app. The core of the app is its database. The database schema is designed to provide a complete and flexible representation of epoched neurophysiological data.

![Database Schema](/models.png?raw=true "Database Schema")

TODO: Detailed documentation in the "docs" directory.

Quick start
-----------

1. In the django-eerf folder, run `pip install -e .`

2. Add "eerfapp" to your INSTALLED_APPS setting in your Django project settings.py like this::

    INSTALLED_APPS = (
        ...
        'eerfapp',
    )

3. Include the eerfapp URLconf in your project's urls.py:
    Modify the import statement so it reads `from django.conf.urls import url, include`
    Add the following to the urlpatterns list:
    `url(r'^eerfapp/', include(('eerfapp.urls','eerfapp'), namespace="eerfapp")),`

4. Make sure the database server is running. `mysql.server start` or `mysqld_safe &`

5. Run `python manage.py migrate` to create the eerfapp models.
    
6. Start the development server (`python manage.py runserver`) and visit `http://127.0.0.1:8000/admin/` to test that it is working (you'll need the Admin app enabled).

7. Visit `http://127.0.0.1:8000/eerfapp/` to use the web app.

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
