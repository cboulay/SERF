function refresh_e3analysis(e3h)

handles=guidata(e3h);

%Get an array of experiments from db, add to handles, update lb.
handles.exps=E3.Experiment.get_obj_array;
if ~isempty(handles.exps)
    set(handles.lb_exp,'String',{handles.exps.Name});
else
    set(handles.lb_exp,'String',{'[EMPTY]'});
    set(handles.lb_exp,'Value',1);
end

%Get an array of sbujects from db, add to handles, update lb.
handles.anis=E3.Subject.get_obj_array;
if ~isempty(handles.anis)
    if get(handles.lb_ani,'Value')>length(handles.anis)
        set(handles.lb_ani,'Value',length(handles.anis));
    end
    set(handles.lb_ani,'String',{handles.anis.Name});
else
    set(handles.lb_ani,'String',{'[EMPTY]'});
    set(handles.lb_ani,'Value',1);
end

%Get an array of subject detail types from db, add to handles, update lb.
handles.adts=E3.Subject_detail_type.get_obj_array;
if ~isempty(handles.adts)
    set(handles.lb_adt,'String',{handles.adts.Name});
else
    set(handles.lb_adt,'String',{'[EMPTY]'});
    set(handles.lb_adt,'Value',1);
end

%Get an array of feature types from db, add to handles, update lb.
handles.fts=E3.Feature_type.get_obj_array;
if ~isempty(handles.fts)
    set(handles.lb_ft,'String',{handles.fts.Name});
else
    set(handles.lb_ft,'String',{'[EMPTY]'});
    set(handles.lb_ft,'Value',1);
end

%Get an array of period types from db, add to handles, update lb.
handles.pts=E3.Period_type.get_obj_array;
if ~isempty(handles.pts)
    set(handles.lb_pt,'String',{handles.pts.Name});
else
    set(handles.lb_pt,'String',{'[EMPTY]'});
    set(handles.lb_pt,'Value',1);
end

%Get an array of analyses from db, add to handles, update lb.
handles.analyses=E3.Analysis.get_obj_array;
if ~isempty(handles.analyses)
    set(handles.lb_analysis,'String',{handles.analyses.Name});
else
    set(handles.lb_analysis,'String',{'[EMPTY]'});
    set(handles.lb_analysis,'Value',1);
end

guidata(e3h,handles);