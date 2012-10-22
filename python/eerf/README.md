# Django project and app for Evoked Electrophysiological Response Feedback

eerf contains the project
- contains generic javascript and HTML templates
- contains project-wide settings and a pointer to the app-specific urls file

eerfd contains the app
- This is where the main webserver code lives
- templates/eerfd contains HTML for the GUI
- static/eerfd contains javascript for the GUI
- urls.py is where the browser's URL is matched to a function
- views.py is where the mached functions reside
- models.py describes the data classes

To understand the above, you should probably familiarize yourself with [Django](https://www.djangoproject.com/)
