eastInputs = readtable("FeedProfilePOLS_AllData.xlsx", "Sheet", "East");
westInputs = readtable("FeedProfilePOLS_AllData.xlsx", "Sheet", "West");
expectedOutputs = readtable("FeedProfilePOLS_AllData.xlsx", "Sheet", "Outputs");

eastInputs = eastInputs(:,19:end);
westInputs = westInputs(:,19:end);

%% parameters

parameters = struct;
parameters.OutputTime = "2023-06-20T06:30:01.000Z";
parameters.LogName = "FeedProfilePOLS_All.log";
parameters.CalculationName = "ACEFeedProfilePOLS_All";
parameters.CalculationID = "ACEFeedProfilePOLS_All";
parameters.LogLevel =  4;

%% Inputs
inputs = struct;

inputs = getTimeVals(eastInputs, parameters, inputs);
inputs = getTimeVals(westInputs, parameters, inputs);

[outputs, errorCode] = cceACEFeedProfilePOLS_All(parameters,inputs);

%%

function inStruct = getTimeVals(inTbl, params, inStruct)
    outTime = extractBefore(params.OutputTime, "T");

    starttime = datetime(outTime + " 05:50:00");
    endtime = starttime + minutes(30);

    tblVars = string(inTbl.Properties.VariableNames);

    for n = 1:2:length(tblVars)
        idx = isbetween(inTbl{:,n}, starttime, endtime);
        inStruct.(tblVars(n+1)) = inTbl{idx,n+1};
    end
end