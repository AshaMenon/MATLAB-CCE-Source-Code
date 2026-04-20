function outputs = MatteTempModel(data, modelName, referenceTime, parameters, log)
    %#function fundamentalm

% Create Simulation Inputs (for Simulink Compiler)
simInputs = Simulink.SimulationInput('fundamentalModel');
log.logTrace(['Compiler Sim Input Loaded for ' simInputs.ModelName])

%fieldnames to variables
simVar = parameters.simVar;
varNames = fieldnames(simVar);
for v = 1:numel(varNames)
    assignin("base", varNames{v}, simVar.(varNames{v}))
    simInputs = setVariable(simInputs, varNames{v}, simVar.(varNames{v}));
end
log.logTrace([num2str(numel(simInputs.Variables)) ' Input Variables Loaded'])

%Set external inputs
inputColumnNames = {'MatteFeedTotal', 'FeedRateTot', 'Lancemotion',...
    'TappingClassificationForPhaseMattetapblock1DT_water',...
    'TappingClassificationForPhaseMattetapblock2DT_water',...
    'SlagClassification', 'LowerwaffleHeatRate', 'CoalFeedRate',...
    'UpperwaffleHeatRate', 'FeFeedblend', 'NiFeedblend', 'CoFeedblend',...
    'CuFeedblend', 'Mattetemperatures', 'Slagtemperatures',...
    'Lanceheight', 'LanceOxyEnrichPercentagePV', 'SilicaPV',...
    'PhaseMattetapblock1DT_water', 'PhaseMattetapblock2DT_water',...
    'PhaseSlagtapblockDT_water', 'Convertermode'};
slInputs = double([seconds(data.Timestamp), data{:, inputColumnNames}]);
assignin("base", "slInputs", slInputs)
simInputs = simInputs.setExternalInput(slInputs);
log.logTrace([num2str(height(simInputs.ExternalInput)) ' by ' num2str(width(simInputs.ExternalInput)) ' External Inputs Set'])

% Define when simulation should end (up until data runs out)
simStopTime = seconds(data.Timestamp(end));
simInputs = simInputs.setModelParameter('StopTime', string(simStopTime));

% Run Simulink model
simInputs = simulink.compiler.configureForDeployment(simInputs);
log.logTrace('Sim Inputs configured')

simOut = sim(simInputs); %  
log.logTrace('Simulation Executed')

if ~exist("D:\simOutputs.mat")
    save('D:\simOutputs', 'simOut');
end

% Find the last timestamp (in string format) and matte temperature
fullTimestamp = duration(0, 0, simOut.tout) + referenceTime;
origTimestamp = data.Timestamp + referenceTime;
fullTM = simOut.logsout.extractTimetable;
log.logTrace(['MATLAB Variables loaded: ' num2str(height(fullTM)) ' by ' num2str(width(fullTM))])

[fullTimestamp, fullTM] = Data.matchTimeStampsAndData(fullTimestamp, origTimestamp, fullTM);
log.logTrace(['MATLAB Variables Matched: ' num2str(height(fullTM)) ' by ' num2str(width(fullTM))])

outputs = struct();
switch parameters.simMode
    case 'simulation'
        returnIdx = 1:height(fullTM);
    case 'production'
        returnIdx = height(fullTM);
end
outputs.Timestamp = fullTimestamp(returnIdx);
outputs.SimulatedMatteTemperature = fullTM{returnIdx, 'Tm [C]'};
outputs.SimulatedSlagTemperature = fullTM{returnIdx, 'Ts [C]'};
outputs.SmoothedMatteTemperature = fullTM{returnIdx, 'Median Tm [C]'};
outputs.SmoothedSlagTemperature = fullTM{returnIdx, 'Median Ts [C]'};
outputs.SimulatedMatteHeight = fullTM{returnIdx, 'hm'};
outputs.SimulatedSlagHeight = fullTM{returnIdx, 'hs'};
outputs.SimulatedTotalBathHeight = outputs.SimulatedSlagHeight + outputs.SimulatedMatteHeight;
outputs.MatteTapping = (data.TappingClassificationForPhaseMattetapblock1DT_water(returnIdx) | data.TappingClassificationForPhaseMattetapblock2DT_water(returnIdx));
% outputs.SlagTapping = data.TappingClassificationForPhaseSlagtapblockDT_water(returnIdx);
outputs.SlagTapping = data.SlagClassification(returnIdx);
% outputs.SlagTappingTapBlock = data.TappingClassificationForPhaseSlagtapblockDT_water(returnIdx);
outputs.ThermoSlagTapping = data.ThermoSlagTapping(returnIdx);

outputs.RecommendedFuelCoalSP = nan(length(returnIdx), 1);
outputs.HeatConductedfromSlagtoMatte = fullTM{returnIdx, 'QMatteConv [kW]'};
outputs.HeatMassFlowfromSlagtoMatte = fullTM{returnIdx, 'QMatteFall [kW]'};
outputs.HeatConductedfromMattetoWaffleCooler = fullTM{returnIdx, 'QMatteHXLower [kW]'};
outputs.HeatMassFlowMatteTappedMatteBath = fullTM{returnIdx, 'QMatteTapping [kW]'};
outputs.HeatGeneratedSlag = fullTM{returnIdx, 'QGenFeed [kW]'} + fullTM{end, 'QGenFuelCoal [kW]'};
outputs.HeatMassFlowfromSlagtoInflow = fullTM{returnIdx, 'Qinflow [kW]'};
outputs.HeatMassFlowMatteTappedFullBath = fullTM{returnIdx, 'QOutMatte [kW]'};
outputs.HeatMassFlowSlagTapped = fullTM{returnIdx, 'QOutSlag [kW]'};
outputs.HeatConductedfromFullBathtoWaffleCooler = fullTM{returnIdx, 'QBathHX [kW]'};
outputs.HeatRadiatedfromSlagtoFurnace = fullTM{returnIdx, 'QRad [kW]'};
outputs.HeatMassFlowfromOffgastoFurnace = fullTM{returnIdx, 'Qoffgas [kW]'};
outputs.HeatMassFlowfromAccruedSlagandDusttoFurnace = fullTM{returnIdx, 'QaccrSlagAndDust [kW]'};
outputs.TotalHeatInMatte = outputs.HeatConductedfromSlagtoMatte + outputs.HeatMassFlowfromSlagtoMatte;
outputs.TotalHeatOutMatte = outputs.HeatConductedfromMattetoWaffleCooler + outputs.HeatMassFlowMatteTappedMatteBath;
outputs.TotalHeatInBath = outputs.HeatGeneratedSlag;
outputs.TotalHeatOutBath = outputs.HeatMassFlowfromSlagtoInflow + outputs.HeatMassFlowMatteTappedFullBath ...
    + outputs.HeatMassFlowSlagTapped + outputs.HeatConductedfromFullBathtoWaffleCooler + outputs.HeatRadiatedfromSlagtoFurnace ...
    + outputs.HeatMassFlowfromOffgastoFurnace + outputs.HeatMassFlowfromAccruedSlagandDusttoFurnace;
outputs.SlagTappingRate = fullTM{returnIdx, 'Slag Tapping Rate [tonne/hr]'};
outputs.MatteTappingRate = fullTM{returnIdx, 'Matte Tapping Rate [tonne/hr]'};


end