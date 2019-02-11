function varargout = spectralAnalyzer(varargin)
% SPECTRALANALYZER MATLAB code for spectralAnalyzer.fig
%      SPECTRALANALYZER, by itself, creates a new SPECTRALANALYZER or raises the existing
%      singleton*.
%
%      H = SPECTRALANALYZER returns the handle to a new SPECTRALANALYZER or the handle to
%      the existing singleton*.
%
%      SPECTRALANALYZER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SPECTRALANALYZER.M with the given input arguments.
%
%      SPECTRALANALYZER('Property','Value',...) creates a new SPECTRALANALYZER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before spectralAnalyzer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to spectralAnalyzer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help spectralAnalyzer

% Last Modified by GUIDE v2.5 05-Jun-2018 15:34:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @spectralAnalyzer_OpeningFcn, ...
                   'gui_OutputFcn',  @spectralAnalyzer_OutputFcn, ...
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


% --- Executes just before spectralAnalyzer is made visible.
function spectralAnalyzer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to spectralAnalyzer (see VARARGIN)

% Choose default command line output for spectralAnalyzer
handles.output = hObject;

switch length(varargin)
    case 0 
        handles.data = randn(10,11);
    case 1
        handles.data = varargin{1};
    otherwise
        error('Unsupported Number of Arguments: %1.0f',length(varargin))
end

handles = initData(handles,varargin);
handles = initGuiElements(hObject,handles);
handles = updateGui(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes spectralAnalyzer wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = spectralAnalyzer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%% Utility functions
% Any function that does not depend on any local variables
function list = vcolon(vec)
assert(length(vec)==2,'vcolon: Illegal input length: %1.0f',length(vec))
list = vec(1):vec(2);

function z = fftzero(n)
% returns the location of the DC bin after fftshift for length n seq.
z = ceil((n+1)/2);

function b = inrange(vals,valrange)
assert(length(valrange) == 2, 'Invalid length to valrange: %1.0f',...
    length(valrange));
valrange = sort(valrange);
b = (vals >= valrange(1)) & (vals <= valrange(2));

function out = clip(x,valrange)
assert(length(valrange) == 2, 'Invalid length to valrange: %1.0f',...
    length(valrange));
valrange = sort(valrange);
out = min(max(x,valrange(1)),valrange(2));
%% Constructors

function handles = initData(handles,varargin)
handles.roi.center(1) = mean([1 size(handles.data,1)]);
handles.roi.center(2) = mean([1 size(handles.data,2)]);
handles.roi.center = floor(handles.roi.center);
handles.roi.dims = size(handles.data);
handles.roi.dims = handles.roi.dims + mod(handles.roi.dims,2)-1;
handles.roi.bounds = handles.roi.center - floor(handles.roi.dims/2) ;
handles.roi.bounds(end+1,:) = handles.roi.center + floor(handles.roi.dims/2);
handles.stepSize = [1 1];

function handles = initGuiElements(hObject,handles)

% dataAxes
axes(handles.dataAxes);
handles.dataImg = imagesc(1:size(handles.data,2),1:size(handles.data,1),...
    handles.data);
handles.dataColorbar = colorbar;
set(handles.dataAxes,'Color','green');
colormap gray;
% xlim auto
% ylim auto
set(handles.dataImg,'AlphaData',~getSpectralBorder(handles));
set(handles.dataAxes,'ButtonDownFcn',@dataAxes_ButtonDownFcn);
set(handles.dataImg,'HitTest','off') % pass click to axes callback.

% spectAxes
axes(handles.spectAxes)
render = @(x) 20*log10(abs(x));
spect = getSpectrum(handles);
stepSize = getStep(handles);
len = stepSize.*size(getRoi(handles));
fftAx = ((1:size(spect,1))-fftzero(size(spect,1)))/len(1); 
fftLat = ((1:size(spect,2))-fftzero(size(spect,2)))/len(2);
handles.spectImg = imagesc(fftLat,fftAx,render(spect));
caxis(max(handles.spectImg.CData(:))+[-60 0]);
colormap gray
handles.spectColorbar = colorbar;
handles.spectAxes.XLimMode = 'auto';
handles.spectAxes.YLimMode = 'auto';


%% High level functions
function handles = renderSpectrum(hObject,handles)
spect = getSpectrum(handles);    
handles.spectImg.CData = 20*log10(abs(spect));
stepSize = getStep(handles);
len = stepSize.*size(getRoi(handles));
handles.spectImg.YData = ((1:size(spect,1))-fftzero(size(spect,1)))/len(1); 
handles.spectImg.XData = ((1:size(spect,2))-fftzero(size(spect,2)))/len(2);

function handles = updateGui(handles)
% ROI
center = getRoiCenter(handles);
dims = getRoiWidth(handles);

handles.roiTable.Data{1,2} = center(2); % Center (lat)
handles.roiTable.Data{2,2} = center(1); % Center (ax)
handles.roiTable.Data{3,2} = dims(2);   % Width
handles.roiTable.Data{4,2} = dims(1);   % Height
% Figure
% Axes
set(handles.dataImg,'AlphaData',~getSpectralBorder(handles));
stepSize = getStep(handles);

axes(handles.dataAxes);
set(handles.dataImg,'XData',(1:size(handles.data,2))*stepSize(2));
set(handles.dataImg,'YData',(1:size(handles.data,1))*stepSize(1));

xlim([1 size(handles.data,2)]*stepSize(2)+0.5*stepSize(2)*[-1 1]); % correct for weird xLim);
ylim([1 size(handles.data,1)]*stepSize(1)+0.5*stepSize(1)*[-1 1]); % correct for weird yLim);

%% Getters
function bounds = getRoiBounds(handles)
bounds = bsxfun(@plus,handles.roi.center,...
    [-1; 1]*floor(handles.roi.dims/2));

function bounds = getClippedRoiBounds(handles)
bounds = getRoiBounds(handles);
bounds(1,:) = max(bounds(1,:),1);
bounds(2,:) = min(bounds(2,:),size(handles.data));

function center = getRoiCenter(handles)
center = handles.roi.center;

function roi = getRoi(handles)
bounds = getRoiBounds(handles);
cBounds = getClippedRoiBounds(handles);
roiCoord = bounds(1,:)-1;
roi = zeros(handles.roi.dims);
roiAxInd = vcolon(cBounds(:,1))-roiCoord(1);
roiLatInd = vcolon(cBounds(:,2))-roiCoord(2);
roi(roiAxInd,roiLatInd) = handles.data(vcolon(cBounds(:,1)),vcolon(cBounds(:,2)));

function dims = getRoiWidth(handles)
dims = handles.roi.dims;

function border = getSpectralBorder(handles)
border = zeros(size(handles.data));

% Uses difference inclusive and exclusive roi to generate border
bounds = getClippedRoiBounds(handles);

h2 = handles;
h2.roi.dims = h2.roi.dims-[2 2];
innerBounds = getClippedRoiBounds(h2);

% clip to edges
bounds(1,:) = max(bounds(1,:),1);
bounds(2,:) = min(bounds(2,:),size(border));

innerBounds(1,:) = max(innerBounds(1,:),1);
innerBounds(2,:) = min(innerBounds(2,:),size(border));

border(vcolon(bounds(:,1)),vcolon(bounds(:,2)))=1;
border(vcolon(innerBounds(:,1)),vcolon(innerBounds(:,2))) = 0;

function spect = getSpectrum(handles)
spect = fftshift(fft2(getRoi(handles)));

function stepSize = getStep(handles)
stepSize = handles.stepSize;

%% Setters
function handles = setRoiCenter(handles,center)
latBounds = [1 size(handles.data,2)];
axBounds =  [1 size(handles.data,1)];
handles.roi.center(1) = clip(center(1), latBounds);
handles.roi.center(2) = clip(center(2), axBounds);

function handles = setRoiWidth(handles, dims)
% dims = [height, width]
% Force odd length
dims = 2*floor(dims/2)+1;
center = getRoiCenter(handles);
bounds = [-floor(dims/2); floor(dims/2)];
handles.roi.bounds = [center;center] + bounds;
handles.roi.dims = dims;

function handles = setStep(handles,stepSize)
handles.stepSize = stepSize;

%% Callbacks

% --- Executes when entered data in editable cell(s) in roiTable.
function roiTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to roiTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
fieldName = hObject.Data{eventdata.Indices(1),1};
switch fieldName
    case 'Center (lat)'
        center = getRoiCenter(handles);
        center(2) = eventdata.NewData;
        handles = setRoiCenter(handles,center);
        center = getRoiCenter(handles);
        hObject.Data{eventdata.Indices(1),eventdata.Indices(2)} = center(2);
    case 'Center (ax)'
        center = getRoiCenter(handles);
        center(1) = eventdata.NewData;
        handles = setRoiCenter(handles,center);
        center = getRoiCenter(handles);
        hObject.Data{eventdata.Indices(1),eventdata.Indices(2)} = center(1);
    case 'Width'
        dims = getRoiWidth(handles);
        dims(2) = eventdata.NewData;
        handles = setRoiWidth(handles,dims);
    case 'Height'
        dims = getRoiWidth(handles);
        dims(1) = eventdata.NewData;
        handles = setRoiWidth(handles,dims);
    otherwise 
        hObject.Data{eventdata.Indices(1),eventdata.Indices(2)} ...
            = eventdata.PreviousData;
end
handles = updateGui(handles);

handles = renderSpectrum(hObject,handles);
guidata(hObject,handles);


% --- Executes on mouse press over axes background.
function dataAxes_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to dataAxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%hAxes = get(hObject,'Parent');
%coordinates = get(hAxes,'CurrentPoint'); 
coordinates = get(hObject,'CurrentPoint');
coordinates = round(fliplr(coordinates(1,1:2)))
handles = guidata(hObject);
handles = setRoiCenter(handles,coordinates);
handles = updateGui(handles);
handles = renderSpectrum(hObject,handles);
guidata(hObject,handles);


% --- Executes when entered data in editable cell(s) in figTable.
function figTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to figTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
fieldName = hObject.Data{eventdata.Indices(1),1};
switch fieldName
    case 'Lat. Step'
        stepSize = getStep(handles);
        stepSize(2) = eventdata.NewData;
        handles = setStep(handles,stepSize);
        stepSize = getStep(handles);
        %hObject.Data{eventdata.Indices(1),eventdata.Indices(2)} = center(2);
    case 'Ax. Step'
        stepSize = getStep(handles);
        stepSize(1) = eventdata.NewData;
        handles = setStep(handles,stepSize);
        stepSize = getStep(handles);
        hObject.Data{eventdata.Indices(1),eventdata.Indices(2)} = center(1);
    case 'CAxis Min'
    case 'CAxis Max'
    otherwise 
        hObject.Data{eventdata.Indices(1),eventdata.Indices(2)} ...
            = eventdata.PreviousData;
end
handles = updateGui(handles);

handles = renderSpectrum(hObject,handles);
guidata(hObject,handles);