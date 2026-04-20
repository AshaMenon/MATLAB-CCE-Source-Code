parameters.highFrequencyPredictorTags = ["Matte feed PV", "Fuel coal feed rate PV", "Specific Oxygen Actual PV",...
                                          "Reverts feed rate PV", "Lump coal PV",...
                                          "Lance oxygen flow rate PV", "Lance air flow rate PV",...
                                          "Matte transfer air flow", "Lance coal carrier air",...
                                          "Silica PV",...
                                          "Upper Waffle 3", "Upper Waffle 4", "Upper Waffle 5",...
                                          "Upper Waffle 6", "Upper Waffle 7", "Upper Waffle 8",...
                                          "Upper Waffle 9", "Upper Waffle 10", "Upper Waffle 11",...
                                          "Upper Waffle 12", "Upper Waffle 13", "Upper Waffle 14",...
                                          "Upper Waffle 15", "Upper Waffle 16", "Upper Waffle 17",...
                                          "Upper Waffle 18",...
                                          "Lower waffle 19", "Lower waffle 20", "Lower waffle 21",...
                                          "Lower waffle 22", "Lower waffle 23", "Lower waffle 24",...
                                          "Lower waffle 25", "Lower waffle 26", "Lower waffle 27",...
                                          "Lower waffle 28", "Lower waffle 29", "Lower waffle 30",...
                                          "Lower waffle 31", "Lower waffle 32", "Lower waffle 33",...
                                          "Lower waffle 34", "Outer long 1", "Middle long 1",...
                                          "Outer long 2", "Middle long 2", "Outer long 3",...
                                          "Middle long 3", "Outer long 4", "Middle long 4",...
                                          "Centre long", "Lance Oxy Enrich % PV", "Roof matte feed rate PV",...
                                          "Lance height", "Lance motion", "Phase B Matte tap block 1 DT_water",...
                                          "Phase B Matte tap block 2 DT_water", "Phase B Slag tap block DT_water",...
                                          "Phase A Matte tap block 1 DT_water", "Phase A Matte tap block  DT_water",...
                                          "Phase A Slag tap block DT_water"];
                 
parameters.lowFrequencyPredictorTags = ["Cr2O3 Slag", "Basicity", "MgO Slag", "Cu Feedblend", "Ni Feedblend",...
                                        "Co Feedblend", "Fe Feedblend", "S Feedblend",...
                                        "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",...
                                        "MgO Feedblend", "Cr2O3 Feedblend", "Slag temperatures"];

parameters.referenceTags = ["Converter mode", "Lance air and oxygen control"];

parameters.responseTags = ["Matte temperatures"];

filterFurnaceModes.add = false;
filterFurnaceModes.modes = [6,7,8];

parameters.filterFurnaceModes = filterFurnaceModes;

parameters.removeTransientData = false;
parameters.tapClassification = true;
parameters.smoothFuelCoal = true;

inputsDF = readAndFormatData('Temperature');
x = inputsDF.Timestamp;
y = datetime(strrep(string(x), '0021','2021'));
inputsDF.Timestamp = y;

inputsDF.Properties.VariableNames = strrep(inputsDF.Properties.VariableNames, " ", "_");
parameters.highFrequencyPredictorTags = strrep(parameters.highFrequencyPredictorTags, " ","_");
parameters.lowFrequencyPredictorTags = strrep(parameters.lowFrequencyPredictorTags, " ","_");
parameters.referenceTags = strrep(parameters.referenceTags, " ","_");
parameters.responseTags = strrep(parameters.responseTags, " ","_");

% Format Data
inputsDF.SumOfSpecies = 1.13 * inputsDF.Cu_Slag + 1.27 * inputsDF.Ni_Slag + 1.27 * inputsDF.Co_Slag + ...
                        1.29 * inputsDF.Fe_Slag + 1.04 - 0.5 * inputsDF.S_Slag + inputsDF.SiO2_Slag + ...
                        inputsDF.Al2O3_Slag + inputsDF.CaO_Slag + inputsDF.MgO_Slag + inputsDF.Cr2O3_Slag;
inputsDF(find(inputsDF.SumOfSpecies > 110), 'SumOfSpecies') = table(0);

inputsDF = removeDuplicates(inputsDF);
inputsDF = fillMissingHXPoints(inputsDF);

phase = 'A';

[inputsDF, parameters.highFrequencyPredictorTags, parameters.lowFrequencyPredictorTags] = addLatentTemperatureFeatures(inputsDF, [parameters.highFrequencyPredictorTags, parameters.lowFrequencyPredictorTags], parameters.highFrequencyPredictorTags, parameters.lowFrequencyPredictorTags, phase);

%%
logger = CCELogger('MatteTemp MATLAB','Test Matte Temperature','TMT',255);
dataModel = Data(inputsDF, logger);

%[inputsDF, origSmoothedResponses, predictorTagsNew] = preprocessingAndFeatureEngineering(dataModel, struct('add', false, 'mode', [8]), 1, 'linear', false, false, [],[],[],[],false);
[inputsDF, origSmoothedResponses, predictorTagsNew] = preprocessingAndFeatureEngineering(dataModel, struct('add', false, 'mode', [8]), 1, 'linear', parameters.tapClassification, parameters.smoothFuelCoal, parameters.responseTags, parameters.referenceTags, parameters.highFrequencyPredictorTags, parameters.lowFrequencyPredictorTags, false);
%% 

function fullDFOrig = fillMissingHXPoints(fullDFOrig)
% Replace missing Lower Waffle values with mean of others
waffleTags = ["Lower_waffle_19", "Lower_waffle_20", "Lower_waffle_21",...
                  "Lower_waffle_22", "Lower_waffle_23", "Lower_waffle_24",...
                  "Lower_waffle_25", "Lower_waffle_26", "Lower_waffle_27",...
                  "Lower_waffle_28", "Lower_waffle_29", "Lower_waffle_30",...
                  "Lower_waffle_31", "Lower_waffle_32", "Lower_waffle_33",...
                  "Lower_waffle_34"];

fullDFOrig = replaceMissingWithMean(fullDFOrig, waffleTags);
fullDFOrig = fillWaffleNans(fullDFOrig, waffleTags);

% Replace missing Upper Waffle values with mean of others
waffleTags = ["Upper_Waffle_3", "Upper_Waffle_4", "Upper_Waffle_5",...
              "Upper_Waffle_6", "Upper_Waffle_7", "Upper_Waffle_8",...
              "Upper_Waffle_9", "Upper_Waffle_10", "Upper_Waffle_11",...
              "Upper_Waffle_12", "Upper_Waffle_13", "Upper_Waffle_14",...
              "Upper_Waffle_15", "Upper_Waffle_16", "Upper_Waffle_17",...
              "Upper_Waffle_18"];
          
fullDFOrig = replaceMissingWithMean(fullDFOrig, waffleTags);
fullDFOrig = fillWaffleNans(fullDFOrig, waffleTags);

% Replace missing outer long values with mean of others
outerLongTags = ["Outer_long_1", "Outer_long_2", "Outer_long_3",...
                 "Outer_long_4"];
fullDFOrig = replaceMissingWithMean(fullDFOrig, outerLongTags);

% Replace missing middle long values with mean of others
middleLongTags = ["Middle_long_1", "Middle_long_2", "Middle_long_3",...
                  "Middle_long_4"];
fullDFOrig = replaceMissingWithMean(fullDFOrig, middleLongTags);

end

function fullDFOrig = replaceMissingWithMean(fullDFOrig, tagsOfInterest)

% Replace spot nans with the mean of the other tags
for tagToFill = 0:(size(tagsOfInterest,2)-1)
    otherTags = [tagsOfInterest(1:tagToFill), tagsOfInterest(tagToFill+2:size(tagsOfInterest,2))];
    missingIdx = find(isnan(fullDFOrig.(tagsOfInterest(tagToFill+1))));
    fullDFOrig(missingIdx,tagsOfInterest(tagToFill+1)) = array2table(mean(table2array(fullDFOrig(missingIdx, otherTags)),2, 'omitnan'));
end
end

function fullDFOrig = fillWaffleNans(fullDFOrig, waffleTags)

% In cases where all tags are nans, replace the nans with 4 hour average
t = fullDFOrig.Timestamp;
fullDFOrig(:,waffleTags) = fillmissing(fullDFOrig(:,waffleTags), 'movmean', [hours(4) 0]);%, 'SamplePoints', t);

% Takes care of the rest
%y = fullDFOrig(:,waffleTags);
%fullDFOrig(:, waffleTags) = fillmissing(fullDFOrig(:,waffleTags), 'previous');
end

function fullDFOrig = removeDuplicates(fullDFOrig)
t = fullDFOrig.Timestamp;
[tDuplicates, i, j] = unique(t);
duplicateIdx = find(not(ismember(1:numel(t),i)));

fullDFOrig(duplicateIdx, :) = [];

end

%% Add Latent temperature features function

% Add Latent features (Specific to temperature model)

function [fullDFOrig, highFreqPredictors, lowFreqPredictors] = addLatentTemperatureFeatures(fullDFOrig, predictorTags, highFreqPredictors, lowFreqPredictors, phase)

%Add height to motion ratio
fullDFOrig.Lance_Height_to_Motion_Ratio = fullDFOrig.Lance_height./fullDFOrig.Lance_motion;
predictorTags = [predictorTags, 'Lance_Height_to_Motion_Ratio'];
highFreqPredictors = [highFreqPredictors, 'Lance_Height_to_Motion_Ratio'];

%Add Heat Flux
fullDFOrig.Heat_flux = -0.056*fullDFOrig.Centre_long + 0.25*mean(table2array(fullDFOrig(:,["Middle_long_1", "Middle_long_2", "Middle_long_3",...
    "Middle_long_4"])),2,'omitnan') - 0.145*mean(table2array(fullDFOrig(:,["Outer_long_1", "Outer_long_2", "Outer_long_3", "Outer_long_4"])),2,'omitnan');
predictorTags = [predictorTags, 'Heat_flux'];
highFreqPredictors = [highFreqPredictors,'Heat_flux'];

%Define Areas

if phase == 'A'
    upperAreas = [1.9, 1.9, 1.9, 1.5, 1.9, 1.5, 1.9, 1.9, 1.9, 1.9, 1.9, 1.5,...
                      1.9, 1.9, 1.9, 1.9];
    lowerAreas = 1.9*ones(1,16);
elseif phase == 'B'
    upperAreas = [1.827, 1.988, 1.827, 1.988, 1.827, 1.988, 1.827, 1.988, 1.827,...
                  1.988, 1.827, 1.988, 1.827, 1.988, 1.827, 1.988];
    lowerAreas = [1.827, 1.988, 1.48, 1.988, 1.48, 1.988, 1.827, 1.988, 1.827,...
                  1.988, 1.827, 1.988, 0.913, 1.988, 1.827, 1.988]; 
else
    warning('Invalid phase entered.')
    
end
 
%Add linearly independant version of lower waffle HX
waffleTags = ["Lower_waffle_19", "Lower_waffle_20", "Lower_waffle_21",...
                  "Lower_waffle_22", "Lower_waffle_23", "Lower_waffle_24",...
                  "Lower_waffle_25", "Lower_waffle_26", "Lower_waffle_27",...
                  "Lower_waffle_28", "Lower_waffle_29", "Lower_waffle_30",...
                  "Lower_waffle_31", "Lower_waffle_32", "Lower_waffle_33",...
                  "Lower_waffle_34"];
              
weightedFluxes = table2array(fullDFOrig(:, waffleTags)) .* (lowerAreas ./ sum(lowerAreas));
fullDFOrig(:, 'Lower_waffle_heat_flux') = array2table(sum(weightedFluxes,2));
predictorTags = [predictorTags, 'Lower_waffle_heat_flux'];        
highFreqPredictors = [highFreqPredictors, 'Lower_waffle_heat_flux'];

%Drop lower waffle heat exchanger - have the PCs
fullDFOrig = removevars(fullDFOrig,waffleTags);
predictorTags(find(ismember(predictorTags, cellstr(waffleTags)))) = [];
highFreqPredictors(find(ismember(highFreqPredictors, cellstr(waffleTags)))) = [];

% Add linearly independent version of Upper Waffle HX
waffleTags = ["Upper_Waffle_3", "Upper_Waffle_4", "Upper_Waffle_5",...
                  "Upper_Waffle_6", "Upper_Waffle_7", "Upper_Waffle_8",...
                  "Upper_Waffle_9", "Upper_Waffle_10", "Upper_Waffle_11",...
                  "Upper_Waffle_12", "Upper_Waffle_13", "Upper_Waffle_14",...
                  "Upper_Waffle_15", "Upper_Waffle_16", "Upper_Waffle_17",...
                  "Upper_Waffle_18"];

% Add total heat flux from Waffles
weightedFluxes = table2array(fullDFOrig(:, waffleTags)) .* (upperAreas ./ sum(upperAreas));
fullDFOrig(:, 'Upper_waffle_heat_flux') = array2table(sum(weightedFluxes,2));
predictorTags = [predictorTags, 'Upper_waffle_heat_flux'];        
highFreqPredictors = [highFreqPredictors, 'Upper_waffle_heat_flux'];

% Drop Upper Waffle Heat Exchangers - have the PCs
fullDFOrig = removevars(fullDFOrig,waffleTags);
predictorTags(find(ismember(predictorTags, cellstr(waffleTags)))) = [];
highFreqPredictors(find(ismember(highFreqPredictors, cellstr(waffleTags)))) = [];

% Drop Hearth Heat Exchangers - only interested in Heat Flux
tagsToDrop = ["Centre_long", "Middle_long_1", "Middle_long_2", "Middle_long_3",...
                  "Middle_long_4", "Outer_long_1", "Outer_long_2", "Outer_long_3",...
                  "Outer_long_4"];
fullDFOrig = removevars(fullDFOrig,tagsToDrop);
predictorTags(find(ismember(predictorTags, cellstr(tagsToDrop)))) = [];
highFreqPredictors(find(ismember(highFreqPredictors, cellstr(tagsToDrop)))) = [];
end