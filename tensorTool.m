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

latAxis = 1:size(matData,2);
axAxis = 1:size(matData,1);
frameAxis = 1:size(matData,3);
%% Constructors
% figure
hMainFigure = figure('Name','tensorTool',...
    'Toolbar','figure'...
    ,'CloseRequestFcn',@closeUI...
    );%,'Visible','off');

% Generate axes
hUnderlayAxes = subplot(3,1,[1 2],'parent',hMainFigure);
set(hUnderlayAxes,'Tag','hUnderlayAxes');
green = zeros([size(matData,1),size(matData,2),3]); green(:,:,2) =1;
hUnderlayImg = image(latAxis,axAxis,green);

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

% hToolPanel
hTPfigure = figure('Name','Tensor Tools','Menubar','none',...
    'NumberTitle','off','CloseRequestFcn',@closeUI);
hTPfigure.Position([1 3]) = [1.05*sum(hMainFigure.Position([1 3])) 0.3*hMainFigure.Position(3)];
hToolPanel = uipanel(hTPfigure,'Title','Tools');
hToolPanel.Units = hImageAxes.Units;
% hToolPanel.Position = [0 0 0.2,sum(hImageAxes.Position([2 4]))-hLineAxes.Position(2)];
% hToolPanel.Units = hLineAxes.Units;

hLineAxes.Position(3)  = hLineAxes.Position(3);%-1.1*hToolPanel.Position(3);
hImageAxes.Position(3) = hLineAxes.Position(3);

%hToolPanel.Position(1) = sum(hLineAxes.Position([1 3]))...
%    +0.1*hToolPanel.Position(3);
%hToolPanel.Position(2) = hLineAxes.Position(2);

% hSlider
if length(directions)==3
    pos = hLineAxes.Position...
        + hLineAxes.Position(4)*[ 0 1 0 0];
    pos(4) = 0.044;
    hSlider = uicontrol(hToolPanel,'Style','slider','Min',1,'Max',size(matData,3)...
        ,'Value',sliceNumber,'callback',@hSliderCallback,...
        'Units','normalized','Position',[0. 0.5,1,0.044],...
        'SliderStep',[1/(size(matData,3)-1), max(0.1,1/(size(matData,3)-1))]);
end

% lineDirButton
lineDirButton = uicontrol(hToolPanel,'Style','pushbutton',...
    ...%uicontrol(hTPfigure,'Style','pushbutton','Parent',hToolPanel,...
    'String',lineDir,'ToolTip','Line Direction',...
    'Callback',@lineDirButton_callback...
    ,'Units','normalized');
lineDirButton.Position(2) = 0.9;
lineDirButton.Position(3) = 1-2*lineDirButton.Position(1);

% makeGifButton
makeGifButton = uicontrol(hToolPanel,'Style','pushbutton',...
    'String','Make Gif','Callback',@makeGif_callback,'units','normalized');
makeGifButton.Position(3) = 1-2*makeGifButton.Position(1);
if length(directions)~=3
    makeGifButton.Visible = 'off';
end
% setAxesButton
setAxesButton = uicontrol(hToolPanel,'Style','pushbutton',...
    'String','Set Axes','units','normalized','Callback',@setAxes_callback);
setAxesButton.Position(2) = dot([1 1.5],makeGifButton.Position([2 4]));
setAxesButton.Position(3)= 1-2*setAxesButton.Position(1);

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
coordTable.ColumnWidth = {floor(0.95*hTPfigure.Position(3)/3)};
coordTable.Position(4) = coordTable.Extent(4);
coordTable.Position(2) = coordTable.Position(2)+coordTable.Extent(4)/2;

% hImg
axes(hImageAxes)   
hImg = imagesc(latAxis,axAxis,renderFunc(matData(:,:,sliceNumber)));
% linkprop([hImg,hUnderlayImg],{'XData','YData'});
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

    function closeUI(hObject,eventdata)
        try delete(hMainFigure);
        catch 
        end
        try delete(hTPfigure);
        catch
        end
    end

    function makeGif_callback(hObject,eventData)
        gifName = 'animation.gif';
        [gifName,fp] = uiputfile('*.gif','Make Gif',gifName);
        gifName = fullfile(fp,gifName);
        makeGif(permute(1:size(matData,3),[1 3 2]),gifName,...
            @updateGif,@(x) [],hMainFigure);
        
        while true
            val = inputdlg('Frame Delay:','Enter Frame Delay',1,{'1/2'});
            [val,stat] = str2num(val{1});
            if stat && ~isequal(val,0)
                [val_num,val_den] = rat(val,1e-4);
                break;
            end
        end
        cmd = sprintf('convert -delay %1.0fx%1.0f %s %s',val_num,val_den,...
            gifName,gifName);
        system(cmd);
        
        msgbox(sprintf('Data stored in %s',gifName));
        function updateGif(i)
            hSlider.Value = i;
            hSliderCallback(hSlider,[]);
        end

    end

    function setAxes_callback(hObject, eventData)
        prompt = {'Lat. Step'; 'Ax. Step'};
        defaults = diff([latAxis(1:2); axAxis(1:2)]')';
        if length(directions)==3
            prompt{end+1} = 'Frame Step';
            defaults(end+1) = diff(frameAxis(1:2));
        end
        defaults = num2cell(defaults);
        defaults = cellfun(@num2str,defaults,'UniformOutput',false);
        resp = inputdlg(prompt,'Set Axes',1,defaults);
        try 
            resp=cellfun(@str2num,resp);
        catch msg
            warndlg('Error processing input!')
            return
        end
        try
            validateattributes(resp,{'numeric'},{'>',0});
        catch msg
            errordlg(msg.message,'Invalid Input!')
            return
        end

        % Update hPointer
        [hPointer(1),ind(1)] = findClosest(latAxis,hPointer(1));
        [hPointer(2),ind(2)] = findClosest(axAxis,hPointer(2));
        
        % Update axes
        latOld = latAxis;
        axOld = axAxis;
        latAxis = (0:(size(matData,2)-1))*resp(1);
        axAxis  = (0:(size(matData,1)-1))*resp(2);
        hPointer = [latAxis(ind(1)), axAxis(ind(2))];
        if length(directions)==3
            frameAxis = (0:(size(matData,3)-1))*resp(3);
        end
        
        % Rederive limits on old axes
        % Image toolbox likes half pixel edges
        yLim=ylim(hImageAxes)-diff(axOld(1:2))*[-0.5 0.5];
        xLim=xlim(hImageAxes)-diff(latOld(1:2))*[-0.5 0.5];
        [~,yLim(1)] = findClosest(axOld,yLim(1));
        [~,yLim(2)] = findClosest(axOld,yLim(2));
        [~,xLim(1)] = findClosest(latOld,xLim(1));
        [~,xLim(2)] = findClosest(latOld,xLim(2));
        yLim = axAxis(yLim)+diff(axAxis(1:2))*0.5*[-1 1];
        xLim = latAxis(xLim)+diff(latAxis(1:2))*0.5*[-1 1];
        
        % Update handles
        set(hImg...,'CData',renderFunc(matData(:,:,sliceNumber))...
            ,'YData',axAxis...
            ,'XData',latAxis...
        );
        set(hUnderlayImg,'YData',axAxis,'XData',latAxis);
        xlim(hImageAxes,xLim); ylim(hImageAxes,yLim);
        
        updatePlots;
    end

    function cAxisCallback( objectHandle , eventData )
        styles = get(objectHandle,'String');
        style = styles{get(objectHandle, 'Value')};
        switch style
            case 'Auto'
                cAxisStyle = style;
            case 'Manual'
                cAxisStyle = style;
            case 'Max' 
                cAxisStyle = style;
            case 'Max Center'
                cAxisStyle = style;
            otherwise 
                val = find(cellfun(@(x) isequal(x,cAxisStyle),styles));
                set(objectHandle,'Value',val);
        end
        updateCaxis();
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
        hPointer(1) = latAxis(hObject.Data(2));
        hPointer(2) = axAxis(hObject.Data(1));
        updatePlots;
    end

%% Utility functions
    function updatePlots
        figure(hMainFigure)
        
        %% Render image
%         yLim=axAxis([1 end])+diff(axAxis(1:2))*[-0.5 0.5];
%         xLim=latAxis([1 end])+diff(latAxis(1:2))*[-0.5 0.5];
        set(hImg,'CData',renderFunc(matData(:,:,sliceNumber))...
            ...,'YData',axAxis...
            ...,'XData',latAxis...
        );
%         set(hUnderlayImg,'YData',axAxis,'XData',latAxis);
%         xlim(hImageAxes,xLim); ylim(hImageAxes,yLim);
        
        %% calculate axes
%         [xData, yData, cData] = getimage(hImageAxes);
%         dx = diff(xData)/(size(cData,2)-1);
%         dy = diff(yData)/(size(cData,1)-1);
%         assert(isequal(length(latAxis),size(cData,2)),'Error: Bad xAxis length');
%         assert(isequal(length(axAxis),size(cData,1)),'Error: Bad yAxis length');
        [hPointer(1),ind(1)] = findClosest(latAxis,hPointer(1));
        [hPointer(2),ind(2)] = findClosest(axAxis,hPointer(2));
        set(coordTable,'data',[flipud(ind(:))' sliceNumber]);
        switch lineDir
            case 'Vertical'
                [~,lineNumber] = findClosest(latAxis,hPointer(1));
                mask = ones(size(matData(:,:,1))); mask(:,lineNumber)=0;
                hImg.AlphaData = mask;
                axes(hLineAxes)
                lineData = evalFunc(matData(:,lineNumber,sliceNumber));
                if fLineUpdate
                    hLine = plot(axAxis,lineData);
                    grid on;
                    fLineUpdate = 0;
                else % cast to double to avoid bugs with logical datatypes
                    set(hLine,'YData',double(lineData),'XData',axAxis);
                end
                
            case 'Horizontal'
                [~,lineNumber] = findClosest(axAxis,hPointer(2));
                mask = ones(size(matData(:,:,1))); mask(lineNumber,:)=0;
                hImg.AlphaData = mask;
                axes(hLineAxes)
                lineData = evalFunc(matData(lineNumber,:,sliceNumber));
                if fLineUpdate
                    hLine =  plot(latAxis,lineData);
                    grid on;
                    fLineUpdate = 0;
                else
                    set(hLine,'YData',double(lineData),'XData',latAxis);                    
                end
                
            case 'Normal'
                [hPointer(1),ind(1)] = findClosest(latAxis,hPointer(1));
                [hPointer(2),ind(2)] = findClosest(axAxis,hPointer(2));
                lineNumber = 0;
                mask = ones(size(matData(:,:,1))); 
                mask(:,ind(1))=0; mask(ind(2),:) = 0;
                
                hImg.AlphaData = mask;
                axes(hLineAxes)
                lineData = evalFunc(squeeze(matData(ind(2),ind(1),:)));
                hLine = plot(frameAxis,lineData);
                hold on
                plot(frameAxis(sliceNumber),lineData(sliceNumber),'ro');
                hold off
                grid on;
            
            otherwise 
                error('Error: Invalid lineDir (%s)',lineDir');
        end
        
        % Reset Tags on figure update
        hImageAxes.Tag = 'hImageAxes';
        hLineAxes.Tag =  'hLineAxes';
        axes(hImageAxes); % for easy caxis
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
