function [simOut, simInTT, parameters] = runMassBalanceTest(varargin)
% Create an input parser
p = inputParser;

% Add parameters with default values
addParameter(p, 'startTime', '01-Aug-2024 15:00:00');
addParameter(p, 'endTime', '8-Aug-2024 23:59:00');
addParameter(p, 'dataDir', 'data/POL_SIL_Data_20241023_2024AugData.xlsx');
addParameter(p, 'showPlots', false);
addParameter(p, 'inputsTT', [], @(inputsTT) istable(inputsTT) || istimetable(inputsTT))

% Parse the input arguments
parse(p, varargin{:});

% Access parsed values
startTime = p.Results.startTime;
endTime = p.Results.endTime;
dataDir = p.Results.dataDir;
showPlots = p.Results.showPlots;
inputsTT = p.Results.inputsTT;

%% Load data and run simulation
% read inputs from file

if isempty(inputsTT)
    inputsTT = readtable(dataDir, "Sheet", "Sheet1");
end

nFeedSamples = 3;
feedDelayHrs = 24;
inputsTT.MatteFallFraction = calcMatteFallFractionsAve(inputsTT, nFeedSamples, feedDelayHrs);

parameters = loadParameters();

% initial filtering
inputsTT = filterByDateTime(inputsTT, startTime, endTime);

[slInputs, slParameters, simStartDateTime] = prepareDataForSim(inputsTT, parameters);
simInTT = inputsTT(inputsTT.Timestamp >= simStartDateTime, :); % input data used directly in the mass balance part of the simulation

%fieldnames to variables
assignin("base", 'slParameters', slParameters)
assignin("base", 'slInputs', slInputs)

% run test harness
open('massBalance.slx');
sltest.harness.open('massBalance', 'massBalance_HarnessFromWorkspace');
tStopSecs = seconds(slInputs.power_MW.simTime(end));
simOut = sim('massBalance_HarnessFromWorkspace', 'StopTime', num2str(tStopSecs));

%% Plot simulation results against levels measured by sounding
if showPlots

    [validMatteSoundingsCm, isValidationMatteSounding, validSlagSoundingsCm, isValidationSlagSounding, validConcSoundingsCm, isValidationConcSounding] = extractValidationSoundings(simInTT, includeFirstVal=true);
    
    totalMassSoundingsTon = parameters.bath_area * (((simInTT.MatteThickness + simInTT.BuildUpThickness)/100) * parameters.matte_density + ...
        (simInTT.SlagThickness / 100) * parameters.slag_density + (simInTT.ConcThickness / 100) * parameters.concentrate_density);
    totalMassSoundingsTon = fillmissing(totalMassSoundingsTon, 'previous');
    totalMassModelTon = parameters.bath_area * (simOut.height_matte.Data * parameters.matte_density + ... 
        simOut.height_slag.Data * parameters.slag_density + simOut.height_concentrate.Data * parameters.concentrate_density);
    isValidationTotalMassSounding = isValidationMatteSounding & isValidationSlagSounding & isValidationConcSounding;
    validTotalMassSoundingsTon = totalMassSoundingsTon(isValidationTotalMassSounding);
    
    graphModelVsSoundings(simInTT.Timestamp, simOut, validMatteSoundingsCm, isValidationMatteSounding, validSlagSoundingsCm, isValidationSlagSounding, validConcSoundingsCm, isValidationConcSounding, validTotalMassSoundingsTon, isValidationTotalMassSounding, totalMassModelTon)




    %% Error metrics    
    
    matteRmse = rmse(simOut.height_matte.Data(isValidationMatteSounding) * 100, validMatteSoundingsCm);
    slagRmse = rmse(simOut.height_slag.Data(isValidationSlagSounding) * 100, validSlagSoundingsCm);
    concRmse = rmse(simOut.height_concentrate.Data(isValidationConcSounding) * 100, validConcSoundingsCm);
    totalMassRmse = rmse(totalMassModelTon(isValidationTotalMassSounding), validTotalMassSoundingsTon);
    
    fprintf("Matte RMSE: %f cm\n", matteRmse)
    fprintf("Slag RMSE: %f cm\n", slagRmse)
    fprintf("Conc RMSE: %f cm\n", concRmse)
    fprintf("Total mass RMSE: %f ton\n", totalMassRmse)


end
end

function graphModelVsSoundings(timestamps, simOut, validMatteSoundingsCm, isValidationMatteSounding, validSlagSoundingsCm, isValidationSlagSounding, validConcSoundingsCm, isValidationConcSounding, validTotalMassSoundingsTon, isValidationTotalMassSounding, totalMassModelTon)
    figure
    tiledlayout(2, 2)
    
    % matte
    ax1 = nexttile;
    stairs(timestamps(isValidationMatteSounding), validMatteSoundingsCm, '.-')
    hold on
    plot(timestamps(1:length(simOut.height_matte.Data)), simOut.height_matte.Data * 100)
    hold off
    title("Matte height (cm)")
    legend(["Measured", "Model"])
    
    % slag
    ax2 = nexttile;
    stairs(timestamps(isValidationSlagSounding), validSlagSoundingsCm, '.-')
    hold on
    plot(timestamps(1:length(simOut.height_slag.Data)), simOut.height_slag.Data * 100)
    hold off
    title("Slag height (cm)")
    legend(["Measured", "Model"])
    
    
    
    % concentrate
    ax3 = nexttile;
    stairs(timestamps(isValidationConcSounding), validConcSoundingsCm, '.-')
    hold on
    plot(timestamps(1:length(simOut.height_concentrate.Data)), simOut.height_concentrate.Data * 100)
    hold off
    title("Concentrate height (cm)")
    legend(["Measured", "Model"])
    
    ax4 = nexttile;
    stairs(timestamps(isValidationTotalMassSounding), validTotalMassSoundingsTon, '.-');
    hold on
    plot(timestamps(1:length(simOut.height_matte.Data)), totalMassModelTon)
    hold off
    title("Total material mass (ton)")
    legend(["Measured", "Model"])
    
    linkaxes([ax1 ax2 ax3 ax4], 'x')
end