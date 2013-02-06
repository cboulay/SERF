# Evoked Electrophysiological Response Feedback (EERF)

- [eerf](https://github.com/cboulay/EERF/tree/master/python/eerf) is a Django project and app.
- [eerfx](https://github.com/cboulay/EERF/tree/master/python/eerfx) is a simple Python package
that contains a few helpers for EERF. It can be installed as a Python package using setup.py
found in this directory. eerfx also contains feature_functions.py which is a list of functions for calculating features from raw ERP waveforms.
- scratch.py is a file I use for quick debugging of test code. You can ignore it.
- standalone.py has some examples for using the Django ORM outside of a Django web server environment.

### Installing Python and some dependencies

#### Before you start
If you intend on using this repo with [BCPy2000](http://bci2000.org/downloads/BCPy2000/BCPy2000.html)
and [BCPyElectrophys](https://github.com/cboulay/BCPyElectrophys) then please follow the instructions
at BCPyElectrophys first. Then return here and skip the next step on Installing Python.

### Installing Python
I use the [graphical installer](http://www.python.org/download/).
If you are using BCPy2000 then you should have already installed [this](http://www.python.org/download/releases/2.6.6/).
Add the Python folder to your PATH environment variable. It may also be convenient to add Python's Scripts subfolder to your path.

### Installing MySQL
Download [here](http://dev.mysql.com/downloads/).
Run the installer. Choose a custom install. Install Server, the Connectors, and possibly Workbench (optional).
Also make sure to set your data folder somewhere with lots of empty space.
The default options are acceptable during the MySQL setup. Make sure you write down the root password you select.

#### Testing MySQL
[MySQL Workbench](http://dev.mysql.com/downloads/workbench/) is invaluable for basic database administration.
If you decided to install it, open MySQL Workbench now. Click on the server in the Server Administration pane
at the right of the screen. In the new Admin tab that opens, click on "Server Status" on the navigation bar at the left.
In the Server Status window (which may have already been open), make sure that `Status:` is  `Running`. If not,
click on "Startup / Shutdown" on the navigation bar at the left. Then press the "Start Server" button.

If you did not install MySQL Workbench, you can test your MySQL server from the command line. Open a command prompt/shell/terminal
and change to the MySQL binaries directory (e.g. `C:\Program Files\MySQL\MySQL Server 5.5\bin>`).
Type `mysql -uroot -p<your root password>`.
(The lack of space between the option flags (-u for user) and their values is not always necessary but sometimes it is).
In the new window that opens, try entering `SHOW DATABASES;` (Semi-colon is very important).

#### Create a MySQL database called eerf
This can be done either with the Workbench (a database is also called a schema) or the command line interface.
If using the CLI, the command is `CREATE DATABASE eerf;`

#### Advanced MySQL
MySQL has many security features and optimization features. For example, it is probably not a good idea to use
the root mysql user for Django. Instead, you should create a separate mysql user that has limited read and write
access. MySQL documentation is abundant on the web.

### Installing Python packages/libraries
The easiest way to install Python packages on Windows is to find the binary installers [here](http://www.lfd.uci.edu/~gohlke/pythonlibs/).
The best way to install packages is to use pip. The best way to install pip is with setup_tools. Get [that first](http://pypi.python.org/pypi/setuptools).
After setuptools is installed, go to a command prompt (cd to C:\$PYTHON\Scripts\ if it is not already on the PATH) and run 'easy_install pip'.
Once pip is installed, almost all packages can be installed with 'pip install $packagename'

#### Django
[Django](https://docs.djangoproject.com/en/1.4/intro/install/) has extensive documentation on
how to download and install it with some links to help with MySQL installation.

#### MySQL-python
MySQL-python is mostly easy to install, but there are some tricks for OSX.
For OSX, try the code below (modify the PATH to match your installed version)

```

>sudo -i
#export PATH=$PATH:/usr/local/mysql-5.5.17-osx10.6-x86_64/bin
#export DYLD_LIBRARY_PATH=/usr/local/mysql/lib/
#export ARCHFLAGS='-arch i386 -arch x86_64'
#export CC=gcc-4.2
#export PATH="/Library/Frameworks/Python.framework/Versions/2.7/bin:${PATH}"
#easy_install mysql-python
#pip install MySQL-python==1.2.3c1

```

### Other packages
This Django project also relies on certain python packages that are also requirements of BCPy2000,
 which you may have installed already, including numpy and scipy. See the 
 [BCPyElectrophys](https://github.com/cboulay/BCPyElectrophys) repository for further information.

### Installing this project/app

Install eerfx first: Change to the EERF/python directory and execute `python setup.py install`.

Configure the Django app next.
Edit python\eerf\eerf\settings.py and set the MySQL username and password, and further down set
the [TIME_ZONE](http://www.postgresql.org/docs/8.1/static/datetime-keywords.html#DATETIME-TIMEZONE-SET-TABLE). 

Tell Django to setup the database: From a console, switch to the EERF/python/eerf and execute
`python manage.py syncdb`.
During this process, you should configure your project admin username and password.
This should setup the database for use with Django.
You may get some errors finishing with `_mysql_exceptions.ProgrammingError: (2014, "Commands out of sync; you can't run
this command now")`
but that doesn't seem to stop this from working.
[BCPyElectrophys](https://github.com/cboulay/BCPyElectrophys) should now be able to use this ORM.

### Interacting with the data...

#### ...In a web browser

In a terminal or command-prompt, change to the EERF/python/eerf directory and execute
`python manage.py runserver`.
This will start the development server and tell you the URL the server is running on.
Open a browser and navigate to the specified URL and append `/admin/` to the end of the URL.
Enter the credentials you specified in the previous step. This will provide you with basic access to the database models.
Furthermore, you can access the /eerfd/ URL to get an interactive GUI. There isn't much data to look at just yet.

#### ...In a custom Python program

To access the ORM from within a separate Python program, we have to set the proper environment variable so the program knows where to find the ORM.
Your script should start with the following commands (change the directory as needed).

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

See the Django documentation on how to work with these models or see [MyBCPyModules/ERPExtension](https://github.com/cboulay/MyBCPyModules/blob/master/ERPExtension.py)
for an example of how to work with the models.