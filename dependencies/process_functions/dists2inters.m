function [dists, az] = dists2inters(panos, inters)
% Find ground truth distances and directions from panoramas to all intersections
% (restrict to candidate intersections for better runtime)

% Intersection coordinate array
intersections = cell2mat({inters.coords}');

% Intialize distance array
arclen = 180*ones(length(panos), length(intersections));
% Initialize direction array
az = zeros(length(panos), length(intersections));
parfor_progress('dists & directs to intersections', length(panos));
parfor i = 1:length(panos)
    if(panos(i).remove)
        parfor_progress('dists & directs to intersections');
        continue;
    end
    [arclen(i,:), az(i,:)] = distance(panos(i).coords(1), panos(i).coords(2), intersections(:,1), intersections(:,2));
    parfor_progress('dists & directs to intersections');
end
dists = arclen./360 * (2*earthRadius*pi); % convert to meters

end

