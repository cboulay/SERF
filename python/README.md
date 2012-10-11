# Evoked Electrophysiological Response Feedback (EERF)

- [eerf](https://github.com/cboulay/EERF/tree/master/python/eerf) is a Django project and app.
- [eerfx](https://github.com/cboulay/EERF/tree/master/python/eerfx) is a simple Python package
that contains a few helpers for EERF. It can be installed as a Python package using setup.py
found in this directory.
- scratch.py is a file I use for quick debugging of test code. You can ignore it.
- standalone.py has some examples for using the Django ORM outside of a Django web server environment.

### Installing Python and some Python packages

Since these packages are designed to be used with [BCPy2000](http://bci2000.org/downloads/BCPy2000/BCPy2000.html),
I will assume that you at least have read [its page](http://bci2000.org/downloads/BCPy2000/Download.html)
on how to download and install Python and some packages for use with BCPy2000. As of this writing, BCPy2000
requires an older version of IPython (0.10) which is incompatible with Python >=2.7. It also relies on
VisionEgg which is incompatible with newer versions of PyOpenGL. Work is underway to make BCPy2000
compatible with newer versions of Python and these other packages, but for now, you are probably
better off simply installing Python as described on the BCPy2000 page.

Beyond the installation listed there, this project also requires MySQL, Django and MySQL-python.
[Django](https://docs.djangoproject.com/en/1.4/intro/install/) has extensive documentation on 
how to download and install it with some links to help with MySQL installation. MySQL-python is
mostly easy to install, but there are some tricks for OSX.
For OSX, try the code below (modify the PATH to match your installed version)

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

### Installing this project/app

We need to add some useful tools for dealing with the eerf data. Change to the EERF/python directory and execute

```python
python setup.py install
```

Tell Django to setup the database. From a console, switch to the EERF/python/eerf directory and execute:

```python
python manage.py syncdb
```

This should setup the database for use with Django. You should now be able to use 
[MyBCPyModules](https://github.com/cboulay/MyBCPyModules) with this provided ORM.

### Interacting with the data

#### In a web browser

In a terminal or command-prompt, change to the EERF/python/eerf directory and execute
`python manage.py runserver`
This will tell you the URL the server is running on.
Open a browser and navigate to the specified URL and append `/admin/` to the end of the URL.
This will provide you with basic access to the database models.
Furthermore, you can access the /eerfd/ URL to get an interactive GUI. Try choosing a subject
and then viewing its data.

#### In a custom Python program

To access the ORM from within a separate Python program, we have to set the proper environment variable so the module knows where to find the ORM. 

```python
import os
sys.path.append(os.path.abspath('d:/tools/eerf/python/eerf'))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "eerf.settings")
```

Now you can import the models and test it out.

```python
from eerfd.models import Subject
my_subject = Subject.objects.get_or_create(name='Test')[0]
```

See the Django documentation on how to work with these models or see (MyBCPyModules/ERPExtension)[https://github.com/cboulay/MyBCPyModules/blob/master/ERPExtension.py] 
for an example of how to work with the models.