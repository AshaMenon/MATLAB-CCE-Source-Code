%% Create Data - ReconstructDensity

% Load Input Data
load(fullfile('..','..','..','data','derivedCalcsMatFiles','reconstructDensityINPUT.mat'))
load(fullfile('..','..','..','data','derivedCalcsMatFiles','reconstructDensityOUTPUT.mat'),'dDVal', 'dDQual')

% Create Parameter Data
LogName = "controllerAnalysisTestLog";
CalculationName = "Controller Analysis";
LogLevel = 255;
CalculationID = "recon_001";
K1 = V3;
K2 = Q3;
K3 = T3;
K4 = V4;
parameterTbl = table(LogName, CalculationID, CalculationName, LogLevel, K1,...
    K2, K3, K4);

% Create Input Data
Timestamps = T1;
WaterFeed = V2;
SolidsFeed = V1;
WaterFeedQuality = Q2;
SolidsFeedQuality = Q1;

% Outputs
DDQual = dDQual;
DDVal = dDVal;

dataTable = table(Timestamps,SolidsFeed, SolidsFeedQuality,WaterFeed,...
    WaterFeedQuality, DDVal, DDQual);

dataTable.Timestamps = datetime(dataTable.Timestamps,'ConvertFrom','datenum',...
            'Format','dd/MM/yyyy HH:mm:ss');
        
dataTblName = fullfile('..','..','..','data','reconstructDensity_Data.csv');
parameterFile = fullfile('..','..','..','data','reconstructDensity_Parameters.csv');

writetable(dataTable, dataTblName)
writetable(parameterTbl, parameterFile)
