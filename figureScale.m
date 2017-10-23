function pp = figureScale(fig,height, width)
%% FIGURESCALE Scale the figure to sane dimensions without fiddling with PaperPosition
% function figureScale(fig,height, width)
margin = 0.25;
topPage = 11-margin; 
left = margin;
bottom = topPage-margin-height;
pp = [left bottom width height];
if fig~=0
    set(fig,'Units','inches');
    set(fig,'PaperUnits','inches');
    set(fig,'PaperPosition',pp);
    set(fig,'Position',pp);
end
end