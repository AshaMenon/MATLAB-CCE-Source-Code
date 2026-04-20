function smoothedData = smootheData(dataTable, monthIndex, smoothingFactor)

% Calculate the durations between consecutive datetime values
durationVector = diff(dataTable.Yimestamp);



% Initialize an array to store the closest indices
closestIndices = zeros(size(monthIndex));

% Loop through each value in 'indices'
for i = 1:length(monthIndex)
    % Calculate the absolute difference between 'indices(i)' and all values in 'timeDuration'
    differences = abs(monthIndex(i) - durationVector);
    
    % Find the index of the minimum difference
    [~, minIndex] = min(differences);
    
    % Store the index of the closest value in 'closestIndices'
    closestIndices(i) = minIndex;
end
closestIndices = [ 1, closestIndices, (size(myTable, 1) + 1)];

smootheData = zeros(size(dataTable, 1), (size(dataTable, 2) - 1));
denoisedData = zeros(size(dataTable, 1), 1);

for j = 1 : size(dataTable, 2)

for i = 1 : (length(closestIndices)) - 1

xDenoised= mlptdenoise(dataTable{closestIndices(i): (closestIndices(i + 1) -1), j}, ...
    myTable.Timestamp(closestIndices(i):(closestIndices(i + 1)-1)), smoothingFactor);

if i ==1
denoisedData = xDenoised;

else
    denoisedData = [denoisedData ; xDenoised];
end
end
smootheData(:, j) = denoisedData;
end

smoothedData = array2table(smootheData, "VariableNames",dataTable.Properties.VariableNames);
