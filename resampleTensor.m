function [rsTensor, interpFilt] = resampleTensor(tensor,p,q,dim)
% RESAMPLETENSOR Resamples the tensor at a rate of p/q
% function [rsTensor, interpFilt] = resampleTensor(tensor,p,q,)
% function [rsTensor, interpFilt] = resampleTensor(tensor,p,q,dim)
%
% Based on behavior of built-in resample function, which only supports
% matrices.

%% Handle arguments
if ~exist('dim', 'var'); dim = 1; end

%% Sanity Checks
validateattributes(p,{'numeric'},...
    {'positive','finite','scalar'},mfilename,'p (or Fout)',2);
validateattributes(q,{'numeric'},...
    {'positive','finite','scalar'},mfilename,'q (or Fin)',3);

%% Force integer ratio
[p,q] = rat(p/q, 1e-12);
if (p==1) && (q==1)
    rsTensor = tensor;
    interpFilt=1;
    return
end
%% Build filter
% Always odd order
interpFilt = buildFilter(p,q,size(tensor,dim));

%% Delay to ensure center tap preserved after downsampling
filtZero = (length(interpFilt)-1)/2;
delay = floor(q-mod(filtZero,q));
interpFilt = [zeros(delay,1); interpFilt];
filtZero = filtZero+delay;
% Induced delay in output sequence due to filter
filtDelay = floor(ceil(filtZero)/q);

%% Pad end such that output equal (Lx*p/q)
% length(upfirdn(x,h,p,q)) == ceil(((Lx-1)p+Lh)/q)
padEnd = max(q*filtDelay+p-length(interpFilt),0);
interpFilt = [interpFilt; zeros(padEnd,1)];
assert(ceil((size(tensor,dim)-1)*p+length(interpFilt)/q)-filtDelay>=...
    ceil(size(tensor,dim)*p/q),'Filter length check failed.');

%% Permute tensor such that resample dimension is first
pdim = circshift(1:ndims(tensor),[0 -(dim-1)]);
tensor=permute(tensor, pdim);

%% Resample
rsTensor = upfirdn(tensor(:,:),interpFilt,p,q);

%% Remove trailing and ending zeros
rsTensor = rsTensor(filtDelay+(1:ceil(p*size(tensor,1)/q)),:);

%% Reshape tensor and permute data back to original dims
rsTensor = reshape(rsTensor,[],size(tensor,2),size(tensor,3));
rsTensor = ipermute(rsTensor,pdim);



function filt = buildFilter(p,q,~)
    % kaiser windowed LS filter, based on resample's default (R2017b)
    % leaving placeholder for derived filter order based on signal length.
    beta = 5; halfWidth = 10;
    fCutoff = 0.5/max(p,q);
    len = 2*halfWidth*max(p,q)+1;
    filt = firls(len-1, [0 2*fCutoff*[1 1] 1], [1 1 0 0] );
    filt = filt(:).*kaiser(len,beta);
    filt = p*filt/sum(filt);
    
    
