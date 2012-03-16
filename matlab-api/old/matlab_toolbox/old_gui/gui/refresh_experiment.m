function refresh_experiment(exper_h)
%Set some gui values.
handles=guidata(exper_h);
exper=handles.exper;

set(handles.et_exp_name,'String',exper.Name);

if ~isempty(exper.Subjects)
    set(handles.lb_subj,'String',{exper.Subjects.Name});
    if get(handles.lb_subj,'Value')>length(get(handles.lb_subj,'String'))
        set(handles.lb_subj,'Value',length(get(handles.lb_subj,'String')));
    end
    set(handles.pb_subj_remove,'enable','on');
else
    set(handles.pb_subj_remove,'enable','off');
    set(handles.lb_subj,'String',{'[EMPTY]'});
end

if ~isempty(exper.Analyses)
    set(handles.lb_analyses,'String',{exper.Analyses.Name});
    if get(handles.lb_analyses,'Value')>length(get(handles.lb_analyses,'String'))
        set(handles.lb_analyses,'Value',length(get(handles.lb_analyses,'String')));
    end
    set(handles.pb_analysis_remove,'enable','on');
else
    set(handles.pb_analysis_remove,'enable','off');
    set(handles.lb_analyses,'String',{'[EMPTY]'});
end

guidata(exper_h,handles);

if isfield(handles,'main_gui')
    refresh_e3analysis(handles.main_gui);
end