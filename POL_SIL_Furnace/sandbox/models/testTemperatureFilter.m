%% Load data and run simulation
% read inputs from file
inputs = readtable("POL_SIL_Data_20241107_2024AugData.xlsx", "Sheet", "Sheet1");

% filter for 1 week of data
startTime = datetime('01-Aug-2024 18:00:00'); % start when sounding reading has just been taken
endTime = datetime('31-Aug-2024 22:00:00');
inputs = filterByDateTime(inputs, startTime, endTime);

% Change TimeStamp to duration
inputs.Timestamp = inputs.Timestamp - inputs.Timestamp(1);

% Convert table to timetable
inputs = table2timetable(inputs, 'RowTimes', 'Timestamp');

% Calculate a mean slag and temperature while ignoring low values
inputs.SlagTemp = calcTempFromCameras(inputs(:,{'SlagTap1ThermalCameraTemp', ...
    'SlagTap2ThermalCameraTemp', 'SlagTap3ThermalCameraTemp'}), 1400);

inputs.MatteTemp = calcTempFromCameras(inputs(:,{'MatteTap1ThermalCameraTemp', ...
    'MatteTap2ThermalCameraTemp', 'MatteTap3ThermalCameraTemp'}), 1200);

% inputs.SlagTemp = fillmissing(inputs.SlagTemp, 'previous');
% inputs.MatteTemp = fillmissing(inputs.MatteTemp, 'previous');

plot(inputs, "Timestamp", ["SlagTap1ThermalCameraTemp", ...
    "SlagTap2ThermalCameraTemp", "SlagTap3ThermalCameraTemp"])
hold on;
plot(inputs.Timestamp, inputs.SlagTemp, '.', 'MarkerSize', 10)

% plot(inputs, "Timestamp", ["MatteTap1ThermalCameraTemp", ...
%     "MatteTap2ThermalCameraTemp", "MatteTap3ThermalCameraTemp", "MatteTemp"])


function filteredTbl = filterByDateTime(tbl, startTime, endTime)
   filteredTbl = tbl(and(tbl.Timestamp >= startTime, tbl.Timestamp <= endTime), :);
end

function row_avg_max_temp = calcTempFromCameras(tempTbl, low_limit, window_size)
    % Set default window_size to 30 if not provided
    if nargin < 3
        window_size = 30;  % Assuming each row represents 1 minute, for a 30-minute window
    end

    % Step 1: Set values below low_limit to NaN for all columns
    tempTbl{:,:}(tempTbl{:,:} < low_limit) = NaN;

    % Step 2: Remove outliers through z-score on each column of tempTbl
    tempTbl = remove_outliers_zscore(tempTbl, 3);

    % Step 3: Initialize a table to store maximum temperatures for each column segment
    max_temps_tbl = varfun(@(col) find_max_in_segments(col), tempTbl);

    % Step 4: Combine all columns into a single column vector
    combined_max_temps = reshape(max_temps_tbl{:,:}, [], 1);

    % Step 5: Initialize the result array with NaNs to match the height of tempTbl
    row_avg_max_temp = NaN(height(tempTbl), 1);
    
    % Step 6: Calculate custom rolling average over 30-minute windows
    idx = 1;
    while idx <= length(combined_max_temps)
        % Define the end of the current 30-minute window
        window_end = min(idx + window_size - 1, length(combined_max_temps));

        % Extract the current 30-minute window
        current_window = combined_max_temps(idx:window_end);

        % Find the first non-NaN value in this window
        first_valid_idx = find(~isnan(current_window), 1, 'first');
        if ~isempty(first_valid_idx)
            % Calculate the average for this window
            window_avg = mean(current_window, 'omitnan');
            
            % Assign the average to the first valid index within the window, relative to row_avg_max_temp
            abs_idx = idx + first_valid_idx - 1;  % Convert to absolute index in original data
            if abs_idx <= height(tempTbl)
                row_avg_max_temp(abs_idx) = window_avg;
            end
        end

        % Move to the next window
        idx = window_end + 1;
    end
end

function max_values = find_max_in_segments(data)
    % Initialize an array to hold the max value for each segment
    max_values = NaN(size(data));

    % Find segments of non-NaN values and calculate the maximum for each segment
    start_idx = 1;
    while start_idx <= length(data)
        % Find the start of the next non-NaN segment
        start_idx = find(~isnan(data(start_idx:end)), 1, 'first') + start_idx - 1;
        if isempty(start_idx)  % No more non-NaN segments
            break;
        end

        % Find the end of the current non-NaN segment
        end_idx = find(isnan(data(start_idx:end)), 1, 'first') + start_idx - 2;
        if isempty(end_idx)  % Segment goes until the end of data
            end_idx = length(data);
        end

        % Find the maximum value and its index within the segment
        [max_temp, max_relative_idx] = max(data(start_idx:end_idx), [], 'omitnan');
        max_idx = start_idx + max_relative_idx - 1;  % Absolute index of the maximum in the original data

        % Place the maximum at its original position within the segment
        max_values(max_idx) = max_temp;

        % Move to the next segment
        start_idx = end_idx + 1;
    end
end

function tempTbl = remove_outliers_zscore(tempTbl, z_threshold)
    % Set default value for z_threshold if not provided
    if nargin < 2
        z_threshold = 3;  % Z-score threshold for outlier detection
    end

    % Apply Z-score outlier detection to each column using varfun
    tempTbl = varfun(@(col) set_outliers_to_nan(col, z_threshold), tempTbl);
end

function col = set_outliers_to_nan(col, z_threshold)
    % Calculate the mean and standard deviation, ignoring NaNs
    mean_val = mean(col, 'omitnan');
    std_val = std(col, 'omitnan');

    % Only proceed if the standard deviation is greater than a small threshold
    if std_val > 1e-5
        % Compute Z-scores and set outliers to NaN
        z_scores = (col - mean_val) / std_val;
        col(abs(z_scores) > z_threshold) = NaN;
    end
end