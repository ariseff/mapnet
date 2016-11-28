function [ warped_image ] = panoWarp( panorama, heading )

% parameters
new_imgH = 227;        % horizontal resolution = width
new_imgShort = 227;    % vertical resolution = height
fov = 100;             % horizontal angle field-of-view (degrees)
fov = fov * pi/180;    % convert to radians

% where is your center of the camera
% horizontal angle
x = heading*pi/180;           % range [-pi,   pi]
% vertical angle
y = 0;           % range [-pi/2, pi/2]


% read the panorama
%panorama = imread('pano_aclzqydjlssfry.jpg');
panorama = double(panorama);

% generate the crop
warped_image = imgLookAt(panorama, x, y, new_imgH, fov );
%warped_image = warped_image/255;
warped_image = uint8(warped_image);
warped_image = warped_image(round((new_imgH-new_imgShort)/2)+(1:new_imgShort),:,:);

end

