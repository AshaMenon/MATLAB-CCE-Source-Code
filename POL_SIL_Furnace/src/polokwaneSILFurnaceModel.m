function simOut = polokwaneSILFurnaceModel(slInputs, slParameters, referenceTime, simStopTime, log)
%POLOKWANESILFURNACEMODEL prepares the simulink model to be called before
%calling SIM on the polokwaneSIL.slx. Ouputs are returned in CCE format.


% Create Simulation Inputs (for Simulink Compiler)
simConfig = Simulink.SimulationInput('polokwaneSIL');
log.logTrace(['Compiler Sim Input Loaded for ' simConfig.ModelName])

%fieldnames to variables
varNames = fieldnames(slParameters);
for v = 1:numel(varNames)
    assignin("base", varNames{v}, slParameters.(varNames{v}))
    simConfig = setVariable(simConfig, varNames{v}, slParameters.(varNames{v}));
end
log.logTrace([num2str(numel(simConfig.Variables)) ' Input Variables Loaded'])

%Set external inputs

simInputs = Simulink.SimulationData.Dataset;
simInputs = simInputs.addElement(slInputs,'in1_signal');
assignin("base", "slInputs", simInputs)


simConfig = simConfig.setModelParameter('StopTime', string(simStopTime));

% Run Simulink model
simConfig = simulink.compiler.configureForDeployment(simConfig);
log.logTrace('Sim Inputs Configured')

%Check that simulink logging is set up correctly
perfT = which('PerfTools.Tracer.logSimulinkData');
log.logTrace(perfT)

simOut = sim(simConfig);
log.logTrace('Simulation Executed')

%Save outputs for debugging purposes
if ~exist(fullfile(fileparts(log.LogFilePath), "simOutputs.mat"), "file")
    try
        save(fullfile(fileparts(log.LogFilePath), "simOutputs.mat"), 'simOut');
    catch err
        log.logWarning(err.message);
    end
end



% parameter estimations
% Convert input parameters for simulink model (error handeling, check for all data)
% Data format checking and converting


% Check all inputs, data is there (error handeling)
% Any preprocessing functions
%

% Move the model running into its own function

% Convert the simulation output to outputs structure (define default output structure with NaNs)


end

