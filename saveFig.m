function saveFig(handle,filepath,dst_exts)
%SAVEFIG Saves figure with specified extensions to path
%   saveFig(handle)
%   saveFig(handle,filepath)
%   saveFig(handle,filepath,dst_exts)
    if exist('filepath','var')==0 || isempty(filepath) 
        filepath = sprintf('./%s',handle.Name);
    end
    if filepath(end)=='/'
        filepath = fullfile(filepath,handle.Name);
    end
    if exist('dst_exts','var')==0
        dst_exts = {'.fig','.png'};
    end
    
    exts = {'.fig', '.png', '.eps', '.jpg', '.svg' };
    if any(strcmpi(filepath(end-3:end),exts))
        filepath = filepath(1:end-3);
    end
    
    for d=1:length(dst_exts)
        f = sprintf('%s%s',filepath,dst_exts{d});
        if exist(f,'file')
            delete(f);
        end
        saveas(handle,f);
    end
    
end