function filepath = uigetfilepath(varargin)
% UIGETFILEPATH Returns the full filepath to file selected with UI.
    [fn,fp] = uigetfile(varargin{:});
    filepath = [fp fn];
end