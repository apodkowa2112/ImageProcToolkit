function saveFigEps(fh,name,opt)
% SAVEFIGEPS Saves the figure with handle 'fh' as a .fig file and an .eps file 
%
% INPUTS
% fh    : figure handle
% name  : filename without extension
%
% Last edited 08/06/2015 Chao Ma
% Add a workround for MATLAB2014b on Mac
% Last edited 03/20/2015 Bryan A Clifford
%-------------------------------------------------------------------------------

    if exist('opt','var')
        if ~isfield(opt,'loose')
            opt.loose = false;
        end
        if ~isfield(opt,'do_save')
            opt.do_save = true;
        end
        if ~isfield(opt,'do_save_fig')
            opt.do_save_fig = true;
        end
    else
        opt.loose = false;
        opt.do_save = true;
        opt.do_save_fig = true;
    end

    if opt.do_save
        if opt.do_save_fig
            hgsave(fh, [name '.fig']);
        end
        set(fh, 'PaperPositionMode', 'auto',...
                'color','none',...
                'inverthardcopy','off', ...
                'PaperUnits','normalized');
        if opt.loose
            print(fh, '-depsc','-r600', '-loose', [name '.eps']);
        else    
            print(fh, '-depsc','-r600', [name '.eps']);
        end
        
        set(fh, 'color','w');
    end
    
end
