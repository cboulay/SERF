tools_paths; %Script to set the paths.
import EERAT.* %Object interfaces.
dbx=EERAT.Dbmym('eerat'); %Open a connection to the database.
subjects=EERAT.Db_obj.get_obj_array(dbx,'Subject'); %Get all subjects;
ss=subjects(3);%Pick a subject.
pp=ss.periods(end);%Pick a period.
tt=pp.trials(1);%Pick a trial.
plot(tt.xvec,tt.erp),legend(tt.channel_labels) %Plot the trial.
meps=pp.get_trials_features('MEP_p2p'); %Get all meps from the period.
powerA=pp.get_trials_details('dat_TMS_powerA'); %Get TMS intensity for the period.
powerA=str2double(powerA);