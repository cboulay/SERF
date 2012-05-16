function feature_value=get_sep_p2(data)
%function feature_value=get_sep_p2(data)
%argument data is an array or instance of Trial, Day, or Period object(s).
%This function calculates the average amplitude of the ECoG in the
%p1 period and subtracts from it the average amplitude in the
%baseline ECoG period.
frag_ids=[2 3]; %Only need the first fragment.
ani=E3.Subject;
ani.DB_id=data(1).subject_id;
ad_names={ani.SubjectDetails.Name};
be_id=str2double(ani.SubjectDetails(strcmpi(ad_names,'best_ecog_channel_id')).Value);
base_start=str2double(ani.SubjectDetails(strcmpi(ad_names,'sep_base_start_ms')).Value);
base_stop=str2double(ani.SubjectDetails(strcmpi(ad_names,'sep_base_stop_ms')).Value);
peak_start=str2double(ani.SubjectDetails(strcmpi(ad_names,'sep_p2_start_ms')).Value);
peak_stop=str2double(ani.SubjectDetails(strcmpi(ad_names,'sep_p2_stop_ms')).Value);
base_values=get_td_feature(data,frag_ids,[base_start base_stop],be_id,false);
sep_values=get_td_feature(data,frag_ids,[peak_start peak_stop],be_id,false);
feature_value=sep_values-base_values;