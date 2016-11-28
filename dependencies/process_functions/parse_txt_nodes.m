function [ways, inters ] = parse_txt_nodes(allNodesFile, inters)
% Parse nodes from allNodes.txt and intersection.txt

% ways struct (information about each way)
ways(1).coords = []; % node coordinates
ways(1).oneway = false; % is a oneway road
ways(1).road_type = ''; % type of highway (residential, motorway, etc.)
ways(1).speed = NaN; % speed limit
ways(1).inters = []; % intersections contained within this way
ways(1).lanes = NaN; % number of lanes
ways(1).bikepath = NaN; % presence of bike path

% inters struct ways-related fields
inters(end).ways = []; % ways belonging to each intersection
inters(end).waysEnd = logical([]); % whether each member way "ends" at the intersection

% scan allNodesFile
fid = fopen(allNodesFile);
allNodes = textscan(fid, '%s', 'Delimiter', '\n');
allNodes = allNodes{1,1};
allNodesCoords = parseCoords(allNodes);

% match up way nodes with the intersection nodes
intersections = cell2mat({inters.coords}');
[~, Locb] = ismember(allNodesCoords, intersections, 'rows');

% iterate through all way nodes
wayNum = 0;
for i = 1:size(allNodes,1)
    % Skip blank lines
    if(isempty(allNodes{i}))
        continue;
    end
    % Check start of new way
    if(contains(allNodes{i}, 'way id:'))
        wayNum = wayNum + 1;
        ways(wayNum).coords = [];
        ways(wayNum).inters = [];
        continue
    end
    % Check if way is oneway
    if(contains(allNodes{i}, 'oneway:'))
        if(contains(allNodes{i}, 'true'))
            ways(wayNum).oneway = true;
        else
            ways(wayNum).oneway = false;
        end
        continue;
    end
    % Check type of highway
    if(contains(allNodes{i}, 'road_type:'))
        ways(wayNum).road_type = allNodes{i}(12:end);
        continue;
    end
    % Check speed limit of way
    if(contains(allNodes{i}, 'speed:'))
        if(contains(allNodes{i}, 'undefined'))
            ways(wayNum).speed = NaN;
        else
            ways(wayNum).speed = str2double(allNodes{i}(8:end));
        end
        continue;
    end
    % Check number of lanes
    if(contains(allNodes{i}, 'lanes'))
        if(contains(allNodes{i}, 'undefined'))
            ways(wayNum).lanes = NaN;
        else
            ways(wayNum).lanes = str2double(allNodes{i}(8:end));
        end
        continue;
    end
    % Check bike path
    if(contains(allNodes{i}, 'cycleway'))
        if(strcmp(allNodes{i}(11:end), 'lane'))
            ways(wayNum).bikepath = 1;
        elseif(strcmp(allNodes{i}(11:end), 'no'))
            ways(wayNum).bikepath = 0;
        else
            ways(wayNum).bikepath = NaN;
        end
        continue;
    end
    % If this point reached, add this node's coordinates to way
    ways(wayNum).coords(end+1,:) = allNodesCoords(i,:);
    % If current node is an intersection, assess its member ways
    if(Locb(i))
        inters(Locb(i)).ways(end+1) = wayNum;
        if(isnan(allNodesCoords(i-1,1)) || isnan(allNodesCoords(i+1,1)))
            inters(Locb(i)).waysEnd(end+1) = true;
        else
            inters(Locb(i)).waysEnd(end+1) = false;
        end
        ways(wayNum).inters(end+1) = Locb(i);
    end
end

% Transpose structs
ways = ways';
end



%% Local functions
function allNodesCoords = parseCoords(allNodes)
allNodesCoords = NaN(size(allNodes,1),2);
for i = 1:size(allNodes,1)
    try
        allNodesCoords(i,:) = strread(allNodes{i,1}, '%f', 2, 'delimiter', ',');
    catch
        allNodesCoords(i,:) = [NaN, NaN];
    end
end
end

function found = contains(str, pattern)
if(~isempty(strfind(str,pattern)))
    found = true;
else
    found = false;
end
end

