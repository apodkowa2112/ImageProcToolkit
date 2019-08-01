function filepath = uigetfilepath(varargin)
% UIGETFILEPATH Returns the full filepath to file selected with UI.
% filepath = uigetfilepath(FILTERSPEC, TITLE)
% See: uigetfile
    [fn,fp] = uigetfile(varargin{:});
    filepath = [fp fn];
    
end