function varargout = spectrogramTool(varargin)
% SPECTROGRAMTOOL Browse spectrograms of a 3D matrix

%% Initialization
switch length(varargin)
    case 1
        matData = varargin{1};
        renderFunc = @(x) x;
    case 2
        % lineBrowser(mat, funcHandle)
        matData = varargin{1};
        renderFunc = varargin{2};
        assert(nargin(renderFunc)==1,'Only one argument to renderFunc supported.');
    otherwise
        error('Error: Unsupported Number of Arguments')
end
slice = 1;
spectCoord = ceil([size(matData,2) size(matData,1)]/2);
spect.segLength = ceil(size(matData,3)/8);
spect.noverlap = spect.segLength-1;
spect.nfft = 2^(nextpow2(spect.segLength)+1);

%% Constructors
% figure
hMainFigure = figure('Name',mfilename,...
    'Toolbar','figure'...
    );%,'Visible','off');

% Generate axes
hImageAxes = subplot(3,1,[1 2]);
set(hImageAxes,'Tag', 'hImageAxes');
colormap(hImageAxes,gray);

hSpectAxes = subplot(3,1,3);
set(hSpectAxes,'Tag', 'hSpectAxes');
% grid(hLineAxes,'on');

% Generate pointer for mouse click action
hImagePointer = spectCoord;

%% Component initialization
% hToolPanel
hToolPanel = uipanel(hMainFigure,'Title','Tools');
set(hToolPanel,'Units', get(hImageAxes,'Units'));

imAxPos = get(hImageAxes,'Position');
spectAxPos = get(hSpectAxes,'Position');
tpPos = [0 0 0.2,sum(imAxPos([2 4]))-spectAxPos(2)];
set(hToolPanel,'Position',tpPos);
set(hToolPanel,'Units', get(hSpectAxes,'Units'));

spectAxPos(3) = spectAxPos(3)-1.1*tpPos(3);
imAxPos(3) = spectAxPos(3);
tpPos(1) = sum(spectAxPos([1 3]))...
    +0.1*tpPos(3);
tpPos(2) = spectAxPos(2);

% Set
set(hToolPanel,'Position',tpPos);
set(hSpectAxes,'Position',spectAxPos);
set(hImageAxes,'Position',imAxPos);


% lineDirButton
% lineDirButton = uicontrol('Style','pushbutton','Parent',hToolPanel,...
%     'String',lineDir,'ToolTip','Line Direction',...
%     'Callback',@lineDirButton_callback...
%     ,'Units','normalized');
% lineDirButton.Position(2) = 0.9;

%% Start GUI
axes(hImageAxes)
hImg = imagesc(renderFunc(matData(:,:,slice)));
colorbar
colormap gray;
set(hImg,'ButtonDownFcn',@ImageClickCallback);
xLine = line((spectCoord(1))*[1 1],[1 size(matData,1)]...
    ,'Color','g','LineWidth',3);
yLine = line([1 size(matData,2)],(spectCoord(2))*[1 1]...
    ,'Color','g','LineWidth',3);


axes(hSpectAxes);
sg = normZero(mag2db(abs(spectrogram(...
    squeeze(matData(spectCoord(2),spectCoord(1),:))...
    ,spect.segLength,spect.noverlap,spect.nfft,'yaxis','centered'))));
hSpectrogram = imagesc([1 size(sg,2)], [-1 1], sg); caxis([-40 0]);
axis('xy');
colormap gray;
tLine = line(slice*[1 1],get(hSpectrogram,'YData'),'Color','g','LineWidth',3);
set(hSpectrogram,'ButtonDownFcn',@SpectClickCallback);
updatePlots;
set(hMainFigure,'Visible','on');

%% Callbacks
%     function lineDirButton_callback(hObject,eventdata)
%        toggleDirection;
%        updatePlots;
%     end

    function ImageClickCallback ( objectHandle , eventData )
        axesHandle  = get(objectHandle,'Parent');
        coordinates = get(axesHandle,'CurrentPoint'); 
        coordinates = coordinates(1,1:2);
        hImagePointer = coordinates;
        updatePlots;
    end

    function SpectClickCallback( objectHandle , eventData )
        axesHandle  = get(objectHandle,'Parent');
        coordinates = get(axesHandle,'CurrentPoint'); 
        coordinates = coordinates(1,1:2);
        slice = findClosest(1:max(get(hSpectrogram,'XData')),...
            coordinates(1));
        set(tLine, 'XData', slice*[1 1]);
        updatePlots;
        
    end

%% Utility functions
    function updatePlots
        figure(hMainFigure)
%         axes(hImageAxes)
        
        set(hImg,'CData', renderFunc(matData(:,:,slice)));
        
        % calculate axes
        [xData, yData, cData] = getimage(hImg);
        dx = diff(xData)/(size(cData,2)-1);
        dy = diff(yData)/(size(cData,1)-1);
        xAxis = xData(1):dx:xData(2);
        yAxis = yData(1):dy:yData(2);
        assert(isequal(length(xAxis),size(cData,2)),'Error: Bad xAxis length');
        assert(isequal(length(yAxis),size(cData,1)),'Error: Bad yAxis length');
        
        [~,spectCoord(1)] = findClosest(xAxis,hImagePointer(1));
        set(xLine, 'XData', xAxis(spectCoord(1))*[1 1]);


        [~,spectCoord(2)] = findClosest(yAxis,hImagePointer(2));
        set(yLine, 'YData', yAxis(spectCoord(2))*[1 1]);

        sg = normZero(mag2db(abs(spectrogram(...
            squeeze(matData(spectCoord(2),spectCoord(1),:))...
            ,spect.segLength,spect.noverlap,spect.nfft,'yaxis','centered'))));
        set(hSpectrogram,'CData',sg);
        ylabel(hSpectAxes,'Freq.')
        xlabel(hSpectAxes,'Time.')
        
        % Reset Tags on figure update
        set(hImageAxes,'Tag', 'hImageAxes');
        set(hSpectAxes,'Tag',  'hSpectAxes');
    end

%     function toggleDirection
%         if isequal(lineDir,'Vertical')
%             lineDir = 'Horizontal';
%         else 
%             lineDir = 'Vertical';
%         end
%         lineDirButton.String = lineDir;
%     end

    function [closestMatch,ind] = findClosest(vec,num)
        optFun = abs(vec-num);
        [~,ind] = min(optFun);
        closestMatch = vec(ind);
        assert(length(closestMatch)==1,'Multiple matches found')
    end

    function out = normZero(in)
        out = in-max(in(:));
    end
end