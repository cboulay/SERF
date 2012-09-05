import EERAT.* %Database object interfaces.
if ~exist('dbx','var')
    dbx=EERAT.Dbmym('eerat'); %Open a connection to the database.
end

import Takemi.* %Some classes to help load the data.

experiment = EERAT.Experiment(dbx,'Name','Takemi_MI_TMS','Description','Takemi applying TMS during motor imagery');%Get or create an experiment to group the subjects.
sub_type = EERAT.SubjectType(dbx,'Name','ghi_healthy');%Get (or create) the subject type
dat_type = EERAT.DatumType(dbx,'Name','Takemi_MI_mep');%Get (or create) the datum type.

get_subject_info;%subject_info stored in a separate file.

for ss=1:length(subjects_info)%For each subject
    tic
    si=subjects_info(ss);
    
    %Get or create the subject. Subjects and data are special in that they
    %require their type to be passed in as an argument at creation time.
    sub=EERAT.Subject(dbx,'Name',['TAKEMI_',si.name],'subject_type_id',sub_type.subject_type_id);
    sub.experiments=experiment;%Add this subject to our experiment.
    
    tksub = Takemi.Subject(si);%Create a Takemi.Subject out of this si.
    tksub.load_data;%Load the data into tksub.trials
    
    %Create a period that encompasses all of the trials.
    this_period = EERAT.Period(dbx, 'subject_id', sub.subject_id, ...
        'datum_type_id', dat_type.datum_type_id, 'span_type', 'period');
    tktrialtimes = sort(datenum({tksub.trials.datetime}));%tksub.trials aren't in chronological order.
    this_period.StartTime = datestr(tktrialtimes(1));
    this_period.EndTime = datestr(tktrialtimes(end));
    
    %trial details and trial features can be added one by one,
    %or by batch (faster and more secure)
    %init the variables for batch add here.
    n_trials = length(tksub.trials);
%     my_mep = NaN(n_trials,1);
    my_bgstart = NaN(n_trials,1);
    my_bgstop = NaN(n_trials,1);
    my_prestimstart = NaN(n_trials,1);
    my_prestimstop = NaN(n_trials,1);
%     my_tms_isi = NaN(n_trials,1);
    for tt=1:n_trials%Step through the trials, entering them into the database.
        tktrial = tksub.trials(tt);
        
        trial=EERAT.Trial(dbx, 'new', true, 'subject_id', sub.subject_id,...
            'datum_type_id', dat_type.datum_type_id,...
            'span_type', 'trial', 'IsGood', true);
        trial.periods=this_period;
        x_vec = tktrial.t_vec_task';
        trial.StartTime = tktrial.datetime;
        trial.EndTime = datestr(datenum(tktrial.datetime) + (x_vec(end) - x_vec(1))/(60*60*24));
        trial.erp = tktrial.raw_data';
        trial.channel_labels = {'C3'};
        trial.xvec = x_vec;
        
%         my_mep(tt) = tktrial.mep;
        %TODO: Set windows.
        x_task = tktrial.t_vec_task';
        task_bool = x_task >= tktrial.baseline_window(1) & x_task < tktrial.baseline_window(2);
        task_times = x_vec(task_bool);
        my_bgstart(tt) = 1000*task_times(1);
        my_bgstop(tt) = 1000*task_times(end);
        x_stim = tktrial.t_vec_stim';
        stim_bool = x_stim >= tktrial.test_window(1) & x_stim < tktrial.test_window(2);
        stim_times = x_vec(stim_bool);
        my_prestimstart(tt) = 1000*stim_times(1);
        my_prestimstop(tt) = 1000*stim_times(end);
    end
    my_mep = [tksub.trials.mep]';
    this_period.set_trials_features({'MEP_p2p'},my_mep);
    
    my_task_cond = ~strcmpi({tksub.trials.task_level},'RC')';
    my_isi = [tksub.trials.isi]';% my_isi(isnan(my_isi))=-1;
    this_period.set_trials_details({'dat_BG_start_ms' 'dat_BG_stop_ms' 'dat_prestim_start_ms' 'dat_prestim_stop_ms' 'dat_task_condition' 'dat_TMS_ISI'},...
        [my_bgstart my_bgstop my_prestimstart my_prestimstop my_task_cond my_isi]);
    toc
end