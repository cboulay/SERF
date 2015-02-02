=====
EERFAPP
=====

eerfapp is a Django app. The core of the app is its database. The database schema is designed to provide a complete and flexible representation of epoched neurophysiological data.

![Database Schema](/models.png?raw=true "Database Schema")

TODO: Detailed documentation in the "docs" directory.

Quick start
-----------

1. Add "eerfapp" to your INSTALLED_APPS setting in your Django project settings.py like this::

    INSTALLED_APPS = (
        ...
        'eerfapp',
    )

2. Include the eerfapp URLconf in your project urls.py like this::

    url(r'^eerfapp/', include('eerfapp.urls')),

3. In the django-eerf folder, run `python setup.py install`

4. Skip this step because I have done it for you: `python manage.py makemigrations eerfapp`

5. Run `python manage.py migrate` to create the eerfapp models.

6. Start the development server (`python manage.py runserver`) and visit `http://127.0.0.1:8000/admin/` to test that it is working (you'll need the Admin app enabled).

7. Visit `http://127.0.0.1:8000/eerfapp/` to use the web app.

If you get an error about missing sqlparse then you can either install it (`pip install sqlparse`) or turn off debugging in settings.py.

TODO
----

Change the static\*.js to use relative paths.