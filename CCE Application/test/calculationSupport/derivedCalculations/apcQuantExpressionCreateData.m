%% Create Data - APC Quant Expression

% Load Input Data
load(fullfile('..','..','..','data','derivedCalcsMatFiles','APCQuantExpressionINPUT.mat'))
load(fullfile('..','..','..','data','derivedCalcsMatFiles','APCQuantExpressionOUTPUT.mat'),'dVal', 'dQual')

% Create Parameter Data
LogName = "CalculationLog";
CalculationName = "APC Quant Expression";
LogLevel = 255;
CalculationID = "apc_001";
DerivedSensorClass = string(varargin{1});
DerivedSensorEU = string(varargin{2});
DerivedSensorSG = varargin{3};
Expression1 = string(varargin{4});
Sensor1ID = string(varargin{12});
Sensor2ID = string(varargin{20});
Sensor3ID = string(varargin{28});
Sensor4ID = string(varargin{36});
% Sensor1Eu = string(varargin{10});
% Sensor1Sg = varargin{11};
Sensor1Eu = string(varargin{18});
Sensor1Sg = varargin{19};
Sensor2Eu = string(varargin{26});
Sensor2Sg = varargin{27};
Sensor3Eu = string(varargin{34});
Sensor3Sg = varargin{35};
Sensor4Eu = string(varargin{42});
Sensor4Sg = varargin{43};

parameterTbl = table(LogName, CalculationID, CalculationName, LogLevel,...
    DerivedSensorClass, DerivedSensorEU, DerivedSensorSG, Sensor1ID,...
    Sensor2ID, Sensor3ID, Sensor4ID,Sensor1Eu, Sensor1Sg,...
    Sensor2Eu, Sensor2Sg, Sensor3Eu, Sensor3Sg, Sensor4Eu, Sensor4Sg,... 
    Expression1);

% Create Input Data
Timestamps = varargin{7};

% Sensor1Value = varargin{5};
% Sensor1Quality = varargin{6};
% Sensor1Active = varargin{8};
% Sensor1Condition = varargin{9};
Sensor1Value = varargin{13};
Sensor1Quality = varargin{14};
Sensor1Active = varargin{16};
Sensor1Condition = varargin{17};

Sensor2Value = varargin{21};
Sensor2Quality = varargin{22};
Sensor2Active = varargin{24};
Sensor2Condition = varargin{25};

Sensor3Value = varargin{29};
Sensor3Quality = varargin{30};
Sensor3Active = varargin{32};
Sensor3Condition = varargin{33};

Sensor4Value = varargin{37};
Sensor4Quality = varargin{38};
Sensor4Active = varargin{40};
Sensor4Condition = varargin{41};

% Outputs
DDQual = dQual;
DDVal = dVal;

dataTable = table(Timestamps,Sensor1Value, Sensor1Quality, Sensor1Active,...
   Sensor1Condition,...
   Sensor2Value, Sensor2Quality, Sensor2Active,Sensor2Condition,...
   Sensor3Value, Sensor3Quality, Sensor3Active,Sensor3Condition,...
   Sensor4Value, Sensor4Quality, Sensor4Active,Sensor4Condition,...
   DDVal, DDQual);

dataTable.Timestamps = datetime(dataTable.Timestamps,'ConvertFrom','datenum',...
            'Format','dd/MM/yyyy HH:mm:ss');
        
dataTblName = fullfile('..','..','..','data','apcQuantExpression_Data.csv');
parameterFile = fullfile('..','..','..','data','apcQuantExpression_Parameters.csv');

writetable(dataTable, dataTblName)
writetable(parameterTbl, parameterFile)




