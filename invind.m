function out = invind(input,valset)
% INVIND Returns the indicies in valset associated with numbers in input  
% function out = invind(input,valset)
% Ex input = [-2 0.5; 1 2], valset = -2:0.5:2; ==> output = [1, 6; 7 9 ]
%
% Note: if all(ismember(input,valset))=1, then
%   input == valset(invind(input,valset)

out = zeros(size(input));

for v=1:length(valset)
    out(input==valset(v)) = v;
end