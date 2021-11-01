function [hData,hCent] = histoseries(data)
%% HISTOSERIES Common data histogram for time series
% function [hData] = histoseries(data)
% function [hData,hCent] = histoseries(data)
%
% This function evaluates the histogram in the second dimension and
% interpolates the histogram to a common grid.
% hCent gives the centroid of the values for plotting.
% The hot colormap works well for this. 

opts={'Normalization','pdf'};
for k=1:size(data,1)
    [histo(k).data,histo(k).edges] = histcounts(data(k,:),opts{:});
    binCent = conv(histo(k).edges,0.5*[1 1],'same');
    histo(k).cent = binCent(1:end-1);  
end

hCent = min([histo(:).cent]):diff(histo(k).cent(1:2)):max([histo(:).cent]);

hData = zeros(size(data,1),length(hCent));
for k=1:length(histo)
    hData(k,:) = interp1(histo(k).cent,histo(k).data,hCent,'linear',0);
end

hData = hData./sum(hData,2);

% if nargout>0
%     clear hData
% end
end