%% ComponentArrayExample
clear
clc

%Get parameters

parameters = struct();
parameters.LogName = "ComponentArrayLog";
parameters.CalculationName = "Component Array";
parameters.CalculationID = "CompArr01";
parameters.LogLevel =  1;
parameters.RollupInputs = ["Assay", "DryMass", "Estimate"];

parameters.ComponentIsPercent = false;
parameters.DoRollupAssay = true;
parameters.DoRollupDry = false;
parameters.RequireAllAssayInputs = false;
parameters.CalculationPeriodsToRun = -90;
parameters.CalculationPeriod = 86400;
parameters.OutputTime = "2024-07-12T12:00:01Z";
parameters.CalculateAtTime = 21601;
parameters.CalculationPeriodOffset = -1;

%Get inputs (use tab 3)
% inputs = struct();
% load([getpref('CCECalcDev', 'DataFolder'), '\LetheCalcs\compArray\inputTabs.mat'])
% endDate = datetime("2022-07-20");
% startDate = endDate-caldays(28);
% calcDates = startDate:endDate;

% compArrayData = readtable([getpref('CCECalcDev', 'DataFolder'), ...
%     '\LetheCalcs\compArray\compArrayInputData2.xlsx'], 'Sheet',2);

% compArrayData = readtable([getpref('CCECalcDev', 'DataFolder'), ...
%     '\LetheCalcs\compArray\compArray.xlsx'], 'Sheet',2);
% 
% compArrayData.Timestamp.Hour = 6;
% compArrayData.Timestamp.Minute = 0;
% compArrayData.Timestamp.Second = 1;

compArrayData = readtable("comparray.xlsx", 'Sheet', 2);
varnames = string(compArrayData.Properties.VariableNames);

inputs = struct;

for n = 1:2:width(compArrayData)
    try
    natIdx = isnat(compArrayData{:,n});

    inputs.(varnames(n+1)) = compArrayData{~natIdx,n+1};
    inputs.(varnames(n+1) + "Timestamps") = compArrayData{~natIdx,n};
    catch
    end
end

% inputs.Assay = NaN;
% inputs.Assay = compArrayData.Assay(1:end-5);
% inputs.Assay_Cr = NaN;
% inputs.AssayTimestamps = compArrayData.Timestamp(1:end-5);
% % inputs.AssayTimestamps = datetime("2017-08-31");
% 
% % inputs.DryMass = NaN;
% inputs.DryMass = compArrayData.DryMass;
% inputs.DryMass_Cr = NaN;
% inputs.DryMassTimestamps = compArrayData.Timestamp;
inputs.Estimate = NaN;
inputs.EstimateTimestamps = NaT;

% Outputs
% expectedOut.Component = dataTab1.Component;
% expectedOut.RollupAssay = dataTab1.RollupAssay;
% expectedOut.RollupDry = NaN;
%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = cceLetheComponentArray(parameters,inputs);
    
% %% MLProdServer Example
% hostName = 'ons-mps:9920';
% archive = 'derivedCalcs';
% functionName = 'apcQuantExpression';
% functionInputs = {parameters,inputs};
%   
% numOfOutputs = 1;
% output = callMLProdServer(hostName,archive,...
%         functionName, functionInputs, numOfOutputs);
%     