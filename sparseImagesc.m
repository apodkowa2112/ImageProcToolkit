function hImg = sparseImagesc( varargin )
%SPARSEIMAGESC CleanImagesc with sparse visualization

%% Spawn underlayAxis
hAxUnderlay = gca;
set(hAxUnderlay,'visible', 'off');

%% Link axes
hImgAxes = axes('color','none','Position',get(gca,'Position'));
linkaxes([hImgAxes,hAxUnderlay]);
linkprop([hImgAxes,hAxUnderlay],{'Position'} );

%% Render Image
hImg = imagesc(varargin{:});
colormap gray
colorbar

%% Turn off background
set(hImgAxes,'color','none');

%% Get rendered data
Hdata = get(hImg, 'CData');

%% Force symmetric color range
range = max(abs(Hdata(:)))*[-1 1];
caxis(range);

%% Calculate mask
mask = ~(Hdata==0);
set(hImg,'AlphaData',mask);

%% Render Underlay
axes(hAxUnderlay)
imagesc(get(hImg,'XData'),get(hImg,'YData'),...
    ones(size(Hdata)),'Parent',hAxUnderlay);
colormap(hAxUnderlay,flipud(hsv(2)));
caxis(hAxUnderlay,[0 1]);
set(hAxUnderlay,'visible','on');

%% Reset axes
axes(hImgAxes);
linkaxes([hImgAxes,hAxUnderlay]);
linkprop([hImgAxes,hAxUnderlay],{'Position'} );

%% Return
if nargout== 0
    clear hImg;
end

end

