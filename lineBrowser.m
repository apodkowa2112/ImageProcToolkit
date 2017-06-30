function varargout = lineBrowser(varargin)
% LINEBROWSER Browse lines in a 2D matrix

%% Initialization
switch length(varargin)
    case 1
        matData = varargin{1};
        lineNumber = 1;
        lineDir = 'Vertical';
        renderFunc = @(x) x;
    otherwise
        error('Error: Unsupported Number of Arguments')
end
        

%% Constructors
% figure
hMainFigure = figure('Name','lineBrowser','Visible','off',...
    'Toolbar','figure');

% Generate axes
hImageAxes = subplot(3,1,[1 2]);
hImageAxes.Tag = 'hImageAxes';
colormap(hImageAxes,gray);

hLineAxes = subplot(3,1,3);
hLineAxes.Tag = 'hLineAxes';
grid(hLineAxes,'on');

% Generate pointer for 
hPointer = zeros(1,2);

%% Component initialization
lineDirButton = uicontrol('Style','pushbutton','String',lineDir,...
    'ToolTip','Line Direction','Callback',@lineDirButton_callback);

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

%% Utility functions
    function updatePlots
        figure(hMainFigure)
        axes(hImageAxes)
        
        hImg = imagesc(renderFunc(matData));
        colorbar
        set(hImg,'ButtonDownFcn',@ImageClickCallback);
        
        % calculate axes
        [xData, yData, cData] = getimage(hImageAxes);
        dx = diff(xData)/(size(cData,2)-1);
        dy = diff(yData)/(size(cData,1)-1);
        xAxis = xData(1):dx:xData(2);
        yAxis = yData(1):dy:yData(2);
        assert(isequal(length(xAxis),size(cData,2)),'Error: Bad xAxis length');
        assert(isequal(length(yAxis),size(cData,1)),'Error: Bad yAxis length');
        
        switch lineDir
            case 'Vertical'
                [~,lineNumber] = findClosest(xAxis,hPointer(1));
                line(xAxis(lineNumber)*[1 1],yData...
                    ,'Color','g','LineWidth',3);
                axes(hLineAxes)
                plot(yAxis,matData(:,lineNumber));
                grid on;
                
            case 'Horizontal'
                [~,lineNumber] = findClosest(yAxis,hPointer(2));
                line(xData,xAxis(lineNumber)*[1 1]...
                    ,'Color','g','LineWidth',3);
                axes(hLineAxes)
                plot(xAxis,matData(lineNumber,:));
                grid on;
            otherwise 
                error('Error: Invalid lineDir (%s)',lineDir');
        end
        
        % Reset Tags on figure update
        hImageAxes.Tag = 'hImageAxes';
        hLineAxes.Tag =  'hLineAxes';
    end

    function toggleDirection
        if isequal(lineDir,'Vertical')
            lineDir = 'Horizontal';
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