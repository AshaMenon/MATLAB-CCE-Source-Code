function row_avg_max_temp = calcTempFromCameras(tempTbl, low_limit, window_size, z_threshold)
    % Set default values if not provided
    if nargin < 3
        window_size = 30;  % Assuming each row represents 1 minute, for a 30-minute window
    end
    if nargin < 4
        z_threshold = 3;  % Default Z-score threshold for outlier detection
    end

    % Step 1: Set values below low_limit to NaN for all columns
    tempTbl{:,:}(tempTbl{:,:} < low_limit) = NaN;

    % Step 2: Remove outliers through z-score on each column of tempTbl
    tempTbl = remove_outliers_zscore(tempTbl, z_threshold);

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
