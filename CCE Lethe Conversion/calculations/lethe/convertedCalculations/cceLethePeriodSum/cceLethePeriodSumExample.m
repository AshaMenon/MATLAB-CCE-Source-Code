%% LethePeriodSumExample
clear
clc

% periodSumData = readtable([getpref('CCECalcDev', 'DataFolder'), ...
%     '\LetheCalcs\periodSum\PeriodSum3.xlsx'], 'Sheet',2);
% 
% periodSumData(1:5,:) = [];

periodSumData = readtable("periosum_badinput.xlsx", "Sheet", 2);

%Get parameters

parameters = struct();
parameters.LogName = "LethePeriodSum2Log";
parameters.CalculationName = "Lethe PeriodSum";
parameters.CalculationID = "LethePeriodSum01";
parameters.LogLevel =  1;

parameters.CalculationPeriodsToRun = -90;
parameters.CalculationPeriod = 86400;
parameters.OutputTime = "2024-08-07T10:00:00.000Z";
parameters.CalculateAtTime = 21601;
parameters.ForceTimeCollation = false;
parameters.CalculationPeriodOffset = -1;
parameters.ForceToZero = false;

% parameters.AdditionalInputs = ["iS:LP.TotalNiTonsPlated.Total.day", "iS:NiTH.NickelicScrap.Day.Total"];
parameters.AdditionalInputs = ["Smelter.USML", "Smelter.WSML"];

%Get inputs
inputs = table2struct(periodSumData,"ToScalar",true);
inputs.Smelter_USML = inputs.Smelter_USML(1:end-1);
inputs.Smelter_USMLTimestamps = inputs.Smelter_USMLTimestamps(1:end-1);
inputs.Smelter_WSML = inputs.Smelter_WSML(1:end-1);
inputs.Smelter_WSMLTimestamps = inputs.Smelter_WSMLTimestamps(1:end-1);
% inputs = struct();
% inputs.Input = periodSumData.Input;
% inputs.iS_LP_TotalNiTonsPlated_Total_day = periodSumData.iS_LP_TotalNiTonsPlated_Total_day;
% inputs.iS_NiTH_NickelicScrap_Day_Total = periodSumData.iS_NiTH_NickelicScrap_Day_Total;

% inputs.InputTimestamps = periodSumData.Var1;
% inputs.iS_LP_TotalNiTonsPlated_Total_dayTimestamps = periodSumData.Var3;
% inputs.iS_NiTH_NickelicScrap_Day_TotalTimestamps = periodSumData.Var5;

% Outputs
% expectedOut.Output = periodSumData.Aggregate(end-89:end);
% expectedOut.Timestamp = periodSumData.Timestamp(end-89:end);

%%   MATLAB Example
% Call Calculation
[outputs, errorCode] = cceLethePeriodSum(parameters,inputs);

%%
% diff = expectedOut.Output - outputs.Aggregate';

%  assert(isequal(outputs.Aggregate', expectedOut.Output))

% figure
% subplot(3,1,1)
% stairs(expectedOut.Timestamp, expectedOut.Output)
% ylabel('Lethe')
% 
% subplot(3,1,2)
% stairs(outputs.Timestamp, outputs.Aggregate)
% ylabel('CCE')
% 
% subplot(3,1,3)
% plot(outputs.Timestamp, outputs.Aggregate - expectedOut.Output')
% ylabel('Error')
