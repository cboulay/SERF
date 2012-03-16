# Evoked Electrophysiological Response Analysis Toolbox (EERAT)

## Table of Contents

1. [Introduction](#intro)
2. [SQL Database](#sql-db)
3. [Python data API](#python-api)
4. [Python analysis apps](#python-apps)
5. Matlab data API
6. Matlab analysis apps

## Introduction ##         {#intro}

Included in this repo are some tools to help with analysis of evoked electrophysiological responses, such as EEG SEPs, EMG H-reflexes, or TMS-evoked EMG MEPs. If you do not know what any of these things are then you probably do not need this software.

At the heart of these tools is a custom relational model (or, if you prefer, 'database structure'). This model allows for storing raw electrophysiological responses but it also stores metadata to facilitate online automatic data analysis. Thus data can be entered into the database by experimental software and analyzed in real-time and the experiment can adapt to complicated features of the responses. Let's be clear about something: **Do not use these tools to store your raw data!** [The data model imposes heavy structural constraints to make sure the data are structured properly and it uses indexing to help speed up analysis. These features cost disc space. One trial with 1 second of 24kHz data from 32 channels would require about 10MB of storage in this database, whereas it would require only 2.3MB in a simple 24-bit INT array.] You should only store as much data as you need to calculate the features that you need (e.g., only need 1 channel (downsample) over a shorter segment to calculate ERP amplitude).

To facilitate interacting with the data I have also provided two separate APIs: one for Python and one for MATLAB. The APIs expose the stored data as class instances. The contents of the class instances are retrieved from the database and modifications to the class instances are immediately stored in the database. Some features of the data are calculated automatically by the database upon data entry. Users are thus able to interact with the data directly in MATLAB or Python without knowing anything about SQL.

Finally I have provided some applications. Each app is designed to exist as an independent module but some modules may interact. These apps range in functionality from outputting simple reports on each subject to an experiment which operantly conditions evoked response sizes.

## SQL Database##(#sql-db)

### Installing your SQL server

I hope that the database structure will work in several SQL servers but I have only tested it in MySQL (version > 5.5). I use MySQL because one of my uses for these tools is to analyze legacy data from ELIZANIII [TODO: link?] and the ELIZANIII data structure requires MySQL.

TODO: Download MySQL [TODO: link?], install MySQL, configure MySQL, test MySQL

### Creating the EERAT relational model for the first time

Run the following at a command prompt.
>mysql -uroot < eerat_v1.sql
>mysql -uroot eerat < eerat_data.sql
The first line inserts the schema, triggers, and stored procedures. The second inserts some default data.

### Modifying the EERAT relation model (includes updating to newer versions)

Everytime the API is instantiated it checks the version of the database against the API's expected version number. If the version numbers do not match, the API attempts to upgrade the database (without destroying any data) using the upgrade path defined by the .sql files.

The relational model was designed using MySQL Workbench. The model diagram is available in /SQL_database/EERAT_model.mwb . This file provides a representation of the data structure. You may modify the data structure to your liking but this will probably break the API and any future upgrades.

## Python data API(#python-api)

*** Installing Python and the API's dependencies

TODO: Instructions for installing Python

SQLAlchemy
http://www.sqlalchemy.org/download.html

*** Interacting with the data

Initializing an API instance will populate the instance with top-level data objects including [TODO:].
TODO: Code sample for importing the API, instantiating, and viewing some top-level data.

Data can be explored by accessing the methods and attributes of each object. Some attributes are themselves data objects with further methods and attributes.
TODO: Code sample for exploring data.

*** Objects, their methods, and their attributes

**** Experiment

**** Subject

**** Period, Day, Trial

**** Data types and other structural elements

## Python Analysis Apps(#python-apps)