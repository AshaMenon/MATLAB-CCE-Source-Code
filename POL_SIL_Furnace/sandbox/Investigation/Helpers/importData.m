function data = importData(filename)
    %IMPORTDATA Import data into MATLAB and correct timestamp

    if iscell(filename)    % Identifies if mutliple files are trying to be imported
        numFiles = size(filename,2);
    else                   % If only one file has been selected then some processing of the file names need to be performed
        numFiles = 1;
        filename = {filename};
    end

    for i = 1:1:numFiles
        opts = detectImportOptions(filename{i});
        opts = setvartype(opts,opts.VariableNames(2:end), 'double'); % Automatically converts all strings (bad data) to NaN which eases data processing
        data{i} = readtimetable(filename{i}, opts);   % Imports data into a timetable
        pat = digitsPattern(4);     % Timestamp gets imported in the dd-MM-yyyy format, the year gets imported incorrectly as 00XX (e.g. 0023) - this code sets a 4 digit pattern to find the incorrect year
        year = extract(string(data{i}.Timestamp),pat);
        correctedTimestamp = datetime(replace(string(data{i}.Timestamp),year(1),string(str2double(year(1)) + 2000)));   % corrects the year being imported
        data{i}.Timestamp = correctedTimestamp;
    end

end