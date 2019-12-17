function [out,func] = taylorfunc(time,nbar,sll)
% TAYLORFUNC Returns values for continuous Taylor window
% function [out,func] = taylorfunc(t,nbar,sll)
% out = Values at time
% func = function handle to evaluate at arbitrary time
%
% Note: The following should be equivalent:
%   t = -k:k;
%   taylorwin(length(t),nbar,sll) = taylorfunc(t/length(t),nbar,ssl)
%
% [1] "Catalog of Window Taper Functions for Sidelobe Control", Sandia
% National Laboratory, April 2017
%% Compute coeffs
coeffs = comp_coeffs(nbar,sll);

%% Compute output
    function out_t = eval_taylor(t)
        out_t = ones(size(t));
        mask = abs(t)<=0.5;
        m = 1:(nbar-1);
        out_t(mask(:)) = 1+...
            (2*coeffs(:)'*cos(2*pi*m(:)*t(mask(:))));
    end

    out = eval_taylor(time);
    func = @eval_taylor;
end

function coeffs = comp_coeffs(nbar,sll)
    %% Compute Parameters
    A = acosh(db2mag(abs(sll)))/pi;
    sigma2 = nbar^2/(A^2+(nbar-0.5).^2);
    m = 1:(nbar-1);
    
    %% Compute coeffs
    coeffs = bsxfun(@(m,n) 1-m.^2./(sigma2.*(A^2+(n-0.5).^2)),m,m(:));
    coeffs = 0.5*prod(coeffs,1);
    coeffs(m(2:2:end)) = -coeffs(m(2:2:end)); %-(-1)^m
    
    %% Renormalize
    norm_coeffs = bsxfun(@(m,n) 1-(m.*double(m~=n)./n).^2,m,m(:));
    norm_coeffs = prod(norm_coeffs,1);
    coeffs = coeffs./norm_coeffs;
    
end