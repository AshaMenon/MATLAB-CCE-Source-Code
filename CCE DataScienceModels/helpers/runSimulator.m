function simulator    = runSimulator(simulator, data, parameters)
%RUNSIMULATOR - Wrapper for sim functino, makes workspace a little neater

% Get Variables for Simulation
simVar = getSimvars(data, parameters);

%fieldnames to variables
varNames = fieldnames(simVar);
for nVar = 1:numel(varNames)
    eval([varNames{nVar} ' = simVar.' varNames{nVar} ';']);
end

simulator    = sim(simulator, 'StopTime', string(seconds(data.Timestamp(end))), ...
    'SrcWorkspace', 'current');
end