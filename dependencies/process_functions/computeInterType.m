function inters = computeInterType(inters)
% Assess topology type of each intersection
% 2, 4, and 7 correspond to turn, t-junction, and cross respectively

unfold = @(v) v{:}; % handle to unfold function
[inters.type] = unfold(num2cell(zeros(size(inters))));

parfor_progress('interType', length(inters));
parfor i = 1:length(inters)
    if(length(inters(i).ways) >= 4)
        inters(i).type = 7;
    else
        numEnd = sum(inters(i).waysEnd);
        if(length(inters(i).ways) == 3)
            if(numEnd == 3)
                inters(i).type = 4;
            else
                inters(i).type = 7;
            end
        else
            if(numEnd == 2)
                inters(i).type = 2;
            elseif(numEnd == 1)
                inters(i).type = 4;
            else
                inters(i).type = 7;
            end
        end
    end
    parfor_progress('interType');
end

end

