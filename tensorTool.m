function varargout = tensorTool(varargin)
% tensorTool Browse lines in a 3D matrix
% tensorTool(matData)
% tensorTool(matData, funcHandle)
% tensorTool(matData, funcHandle, renderHandle)
%% Initialization
switch length(varargin)
    case 1
        % tensorTool(matData)
        matData = varargin{1};
        lineNumber = 1;
        lineDir = 'Vertical';
    case 2
        % tensorTool(matData, funcHandle)
        matData = varargin{1};
        lineNumber = 1;
        lineDir = 'Vertical';
        renderFunc = varargin{2};
    case 3
        % tensorTool(matData, funcHandle, renderHandle)
        matData = varargin{1};
        lineNumber = 1;
        lineDir = 'Vertical';        
        renderFunc = varargin{2};
        evalFunc = varargin{3};
    otherwise
        error('Error: Unsupported Number of Arguments')
end

if ~exist('renderFunc','var') || isempty(renderFunc)
    renderFunc = @(x) x;
end
assert(nargin(renderFunc)==1,'Only one argument to renderFunc supported.');
if ~exist('evalFunc','var') || isempty(evalFunc)
    evalFunc = @(x) x;
end
assert(nargin(evalFunc)==1,'Only one argument to evalFunc supported.');
        
sliceNumber = 1;
lineData = 0;
directions = {'Vertical','Horizontal'};
if isequal(ndims(matData),3)
    directions = [directions, {'Normal'}];
end

%% Constructors
% figure
hMainFigure = figure('Name','tensorTool',...
    'Toolbar','figure'...
    );%,'Visible','off');

% Generate axes
hUnderlayAxes = subplot(3,1,[1 2],'parent',hMainFigure);
set(hUnderlayAxes,'Tag','hUnderlayAxes');
green = zeros([size(matData,1),size(matData,2),3]); green(:,:,2) =1;
hUnderlayImg = image(green);

hImageAxes = axes('Position',get(hUnderlayAxes,'Position'));

hImageAxes.Tag = 'hImageAxes';
colormap(hImageAxes,gray);

linkaxes([hImageAxes,hUnderlayAxes]);
linkprop([hImageAxes,hUnderlayAxes],{'Position'} );

% subplot clobbers axes, so set the position manually
hLineAxes = axes('Position',[0.13 0.11 0.775 0.15]);
hLineAxes.Tag = 'hLineAxes';
grid(hLineAxes,'on');

% Generate pointer for mouse click action
hPointer = zeros(1,2);

%% Component initialization
% hSlider
if length(directions)==3
    hSlider = uicontrol(hMainFigure,'Style','slider','Min',1,'Max',size(matData,3)...
        ,'Value',sliceNumber,'callback',@hSliderCallback,...
        'Units','normalized','Position',[0.13 0.32,0.48,0.044],...
        'SliderStep',[1/(size(matData,3)-1), max(0.1,1/(size(matData,3)-1))]);
end

% hToolPanel
hToolPanel = uipanel(hMainFigure,'Title','Tools');
hToolPanel.Units = hImageAxes.Units;
hToolPanel.Position = [0 0 0.2,sum(hImageAxes.Position([2 4]))-hLineAxes.Position(2)];
hToolPanel.Units = hLineAxes.Units;

hLineAxes.Position(3)  = hLineAxes.Position(3)-1.1*hToolPanel.Position(3);
hImageAxes.Position(3) = hLineAxes.Position(3);

hToolPanel.Position(1) = sum(hLineAxes.Position([1 3]))...
    +0.1*hToolPanel.Position(3);
hToolPanel.Position(2) = hLineAxes.Position(2);

% lineDirButton
lineDirButton = uicontrol(hMainFigure,'Style','pushbutton','Parent',hToolPanel,...
    'String',lineDir,'ToolTip','Line Direction',...
    'Callback',@lineDirButton_callback...
    ,'Units','normalized');
lineDirButton.Position(2) = 0.9;

% coordTable
coordTable = uitable(hToolPanel,...
    'columnName',{'row','col','slice'},...
    'rowName',[],...
    'ColumnEditable',true(1,3),...
    'ColumnWidth',{35},...
    'data',[hPointer(:)' 1],...
    'CellEditCallback',@coordTableEditCallback,...
    'Units','normalized','Position',[0 0.675 1 0.2]...
    );
coordTable.Position(4) = coordTable.Extent(4);
coordTable.Position(2) = coordTable.Position(2)+coordTable.Extent(4)/2;

% hImg
axes(hImageAxes)      
hImg = imagesc(renderFunc(matData(:,:,sliceNumber)));
colorbar
set(hImg,'ButtonDownFcn',@ImageClickCallback);
set(hImageAxes,'Color','none');

fLineUpdate = 1;
hLine = 0;

%% Start GUI
updatePlots;
hMainFigure.Visible = 'on';

%% Callbacks
    function lineDirButton_callback(hObject,eventdata)
       toggleDirection;
       updatePlots;
    end

    function ImageClickCallback ( objectHandle , eventData )
        axesHandle  = get(objectHandle,'Parent');
        coordinates = get(axesHandle,'CurrentPoint'); 
        coordinates = coordinates(1,1:2);
        hPointer = coordinates;
        updatePlots;
    end

    function hSliderCallback(hObject,eventData)
        value = round(get(hObject,'Value'));
        sliceNumber = value;
        updatePlots;
        
    end
    
    function coordTableEditCallback(hObject,callbackdata)
        % magic from "uitable properties" documentation
        coordinate = eval(callbackdata.EditData);
        row = callbackdata.Indices(1);
        col = callbackdata.Indices(2);
        if col==3
            sliceNumber = min(max(1,round(coordinate)),size(matData,3));
            set(hSlider,'Value',sliceNumber);
        else
            hObject.Data(row,col) = coordinate;
        end
        hPointer = flipud(hObject.Data(1:2)');
        updatePlots;
    end

%% Utility functions
    function updatePlots
        figure(hMainFigure)
        
        %% Render image
%         axes(hImageAxes)      
%         hImg = imagesc(renderFunc(matData(:,:,sliceNumber)));
%         colorbar
%         set(hImg,'ButtonDownFcn',@ImageClickCallback);
%         set(hImageAxes,'Color','none');
        set(hImg,'CData',renderFunc(matData(:,:,sliceNumber)));
        
        %% calculate axes
        [xData, yData, cData] = getimage(hImageAxes);
        dx = diff(xData)/(size(cData,2)-1);
        dy = diff(yData)/(size(cData,1)-1);
        xAxis = xData(1):dx:xData(2);
        yAxis = yData(1):dy:yData(2);
        assert(isequal(length(xAxis),size(cData,2)),'Error: Bad xAxis length');
        assert(isequal(length(yAxis),size(cData,1)),'Error: Bad yAxis length');
        [~,hPointer(1)] = findClosest(xAxis,hPointer(1));
        [~,hPointer(2)] = findClosest(yAxis,hPointer(2));
        set(coordTable,'data',[flipud(hPointer(:))' sliceNumber]);
        switch lineDir
            case 'Vertical'
                [~,lineNumber] = findClosest(xAxis,hPointer(1));
                mask = ones(size(matData(:,:,1))); mask(:,lineNumber)=0;
                hImg.AlphaData = mask;
                axes(hLineAxes)
                lineData = evalFunc(matData(:,lineNumber,sliceNumber));
                if fLineUpdate
                    hLine = plot(yAxis,lineData);
                    grid on;
                    fLineUpdate = 0;
                else % cast to double to avoid bugs with logical datatypes
                    set(hLine,'YData',double(lineData));
                end
                
            case 'Horizontal'
                [~,lineNumber] = findClosest(yAxis,hPointer(2));
                mask = ones(size(matData(:,:,1))); mask(lineNumber,:)=0;
                hImg.AlphaData = mask;
                axes(hLineAxes)
                lineData = evalFunc(matData(lineNumber,:,sliceNumber));
                if fLineUpdate
                    hLine =  plot(xAxis,lineData);
                    grid on;
                    fLineUpdate = 0;
                else
                    set(hLine,'YData',double(lineData));
                    
                end
                
            case 'Normal'
                [~,hPointer(1)] = findClosest(xAxis,hPointer(1));
                [~,hPointer(2)] = findClosest(yAxis,hPointer(2));
                lineNumber = 0;
                mask = ones(size(matData(:,:,1))); 
                mask(:,hPointer(1))=0; mask(hPointer(2),:) = 0;
                
                hImg.AlphaData = mask;
                axes(hLineAxes)
                lineData = evalFunc(squeeze(matData(hPointer(2),hPointer(1),:)));
                hLine = plot(1:size(matData,3),lineData);
                hold on
                plot(sliceNumber,lineData(sliceNumber),'ro');
                hold off
                grid on;
                
            
            otherwise 
                error('Error: Invalid lineDir (%s)',lineDir');
        end
        
        % Reset Tags on figure update
        hImageAxes.Tag = 'hImageAxes';
        hLineAxes.Tag =  'hLineAxes';
    end

    function toggleDirection        
        if any(ismember(directions,lineDir))
            val = mod(find(ismember(directions,lineDir)),length(directions))+1;
            lineDir = directions{val};
        else 
            lineDir = 'Vertical';
        end
        lineDirButton.String = lineDir;
        fLineUpdate = 1;
    end

    function [closestMatch,ind] = findClosest(vec,num)
        optFun = abs(vec-num);
        [~,ind] = min(optFun);
        closestMatch = vec(ind);
        assert(length(closestMatch)==1,'Multiple matches found')
    end

end
