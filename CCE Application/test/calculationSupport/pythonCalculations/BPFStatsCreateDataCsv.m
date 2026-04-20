%% Create Data - Python (BPF Stats)

% Load Input Data
load(fullfile('..','..','..','data','pythonMatFiles','params.mat'))

% Create Parameter Data
LogName = "BPFstatsLog";
CalculationName = "BPF Stats";
LogLevel = 255;
CalculationID = "BPF001";
SensorType = string(SensorType);
parameterTbl = table(LogName, CalculationID, CalculationName, LogLevel, C80,...
    P75, UCL, LCL, RunRule, ZeroPoints, Inverse, ExcludeData, DateAsMatlab,...
    DateAsJS, SensorType, TrendHigh, TrendLow, SensorHigh, SensorLow, StandardStd);
parameterFile = fullfile('..','..','..','data','BPFStatsParameters.csv');
writetable(parameterTbl, parameterFile)


% Create Input/Output Data
for i = 1:3
    inputFileName = sprintf('inputmat%d', i);
    load(fullfile('..','..','..','data','pythonMatFiles',inputFileName))
    Timestamps = InputSensorTimestamps';
    InputSensor = InputSensor';
    InputSensorQuality = InputSensorQuality';
    fileName = sprintf('expectedOutput%d.mat', i);
    load(fullfile('..','..','..','data','pythonMatFiles',fileName))
    dataTable = table(Timestamps,InputSensor, InputSensorQuality);
    dataTable.Timestamps = datetime(dataTable.Timestamps,'ConvertFrom','datenum',...
            'Format','dd/MM/yyyy HH:mm:ss');

    dataTblName = fullfile('..','..','..','data',sprintf('BPFStatsData%d.csv',i));
    writetable(dataTable, dataTblName)
    outputs = table(C80,LCL, Mean, P75, UCL, estStdev);
    outputsTblName = fullfile('..','..','..','data',sprintf('BPFStatsOutputs%d.csv',i));
    writetable(outputs, outputsTblName)
end