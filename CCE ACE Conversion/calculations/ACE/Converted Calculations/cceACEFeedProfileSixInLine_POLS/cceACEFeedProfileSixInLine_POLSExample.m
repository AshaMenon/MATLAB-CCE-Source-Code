eastInputs = readtable("FeedProfilePOLS_AllData.xlsx", "Sheet", "West");
expectedOutputs = eastInputs(:,1:18);

eastInputs = eastInputs(:,19:end);

%% parameters

parameters = struct;
parameters.OutputTime = "2023-06-20T06:30:01.000Z";
parameters.LogName = "FeedProfileSixInLine_POLS.log";
parameters.CalculationName = "ACEFeedProfileSixInLine_POLS";
parameters.CalculationID = "ACEFeedProfileSixInLine_POLS";
parameters.LogLevel =  4;

%% Inputs
inputs = struct;

inputs = getTimeVals(eastInputs, parameters, inputs);

[outputs, errorCode] = cceACEFeedProfileSixInLine_POLS(parameters,inputs);


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