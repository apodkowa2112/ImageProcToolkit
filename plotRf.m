function plotRf(in)
    in = in/max(abs(in(:)));
    sf = 2.1;
    for i=1:size(in,2)
        in(:,i) = in(:,i) + (i-1)*sf;
    end
    plot(in,'bo-')
end
