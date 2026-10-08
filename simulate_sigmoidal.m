function varargout = simulate_sigmoidal(varargin)
% SIMULATE_SIGMOIDAL MATLAB code for simulate_sigmoidal.fig
%      SIMULATE_SIGMOIDAL, by itself, creates a new SIMULATE_SIGMOIDAL or raises the existing
%      singleton*.
%
%      H = SIMULATE_SIGMOIDAL returns the handle to a new SIMULATE_SIGMOIDAL or the handle to
%      the existing singleton*.
%
%      SIMULATE_SIGMOIDAL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SIMULATE_SIGMOIDAL.M with the given input arguments.
%
%      SIMULATE_SIGMOIDAL('Property','Value',...) creates a new SIMULATE_SIGMOIDAL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before simulate_sigmoidal_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to simulate_sigmoidal_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help simulate_sigmoidal

% Last Modified by GUIDE v2.5 10-Dec-2024 13:22:08

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @simulate_sigmoidal_OpeningFcn, ...
                   'gui_OutputFcn',  @simulate_sigmoidal_OutputFcn, ...
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


% --- Executes just before simulate_sigmoidal is made visible.
function simulate_sigmoidal_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to simulate_sigmoidal (see VARARGIN)

% Choose default command line output for simulate_sigmoidal
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

subjects = getSubjects;
set(handles.subjectSelector,'String',subjects);
updateSubject(handles);

% UIWAIT makes simulate_sigmoidal wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function updateSubject(handles)

subjects = handles.subjectSelector.String;
subject = subjects{handles.subjectSelector.Value};

repetitions = getRepetitions(subject);
set(handles.repetitionSelector,'String',repetitions);
handles.repetitionSelector.Value = 1;
updateRepetition(handles);

function updateRepetition(handles)

subjects = handles.subjectSelector.String;
subject = subjects{handles.subjectSelector.Value};

repetitions = handles.repetitionSelector.String;
repetition = repetitions{handles.repetitionSelector.Value};

[result,handles.stimulatorOutput,handles.logMEPsMEP0] = fitIOcurveRepetition(subject,repetition);
guidata(handles.figure1, handles);

set(handles.deltay,'String',num2str(result(1)));
set(handles.s,'String',num2str(result(2)));
set(handles.m,'String',num2str(result(3)));

updateGraph(handles);

function updateGraph(handles)

deltay = str2double(handles.deltay.String);
s = str2double(handles.s.String);
m = str2double(handles.m.String);

x = handles.stimulatorOutput;
y = handles.logMEPsMEP0;

minx = 0; %min(x);
maxx = 200; %max(x);
hold(handles.axes1,'off');
xs = linspace(minx,maxx,100);
yfit = evaluateIOfunction(xs,deltay,s,m);
plot(handles.axes1,xs,yfit);
hold(handles.axes1,'on');
plot(handles.axes1,x,y,'r*');



% --- Outputs from this function are returned to the command line.
function varargout = simulate_sigmoidal_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function deltay_Callback(hObject, eventdata, handles)
updateGraph(handles);

% --- Executes during object creation, after setting all properties.
function deltay_CreateFcn(hObject, eventdata, handles)
% hObject    handle to deltay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function s_Callback(hObject, eventdata, handles)
updateGraph(handles);


% --- Executes during object creation, after setting all properties.
function s_CreateFcn(hObject, eventdata, handles)
% hObject    handle to s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function m_Callback(hObject, eventdata, handles)
updateGraph(handles);


% --- Executes during object creation, after setting all properties.
function m_CreateFcn(hObject, eventdata, handles)
% hObject    handle to m (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in subjectSelector.
function subjectSelector_Callback(hObject, eventdata, handles)
updateSubject(handles);

% --- Executes during object creation, after setting all properties.
function subjectSelector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subjectSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in repetitionSelector.
function repetitionSelector_Callback(hObject, eventdata, handles)
updateRepetition(handles);

% --- Executes during object creation, after setting all properties.
function repetitionSelector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to repetitionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
