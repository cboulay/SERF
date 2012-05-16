function feature_value=get_feature_bge(data)
%function feature_value=get_feature_bg(data)
%argument data is an array or instance of Trial, Day, or Period object(s).
%This function calculates the average absolute amplitude of the background
%EMG for conditioned channel
frag_ids=1; %Only need the first fragment.
ani=E3.Subject;
ani.DB_id=data(1).subject_id;
ad_names={ani.SubjectDetails.Name};
time_window=[-200 0];
cc_ad=find(strcmp(ad_names,'conditioned_channel_id'));
if any(cc_ad)
    cc_id=str2double(ani.SubjectDetails(cc_ad).Value);
    feature_value=get_td_feature(data,frag_ids,time_window,cc_id,true);
end
