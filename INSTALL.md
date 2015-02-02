## Installing Python and Django and Databases

The most important parts of these tools are the database and its interfaces. The database schema is installed and configured using [Django](https://www.djangoproject.com/download/), a [Python](https://www.python.org/)-based web framework.

To get up and running, we need a database server, Python, Django, the python-database connector, Python's scientific packages, and some other Python packages. Platform-specific instructions are below.

### On OS X

1. Install [homebrew](http://brew.sh/).
2. `brew install python`
3. `pip install numpy`
4. `brew install gcc`
5. `pip install scipy`
6. `brew install freetype`
7. `pip install matplotlib`
8. `pip install ipython[all]`
9. `brew install pyqt`
10. `pip install django`
11. `brew install mysql`
12. Edit ~/.profile and add the following lines.
    `export PATH=/usr/local/mysql/bin:$PATH`
    `export PATH=/usr/local/mysql/lib:$PATH`
13. `source ~/.profile` or you may have to close and reopen terminal.
14. `pip install mysql-python`

### On Windows

TODO

## Configuring the database server and Django

Though any DBMS should work, I use MySQL because some of the data I work with were originally recorded into MySQL. I use the MyISAM storage engine because I had trouble getting good performance out of InnoDB when working with these old data. If you followed the instructions above then mysql and its python connector should already be installed.
Many of the instructions are from the [Django tutorial](https://docs.djangoproject.com/en/dev/intro/tutorial01/):

1. Configure the database server.
    1. Create the directory where your mysql data will reside. I used `mkdir /Volumes/STORE/eerfdata`
    2. `mysql_install_db --verbose --user=root --basedir="$(brew --prefix mysql)" --datadir=/Volumes/STORE/eerfdata --tmpdir=/tmp`
    3. Specify the data directory in my.cnf . You may choose to edit and use the one from this repo then place it in your /etc/my.cnf
    4. Run the server `mysqld_safe &`
2. Create a Django project. From ~/Documents/Django\ Projects/ `django-admin startproject mysite`
3. Configure the Django project.
    1. Edit mysite/settings.py to point to the database. `’ENGINE’: ‘django.db.backends.mysql’, ’NAME’: ‘mysite’, ’USER’: ‘root’, ‘HOST’: ’127.0.0.1’, ‘PORT’: ‘3306’`
    2. Create the Django project database.
        - `mysql -uroot`
        - `create database mysite character set utf8;`
        - `exit;`
4. Install the base Django tables. From ~/Documents/Django\ Projects/mysite/ `python manage.py migrate`
5. Test Django
    - `python manage.py runserver`
    - Navigate to `http://127.0.0.1:8000/`

You are now ready to install the Django [eerf web application](django-eerf/README.md).

## Additional Tips for installing MySQL

You may need to `chown -R mysql:wheel datadir` and `chmod -R 755 datadir`
Create a defaults file (usually /etc/my.cnf) with all of your settings. You can use the provided my.cnf to start.
Run `sudo mysql_install_db --user=mysql --defaults-file=/etc/my.cnf`
Run `mysqld_safe & --defaults-file=/etc/my.cnf`
It is not necessary to specify the defaults file when using the default location (/etc/my.cnf).

Consider adding the following to my.cnf
```
default-storage-engine = MyISAM
query_cache_type = 1
key_buffer_size = 2G
query_cache_limit = 400M
```

## Install Spyder, my preferred Python IDE

1. Edit ~/.profile and add the following lines::
    
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

2. `pip install spyder`

3. Create a dock icon
    
```
mkdir /Applications/Spyder.app
mkdir /Applications/Spyder.app/Contents`
mkdir /Applications/Spyder.app/Contents/MacOS
mkdir /Applications/Spyder.app/Contents/Resources
touch /Applications/Spyder.app/Contents/MacOS/spyder
chmod +xxx /Applications/Spyder.app/Contents/MacOS/spyder
curl -o /Applications/Spyder.app/Contents/Resources/spyder.icns https://spyderlib.googlecode.com/hg/img_src/spyder.icns
touch /Applications/Spyder.app/Contents/Info.plist
```    

Copy the following into /Applications/Spyder.app/Contents/Info.plist:

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"> 
<plist version="1.0"> 
    <dict> 
        <key>CFBundleIconFile</key> 
        <string>spyder</string> 
    </dict> 
</plist> 
```

Copy the following into /Applications/Spyder.app/Contents/MacOS/spyder

```
#! /usr/local/bin/python

import os
import subprocess

envstr = subprocess.check_output('source /etc/profile; source ~/.profile; printenv', shell=True)
env = [a.split('=') for a in envstr.strip().split('\n')]
os.environ.update(env)

executable = '/usr/local/bin/spyder'
arguments = [executable]

os.execve(executable, arguments, os.environ)
```