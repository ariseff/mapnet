%% Add dependencies to path
addpath(genpath('dependencies'));


%% Scrape Google Street View panoramas and associated metadata
% breadth-first search from initial seed location (see bfs_download.m for options)
bfs_download(); % requires wget


%% Extract ground truth road layout attributes for Google Street View panoramas based on corresponding OpenStreetMap info
% This section assumes "map.osm" was previously downloaded from osm.org and the GSV
% panoramas/xml are saved in "panos" directory.

% parse intersection and street info from OSM map
system('python dependencies/map_parsing/parse_script.py');

% assign attributes to GSV panoramas based on OSM and store in "panos" struct
files = dir('panos/*.xml');
files = {files.name}';
panos = gsv_osm_corr(files); % see gsv_osm_corr.m for panos struct details
save('processed_panos.mat', 'files', 'panos');


%% Prepare Marvin tensors for training and testing models
tensorPrep(true, 'inter_detection'); % training data tensor
tensorPrep(false, 'inter_detection'); % testing data tensor


%% Train models
system('./marvin train mapnet/inter_detection/arch.json models/alexnet_places/alexnet_places_half.marvin 2>&1 | tee mapnet/inter_detection/log_file.txt');