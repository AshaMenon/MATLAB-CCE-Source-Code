function parameters = SPO2Params

%% Preprocessing data properties

parameters.removeTransientData = true;

parameters.smoothBasicityResponse = false;

parameters.resampleTime = '1min';

parameters.resampleMethod = 'zero';

parameters.subModel = 'Chemistry';

%% Model Specific Parameters
parameters.NiSlagTarget = 0; % Change to 0 for dynamic, else 3.2

parameters.deadBand = 0;

parameters.writeTermsToSpreadsheet = false;

parameters.refitModel = false;

parameters.Path = 'data/SPO2Model/';

%% Thermo Parameters
parameters.pathToThermo = 'data/thermoDataNewCombinations_v2.csv';

parameters.ThermoModel = 'thermoMdl_Pickle_file.pickle';

parameters.ThermoExcel = 'NiSlagEquationOrder2.xlsx';

%% Ni Slag Parameters
parameters.subtractionParam = 0.2;

parameters.multiplierParam = 1.85;

parameters.thresholdParam = 0.8;

%% SPO2 Parameters
parameters.PSO2_const = 0.15;

parameters.setFeMatteTarget = true;

parameters.modelPath = 'data/SPO2Model/TrainSPO2_2021-01-01_00.31.00_to_2021-12-31_23.17.00';

%% CCE Calc Parameters

parameters.LogName = 'SPO2.log';

parameters.CalculationID = 'TSPO2';

parameters.LogLevel = 255;

parameters.CalculationName = 'TrainSPO2';
end