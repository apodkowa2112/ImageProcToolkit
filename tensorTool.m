function varargout = tensorTool(varargin)
% tensorTool Browse lines in a 3D matrix
% tensorTool(matData)
% tensorTool(matData, funcHandle)
% tensorTool(matData, funcHandle, renderHandle)
% cb = tensorTool(...)
% cb is a struct of callbacks for programmatic setting definitions
%   cb.setAxes(lat,ax,frame) sets the lateral, axial and frame axes
%       respectively
%   cb.setFrameFormat(func) set the formatting of `f` placeholder 
%       (i.e. func = @(x) sprintf('%1.2f',x));
%   cb.setLabel(y,x,leftTitle,rightTitle) sets the figure labels
%
% See also comparator

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

% Generate Underlay axes
hUnderlayAxes = subplot(3,1,[1 2],'parent',hMainFigure);
set(hUnderlayAxes,'Tag','hUnderlayAxes');
green = zeros([size(matData,1),size(matData,2),3]); green(:,:,2) =1;
hUnderlayImg = image(latAxis,axAxis,green);

% Generate image axes
hImageAxes = axes('Position',get(hUnderlayAxes,'Position'));
hImageAxes.Tag = 'hImageAxes';
colormap(hImageAxes,gray);

linkaxes([hImageAxes,hUnderlayAxes]);
hl = linkprop([hImageAxes,hUnderlayAxes],{'Position'} );

figure(hMainFigure); % Needed for programatic interface.  Spawns separate figure otherwise.
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
hTPfigure.Position(4) = hMainFigure.Position(4) + 50; %50 pixels for menubars
hToolPanel = uipanel(hTPfigure,'Title','Tools');
hToolPanel.Units = hImageAxes.Units;
% hToolPanel.Position = [0 0 0.2,sum(hImageAxes.Position([2 4]))-hLineAxes.Position(2)];
% hToolPanel.Units = hLineAxes.Units;

% Keep hToolPanel locked to hMainFigure
% https://www.mathworks.com/matlabcentral/answers/391084-continuous-tracking-of-locationchanged-event-of-figure
hListener = event.listener(hMainFigure, 'LocationChanged', @move_callback);

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

hackFlag = true;
if hackFlag
    hackButton = uicontrol(hToolPanel,'Style','pushbutton',...
    'String','Hack!','units','normalized',...
    'Callback',@hackityhack_callback);
    hackButton.Position(2) = dot([1 3.5],makeGifButton.Position([2 4]));
    hackButton.Position(3)= 1-2*setAxesButton.Position(1);

end
function hackityhack_callback(hObject,eventdata)
    keyboard;
    updatePlots;
end
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

% caxis menu
cAxisPopUp = uicontrol(hToolPanel,'Style','popup',...
    'String',{'Auto','Auto Center','Max','Max Center','Manual'},...
    'Callback',@cAxisCallback,...
    'Tooltip', 'Color Axis', ...
    'Units','normalized',...
    'Position', [0.05, coordTable.Position(2)-0.175 0.9 0.15]);
cAxisStyle = 'Auto';

% hImg
axes(hImageAxes)   
hImg = imagesc(latAxis,axAxis,renderFunc(matData(:,:,sliceNumber)));
colormap gray;
% linkprop([hImg,hUnderlayImg],{'XData','YData'});
hColorbar = colorbar;
colorbar_title = '';
title(hColorbar,colorbar_title);
set(hImg,'ButtonDownFcn',@ImageClickCallback);
set(hImageAxes,'Color','none');
hTitle = title('Data'); hTitle.UserData = hTitle.String;
set(hTitle,'ButtonDownFcn',@LabelCallback);

axes(hLineAxes)
lineData = evalFunc(matData(:,lineNumber,sliceNumber));
hLine = plot(1:size(matData,1),lineData); hold on;
grid on;

fLineUpdate = 1;

% Function for updating `f` in title string
titleRender = @(x) sprintf('%1.2f',x);

%% Struct for external callbacks for programmatic access
extCallbacks.setAxes = @(lat,ax,frame) setAxes_callback(setAxesButton,[],{lat;ax;frame});
extCallbacks.setFrameFormat = @setFrameFormat;
extCallbacks.setLabel = @setLabel;
extCallbacks.setDirection = @setDirection;
extCallbacks.setCoordinate = @setCoordinate;
extCallbacks.setCaxisStyle = @setCaxisStyle;
extCallbacks.exportGif = @exportGif;
extCallbacks.Img = hImg;
extCallbacks.ax = hImageAxes;
extCallbacks.lineAxes = hLineAxes;
extCallbacks.titleRender = titleRender;

%% Start GUI
updatePlots;
hMainFigure.Visible = 'on';
figure(hMainFigure); colormap gray;
set(hUnderlayAxes,'XTick',[],'YTick',[])

%% Callbacks
    function move_callback(hSource, eventdata)
        hTPfigure.Position(1) = sum(hMainFigure.Position([1 3]));
        hTPfigure.Position(2) = hMainFigure.Position(2);
        figure(hTPfigure)
        figure(hMainFigure)
    end

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
%         gifName = 'animation.gif';
%         [gifName,fp] = uiputfile('*.gif','Make Gif',gifName);
%         gifName = fullfile(fp,gifName);
%         makeGif(permute(1:size(matData,3),[1 3 2]),gifName,...
%             @updateGif,@(x) [],hMainFigure);
%         
%         while true
%             val = inputdlg('Frame Delay:','Enter Frame Delay',1,{'1/2'});
%             [val,stat] = str2num(val{1});
%             if stat && ~isequal(val,0)
%                 [val_num,val_den] = rat(val,1e-4);
%                 break;
%             end
%         end
%         cmd = sprintf('convert -delay %1.0fx%1.0f %s %s',val_num,val_den,...
%             gifName,gifName);
%         system(cmd);
%         
%         msgbox(sprintf('Data stored in %s',gifName));
%         function updateGif(i)
%             hSlider.Value = i;
%             hSliderCallback(hSlider,[]);
%         end
        exportGif();
    end

    function exportGif(filename,delay)
        guiFlag = true;
        msg = @msgbox;
        if ~exist('filename','var')
            gifName = 'animation.gif';
            [gifName,fp] = uiputfile('*.gif','Make Gif',gifName);
            gifName = fullfile(fp,gifName);
        else
            gifName = filename;
        end
        if ~exist('delay','var')
            while true
                delay = inputdlg('Frame Delay:','Enter Frame Delay',1,{'1/2'});
                [delay,stat] = str2num(delay{1});
                if stat && ~isequal(delay,0)
                    [val_num,val_den] = rat(delay,1e-4);
                    break;
                end
            end
        else
            [val_num,val_den] = rat(delay,1e-4);
            guiFlag = false;
            msg = @disp;
        end
        makeGif(permute(1:size(matData,3),[1 3 2]),gifName,...
            @updateGif,@(x) [],hMainFigure,delay);
        
        cmd = sprintf('convert -delay %1.0fx%1.0f %s %s',val_num,val_den,...
            gifName,gifName);
        system(cmd);
        
        msg(sprintf('Data stored in %s',gifName));
        function updateGif(i)
            hSlider.Value = i;
            hSliderCallback(hSlider,[]);
        end
    end
    
    function LabelCallback(hObject,eventData,resp)
        prompt = {'Ax. Label'; 'Lat. Label'; 'Title'; 'Colorbar'};
        cbtitle_old = colorbar_title;
        defaults = {hImageAxes.YLabel.String; ...
            hImageAxes.XLabel.String;...
            hTitle.UserData;...
            colorbar_title};
        resp = inputdlg(prompt,'Set Label',1,defaults);
        setLabel(resp{2},resp{1},resp{3},resp{4})
    end

    function setLabel(xLabel,yLabel,mainTitle,cbTitle)
        hTold = hTitle;
        cbtitle_old = colorbar_title;
        try
            ylabel(hImageAxes,yLabel);
            xlabel(hImageAxes,xLabel);
            hTitle.UserData = mainTitle;
            colorbar_title = cbTitle;
            title(hColorbar,colorbar_title);
            updatePlots();
        catch exc
            warning('Error processing data. Reverting...')
            hTitle = hTold;
            colorbar_title = cbtitle_old;
            title(hColorbar,colorbar_title);
            updatePlots();
            throw(exc)
        end
        
    end

    function setAxes_callback(hObject, eventData, resp)
        % (hObject, eventData) is for standard gui access
        % (hObject, eventData, resp) is for programmatic access (eventData is empty)
        updateLabels=false;
        if ~exist('resp','var') % For programmatic access
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
                % I like to live dangerously
                proc = @(x) evalin('base',x);
                resp=cellfun(proc,resp,'UniformOutput',false);
            catch msg
                warndlg('Error processing input!')
                return
            end
            updateLabels=true;
        end
        try
            for i=1:length(resp)
                if isscalar(resp{i})
                    validateattributes(resp{i},{'numeric'},{'>',0});
                elseif isvector(resp{i})
                    validateattributes(resp{i},{'numeric'},{'increasing'});
                else 
                    error('Invalid entry in resp');
                end
            end
        catch msg
            errordlg(msg.message,'Invalid Input!')
            return
        end
        if isscalar(resp{1})
            centerLatAxis = questdlg('Center Lat Axis?',...
                'Center Lat Axis?','Yes','No','Yes');
            centerLatAxis = isequal(centerLatAxis,'Yes');
        end
        if isscalar(resp{2})
            centerAxAxis  = questdlg('Center Ax Axis?',...
                'Center Ax Axis?','Yes','No','No');
            centerAxAxis = isequal(centerAxAxis,'Yes');
        end
        
        % Update hPointer
        [hPointer(1),ind(1)] = findClosest(latAxis,hPointer(1));
        [hPointer(2),ind(2)] = findClosest(axAxis,hPointer(2));
        
        % Update axes
        latOld = latAxis;
        axOld  = axAxis;
        if isvector(resp{1}) && ~isscalar(resp{1})
            latAxis = resp{1};
            latAxis = latAxis(:)';
            assert(isequal(size(latAxis),size(latOld)));
        else
            latAxis = (0:(length(latAxis)-1))*resp{1};
            if centerLatAxis; latAxis = latAxis-mean(latAxis([1,end])); end
        end
        if isvector(resp{2}) && ~isscalar(resp{2})
            axAxis = resp{2};
            axAxis = axAxis(:)';
            assert(isequal(size(axAxis),size(axOld)));
        else
            axAxis  = (0:(length( axAxis)-1))*resp{2};
            if centerAxAxis; axAxis = axAxis-mean(axAxis([1,end])); end
        end
        hPointer = [latAxis(ind(1)), axAxis(ind(2))];
        if length(directions)==3
            if isvector(resp{3}) && ~isscalar(resp{3})
                f = resp{3};
                f = f(:)';
                assert(isequal(size(frameAxis),size(f)));
                frameAxis = f;
            else
                frameAxis = (0:(length(frameAxis)-1))*resp{3};
            end
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
        if updateLabels
            LabelCallback(hObject,eventData);
        end
    end

    function cAxisCallback( objectHandle , eventData )
        styles = get(objectHandle,'String');
        style = styles{get(objectHandle, 'Value')};
        setCaxisStyle(style);
    end

    function setCaxisStyle(s,dynRange)
        styles = get(cAxisPopUp,'String');
        if isequal(class(s),'char') || isequal(class(s),'string')
            % Set via String
            if ismember(s,styles)
                style = s;
            else 
                error('Invalid Style %s',s);
            end
            val = find(cellfun(@(x) isequal(x,s),styles));
        else 
            % Set via Value
            validateattributes(s,{'numeric'},{'integer','>=',1,'<=',length(styles)})
            style = styles{s};
            val = s;
        end
        switch style
            case 'Auto'
                cAxisStyle = style;
            case 'Auto Center'
                cAxisStyle = style;
            case 'Manual'
                s = cAxisStyle;
                try
                    cAxisStyle = style;
                    if exist('dynRange','var')
                        resp = dynRange;
                    else
                        prompt = {'Min:', 'Max:', 'Unit:'};
                        defaults = compose('%1.1f',get(hImageAxes,'CLim'));
                        defaults{end+1} = '';
                        resp=inputdlg(prompt,'Set CAxis',1,defaults);
                        titleStr = resp{3};
                        dynRange=cellfun(@str2num,resp(1:2));
                    end
                    validateattributes(dynRange,{'numeric'},{});
                    assert(dynRange(2)>dynRange(1),'Invalid CLim: Reverting...');
                    updateCaxis();
                    caxis(hImageAxes,dynRange(:)');
                    if exist('titleStr','var')
                        title(colorbar(hImageAxes),titleStr);
                    end
                catch
                    warning('Error processing cAxisCallback')
                    cAxisStyle = s;
                    updateCaxis();
                end
                cAxisStyle = style;
            case 'Max' 
                cAxisStyle = style;
            case 'Max Center'
                cAxisStyle = style;
            otherwise 
                val = find(cellfun(@(x) isequal(x,cAxisStyle),styles));
                set(cAxisPopUp,'Value',val);
        end
        set(cAxisPopUp,'Value',val);
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
        prev = hObject.Data;
        prev(row,col) = callbackdata.PreviousData;
        try 
            if col==3
                sliceNumber = min(max(1,round(coordinate)),size(matData,3));
                set(hSlider,'Value',sliceNumber);
            end
            setCoordinate(hObject.Data(1),hObject.Data(2),hObject.Data(3));
        catch exc
            setCoordinate(prev(1),prev(2),prev(3));
            rethrow(exc)
        end
    end

    function setCoordinate(row,col,slice)
        oldPointer= hPointer;
        oldTable = coordTable.Data;
        try
            hPointer(1) = latAxis(col);
            hPointer(2) = axAxis(row);
            coordTable.Data = [row col slice];
            sliceNumber = slice;
            if exist('hSlider','var')
                set(hSlider,'Value',sliceNumber);
            end
        catch exc
            coordTable.Data = oldTable;
            hPointer = oldPointer;
            sliceNumber = oldTable(3);
            if exist('hSlider','var')
                set(hSlider,'Value',sliceNumber);
            end
            rethrow(exc);
        end
        updatePlots;
    end

%% Utility functions
    function updatePlots
        figure(hMainFigure)
        
        %% Render image
        set(hImg,'CData',renderFunc(matData(:,:,sliceNumber))...
            ...,'YData',axAxis...
            ...,'XData',latAxis...
        );
         %set(hUnderlayImg,'YData',axAxis,'XData',latAxis);
         %xlim(hImageAxes,xLim); ylim(hImageAxes,yLim);
        
        updateCaxis();
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
%                axes(hLineAxes)
%                lineData = evalFunc(matData(:,lineNumber,sliceNumber));
%                if fLineUpdate
%                    hLine = plot(axAxis,lineData);
%                    grid on;
%                    fLineUpdate = 0;
%                else % cast to double to avoid bugs with logical datatypes
%                    set(hLine,'YData',double(lineData),'XData',axAxis);
%                end
                set(hLine,'XData',axAxis,...
                    'YData', evalFunc(matData(:,lineNumber,sliceNumber)));
                
            case 'Horizontal'
                [~,lineNumber] = findClosest(axAxis,hPointer(2));
                mask = ones(size(matData(:,:,1))); mask(lineNumber,:)=0;
                hImg.AlphaData = mask;
                axes(hLineAxes)
%                lineData = evalFunc(matData(lineNumber,:,sliceNumber));
%                if fLineUpdate
%                    hLine =  plot(latAxis,lineData);
%                    grid on;
%                    fLineUpdate = 0;
%                else
%                    set(hLine,'YData',double(lineData),'XData',latAxis);                    
%                end
                set(hLine,'XData',latAxis,...
                    'YData', evalFunc(matData(lineNumber,:,sliceNumber)));
                
            case 'Normal'
                [hPointer(1),ind(1)] = findClosest(latAxis,hPointer(1));
                [hPointer(2),ind(2)] = findClosest(axAxis,hPointer(2));
                lineNumber = 0;
                mask = ones(size(matData(:,:,1))); 
                mask(:,ind(1))=0; mask(ind(2),:) = 0;
                
                hImg.AlphaData = mask;
%                axes(hLineAxes)
%                lineData = evalFunc(squeeze(matData(ind(2),ind(1),:)));
%                hLine = plot(frameAxis,lineData);
%                hold on
%                plot(frameAxis(sliceNumber),lineData(sliceNumber),'ro');
%                hold off
%                grid on;
                set(hLine,'XData',frameAxis,...
                    'YData', evalFunc(squeeze(matData(ind(2),ind(1),:))));
            
            otherwise 
                error('Error: Invalid lineDir (%s)',lineDir');
        end
        
        % Reset Tags on figure update
        hImageAxes.Tag = 'hImageAxes';
        hLineAxes.Tag =  'hLineAxes';
        axes(hImageAxes); % for easy caxis
        % Update titles if necessary
        try
            hTitle.String = strrep(hTitle.UserData,'`f`',...
                ...sprintf('%1.1e',frameAxis(sliceNumber)));
                titleRender(frameAxis(sliceNumber)));
        catch
            warning('Error updating titles');
        end
    end

    function toggleDirection        
        if any(ismember(directions,lineDir))
            val = mod(find(ismember(directions,lineDir)),length(directions))+1;
            setDirection(directions{val});
        else 
            setDirection('Vertical');
        end
        
    end

    function setDirection(val)
        assert(ismember(val,directions),'Direction %s invalid.',val);
                    lineDir = val;
        switch(val)
            case directions{1} % Vertical
                xlabel(hLineAxes,hImageAxes.YLabel.String);
                title(hLineAxes,'Ax. Cross Section')
            case directions{2} % Horizontal
                xlabel(hLineAxes,hImageAxes.XLabel.String);
                title(hLineAxes,'Lat. Cross Section')
            case directions{3} % Normal
                xlabel(hLineAxes,'');
                title('');
        end
        lineDirButton.String = lineDir;
        fLineUpdate = 1;
    end

    function updateCaxis
        % Set Clim Mode
        if isequal(cAxisStyle,'Auto')
            set(hImageAxes,'CLimMode','auto')
            return
        elseif isequal(cAxisStyle,'Auto Center')
            set(hImageAxes,'CLimMode','manual')
            caxis(hImageAxes,max(max(abs(renderFunc(matData(:,:,sliceNumber)))))*[-1 1])
            return
        else 
            set(hImageAxes,'CLimMode','manual')
            return
        end
        %% Get Caxis
        switch cAxisStyle
            case 'Max'
                c_max = max(max(renderFunc(matData(:,:,1))));
                c_min = min(min(renderFunc(matData(:,:,1))));
                for k = 1:max(size(matData,3))
                    c_max = max(c_max,...
                        max(max([renderFunc(matData(:,:,k))...
                        ])));
                    c_min = min(c_min,...
                        min(min([renderFunc(matData(:,:,k))...
                        ])));
                end
                caxis(hImageAxes,[c_min,c_max]);
            case 'Max Center'
                c_max = max(max(abs(renderFunc(matData(:,:,1)))));
                for k = 1:max(size(matData,3))
                    c_max = max(c_max,...
                        max(max(abs([renderFunc(matData(:,:,k))...
                        ]))));
                end
                caxis(hImageAxes,c_max*[-1 1]);
            otherwise
                error('Unsupported cAxisStyle: %s',cAxisStyle);
        end
    end

    function [closestMatch,ind] = findClosest(vec,num)
        optFun = abs(vec-num);
        [~,ind] = min(optFun);
        closestMatch = vec(ind);
        assert(length(closestMatch)==1,'Multiple matches found')
    end
    
    function setFrameFormat(s)
        old = titleRender;
        try
            titleRender=s;
            updatePlots;
        catch
            titleRender=old;
            updatePlots;
        end
    end
    varargout{1} = extCallbacks;

    %% This function is dangerous.  Use at your own risk
    function setter(s)
        warning('Dangerous function. Use at your own risk')
        eval(s);
    end

    % Intentional obfuscation here
    varargout{2} = @setter;

end
