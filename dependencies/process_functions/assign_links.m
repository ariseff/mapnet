function ways = assign_links( ways )
% Assign motorway_links to motorways (& remove motorway links)

link_1st_coords = NaN(length(ways),2);
for i = 1:length(ways)
    if(strcmp(ways(i).road_type, 'motorway_link'))
        link_1st_coords(i,:) = ways(i).coords(1,:);
    end
end

% Set up default links
unfold = @(v) v{:}; % for array to struct assignment
[ways.link] = unfold(num2cell(NaN(length(ways),1)));

for c = 1:length(link_1st_coords)
    if(~isnan(link_1st_coords(c,1)))
        for w = 1:length(ways)
            if(strcmp(ways(w).road_type, 'motorway'))
                if(ismember(link_1st_coords(c,:), ways(w).coords, 'rows'))
                    ways(w).link = ways(c).coords;
                    break;
                end
            end
        end
    end
end

road_type = {ways.road_type};
ways(strcmp(road_type, 'motorway_link')) = [];

end

