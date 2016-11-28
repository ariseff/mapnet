function panos = gsv_osm_corr(files)
% Extract ground truth road layout attributes for GSV panoramas based on corresponding
% OSM info.

% INPUTS
%  files  -  cell array of GSV panorama metadata file names
%
% OUTPUTS
%  panos  -  struct containing road layout attribute information for each
%            GSV panorama
%            fields:
%                   id: GSV panorama id
%                   coords: [latitude, longitude]
%                   yaw: angle of camera clockwise relative to true north (0 degrees)
%                   remove: boolean indicating if panorama ineligible for inclusion  
%                   wayIndex: index of panorama's road in the processed map
%                   oneway: 0 if on a two-way road, 1 if one-way
%                   road_type: type of road according to OSM specifications
%                   speed: speed limit in mph, NaN if unavailable
%                   lanes: number of lanes, NaN if unavailable
%                   bikepath: 0 if no bike lane present, 1 if present
%                   tops: - topologies of the nearest intersections (within 100 m) 
%                           ahead of (1st) or behind (2nd) the panorama 
%                         - topologies are numbered 1-7 according to Geiger et al., 2014)
%                         - other entries indicate no eligible intersection
%                   dists: distances to the two intersections in meters
%                   directs: - yaw angle to the two intersections
%                            - forward intersection direction is measured
%                              clockwise relative to panorama's 0-degree mark (center)
%                            - backward intersection direction is measured
%                              clockwise relative to panorama's 180-degree mark
%                   driveHeadings: array of driveable headings aligned with
%                                  panorama's road(s)


% Read intersection and node coordinates previously extracted from map.osm
intersections = csvread('intersections.txt'); % intersection coordinates
allNodesFile = 'allNodes.txt'; % all street coordinates and metadata
mapFile = 'map.osm'; % OSM extract

panoDir = 'panos/'; % directory containing GSV panoramas and xml metadata

% Transfer intersection coordinates to an inters struct
unfold = @(v) v{:}; % handle to unfold function
inters(size(intersections,1),1).coords = [];
[inters.coords] = unfold(num2cell(intersections,2));
clear intersections;

% Extract information about each way and intersection (origin of the ways struct)
[ways, inters] = parse_txt_nodes(allNodesFile, inters);

% Assign motorway_links to motorways (& remove motorway links)
% ways = assign_links(ways);

% For each pano, extract lat, lng, yaw, and ensure it's both outdoors and within osm map range
% (origin of the panos struct)
panos = get_pano_locations(mapFile, panoDir, files);

% Assign each panorama to a way & transer oneway, type of highway, and
% speed limit attributes
panos = assign_pano_ways(panos, ways);

% Find ground truth distances and directions from panoramas to all intersections
[dists, az] = dists2inters(panos, inters);

% Intersection type (turn vs. t-junction vs. cross)
inters = computeInterType(inters);

% Topology & driveable path assignment
panos = getTopology(panos, dists, az, inters, ways);
end