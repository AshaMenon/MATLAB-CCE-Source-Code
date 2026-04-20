function [matteFallFractions] = calcMatteFallFractionsAve(dataTT, nSamples, delayHrs, log)
    %CALCMATTEFALLFRACTIONSFROMFLASHDRYER calculates the matte fall
    %fraction for each time step in inputs based on flash dryer composition

    % all mass inputs should be in grams, and sample is assumed to be 100g
    %   (or equivalently all mass inputs should be in percentage of the
    %   100g sample)


    arguments
        dataTT
        nSamples {mustBeNumeric}
        delayHrs {mustBeNumeric}
        log = []
    end

    % extract discrete samples
    feedSamplesTable = extractValidSamples(dataTT);

    % validation
    if height(feedSamplesTable) == 0
        error("No valid feed composition samples found")
    end

    if height(feedSamplesTable) < nSamples
        if ~isempty(log)
            log.logWarning("Only %d feed composition samples are present in the data. %d samples are expected.\n" + ...
                "Calculating using %d samples.", height(feedSamplesTable), nSamples, height(feedSamplesTable));
        else
            warning("Only %d feed composition samples are present in the data. %d samples are expected.\n" + ...
                "Calculating using %d samples.", height(feedSamplesTable), nSamples, height(feedSamplesTable));
        end
        nSamples = height(feedSamplesTable);
    end

    %% calculate number of samples taken at least delayHrs before the timestep
    feedSamplesTable.FurnaceTimestamp = feedSamplesTable.Timestamp + hours(delayHrs);

    matteFallFractions = nan(size(dataTT.Timestamp));

    % special case: only nSamples in data window
    if height(feedSamplesTable) == nSamples
        matteFallFractions(:) = calcMatteFallFraction(mean(feedSamplesTable.MgO), ...
            mean(feedSamplesTable.Al2O3), mean(feedSamplesTable.SiO2), mean(feedSamplesTable.S), mean(feedSamplesTable.CaO), mean(feedSamplesTable.Cr2O3), ...
            mean(feedSamplesTable.Fe), mean(feedSamplesTable.Co), mean(feedSamplesTable.Ni), mean(feedSamplesTable.Cu));
        return
    end

    % for all values for which we don't have more than nSamples (delayHrs before),
    % use the first nSamples in the input set
    matteFallFractions(dataTT.Timestamp < feedSamplesTable.FurnaceTimestamp(nSamples+1)) = calcMatteFallFraction(mean(feedSamplesTable.MgO(1:nSamples)), ...
        mean(feedSamplesTable.Al2O3(1:nSamples)), mean(feedSamplesTable.SiO2(1:nSamples)), mean(feedSamplesTable.S(1:nSamples)), mean(feedSamplesTable.CaO(1:nSamples)), mean(feedSamplesTable.Cr2O3(1:nSamples)), ...
        mean(feedSamplesTable.Fe(1:nSamples)), mean(feedSamplesTable.Co(1:nSamples)), mean(feedSamplesTable.Ni(1:nSamples)), mean(feedSamplesTable.Cu(1:nSamples)));

    % for any values (more than delayHrs) after the last sample, use the last
    % 3 samples in the input set
    matteFallFractions(dataTT.Timestamp >= feedSamplesTable.FurnaceTimestamp(end)) = calcMatteFallFraction(mean(feedSamplesTable.MgO(end-(nSamples-1):end)), ...
        mean(feedSamplesTable.Al2O3(end-(nSamples-1):end)),...
        mean(feedSamplesTable.SiO2(end-(nSamples-1):end)), mean(feedSamplesTable.S(end-(nSamples-1):end)), mean(feedSamplesTable.CaO(end-(nSamples-1):end)), mean(feedSamplesTable.Cr2O3(end-(nSamples-1):end)), ...
        mean(feedSamplesTable.Fe(end-(nSamples-1):end)), mean(feedSamplesTable.Co(end-(nSamples-1):end)), mean(feedSamplesTable.Ni(end-(nSamples-1):end)), mean(feedSamplesTable.Cu(end-(nSamples-1):end)));

    % for all other entries, use the 3 most recent samples (from at least delayHrs before)
    for idx = nSamples+1 : height(feedSamplesTable) - 1
        conditional = all([dataTT.Timestamp >= feedSamplesTable.FurnaceTimestamp(idx), dataTT.Timestamp < feedSamplesTable.FurnaceTimestamp(idx+1)], 2);
        matteFallFractions(conditional) = calcMatteFallFraction(mean(feedSamplesTable.MgO(idx-(nSamples-1):idx)), ...
            mean(feedSamplesTable.Al2O3(idx-(nSamples-1):idx)),...
            mean(feedSamplesTable.SiO2(idx-(nSamples-1):idx)), mean(feedSamplesTable.S(idx-(nSamples-1):idx)), mean(feedSamplesTable.CaO(idx-(nSamples-1):idx)), mean(feedSamplesTable.Cr2O3(idx-(nSamples-1):idx)), ...
            mean(feedSamplesTable.Fe(idx-(nSamples-1):idx)), mean(feedSamplesTable.Co(idx-(nSamples-1):idx)), mean(feedSamplesTable.Ni(idx-(nSamples-1):idx)), mean(feedSamplesTable.Cu(idx-(nSamples-1):idx)));
    end
end

function feedSamplesTable = extractValidSamples(inputs)
    feedCompounds = {'MgO', 'Al2O3', 'SiO2', 'S', 'CaO', 'Cr2O3', 'Fe', 'Co', 'Ni', 'Cu'};
    feedSamples = [];
    validSamples = all([inputs.FeedS > 3, inputs.FeedS < 8], 2);
    for idx = 2 : length(inputs.Timestamp)
        compositionHasChanged = any([inputs.FeedMgO(idx) ~= inputs.FeedMgO(idx-1), inputs.FeedAl2O3(idx) ~= inputs.FeedAl2O3(idx-1),...
            inputs.FeedSiO2(idx) ~= inputs.FeedSiO2(idx-1),...
            inputs.FeedS(idx) ~= inputs.FeedS(idx-1),...
            inputs.FeedCaO(idx) ~= inputs.FeedCaO(idx-1),...
            inputs.FeedCr2O3(idx) ~= inputs.FeedCr2O3(idx-1),...
            inputs.FeedFe(idx) ~= inputs.FeedFe(idx-1),...
            inputs.FeedCo(idx) ~= inputs.FeedCo(idx-1),...
            inputs.FeedNi(idx) ~= inputs.FeedNi(idx-1),...
            inputs.FeedCu(idx) ~= inputs.FeedCu(idx-1)]);

        if compositionHasChanged && validSamples(idx)
            feedSample = cell2struct({inputs.Timestamp(idx) inputs.FeedMgO(idx) inputs.FeedAl2O3(idx) ...
                inputs.FeedSiO2(idx) inputs.FeedS(idx) inputs.FeedCaO(idx) inputs.FeedCr2O3(idx) inputs.FeedFe(idx) ...
                inputs.FeedCo(idx) inputs.FeedNi(idx) inputs.FeedCu(idx)}', ...
                [{'Timestamp'} feedCompounds]', 1);
            feedSamples = [feedSamples; feedSample]; %#ok<AGROW>
        end
    end

    if isempty(feedSamples)
        feedSamples = cell2struct({inputs.Timestamp(idx) inputs.FeedMgO(idx) inputs.FeedAl2O3(idx) ...
            inputs.FeedSiO2(idx) inputs.FeedS(idx) inputs.FeedCaO(idx) inputs.FeedCr2O3(idx) inputs.FeedFe(idx) ...
            inputs.FeedCo(idx) inputs.FeedNi(idx) inputs.FeedCu(idx)}', ...
            [{'Timestamp'} feedCompounds]', 1);
    end
    feedSamplesTable = struct2table(feedSamples);
end

