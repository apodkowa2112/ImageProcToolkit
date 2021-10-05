function varargout = imgShifter(varargin)
% Simple GUI tool to visually align two images by simple translation.
%% Requirements:
% Image processing toolbox
%% Inputs:
% First image: moving; Second image: stationary
% Both images must be of type supported by imshowpair.m
%% Usage:
% Usage: imgShifter(movingImg,staticImg)
% Supports translation input through on-screen arrows, keyboard arrow keys,
% or manual entry in displayed text fields
%
% This file was forked from David A. Scaduto's imgShifter from the
% Mathworks file exchange
% https://www.mathworks.com/matlabcentral/fileexchange/55649-imgshifter?s_tid=srchtitle
% 
%% Version History
% 1.0   DAS    02/2016  Development
% 1.1   ASP    10/2021  Rotational registration & WASDEQ control

% 
%%
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @imgShifter_OpeningFcn, ...
                   'gui_OutputFcn',  @imgShifter_OutputFcn, ...
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


% --- Executes just before imgShifter is made visible.
function imgShifter_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to imgShifter (see VARARGIN)

global img_static
global img_moving

% Choose default command line output for imgShifter
handles.output = hObject;
set(handles.disp_xoff,'String',0);
set(handles.disp_yoff,'String',0);
set(handles.disp_theta,'String',0);

img_moving = varargin{1};
img_static = varargin{2};

axes(handles.img_axes); 
imshowpair(img_static,img_moving);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes imgShifter wait for user response (see UIRESUME)
% uiwait(handles.imgShifterFig);

% --- Outputs from this function are returned to the command line.
function varargout = imgShifter_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function shift_image(hObject, eventdata, handles, shift_var)
global img_static
global img_moving
global img_translated

x_off = str2double(get(handles.disp_xoff,'String')) + shift_var(1);
set(handles.disp_xoff,'String',num2str(x_off));

y_off = str2double(get(handles.disp_yoff,'String')) + shift_var(2);
set(handles.disp_yoff,'String',num2str(y_off));

img_translated = imtranslate(img_moving,[x_off y_off]);
axes(handles.img_axes); 

disp_method = get(handles.disp_opt_diff,'Value');
switch disp_method
    case{0}, % Blend option
        imshowpair(img_static,img_translated);
    case{1}, % Diff image
        imshowpair(img_static,img_translated,'diff');
end

function rotate_image(hObject, eventdata, handles, dtheta)
global img_static
global img_moving
global img_translated

theta = str2double(get(handles.disp_theta,'String'))+dtheta;
set(handles.disp_theta,'String',num2str(theta));
img_translated = imrotate(img_moving,theta,'bicubic','crop');
axes(handles.img_axes); 

disp_method = get(handles.disp_opt_diff,'Value');
switch disp_method
    case{0}, % Blend option
        imshowpair(img_static,img_translated);
    case{1}, % Diff image
        imshowpair(img_static,img_translated,'diff');
end


% --- Executes on button press in button_up.
function button_up_Callback(hObject, eventdata, handles)
% hObject    handle to button_up (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

shift_image(hObject, eventdata, handles, [0 -1]);

% --- Executes on button press in button_down.
function button_down_Callback(hObject, eventdata, handles)
% hObject    handle to button_down (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

shift_image(hObject, eventdata, handles, [0 1]);

% --- Executes on button press in button_right.
function button_right_Callback(hObject, eventdata, handles)
% hObject    handle to button_right (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

shift_image(hObject, eventdata, handles, [1 0]);

% --- Executes on button press in button_left.
function button_left_Callback(hObject, eventdata, handles)
% hObject    handle to button_left (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

shift_image(hObject, eventdata, handles, [-1 0]);

% --- Executes on button press in button_ccw.
function button_cclockwise_Callback(hObject, eventdata, handles)
% hObject    handle to button_left (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

rotate_image(hObject, eventdata, handles, -0.1);

function button_clockwise_Callback(hObject, eventdata, handles)
% hObject    handle to button_left (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

rotate_image(hObject, eventdata, handles, 0.1);

function disp_xoff_Callback(hObject, eventdata, handles)
% hObject    handle to disp_xoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of disp_xoff as text
%        str2double(get(hObject,'String')) returns contents of disp_xoff as a double

shift_image(hObject, eventdata, handles, [0 0]);

% --- Executes during object creation, after setting all properties.
function disp_xoff_CreateFcn(hObject, eventdata, handles)
% hObject    handle to disp_xoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function disp_yoff_Callback(hObject, eventdata, handles)
% hObject    handle to disp_yoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of disp_yoff as text
%        str2double(get(hObject,'String')) returns contents of disp_yoff as a double

shift_image(hObject, eventdata, handles, [0 0]);

% --- Executes during object creation, after setting all properties.
function disp_yoff_CreateFcn(hObject, eventdata, handles)
% hObject    handle to disp_yoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on key press with focus on imgShifterFig or any of its controls.
function imgShifterFig_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to imgShifterFig (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

switch eventdata.Key
    case{'uparrow'},    button_up_Callback(hObject, eventdata, handles);
    case{'w'},          button_up_Callback(hObject, eventdata, handles);
    case{'downarrow'},  button_down_Callback(hObject, eventdata, handles);
    case{'s'},          button_down_Callback(hObject, eventdata, handles);
    case{'rightarrow'}, button_right_Callback(hObject, eventdata, handles);
    case{'d'},          button_right_Callback(hObject, eventdata, handles);
    case{'leftarrow'},  button_left_Callback(hObject, eventdata, handles);
    case{'a'},          button_left_Callback(hObject, eventdata, handles);
    % Rotation
    case{'q'},          button_cclockwise_Callback(hObject, eventdata, handles);
    case{'e'},          button_clockwise_Callback(hObject, eventdata, handles);
end

% --- Executes when selected object is changed in disp_mode_group.
function disp_mode_group_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in disp_mode_group 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global img_static
global img_translated

disp_method = get(handles.disp_opt_diff,'Value');
switch disp_method
    case{0}, % Blend option
        imshowpair(img_static,img_translated);
    case{1}, % Diff image
        imshowpair(img_static,img_translated,'diff');
end

function disp_theta_Callback(hObject, eventdata, handles)
% hObject    handle to disp_theta (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of disp_theta as text
%        str2double(get(hObject,'String')) returns contents of disp_theta as a double
rotate_image(hObject, eventdata, handles, 0);

% --- Executes during object creation, after setting all properties.
function disp_theta_CreateFcn(hObject, eventdata, handles)
% hObject    handle to disp_theta (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% David A. Scaduto
% david.scaduto@stonybrook.edu
% www.davidscaduto.com
%
% Copyright (c) 2016, David Scaduto
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.
