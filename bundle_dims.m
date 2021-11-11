function [out,arr_size] = bundle_dims(arr, dims)
% BUNDLE_DIMS Squash specific dimensions of an array
% function out = bundle_dims(arr, dims) 
% This collapses the N dimensional array such that dimension dims(1) of the
% output is the product of the input dimensions between dims(1) and
% dims(2).
% Example: size(bundle_dims(randn(1:5),2:3),[]) returns [1 6 4 5]
% 
% The input array size is returned as a secondary output to facilitate
% inversion. For example, 
%   [out,orig_size] = bundle_dims(arr,dims); 
%   reshape(out, orig_size) returns the original array.

arr_size = size(arr);
if numel(arr_size) <dims(end) % For unexpected matrix squashing
    arr_size(end+1:dims(end)) = 1;
end
out_size = arr_size;

out_size(dims(1)) = prod(arr_size(dims(1):dims(end)));
out_size((dims(1)+1):dims(end)) = [];

% In case the function collapses down to a vector
if numel(out_size)==1
    out_size(2)=1;
end

try
    out = reshape(arr,out_size);
catch
    warning('Error reshaping data.')
    warning('Input Size:')
    f = get(0,'FormatSpacing');
    format short
    disp(arr_size)
    warning('Output Size:')
    disp(out_size)
    warning('Dims:')
    disp(dims)
    format(f);
    error('Check inputs accordingly')
end
    

end