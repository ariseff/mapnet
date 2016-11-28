function panos = getTopology(panos, dists, az, inters, ways, opts)
% Assign intersection topology, distance and direction for each pano.
% Also assign driveable headings.

% Options
opts.straightThresh = 100; % minimum distance (meters) for counting as a "straightaway"
opts.minInterDist = 0; % minimum allowed to be topologically an intersection
opts.maxInterDist = 100; % initial thresholding for assigning intersections to panos
opts.uncanny_range = [2.5, 15]; % ambiguous distance range near intersections for driveable headings

unfold = @(v) v{:}; % handle to unfold function
[panos.tops] = unfold(num2cell(-1*ones(length(panos),2),2)); % nearby intersection topology
[panos.dists] = unfold(num2cell(NaN(length(panos),2),2)); % distance to intersections
[panos.directs] = panos.dists; % direction heading to intersections
panos(end).driveHeadings = []; % driveable path directions

% Extract intersection fields for temporary ease of use
intersections = cell2mat({inters.coords}');
interWays = {inters.ways}';
interWaysEnd = {inters.waysEnd}';
interType = cell2mat({inters.type}');

% Iterate through each pano
parfor_progress('topological assignment', size(dists,1));
for i = 1:size(dists, 1)
    % skip pano if invalid
    if(panos(i).remove)
        parfor_progress('topological assignment');
        continue;
    end
    
    % Threshold nearby intersections by distance (stricter thresholding will occur)
    potentials = find(dists(i,:) < opts.straightThresh);
    
    % Determine if forward or backward view and only keep minimums
    min_fb_dist = [1000000, 1000000]; % minimum forward & backward distances to intersections
    min_fb = [0, 0]; % indices of closest forward & backward intersections
    for j = 1:length(potentials)
        % Skip potential intersection if pano's way is not involved
        if(~ismember(panos(i).wayIndex, interWays{potentials(j)}))
            continue;
        end
        % Use az to determine if forward or backward
        adjustedAZ = mod(panos(i).yaw-az(i,potentials(j)), 360);
        if(adjustedAZ > 90 && adjustedAZ < 270)
            direct = 2; % backward
        else
            direct = 1; % forward
        end
        if(dists(i, potentials(j)) < min_fb_dist(direct))
            min_fb_dist(direct) = dists(i, potentials(j));
            min_fb(direct) = potentials(j);
        end
    end
    
    % Determine driveability heading(s) (within intersections as well)
    driveWays = []; % ways associated w/ current pano
    if(min(min_fb_dist) < min(opts.uncanny_range))
        [~, minInter] = min(min_fb_dist);
        driveWays = interWays{min_fb(minInter)};
    elseif(min(min_fb_dist) > max(opts.uncanny_range)); % uncanny range is not direction-specific
        driveWays = panos(i).wayIndex;
    end
    for d = 1:length(driveWays)
        [~, driveHead] = straightaway(panos(i).coords, panos(i).yaw, ways(driveWays(d)).coords, opts.straightThresh);
        panos(i).driveHeadings = [panos(i).driveHeadings, driveHead];
    end
    
    % Differentiate between straight, ambiguous, and intersection
    for direct = 1:2
        oppDirect = getOppDirect(direct);
        if(direct == 1)
            direct_yaw = panos(i).yaw;
        else
            direct_yaw = mod(panos(i).yaw+180, 360); % backwards heading
        end
        [isStraight, ~] = straightaway(panos(i).coords, direct_yaw, ways(panos(i).wayIndex).coords, opts.straightThresh);
        if(min_fb(direct) == 0 && isStraight && min_fb_dist(oppDirect) > opts.minInterDist + 13)
            % straight (or simply non-intersection)
            panos(i).tops(direct) = 1;
            continue;
        elseif(min_fb_dist(direct) < opts.minInterDist || min_fb_dist(direct) > opts.maxInterDist)
            % ambiguous
            panos(i).tops(direct) = 0; % too close/far to intersection
            continue;
        else
            % intersection
            j = min_fb(direct); % j is intersection index
        end
        
        % For panos near qualifying intersections, assign distinguished
        % topology (according to Geiger definitions)
        wayOrder = find(interWays{j} == panos(i).wayIndex); % index of way in this interWays
        otherWay = interWays{j}(interWays{j} ~= panos(i).wayIndex);
        if(isempty(otherWay))
            % in case of OSM error
            panos(i).tops(direct) = -1;
            continue;
        end
        if(interType(j) == 2)
            [A, C] = nodes4pano(ways(panos(i).wayIndex).coords, intersections(j,:), panos(i).coords, ways(otherWay).coords);
            interAngle = coordsangle(A, intersections(j,:), C);
            if(interAngle < 180)
                panos(i).tops(direct) = 2;
            else
                panos(i).tops(direct) = 3;
            end
        elseif(interType(j) == 4)
            if(length(otherWay) == 2)
                ownWay = findOwnWay({ways.coords}', interWays{j}, intersections(j,:));
                if(ownWay == wayOrder)
                    panos(i).tops(direct) = 4;
                else
                    otherWay = interWays{j}(ownWay);
                    [A, C] = nodes4pano(ways(panos(i).wayIndex).coords, intersections(j,:), panos(i).coords, ways(otherWay).coords);
                    interAngle = coordsangle(A, intersections(j,:), C);
                    if(interAngle < 180)
                        panos(i).tops(direct) = 5;
                    else
                        panos(i).tops(direct) = 6;
                    end
                end
            elseif(length(otherWay) == 1)
                if(interWaysEnd{j}(wayOrder))
                    panos(i).tops(direct) = 4;
                else
                    [A, C] = nodes4pano(ways(panos(i).wayIndex).coords, intersections(j,:), panos(i).coords, ways(otherWay).coords);
                    interAngle = coordsangle(A, intersections(j,:), C);
                    if(interAngle < 180)
                        panos(i).tops(direct) = 5;
                    else
                        panos(i).tops(direct) = 6;
                    end
                end
            end
        elseif(interType(j) == 7)
            panos(i).tops(direct) = 7;
        end
        % Add distance and relative direction
        panos(i).dists(direct) = dists(i, j);
        if(direct == 1)
            panos(i).directs(direct) = az(i, j) - panos(i).yaw;
        else
            panos(i).directs(direct) = az(i, j) - mod(panos(i).yaw+180, 360);
        end
        % Ensure intersection directions range from -90 to +90
        if(panos(i).directs(direct) > 90)
            panos(i).directs(direct) = panos(i).directs(direct) - 360;
        elseif(panos(i).directs(direct) < -90)
            panos(i).directs(direct) = panos(i).directs(direct) + 360;
        end
        
    end
    parfor_progress('topological assignment');
end
end

%% Local functions

function oppDirect = getOppDirect(direct)
if(direct == 1)
    oppDirect = 2;
else
    oppDirect = 1;
end
end

function [straight, driveHead] = straightaway(pano, pano_yaw_deg, way, straightThresh)
% Determines if straightaway ahead and also returns drivable heading(s)
% Options
headThresh = 15; % min road distance for a heading to be considered "driveable"

driveHead = [];
straight = false;
[arclen, az] = distance(pano(1), pano(2), way(:,1), way(:,2));
dists = arclen./360 * (2*earthRadius*pi); % convert to meters
[~, startNode] = min(dists);

az = az - pano_yaw_deg;
inds = az < -180;
az(inds) = az(inds)  + 360;
inds = az > 180;
az(inds) = az(inds) - 360;

diffAZ = abs(abs(az(2:end)) - abs(az(1:end-1)));
decrNode = find(diffAZ > 90, 1, 'first');
if(isempty(decrNode))
    decrNode = startNode;
end
incrNode = decrNode + 1;

% driveHead
nodeOrdering = {decrNode:-1:1, incrNode:size(way,1)};
for direct = 1:2
    for i = nodeOrdering{direct}
        if(dists(i) > headThresh) % used to have abs(az(i)) <= 90
            driveHead(1,end+1) = az(i);
            break;
        end
    end
end

% straightaway
nodeOrdering = {startNode-1:-1:1, startNode+1:size(way,1)};
for direct = 1:2
    for i = nodeOrdering{direct};
        if(dists(i) > straightThresh)
            straight = true;
            break;
        end
    end
end
end

% Find way that is not aligned with the other two
function ownWay = findOwnWay(wayCoords, interWays, intersection)
coords = [];
for i = 1:length(interWays)
    if(isequal(wayCoords{interWays(i)}(1,:), intersection))
        coords(i,:) = wayCoords{interWays(i)}(2,:);
    else
        coords(i,:) = wayCoords{interWays(i)}(end-1,:);
    end
end

[~, az] = distance(coords(:,1), coords(:,2), intersection(1), intersection(2));

one2Two = abs(180 - abs(az(1) - az(2)));
one2Three = abs(180 - abs(az(1) - az(3)));
two2Three = abs(180 - abs(az(2) - az(3)));
[~, idx] = min([one2Two, one2Three, two2Three]);
switch idx
    case 1
        ownWay = 3;
    case 2
        ownWay = 2;
    otherwise
        ownWay = 1;
end
end

function [node1, node2] = nodes4pano(way1, intersection, pano, way2)
for i = 1:size(way1, 1)
    if(isequal(way1(i,:), intersection))
        if(i == 1)
            node1 = way1(2,:);
        elseif(i == size(way1,1))
            node1 = way1(end-1,:);
        else
            angle1 = coordsangle(pano, intersection, way1(i-1,:));
            angle2 = coordsangle(pano, intersection, way1(i+1,:));
            angle1 = abs(angle1 - 180); angle2 = abs(angle2 - 180);
            if(angle1 < angle2)
                node1 = way1(i-1,:);
            else
                node1 = way1(i+1,:);
            end
        end
        break
    end
end
if(isequal(way2(1,:), intersection))
    node2 = way2(2,:);
else
    node2 = way2(end-1,:);
end
end

function angle = coordsangle(A, B, C)
% geographic azimuth of ABC
[~, az_AB] = distance(A(1), A(2), B(1), B(2));
[~, az_BC] = distance(B(1), B(2), C(1), C(2));
angle = mod(az_BC - az_AB, 360);
end