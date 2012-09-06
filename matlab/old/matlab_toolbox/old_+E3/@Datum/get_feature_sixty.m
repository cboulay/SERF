function power=get_feature_sixty(data)
%function feature_value=get_feature_sixty(data)
%argument data is an array or instance of Trial, Day, or Period object(s).
%This function calculates the the power at 60hz for best_ecog_channel if
%available. It uses all 3 fragments. This feature is defined for all data
%classes.

%Let's make sure we have best_ecog_channel_id and that it is a good channel
%for this subject.
ani=E3.Subject;
ani.DB_id=data(1).subject_id;
ads=ani.SubjectDetails;
be_id=str2double(ads(strcmpi({ads.Name},'best_ecog_channel_id')).Value);
model_order=25;
first_bin=60;
last_bin=60;
bin_width=5;
evals_per_bin=10;
detrend=0;
frequency=NaN;
params=[model_order, first_bin, last_bin, bin_width, evals_per_bin, detrend, frequency];
[power,freqs]=get_power(data,params,be_id); %#ok<NASGU>
%ff x cc x dd