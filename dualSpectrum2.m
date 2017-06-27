function dualSpectrum2(preBF,BF,sample_freq,dx,dyn_range)
%% DUALSPECTRUM2 Plots 2 2D spectra side by side
% function dualSpectrum2(preBF,BF,sample_freq,dx,dyn_range)

p1 = subplot(121)
quickSpectrum2(preBF,sample_freq,dx,dyn_range);
title('Pre-Beamformed')

p2 = subplot(122)
quickSpectrum2(BF,sample_freq,dx,dyn_range);
title('Beamformed')

linkaxes([p1 p2], 'xy');

end