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

% Last Modified by GUIDE v2.5 23-Nov-2011 18:44:51

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
handles.e3dbx=E3.Dbmym('e3analysis');
% Choose default command line output for e3analysis
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

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


% --- Executes on selection change in lb_experiments.
function lb_experiments_Callback(hObject, eventdata, handles)
% hObject    handle to lb_experiments (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lb_experiments contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_experiments


% --- Executes during object creation, after setting all properties.
function lb_experiments_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lb_experiments (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_exp_new.
function pb_exp_new_Callback(hObject, eventdata, handles)
% hObject    handle to pb_exp_new (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pb_exp_edit.
function pb_exp_edit_Callback(hObject, eventdata, handles)
% hObject    handle to pb_exp_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in lb_subjects.
function lb_subjects_Callback(hObject, eventdata, handles)
% hObject    handle to lb_subjects (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lb_subjects contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_subjects


% --- Executes during object creation, after setting all properties.
function lb_subjects_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lb_subjects (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_subj_new.
function pb_subj_new_Callback(hObject, eventdata, handles)
% hObject    handle to pb_subj_new (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pb_subj_edit.
function pb_subj_edit_Callback(hObject, eventdata, handles)
% hObject    handle to pb_subj_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pb_features.
function pb_features_Callback(hObject, eventdata, handles)
% hObject    handle to pb_features (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pb_details.
function pb_details_Callback(hObject, eventdata, handles)
% hObject    handle to pb_details (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pb_subject_types.
function pb_subject_types_Callback(hObject, eventdata, handles)
% hObject    handle to pb_subject_types (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pb_functions.
function pb_functions_Callback(hObject, eventdata, handles)
% hObject    handle to pb_functions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pb_periods.
function pb_periods_Callback(hObject, eventdata, handles)
% hObject    handle to pb_periods (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pb_sys_defaults.
function pb_sys_defaults_Callback(hObject, eventdata, handles)
% hObject    handle to pb_sys_defaults (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
e3refresh(gcbf);
handles=guidata(gcbf);
sys_vars_gui('main_gui',gcbf);

function e3refresh(e3h)
handles=guidata(e3h);
guidata(e3h,handles);