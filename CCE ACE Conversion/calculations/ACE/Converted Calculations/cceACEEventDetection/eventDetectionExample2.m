edData = readtable("ED.xlsx","Sheet",2);

varNames = string(edData.Properties.VariableNames);
varNames(1:2:end) = varNames(2:2:end) + "Timestamps";

edData.Properties.VariableNames = varNames;

inputs = table2struct(edData,"ToScalar",true);

inputFields = string(fieldnames(inputs))';
inputFields(contains(inputFields,"Timestamps")) = [];

for fieldName=inputFields
    try
    val = inputs.(fieldName);
    val(isnan(val)) = [];
    inputs.(fieldName) = val;
    catch
    end
end

inputs.Event_1 = nan;
inputs.Event_1Timestamps = NaT;

%%
parameters = struct;
parameters.LogName = "EventDetection.Log";
parameters.CalculationID = "EventDetection01";  
parameters.CalculationName = "Event Detection";
parameters.LogLevel = 4;
parameters.OutputTime = "2023-10-25T12:20:22.000Z";
parameters.OPMAnalysisName = "POLSFCE1_CMBullnose_PCA_S";
parameters.OPMParameterPath = "D:\OPMEventDetection\";
parameters.ConfigReloadTime = 3600;
parameters.ParameterFileLife = 259200;
parameters.CheckLimits = 0;


[outputs, errorCode] = cceACEEventDetection(parameters,inputs);