function makeGif(data, outfile, renderFunc,titleFunc,figHandle)
% MAKEGIF Makes a gif of the data
% Loops over last dimension of data
% Supported Syntaxes
% function makeGif(data, outfile, renderFunc,titleFunc,)
% function makeGif(data, outfile, renderFunc,titleFunc,figHandle)
% Example titleFunc:
%titleFunc = @(f)...
%    title(sprintf('Reg. Param: %1.1e',...
%        evalin('base',sprintf('regParamList(%f)',f))));
%% Handle arguments
switch ndims(data)
    case 2
        index = @(x,ind) x(:,ind);
    case 3
        index = @(x,ind) x(:,:,ind);
    otherwise
        error('Indexing not supported for data of these dimensions.')
end

if ~exist('figHandle','var')
    figHandle = gcf;
end

if ~exist('titleFunc','var')
    titleFunc = @(f) [];
end
%% 
numFrames = size(data,ndims(data));

%% Generate figure and loop over frames
figHandle = figure(figHandle);


for f=1:numFrames
 
    %% plotting kernel
    renderFunc(index(data,f));
    %title(sprintf('Reg. Param: %1.1e',evalin('base',sprintf('regParamList(%f)',f))));
    titleFunc(f);
    %% gif utilities
    % set(gcf,'color','w'); % set figure background to white
    drawnow;
    frame = getframe(figHandle);
    im = frame2im(frame);
    [imind,cm] = rgb2ind(im,256);
 
    % On the first loop, create the file. In subsequent loops, append.
    if f==1
        imwrite(imind,cm,outfile,'gif','DelayTime',1,'loopcount',inf);
    else
        imwrite(imind,cm,outfile,'gif','DelayTime',1,'writemode','append');
    end
 
end

end