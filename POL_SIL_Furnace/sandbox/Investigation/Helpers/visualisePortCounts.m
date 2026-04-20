function visualisePortCounts(data)
    %UNTITLED10 Summary of this function goes here
    %   Detailed explanation goes here

    numPorts = size(data, 2); % Number of ports
    totalRows = size(data, 1); % Total number of rows

    counts = zeros(1, numPorts); % Initialize an array to store counts

    for portIndex = 1:numPorts
        portValues = data{:, portIndex};

        % Count rows with non-zero and non-NaN values
        nonZeroNonNanRows = ~(portValues == 0 | isnan(portValues));
        counts(portIndex) = sum(nonZeroNonNanRows);
    end

    % Calculate percentages
    percentages = (counts / totalRows) * 100;

    % Get variable names and sort them alphabetically
    variableNames = data.Properties.VariableNames;
    
    % Sort percentages accordingly
    % Sort variables based on percentages
    % [sortedNames, sortedIndices] = sort(variableNames);
    % sortedPercentages = percentages(sortedIndices);

    [~, idx] = sort(cellfun(@(x) str2double(regexp(x, '\d+', 'match')), variableNames));

    sortedNames = variableNames(idx);
    sortedPercentages = percentages(idx);

    % Create a bar chart
    figure
    bar(sortedPercentages);
    xticks(1:numPorts);
    xticklabels(sortedNames);
    xtickangle(45);
    ylabel('Percentage');
    title('Percentage of Usage');
    
    for idx = 1:length(variableNames)
        % Create a binary signal for each port
        portState(:, idx) = ~isnan(data{:, idx}) & data{:, idx} > 0;
    end

    stateTbl = array2timetable(portState, 'RowTimes', data.Timestamp, 'VariableNames', variableNames);

    figure
    for j = 1:length(variableNames)
        subplot(length(variableNames), 1, j)
        plot(stateTbl.Time, stateTbl{:,j})
        title(variableNames{j})
        ylim([-0.5, 1.5])
        ylabel('State')
     
    end    
    sgtitle('Timeseries of Port State')
    

end