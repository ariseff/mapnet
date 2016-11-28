function [new_files, headings, labels] = panos_x(panos, files, task)
% Determine the headings to crop and labels for the given panos & task
%
% task choices:
% 'inter_detection', 'inter_distance', 'driveable', 'heading_angle',
% 'bike_lane', 'speed_limit', 'oneway', 'wrongway', 'num_lanes'


new_files = {};
headings = [];
labels = [];

% Intersection detection
if(strcmp(task, 'inter_detection'))
    for i = 1:length(panos)
        % cross intersection is positive
        if(panos(i).dists(1) < 30 && panos(i).dists(1) > 0 && panos(i).tops(1) == 7)
            headings(end+1,1) = panos(i).directs(1);
            labels(end+1,1) = 1;
            new_files(end+1,1) = files(i);
        % straightaway is negative
        elseif(panos(i).tops(1) == 1)
            zeroth = forHeading(panos(i).driveHeadings);
            if(length(zeroth) == 1)
                headings(end+1,1) = zeroth;
                labels(end+1,1) = 0;
                new_files(end+1,1) = files(i);
            end                
        end
    end
    [new_files, headings, labels] = dataBalance(new_files, headings, labels);
end

% Distance to type 7 intersection
if(strcmp(task, 'inter_distance'))
    for i = 1:length(panos)
        if(panos(i).dists(1) < 30 && panos(i).dists(1) > 0 && panos(i).tops(1) == 7)
            headings(end+1,1) = panos(i).directs(1);
            labels(end+1,1) = panos(i).dists(1);
            new_files(end+1,1) = files(i);
        end
    end
end

% Driveability
if(strcmp(task, 'driveable'))
    for i = 1:length(panos)
        if(isempty(panos(i).driveHeadings))
            continue;
        end
        if(min(panos(i).dists(:)) < 2.5) % within an intersection
            sorted_headings = sort(panos(i).driveHeadings);
            for h = 1:length(sorted_headings)
                headings(end+1,1) = sorted_headings(h); % positive
                labels(end+1,1) = 1;
                new_files(end+1,1) = files(i);
                if(h == length(sorted_headings))
                    headDiff = mod(sorted_headings(1) - sorted_headings(h), 360);
                else
                    headDiff = mod(sorted_headings(h+1) - sorted_headings(h), 360);
                end
                badHeading = sorted_headings(h) + headDiff/2;
                headings(end+1,1) = badHeading;
                labels(end+1,1) = 0;
                new_files(end+1,1) = files(i);
            end
        else % non-intersection (hence only one road to consider)
            this_heading = panos(i).driveHeadings(randi(length(panos(i).driveHeadings)));
            headings(end+1,1) = this_heading; % positive
            labels(end+1,1) = 1;
            new_files(end+1,1) = files(i);
            addAngle = [-75, -45, 45, 75];
            badHeading = this_heading + addAngle(randi(length(addAngle))); % negative
            headings(end+1,1) = badHeading;
            labels(end+1,1) = 0;
            new_files(end+1,1) = files(i);
        end
    end
end
            
% Heading angle regression
if(strcmp(task, 'heading_angle'))
    for i = 1:length(panos)
        if((min(panos(i).dists) > 30 || isequal(panos(i).tops, [1,1])) && length(panos(i).driveHeadings) == 2) % non-intersection
            zeroth = forHeading(panos(i).driveHeadings);
            if(length(zeroth) == 1)
                headings(end+1:end+4,1) = [(zeroth-60)+(rand*30), (zeroth-30)+(rand*30), zeroth+(rand*30), (zeroth+30)+(rand*30)];
                labels(end+1:end+4,1) = headings(end-3:end) - zeroth;
                new_files(end+1:end+4,1) = files(i);
            end
        end
    end
end

% Bike lane detection
if(strcmp(task, 'bike_lane'))
    for i = 1:length(panos)
        if(panos(i).bikepath == 1)
            bikepath = 1;
        elseif(panos(i).bikepath == 0)
            bikepath = 0;
        else
            continue;
        end
        if(((panos(i).dists(1) > 20 && panos(i).dists(2) > 13) || panos(i).tops(1) == 1)) % assessing in non-intersections
            zeroth = forHeading(panos(i).driveHeadings);
            if(length(zeroth) == 1)
                headings(end+1,1) = zeroth + 45;
                labels(end+1,1) = bikepath;
                new_files(end+1,1) = files(i);
            end
        end
    end
    [new_files, headings, labels] = dataBalance(new_files, headings, labels);
end

% Speed limit
if(strcmp(task, 'speed_limit'))
    for i = 1:length(panos)
        if(~isnan(panos(i).speed))
            zeroth = forHeading(panos(i).driveHeadings);
            zeroth = zeroth(1); % only 1 view per pano for now
            headings(end+1,1) = zeroth;
            labels(end+1,1) = panos(i).speed;
            new_files(end+1,1) = files(i);
        end
    end
end

% Oneway
if(strcmp(task, 'oneway'))
    for i = 1:length(panos)
        if(((panos(i).dists(1) > 20 && panos(i).dists(2) > 13) || panos(i).tops(1) == 1)) % assessing in non-intersections
            zeroth = forHeading(panos(i).driveHeadings);
            if(length(zeroth) == 1)
                headings(end+1,1) = zeroth;
                if(panos(i).oneway)
                    labels(end+1,1) = 1;
                else
                    labels(end+1,1) = 0;
                end
                new_files(end+1,1) = files(i);
            end
        end
    end
    [new_files, headings, labels] = dataBalance(new_files, headings, labels);
end

% Wrong way
if(strcmp(task, 'wrongway'))
    for i = 1:length(panos)
        if((min(panos(i).dists) > 30 || isequal(panos(i).tops, [1,1])) && length(panos(i).driveHeadings) == 2) % non-intersection
            zeroth = forHeading(panos(i).driveHeadings);
            if(length(zeroth) == 1)
                headings(end+1:end+4,1) = [zeroth-rand*15, zeroth+rand*15, (zeroth-180)-rand*15, (zeroth-180)+rand*15];
                labels(end+1:end+4,1) = [1, 1, 0, 0];
                new_files(end+1:end+4,1) = files(i);
            end
        end
    end
end

% Number of lanes
if(strcmp(task, 'num_lanes'))
    for i = 1:length(panos)
        if(panos(i).oneway && ~isnan(panos(i).lanes)) % only assessing within oneways now
            if(((panos(i).dists(1) > 20 && panos(i).dists(2) > 13) || panos(i).tops(1) == 1)) % assessing in non-intersections
                mod_headings = mod(panos(i).driveHeadings, 360);
                zeroth = panos(i).driveHeadings(mod_headings < 90 | mod_headings > 270); % forward
                if(length(zeroth) == 1)
                    headings(end+1,1) = zeroth;
                    labels(end+1,1) = panos(i).lanes;
                    new_files(end+1,1) = files(i);
                end
            end
        end
    end
end


end



%% Local functions

% optional category balancing - can alternatively do this on the data layer
% side to avoid image duplication
function [new_files, headings, labels] = dataBalance(new_files, headings, labels)
uniqueLabels = unique(labels);
for i = 1:length(uniqueLabels)
    disp(['Balancing ' num2str(uniqueLabels(i)) ' ...']);
    inds = find(labels == uniqueLabels(i));
    addNum = sum(labels == mode(labels)) - length(inds);
    inds = inds(randperm(length(inds)));
    inds = repmat(inds, ceil(addNum/length(inds)), 1);
    inds = inds(1:addNum);
    new_files = [new_files; new_files(inds)];
    headings = [headings; headings(inds,:)];
    labels = [labels; labels(inds,:)];
end
end

% determine forward driving heading (possibly multiple if within
% intersection)
function [zeroth] = forHeading(driveHeadings)
mod_headings = mod(driveHeadings, 360);
zeroth = driveHeadings(mod_headings < 90 | mod_headings > 270);
end


