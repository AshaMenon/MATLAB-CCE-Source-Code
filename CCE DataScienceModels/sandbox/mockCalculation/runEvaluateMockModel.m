% Run Evaluate Mock Model

inputs.Value1 = 10;
inputs.Value2 = 20;
parameters.LogName = "mockLogFile.log";
parameters.CalculationID = 'mockcalc-01';
parameters.LogLevel = 3;
parameters.CalculationName = 'Mock Model';


% Run Initial Workflow
%[outputs, errorCode] = EvalMockModel(parameters,inputs);

% Run Second Workflow
[outputs, errorCode] = EvaluateMockModel(parameters,inputs);