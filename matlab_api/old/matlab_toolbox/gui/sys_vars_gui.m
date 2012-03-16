function varargout = sys_vars_gui(varargin)
% SYS_VARS_GUI MATLAB code for sys_vars_gui.fig
%      SYS_VARS_GUI, by itself, creates a new SYS_VARS_GUI or raises the existing
%      singleton*.
%
%      H = SYS_VARS_GUI returns the handle to a new SYS_VARS_GUI or the handle to
%      the existing singleton*.
%
%      SYS_VARS_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SYS_VARS_GUI.M with the given input arguments.
%
%      SYS_VARS_GUI('Property','Value',...) creates a new SYS_VARS_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before sys_vars_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to sys_vars_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help sys_vars_gui

% Last Modified by GUIDE v2.5 25-Nov-2011 14:28:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @sys_vars_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @sys_vars_gui_OutputFcn, ...
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


% --- Executes just before sys_vars_gui is made visible.
function sys_vars_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to sys_vars_gui (see VARARGIN)

mainGuiInput = find(strcmp(varargin, 'main_gui'));
if ~isempty(mainGuiInput)
    handles.main_gui = varargin{mainGuiInput+1};
    temph=guidata(handles.main_gui);
    %handles.e3dbx=temph.e3dbx;
else
    import E3.*
    paths;
end
handles.e3dbx=E3.Dbmym('e3analysis');

% Choose default command line output for sys_vars_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
refresh_sys_vars(hObject);

% UIWAIT makes sys_vars_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = sys_vars_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in pb_add.
function pb_add_Callback(hObject, eventdata, handles)
% hObject    handle to pb_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pb_delete.
function pb_delete_Callback(hObject, eventdata, handles)
handles.sys_vars(handles.selected_row).remove_from_db;
refresh_sys_vars(hObject);

function refresh_sys_vars(h)
handles=guidata(h);
%get the data from the database.
handles.sys_vars=E3.Sysvar.get_obj_array(handles.e3dbx);
data=[{handles.sys_vars.Name}' {handles.sys_vars.Value}' {handles.sys_vars.Description}'];
set(handles.tbl_sysvars,'Data',data);
guidata(h,handles);

% --- Executes when entered data in editable cell(s) in tbl_sysvars.
function tbl_sysvars_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to tbl_sysvars (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
row=eventdata.Indices(1);
col=eventdata.Indices(2);
col_names=get(handles.tbl_sysvars,'ColumnName');
adjusted_colname=col_names{col};
handles.sys_vars(row).(adjusted_colname)=eventdata.NewData;
refresh_sys_vars(hObject);


% --- Executes when selected cell(s) is changed in tbl_sysvars.
function tbl_sysvars_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to tbl_sysvars (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
handles.selected_row=eventdata.Indices(1);
guidata(hObject,handles);
