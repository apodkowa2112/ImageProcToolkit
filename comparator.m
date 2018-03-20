function varargout = comparator(varargin)
% COMPARATOR Compare 2 3D matrices
% comparator(matData1, matData2)
% comparator(matData1, matData2, funcHandle)
% comparator(matData1, matData2, funcHandle, renderHandle)
%% Initialization
switch length(varargin)
    case 2
        % comparator(matData1, matData2)
        matData1 = varargin{1};
        matData2 = varargin{2};
        lineNumber = 1;
        lineDir = 'Vertical';
    case 3
        % comparator(matData1, matData2, funcHandle)
        matData1 = varargin{1};
        matData2 = varargin{2};
        lineNumber = 1;
        lineDir = 'Vertical';
        renderFunc = varargin{3};
    case 4
        % comparator(matData1, matData2, funcHandle, renderHandle)
        matData1 = varargin{1};
        matData2 = varargin{2};
        lineNumber = 1;
        lineDir = 'Vertical';
        renderFunc = varargin{3};
        evalFunc = varargin{4};
    otherwise
        error('Error: Unsupported Number of Arguments: %1.0f', length(varargin) )
end

%% Sanity checks
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
if isequal(ndims(matData1),3)
    directions = [directions, {'Normal'}];
end

assert(isequal(size(matData1),size(matData2)),'Data matrices have different sizes');

%% Constructors
% figure
hMainFigure = figure('Name','Comparator',...
    'Toolbar','figure'...
    );%,'Visible','off');

% Generate Underlay axes
hUnderlayAxes1 = subplot(3,2,[1 3],'parent',hMainFigure);
set(hUnderlayAxes1,'Tag','hUnderlayAxes1');
blue = zeros([size(matData1,1),size(matData1,2),3]); blue(:,:,3) =1;
hUnderlayImg1 = image(blue);

hUnderlayAxes2 = subplot(3,2,1+[1 3],'parent',hMainFigure);
set(hUnderlayAxes2,'Tag','hUnderlayAxes2');
red = zeros([size(matData2,1),size(matData2,2),3]); red(:,:,1) =1;
hUnderlayImg2 = image(red);

% Generate image axes
hImageAxes1 = axes('Position',get(hUnderlayAxes1,'Position'));
hImageAxes1.Tag = 'hImageAxes1';
colormap(hImageAxes1,gray);

hImageAxes2 = axes('Position',get(hUnderlayAxes2,'Position'));
hImageAxes2.Tag = 'hImageAxes2';
colormap(hImageAxes2,gray);


linkaxes([hImageAxes1,hUnderlayAxes1,hImageAxes2, hUnderlayAxes2]);
hl1 = linkprop([hImageAxes1,hUnderlayAxes1],{'Position'} );
hl2 = linkprop([hImageAxes2,hUnderlayAxes2],{'Position'} );

% subplot clobbers axes, so set the position manually
hLineAxes = axes('Position',[0.13 0.11 0.775 0.15]);
hLineAxes.Tag = 'hLineAxes';
grid(hLineAxes,'on');

% Generate pointer for mouse click action
hPointer = zeros(1,2);

%% Component initialization
% hSlider
if length(directions)==3
    hSlider = uicontrol(hMainFigure,'Style','slider','Min',1,'Max',size(matData1,3)...
        ,'Value',sliceNumber,'callback',@hSliderCallback,...
        'Units','normalized','Position',[0.13 0.32,0.48,0.044],...
        'SliderStep',[1/(size(matData1,3)-1), max(0.1,1/(size(matData1,3)-1))]);
end

% hToolPanel
hToolPanel = uipanel(hMainFigure,'Title','Tools');
hToolPanel.Units = hImageAxes1.Units;
hToolPanel.Position = [0 0 0.2,sum(hImageAxes1.Position([2 4]))-hLineAxes.Position(2)];
hToolPanel.Units = hLineAxes.Units;

hLineAxes.Position(3)  = hLineAxes.Position(3)-1.1*hToolPanel.Position(3);
axSep = hImageAxes2.Position(1)-hImageAxes1.Position(1)-hImageAxes1.Position(3);
hImageAxes1.Position(3) = (hLineAxes.Position(3)-axSep)/2;
hImageAxes2.Position(3) = hImageAxes1.Position(3);
hImageAxes2.Position(1) = sum(hImageAxes1.Position([1 3])) + axSep;

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
axes(hImageAxes1)      
hImg1 = imagesc(renderFunc(matData1(:,:,sliceNumber)));
colorbar
set(hImg1,'ButtonDownFcn',@ImageClickCallback);
set(hImageAxes1,'Color','none');

axes(hImageAxes2)      
hImg2 = imagesc(renderFunc(matData2(:,:,sliceNumber)));
colorbar
set(hImg2,'ButtonDownFcn',@ImageClickCallback);
set(hImageAxes2,'Color','none');

axes(hLineAxes)
lineData = evalFunc(matData1(:,lineNumber,sliceNumber));
hLine1 = plot(1:size(matData1,1),lineData); hold on;
hLine2 = plot(1:size(matData1,1),evalFunc(matData2(:,lineNumber,sliceNumber)),'r');
grid on;

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
            sliceNumber = min(max(1,round(coordinate)),size(matData1,3));
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
        set(hImg1,'CData',renderFunc(matData1(:,:,sliceNumber)));
        set(hImg2,'CData',renderFunc(matData2(:,:,sliceNumber)));
        
        %% calculate axes
        [xData, yData, cData1] = getimage(hImageAxes1);
        [xData, yData, cData2] = getimage(hImageAxes2);
        dx = diff(xData)/(size(cData1,2)-1);
        dy = diff(yData)/(size(cData1,1)-1);
        xAxis = xData(1):dx:xData(2);
        yAxis = yData(1):dy:yData(2);
        assert(isequal(length(xAxis),size(cData1,2)),'Error: Bad xAxis length');
        assert(isequal(length(yAxis),size(cData1,1)),'Error: Bad yAxis length');
        [~,hPointer(1)] = findClosest(xAxis,hPointer(1));
        [~,hPointer(2)] = findClosest(yAxis,hPointer(2));
        set(coordTable,'data',[flipud(hPointer(:))' sliceNumber]);
        switch lineDir
            case 'Vertical'
                [~,lineNumber] = findClosest(xAxis,hPointer(1));
                mask = ones(size(matData1(:,:,1))); mask(:,lineNumber)=0;
                hImg1.AlphaData = mask;
                hImg2.AlphaData = mask;
%                 axes(hLineAxes)
%                 lineData = evalFunc(matData1(:,lineNumber,sliceNumber));
%                 plot(yAxis,lineData);
%                 grid on;
                set(hLine1,'XData',yAxis,...
                    'YData', evalFunc(matData1(:,lineNumber,sliceNumber)));
                set(hLine2,'XData',yAxis,...
                    'YData', evalFunc(matData2(:,lineNumber,sliceNumber)));
            case 'Horizontal'
                [~,lineNumber] = findClosest(yAxis,hPointer(2));
                mask = ones(size(matData1(:,:,1))); mask(lineNumber,:)=0;
                hImg1.AlphaData = mask;
                hImg2.AlphaData = mask;
%                 axes(hLineAxes)
%                 lineData = evalFunc(matData1(lineNumber,:,sliceNumber));
%                 plot(xAxis,lineData);
%                 grid on;
                set(hLine1,'XData',xAxis,...
                    'YData', evalFunc(matData1(lineNumber,:,sliceNumber)));
                set(hLine2,'XData',xAxis,...
                    'YData', evalFunc(matData2(lineNumber,:,sliceNumber)));
            case 'Normal'
                [~,hPointer(1)] = findClosest(xAxis,hPointer(1));
                [~,hPointer(2)] = findClosest(yAxis,hPointer(2));
                lineNumber = 0;
                mask = ones(size(matData1(:,:,1))); 
                mask(:,hPointer(1))=0; mask(hPointer(2),:) = 0;
                
                hImg1.AlphaData = mask;
                hImg2.AlphaData = mask;
%                 axes(hLineAxes)
%                 lineData = evalFunc(squeeze(matData1(hPointer(2),hPointer(1),:)));
%                 plot(1:size(matData1,3),lineData);
%                 hold on
%                 plot(sliceNumber,lineData(sliceNumber),'ro');
%                 hold off
%                 grid on;
                set(hLine1,'XData',1:size(matData1,3),...
                    'YData', evalFunc(squeeze(matData1(hPointer(2),hPointer(1),:))));
                set(hLine2,'XData',1:size(matData1,3),...
                    'YData', evalFunc(squeeze(matData2(hPointer(2),hPointer(1),:))));
            
            otherwise 
                error('Error: Invalid lineDir (%s)',lineDir');
        end
        
        % Reset Tags on figure update
        hImageAxes1.Tag = 'hImageAxes1';
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
    end

    function [closestMatch,ind] = findClosest(vec,num)
        optFun = abs(vec-num);
        [~,ind] = min(optFun);
        closestMatch = vec(ind);
        assert(length(closestMatch)==1,'Multiple matches found')
    end

end
