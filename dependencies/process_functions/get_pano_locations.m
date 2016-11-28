function panos = get_pano_locations(mapFile, panoDir, files)
% For each pano, extract lat, lng, yaw, "outdoorsness" and ensure within osm map range

panos(length(files),1).id = []; % panoid
panos(length(files),1).coords = []; % geographic coordinates
panos(length(files),1).yaw = NaN; % yaw direction
panos(length(files),1).remove = false; % if this pano is invalid

[minlat, minlon, maxlat, maxlon] = mapBoundaries(mapFile); % map boundaries

% Iterate through panos
parfor_progress('pano coordinates',length(files));
parfor i = 1:length(files)
    panos(i).id = files{i}(1:end-4);
    str = fileread(fullfile(panoDir, files{i}));
    try
        lat_ind = strfind(str, 'lat='); lng_ind = strfind(str, 'lng=');
        lat = str2double(panoExtract(lat_ind(1), str)); lng = str2double(panoExtract(lng_ind(1), str));
        assert(lat < maxlat && lat > minlat); assert(lng < maxlon && lng > minlon);
        panos(i).coords = [lat, lng];
        yaw_ind = strfind(str, 'pano_yaw_deg=');
        panos(i).yaw = str2double(panoExtract(yaw_ind, str));
        panos(i).remove = false;
    catch
        disp(['pano ' num2str(i) ' is outside the map range (skipping)...']);
        panos(i).coords = [0,0];
        panos(i).yaw = NaN;
        panos(i).remove = true;
    end
    parfor_progress('pano coordinates');
end

end


% local function
function [minlat, minlon, maxlat, maxlon] = mapBoundaries(file)
str = fileread(file);
minlat = str2double(panoExtract(strfind(str, 'minlat='), str));
minlon = str2double(panoExtract(strfind(str, 'minlon='), str));
maxlat = str2double(panoExtract(strfind(str, 'maxlat='), str));
maxlon = str2double(panoExtract(strfind(str, 'maxlon='), str));
end
