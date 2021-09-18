function out = rcvsplit(buffer,Receive)
%% RCVSPLIT Split VSX buffer & Reshape
% out = rcvsplit(buffer,Receive) reshapes a VSX buffer to the indexing
% convention (time, channel, acq, frame) as defined in the Receive struct

%% Handle Arguments
if isequal(class(buffer),'cell')
    warning('Buffer is a cell array. Defaulting to first buffer.')
    buffer = buffer{1};
end

%% Initial Sanity Checks

%% Reshape buffer to sane dimensions
for r=1:length(Receive)
    rec = Receive(r);
    out(:,:,rec.acqNum,rec.framenum) = buffer(rec.startSample:rec.endSample,:,rec.framenum);
end

end