%% QUICKSPECTRUM Plots the spectrum, quick & dirty
% function spect = quickSpectrum(rf,fs)
function spect = quickSpectrum(rf,fs)
    %% Compute optimal length
    num_fft = 2^nextpow2(length(rf)*2);
    
    %% Compute spectrum
    spect = fft(rf,num_fft);
    
    %% Compute axis
    freq_axis = (0:num_fft-1)*fs/num_fft;
    
    %% Plot normalized spectrum
    plot(freq_axis*1e-6,normZero(mag2db(abs(spect))),'.-');
    title('Normalized Spectrum')
    xlabel('Frequency (MHz)')
    ylabel('Normalized Spectrum (dB)')
    grid on
    
    %% clear spect if not assigned
    if nargout==0
        clear spect
    end
end

function out = normZero(in)
    out = in - max(in(:));
end