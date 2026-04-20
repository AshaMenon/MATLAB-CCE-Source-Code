function retimedCompressed = validSoundingCompressed(retimedCompressed)
% This function checks and cleans the sounding data in the timetable 'T'.
% Invalid values in Matte and Slag Sounding columns are replaced with NaN.
% Additionally, if either the Matte or Slag value is missing (NaN), both values for that port are set to NaN.

retimedCompressed = timetable2table(retimedCompressed);
% Define the valid range conditions for Matte and Slag for each port
matte_min = 54; matte_max = 76;    % Matte Sounding should be between 54 and 76
slag_min = 70; slag_max = 160;  % Slag Sounding should be between 70 and 160
conc_min = 0; conc_max = 150;    % Conc Sounding should be between 0 and 150
buildup_min = 0; buildup_max = 20;  % BuildUp Sounding should be between 0 and 20
matteBuildUp_min = 54; matteBuildUp_max = 80; 


%Get the list of column names in the timetable (excluding 'Time' column)
port_columns = retimedCompressed.Properties.VariableNames(2:end);

% Iterate through all ports 
for i = 1:(length(port_columns)/4)+1  % Iterate over each port (half of columns)
    % Construct the Mat and Slag column names based on the port number
    matte_column = sprintf('MatteSoundingPort%d', i);  % e.g., 'MatteSoundingPort 1'
    slag_column = sprintf('SlagSoundingPort%d', i); % e.g., 'SlagSoundingPort1'
    conc_column = sprintf('ConcentrateSoundingPort%d', i);  % e.g., 'ConcentrateSoundingPort 1'
    buildup_column = sprintf('BuildUpSoundingPort%d', i); % e.g., 'BuildUpSoundingPort1'


    % Check if the constructed column names exist in the timetable
    if ismember(matte_column, port_columns) && ismember(slag_column, port_columns) && ismember(conc_column, port_columns)&& ismember(buildup_column, port_columns) 

        % Find rows where Matte Sounding is outside the valid range (Mat > 0, Mat < 60)
        matte_invalid = retimedCompressed.(matte_column) <= matte_min | retimedCompressed.(matte_column) >= matte_max;

        % Find rows where Slag Sounding is outside the valid range (Slag > 0, Slag < 150)
        slag_invalid = retimedCompressed.(slag_column) <= slag_min | retimedCompressed.(slag_column) >= slag_max;

        % Find rows where Conc Sounding is outside the valid range (Conc > 0, Conc < 150)
        conc_invalid = retimedCompressed.(conc_column) <= conc_min | retimedCompressed.(conc_column) >= conc_max;

        % Find rows where Buildup Sounding is outside the valid range (Conc > 0, Conc < 150)
        buildup_invalid = retimedCompressed.(buildup_column) <= buildup_min | retimedCompressed.(buildup_column) >= buildup_max;

         % Set the invalid readings to NaN for each port separately
        retimedCompressed.(matte_column)(matte_invalid) = NaN;
        retimedCompressed.(slag_column)(slag_invalid) = NaN;
        retimedCompressed.(conc_column)(conc_invalid) = NaN;
        retimedCompressed.(buildup_column)(buildup_invalid) = NaN;

        % After filling invalid entries with NaN, check for missing values (NaNs)
        % If any of Matte, Slag, Conc, or BuildUp is NaN, set all columns for that port to NaN
        missing_rows = isnan(retimedCompressed.(matte_column)) | ...
                       isnan(retimedCompressed.(slag_column)) | ...
                       isnan(retimedCompressed.(conc_column)) | ...
                       isnan(retimedCompressed.(buildup_column));

        % Only set the individual port columns to NaN if any reading is missing
        retimedCompressed.(matte_column)(missing_rows) = NaN;
        retimedCompressed.(slag_column)(missing_rows) = NaN;
        retimedCompressed.(conc_column)(missing_rows) = NaN;
        retimedCompressed.(buildup_column)(missing_rows) = NaN;

        % Compute the sum of Matte and BuildUp for the port 
        sum_column = sprintf('Matte+BuildUpPort%d', i);  
        retimedCompressed.(sum_column) = retimedCompressed.(matte_column) + retimedCompressed.(buildup_column);
    end
end
% Calculate the sum of Matte plus BuildUp across all ports for each time point
sum_columns = retimedCompressed.Properties.VariableNames(contains(retimedCompressed.Properties.VariableNames, 'Matte+BuildUpPort'));

% Calculate the mean of the Matte plus BuildUp values across all ports for each time point
matte_buildup_mean_across_ports = nanmean(retimedCompressed{:, sum_columns}, 2);

% Add the Matte plus BuildUp mean across the port as a new column in the timetable
retimedCompressed.NewMeanMattePlusBuildup = matte_buildup_mean_across_ports;

% Calculate the mean of the Slag across all ports for each time point
slag_sum_columns = retimedCompressed.Properties.VariableNames(contains(retimedCompressed.Properties.VariableNames, 'SlagSoundingPort'));

% Calculate the mean of Slag values across all ports for each time point
mean_slag_across_ports = nanmean(retimedCompressed{:, slag_sum_columns}, 2);

% Add the mean_slag_across_ports as a new column in the timetable
retimedCompressed.NewMeanSlag = mean_slag_across_ports;

% Calculate the mean of the Conc across all ports for each time point
conc_sum_columns = retimedCompressed.Properties.VariableNames(contains(retimedCompressed.Properties.VariableNames, 'ConcentrateSoundingPort'));

% Calculate the mean of Conc values across all ports for each time point
mean_conc_across_ports = nanmean(retimedCompressed{:, conc_sum_columns}, 2);

% Add the mean_conc_across_ports as a new column in the timetable
retimedCompressed.NewMeanConc = mean_conc_across_ports;

% Add a new column 'NewMeanTotalLiquid' which is the sum of 'NewMeanMattePlusBuildup' and 'NewMeanSlag'
retimedCompressed.NewMeanTotalLiquid = retimedCompressed.NewMeanMattePlusBuildup + retimedCompressed.NewMeanSlag;

retimedCompressed = table2timetable(retimedCompressed);
end
