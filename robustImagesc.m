function h = robustImagesc( latAxis, axAxis, img, dynRange)
%ROBUSTIMAGESC imagesc with axis checking support & scaling dynRange
%   Dependencies: cleanImagesc.m

%% Sanity checks
if ~isequal(size(latAxis(:)),[size(img,2) 1])
    whos latAxis img
    error('latAxis Mismatch')
elseif ~isequal(size(axAxis(:)),[size(img,1) 1])
    whos axAxis img
    error('axAxis Mismatch')
    
elseif exist('dynRange','var')
    
    if numel(dynRange) == 1
        dynRange = [dynRange 0];
    end
end

%% Plot image
if exist('dynRange','var')
    h = cleanImagesc(latAxis,axAxis, img, dynRange + max(img(:)));
else
    h = cleanImagesc(latAxis,axAxis, img);
end


end

