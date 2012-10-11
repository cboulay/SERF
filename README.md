# Evoked Electrophysiological Response Feedback (EERF)

## Table of Contents

1. Introduction
2. [Python Django ORM and web app and helper package](https://github.com/cboulay/EERF/tree/master/python)
3. [Matlab ORM](https://github.com/cboulay/EERF/tree/master/matlab)

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