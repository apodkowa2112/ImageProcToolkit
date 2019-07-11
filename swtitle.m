function swtitle(handle,string,varargin)
% SWTITLE Title an object rotated sideways
% function swtitle(handle,string)
% function swtitle(handle,string,options)
% Usage: swtitle(colorbar,'units')

if ~exist('varargin','var'); varargin = {}; end
varargin = [varargin 'String',string,...
    'VerticalAlignment','middle','Rotation',270];
set(get(handle,'XLabel'),varargin{:})
