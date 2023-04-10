function varargout = comparator(varargin)
% COMPARATOR Compare 2 3D matrices
% comparator(matData1, matData2)
% comparator(matData1, matData2, funcHandle)
% comparator(matData1, matData2, funcHandle, renderHandle)
% cb = comparator(...)
% cb is a struct of callbacks for programmatic setting definitions
%   cb.setAxes(lat,ax,frame) sets the lateral, axial and frame axes respectively
%   cb.setLatAxis(lat)  lateral axis
%   cb.setAxAxis(ax)    axial axis
%   cb.setFrmAxis(frm)  frame axis
%   cb.setDirection('Vertical')  {'Horizontal','Normal'}
%   cb.setFrameFormat(func) set the formatting of `f` placeholder 
%       (i.e. func = @(x) sprintf('%1.2f',x));
%   cb.setCoordinate(row,col,slice)
%   cb.exportGif(filename,[delay])
%   cb.setLabel(y,x,leftTitle,rightTitle) sets the figure labels

%% Initialization
switch length(varargin)
    case 0
        matData1 = randn(5,6,7);
        matData2 = randn(size(matData1));
        lineNumber = 1;
        lineDir = 'Vertical';
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

% Collapse dimensions
matData1 = matData1(:,:,:);
matData2 = matData2(:,:,:);

sliceNumber = 1;
lineData = 0;
directions = {'Vertical','Horizontal'};
if isequal(max(ndims(matData1), ndims(matData2)),3)
    directions = [directions, {'Normal'}];
end

if size(matData1,3) == 1
    matData1 = repmat(matData1,1,1,size(matData2,3));
end
if size(matData2,3) == 1
    matData2 = repmat(matData2,1,1,size(matData1,3));
end

if isequal(class(matData1),'logical')
    % Logical datatypes cause updatePlots to crash
    matData1 = single(matData1);
end

if isequal(class(matData2),'logical')
    matData2 = single(matData2);
end

assert(isequal(size(matData1),size(matData2)),'Data matrices have different sizes');

latAxis = 1:size(matData1,2);
axAxis = 1:size(matData1,1);
frameAxis = 1:size(matData1,3);

%% Constructors
% figure
hMainFigure = figure('Name','Comparator',...
    'Toolbar','figure'...
    ,'CloseRequestFcn',@closeUI...
    );%,'Visible','off');

% Generate Underlay axes
% hUnderlayAxes1 = subplot(2,2,[1],'parent',hMainFigure);
hUnderlayAxes1 = subplot(5,2,[1 3 5],'parent',hMainFigure);
set(hUnderlayAxes1,'Tag','hUnderlayAxes1');
blue = zeros([size(matData1,1),size(matData1,2),3]); blue(:,:,3) =1;
hUnderlayImg1 = image(latAxis,axAxis,blue);

% hUnderlayAxes2 = subplot(2,2,1+[1],'parent',hMainFigure);
hUnderlayAxes2 = subplot(5,2,1+[1 3 5],'parent',hMainFigure);
set(hUnderlayAxes2,'Tag','hUnderlayAxes2');
red = zeros([size(matData2,1),size(matData2,2),3]); red(:,:,1) =1;
hUnderlayImg2 = image(latAxis,axAxis,red);

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
% hl3 = linkprop([hImageAxes1 hImageAxes2],{'XLabel'}); % Causes Race condition
% subplot clobbers axes, so set the position manually

figure(hMainFigure); % Needed for programatic interface.  Spawns separate figure otherwise.
% hLineAxes = subplot(2,2,[3 4]);%axes('Position',[0.13 0.11 0.775 0.15]);
hLineAxes = subplot(5,2,[7:10]);%axes('Position',[0.13 0.11 0.775 0.15]);
hLineAxes.Tag = 'hLineAxes';
grid(hLineAxes,'on');

% Generate pointer for mouse click action
hPointer = zeros(1,2);

%% Component initialization

% hToolPanel
hTPfigure = figure(100+hMainFigure.Number);
set(hTPfigure,'Name','Comparator Tools','Menubar','none',...
    'NumberTitle','off','CloseRequestFcn',@closeUI);
hTPfigure.Position([1 3]) = [1.05*sum(hMainFigure.Position([1 3])) 0.3*hMainFigure.Position(3)];
hTPfigure.Position(4) = hMainFigure.Position(4) + 50; %50 pixels for menubars
hToolPanel = uipanel(hTPfigure,'Title','Tools');
hToolPanel.Units = hImageAxes1.Units;
% hToolPanel.Position = [0 0 0.2,sum(hImageAxes1.Position([2 4]))-hLineAxes.Position(2)];
% hToolPanel.Units = hLineAxes.Units;

% Keep hToolPanel locked to hMainFigure
% https://www.mathworks.com/matlabcentral/answers/391084-continuous-tracking-of-locationchanged-event-of-figure
hListener = event.listener(hMainFigure, 'LocationChanged', @move_callback);

hLineAxes.Position(3)  = hLineAxes.Position(3);%-1.1*hToolPanel.Position(3);
axSep = hImageAxes2.Position(1)-hImageAxes1.Position(1)-hImageAxes1.Position(3);
hImageAxes1.Position(3) = (hLineAxes.Position(3)-axSep)/2;
hImageAxes2.Position(3) = hImageAxes1.Position(3);
hImageAxes2.Position(1) = sum(hImageAxes1.Position([1 3])) + axSep;
% 
% hToolPanel.Position(1) = sum(hLineAxes.Position([1 3]))...
%     ;%+0.1*hToolPanel.Position(3);
% hToolPanel.Position(2) = hLineAxes.Position(2);

% hSlider
if length(directions)==3
    pos = hLineAxes.Position...
        + hLineAxes.Position(4)*[ 0 1 0 0];
    pos(4) = 0.044;
    hSlider = uicontrol(hToolPanel,'Style','slider','Min',1,'Max',size(matData1,3)...
        ,'Value',sliceNumber,'callback',@hSliderCallback,...
        'Units','normalized','Position',pos,...
        'SliderStep',[1/(size(matData1,3)-1), max(0.1,1/(size(matData1,3)-1))]);
    hLineAxes.Position(4) = hLineAxes.Position(4)-1.1*pos(4);
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

% ComparativeStatsButton
compStatsButton = uicontrol(hToolPanel,'Style','pushbutton',...
    'String','Comp. Stats','units','normalized','Callback',@compStats_callback);
compStatsButton.Position(2) = dot([1 1.5],setAxesButton.Position([2 4]));
compStatsButton.Position(3)= 1-2*compStatsButton.Position(1);


hackFlag = true;
if hackFlag
    hackButton = uicontrol(hToolPanel,'Style','pushbutton',...
    'String','Hack!','units','normalized',...
    'Callback',@hackityhack_callback);
    hackButton.Position(2) = dot([1 1.5],compStatsButton.Position([2 4]));
    hackButton.Position(3)= 1-2*compStatsButton.Position(1);

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
    'String',{'Auto','Auto Center','Left','Right','Max','Max Center','Manual'},...
    'Callback',@cAxisCallback,...
    'Tooltip', 'Color Axis', ...
    'Units','normalized',...
    'Position', [0.05, coordTable.Position(2)-0.175 0.9 0.15]);
cAxisStyle = 'Auto';

% hImg
axes(hImageAxes1)
hImg1 = imagesc(latAxis,axAxis,renderFunc(matData1(:,:,sliceNumber)));
colorbar
set(hImg1,'ButtonDownFcn',@ImageClickCallback);
set(hImageAxes1,'Color','none');
hLeftTitle = title('Left'); hLeftTitle.UserData = hLeftTitle.String;
xlabel('Lat. Dist. (mm)');
ylabel('Depth (mm)');

axes(hImageAxes2)      
hImg2 = imagesc(renderFunc(matData2(:,:,sliceNumber)));
colorbar
set(hImg2,'ButtonDownFcn',@ImageClickCallback);
set(hImageAxes2,'Color','none');
hRightTitle = title('Right'); hRightTitle.UserData = hRightTitle.String;
set([hLeftTitle hRightTitle],'ButtonDownFcn',@LabelCallback)
% linkprop([hUnderlayImg1 hImg1 hUnderlayImg2 hImg2],{'XData','YData'});
xlabel(hImageAxes1.XLabel.String);

axes(hLineAxes)
lineData = evalFunc(matData1(:,lineNumber,sliceNumber));
hLine1 = plot(1:size(matData1,1),lineData); hold on;
hLine2 = plot(1:size(matData1,1),evalFunc(matData2(:,lineNumber,sliceNumber)),'r');
grid on;

fmt = @(s) strrep(s,'`f`',''); % Not intentionally shared
hLegend = legend(fmt(hLeftTitle.String), fmt(hRightTitle.String));
clear fmt;
% Function for updating `f` in title string
frameFmt='%1.1f';
titleRender = @(x) sprintf(frameFmt,x);

%% Struct for external callbacks for programmatic access
extCallbacks.setAxes = @(lat,ax,frame) setAxes_callback(setAxesButton,[],{lat;ax;frame});
% Below doesn't work, because it fixes external values into the callback
% extCallbacks.setLatAxis = @(lat) setAxes_callback(setAxesButton,[],{lat;axAxis;frameAxis});
extCallbacks.setLatAxis = @setLatAxis;
extCallbacks.setAxAxis = @setAxAxis;
extCallbacks.setFrmAxis = @setFrmAxis;
extCallbacks.setFrameFormat = @setFrameFormat;
extCallbacks.setLabel = @setLabel;
extCallbacks.setDirection = @setDirection;
extCallbacks.setCoordinate = @setCoordinate;
extCallbacks.setCaxisStyle = @setCaxisStyle;
extCallbacks.exportGif = @exportGif;
extCallbacks.updatePlots = @updatePlots;
extCallbacks.legend = hLegend;
extCallbacks.Img1 = hImg1;
extCallbacks.Img2 = hImg2;
extCallbacks.ax1 = hImageAxes1;
extCallbacks.ax2 = hImageAxes2;
extCallbacks.ImgAxes = [hImageAxes1 hImageAxes2 hUnderlayAxes1 hUnderlayAxes2];
extCallbacks.lineAxes = hLineAxes;

%% Start GUI
updatePlots;
hMainFigure.Visible = 'on';
figure(hMainFigure); colormap gray;
set([hUnderlayAxes1 hUnderlayAxes2],'XTick',[],'YTick',[])

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
%         gifName = 'comparison.gif';
%         [gifName,fp] = uiputfile('*.gif','Make Gif',gifName);
%         gifName = fullfile(fp,gifName);
%         makeGif(permute(1:size(matData1,3),[1 3 2]),gifName,...
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
            gifName = 'comparison.gif';
            [gifName,fp] = uiputfile('*.gif','Make Gif',gifName);
            gifName = fullfile(fp,gifName);
        else
            gifName = filename;
        end
        if ~exist('delay','var')
            while true
                val = inputdlg('Frame Delay:','Enter Frame Delay',1,{'1/2'});
                [val,stat] = str2num(val{1});
                if stat && ~isequal(val,0)
%                     [val_num,val_den] = rat(val,1e-4);
                    delay = val;
                    break;
                end
            end
        end
        makeGif(permute(1:size(matData1,3),[1 3 2]),gifName,...
            @updateGif,@(x) [],hMainFigure,delay);
        
%         if ~exist('delay','var')
%             while true
%                 val = inputdlg('Frame Delay:','Enter Frame Delay',1,{'1/2'});
%                 [val,stat] = str2num(val{1});
%                 if stat && ~isequal(val,0)
%                     [val_num,val_den] = rat(val,1e-4);
%                     break;
%                 end
%             end
%         else
%             [val_num,val_den] = rat(delay,1e-4);
%             guiFlag = false;
%             msg = @disp;
%         end
%         cmd = sprintf('convert -delay %1.0fx%1.0f %s %s',val_num,val_den,...
%             gifName,gifName);
%         system(cmd);
        
        msg(sprintf('Data stored in %s',gifName));
        function updateGif(i)
            hSlider.Value = i;
            hSliderCallback(hSlider,[]);
        end
    end
    
    function LabelCallback(hObject,eventData,resp)
        prompt = {'Ax. Label'; 'Lat. Label'; 'Left Title'; 'Right Title'};
        defaults = {hImageAxes1.YLabel.String; ...
            hImageAxes1.XLabel.String;...
            hLeftTitle.UserData;
            hRightTitle.UserData};
        resp = inputdlg(prompt,'Set Label',1,defaults);
        setLabel(resp{2},resp{1},resp{3},resp{4})
        
    end
    function setLabel(xLabel,yLabel,leftTitle,rightTitle)
        % SETLABEL Sets the labels of the images
        % setLabel(xLabel,yLabel,leftTitle,rightTitle)
        hLeftTold = hLeftTitle;
        hRightTold = hRightTitle;
        try
            ylabel(hImageAxes1,yLabel);
            xlabel(hImageAxes1,xLabel);
            xlabel(hImageAxes2,xLabel);
            hLeftTitle.UserData = leftTitle;
            hRightTitle.UserData = rightTitle;
            fmt = @(s) strrep(s,'`f`',''); % Not intentionally shared
            hLegend.String(1:2) = {fmt(hLeftTitle.UserData),fmt(hRightTitle.UserData)};
            updatePlots();
        catch
            warning('Error processing data. Reverting...')
            hLeftTitle = hLeftTold;
            hRightTitle = hRightTold;
            updatePlots();
        end
    end

    function setLatAxis(lat)
        setAxes_callback(setAxesButton,[],{lat;axAxis;frameAxis})
        
    end
    
    function setAxAxis(ax)
        setAxes_callback(setAxesButton,[],{latAxis;ax;frameAxis});
    end
    function setFrmAxis(frm)
        setAxes_callback(setAxesButton,[],{latAxis;axAxis;frm});
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
        yLim=ylim(hImageAxes1)-diff(axOld(1:2))*[-0.5 0.5];
        xLim=xlim(hImageAxes1)-diff(latOld(1:2))*[-0.5 0.5];
        [~,yLim(1)] = findClosest(axOld,yLim(1));
        [~,yLim(2)] = findClosest(axOld,yLim(2));
        [~,xLim(1)] = findClosest(latOld,xLim(1));
        [~,xLim(2)] = findClosest(latOld,xLim(2));
        yLim = axAxis(yLim)+diff(axAxis(1:2))*0.5*[-1 1];
        xLim = latAxis(xLim)+diff(latAxis(1:2))*0.5*[-1 1];
        
        % Update handles
        set([hImg1,hImg2]...,'CData',renderFunc(matData(:,:,sliceNumber))...
            ,'YData',axAxis...
            ,'XData',latAxis...
        );
        set([hUnderlayImg1 hUnderlayImg2],'YData',axAxis,'XData',latAxis);
        xlim(hImageAxes1,xLim); ylim(hImageAxes1,yLim);
        xlim(hImageAxes2,xLim); ylim(hImageAxes2,yLim);
        
        updatePlots;
        if updateLabels
            LabelCallback(hObject,eventData);
        end
    end
    
    function updateAxes(latNew,axNew,latOld,axOld)
        % Rederive limits on old axes
        % Image toolbox likes half pixel edges
        yLim=ylim(hImageAxes1)-diff(axOld(1:2))*[-0.5 0.5];
        xLim=xlim(hImageAxes1)-diff(latOld(1:2))*[-0.5 0.5];
        [~,yLim(1)] = findClosest(axOld,yLim(1));
        [~,yLim(2)] = findClosest(axOld,yLim(2));
        [~,xLim(1)] = findClosest(latOld,xLim(1));
        [~,xLim(2)] = findClosest(latOld,xLim(2));
        yLim = axAxis(yLim)+diff(axAxis(1:2))*0.5*[-1 1];
        xLim = latAxis(xLim)+diff(latAxis(1:2))*0.5*[-1 1];
        
        % Update handles
        set([hImg1,hImg2]...,'CData',renderFunc(matData(:,:,sliceNumber))...
            ,'YData',axAxis...
            ,'XData',latAxis...
        );
        set([hUnderlayImg1 hUnderlayImg2],'YData',axAxis,'XData',latAxis);
        xlim(hImageAxes1,xLim); ylim(hImageAxes1,yLim);
        xlim(hImageAxes2,xLim); ylim(hImageAxes2,yLim);
        
        updatePlots;
        if updateLabels
            LabelCallback(hObject,eventData);
        end
    end

    function compStats_callback(hObj, evnt)
        warning('Work in Progress');
        fprintf('Left\tMin\tMax\tMean\tStd\n')
        fprintf('\t%1.4e,%1.4e,%1.4e,%1.4e\n',...
            min(matData1(:)),max(matData1(:)),...
            mean(matData1(:)),std(matData1(:)))
        
        fprintf('Right\tMin\tMax\tMean\tStd\n');
        fprintf('\t%1.4e,%1.4e,%1.4e,%1.4e\n',...
            min(matData2(:)),max(matData2(:)),...
            mean(matData2(:)),std(matData2(:)))
        
        fprintf('Diff\tMin\tMax\tMean\tStd\n');
        fprintf('\t%1.4e,%1.4e,%1.4e,%1.4e\n',...
            min(abs(matData1(:)-matData2(:))),max(abs(matData1(:)-matData2(:))),...
            mean(abs(matData1(:)-matData2(:))),std(abs(matData1(:)-matData2(:))))
        
    end
    function cAxisCallback( objectHandle , eventData )
        styles = get(objectHandle,'String');
        style = styles{get(objectHandle, 'Value')};
        setCaxisStyle(style);
    end
    function setCaxisStyle(s,clim1,clim2,titleStr)
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
                    if nargin==1
                        prompt = {'Min:', 'Max:', 'Unit:'};
                        defaults = compose('%1.1f',get(hImageAxes1,'CLim'));
                        defaults{end+1} = '';
                        resp=inputdlg(prompt,'Set CAxis',1,defaults);
                        titleStr = resp{3};
                        resp=cellfun(@str2num,resp(1:2));
                        validateattributes(resp,{'numeric'},{});
                        assert(resp(2)>resp(1),'Invalid CLim: Reverting...');
                        updateCaxis();
                        caxis(hImageAxes1,resp(:)');
                        caxis(hImageAxes2,resp(:)');
                        title(colorbar(hImageAxes1),titleStr);
                        title(colorbar(hImageAxes2),titleStr);
                    elseif nargin > 1
                        if nargin==2
                            clim2 = clim1;
                        end

                        caxis(hImageAxes1,clim1)
                        caxis(hImageAxes2,clim2)
                        if nargin==4
                            if ischar(titleStr) || isstring(titleStr)
                                title(colorbar(hImageAxes1),titleStr);
                                title(colorbar(hImageAxes2),titleStr);
                            else
                                warning('Invalid titleStr');
                            end
                        end
                        updateCaxis();
                    end
                catch
                    warning('Error processing cAxisCallback')
                    cAxisStyle = s;
                    updateCaxis();
                end
            case 'Left'
                cAxisStyle = style;
            case 'Right' 
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
                sliceNumber = min(max(1,round(coordinate)),size(matData1,3));
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
        set(hImg1,'CData',renderFunc(matData1(:,:,sliceNumber))...);
            ...,'YData',axAxis...
            ...,'XData',latAxis...
        );
        set(hImg2,'CData',renderFunc(matData2(:,:,sliceNumber))...);
            ...,'YData',axAxis...
            ...,'XData',latAxis...
        );
        
        updateCaxis();
        %% calculate axes
        %[xData, yData, cData1] = getimage(hImageAxes1);
        %[xData, yData, cData2] = getimage(hImageAxes2);
        %dx = diff(xData)/(size(cData1,2)-1);
        %dy = diff(yData)/(size(cData1,1)-1);
        %xAxis = xData(1):dx:xData(2);
        %yAxis = yData(1):dy:yData(2);
        %assert(isequal(length(latAxis),size(cData1,2)),'Error: Bad xAxis length');
        %assert(isequal(length(axAxis),size(cData1,1)),'Error: Bad yAxis length');
        [hPointer(1),ind(1)] = findClosest(latAxis,hPointer(1));
        [hPointer(2),ind(2)] = findClosest(axAxis,hPointer(2));
        set(coordTable,'data',[flipud(ind(:))' sliceNumber]);

        deleteLines = @(ax) delete(findobj(ax,'Type','ConstantLine'));
        addXLine = @(ax,val,col) xline(ax,val,col,'LineWidth',2);
        addYLine = @(ax,val,col) yline(ax,val,col,'LineWidth',2);
        switch lineDir
            case 'Vertical'
                [~,lineNumber] = findClosest(latAxis,hPointer(1));
                % mask = ones(size(matData1(:,:,1))); mask(:,lineNumber)=0;
                % hImg1.AlphaData = mask;
                % hImg2.AlphaData = mask;
                
                deleteLines([hImageAxes1 hImageAxes2])
                addXLine(hImageAxes1,latAxis(lineNumber),'b')
                addXLine(hImageAxes2,latAxis(lineNumber),'r')
%                 axes(hLineAxes)
%                 lineData = evalFunc(matData1(:,lineNumber,sliceNumber));
%                 plot(yAxis,lineData);
%                 grid on;
                set(hLine1,'XData',axAxis,...
                    'YData', evalFunc(matData1(:,lineNumber,sliceNumber)));
                set(hLine2,'XData',axAxis,...
                    'YData', evalFunc(matData2(:,lineNumber,sliceNumber)));
            case 'Horizontal'
                [~,lineNumber] = findClosest(axAxis,hPointer(2));
                % mask = ones(size(matData1(:,:,1))); %mask(lineNumber,:)=0;
                % hImg1.AlphaData = mask;
                % hImg2.AlphaData = mask;
                deleteLines([hImageAxes1 hImageAxes2])
                addYLine(hImageAxes1,axAxis(lineNumber),'b')
                addYLine(hImageAxes2,axAxis(lineNumber),'r')
%                 axes(hLineAxes)
%                 lineData = evalFunc(matData1(lineNumber,:,sliceNumber));
%                 plot(xAxis,lineData);
%                 grid on;
                set(hLine1,'XData',latAxis,...
                    'YData', evalFunc(matData1(lineNumber,:,sliceNumber)));
                set(hLine2,'XData',latAxis,...
                    'YData', evalFunc(matData2(lineNumber,:,sliceNumber)));

            case 'Normal'
                [hPointer(1),ind(1)] = findClosest(latAxis,hPointer(1));
                [hPointer(2),ind(2)] = findClosest(axAxis,hPointer(2));
                lineNumber = 0;
                % mask = ones(size(matData1(:,:,1))); 
                % mask(:,ind(1))=0; mask(ind(2),:) = 0;
                deleteLines([hImageAxes1 hImageAxes2])
                addXLine(hImageAxes1,latAxis(ind(1)),'b')
                addXLine(hImageAxes2,latAxis(ind(1)),'r')
                addYLine(hImageAxes1,axAxis(ind(2)),'b')
                addYLine(hImageAxes2,axAxis(ind(2)),'r')
                hImg1.AlphaData = mask;
                hImg2.AlphaData = mask;
%                 axes(hLineAxes)
%                 lineData = evalFunc(squeeze(matData1(ind(2),ind(1),:)));
%                 hLine = plot(frameAxis,lineData);
%                 hold on
%                 plot(frameAxis(sliceNumber),lineData(sliceNumber),'ro');
%                 hold off
%                 grid on;
                set(hLine1,'XData',frameAxis,...
                    'YData', evalFunc(squeeze(matData1(ind(2),ind(1),:))));
                set(hLine2,'XData',frameAxis,...
                    'YData', evalFunc(squeeze(matData2(ind(2),ind(1),:))));
            
            otherwise 
                error('Error: Invalid lineDir (%s)',lineDir');
        end
        
        % Update Statistics
        updateStats();
        
        % Reset Tags on figure update
        hImageAxes1.Tag = 'hImageAxes1';
        hLineAxes.Tag =  'hLineAxes';
        
        % Update titles if necessary
        try
            hLeftTitle.String = strrep(hLeftTitle.UserData,'`f`',...
                ...sprintf('%1.1e',frameAxis(sliceNumber)));
                titleRender(frameAxis(sliceNumber)));
            hRightTitle.String = strrep(hRightTitle.UserData,'`f`',...
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
                xlabel(hLineAxes,hImageAxes1.YLabel.String);
                title(hLineAxes,'Ax. Cross Section')
            case directions{2} % Horizontal
                xlabel(hLineAxes,hImageAxes1.XLabel.String);
                title(hLineAxes,'Lat. Cross Section')
            case directions{3} % Normal
                xlabel(hLineAxes,'');
                title('')
        end
        lineDirButton.String = lineDir;
        
    end

    function updateCaxis
        % Set Clim Mode
        if isequal(cAxisStyle,'Auto')
            set([hImageAxes1 hImageAxes2],'CLimMode','auto')
            return
        elseif isequal(cAxisStyle,'Auto Center')
            set([hImageAxes1 hImageAxes2],'CLimMode','manual')
            caxis(hImageAxes1,max(max(abs(renderFunc(matData1(:,:,sliceNumber)))))*[-1 1])
            caxis(hImageAxes2,max(max(abs(renderFunc(matData2(:,:,sliceNumber)))))*[-1 1])
            return
        elseif isequal(cAxisStyle,'Left')
            set(hImageAxes1,'CLimMode','auto');
            caxis(hImageAxes2,get(hImageAxes1,'CLim'));
            return
        elseif isequal(cAxisStyle,'Right')
            set(hImageAxes2,'CLimMode','auto');
            caxis(hImageAxes1,get(hImageAxes2,'CLim'));
            return
        else 
            set([hImageAxes1 hImageAxes2],'CLimMode','manual')
            return
        end
        %% Get Caxis
        switch cAxisStyle
            case 'Max'
                c_max = max(max(renderFunc(matData1(:,:,1))));
                c_min = min(min(renderFunc(matData1(:,:,1))));
                for k = 1:max(size(matData1,3))
                    c_max = max(c_max,...
                        max(max([renderFunc(matData1(:,:,k))...
                        renderFunc(matData2(:,:,k))])));
                    c_min = min(c_min,...
                        min(min([renderFunc(matData1(:,:,k))...
                        renderFunc(matData2(:,:,k))])));
                end
                caxis(hImageAxes1,[c_min,c_max]);
                caxis(hImageAxes2,[c_min,c_max]);
            case 'Max Center'
                c_max = max(max(abs(renderFunc(matData1(:,:,1)))));
                for k = 1:max(size(matData1,3))
                    c_max = max(c_max,...
                        max(max(abs([renderFunc(matData1(:,:,k))...
                        renderFunc(matData2(:,:,k))]))));
                end
                caxis(hImageAxes1,c_max*[-1 1]);
                caxis(hImageAxes2,c_max*[-1 1]);
            otherwise
                error('Unsupported cAxisStyle: %s',cAxisStyle);
        end
    end

    function updateStats()
        % If stats window is visible update, otherwise skip
        
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
