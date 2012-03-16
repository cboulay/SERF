function varargout = subject_gui(varargin)
% SUBJECT_GUI MATLAB code for subject_gui.fig
%      SUBJECT_GUI, by itself, creates a new SUBJECT_GUI or raises the existing
%      singleton*.
%
%      H = SUBJECT_GUI returns the handle to a new SUBJECT_GUI or the handle to
%      the existing singleton*.
%
%      SUBJECT_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SUBJECT_GUI.M with the given input arguments.
%
%      SUBJECT_GUI('Property','Value',...) creates a new SUBJECT_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before subject_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to subject_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help subject_gui

% Last Modified by GUIDE v2.5 25-Jul-2011 12:59:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @subject_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @subject_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before subject_gui is made visible.
function subject_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to subject_gui (see VARARGIN)
mainGuiInput = find(strcmp(varargin, 'main_gui'));
if ~isempty(mainGuiInput)
    handles.main_gui = varargin{mainGuiInput+1};
end
aniInput = find(strcmp(varargin,'ani'));
if ~isempty(aniInput)
    handles.ani=varargin{aniInput+1};
end

% Choose default command line output for subject_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
refresh_subject(hObject);


% UIWAIT makes subject_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = subject_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on selection change in pu_dbname.
function pu_dbname_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns pu_dbname contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pu_dbname
contents = cellstr(get(hObject,'String'));
handles.ani.E3Name=contents{get(hObject,'Value')};
refresh_subject(gcbf);
function pu_dbname_CreateFcn(hObject, eventdata, handles)
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function et_strain_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of et_strain as text
%        str2double(get(hObject,'String')) returns contents of et_strain as a double
handles.ani.Strain=get(hObject,'String');
refresh_subject(gcbf);
function et_strain_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function et_weight_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of et_weight as text
%        str2double(get(hObject,'String')) returns contents of et_weight as a double
handles.ani.Weight=str2double(get(hObject,'String'));
refresh_subject(gcbf);
function et_weight_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function et_subj_name_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of et_subj_name as text
%        str2double(get(hObject,'String')) returns contents of et_subj_name as a double
handles.ani.Name=get(hObject,'String');
refresh_subject(gcbf);
function et_subj_name_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function et_notes_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of et_notes as text
%        str2double(get(hObject,'String')) returns contents of et_notes as a double
handles.ani.Notes=get(hObject,'String');
refresh_subject(gcbf);
function et_notes_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pb_delete.
function pb_delete_Callback(hObject, eventdata, handles)
handles.ani.remove_from_db;
if isfield(handles,'main_gui')
    refresh_e3analysis(handles.main_gui);
end
close(gcbf);

% --- Executes on selection change in lb_crit.
function lb_crit_Callback(hObject, eventdata, handles)
function lb_crit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pb_crit_add.
function pb_crit_add_Callback(hObject, eventdata, handles)
trial_criterion_builder('subject_gui',get(hObject,'parent'));

function pb_crit_remove_Callback(hObject, eventdata, handles)
handles.ani.TrialCriteria(get(handles.lb_crit,'Value')).remove_from_db;
refresh_subject(gcbf);

% --- Executes on selection change in pu_periods.
function pu_periods_Callback(hObject, eventdata, handles)
refresh_subject(gcbf);
function pu_periods_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pb_periods_add.
function pb_periods_add_Callback(hObject, eventdata, handles)
pts=E3.Period_type.get_obj_array;
[Selection,ok] = listdlg('ListString',{pts.Name},'SelectionMode','single');
pt=pts(Selection);
if ok && ~isempty(pt) && (isempty(handles.ani.Periods) || ~any(strcmpi({handles.ani.Periods.Name},pt.Name)))
    period=E3.Period;
    period.subject_id=handles.ani.DB_id;
    period.period_type_id=pt.DB_id;
    period.StartTime='01-Jan-2010';%Define in matlab format.
    period.EndTime='31-Dec-2010';
    set(handles.pu_periods,'Value',find(strcmp({handles.ani.Periods.Name},pt.Name)));
end
refresh_subject(gcbf);

% --- Executes on button press in pb_periods_remove.
function pb_periods_remove_Callback(hObject, eventdata, handles)
handles.ani.Periods(get(handles.pu_periods,'Value')).remove_from_db;
refresh_subject(gcbf);

function et_det_value_Callback(hObject, eventdata, handles)
new_val=get(hObject,'String');
handles.ani.SubjectDetails(get(handles.pu_details,'Value')).Value=new_val;
refresh_subject(gcbf);
function et_det_value_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pb_det_add.
function pb_det_add_Callback(hObject, eventdata, handles)
adts=E3.Subject_detail_type.get_obj_array;
[Selection,ok] = listdlg('ListString',{adts.Name},'SelectionMode','single');
adt=adts(Selection);
if ok && ~isempty(adt) && (isempty(handles.ani.SubjectDetails) || ~any(strcmpi({handles.ani.SubjectDetails.Name},adt.Name)))
    ad=E3.Subject_detail;
    ad.subject_detail_type_id=adt.DB_id;
    ad.subject_id=handles.ani.DB_id;
    ad.Value='1';
    set(handles.pu_details,'Value',find(strcmp({handles.ani.SubjectDetails.Name},ad.Name)));
end
refresh_subject(gcbf);

% --- Executes on button press in pb_det_remove.
function pb_det_remove_Callback(hObject, eventdata, handles)
handles.ani.SubjectDetails(get(handles.pu_details,'Value')).remove_from_db;
refresh_subject(gcbf);

% --- Executes on selection change in pu_details.
function pu_details_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns pu_details contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pu_details
refresh_subject(gcbf);
function pu_details_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in pu_channels.
function pu_channels_Callback(hObject, eventdata, handles) %#ok<*INUSL,*DEFNU>
% Hints: contents = cellstr(get(hObject,'String')) returns pu_channels contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pu_channels
refresh_subject(gcbf);
function pu_channels_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in cb_rectified.
function cb_rectified_Callback(hObject, eventdata, handles)
handles.ani.Channels(get(handles.pu_channels,'Value')).IsRectified=logical(get(hObject,'Value'));
refresh_subject(gcbf);

% --- Executes on button press in cb_inverted.
function cb_inverted_Callback(hObject, eventdata, handles)
handles.ani.Channels(get(handles.pu_channels,'Value')).IsInverted=logical(get(hObject,'Value'));
refresh_subject(gcbf);

% --- Executes on button press in cb_chan_is_good.
function cb_chan_is_good_Callback(hObject, eventdata, handles)
handles.ani.Channels(get(handles.pu_channels,'Value')).IsGood=logical(get(hObject,'Value'));
refresh_subject(gcbf);

function et_ad_range_Callback(hObject, eventdata, handles)
handles.ani.Channels(get(handles.pu_channels,'Value')).ADRange=str2double(get(hObject,'String'));
refresh_subject(gcbf);
function et_ad_range_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function et_ad_bits_Callback(hObject, eventdata, handles)
handles.ani.Channels(get(handles.pu_channels,'Value')).ADBits=str2double(get(hObject,'String'));
refresh_subject(gcbf);
function et_ad_bits_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function et_mr_start_Callback(hObject, eventdata, handles)
handles.ani.Channels(get(handles.pu_channels,'Value')).MRStartms=str2double(get(hObject,'String'));
refresh_subject(gcbf);
function et_mr_start_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function et_mr_stop_Callback(hObject, eventdata, handles)
handles.ani.Channels(get(handles.pu_channels,'Value')).MRStopms=str2double(get(hObject,'String'));
refresh_subject(gcbf);
function et_mr_stop_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function et_hr_start_Callback(hObject, eventdata, handles)
handles.ani.Channels(get(handles.pu_channels,'Value')).HRStartms=str2double(get(hObject,'String'));
refresh_subject(gcbf);
function et_hr_start_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function et_hr_stop_Callback(hObject, eventdata, handles)
handles.ani.Channels(get(handles.pu_channels,'Value')).HRStopms=str2double(get(hObject,'String'));
refresh_subject(gcbf);
function et_hr_stop_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function et_rew_start_Callback(hObject, eventdata, handles)
handles.ani.Channels(get(handles.pu_channels,'Value')).RewardLow=str2double(get(hObject,'String'));
refresh_subject(gcbf);
function et_rew_start_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function et_rew_stop_Callback(hObject, eventdata, handles)
handles.ani.Channels(get(handles.pu_channels,'Value')).RewardHigh=str2double(get(hObject,'String'));
refresh_subject(gcbf);
function et_rew_stop_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function et_amplification_Callback(hObject, eventdata, handles)
handles.ani.Channels(get(handles.pu_channels,'Value')).TotalAmplification=str2double(get(hObject,'String'));
refresh_subject(gcbf);
function et_amplification_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pb_channels_default.
function pb_channels_default_Callback(hObject, eventdata, handles)
handles.ani.Channels.remove_from_db;
refresh_subject(gcbf);

% --- Executes on button press in pb_periods_start.
function pb_periods_start_Callback(hObject, eventdata, handles)
new_date=uigetdate(get(handles.pb_periods_start,'String'));
new_date=floor(new_date);
handles.ani.Periods(get(handles.pu_periods,'Value')).StartTime=datestr(new_date+13/24);
refresh_subject(gcbf);

% --- Executes on button press in pb_periods_stop.
function pb_periods_stop_Callback(hObject, eventdata, handles)
new_date=uigetdate(get(handles.pb_periods_stop,'String'));
new_date=floor(new_date);
handles.ani.Periods(get(handles.pu_periods,'Value')).EndTime=datestr(new_date+13/24);
refresh_subject(gcbf);

function figure_CloseRequestFcn(hObject, eventdata, handles)

function pb_triage_trials_Callback(hObject, eventdata, handles)
if get(handles.cb_force_recalc,'Value')
    handles.ani.clear_calculated;
end
handles.ani.triage_trials;
refresh_subject(gcbf);

function pb_triage_days_Callback(hObject, eventdata, handles)
if get(handles.cb_force_recalc,'Value')
    handles.ani.clear_calculated;
end
handles.ani.triage_days;
refresh_subject(gcbf);

function pb_show_periods_Callback(hObject, eventdata, handles)
if get(handles.cb_force_recalc,'Value')
    handles.ani.clear_calculated;
end
handles.ani.show_periods;

function cb_force_recalc_Callback(hObject, eventdata, handles)
