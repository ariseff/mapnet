function tensorPrep(training, task)
% Generate image and label tensors for a ConvNet in Marvin
% The images are warped/cropped from the panoramas according to angles determined in panos_x.m

% INPUTS
%  training   - boolean indicating if generated tensors are for training or testing
%  task       - string indicating the task (e.g., 'bike_lane' - see panos_x.m)


addpath(genpath('dependencies'));
panoDir = 'panos/'; % directory containing GSV panoramas and xml metadata
imgsize = 227;

% Load variables
matVar = load('processed_panos.mat');
panos = matVar.panos;
files = matVar.files;

% Remove files
files([panos.remove]) = [];
panos([panos.remove]) = [];

% Train/test longitudinal thresholding
panoCoords = cell2mat({panos.coords}');
longitudes = sort(panoCoords(:,2));
long_thresh = longitudes(round(0.8*length(longitudes))); % arbitrary 4:1 split
fileRemove = false(length(panos));
if training
    fileRemove(panoCoords(:,2) > long_thresh) = true;
    data_name = 'train';
else
    fileRemove(panoCoords(:,2) <= long_thresh) = true;
    data_name = 'test';
end
files(fileRemove) = []; 
panos(fileRemove) = [];

% Determine pano crops and labels for the specified task
[files, headings, returned_labels] = panos_x(panos, files, task);

% Preallocate tensors
data  = zeros(imgsize, imgsize, 3, length(files), 'uint8');
labels = zeros(1,1,1,size(data,4));

% Generate tensors
parfor_progress(['preparing ' task], length(files));
parfor i = 1:length(files)
    img = imread([panoDir files{i}(1:end-4) '.jpg']);
    img = panoWarp(img, headings(i));
    data(:,:,:,i) = img;
    labels(1,1,1,i) = returned_labels(i);
    parfor_progress(['preparing ' task]);
end

% Save tensors
data_num = size(data, 4);
saveDir = ['tensors/' task];
if ~exist(saveDir,'dir')
    mkdir(saveDir)
end

% Image tensor
tensor.type = 'uint8';
tensor.sizeof = 1;
tensor.name = 'images';
tensor.value = data;
tensor.dim = 4;
writeTensors(sprintf('%s/%s_images_%d.tensor', saveDir, data_name, data_num), tensor);

% Mean image tensor
if strcmp(data_name, 'train')
    tensor.type = 'half';
    tensor.sizeof = 2;
    tensor.name = 'mean';
    tensor.value = single(mean(data,4));
    tensor.dim= 3;
    writeTensors(sprintf('%s/%s_mean_%d.tensor',saveDir, data_name, data_num), tensor);
end

% Label tensor
tensor.type = 'half';
tensor.sizeof = 2;
tensor.name = 'labels';
tensor.value = single(labels);
tensor.dim = 4;
writeTensors(sprintf('%s/%s_labels_%d.tensor',saveDir, data_name, data_num), tensor);

end

