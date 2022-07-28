function timeStamp = rf2timetag(rf)
% RF2TIMETAG Twos comp conversion for time tags
% Example use case:
% rf = rcvsplit(RcvData{1},Receive)
% timeStamp = rf2timetag(squeeze(rf(1:2,1,:)));
    tt = double(rf(1:2,:));
    tt(tt<0)  = tt(tt<0)+2^16;
    timeStamp = [1, 2^16]*tt*25e-6;
    timeStamp = reshape(timeStamp,size(rf,2:ndims(rf)));
end