function str = scitex(num)
% SCITEX Return LaTeX string for scientific notation
% function str = scitex(num)

exponent = floor(log10(abs(num)));
n = num/10^exponent;
strSpec = '%1.1f\\cdot10^{%1.0f}';
str = sprintf(strSpec, n, exponent);
