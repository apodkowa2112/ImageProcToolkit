%% QUICKSPECTRUM2 Plots the spectrum, quick & dirty
% function spect = quickSpectrum2(img,fs,dx,dyn_range)
function spect = quickSpectrum2(img,fs,dx,dyn_range)
    if numel(dyn_range) == 1
        dyn_range = [-abs(dyn_range) 0];
    end

    %% Compute optimal length
    num_fft_ax  = 2^nextpow2(size(img,1)*2);
    num_fft_lat = 2^nextpow2(size(img,2)*2);
    
    %% Compute spectrum
    spect = fft2(img,num_fft_ax,num_fft_lat);
    mag_spect = (mag2db(abs(spect)));
    %% Compute axis
    freq_axis = (0:num_fft_ax-1)*fs/num_fft_ax;
    freq_axis = freq_axis-mean(freq_axis);
    nu_x_axis = (0:num_fft_lat-1)/(dx*num_fft_lat);
    nu_x_axis = nu_x_axis - mean(nu_x_axis);
    
    %% Plot normalized spectrum
    imagesc(nu_x_axis*1e-3,freq_axis*1e-6,fftshift(mag_spect),max(mag_spect(:))+dyn_range);
    colormap gray, colorbar
    title('Spectrum')
    xlabel('\nu_x (1/mm)')
    ylabel('Frequency (MHz)')
    grid on
end

function out = normZero(in)
    out = in - max(in(:));
end