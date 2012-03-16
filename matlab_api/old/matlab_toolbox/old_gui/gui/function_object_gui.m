function varargout = function_object_gui(varargin)
% FUNCTION_OBJECT_GUI MATLAB code for function_object_gui.fig
%      FUNCTION_OBJECT_GUI, by itself, creates a new FUNCTION_OBJECT_GUI or raises the existing
%      singleton*.
%
%      H = FUNCTION_OBJECT_GUI returns the handle to a new FUNCTION_OBJECT_GUI or the handle to
%      the existing singleton*.
%
%      FUNCTION_OBJECT_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FUNCTION_OBJECT_GUI.M with the given input arguments.
%
%      FUNCTION_OBJECT_GUI('Property','Value',...) creates a new FUNCTION_OBJECT_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before function_object_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to function_object_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help function_object_gui

% Last Modified by GUIDE v2.5 19-Jul-2011 12:58:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @function_object_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @function_object_gui_OutputFcn, ...
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


% --- Executes just before function_object_gui is made visible.
function function_object_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to function_object_gui (see VARARGIN)

mainGuiInput = find(strcmp(varargin, 'main_gui'));
if ~isempty(mainGuiInput)
    handles.main_gui = varargin{mainGuiInput+1};
end
objInput = find(strcmp(varargin,'obj'));
if ~isempty(objInput)
    handles.obj=varargin{objInput+1};    
    set(handles.panel,'Title',class(handles.obj));
    set(handles.et_name,'String',handles.obj.Name);
    set(handles.et_func,'String',handles.obj.FunctionName);
    set(handles.et_description,'String',handles.obj.Description);
end

% Choose default command line output for function_object_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes function_object_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = function_object_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function et_name_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of et_name as text
%        str2double(get(hObject,'String')) returns contents of et_name as a double
handles.obj.Name=get(hObject,'String');
refresh_e3analysis(handles.main_gui);
function et_name_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function et_func_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of et_func as text
%        str2double(get(hObject,'String')) returns contents of et_func as a double
handles.obj.FunctionName=get(hObject,'String');
refresh_e3analysis(handles.main_gui);
function et_func_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function et_description_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of et_description as text
%        str2double(get(hObject,'String')) returns contents of et_description as a double
handles.obj.Description=get(hObject,'String');
refresh_e3analysis(handles.main_gui);
function et_description_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
