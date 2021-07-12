function out = bufsplit(buffer,endSample)
%% BUFSPLIT Split VSX buffer & Reshape
% out = bufsplit(buffer,endSample) reshapes a VSX buffer to the indexing
% convention (time, channel, transmit) for easy interpretation.  The
% endSample represents the last sample of the Rx event
% (i.e. Receive(1).endSample), which is assumed to be uniform across all
% events in the buffer.  Excess data after the last frame will be ignored.

%% Handle Arguments
if isequal(class(buffer),'cell')
    warning('Buffer is a cell array. Defaulting to first buffer.')
    buffer = buffer{1};
end

%% Initial Sanity Checks
assert(endSample>1,'Invalid endSample: %1.0f',endSample);
assert(size(buffer,1)>=endSample,...
    'Buffer length (%1.0f) smaller than endSample (%1.0f)',...
    size(buffer,1),endSample)

%% Trim excess samples from buffer
lastValid = floor(size(buffer,1)/endSample)*endSample;
buffer = buffer(1:lastValid,:);

%% Reshape buffer to sane dimensions
buffer = reshape(buffer,endSample,[],size(buffer,2));
out = permute(buffer,[1 3 2]);

end