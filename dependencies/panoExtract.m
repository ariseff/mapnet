function [ value ] = panoExtract( ind, str )
% Extract a quote-enclosed value from a pano's xml file

for i = ind:length(str)
    if(str(i) == '"')
        beg = i + 1;
        break;
    end
end

for i = beg:length(str)
    if(str(i) == '"')
        last = i - 1;
        break;
    end
end

value = str(beg:last);

end

