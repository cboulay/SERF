function refresh_subject(subj_h)
%Set some gui values.
handles=guidata(subj_h);
ani=handles.ani;
set(handles.et_subj_name,'String',ani.Name);
handles.dbnames=get_db_names;
set(handles.pu_dbname,'String',handles.dbnames);
if ~isempty(ani.E3Name)
    set(handles.pu_dbname,'Value',find(strcmpi(handles.dbnames,ani.E3Name)));
else
    set(handles.pu_dbname,'Value',1);
end
set(handles.rb_male,'Value',strcmpi(ani.Gender,'male'));
set(handles.et_strain,'String',ani.Strain);
set(handles.et_weight,'String',num2str(ani.Weight));

if ~isempty(ani.Periods)
    per_v=get(handles.pu_periods,'Value');
    set(handles.pu_periods,'String',{ani.Periods.Name});
    set(handles.pb_periods_start,'String',datestr(floor(datenum(ani.Periods(per_v).StartTime))));
    set(handles.pb_periods_stop,'String',datestr(floor(datenum(ani.Periods(per_v).EndTime))));
    set(handles.pb_periods_remove,'enable','on');
else
    set(handles.pb_periods_remove,'enable','off');
    set(handles.pu_periods,'String',{'[EMPTY]'});
end

if ~isempty(ani.Channels)
    chan_v=get(handles.pu_channels,'Value');
    set(handles.pu_channels,'String',{ani.Channels.Name});
    set(handles.cb_rectified,'Value',ani.Channels(chan_v).IsRectified);
    set(handles.cb_inverted,'Value',ani.Channels(chan_v).IsInverted);
    set(handles.cb_chan_is_good,'Value',ani.Channels(chan_v).IsGood);
    set(handles.et_ad_bits,'String',num2str(ani.Channels(chan_v).ADBits));
    set(handles.et_ad_range,'String',num2str(ani.Channels(chan_v).ADRange));
    set(handles.et_amplification,'String',num2str(ani.Channels(chan_v).TotalAmplification));
    set(handles.et_mr_start,'String',num2str(ani.Channels(chan_v).MRStartms));
    set(handles.et_mr_stop,'String',num2str(ani.Channels(chan_v).MRStopms));
    set(handles.et_hr_start,'String',num2str(ani.Channels(chan_v).HRStartms));
    set(handles.et_hr_stop,'String',num2str(ani.Channels(chan_v).HRStopms));
    set(handles.et_rew_start,'String',num2str(ani.Channels(chan_v).RewardLow));
    set(handles.et_rew_stop,'String',num2str(ani.Channels(chan_v).RewardHigh));
    set(handles.pb_det_remove,'enable','on');
else
    set(handles.pu_channels,'String',{'[EMPTY]'});
end

if ~isempty(ani.SubjectDetails)
    set(handles.pu_details,'String',{ani.SubjectDetails.Name});
    if get(handles.pu_details,'Value')>length(get(handles.pu_details,'String'))
        set(handles.pu_details,'Value',length(get(handles.pu_details,'String')));
    end
    det_v=get(handles.pu_details,'Value');
    set(handles.et_det_value,'String',ani.SubjectDetails(det_v).Value);
    set(handles.pb_det_remove,'enable','on');
else
    set(handles.pb_det_remove,'enable','off');
    set(handles.pu_details,'String',{'[EMPTY]'});
end

handles.fts=E3.Feature_type.get_obj_array; %All feature types.

if ~isempty(ani.TrialCriteria)
    set(handles.lb_crit,'String',{ani.TrialCriteria.Full_name});
    if get(handles.lb_crit,'Value')>length(get(handles.lb_crit,'String'))
        set(handles.lb_crit,'Value',length(get(handles.lb_crit,'String')));
    end
    set(handles.pb_crit_remove,'enable','on');
else
    set(handles.pb_crit_remove,'enable','off');
    set(handles.lb_crit,'String',{'[EMPTY]'});
end

set(handles.et_notes,'String',ani.Notes);

guidata(subj_h,handles);

if isfield(handles,'main_gui')
    refresh_e3analysis(handles.main_gui);
end