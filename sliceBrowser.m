function varargout = sliceBrowser(varargin)
% SLICEBROWSER Browse 3D array, slice by slice along 3rd dimension
%      sliceBrowser(arr) Browse the 3D array, sliding dynamic range
%      sliceBrowser(arr,postProcFunction) Browse the array, processing each 
%      slice with postProcFunction.
%           EX. sliceBrowser(arr,@angle) 
%           EX. filt = ones(3); sliceBrowser(arr,@(x) filter2(filt,x) )
%
%      SLICEBROWSER, by itself, creates a new SLICEBROWSER or raises the existing
%      singleton*.
%
%      H = SLICEBROWSER returns the handle to a new SLICEBROWSER or the handle to
%      the existing singleton*.
%
%      SLICEBROWSER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SLICEBROWSER.M with the given input arguments.
%
%      SLICEBROWSER('Property','Value',...) creates a new SLICEBROWSER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before sliceBrowser_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to sliceBrowser_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Last Modified by GUIDE v2.5 25-Aug-2017 10:56:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @sliceBrowser_OpeningFcn, ...
                   'gui_OutputFcn',  @sliceBrowser_OutputFcn, ...
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

% --- Executes just before sliceBrowser is made visible.
function sliceBrowser_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to sliceBrowser (see VARARGIN)

% Choose default command line output for sliceBrowser
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Handle arguments
switch length(varargin)
    case 1
        % sliceBrowser(arr)
        handles.image_arr = varargin{1};
    case 2
        % sliceBrowser(arr,func)
        handles.image_arr = varargin{1};
        handles.func = varargin{2};
    case 3
        % sliceBrowser(arr,func,cLim)
        handles.image_arr = varargin{1};
        handles.func = varargin{2};
        cLim = varargin{3}; 
    otherwise
        handles.image_arr = randn(5,5,5);
end
if ~isfield(handles,'func')
    handles.func = @(x) x;
end

handles.slice = 1;
if ~exist('cLim','var')
    cLim = handles.func(handles.image_arr(:,:,handles.slice));
    cLim = [min(cLim(:)), max(cLim(:))];
end
minVal = 1;
maxVal = size(handles.image_arr,3);
range = maxVal-minVal;

% Set video playback options
handles.video.fr = 5;
handles.video.frameskip = 1;
handles.video.isPlaying = false;

% Update slider values
set(handles.slider1,'Min',minVal);
set(handles.slider1,'Max',maxVal);
set(handles.slider1,'Value',handles.slice);
set(handles.slider1,'SliderStep',[1 max(floor(floor(0.05*range)/10)*10,1)]/(range));
guidata(hObject,handles);

% Initialize popup menu
set(handles.popupmenu2,'Min',1);
set(handles.popupmenu2,'Max',size(handles.image_arr,3));
set(handles.popupmenu2,'Value',handles.slice);
set(handles.popupmenu2,'String',(1:size(handles.image_arr,3)));
guidata(hObject,handles);

% This sets up the initial plot - only do when we are invisible
% so window can get raised using sliceBrowser.
if strcmp(get(hObject,'Visible'),'off')
%     plot(rand(5));
    handles.img = imagesc(...
        handles.func(handles.image_arr(:,:,handles.slice)),cLim);
    updateImage(hObject,handles);
    set(hObject,'Visible','on');
    pause(0.001); % Give GUI time to turn on. Increase if misbehaving.
    caxis auto;
    colormap(gray)
    ylim([1 size(handles.image_arr,1)]+0.5*[-1 1] );
    xlim([1 size(handles.image_arr,2)]+0.5*[-1 1] );
    caxis(cLim);
    
end

function playVideo(hObject,handles)
while(get(handles.PlayButton,'Value'))
%     disp(handles.slice)
    handles.slice = handles.slice+handles.video.frameskip;
    if handles.slice > size(handles.image_arr,3) 
        handles.slice = 1;
    end
    guidata(hObject,handles);
    updateImage(hObject,handles);
    drawnow;
    pause(1/handles.video.fr)
%     if ~handles.PlayButton.Value
%         break;
%     end
        
end

function updateImage(hObject,handles)
% Update slice values
set(handles.slider1,'Value',handles.slice)
set(handles.popupmenu2,'Value',handles.slice)
img = squeeze(handles.image_arr(:,:,handles.slice));
% if isfield(handles, 'func')
%     handles.img = handles.func(handles.img);
% end
assert(ismatrix(img),'img not matrix');

%% Update plot
if isequal(get(handles.axes1,'CLimMode'),'manual')
    clim = get(handles.axes1,'CLim');
end
% imagesc(img);
set(handles.img,'CData',handles.func(img));
guidata(hObject,handles);
if exist('clim','var')
    caxis(handles.axes1,clim); caxis manual;
end
colorbar

% UIWAIT makes sliceBrowser wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = sliceBrowser_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.figure1)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
                     ['Close ' get(handles.figure1,'Name') '...'],...
                     'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

delete(handles.figure1)


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
     set(hObject,'BackgroundColor','white');
end

set(hObject, 'String', {'plot(rand(5))', 'plot(sin(1:0.01:25))', 'bar(1:.5:10)', 'plot(membrane)', 'surf(peaks)'});


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
%set slice
handles.slice = round(get(hObject,'Value'));
guidata(hObject,handles);
%update axes
updateImage(hObject,handles);

% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2
handles.slice = round(get(hObject,'Value'));
guidata(hObject,handles);
updateImage(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function axes1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes1


% --- Executes on button press in PlayButton.
function PlayButton_Callback(hObject, eventdata, handles)
% hObject    handle to PlayButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PlayButton
handles.video.isPlaying = get(hObject,'Value');
guidata(hObject,handles);
if handles.video.isPlaying
    set(hObject,'String','Pause');
    guidata(hObject, handles);
    playVideo(hObject, handles);
else
    set(hObject,'String','Play');
end
