function feature_value=get_sep_p1(data)
%function feature_value=get_sep_p1(data)
%argument data is an array or instance of Trial, Day, or Period object(s).
%This function calculates the average amplitude of the ECoG in the
%p1 period and subtracts from it the average amplitude in the
%baseline ECoG period.
frag_ids=[2 3]; %Only need the first fragment.
ani=E3.Subject;
ani.DB_id=data(1).subject_id;
ads=ani.SubjectDetails;
ad_names={ads.Name};
be_id=str2double(ads(strcmpi(ad_names,'best_ecog_channel_id')).Value);
base_start=str2double(ads(strcmpi(ad_names,'sep_base_start_ms')).Value);
base_stop=str2double(ads(strcmpi(ad_names,'sep_base_stop_ms')).Value);
p1_start=str2double(ads(strcmpi(ad_names,'sep_p1_start_ms')).Value);
p1_stop=str2double(ads(strcmpi(ad_names,'sep_p1_stop_ms')).Value);
base_values=get_td_feature(data,frag_ids,[base_start base_stop],be_id,false);
sep_values=get_td_feature(data,frag_ids,[p1_start p1_stop],be_id,false);
feature_value=sep_values-base_values;