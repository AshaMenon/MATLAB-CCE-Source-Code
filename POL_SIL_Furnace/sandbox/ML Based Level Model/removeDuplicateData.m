function data = removeDuplicateData(data)

% Convert the table data to an array for comparison
dataMatrix = table2array(data(:, 2:end));

% Find where the data is equal to the data in the previous row
sameAsPrevious = [false(1, size(data, 2) - 1); diff(dataMatrix) == 0];

% Set the values in feedData to 0 where they are the same as the previous row
dataMatrix(sameAsPrevious) = 0;

% Update the table with the modified dataMatrix
data(:, 2:end) = array2table(dataMatrix);

data(data{:, 2} == 0, :) = [];
