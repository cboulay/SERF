# Evoked Electrophysiological Response Feedback (EERF)

## Table of Contents

1. Introduction
2. Installation
3. [Python Django ORM and web app and helper package](https://github.com/cboulay/EERF/tree/master/python)
4. [Matlab ORM](https://github.com/cboulay/EERF/tree/master/matlab)

## Introduction

This repo contains a [Django](https://www.djangoproject.com/) project and app, a helper Python package,
and a Matlab ORM. These tools are designed to help with the analysis of evoked electrophysiological responses,
such as EEG SEPs, EMG H-reflexes, or TMS-evoked EMG MEPs. 

The Django project and app can be used to instantiate a database, which can then be accessed through the Django ORM.
The Django project and app can also serve a web app for interacting with the data and exporting them to a common data format (GDF).
The Matlab ORM can be used to interact with the database from the Matlab environment.

The Django ORM is used primarily by [one of my BCPy2000 modules](https://github.com/cboulay/MyBCPyModules/blob/master/ERPExtension.py).
This is one example of using the Django ORM in a standalone application. You can find other examples
[here](https://github.com/cboulay/EERF/blob/master/python/standalone.py) and [here](https://github.com/cboulay/EERF/blob/master/python/eerfx/utils/MonitorNewTrials.pyw).

## Installation

You will need to download and install [git](https://help.github.com/articles/set-up-git).
I also recommend installing a [git GUI](http://git-scm.com/downloads/guis), or at least use an IDE with git integrated.
If you installed the github GUI then you can simply click on the "Clone for X" link at the top of this page (where X is your operating system).
If you did not use the GUI, then open a shell (on Windows, start-->Git-->Git Bash.
In that window, change to a directory which will be the parent of this repository.
Copy the http (?) link at the top of this page to your clipboard.
Open the bash window again and type `git clone ` and paste the link. Then press enter.
(You may have to right click on the title bar and select "Edit->Paste").