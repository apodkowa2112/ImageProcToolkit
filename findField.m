function outString = findField(InStruct, searchString)
%% FINDFIELD Recursively searches struct for searchString.
%
% function outString = findField(InStruct, searchString)
% Right now, this does not use regexs and strings are case insensitive for
% simplicity and maximum matching.
% The output can be further refined using contains() if necessary, which is
% case sensitive by default.
%
% See also contains (R2019b)

    %% Handle Arguments
    assert(nargin>=2,           'Invalid number of inputs: %d',     nargin);
    assert(isstruct(InStruct),  'Input is not a struct. Class: %s', class(InStruct));
    assert(ischar(searchString) || isstring(searchString), 'Search string invalid class: %s', class(searchString))
    searchString = string(searchString); % in case of char array
    inName   = inputname(1); 
    assert(isequal(evalin("caller",inName),InStruct),...
        "Internal Error: Make sure argument number corresponds to %s", getname(InStruct))
    %% Build array of strings
    strArr   = buildArr(InStruct, inName);

    %% Filter out strings that do not contain search string
    outString = strArr(contains(strArr,searchString,"IgnoreCase",true));

end

function name = getname(var)
    name = inputname(1);
end

function outString = buildArr(InStruct,inName)
% BUILDARR Builds an array of strings recursively
% function outString = buildArr(InStruct,inName)
% Note: for efficiency reasons associated with recursive implementation,
% the inputs are assumed to be appropriately typed and valid
%
%   InStruct:   (struct) to be traversed
%   inName:     (string) containing the struct name
%
%   outString:  (string) column vector of strings associated with the field names

    %% Setup
    % inName    = string(inName); % Removed for efficiency reasons
    fieldArr  = string(fieldnames(InStruct));
    outString = []; % Will be converted to string class below
    
    %% Main loop
    for f=1:length(fieldArr)
        field    = fieldArr(f);
        fullname = inName + "." + field;
        if isequal(class(InStruct.(field)),"struct")
            outArr = buildArr(InStruct.(field),fullname);
        else
            outArr = fullname;
        end % if isstruct

        outString = [outString; outArr]; %#ok<AGROW> Size not known a priori due to recursion
    end
    
end