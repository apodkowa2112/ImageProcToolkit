function c = water_speed(temp)
% WATER_SPEED Return the sound speed of water as a function of temperature
% temp = temperature in degrees C
% c = sound speed in m/s
% Taken from Bilaniuk & Wong, JASA 1993, https://doi.org/10.1121/1.406819

%% Define coeffs
coeffs = [1.40238744e3,... constant term
    5.03835027e0,...    1
    -5.81142290e-2,...  2
    3.34558776e-4,...   3
    -1.48150040e-6,...  4
    3.16081885e-9...    5
    ];

t = temp(:);
c = polyval(fliplr(coeffs),t);

%% Reshape to original size
c = reshape(c,size(temp));

end