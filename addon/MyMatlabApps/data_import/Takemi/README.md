This is used to import data from Takemi's ERD/MEP experiment.

1. Edit get_subject_info.m to make sure it matches the subject details.

2. Run
>> tools_paths

3. Run
>> prepare_database
Note: This only needs to be done once.

4. Run
>> do_import.m
This will import the data from the .mat and .csv files and store them in the database.

In the future, data may be accessed as follows.
>> import EERAT.*
>> dbx=EERAT.Dbmym('eerat');
>> experiment = EERAT.Experiment(dbx,'Name','TakemiERDMEP');

Then data can be accessed.
>> my_subject = experiment.subjects(ss);
>> periods = my_subject.periods;
>> my_trials = periods(1).trials;
>> trial = my_trials(tt);
Plot a trial
>> plot(trial.xvec,trial.erp), legend(trial.channel_labels)

If you want to calculate a trial's adaptively normalized power, then a 
separate script is needed to step through the trials to create the buffer
for each trial. This buffer is not stored so this script will be needed
every time.
>> trials = experiment.subjects(ss).periods(pp).trials;
>> fill_buffer(trials);