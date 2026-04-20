function dataTbl = readAndFormatData(subModel) %, predictorTags, responseTags)

% Get Data
if isequal(subModel, "Chemistry")
    janMarData = readtable(fullfile('data', 'ChemistryModel', ...
        'chemistryData_Jan-Mar-21_v9.csv'),'PreserveVariableNames',true);
    aprJunData = readtable(fullfile('data', 'ChemistryModel', ...
        'chemistryData_Apr-Jun-21_v9.csv'),'PreserveVariableNames',true);
    junSepData = readtable(fullfile('data', 'ChemistryModel', ...
        'chemistryData_Jul-Sep-21_v9.csv'),'PreserveVariableNames',true);
    octDecData = readtable(fullfile('data', 'ChemistryModel', ...
        'chemistryData_Oct-Dec-21_v9.csv'),'PreserveVariableNames',true);
    octDecData.("O2_SO2 Ratio 2") = nan(height(octDecData),1);
    dataTbl = [janMarData; aprJunData; junSepData; octDecData];
elseif isequal(subModel, "Temperature")
    opts = detectImportOptions('temperatureData_Jan-Mar-21_v9.csv', 'VariableNamingRule', 'preserve');
    opts = setvartype(opts, opts.VariableNames(2:end), 'double');
    janMarData = readtimetable(fullfile('data', 'TemperatureModel', ...
        'temperatureData_Jan-Mar-21_v9.csv'), opts);
    aprJunData = readtimetable(fullfile('data', 'TemperatureModel', ...
        'temperatureData_Apr-Jun-21_v9.csv'), opts);
    junSepData = readtimetable(fullfile('data', 'TemperatureModel', ...
        'temperatureData_Jul-Sep-21_v9.csv'), opts);
    octDecData = readtimetable(fullfile('data', 'TemperatureModel', ...
        'temperatureData_Oct-Dec-21_v9.csv'), opts);
    dataTbl = [janMarData; aprJunData; junSepData; octDecData];
elseif isequal(subModel,"Chemistry2022")
    opts = detectImportOptions('chemistryData_Jan-Mar-22_v1.csv', 'VariableNamingRule', 'preserve');
    opts = setvartype(opts, opts.VariableNames(2:end), 'double');
    janMarDF = readtimetable(fullfile('data', 'ChemistryModel', ...
        'chemistryData_Jan-Mar-22_v1.csv'), opts);
    aprJunDF = readtimetable(fullfile('data', 'ChemistryModel', ...
        'chemistryData_Apr-Jun-22_v1.csv'), opts);
    julSepDF = readtimetable(fullfile('data', 'ChemistryModel', ...
        'chemistryData_Jul-Aug-22_v1.csv'), opts);
    dataTbl = [janMarDF, aprJunDF, julSepDF];
elseif isequal(subModel,"sept22Chemistry")
    opts = detectImportOptions('chemistryData_Sep-Oct-22.csv', 'VariableNamingRule', 'preserve');
    opts = setvartype(opts, opts.VariableNames(2:end), 'double');
    opts = setvaropts(opts,'Timestamp','InputFormat','dd-MMM-yy HH:mm:ss');
    dataTbl = readtimetable(fullfile('data', 'ChemistryModel', ...
        'chemistryData_Sep-Oct-22.csv'), opts);
elseif isequal(subModel, "oct22Chemistry")
    opts = detectImportOptions('chemistryData_Oct_22.csv', 'VariableNamingRule', 'preserve');
    opts = setvartype(opts, opts.VariableNames(2:end), 'double');
    dataTbl = readtimetable(fullfile('data', 'ChemistryModel', ...
        'chemistryData_Oct_22.csv'), opts);
elseif isequal(subModel, "Temperature2022")
    opts = detectImportOptions('temperatureData_Jan-Mar-22_v2.csv', 'VariableNamingRule', 'preserve');
    opts = setvartype(opts, opts.VariableNames(2:end), 'double');
    janMarData = readtimetable(fullfile('data', 'TemperatureModel', ...
        'temperatureData_Jan-Mar-22_v2.csv'), opts);
    aprJunData = readtimetable(fullfile('data', 'TemperatureModel', ...
        'temperatureData_Apr-Jun-22_v2.csv'), opts);
    junSepData = readtimetable(fullfile('data', 'TemperatureModel', ...
        'temperatureData_Jul-Sep-22_v2.csv'), opts);
    octDecData = readtimetable(fullfile('data', 'TemperatureModel', ...
        'temperatureData_Oct-Dec-22_v2.csv'), opts);
%     octDecData = octDecData(:, janMarData.Properties.VariableNames);
%     octDecData.("Upper Waffle 18") = str2double(octDecData{:, "Upper Waffle 18"});
    dataTbl = [janMarData; aprJunData; junSepData; octDecData];
elseif isequal(subModel, "Temperature2023")
    opts = detectImportOptions('temperatureData_Jan-Mar-23_v1.csv', 'VariableNamingRule', 'preserve');
    opts = setvartype(opts, opts.VariableNames(2:end), 'double');
    janMarData = readtimetable(fullfile('data', 'TemperatureModel', ...
        'temperatureData_Jan-Mar-23_v1.csv'), opts);
    dataTbl = janMarData;
end

end
