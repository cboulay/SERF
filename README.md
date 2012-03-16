# Evoked Electrophysiological Response Analysis Toolbox (EERAT)

## Table of Contents

1. Introduction
2. [SQL Database](https://github.com/cboulay/EERAT/tree/master/datastore)
3. [Python data API](https://github.com/cboulay/EERAT/tree/master/python-api)
4. [Python apps](https://github.com/cboulay/EERAT/tree/master/python-apps)
5. Matlab data API
6. Matlab analysis apps

## Introduction

Included in this repo are some tools to help with analysis of evoked electrophysiological responses, such as EEG SEPs, EMG H-reflexes, or TMS-evoked EMG MEPs. If you do not know what any of these things are then you probably do not need this software.

At the heart of these tools is a custom relational model (or, if you prefer, 'database structure'). This model allows for storing raw electrophysiological responses but it also stores metadata to facilitate online automatic data analysis. Thus data can be entered into the database by experimental software and analyzed in real-time and the experiment can adapt to complicated features of the responses. Let's be clear about something: **Do not use these tools to store your raw data!** [The data model imposes heavy structural constraints to make sure the data are structured properly and it uses indexing to help speed up analysis. These features cost disc space.]

To facilitate interacting with the data I have also provided two separate APIs: one for Python and one for MATLAB. The APIs expose the stored data as class instances. The contents of the class instances are retrieved from the database and modifications to the class instances are immediately stored in the database. Some features of the data are calculated automatically upon data entry. Users are thus able to interact with the data directly in MATLAB or Python without knowing anything about SQL.

Finally I have provided some applications. Each app is designed to exist as an independent module but some modules may interact. These apps range in functionality from outputting simple reports on each subject to an experiment which operantly conditions evoked response sizes.