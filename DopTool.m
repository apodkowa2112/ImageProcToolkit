function varargout = DopTool(varargin)
% DOPTOOL MATLAB code for DopTool.fig
%      DOPTOOL, by itself, creates a new DOPTOOL or raises the existing
%      singleton*.
%
%      H = DOPTOOL returns the handle to a new DOPTOOL or the handle to
%      the existing singleton*.
%
%      DOPTOOL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DOPTOOL.M with the given input arguments.
%
%      DOPTOOL('Property','Value',...) creates a new DOPTOOL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before DopTool_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to DopTool_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DopTool

% Last Modified by GUIDE v2.5 03-Aug-2017 09:34:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DopTool_OpeningFcn, ...
                   'gui_OutputFcn',  @DopTool_OutputFcn, ...
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
% --- Executes just before DopTool is made visible.

function DopTool_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to DopTool (see VARARGIN)

% Choose default command line output for DopTool
handles.output = hObject;

%% Load in appropriate paths
loadPaths;

%% Setup handles
warning('Hack: numFrames');
handles.data.numFrames=100;

handles.data.clutterFilt.cutoff = 1000; % [Hz]
handles.clutterFiltMode = 'clutterFiltSimple';

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DopTool wait for user response (see UIRESUME)
% uiwait(handles.figure1);


%% Data Processing functions
function bMode = getBmode(hObject,handles)
    if ~isfield(handles.data,'frameNum')
        handles.data.frameNum = 1;
    end
    guidata(hObject,handles);
    switch handles.data.compMode
    case 'HRI'
        bMode = iq2bMode(squeeze(...
            sum(handles.data.IQ(:,:,:,handles.data.frameNum),3)  ));
    case 'LRI'
        bMode = iq2bMode(handles.data.IQ(:,:,handles.data.frameNum));
    otherwise
        error('Unsupported Compounding String: %s', handles.data.compMode);
    end
    
function pdi = getPowerDoppler(hObject,handles)
    % Clear handles.data.pdi to force update
    if ~isfield(handles.data,'pdi')
        computePDI = @(iq) (mean(abs(iq(:,:,:)).^2, 3)); % parens to handle ND data
        pdi = computePDI(getFilteredIQ(hObject,handles));
        handles=guidata(hObject);
    else
        pdi = handles.data.pdi;
    end
    handles.data.pdi = pdi;
    guidata(hObject,handles);
    
function iq = getIQ(hObject,handles)
    switch handles.data.compMode
    case 'HRI'
        iq = squeeze(sum(handles.data.IQ,3));
    case 'LRI'
        iq = handles.data.IQ;
    otherwise 
        error('Unsupported compMode: %s',handles.data.compMode)
    end
    
function iq = getFilteredIQ(hObject,handles)
    
    % Clear handles.data.filt.IQ to force update
    if ~isfield(handles.data,'filtIQ')
        hMsg = msgbox('Filtering data.  Please wait.  This can take a long time.');
        iq = getIQ(hObject,handles);

        switch handles.clutterFiltMode
        case 'clutterFiltSimple'
            frameRate = 1/diff(handles.data.timeAxis(1:2));
            [iq,handles.data.clutterFilt.sos] = clutterFiltSimple(iq,frameRate,...
                handles.data.clutterFilt.cutoff);
            handles.data.filtIQ = iq;
            guidata(hObject,handles);
        case 'clutterFiltMatchedTx'
            frameRate = handles.data.AP.PRF1;
            %This function always operates on 4D data, so use LRIs here
            [iq,handles.data.clutterFilt.sos] = clutterFiltMatchedTx(handles.data.IQ,frameRate,...
                handles.data.clutterFilt.cutoff);
            if handles.data.compMode == 'HRI'
                handles.data.filtIQ = squeeze(sum(iq,3));
            end
            handles.data.filtIQ = iq;
            guidata(hObject,handles);
        otherwise
            error('Unsupported Mode: %s',value);
            handles.clutterFiltMode = 'Error';
        end
        close(hMsg);
    else
        iq = handles.data.filtIQ;
    end


function bMode = getFilteredBmode(hObject,handles)
    if ~isfield(handles.data,'frameNum')
        handles.data.frameNum = 1;
    end
    guidata(hObject,handles);
    iq = getFilteredIQ(hObject,handles);
    switch handles.data.compMode
    case 'HRI'
        iq = squeeze(iq(:,:,handles.data.frameNum));
    case 'LRI'
        iq = squeeze(iq(:,:,handles.data.frameNum));
    otherwise
        error('Unsupported Compounding String: %s', handles.data.compMode);
    end
    bMode = iq2bMode( iq  );
    

function frameRate = getFrameRate(hObject,handles)
        frameRate = 1/diff(handles.data.timeAxis(1:2));
        
%% Utility functions

function out = normZero(in) 
% Subtracts maximum, useful for decibel data
    out = in-max(in(:));
    
function out = iq2bMode(iq)
    % quick and dirty rendering function
    out = normZero(mag2db(abs(squeeze(iq)))); 

function out = valRange(x)
    % Get global min and max, useful for caxis scaling
    out = [min(x(:)) max(x(:))]; 
    
function out = findClosest(vec,num) 
    out = vec((abs(vec-num)==min(abs(vec-num))));

function ind = closestInd(vec,num)
    ind = find(abs(vec-num)==min(abs(vec-num)));

function vel = freq2Vel(freq,TxFreq,c)
    % Note: Make sure that freq and TxFreq have same units.
    vel = freq/TxFreq*c/2;

%% Internal Functions
function loadPaths()
    verasonicsDir = 'D:\Documents\MATLAB\verasonics-suite\PlaneWave\Verasonic Scripts';
%     verasonicsDir = 'G:\Verasonic Scripts';
    addpath([verasonicsDir '/analysis']);
    addpath([verasonicsDir '/doppler_routines']);
    addpath([verasonicsDir '/ImageProcToolkit']);
    addpath([verasonicsDir '/-save_routines/']);
    
function initBmode(hObject,handles)
    axes(handles.bModeAxes);
    bMode = getBmode(hObject,handles);
    handles = guidata(hObject);
    handles.bModeImg = ...
        imagesc(handles.data.latAxis*1e3,...
            handles.data.axAxis*1e3,...
            bMode,[-60 0]);
    colormap gray
    colorbar
    title('B Mode');
    xlabel('mm');
    ylabel('mm');
    guidata(hObject,handles);
        
function updateBmode(hObject,handles)
    bMode = getBmode(hObject,handles);
    set(handles.bModeImg,'CData',bMode);
    guidata(hObject,handles);
    
function initDoppler(hObject,handles)
    axes(handles.dopplerAxes);
    dop = getDoppler(hObject,handles);
            
    handles.dopplerImg = imagesc(handles.data.latAxis*1e3,...
        handles.data.axAxis*1e3,...
        dop.Data,dop.Range);
    dopColorbar = colorbar(handles.dopplerAxes,'Tag','dopColorbar');
    
    % Underlay the bmode image
    bMode = getBmode(hObject,handles);
%     getPowerDoppler(hObject,handles);
    pdi = getPowerDoppler(hObject,handles);
    handles = guidata(hObject);
    mask = pdi>max(pdi(:))*1e-3;
    hUnderlay=underlayImg(handles.dopplerAxes,bMode,...
        mask,[-60 0]);
    set(hUnderlay,'Tag','dopUnderlayAxes');
    updateDoppler(hObject,handles);
    linkaxes([handles.bModeAxes handles.dopplerAxes hUnderlay],'xy')
%     axis([handles.bModeAxes,handles.dopplerAxes hUnderlay],'square');

    handles = guidata(hObject);
    guidata(hObject,handles);

function dop = getDoppler(hObject,handles)
    switch handles.dopMode
        case 'PDI'
            dop.Data = 10*log10(getPowerDoppler(hObject,handles));
            handles = guidata(hObject);
            dop.Range = [-30 0] + max(dop.Data(:));
            dop.Title = 'Power Doppler';
            dop.ColorbarTitle = 'dB';
            dop.Colormap = hot(256);
            guidata(hObject,handles);
        case 'CFD'
            dop.Data = 1e3*getColorFlow(hObject,handles);
            handles = guidata(hObject);
            dop.Data = dop.Data(:,:,handles.data.frameNum);
            dop.Range = 1e3*freq2Vel(getFrameRate(hObject,handles)/2,...
                handles.data.freq,handles.data.soundSpeed)*[-1 1];
            dop.Title = 'Color Flow';
            dop.ColorbarTitle = 'mm';
            dop.Colormap = dopMap(256);
            guidata(hObject,handles);
            
        otherwise 
            error('Unsupported Doppler Mode: %s',handles.dopMode);
    end

function cfd = getColorFlow(hObject,handles)
    cfd = NaN;
    if ~isfield(handles.data.cfd,'vel')
        switch handles.data.cfd.mode
            case 'lagOneEst'
                iq = getFilteredIQ(hObject,handles);
                handles = guidata(hObject);
                cfd = lagOneEst(iq(:,:,:),...
                    diff(handles.data.timeAxis(1:2)),...
                    handles.data.freq,...
                    handles.data.cfd.windowLength,...
                    handles.data.soundSpeed);
                handles.data.cfd.vel = cfd;
                guidata(hObject,handles);
            otherwise
                error('Unsupported Doppler Mode: %s',handles.data.cfd.mode);
        end
    else
        cfd = handles.data.cfd.vel;
    end

function updateDoppler(hObject,handles)
    
    dop = getDoppler(hObject,handles);
    handles = guidata(hObject);
    
    guidata(hObject,handles);
    set(handles.dopplerImg,'CData',dop.Data)
    
    pdi = getPowerDoppler(hObject,handles);
    handles = guidata(hObject);
    
    mask = pdi>max(pdi(:))*1e-3;
    set(handles.dopplerImg,'AlphaData',mask);
    
    title(handles.dopplerAxes,dop.Title)
    set(handles.dopplerAxes,'CLim',dop.Range);
    xlabel(handles.dopplerAxes,'mm'); ylabel(handles.dopplerAxes,'mm');
    colormap(handles.dopplerAxes,dop.Colormap)
    dopColorbar = findobj(handles.figure1,'Tag','dopColorbar');
    title(dopColorbar, dop.ColorbarTitle);
    
    %% Turn titles back on
    set(findall(handles.dopplerAxes,'type','text'),'visible','on');
    
    %% Update Underlay
    underlayAxis = findall(gcf,'Tag','dopUnderlayAxes');
    underlayImg = findall(underlayAxis,'Type','Image');
    set(underlayImg,'CData',getFilteredBmode(hObject,handles));
    
function buildTimeAxis(hObject,handles)
    switch handles.data.compMode
    case 'HRI'
        dt = 1/handles.data.AP.PRF1;
        dt = dt*size(handles.data.IQ,3);
        handles.data.timeAxis = 0:size(handles.data.IQ,4)-1;
        handles.data.timeAxis = handles.data.timeAxis*dt;
    case 'LRI'
        dt = 1/handles.data.AP.PRF1;
        handles.data.timeAxis = ...
            0:(size(handles.data.IQ,3)*size(handles.data.IQ,4))-1;
        handles.data.timeAxis = handles.data.timeAxis*dt;
    otherwise
        error('Unsupported Compounding String: %s', handles.data.compMode);
    end
    guidata(hObject,handles);

function handles = refreshDerivedData(hObject,handles)
    handles.data = clearField(handles.data,'pdi');
    handles.data = clearField(handles.data,'filtIQ');
    handles.data.cfd = clearField(handles.data.cfd,'vel');
    
    function struct = clearField(struct,field)
        if isfield(struct,field)
            struct = rmfield(struct,field);
        end
            
%% UI Control functions


% --- Outputs from this function are returned to the command line.
function varargout = DopTool_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.data;

% --- Executes on slider movement.
function frameSlider_Callback(hObject, eventdata, handles)
% hObject    handle to frameSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles.data.frameNum = round(get(hObject,'Value'));
set(handles.frameEdit,'string',num2str(handles.data.frameNum));
guidata(hObject,handles);
updateBmode(hObject,handles);
updateDoppler(hObject,handles);

function frameNum = checkFrameNum(hObject,handles,frameNum)
if isempty(frameNum)
    warning('Invalid frame. Resetting to previous');
    frameNum = handles.data.frameNum;
end
maxVal = get(handles.frameSlider,'max');
minVal = get(handles.frameSlider,'min');
if frameNum > maxVal
    warning('Frame out of bounds. Setting to max.')
    frameNum = maxVal;
elseif frameNum < minVal
    warning('Frame out of bounds. Setting to min.')
    frameNum = minVal;
end

% --- Executes during object creation, after setting all properties.
function frameSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frameSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

set(hObject,'Value',1);

function frameEdit_Callback(hObject, eventdata, handles)
% hObject    handle to frameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of frameEdit as text
%        str2double(get(hObject,'String')) returns contents of frameEdit as a double

frameNum = round(str2num(get(hObject,'string')));
frameNum = checkFrameNum(hObject,handles,frameNum);
handles.data.frameNum = frameNum;
set(handles.frameSlider,'value',handles.data.frameNum);
set(hObject,'string',num2str(frameNum));
guidata(hObject,handles);
frameSlider_Callback(handles.frameSlider,eventdata,handles);

% --- Executes during object creation, after setting all properties.
function frameEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in playButton.
function playButton_Callback(hObject, eventdata, handles)
% hObject    handle to playButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on selection change in dopModeMenu.
function dopModeMenu_Callback(hObject, eventdata, handles)
% hObject    handle to dopModeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns dopModeMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from dopModeMenu
contents = cellstr(get(hObject,'String'));
handles.dopMode = contents{get(hObject,'Value')};
guidata(hObject,handles);
% handles = refreshDerivedData(hObject,handles);
updateDoppler(hObject,handles);
handles = guidata(hObject);
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function dopModeMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dopModeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
contents = get(hObject,'String');
handles.dopMode = contents{get(hObject,'Value')};
guidata(hObject,handles);

% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function loadFileMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to loadFileMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% Spawn fileBrowser
[filename,filepath] = uigetfile('*IQSum_G.mat');

%% Sanity Checks
filefullpath = [filepath filename];
assert(exist(filefullpath,'file')==2,'File nonexistant: %s',filefullpath);

%% Generate Names structure for file loading
Names=File_Paths(1,mfilename); 
Names.DataPath = [filepath '/'];
Names.DataFileName = filename(1:end-4); % strip off '.mat'
Names.IQSum_addon = '';

%% load metadata
varList = {'AP','XT','Trans','Resource'};

%% Check for numFrames & preserve certain fields
if ~isfield(handles.data,'numFrames')
    numFrames = Inf;
else
    numFrames = handles.data.numFrames;
end
compMode = handles.data.compMode;
clutterFiltCutoff = handles.data.clutterFilt.cutoff;

%% Load data
handles.data = load(filefullpath,varList{:});

%% Copy metadata to field handles
handles.data.numFrames = numFrames;
handles.data.compMode = compMode;
handles.data.clutterFilt.cutoff = clutterFiltCutoff;
handles.data.cfd.mode = 'lagOneEst';
handles.data.cfd.windowLength = 31;
handles.data.freq = handles.data.Trans.frequency*1e6;
handles.data.soundSpeed = handles.data.Resource.Parameters.speedOfSound;

%% Build estimatorMenu
buildEstimatorMenu(hObject,handles);

%% Clear redundant data
guidata(hObject,handles);

%% Load IQData
hMsg = msgbox('Loading Data. This might take several minutes','Loading Data');
iqCell = PopulateIQDataChunks(handles.data.AP,...
    handles.data.XT,...
    Names,...
    handles.data.numFrames);
% Third buffer corresponds to high frame rate buffer.
channelBuffer = 3;
handles.data.IQ = single(iqCell{channelBuffer});
close(hMsg);

%% Compute axes
[handles.data.latAxis, handles.data.axAxis] ...
    = computeAxes(handles.data.AP,...
    handles.data.Trans,...
    channelBuffer,...
    handles.data.IQ);
guidata(hObject,handles);
buildTimeAxis(hObject,handles);
handles = guidata(hObject);
 
%% Apply TGC
TGC = handles.data.axAxis(:);
TGC = TGC/TGC(1)/1e3;
handles.data.TGC = TGC;
TGC = reshape(TGC,[],1);
handles.data.IQ = bsxfun(@times,handles.data.IQ,TGC);
guidata(hObject,handles);

%% Initialize bMode image
initBmode(hObject,handles);
handles = guidata(hObject);
initDoppler(hObject,handles);
handles = guidata(hObject);

%% Initialize UI
initSlider(hObject,handles);

% --------------------------------------------------------------------
function initSlider(hObject,handles)
%% Update slider values
switch handles.data.compMode
    case 'HRI'
        range = size(handles.data.IQ,4);
    case 'LRI'
        range = size(handles.data.IQ,3)*size(handles.data.IQ,4);
    otherwise
        error('Unsupported Compounding String: %s', handles.data.compMode);
end

set(handles.frameSlider,'Min',1);
set(handles.frameSlider,'Max',range);
set(handles.frameSlider,'Value',handles.data.frameNum);
set(handles.frameSlider,'SliderStep',[1 max(floor(floor(0.05*range)/10)*10,1)]/(range));
guidata(hObject,handles);

% --------------------------------------------------------------------
function saveDataMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to saveDataMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on selection change in compoundingPopUp.
function compoundingPopUp_Callback(hObject, eventdata, handles)
% hObject    handle to compoundingPopUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns compoundingPopUp contents as cell array
%        contents{get(hObject,'Value')} returns selected item from compoundingPopUp

contents = cellstr(get(hObject,'String'));
handles.data.compMode = contents{get(hObject,'Value')};
% Get old timeAxis and frameNum for recomputation.
time = handles.data.timeAxis;
frameTime = time(handles.data.frameNum);

% Rebuild the timeAxis to account for new compounding scheme
buildTimeAxis(hObject,handles);
handles = guidata(hObject);

% Set frame to closest time instance
handles.data.frameNum = closestInd(handles.data.timeAxis,frameTime);
guidata(hObject,handles);

% Reinitialize slider to reset boundary values
initSlider(hObject,handles); 
handles = guidata(hObject);

% Update frame edit box to reflect new value
set(handles.frameEdit,'value',handles.data.frameNum);
guidata(hObject,handles);

% Clear the pdi to force update
handles = refreshDerivedData(hObject,handles);
guidata(hObject,handles);

% Update images and syncronize data
updateBmode(hObject,handles);
handles = guidata(hObject);
updateDoppler(hObject,handles);
handles = guidata(hObject);
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function compoundingPopUp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to compoundingPopUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
compModes = cellstr(get(hObject,'String'));
handles.data.compMode = compModes{1};
guidata(hObject,handles);


% --- Executes on selection change in clutterFiltMenu.
function clutterFiltMenu_Callback(hObject, eventdata, handles)
% hObject    handle to clutterFiltMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns clutterFiltMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from clutterFiltMenu

supportedModes = {'clutterFiltSimple','clutterFiltMatchedTx'};
contents = cellstr(get(hObject,'String'));
value = contents{get(hObject,'Value')};
handles = refreshDerivedData(hObject,handles);
switch value
    case 'clutterFiltSimple'
        handles.clutterFiltMode = value;
    case 'clutterFiltMatchedTx'
        handles.clutterFiltMode = value;
    otherwise
        error('Unsupported Mode: %s',value);
        handles.clutterFiltMode = 'Error';
end
updateDoppler(hObject,handles);
handles = guidata(hObject);
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function clutterFiltMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to clutterFiltMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in spectrogramButton.
function spectrogramButton_Callback(hObject, eventdata, handles)
% hObject    handle to spectrogramButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iq = getFilteredIQ(hObject,handles);
spectrogramTool(iq(:,:,:),...
    @(x) clip(iq2bMode(x),[-60 0]));


    function out = clip(data,range)
        out = min(max(data,range(1)),range(2));


% --- Executes on selection change in estimatorMenu.
function estimatorMenu_Callback(hObject, eventdata, handles)
% hObject    handle to estimatorMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns estimatorMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from estimatorMenu
contents = cellstr(get(hObject,'String'));
value = contents{get(hObject,'Value')};
switch value
    case 'lagOneEst'
        handles.data.cfd.mode = value;
    otherwise
        set(hObject,'Value',1);
        error('Unsupported Estimator: %s. Reverting to default.',value);
end

% --- Executes during object creation, after setting all properties.
function estimatorMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to estimatorMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function buildEstimatorMenu(hObject,handles)
contents = {'lagOneEst'};
if handles.data.AP.doubleTx
    contents = [contents;{'lagOneEstPairwise'}];
end
set(handles.estimatorMenu,'String',contents);
guidata(hObject,handles);

