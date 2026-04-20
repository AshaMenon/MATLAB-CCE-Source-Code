contData = readtable("ED2.xlsx", "Sheet", 2);
variables = string(contData.Properties.VariableNames);
inputs = struct;

for varNum = 2:2:width(contData)
    
    inputs.(variables(varNum)) = rmmissing(contData{:, varNum});
    inputs.(variables(varNum)+"Timestamps") = rmmissing(contData{:,varNum-1});
end

parameters = struct;
parameters.LogName = "EventDetection.Log";
parameters.CalculationID = "EventDetection01";  
parameters.CalculationName = "Event Detection";
parameters.LogLevel = 4;

parameters.OutputTime = "2024-05-02T10:54:46.000Z";
parameters.OPMAnalysisName = "POLSFCE1_CSTB_PCA_S";
parameters.OPMParameterPath = "D:\OPMEventDetection\";
parameters.ConfigReloadTime = 3600;
parameters.ParameterFileLife = 259200;
parameters.CheckLimits = 0;

tic
[outputs, errorCode] = cceACEEventDetection(parameters,inputs);
toc