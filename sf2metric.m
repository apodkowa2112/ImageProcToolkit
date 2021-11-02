function str = sf2metric(sf,str)
% SF2METRIC Convert scale factor to metric prefix
% function char = sf2metric(sf)
if ~exist('str','var')
    str='%s';
end
order = floor(log10(sf)/3);
arr = {'y','z','a','f','p','n','\mu','m','','k','M','G','T','P','E','Z','Y'};
for k=1:length(arr)
    if isequal(arr{k},'')
        zero=k;
        break;
    end
end
try
char = arr{zero+order};
catch exc
    warning('Scale factor (%1.1f) out of bounds',sf)
    throw(exc)
end
str = sprintf(str,char);
end