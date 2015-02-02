## Prepare your system

Note: If you already have a working Django installation, you can skip ahead to "EERFAPP" below.

### Installing Python and Django and Databases

The most important parts of these tools are the database and its interfaces. The database schema is installed and configured using [Django](https://www.djangoproject.com/download/), a [Python](https://www.python.org/)-based web framework.

To get up and running, we need a database server, Python, Django, the python-database connector, Python's scientific packages, and some other Python packages. Platform-specific instructions are below.

#### On OS X

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
    `export LANG=en_US.UTF-8`
    `export LC_ALL=en_US.UTF-8`
    The first two lines are to make sure mysql-python works. The next two are to make sure spyder works.
13. `source ~/.profile` or you may have to close and reopen terminal.
14. `pip install mysql-python`
15. Optional: `pip install spyder`  This is my preferred IDE for Python.

#### On Windows

TODO

### Configuring the database server and Django

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
