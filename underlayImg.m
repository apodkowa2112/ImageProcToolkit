function [hAxUnderlay,hImg] = underlayImg(ax,img,mask,cLim)
% UNDERLAYIMG Underlay an image in a matlab figure
% function hAxUnderlay = underlayImg(ax,img,mask,cLim)

    %% Turn off axis
    ax.Visible = 'off';
    
    %% Get img handle from axis
    imgHandle = findall(ax,'Type','Image');
    assert(length(imgHandle)==1,'Multiple Image handles found.')
    
    %% Make background transparent
    imgHandle.AlphaData = mask;
    
    %% Spawn new axis for figure
    hAxUnderlay = axes();
    
    %% Render figure
    hImg = imagesc(imgHandle.XData,imgHandle.YData,img,'Parent',hAxUnderlay);
    caxis(cLim);
    colormap(hAxUnderlay,gray);
    
    %% Reset axes
    axes(ax);
    
    %% Turn titles back on
    set(findall(ax,'type','text'),'visible','on');
    
    %% Link axes
    linkaxes([ax,hAxUnderlay]);
    linkprop([ax,hAxUnderlay],{'Position'} );
    
    %% Return
    if nargout== 0
        clear hAxUnderlay;
    end

end