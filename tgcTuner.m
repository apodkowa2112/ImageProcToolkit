function varargout = tgcTuner(varargin)
% TGCTUNER MATLAB code for tgcTuner.fig
%      TGCTUNER, by itself, creates a new TGCTUNER or raises the existing
%      singleton*.
%
%      H = TGCTUNER returns the handle to a new TGCTUNER or the handle to
%      the existing singleton*.
%
%      TGCTUNER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TGCTUNER.M with the given input arguments.
%
%      TGCTUNER('Property','Value',...) creates a new TGCTUNER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before tgcTuner_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to tgcTuner_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help tgcTuner

% Last Modified by GUIDE v2.5 07-Sep-2022 16:30:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @tgcTuner_OpeningFcn, ...
                   'gui_OutputFcn',  @tgcTuner_OutputFcn, ...
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

function handles=updateImg(handles)
%% Load Variables
tgcCtrl = handles.tgcCtrl;
tgc = handles.tgc;
% Need to force range of [0,1] to avoid extrapolation, hence -1
tgc = interp1((0:length(tgcCtrl)-1)/(length(tgcCtrl)-1),tgcCtrl,...
    (0:length(tgc)-1)/(length(tgc)-1),'pchip');

%% Update TGC Plot
handles.hTgc.YData = tgc;

%% Update figure
data = handles.data;
handles.hImg.CData = bsxfun(@plus,data,tgc(:));
drawnow limitrate

%% Update handles
handles.tgcCtrl = tgcCtrl;
handles.tgc = tgc;

function y = ceilsf(x,n)
y = ceil(x/n)*n;

% --- Executes just before tgcTuner is made visible.
function tgcTuner_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to tgcTuner (see VARARGIN)

% Choose default command line output for tgcTuner
handles.output = hObject;

try
    handles.data = varargin{1};
catch
    handles.data = abs(randn(3000,128));
end
dynamicRange = [-80 0];
handles.tgcCtrl = zeros(6,1); % Designed for dB scale of [-80 0]
handles.tgc = zeros(size(handles.data,1),1);
handles.hTgc = plot(1:length(handles.tgc),handles.tgc);
ylim(dynamicRange)
grid on;
view(90,90);
title('TGC')
xlim([1 length(handles.tgc)])
xticks(linspace(1,length(handles.tgc),6));
yticks(dynamicRange(1):20:dynamicRange(2));

handles.hImg = imagesc(handles.imgAxes,handles.data);
colormap gray;
caxis(handles.imgAxes,dynamicRange+ceilsf(max(handles.data(:)),10));
handles.hCB = colorbar(handles.imgAxes);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes tgcTuner wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = tgcTuner_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.tgc;
delete(handles.figure1);

function tgcSld_Callback(hObject,eventdata,handles,num)
tgc = get(hObject,'Value');
handles.tgcCtrl(num) = tgc;
handles = updateImg(handles);
guidata(hObject,handles);

% --- Executes on slider movement.
function tgcSld1_Callback(hObject, eventdata, handles)
% hObject    handle to tgcSld1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tgcSld_Callback(hObject,eventdata,handles,1);
% tgc = get(hObject,'Value');
% handles.tgcCtrl(1) = tgc;
% handles = updateImg(handles);
% guidata(hObject,handles);

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function tgcSld1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tgcSld1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function tgcSld2_Callback(hObject, eventdata, handles)
% hObject    handle to tgcSld2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tgcSld_Callback(hObject,eventdata,handles,2);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function tgcSld2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tgcSld2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function tgcSld3_Callback(hObject, eventdata, handles)
% hObject    handle to tgcSld3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tgcSld_Callback(hObject,eventdata,handles,3);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function tgcSld3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tgcSld3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function tgcSld4_Callback(hObject, eventdata, handles)
% hObject    handle to tgcSld4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tgcSld_Callback(hObject,eventdata,handles,4);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function tgcSld4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tgcSld4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function tgcSld5_Callback(hObject, eventdata, handles)
% hObject    handle to tgcSld5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tgcSld_Callback(hObject,eventdata,handles,5);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function tgcSld5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tgcSld5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function tgcSld6_Callback(hObject, eventdata, handles)
% hObject    handle to tgcSld6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tgcSld_Callback(hObject,eventdata,handles,6);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function tgcSld6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tgcSld6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% https://blogs.mathworks.com/videos/2010/02/12/advanced-getting-an-output-from-a-guide-gui/
if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, use UIRESUME
    uiresume(hObject);
else
    % The GUI is no longer waiting, just close it
    delete(hObject);
end
% Hint: delete(hObject) closes the figure
% delete(hObject);
