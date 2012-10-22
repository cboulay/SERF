This is out of date. I'm working on a new API that uses the new schema and ORM.

--------------------------------
This is the API for accessing the EERAT database in MATLAB.
Try it as follows (see test.m):
>>tools_paths; %Script to set the paths.
>>import EERAT.* %Object interfaces.
>>dbx=EERAT.Dbmym('eerat'); %Open a connection to the database.
>>subjects=EERAT.Db_obj.get_obj_array(dbx,'Subject'); %Get all subjects;
>>ss=subjects(3);%Pick a subject.
>>pp=ss.periods(end);%Pick a period.
>>tt=pp.trials(1);%Pick a trial.
>>plot(tt.xvec,tt.erp),legend(tt.channel_labels) %Plot the trial.
>>meps=pp.get_trials_features('MEP_p2p'); %Get all meps from the period.
>>powerA=pp.get_trials_details('dat_TMS_powerA'); %Get TMS intensity for the period.
>>powerA=str2double(powerA);

tools_paths.m assumes that you have certain tools and that these are in 
a certain location.
Edit the file to point it to the correct folders.
Alternatively, you can download all of the required tools in a zip file
in this repo and unzip it to a directory and point tools_paths there.