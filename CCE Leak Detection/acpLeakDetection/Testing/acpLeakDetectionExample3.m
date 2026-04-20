% Example script for executing R Calculation via MATLAB
clear, clc
%% Parameters
parameters = struct;
parameters.OutputTime = "2023-09-02T06:00:00.000Z";
parameters.LogName = "ContRampTo2Total.log";
parameters.CalculationName = "ACEContRampTo2Total";
parameters.CalculationID = "ACEContRampTo2Total";
parameters.LogLevel = 4;
parameters.FactorTypeTags = "ConvertorMode_0_0";
parameters.ConvertorPhase = 2;
%ModelPerformance
parameters.ModelPerformance_errormean = -0.000795389729336685;
parameters.ModelPerformance_errorul = 0.27726862000318;
parameters.ModelPerformance_errorll = -0.278859399461853;
parameters.ModelPerformance_errorsd = 0.278064009732516;
parameters.ModelPerformance_rmse = 0.278063793222971;
parameters.ModelPerformance_rsq = 0.964031224621893;
parameters.ModelPerformance_bias = -0.0291446134978409;

%% f factors
configData = readtable("Config.csv");
configData(1,:) = []; %Remove timestamp

inputAttrNames = configData.Feature + "_" + configData.Phase + "_" + configData.Digital;

for i = 1:length(inputAttrNames)
    parameters.(inputAttrNames(i) + "_" + "F_GrossOutlierDetection") = configData.F_GrossOutlierDetection(i);
    parameters.(inputAttrNames(i) + "_" + "F_GrossOutlierDetection_k") = configData.F_GrossOutlierDetection_k(i);
    parameters.(inputAttrNames(i) + "_" + "F_Smoothing") = configData.F_Smoothing(i);
    parameters.(inputAttrNames(i) + "_" + "F_Smoothing_p") = configData.F_Smoothing_p(i);
    parameters.(inputAttrNames(i) + "_" + "F_Smoothing_a") = configData.F_Smoothing_a(i);
end

%% Inputs

endDate = datetime("2023-11-10 12:00:00");
startDate = endDate - minutes(70);

data = readtable('LeakDetection2.xlsx','VariableNamingRule', 'preserve', 'Sheet',2);

varNames = string(data.Properties.VariableNames);
varNames(1:2:end) = varNames(2:2:end) + "Timestamps";

data.Properties.VariableNames = varNames;

inputs = table2struct(data,"ToScalar",true);

inputs = structfun(@rmmissing, inputs, "UniformOutput", false);

inputFields = string(fieldnames(inputs));
timeIdx = contains(inputFields,"Timestamps");
inputFields(timeIdx) = [];

for field = inputFields'
    try
        idx = isbetween(inputs.(field + "Timestamps"), startDate, endDate);
        inputs.(field + "Timestamps")(~idx) = [];
        inputs.(field)(~idx) = [];
    catch
    end
end


parameters.Backfill = false;

%% Evaluate R Calc
[outputs, errorCode] = acpLeakDetection(parameters,inputs);
