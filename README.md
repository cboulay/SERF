# Evoked Electrophysiological Response Feedback (EERF)

## Table of Contents

1. Introduction
2. Installation
3. Use
3. [Python Django ORM and web app and helper package](https://github.com/cboulay/EERF/tree/master/python)
4. [Matlab ORM](https://github.com/cboulay/EERF/tree/master/matlab)

## Introduction

This repo comprises Matlab and Python utilities to facilitate the analysis of evoked
 electrophysiological responses in real time (i.e., as they are collected). Examples of
 evoked reponses include EEG SEPs, EMG H-reflexes, or TMS-evoked EMG MEPs.

Data are stored in a database and accessed through the provided Python or Matlab object relational models (ORM).

The Python ORM was built with [Django](https://www.djangoproject.com/). The Django ORM is also the preferred way
to instantiate the database. The Django ORM can be included in a standalone application or it can be integrated
in a web app.

Examples of using this ORM in a standalone application include
[one of my BCPy2000 modules](https://github.com/cboulay/BCPyElectrophys/blob/master/ERPExtension.py),
or a simple app [here](https://github.com/cboulay/EERF/blob/master/python/eerfx/utils/MonitorNewTrials.pyw).
A generalized standalone template is [here](https://github.com/cboulay/EERF/blob/master/python/standalone.py)

The provided Python Django project also includes a web app to interact with the data through a web browser and
to export the data to a common data format (GDF). (Data export not yet implemented).

The Matlab ORM is a set of Matlab objects to (lazily) load and stored data to the database. I don't keep the Matlab
ORM up to date because I don't use it but the basic pieces are all there so I can update it if you request it.

## Installation and Use

Clone this repo to your local harddrive. (Search for "github clone" if you don't know what that means).

See the matlab and python folders' README files for their respective installation and usage instructions.