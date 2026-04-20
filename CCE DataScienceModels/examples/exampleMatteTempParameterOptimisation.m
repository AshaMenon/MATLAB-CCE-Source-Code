%% Parameter Optimisation Example Script

%% Set up the experiment parameters
parameterTable = table('Size', [80, 16], 'VariableTypes', ...
    [repmat(["string"], 1, 2), repmat(["double"], 1, 14)], ...
    'VariableNames', {'startDate', 'endDate', 'rmseTm', 'rmseTs',...
    'U', 'delta_Ts', 'alpha_Fe', 'alpha_Ni', 'alpha_Co', 'alpha_Cu',...
    'm_dot_dust_and_accr', 'epsilon', 'T_furnace', 'R', 'r_m', 'r_s'});
logFile = '.\MatteTemperature.log';
calculationName = 'TestMatteTemperature';
calculationID = 'TestMT';
logLevel = 255;
    
log = CCELogger(logFile, calculationName, calculationID, logLevel);

[origData, timestamps, parameters] = sdoTempModelEstimation_loadAndPreprocessData(log);
startIdx = 25355;
tableIdx = 0;
stepSize = round(0.75*(height(origData)-startIdx)); %4421*3;
warning('off','all')

% Required for root-level inports
inputColumnNames = {'MatteFeedTotal', 'FeedRateTot',...
    'TappingClassificationForPhaseMattetapblock1DT_water',...
    'TappingClassificationForPhaseMattetapblock2DT_water',...
    'TappingClassificationForPhaseSlagtapblockDT_water',...
    'Lowerwaffleheatflux', 'CoalFeedRate', 'Upperwaffleheatflux',...
    'FeFeedblend', 'NiFeedblend', 'CoFeedblend', 'CuFeedblend',...
    'Mattetemperatures', 'Slagtemperatures', 'Lanceheight',...
    'LanceOxyEnrichPercentagePV', 'SilicaPV', 'PhaseMattetapblock1DT_water',...
    'PhaseMattetapblock2DT_water', 'PhaseSlagtapblockDT_water'};

clear('tempdir')
setenv('tmp','D:\John\Matlab_temp\')

%% Start the optimisation
for dataIdx = startIdx:stepSize:height(origData)
    % Get the simulated Data
    idx = dataIdx:dataIdx+stepSize;
    tableIdx = tableIdx + 1;
    
    [data, startDate, endDate] = sdoTempModelEstimation_Measurement(idx, timestamps, origData);

    parameterTable.startDate(tableIdx) = startDate;
    parameterTable.endDate(tableIdx) = endDate;
    data.('Bath Height') = (data.Lanceheight+350)/1000;
    % Create an Experiment Object
    % Stores the measured input/output data
    
    exp = sdo.Experiment('fundamentalModel');
    
    % Store the measured outputs
    
    slagTemp = Simulink.SimulationData.Signal;
    slagTemp.Name      = 'Ts [C]';
    slagTemp.BlockPath = 'fundamentalModel/Ts [C]';
    slagTemp.PortType  = 'outport';
    slagTemp.PortIndex = 1;
    slagTemp.Values    = timeseries(data{:, 'Slagtemperatures'}, seconds(data.Timestamp));
    
    matteTemp = Simulink.SimulationData.Signal;
    matteTemp.Name = 'Median Tm [C]';
    matteTemp.BlockPath = 'fundamentalModel/Median Tm [C]';
    matteTemp.PortType  = 'outport';
    matteTemp.PortIndex = 1;
    matteTemp.Values    = timeseries(data{:, 'Mattetemperatures'}, seconds(data.Timestamp));
    
    % Add measured outputs as expected output data
    
    exp.OutputData = [...
        matteTemp; ...
        slagTemp];
    
    % (Optional) Add initial states for each of the blocks and set them as free so they're estimated
    
    % Compare measured and simulated outputs
    
    simulator    = createSimulator(exp);
    % Get Variables for Simulation
    simVar = getSimvars(data, parameters, log);
    
    %fieldnames to variables
    varNames = fieldnames(simVar);
    for nVar = 1:numel(varNames)
        eval([varNames{nVar} ' = simVar.' varNames{nVar} ';']);
    end

    slInputs = [seconds(data.Timestamp), data{:, inputColumnNames}];

    simulator    = sim(simulator, 'StopTime', string(seconds(data.Timestamp(end))));
    
    % Search for the output signals in the logged simulation data
    
%     simLog             = find(simulator.LoggedData, get_param('fundamentalModel','SignalLoggingName'));
%     slagTempSignal   = find(simLog,'Ts [C]');
%     matteTempSignal    = find(simLog,'Tm [C]');
    
    % Plot the measured and simulated data
    
    % plotSimOutputs(seconds(data.Timestamp), data, bathHeightSignal, matteTempSignal)
    
    % Specify the parameters to estimate
    
    p = sdo.getParameterFromModel('fundamentalModel',{'U','delta_Ts','alpha_Fe',...
        'alpha_Ni', 'alpha_Co', 'alpha_Cu', 'm_dot_dust_and_accr', 'epsilon',...
        'T_furnace', 'R', 'r_m', 'r_s'});
    p(1).Minimum = 1000;  %U
    p(1).Maximum = 10000;
    p(2).Minimum = 25;   %delta_Ts
    p(2).Maximum = 300;
    p(3).Minimum = 0.9;  %alpha_Fe
    p(3).Maximum = 1;
    p(4).Minimum = 0.01;  %alpha_Ni
    p(4).Maximum = 0.1;
    p(5).Minimum = 0.5;  %alpha_Co
    p(5).Maximum = 1;
    p(6).Minimum = 0.05;  %alpha_Cu
    p(6).Maximum = 0.5;
    p(7).Minimum = 0.145/10;  %m_dot_dust_and_accr. Divided by 10 because lance motion is a value between 1 and 10.
    p(7).Maximum = 30/10;
    p(8).Minimum = 0.88;   %epsilon
    p(8).Maximum = 0.95;
    p(9).Minimum = 373.15;  %T_furnace
    p(9).Maximum = 1473.15;
    p(10).Minimum = 1.5;  %R
    p(10).Maximum = 2;
    p(11).Minimum = 0.01;   %r_m
    p(11).Maximum = 0.03;
    p(12).Minimum = 0.025;  %r_s
    p(12).Maximum = 0.0375;
    
    % Get actual initial state and append it to the parameters in order for it to be estimated
    
    s = getValuesToEstimate(exp);
    stateVector = [p;s];
    
    % Define the estimation objective function
    
    estFcn = @(v) sdoTempModelEstimation_Objective(v,simulator,exp,data.Convertermode); % This is pretty easy to define - edit the one that's saved
    
    % Estimate the parameters
    
    opt = sdo.OptimizeOptions;
    opt.Method = 'lsqnonlin';
    vOpt = sdo.optimize(estFcn,stateVector,opt);
    
    % Compare measured outputs and final simulated outputs
    
    exp = setEstimatedValues(exp,vOpt);
    
    simulator    = createSimulator(exp, simulator);
    simulator    = sim(simulator);
    simLog             = find(simulator.LoggedData, get_param('fundamentalModel','SignalLoggingName'));
    slagTempSignal   = find(simLog,'Ts [C]');
    matteTempSignal    = find(simLog,'Median Tm [C]');

    % plotSimOutputs(seconds(data.Timestamp), data, bathHeightSignal, matteTempSignal)
    
    % Store optimal values from run (and results)
    rmseTm = sqrt(median((data.Mattetemperatures - matteTempSignal.Values.Data(2:end)).^2)); % Median is better
    rmseTs = sqrt(median((data.Slagtemperatures - slagTempSignal.Values.Data(2:end)).^2));
    
    parameterTable.rmseTm(tableIdx) = rmseTm;
    parameterTable.rmseTs(tableIdx) = rmseTs;

    parameterTable{tableIdx,5:end} = [vOpt.Value];

    fprintf('Endpoint %d of %d\n', [dataIdx+10000, height(origData)])
    clear tempdir
end
warning('on','all')
% Drop empty table rows
parameterTable(~parameterTable.U,:) = [];

%% Plot results

columnsToPlot = parameterTable.Properties.VariableNames(5:end);
for nColumn = 1:length(columnsToPlot)
    column = columnsToPlot{nColumn};
    figure
    histogram(parameterTable.(column),10)
    title(sprintf(column + ", Median = %4.3f", median(parameterTable.(column))),'interpreter','none')
end

%% Save rows as xml files

for nRow = 1:height(parameterTable)
    writestruct(table2struct(parameterTable(nRow,5:end)), ...
        ['optParams' + strrep(strrep(parameterTable{nRow,1}, ' ', ''), ':', '') + '.xml'])
end

%% Parallel Coords Plot

idx = kmeans(zscore(parameterTable{:, {'alpha_T', 'm_dot_dust_and_accr', 'T_furnace'}}), 3);
parameterTable.Cluster = idx;
parallelplot(parameterTable(:, 3:end), 'GroupVariable', 'Cluster')
