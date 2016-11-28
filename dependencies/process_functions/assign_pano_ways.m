function panos = assign_pano_ways(panos, ways)
% Assign each panorama to a way (minimum distance from point to a polyline
% under Mercator projection)

% Preallocate distance array
polyDists = Inf(length(panos), length(ways));

% Use panoCoords array for parallelization
panoCoords = cell2mat({panos.coords}');

parfor_progress('dists to ways',length(ways));

parfor i = 1:length(ways)
    ways(i).coords = unique(ways(i).coords,'rows','stable'); % in case any nodes are duplicated
    % p_poly_dist requires [x,y]
    polyDists(:,i) = p_poly_dist(panoCoords(:,2), panoCoords(:,1), ways(i).coords(:,2), ways(i).coords(:,1), false);
    parfor_progress('dists to ways');
end

% Way membership of gsv panoramas
[wayDists, wayIndex] = min(polyDists, [], 2);
% Remove panoramas not on a highway (indoors previously taken care of?)
fileRemove = [panos.remove];
fileRemove(wayDists > 0.0001) = true; % magic parameter

% Assign oneway to panos
oneway = [ways.oneway]';
oneway = oneway(wayIndex);

% Assign residentiality to panos
road_type = {ways.road_type}';
road_type = road_type(wayIndex);

% Assign speed limit to panos
speed = [ways.speed]';
speed = speed(wayIndex);

% Assign num lanes to panos
lanes = [ways.lanes]';
lanes = lanes(wayIndex);

% Assign bike path presence to panos
bikepath = [ways.bikepath]';
bikepath = bikepath(wayIndex);

% Place arrays within struct
unfold = @(v) v{:}; % for array to struct assignment
[panos.wayIndex] = unfold(num2cell(wayIndex));
[panos.remove] = unfold(num2cell(fileRemove));
[panos.oneway] = unfold(num2cell(oneway));
[panos.road_type] = unfold(road_type);
[panos.speed] = unfold(num2cell(speed));
[panos.lanes] = unfold(num2cell(lanes));
[panos.bikepath] = unfold(num2cell(bikepath));

% Assign dist and direct to 3rd node of motorway_link (if exists) to panos
% for i = 1:length(panos)
%     panos(i).link.dist = NaN;
%     panos(i).link.direct = NaN;
%     link = ways(panos(i).wayIndex).link;
%     if(~isnan(link(1,1)) && ~panos(i).remove)
%         [arclen, az] = distance(panos(i).coords(1), panos(i).coords(2), link(3,1), link(3,2));
%         dist = arclen./360 * (2*earthRadius*pi); % convert to meters
%         az = az - panos(i).yaw;
%         inds = az < -180;
%         az(inds) = az(inds)  + 360;
%         inds = az > 180;
%         az(inds) = az(inds) - 360;
%         panos(i).link.dist = dist;
%         panos(i).link.direct = az;
%     end
% end
end