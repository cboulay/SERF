function varargout = e3analysis(varargin)
% E3ANALYSIS MATLAB code for e3analysis.fig
%      E3ANALYSIS, by itself, creates a new E3ANALYSIS or raises the existing
%      singleton*.
%
%      H = E3ANALYSIS returns the handle to a new E3ANALYSIS or the handle to
%      the existing singleton*.
%
%      E3ANALYSIS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in E3ANALYSIS.M with the given input arguments.
%
%      E3ANALYSIS('Property','Value',...) creates a new E3ANALYSIS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before e3analysis_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to e3analysis_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help e3analysis

% Last Modified by GUIDE v2.5 19-Jul-2011 13:15:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @e3analysis_OpeningFcn, ...
                   'gui_OutputFcn',  @e3analysis_OutputFcn, ...
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


% --- Executes just before e3analysis is made visible.
function e3analysis_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to e3analysis (see VARARGIN)
import E3.*
paths;
% Choose default command line output for e3analysis
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
refresh_e3analysis(hObject);


% UIWAIT makes e3analysis wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = e3analysis_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function pb_new_exp_Callback(hObject, eventdata, handles)
new_exper=E3.Experiment('New Experiment');
refresh_e3analysis(gcbf);
handles=guidata(gcbf);
exper_names=get(handles.lb_exp,'String');
new_id=find(strcmp(exper_names,new_exper.Name));
set(handles.lb_exp,'Value',new_id);
experiment_gui('exper',handles.exps(get(handles.lb_exp,'Value')),'main_gui',gcbf);
function pb_edit_exp_Callback(hObject, eventdata, handles)
experiment_gui('exper',handles.exps(get(handles.lb_exp,'Value')),'main_gui',gcbf);
function lb_exp_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns lb_exp contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_exp
function lb_exp_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function pb_new_pt_Callback(hObject, eventdata, handles)
answer=inputdlg('Enter name of period type','New PT');
if ~isempty(answer)
    E3.Period_type(answer{1});
    refresh_e3analysis(gcbf);
end
function pb_edit_pt_Callback(hObject, eventdata, handles)
pt_id=get(handles.lb_pt,'Value');
this_pt=handles.pts(pt_id);
answer=inputdlg('Enter name of period type','Edit PT',1,{this_pt.Name});
if ~isempty(answer)
    this_pt.Name=answer{1};
    refresh_e3analysis(gcbf);
end
function pb_delete_pt_Callback(hObject, eventdata, handles)
pt=handles.pts(get(handles.lb_pt,'Value'));
pt.remove_from_db;
refresh_e3analysis(gcbf);
function lb_pt_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns lb_ft contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_ft
function lb_pt_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function pb_new_adt_Callback(hObject, eventdata, handles)
answer=inputdlg('Enter name of subject detail type','New ADT');
if ~isempty(answer)
    E3.Subject_detail_type(answer{1});
    refresh_e3analysis(gcbf);
end
function pb_edit_adt_Callback(hObject, eventdata, handles)
adt_id=get(handles.lb_adt,'Value');
this_adt=handles.adts(adt_id);
answer=inputdlg('Enter name of subject detail type','Edit ADT',1,{this_adt.Name});
if ~isempty(answer)
    this_adt.Name=answer{1};
    refresh_e3analysis(gcbf);
end
function pb_delete_adt_Callback(hObject, eventdata, handles)
adt=handles.adts(get(handles.lb_adt,'Value'));
adt.remove_from_db;
refresh_e3analysis(gcbf);
function lb_adt_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns lb_adt contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_adt
function lb_adt_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function pb_new_ani_Callback(hObject, eventdata, handles)
new_ani=E3.Subject('New Subject');
refresh_e3analysis(gcbf);
handles=guidata(gcbf);
ani_names=get(handles.lb_ani,'String');
new_id=find(strcmp(ani_names,new_ani.Name));
set(handles.lb_ani,'Value',new_id);
subject_gui('ani',handles.anis(get(handles.lb_ani,'Value')),'main_gui',gcbf);
function pb_edit_ani_Callback(hObject, eventdata, handles)
subject_gui('ani',handles.anis(get(handles.lb_ani,'Value')),'main_gui',gcbf);
function lb_ani_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns lb_ani contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_ani
function lb_ani_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function pb_new_ft_Callback(hObject, eventdata, handles)
new_ft=E3.Feature_type('New FT');
refresh_e3analysis(gcbf);
handles=guidata(gcbf);
ft_names=get(handles.lb_ft,'String');
new_id=find(strcmp(ft_names,new_ft.Name));
set(handles.lb_ft,'Value',new_id);
function_object_gui('obj',handles.fts(get(handles.lb_ft,'Value')),'main_gui',gcbf);
function pb_edit_ft_Callback(hObject, eventdata, handles)
function_object_gui('obj',handles.fts(get(handles.lb_ft,'Value')),'main_gui',gcbf);
function pb_delete_ft_Callback(hObject, eventdata, handles)
ft=handles.fts(get(handles.lb_ft,'Value'));
ft.remove_from_db;
set(handles.lb_ft,'Value',1);
refresh_e3analysis(gcbf);
function lb_ft_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns lb_ft contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_ft
function lb_ft_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pb_new_analysis_Callback(hObject, eventdata, handles)
new_ana=E3.Analysis('New Analysis');
refresh_e3analysis(gcbf);
handles=guidata(gcbf);
ana_names=get(handles.lb_analysis,'String');
new_id=find(strcmp(ana_names,new_ana.Name));
set(handles.lb_analysis,'Value',new_id);
function_object_gui('obj',handles.analyses(get(handles.lb_analysis,'Value')),'main_gui',gcbf);
function pb_edit_analysis_Callback(hObject, eventdata, handles)
function_object_gui('obj',handles.analyses(get(handles.lb_analysis,'Value')),'main_gui',gcbf);
function pb_delete_analysis_Callback(hObject, eventdata, handles)
ana=handles.analyses(get(handles.lb_analysis,'Value'));
ana.remove_from_db;
refresh_e3analysis(gcbf);
function lb_analysis_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns lb_analysis contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_analysis
function lb_analysis_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
