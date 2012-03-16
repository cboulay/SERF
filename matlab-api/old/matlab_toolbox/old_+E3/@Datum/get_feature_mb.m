function power=get_feature_mb(data)
%function feature_value=get_feature_sixty(data)
%argument data is an array or instance of Trial, Day, or Period object(s).
%This function calculates the the power at 60hz for best_ecog_channel if
%available. It uses all 3 fragments. This feature is defined for all data
%classes.
ani=E3.Subject;
ani.DB_id=data(1).subject_id;
ads=ani.SubjectDetails;
be_id=str2double(ads(strcmpi({ads.Name},'best_ecog_channel_id')).Value);
model_order=25;
first_bin=17.5;
last_bin=17.5;
bin_width=25;
evals_per_bin=10;
detrend=0;
frequency=NaN;
params=[model_order, first_bin, last_bin, bin_width, evals_per_bin, detrend, frequency];
[power,freqs]=get_power(data,params,be_id); %#ok<NASGU>
%ff x cc x dd