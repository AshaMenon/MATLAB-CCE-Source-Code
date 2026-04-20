function inputsTT = calculateValidSoundingAverages(inputsTT, parameters)
% This function checks and cleans the sounding data in the timetable 'T'.
% Invalid values in Matte and Slag Sounding columns are replaced with NaN.
% Additionally, if either the Matte or Slag value is missing (NaN), both values for that port are set to NaN.

% Define the valid range conditions for Matte and Slag for each port
matte_min = 54; matte_max = 76;    % Matte Sounding should be between 54 and 76
slag_min = 70; slag_max = 160;  % Slag Sounding should be between 70 and 160
conc_min = 0; conc_max = 150;    % Conc Sounding should be between 0 and 150
buildup_min = 0; buildup_max = 20;  % BuildUp Sounding should be between 0 and 20
matteBuildUp_min = 54; matteBuildUp_max = 80;

%Get the list of column names in the timetable (excluding 'Time' column)
port_columns = inputsTT.Properties.VariableNames(:);

% Iterate through all ports
for i = 1:(length(port_columns)/4) + 1  % Iterate over each port (half of columns)
    % Construct the Mat and Slag column names based on the port number
    matte_column = sprintf('MatteSoundingPort%d', i);  % e.g., 'MatteSoundingPort 1'
    slag_column = sprintf('SlagSoundingPort%d', i); % e.g., 'SlagSoundingPort1'
    conc_column = sprintf('ConcentrateSoundingPort%d', i);  % e.g., 'ConcentrateSoundingPort 1'
    buildup_column = sprintf('BuildUpSoundingPort%d', i); % e.g., 'BuildUpSoundingPort1'

    if ismember(matte_column, port_columns) && ismember(slag_column, port_columns) && ismember(conc_column, port_columns)&& ismember(buildup_column, port_columns)

        % Compute the sum of Matte and BuildUp for the port
        sum_column = sprintf('Matte+BuildUpPort%d', i);
        inputsTT.(sum_column) = inputsTT.(matte_column) + inputsTT.(buildup_column);

        totalLiquid_column = sprintf('TotalLiquid%d', i);
        inputsTT.(totalLiquid_column) = inputsTT.(sum_column) + inputsTT.(slag_column);

        % If any of Matte, Slag, Conc, or BuildUp is NaN, set all columns for that port to NaN
        missing_rows = isnan(inputsTT.(matte_column)) | ...
            isnan(inputsTT.(slag_column)) | ...
            isnan(inputsTT.(conc_column)) | ...
            isnan(inputsTT.(buildup_column));

        % Only set the individual port columns to NaN if any reading is missing
        inputsTT.(matte_column)(missing_rows) = NaN;
        inputsTT.(slag_column)(missing_rows) = NaN;
        inputsTT.(conc_column)(missing_rows) = NaN;
        inputsTT.(buildup_column)(missing_rows) = NaN;
        inputsTT.(sum_column)(missing_rows) = NaN;
        inputsTT.(totalLiquid_column)(missing_rows) = NaN;

        % If matte is 0 but slag has a value, write value to total liquid
        % and remove both matte and slag values
        writeSlagToLiquidIdx = inputsTT.(matte_column) == 0 & ...
            ~(inputsTT.(slag_column) == 0 | isnan(inputsTT.(slag_column)));
        
        inputsTT.(totalLiquid_column)(writeSlagToLiquidIdx) = inputsTT.(slag_column)(writeSlagToLiquidIdx);
        inputsTT.(slag_column)(writeSlagToLiquidIdx) = NaN;

        % Find rows where Sounding is outside the valid range 
        matte_invalid = inputsTT.(matte_column) <= matte_min | inputsTT.(matte_column) >= matte_max;
        slag_invalid = inputsTT.(slag_column) <= slag_min | inputsTT.(slag_column) >= slag_max;
        conc_invalid = inputsTT.(conc_column) <= conc_min | inputsTT.(conc_column) >= conc_max;
        buildup_invalid = inputsTT.(buildup_column) <= buildup_min | inputsTT.(buildup_column) >= buildup_max;
        buildupMatte_invalid = inputsTT.(sum_column) <= matteBuildUp_min | inputsTT.(sum_column) >= matteBuildUp_max;
        
        invalid_rows = matte_invalid | slag_invalid | conc_invalid | buildup_invalid | buildupMatte_invalid;

        % If there are invalid values, set all Matte, BuildUp, Conc and Slag columns for that port to NaN
        inputsTT.(matte_column)(matte_invalid) = NaN;
        inputsTT.(slag_column)(slag_invalid) = NaN;
        inputsTT.(conc_column)(conc_invalid) = NaN;
        inputsTT.(buildup_column)(buildup_invalid) = NaN;
        inputsTT.(sum_column)(buildupMatte_invalid) = NaN;
    end
end

% Calculate the sum of Matte plus BuildUp across all ports for each time point
sum_columns = inputsTT.Properties.VariableNames(contains(inputsTT.Properties.VariableNames, 'Matte+BuildUpPort'));

% Calculate the mean of the Matte plus BuildUp values across all ports for each time point
matte_buildup_mean_across_ports = mean(inputsTT{:, sum_columns}, 2, 'omitnan');

% Add the Matte plus BuildUp mean across the port as a new column in the timetable
inputsTT.NewMeanMattePlusBuildupThickness = matte_buildup_mean_across_ports;

% Calculate the mean of the Slag across all ports for each time point
slag_sum_columns = inputsTT.Properties.VariableNames(contains(inputsTT.Properties.VariableNames, 'SlagSoundingPort'));

% Calculate the mean of Slag values across all ports for each time point
mean_slag_across_ports = mean(inputsTT{:, slag_sum_columns}, 2, 'omitnan');

% Add the mean_slag_across_ports as a new column in the timetable
inputsTT.NewMeanSlagThickness = mean_slag_across_ports;

% Calculate the mean of the Conc across all ports for each time point
conc_sum_columns = inputsTT.Properties.VariableNames(contains(inputsTT.Properties.VariableNames, 'ConcentrateSoundingPort'));

% Calculate the mean of Conc values across all ports for each time point
mean_conc_across_ports = mean(inputsTT{:, conc_sum_columns}, 2, 'omitnan');

% Add the mean_conc_across_ports as a new column in the timetable
inputsTT.NewMeanConcThickness = mean_conc_across_ports;

% Add a new column 'NewMeanTotalLiquid' which is the sum of 'NewMeanMattePlusBuildup' and 'NewMeanSlag'
liquid_sum_columns = inputsTT.Properties.VariableNames(contains(inputsTT.Properties.VariableNames, 'TotalLiquid'));

% Calculate the mean of Conc values across all ports for each time point
inputsTT.NewMeanTotalLiquidThickness = mean(inputsTT{:, liquid_sum_columns}, 2, 'omitnan');

inputsTT.IsValidDeltaMatte = double(findValidSounding(inputsTT.NewMeanMattePlusBuildupThickness, 3));
inputsTT.IsValidDeltaSlag = double(findValidSounding(inputsTT.NewMeanSlagThickness, 20));
inputsTT.IsValidDeltaConc = double(findValidSounding(inputsTT.NewMeanConcThickness , 35));

inputsTT.CombinedValidDeltaSounding  = double(inputsTT.IsValidDeltaMatte & inputsTT.IsValidDeltaSlag & inputsTT.IsValidDeltaConc);

end
