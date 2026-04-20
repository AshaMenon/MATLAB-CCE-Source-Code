classdef Data < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        outputLogger CCELogger
        fullDF timetable
    end

    methods
        function obj = Data(fullDF, outputLogger)
            obj.fullDF = fullDF;
            obj.outputLogger = outputLogger;
        end

        function [fullDF, origSmoothedResponses, predictorTagsNew] = preprocessingAndFeatureEngineering(self, ...
                filterFurnaceModes, resampleTime, resampleMethod, ...
                tapClassification, smoothFuelCoal, responseTags, referenceTags, ...
                highFrequencyPredictorTags, lowFrequencyPredictorTags, phase, writeToExcel)
            arguments
                self Data
                filterFurnaceModes struct
                resampleTime = "minutely"
                resampleMethod = 'linear'
                tapClassification = parameters
                smoothFuelCoal = parameters
                responseTags = parameters.responseTags
                referenceTags = parameters.referenceTags
                highFrequencyPredictorTags = parameters.highFrequencyPredictorTags
                lowFrequencyPredictorTags = parameters.lowFrequencyPredictorTags
                phase = parameters.phase
                writeToExcel = false
            end

            % Extract specific data to be processed
            fullDF = self.fullDF;
            
            % Format data (remove duplicate timestamps)
            fullDF = Data.formatData(fullDF);
            fullDF = Data.fillMissingHXPoints(fullDF);
            [fullDF, highFrequencyPredictorTags, lowFrequencyPredictorTags, ~] = Data.addLatentTemperatureFeatures(fullDF, [highFrequencyPredictorTags, lowFrequencyPredictorTags], highFrequencyPredictorTags, lowFrequencyPredictorTags, phase);
            self.outputLogger.logTrace(['Data formatted and duplicates removed, dataset size: ', num2str(height(fullDF))])
            
            % Add Sum of Species
            fullDF.SumOfSpecies = 1.13 * fullDF.CuSlag + 1.27 * fullDF.NiSlag + 1.27 * fullDF.CoSlag + ...
                1.29 * fullDF.FeSlag + 1.04 - 0.5 * fullDF.SSlag + fullDF.SiO2Slag + ...
                fullDF.Al2O3Slag + fullDF.CaOSlag + fullDF.MgOSlag + fullDF.Cr2O3Slag;
            fullDF.SumOfSpecies(fullDF.SumOfSpecies > 110) = 0;
            self.outputLogger.logTrace('Sum of Species added')
            
            if phase == 'A'
                highFrequencyPredictorTags(strcmp(highFrequencyPredictorTags,"PhaseBMattetapblock1DT_water")) = [];
                highFrequencyPredictorTags(strcmp(highFrequencyPredictorTags,"PhaseBMattetapblock2DT_water")) = [];
                highFrequencyPredictorTags(strcmp(highFrequencyPredictorTags,"PhaseBSlagtapblockDT_water")) = [];
                highFrequencyPredictorTags(strcmp(highFrequencyPredictorTags,"PhaseAMattetapblock1DT_water")) = "PhaseMattetapblock1DT_water";
                highFrequencyPredictorTags(strcmp(highFrequencyPredictorTags,"PhaseAMattetapblockDT_water")) = "PhaseMattetapblock2DT_water";
                highFrequencyPredictorTags(strcmp(highFrequencyPredictorTags,"PhaseASlagtapblockDT_water")) = "PhaseSlagtapblockDT_water";
                fullDF.Properties.VariableNames(strcmp(fullDF.Properties.VariableNames,"PhaseAMattetapblock1DT_water")) = "PhaseMattetapblock1DT_water";
                fullDF.Properties.VariableNames(strcmp(fullDF.Properties.VariableNames,"PhaseAMattetapblockDT_water")) = "PhaseMattetapblock2DT_water";
                fullDF.Properties.VariableNames(strcmp(fullDF.Properties.VariableNames,"PhaseASlagtapblockDT_water")) = "PhaseSlagtapblockDT_water";
            elseif phase =='B'
                highFrequencyPredictorTags(strcmp(highFrequencyPredictorTags,"PhaseAMattetapblock1DT_water")) = [];
                highFrequencyPredictorTags(strcmp(highFrequencyPredictorTags,"PhaseAMattetapblockDT_water")) = [];
                highFrequencyPredictorTags(strcmp(highFrequencyPredictorTags,"PhaseASlagtapblockDT_water")) = [];
                highFrequencyPredictorTags(strcmp(highFrequencyPredictorTags,"PhaseBMattetapblock1DT_water")) = "PhaseMattetapblock1DT_water";
                highFrequencyPredictorTags(strcmp(highFrequencyPredictorTags,"PhaseBMattetapblock2DT_water")) = "PhaseMattetapblock2DT_water";
                highFrequencyPredictorTags(strcmp(highFrequencyPredictorTags,"PhaseBSlagtapblockDT_water")) = "PhaseSlagtapblockDT_water";
                fullDF.Properties.VariableNames(strcmp(fullDF.Properties.VariableNames,"PhaseBMattetapblock1DT_water")) = "PhaseMattetapblock1DT_water";
                fullDF.Properties.VariableNames(strcmp(fullDF.Properties.VariableNames,"PhaseBMattetapblock2DT_water")) = "PhaseMattetapblock2DT_water";
                fullDF.Properties.VariableNames(strcmp(fullDF.Properties.VariableNames,"PhaseBSlagtapblockDT_water")) = "PhaseSlagtapblockDT_water";
            end

            predictorTags = [highFrequencyPredictorTags, lowFrequencyPredictorTags];
            fullDF = fullDF(:, unique([predictorTags, responseTags, referenceTags, highFrequencyPredictorTags, lowFrequencyPredictorTags], 'sorted'));
            self.outputLogger.logTrace(['Full Dataset set, dataset size :', num2str(height(fullDF))]);

            % Replace data outside operating range
            operatingRangeDict = Data.restrictData(fullDF.Properties.VariableNames);
            for column = fullDF.Properties.VariableNames
                fullDF(:, column) = Data.filterExpectedDataRange(fullDF(:,column),...
                    operatingRangeDict{column, 1},...
                    operatingRangeDict{column, 2});
                if any(isnan(table2array(fullDF(:,column))))
                    fullDF(:, column) =  array2table(fillmissing(table2array(fullDF(:, column)), 'previous'));
                    self.outputLogger.logWarning(strcat('Out of bounds data forward filled for input: ', num2str(size(fullDF))))
                end
            end
            self.outputLogger.logTrace(['Data set within operating Range :', num2str(height(fullDF))])
            
            predictorTagsNew = predictorTags;
            
            % Filter furnace modes
            if filterFurnaceModes.add
                fullDF = Data.filterMultipleFurnaceModes(fullDF, filterFurnaceModes.modes);
                self.outputLogger.logTrace('Furnace Modes Filtered')
            end

            % Store original responses (no resampling)
            origSmoothedResponses = Data.getUniqueDataPoints(fullDF(any(~isnan(table2array(fullDF(:,responseTags))),2), responseTags));
            self.outputLogger.logTrace(['Original Smooth Response Found, dataset size: ', num2str(height(fullDF))])

            % Add tapping indication signals
            if tapClassification
                fullDF = Data.tappingClassification(fullDF, "PhaseMattetapblock1DT_water", 5, 0.2);
                fullDF = Data.tappingClassification(fullDF, "PhaseMattetapblock2DT_water", 5, 0.2);
                % fullDF = Data.tappingClassification(fullDF, "PhaseSlagtapblockDT_water", 5, 0.05);
                fullDF = Data.slagTappingClassification(fullDF, 'SlagFlowThermo');
                % fullDF = Data.comboSlagTappingClassification(fullDF, 20);
                
                self.outputLogger.logTrace(['Tapping Classifications added, dataset size: ', num2str(height(fullDF))]);
            end

            %Smooth Fuel Coal Feed Rate
            if smoothFuelCoal
                smoothedFuelCoal = Data.smoothFuelCoal(table2array(fullDF(:, "FuelcoalfeedratePV")));
                fullDF(:, "FuelcoalfeedratePV") = array2table(smoothedFuelCoal);
                self.outputLogger.logTrace(['Smooth Fuel Coal Feed Rate added, dataset size: ', num2str(height(fullDF))]);
            end

            if writeToExcel
                fileName = 'processedAndEngineeredData.xlsx';
                thisFile = pwd;
                filePath = fullfile(thisFile, 'data', fileName);
                writetimetable(fullDF, filePath);
                self.outputLogger.logTrace(['Data written out to excel, dataset size: ', num2str(height(fullDF))]);
            end

            for nColumn = 1:length(fullDF.Properties.VariableNames)
                columnName = fullDF.Properties.VariableNames{nColumn};
                if all(isnan(table2array(fullDF(:,column))),1)
                    error(['All NaNs in column: ', columnName]);
                end
            end
            
            % Replace Datetime index with duration index
            fullDF = Data.createDurationIndex(fullDF);
            self.outputLogger.logTrace(['Duration index added, dataset size: ', num2str(height(fullDF))]);

            % Add additional feeds to table for Temperature SL Model
            fullDF = Data.addFeedsTemperatureData(fullDF);
            self.outputLogger.logTrace(['Feed temperature data added, dataset size: ', num2str(height(fullDF))]);

            fullDF = rmmissing(fullDF);
            self.outputLogger.logTrace(['Missing values removed, dataset size: ', num2str(height(fullDF))]);
        end
    end

    methods (Static, Access=private)
        function operatingRangeDict = restrictData(columnNames)
            arguments
                columnNames (1,:) cell
            end

            operatingRangeDict = array2table(repmat([-1000000, 1000000],[numel(columnNames),1]));
            operatingRangeDict.Row = columnNames;
            operatingRangeDict("Cu_Slag",:) = table(0.1, 25);
            operatingRangeDict("Ni_Slag",:) = table(0.2, 30);
            operatingRangeDict("Corrected_Ni_Slag",:) = table(0.5, 10);
            operatingRangeDict("Co_Slag",:) = table(0, 10);
            operatingRangeDict("Fe_Slag",:) = table(20, 60);
            operatingRangeDict("S_Slag",:) = table(0.1, 20);
            operatingRangeDict("Al2O3_Slag",:) = table(0.5, 6);
            operatingRangeDict("CaO_Slag",:) = table(0.2, 3);
            operatingRangeDict("MgO_Slag",:) = table(0.1, 2);
            operatingRangeDict("Cr2O3_Slag",:) = table(0.1, 10);
            operatingRangeDict("SiO2_Slag",:) = table(0.1, 60);  % check
            operatingRangeDict("Basicity",:) = table(1.1, 2.5);
            operatingRangeDict("Cu_Matte",:) = table(20, 40);
            operatingRangeDict("Ni_Matte",:) = table(30, 50);
            operatingRangeDict("Co_Matte",:) = table(0.05, 1.0);
            operatingRangeDict("Fe_Matte",:) = table(0, 20);
            operatingRangeDict("S_Matte",:) = table(5, 35);
            operatingRangeDict('Specific_Oxygen_Actual_PV',:) = table(0, 10000);
            operatingRangeDict('Specific_Silica_Actual_PV',:) = table(0, 300);
            operatingRangeDict("Matte_feed_PV(unfiltered)",:) = table(0, 150);
            operatingRangeDict("Lance_air_flow_rate_PV",:) = table(0, 30000);
            operatingRangeDict("Lance_air_flow_rate_SP",:) = table(0, 30000);
            operatingRangeDict("Lance_oxygen_flow_rate_PV",:) = table(0, 10000);
            operatingRangeDict("Lance_oxygen_flow_rate_SP",:) = table(0, 10000);
            operatingRangeDict("Shroud_air_flow_rate_PV",:) = table(0, 14000);
            operatingRangeDict("Shroud_air_flow_rate_SP",:) = table(0, 14000);
            operatingRangeDict("Shroud_oxygen_flow_rate_PV",:) = table(0, 3000);
            operatingRangeDict("Shroud_oxygen_flow_rate_SP",:) = table(0, 3000);
            operatingRangeDict("Standby_system_coal_transfer_air_pressure",:) = table(0, 30);
            operatingRangeDict("Lancemotion",:) = table(0, 10);
            operatingRangeDict("Lance_foam_potential",:) = table(-20, 20);
            operatingRangeDict("Trolley_foam_potential",:) = table(-5, 5);
            operatingRangeDict("Slag_mass_flow",:) = table(0, 10);
            operatingRangeDict("Matte_temperatures",:) = table(1100, 1600);
            operatingRangeDict("Slag_temperatures",:) = table(1000, 1600);
            operatingRangeDict("Lance_height",:) = table(0, 4000);
            operatingRangeDict("Fe_in_mould_(per_blow)",:) = table(0, 20);
            operatingRangeDict("Ni_Feedblend",:) = table(1, 30);
            operatingRangeDict("Cu_Feedblend",:) = table(6, 15);
            operatingRangeDict("Co_Feedblend",:) = table(0, 10);
            operatingRangeDict("MgO_Feedblend",:) = table(0, 10);
            operatingRangeDict("CaO_Feedblend",:) = table(0, 10);
            operatingRangeDict("Al2O3_Feedblend",:) = table(0, 10);
            operatingRangeDict("Fe_Feedblend",:) = table(20, 50);
            operatingRangeDict("S_Feedblend",:) = table(5, 40);
            operatingRangeDict("SiO2_Feedblend",:) = table(0.5, 40);
            operatingRangeDict("Cr2O3_Feedblend",:) = table(0, 10);
            operatingRangeDict("Percent_Vapour",:) = table(0.1, 20);
            operatingRangeDict("Lance_feed_PV",:) = table(0, 20);
            operatingRangeDict("Lump_Coal_SP",:) = table(0, 25);
            operatingRangeDict("Matte_feed_SP",:) = table(0, 60);
            operatingRangeDict("Matte_feed_PV(filtered)",:) = table(0, 60);
            operatingRangeDict("Roof_feed_PV",:) = table(0, 20);
            operatingRangeDict("Roof_coal_transfer_air_pressure",:) = table(0, 500);
            operatingRangeDict("Acid_plant_damper_position",:) = table(0,50);
            operatingRangeDict("Blower_222",:) = table(50,100);
            operatingRangeDict("Blower_221",:) = table(50,100);
            operatingRangeDict("Lance_Oxy_Enrich_%_PV",:) = table(-1000,1000);
            operatingRangeDict("O2_SO2_Ratio_1",:) = table(0,45);
            operatingRangeDict("O2_SO2_Ratio_2",:) = table(0,45);
            operatingRangeDict("Roof_Coal_feed_PV",:) = table(0,100);
            operatingRangeDict("Fuel_coal_feed_rate_PV",:) = table(0,100);
            operatingRangeDict("Lower_waffle_19",:) = table(-20, 150);
            operatingRangeDict("Lower_waffle_20",:) = table(-20, 150);
            operatingRangeDict("Lower_waffle_21",:) = table(-20, 150);
            operatingRangeDict("Lower_waffle_22",:) = table(-20, 150);
            operatingRangeDict("Lower_waffle_23",:) = table(-20, 150);
            operatingRangeDict("Lower_waffle_24",:) = table(-20, 150);
            operatingRangeDict("Lower_waffle_25",:) = table(-20, 150);
            operatingRangeDict("Lower_waffle_26",:) = table(-20, 150);
            operatingRangeDict("Lower_waffle_27",:) = table(-20, 150);
            operatingRangeDict("Lower_waffle_28",:) = table(-20, 150);
            operatingRangeDict("Lower_waffle_29",:) = table(-20, 150);
            operatingRangeDict("Lower_waffle_30",:) = table(-20, 150);
            operatingRangeDict("Lower_waffle_31",:) = table(-20, 150);
            operatingRangeDict("Lower_waffle_32",:) = table(-20, 150);
            operatingRangeDict("Lower_waffle_33",:) = table(-20, 150);
            operatingRangeDict("Lower_waffle_34",:) = table(-20, 150);
            operatingRangeDict("Upper_waffle_3",:) = table(-20, 150);
            operatingRangeDict("Upper_waffle_4",:) = table(-20, 150);
            operatingRangeDict("Upper_waffle_5",:) = table(-20, 150);
            operatingRangeDict("Upper_waffle_6",:) = table(-20, 150);
            operatingRangeDict("Upper_waffle_7",:) = table(-20, 150);
            operatingRangeDict("Upper_waffle_8",:) = table(-20, 150);
            operatingRangeDict("Upper_waffle_9",:) = table(-20, 150);
            operatingRangeDict("Upper_waffle_10",:) = table(-20, 150);
            operatingRangeDict("Upper_waffle_11",:) = table(-20, 150);
            operatingRangeDict("Upper_waffle_12",:) = table(-20, 150);
            operatingRangeDict("Upper_waffle_13",:) = table(-20, 150);
            operatingRangeDict("Upper_waffle_14",:) = table(-20, 150);
            operatingRangeDict("Upper_waffle_15",:) = table(-20, 150);
            operatingRangeDict("Upper_waffle_16",:) = table(-20, 150);
            operatingRangeDict("Upper_waffle_17",:) = table(-20, 150);
            operatingRangeDict("Upper_waffle_18",:) = table(-20, 150);
            operatingRangeDict("SpO2_PV",:) = table(0, 400);
        end

        function fullDF = formatData(fullDF)
            t = fullDF.Timestamp;
            [~, i, ~] = unique(t);
            duplicateIdx = ~(ismember(1:numel(t),i));

            fullDF(duplicateIdx, :) = [];
        end
        
        function fullDF = fillMissingHXPoints(fullDF)
            % Replace missing Lower Waffle values with mean of others
            waffleTags = ["Lowerwaffle19", "Lowerwaffle20", "Lowerwaffle21",...
                          "Lowerwaffle22", "Lowerwaffle23", "Lowerwaffle24",...
                          "Lowerwaffle25", "Lowerwaffle26", "Lowerwaffle27",...
                          "Lowerwaffle28", "Lowerwaffle29", "Lowerwaffle30",...
                          "Lowerwaffle31", "Lowerwaffle32", "Lowerwaffle33",...
                          "Lowerwaffle34"];

            fullDF = Data.replaceMissingWithMean(fullDF, waffleTags);
            fullDF = Data.fillWaffleNans(fullDF, waffleTags);

            % Replace missing Upper Waffle values with mean of others
            waffleTags = ["UpperWaffle3", "UpperWaffle4", "UpperWaffle5",...
                          "UpperWaffle6", "UpperWaffle7", "UpperWaffle8",...
                          "UpperWaffle9", "UpperWaffle10", "UpperWaffle11",...
                          "UpperWaffle12", "UpperWaffle13", "UpperWaffle14",...
                          "UpperWaffle15", "UpperWaffle16", "UpperWaffle17",...
                          "UpperWaffle18"];

            fullDF = Data.replaceMissingWithMean(fullDF, waffleTags);
            fullDF = Data.fillWaffleNans(fullDF, waffleTags);

%             % Replace missing outer long values with mean of others
%             outerLongTags = ["Outerlong1", "Outerlong2", "Outerlong3",...
%                              "Outerlong4"];
%             fullDF = Data.replaceMissingWithMean(fullDF, outerLongTags);
% 
%             % Replace missing middle long values with mean of others
%             middleLongTags = ["Middlelong1", "Middlelong2", "Middlelong3",...
%                               "Middlelong4"];
%             fullDF = Data.replaceMissingWithMean(fullDF, middleLongTags);
        end
        
        function fullDF = replaceMissingWithMean(fullDF, tagsOfInterest)
            % Replace spot nans with the mean of the other tags
            for tagToFill = 0:(size(tagsOfInterest,2)-1)
                otherTags = [tagsOfInterest(1:tagToFill), tagsOfInterest(tagToFill+2:size(tagsOfInterest,2))];
                missingIdx = find(isnan(fullDF.(tagsOfInterest(tagToFill+1))));
                fullDF(missingIdx,tagsOfInterest(tagToFill+1)) = array2table(mean(table2array(fullDF(missingIdx, otherTags)),2, 'omitnan'));
            end
        end
        
        function fullDF = fillWaffleNans(fullDF, waffleTags)
            % In cases where all tags are nans, replace the nans with 4 hour average
            fullDF(:,waffleTags) = fillmissing(fullDF(:,waffleTags), 'movmean', [minutes(239) 0]); %240 minutes is equivalent to 4 hours. 2399 minutes was used otherwise the results would be offest compared to the python results by 1 minute.
        end
        
        function filteredData = filterExpectedDataRange(data, low, high)
            highIdx = table2array(data) <= high;
            lowIdx = table2array(data) >= low;
            Idx = ~(highIdx & lowIdx);
            data(Idx,:) = table(NaN);
            filteredData = data;
        end
        
        function filteredData = filterMultipleFurnaceModes(data, modes)
            modeIdx = data("Converter mode") == modes(1);
            for nMode = modes
                modeIdx = modeIdx | data("Converter mode") == nMode;
            end
            filteredData = data(:,modeIdx);
        end

        function fullDF = tappingClassification(fullDF, tag, startingPoint, increaseThreshold)

            tappingData = fullDF(:,tag);

            % Create a new coloumn in the dataframe to store classification data
            tappingData(:, append("TappingClassificationFor", string(tag))) = table(zeros(size(fullDF,1),1));

            % Apply a low pass filter on the the noisy slag tap block temp data (this is not applied in a real time format to save computing power - yields the same results when applied in a real-time format)
            if isequal(tag, "PhaseSlagtapblockDT_water")
                [b, a] = butter(2, (2.5/(30/2)),"low");
                tappingData.origPhaseSlagtapblockDT_water = tappingData.PhaseSlagtapblockDT_water;
                tappingData(:, "PhaseSlagtapblockDT_water") = array2table(filter(b, a, table2array(tappingData(:, "PhaseSlagtapblockDT_water"))));
            end
            
            % Iterate through the data in a real-time approach to find definite increases in temperature between successive points
            difference2 = splitAndDiff(tappingData, tag, 2);
            difference3 = splitAndDiff(tappingData, tag, 3);
            difference4 = splitAndDiff(tappingData, tag, 4);
            difference5 = splitAndDiff(tappingData, tag, 5);

            tapIdx = (difference2 > 0 & difference3 > 0 & difference4 > 0 & difference5 > increaseThreshold);
            
            tappingTagName = append("TappingClassificationFor", string(tag));
            tappingData(tapIdx, tappingTagName) = table(1);
            
            % Fill small gaps with previous tap states
            tappingData = Data.fillTapGaps(tappingData(:, tappingTagName), tappingTagName, minutes(3));
            tappingData.Properties.VariableNames{2} = 'firstSmooth';
            tappingData = Data.fillTapGaps(tappingData(:, 'firstSmooth'), 'firstSmooth', minutes(3));
            fullDF(:,tappingTagName) = tappingData(:, 'smoothedTap');
            
        end
    
        function coalFeedRate = smoothFuelCoal(coalFeedRate)
            upperCoalFeedThreshold = 2.5;
            lowerCoalFeedThreshold = 0.5;
            threshold = 0.5;     %units fuelCoalFeedRate/min

            for i = 10:height(coalFeedRate)-1
                gradient = coalFeedRate(i,:) - coalFeedRate(i-1,:); % calculates the change in fuel coal feed rate between sucessive measurements
                if (gradient > threshold) && (coalFeedRate(i,:) > upperCoalFeedThreshold) % if the change in successive feed rates is large and the next measurement is out of an acceptable bound then reset it
                    coalFeedRate(i,:) = coalFeedRate(i-1,:);
                elseif (gradient < -threshold) && (coalFeedRate(i,:) < lowerCoalFeedThreshold) % if the change in successive feed rates is large (in the negative direction) and the next measurement is out of an acceptable bound then reset it
                    coalFeedRate(i,:) = coalFeedRate(i-1,:);
                elseif (gradient > 1) || (gradient < -1) % if the change in fuel coal rate is [excessively] large then reset the next measurement
                    coalFeedRate(i,:) = coalFeedRate(i-1,:);
                end
            end

            % #The code below smoothes out the response of the coalFeedRate, it has been implemented below to decrease runtime. For a real time application it needs to be included in the for loop so that it updates every minute.
            % smoothCoalFeedRate = SimpleExpSmoothing(coalFeedRate[:i], initialization_method="heuristic").fit(
            %     smoothing_level=0.1, optimized=False)
            % coalFeedRate = smoothCoalFeedRate.fittedvalues
        end

        function [fullDF, highFreqPredictors, lowFreqPredictors, predictorTags] = addLatentTemperatureFeatures(fullDF, predictorTags, highFreqPredictors, lowFreqPredictors, phase)

%             %Add height to motion ratio
%             fullDF.LanceHeighttoMotionRatio = fullDF.Lanceheight./fullDF.Lancemotion;
%             predictorTags = [predictorTags, 'LanceHeighttoMotionRatio'];
%             highFreqPredictors = [highFreqPredictors, 'LanceHeighttoMotionRatio'];
% 
%             %Add Heat Flux
%             fullDF.Heatflux = -0.056*fullDF.Centrelong + 0.25*mean(table2array(fullDF(:,["Middlelong1", "Middlelong2", "Middlelong3",...
%                 "Middlelong4"])),2,'omitnan') - 0.145*mean(table2array(fullDF(:,["Outerlong1", "Outerlong2", "Outerlong3", "Outerlong4"])),2,'omitnan');
%             predictorTags = [predictorTags, 'Heatflux'];
%             highFreqPredictors = [highFreqPredictors,'Heatflux'];

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
            waffleTags = ["Lowerwaffle19", "Lowerwaffle20", "Lowerwaffle21",...
                "Lowerwaffle22", "Lowerwaffle23", "Lowerwaffle24",...
                "Lowerwaffle25", "Lowerwaffle26", "Lowerwaffle27",...
                "Lowerwaffle28", "Lowerwaffle29", "Lowerwaffle30",...
                "Lowerwaffle31", "Lowerwaffle32", "Lowerwaffle33",...
                "Lowerwaffle34"];

            heatOutPerPanel = table2array(fullDF(:, waffleTags)) .* lowerAreas;
            fullDF(:, 'LowerwaffleHeatRate') = array2table(sum(heatOutPerPanel,2));
            predictorTags = [predictorTags, 'LowerwaffleHeatRate'];
            highFreqPredictors = [highFreqPredictors, 'LowerwaffleHeatRate'];

            %Drop lower waffle heat exchanger - have the PCs
            fullDF = removevars(fullDF,waffleTags);
            predictorTags(ismember(predictorTags, cellstr(waffleTags))) = [];
            highFreqPredictors(ismember(highFreqPredictors, cellstr(waffleTags))) = [];

            % Add linearly independent version of Upper Waffle HX
            waffleTags = ["UpperWaffle3", "UpperWaffle4", "UpperWaffle5",...
                "UpperWaffle6", "UpperWaffle7", "UpperWaffle8",...
                "UpperWaffle9", "UpperWaffle10", "UpperWaffle11",...
                "UpperWaffle12", "UpperWaffle13", "UpperWaffle14",...
                "UpperWaffle15", "UpperWaffle16", "UpperWaffle17",...
                "UpperWaffle18"];

            % Add total heat flux from Waffles
            heatOutPerPanel = table2array(fullDF(:, waffleTags)) .* upperAreas;
            fullDF(:, 'UpperwaffleHeatRate') = array2table(sum(heatOutPerPanel,2));
            predictorTags = [predictorTags, 'UpperwaffleHeatRate'];
            highFreqPredictors = [highFreqPredictors, 'UpperwaffleHeatRate'];

            % Drop Upper Waffle Heat Exchangers - have the PCs
            fullDF = removevars(fullDF,waffleTags);
            predictorTags(ismember(predictorTags, cellstr(waffleTags))) = [];
            highFreqPredictors(ismember(highFreqPredictors, cellstr(waffleTags))) = [];

%             % Drop Hearth Heat Exchangers - only interested in Heat Flux
%             tagsToDrop = ["Centrelong", "Middlelong1", "Middlelong2", "Middlelong3",...
%                 "Middlelong4", "Outerlong1", "Outerlong2", "Outerlong3",...
%                 "Outerlong4"];
%             fullDF = removevars(fullDF,tagsToDrop);
%             predictorTags(ismember(predictorTags, cellstr(tagsToDrop))) = [];
%             highFreqPredictors(ismember(highFreqPredictors, cellstr(tagsToDrop))) = [];
        end

        function fullDF = slagTappingClassification(fullDF, tag)
            % Uses the SlagFlowThermo tag to indicate when tapping happens
            fullDF.ThermoSlagTapping = zeros(height(fullDF), 1);
            
            onIdx = diff(fullDF.(tag)) > 0.25;
            offIdx = diff(fullDF.(tag)) < -0.25;
            
            onTimes = fullDF.Timestamp(onIdx);
            offTimes = fullDF.Timestamp(offIdx);
            if ~isempty(onTimes)
                thisOnTime = onTimes(1);
                while thisOnTime < onTimes(end)
                    nextPotentialOnTimes = onTimes - thisOnTime;
                    nextOnTime = onTimes(find(nextPotentialOnTimes > minutes(10), 1));
                    if isempty(nextOnTime)
                        nextOnTime = fullDF.Timestamp(end);
                    end
                    timeDiffs = thisOnTime - offTimes(offTimes < nextOnTime);
                    thisOffTimeOptions = offTimes(timeDiffs > hours(-2) & timeDiffs < 0);
                    if isempty(thisOffTimeOptions)
                        thisOffTime = nextOnTime;
                    else
                        thisOffTime = thisOffTimeOptions(end);
                    end
                    fullDF{isbetween(fullDF.Timestamp, thisOnTime, thisOffTime, "closed"), 'ThermoSlagTapping'} = 1;
                    %update nOnTime
                    thisOnTime = nextOnTime;
                end
            end
            tappingData = Data.fillTapGaps(fullDF(:, 'ThermoSlagTapping'), 'ThermoSlagTapping', minutes(5));
            fullDF.SlagClassification = tappingData.smoothedTap;
        end

        function fullDF = comboSlagTappingClassification(fullDF, tappingThreshold)

            data = fullDF(:,'ThermoSlagTapping');
            if all(data.ThermoSlagTapping == 0)
                data.SlagClassification = false(height(data), 1);
            else
                data.onSignal = [false; diff(data.ThermoSlagTapping) == 1];

                onOffThresholds = [data.Timestamp(data.onSignal), data.Timestamp(data.onSignal) + minutes(tappingThreshold)];

                timeThresholdIdx = arrayfun(@(x1, x2) isbetween(data.Timestamp,x1,x2),...
                    onOffThresholds(:,1), onOffThresholds(:,2), 'UniformOutput', false);
                data.timeThresholdSignal = sum(horzcat(timeThresholdIdx{:}), 2);
                data.timeThresholdSignal = data.timeThresholdSignal > 0;
                data.tapBlockClassification = fullDF.TappingClassificationForPhaseSlagtapblockDT_water;
                data.timeSignalOff = [false; diff(data.timeThresholdSignal) == -1];
                data.tapBlockClassificationOff = [false; diff(data.tapBlockClassification) == -1];

                % Tapping classification ON when time threshold signal on
                data.SlagClassification = data.timeThresholdSignal;
                % When time threshold signal goes OFF, check tap block
                % classification
                timeSignalOFFTimes = data.Timestamp(data.timeSignalOff);
                tapBlockClassificationOffTimes = data.Timestamp(data.tapBlockClassificationOff);
                for nTime = 1:length(timeSignalOFFTimes)
                    %       if tap block classification is still on, or
                    %       <if it has been on during the time threshold,>
                    %           stay on until tap block classification OFF
                    timeSignalOFFTime = timeSignalOFFTimes(nTime);
                    if data.tapBlockClassification(timeSignalOFFTime)
                        tapBlockClassificationOffTimeIdx = find(tapBlockClassificationOffTimes - timeSignalOFFTime > 0, 1, 'first');
                        thisTapBlockOffTime = tapBlockClassificationOffTimes(tapBlockClassificationOffTimeIdx);
                        if isempty(thisTapBlockOffTime)
                            data{isbetween(data.Timestamp, timeSignalOFFTime, data.Timestamp(end)), 'SlagClassification'} = true;
                        else
                            data{isbetween(data.Timestamp, timeSignalOFFTime, thisTapBlockOffTime), 'SlagClassification'} = true;
                        end
                    end
                end
            %       if tap block classification off, go OFF
            end
            fullDF.SlagClassification = data.SlagClassification;
        end

        function endIdx  = getTimeIdx(tbl, start_date, end_date)

            % Select range of times from the timetable
            tr = timerange(start_date, end_date);
            tt_range = tbl(tr,:);


            % Initialize variables
            first_to_one = NaT;
            last_to_zero = NaT;

            % Loop through the rows of the timetable range
            for i = 2:height(tt_range)
                % Get the date and data values for the current row
                curr_date = tt_range(i,:).Timestamp;
                curr_data = tt_range{i-1:i,:};

                % Check for transition from 0 to 1
                if diff(curr_data) == 1 && isnat(first_to_one)
                    first_to_one = curr_date;
                end

                % Check for transition from 1 to 0
                if diff(curr_data) == -1
                    last_to_zero = curr_date;
                end
            end
            endIdx = last_to_zero;
        end
    end  

    methods (Static, Access=public)

        function [uniqueDataSeries, irregularIdx, dataSeries] = getUniqueDataPoints(dataSeries)
            valueChangeIdx = [true; diff(table2array(dataSeries)) ~= 0];
            irregularIdx = dataSeries.Timestamp(valueChangeIdx,:);
            uniqueDataSeries = dataSeries(valueChangeIdx,:);
            dataSeries(~valueChangeIdx,:) = table(NaN);
            dataSeries = fillmissing(dataSeries, "linear", 'EndValues', 'previous');
            dataSeries(end,:) = array2table(table2array(uniqueDataSeries(end,:)));
        end

        function [fullTimestamp, fullTM] = matchTimeStampsAndData(fullTimestamp, origTimestamp, fullTM)
            %MATCHTIMESTAMPSANDDATA - Fixes oversampling problem when Simulink
            %   model assumes all data is available
            origTimestamp = dateshift(origTimestamp, 'start', 'minute', 'nearest');
            idx = ismember(fullTimestamp, origTimestamp);
            fullTimestamp = fullTimestamp(idx);
            fullTM = fullTM(idx,:);
        end

        function [data, seriesStartDate] = createDurationIndex(data)
            %CREATEDURATIONINDEX - Takes timetable DATA and converts the datetime index
            %   to an elapsed duration instead. For use with the Simulinnk Model
            
            seriesStartDate = data.Timestamp(1);
            time = cumsum(diff(data.Timestamp));
            data(1,:) = [];
            data.Timestamp = time;
        end

        function data = addFeedsTemperatureData(data)
            % ADDFEEDSTEMPERATUREDATA - Adds some additional feeds used in the
            %   temperature model
            % Total Feed Consists of:
            % - Matte Feed
            % - Roof Matte
            % - Reverts
            % - PGM Feed
            % - Lump Coal
            % - Roof Coal (?)
            % - Fuel Coal
            % - Standby Feed (?)
            % - Silica
            % - Lance Air Flow
            % - Lance Oxygen Flow
            % - Shroud Air Flow
            % - Shroud Oxygen Flow
            % - Matte Transfer Air Flow
            % - Lance Coal Transfer Air

            data.FeedRateTot = data.MattefeedPV + data.FuelcoalfeedratePV + ... %TODO: Lump coal isn't a fuel - double check its usage in the fundamental model
                data.SilicaPV + data.RoofmattefeedratePV +...
                data.LanceairflowratePV*1.293/1000 +...
                data.LanceoxygenflowratePV.*1.429/1000; %TODO: Check this equation.

            data.CoalFeedRate = data.FuelcoalfeedratePV; %TODO: Lump coal isn't a fuel - double check its usage in the fundamental model

            data.MatteFeedTotal = data.MattefeedPV + data.RoofmattefeedratePV;
        end

        function data = fillTapGaps(data, tappingTagName, threshold)
        % Fills small gaps <= threshold in the input sqare waveform with
        % the previous value
            onOffChangeTimes = data.Timestamp(abs(diff(data.(tappingTagName))) == 1);
            shortGapIdx = diff(onOffChangeTimes) <= threshold;
            onOffChangeTimes = [onOffChangeTimes(1:end-1), onOffChangeTimes(2:end)];
            data.smoothedTap = data.(tappingTagName);
            for nGap = 1:length(shortGapIdx)
                gap = shortGapIdx(nGap);
                if gap
                    gapStart = onOffChangeTimes(nGap, 1);
                    gapEnd = onOffChangeTimes(nGap, 2);
                    data{isbetween(data.Timestamp, gapStart, gapEnd, 'openleft'), 'smoothedTap'} = nan;
                end
            end
            data.smoothedTap = fillmissing(data.smoothedTap, 'next');
        end
    end
end
