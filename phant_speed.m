function cp = phant_speed(Tf,Tb,Tp,Tw,cw)
%% PHANT_SPEED Computes the speed of a phantom by insertion loss
% function cp = phant_speed(Tf,Tb,Tp,Tw,cw)
% Tw = Tank ref time, no phantom
% Tp = Tank ref time, phantom
% Tf = phantom front reflection 
% Tb = phantom back reflection
% cw = Water sound speed (m/s)

%% Define sound speed
if ~exist('cw')
cw=1485.48;
end

%% Compute
cp = cw*((Tw-Tp)./(Tb-Tf)+1);
