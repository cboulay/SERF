=====
EERFAPP
=====

eerfapp is a Django app. The core of the app is its database. The database schema is designed to provide a complete and flexible representation of epoched neurophysiological data.

![Database Schema](/models.png?raw=true "Database Schema")

TODO: Detailed documentation in the "docs" directory.

Quick start
-----------

1. Add "eerfapp" to your INSTALLED_APPS setting like this::

    INSTALLED_APPS = (
        ...
        'eerfapp',
    )

2. Include the eerfapp URLconf in your project urls.py like this::

    url(r'^eerfapp/', include('eerfapp.urls')),

3. Run `python manage.py migrate` to create the eerfapp models.

4. Start the development server and visit http://127.0.0.1:8000/admin/
   to ...(you'll need the Admin app enabled).

5. Visit http://127.0.0.1:8000/eerfapp/ to...
