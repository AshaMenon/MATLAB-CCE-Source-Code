function data = prepareDataSource()

dataFileName = 'processedAndEngineeredData.xlsx';
thisDir = fileparts(mfilename('fullpath'));
data = readtable(fullfile(thisDir ,'..', 'data', dataFileName));
data.Timestamp.Format = 'dd-MMM-yyyy HH:mm:ss';
data = table2timetable(data, 'RowTimes', 'Timestamp');

end