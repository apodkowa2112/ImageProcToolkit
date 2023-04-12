function out = isdef(varName)
% ISDEF Checks if variable is defined (exists and nonempty)
% Usage isdef('A') is equivalent to "exist('A','var') && ~isempty(A)"
% Seems to work with struct fields, though when the goal is to detect empty
% struct fields isfield() is preferable
% See also isfield
    out = false;
    try
        out = ~isempty(evalin("caller",varName));
    catch
        return
    end
end