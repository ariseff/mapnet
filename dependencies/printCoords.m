function [ stringCoords ] = printCoords( coords )
% Prints coordinates stored the 2D array "coords"

stringCoords = [];
for i = 1:size(coords,1)
    stringCoords = sprintf([stringCoords '\n' num2str(coords(i,1), 10) ', ' num2str(coords(i,2), 10)]);
end
end

