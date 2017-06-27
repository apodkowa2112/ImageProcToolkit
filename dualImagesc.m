function dualImagesc(img1,img2)
%% DUALIMAGESC Plot 2 images side by side
% function dualImagesc(img1,img2)
p1 = subplot(121);
cleanImagesc(img1)

p2 = subplot(122);
cleanImagesc(img2);
linkaxes([p1 p2], 'xy')
end