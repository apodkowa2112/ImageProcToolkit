function h = cleanImagesc( varargin )
%CLEANIMAGESC Adds "colormap gray, colorbar" to imagesc
h = imagesc(varargin{:});
colormap gray
colorbar

end

