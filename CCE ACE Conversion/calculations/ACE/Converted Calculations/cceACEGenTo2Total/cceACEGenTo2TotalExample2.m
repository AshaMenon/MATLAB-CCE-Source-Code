inData = readtable("data2.xlsx", "Sheet", 1);
formData = readtable("data2.xlsx", "Sheet", 2);

%% Parameters

parameters = struct;
parameters.OutputTime = "2024-05-30T02:00:02.000Z";
parameters.LogName = "GenTo2Total.log";
parameters.CalculationName = "ACEGenTo2Total";
parameters.CalculationID = "ACEGenTo2Total";
parameters.LogLevel =  4;
parameters.ElementName = "GenTo2valTotal.24.5";
% parameters.Formula = "'tag'/1000 + ('345_LI_203/PV_V'86400_18000_SInt' - '345_LI_203/PV_V'86400_18000_EInt')";
parameters.Formula = "1";

inputs = struct;
inputs.ACE_315_Coal_Consumption_Day_Total_86400_18000_TAve = nan;
inputs.ACE_315_Coal_Consumption_Day_Total_86400_18000_TAveTimestamps = NaT;
% inputs.ACE_315_Coal_Consumption_Day_Total_86400_18000_TAve = inData.Value;
% inputs.ACE_315_Coal_Consumption_Day_Total_86400_18000_TAveTimestamps = inData.TimeStamp;
% inputs.Formula_345_LI_203_PV_V = formData.Value;
% inputs.Formula_345_LI_203_PV_VTimestamps = formData.TimeStamp;

%% Run Calc
[outputs, errorCode] = cceACEGenTo2Total(parameters, inputs);