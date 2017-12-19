function makeGif(data, outfile, renderFunc,figHandle)
% MAKEGIF Makes a gif of the data
% Loops over last dimension of data
% Supported Syntaxes
% function makeGif(data, outfile, renderFunc)
% function makeGif(data, outfile, renderFunc, figHandle)

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
%% 
numFrames = size(data,ndims(data));

%% Generate figure and loop over frames
figHandle = figure(figHandle);

for f=1:numFrames
 
    %% plotting kernel
    renderFunc(index(data,f));
 
    %% gif utilities
    % set(gcf,'color','w'); % set figure background to white
    drawnow;
    frame = getframe(figHandle);
    im = frame2im(frame);
    [imind,cm] = rgb2ind(im,256);
 
    % On the first loop, create the file. In subsequent loops, append.
    if f==1
        imwrite(imind,cm,outfile,'gif','DelayTime',0,'loopcount',inf);
    else
        imwrite(imind,cm,outfile,'gif','DelayTime',0,'writemode','append');
    end
 
end

end