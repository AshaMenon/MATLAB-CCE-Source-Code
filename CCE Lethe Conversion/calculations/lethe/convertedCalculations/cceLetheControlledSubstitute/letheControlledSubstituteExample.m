%% LetheControlledSubstituteExample
clear
clc

% Parameters
parameters = struct();
parameters.LogName = "LetheControlledSubstituteLog";
parameters.CalculationName = "LetheControlledSubstitute";
parameters.CalculationID = "LetheControlledSubstitute01";
parameters.LogLevel = 1;
parameters.OutputTime = "2024-05-24T06:00:01.000Z";

parameters.CalculationPeriodsToRun = -90;
parameters.CalculationPeriod = 86400;
parameters.CalculateAtTime = 21601;
parameters.CalculationPeriodOffset = -1;
parameters.InputMax = nan;
parameters.InputMin = nan;

% Candidate signals ordered by suffix (lower suffix = higher priority).
% Input_1 would override Mog_3 which overrides Minpas_4, etc.
parameters.RollupInputs = ["Estimate", "UserEstimate", "Input", "Ma", "Mog", "Minpas"];

% Inputs
inputs = struct();

% Candidate signals
inputs.Ma_2 = 65.3;
inputs.Ma_2Timestamps = datetime("2024-05-23T06:00:00.000Z", 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''', 'TimeZone', 'UTC');

inputs.Minpas_4 = 63.8;
inputs.Minpas_4Timestamps = datetime("2024-05-22T06:00:00.000Z", 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''', 'TimeZone', 'UTC');

inputs.Input_1 = NaN;
inputs.Input_1Timestamps = NaT;

inputs.Estimate_5 = NaN;
inputs.Estimate_5Timestamps = NaT;

% Control / interlock - feed must be present for output to be valid
inputs.FeedDrymass = 1500;
inputs.FeedDrymassTimestamps = datetime("2024-05-23T06:00:00.000Z", 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''', 'TimeZone', 'UTC');

% Override - set OverrideAction = 1 to force UserOverride value
inputs.OverrideAction = 0;
inputs.OverrideActionTimestamps = datetime("2024-05-23T06:00:00.000Z", 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''', 'TimeZone', 'UTC');

inputs.OverrideSelection = NaN;
inputs.OverrideSelectionTimestamps = NaT;

% UserOverride_8 - value used when OverrideAction == 1; suffix sets the level output
inputs.UserOverride_8 = 70.0;
inputs.UserOverride_8Timestamps = datetime("2024-05-23T06:00:00.000Z", 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''', 'TimeZone', 'UTC');

%% Call Calculation
[outputs, errorCode] = cceLetheControlledSubstitute(parameters, inputs);
