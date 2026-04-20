function testArr = extractValidationSoundingsTest
    testArr = functiontests(localfunctions);
end

function setupOnce(testCase)
    startDatetime = datetime(2024, 8, 1);
    endDatetime = datetime(2024, 8, 8);
    testCase.TestData.defaultInputsTT = timetable((startDatetime:minutes(1):endDatetime)');
    testCase.TestData.defaultInputsTT.Properties.DimensionNames{1} = 'Timestamp';
    testCase.TestData.defaultInputsTT.BuildUpThickness = zeros(height(testCase.TestData.defaultInputsTT), 1);
    testCase.TestData.defaultInputsTT.MatteThickness = zeros(height(testCase.TestData.defaultInputsTT), 1);
    testCase.TestData.defaultInputsTT.SlagThickness = zeros(height(testCase.TestData.defaultInputsTT), 1);
    testCase.TestData.defaultInputsTT.ConcThickness = zeros(height(testCase.TestData.defaultInputsTT), 1);

    testCase.TestData.tolCm = 0.1;
    testCase.TestData.matteLevelMaxCm = 76;
    testCase.TestData.matteLevelMinCm = 54;
    testCase.TestData.slagLevelMaxCm = 150;
    testCase.TestData.slagLevelMinCm = 76;
    testCase.TestData.concLevelMaxCm = 130;
    testCase.TestData.concLevelMinCm = 70;
end

function testNoSoundings(testCase)
    inputsTT = testCase.TestData.defaultInputsTT;
    tolCm = testCase.TestData.tolCm;
    matteLevelMaxCm = testCase.TestData.matteLevelMaxCm;
    matteLevelMinCm = testCase.TestData.matteLevelMinCm;
    slagLevelMaxCm = testCase.TestData.slagLevelMaxCm;
    slagLevelMinCm = testCase.TestData.slagLevelMinCm;
    concLevelMaxCm = testCase.TestData.concLevelMaxCm;
    concLevelMinCm = testCase.TestData.concLevelMinCm;
    
    % zeros
    inputsTT.BuildUpThickness = zeros(height(inputsTT), 1);
    inputsTT.MatteThickness = zeros(height(inputsTT), 1);
    inputsTT.SlagThickness = zeros(height(inputsTT), 1);
    inputsTT.ConcThickness = zeros(height(inputsTT), 1);
    [validMatteSoundingsCm, isValidationMatteSounding, validSlagSoundingsCm, isValidationSlagSounding, validConcSoundingsCm, isValidationConcSounding] = extractValidationSoundings(inputsTT, ...
        tolCm=tolCm, matteLevelMaxCm=matteLevelMaxCm, matteLevelMinCm=matteLevelMinCm, slagLevelMaxCm=slagLevelMaxCm, slagLevelMinCm=slagLevelMinCm, concLevelMaxCm=concLevelMaxCm, concLevelMinCm=concLevelMinCm);
    verifyTrue(testCase, isempty(validMatteSoundingsCm))
    verifyEqual(testCase, sum(isValidationMatteSounding), 0)
    verifyTrue(testCase, isempty(validSlagSoundingsCm))
    verifyEqual(testCase, sum(isValidationSlagSounding), 0)
    verifyTrue(testCase, isempty(validConcSoundingsCm))
    verifyEqual(testCase, sum(isValidationConcSounding), 0)

    % constant: a constant array implies no soundings have been taken during
    % the period
    inputsTT.BuildUpThickness = 20 * ones(height(inputsTT), 1);
    inputsTT.MatteThickness = 50 * ones(height(inputsTT), 1);
    inputsTT.SlagThickness =  100 * ones(height(inputsTT), 1);
    inputsTT.ConcThickness = 100 * ones(height(inputsTT), 1);

    [validMatteSoundingsCm, isValidationMatteSounding, validSlagSoundingsCm, isValidationSlagSounding, validConcSoundingsCm, isValidationConcSounding] = extractValidationSoundings(inputsTT, ...
        tolCm=tolCm, matteLevelMaxCm=matteLevelMaxCm, matteLevelMinCm=matteLevelMinCm, slagLevelMaxCm=slagLevelMaxCm, slagLevelMinCm=slagLevelMinCm, concLevelMaxCm=concLevelMaxCm, concLevelMinCm=concLevelMinCm);
    verifyTrue(testCase, isempty(validMatteSoundingsCm))
    verifyEqual(testCase, sum(isValidationMatteSounding), 0)
    verifyTrue(testCase, isempty(validSlagSoundingsCm))
    verifyEqual(testCase, sum(isValidationSlagSounding), 0)
    verifyTrue(testCase, isempty(validConcSoundingsCm))
    verifyEqual(testCase, sum(isValidationConcSounding), 0)
end

function testTwoInvalidSoundings(testCase)
    inputsTT = testCase.TestData.defaultInputsTT;
    tolCm = testCase.TestData.tolCm;
    matteLevelMaxCm = testCase.TestData.matteLevelMaxCm;
    matteLevelMinCm = testCase.TestData.matteLevelMinCm;
    slagLevelMaxCm = testCase.TestData.slagLevelMaxCm;
    slagLevelMinCm = testCase.TestData.slagLevelMinCm;
    concLevelMaxCm = testCase.TestData.concLevelMaxCm;
    concLevelMinCm = testCase.TestData.concLevelMinCm;

    SOUNDING_INDEX_1 = 100;
    SOUNDING_INDEX_2 = 200;
    % sounding 1: all below min
    inputsTT.BuildUpThickness(SOUNDING_INDEX_1:end) = matteLevelMinCm/2 - 2 * tolCm;
    inputsTT.MatteThickness(SOUNDING_INDEX_1:end) = matteLevelMinCm/2;
    inputsTT.SlagThickness(SOUNDING_INDEX_1:end) =  slagLevelMinCm - 2 * tolCm;
    inputsTT.ConcThickness(SOUNDING_INDEX_1:end) = concLevelMinCm - 2 * tolCm;
    % sounding 2: all above max
    inputsTT.BuildUpThickness(SOUNDING_INDEX_2:end) = matteLevelMaxCm/2 + 2 * tolCm;
    inputsTT.MatteThickness(SOUNDING_INDEX_2:end) = matteLevelMaxCm/2;
    inputsTT.SlagThickness(SOUNDING_INDEX_2:end) =  slagLevelMaxCm + 2 * tolCm;
    inputsTT.ConcThickness(SOUNDING_INDEX_2:end) = concLevelMaxCm + 2 * tolCm;

[validMatteSoundingsCm, isValidationMatteSounding, validSlagSoundingsCm, isValidationSlagSounding, validConcSoundingsCm, isValidationConcSounding] = extractValidationSoundings(inputsTT, ...
        tolCm=tolCm, matteLevelMaxCm=matteLevelMaxCm, matteLevelMinCm=matteLevelMinCm, slagLevelMaxCm=slagLevelMaxCm, slagLevelMinCm=slagLevelMinCm, concLevelMaxCm=concLevelMaxCm, concLevelMinCm=concLevelMinCm);
    verifyTrue(testCase, isempty(validMatteSoundingsCm))
    verifyEqual(testCase, sum(isValidationMatteSounding), 0)
    verifyTrue(testCase, isempty(validSlagSoundingsCm))
    verifyEqual(testCase, sum(isValidationSlagSounding), 0)
    verifyTrue(testCase, isempty(validConcSoundingsCm))
    verifyEqual(testCase, sum(isValidationConcSounding), 0)
end

function testTwoValidSoundings(testCase)
    inputsTT = testCase.TestData.defaultInputsTT;
    tolCm = testCase.TestData.tolCm;
    matteLevelMaxCm = testCase.TestData.matteLevelMaxCm;
    matteLevelMinCm = testCase.TestData.matteLevelMinCm;
    slagLevelMaxCm = testCase.TestData.slagLevelMaxCm;
    slagLevelMinCm = testCase.TestData.slagLevelMinCm;
    concLevelMaxCm = testCase.TestData.concLevelMaxCm;
    concLevelMinCm = testCase.TestData.concLevelMinCm;

    SOUNDING_INDEX_1 = 100;
    SOUNDING_INDEX_2 = 200;
    % sounding 1: all just above min
    inputsTT.BuildUpThickness(SOUNDING_INDEX_1:end) = matteLevelMinCm/2 + 2 * tolCm;
    inputsTT.MatteThickness(SOUNDING_INDEX_1:end) = matteLevelMinCm/2;
    inputsTT.SlagThickness(SOUNDING_INDEX_1:end) =  slagLevelMinCm + 2 * tolCm;
    inputsTT.ConcThickness(SOUNDING_INDEX_1:end) = concLevelMinCm + 2 * tolCm;
    % sounding 2: all just below max
    inputsTT.BuildUpThickness(SOUNDING_INDEX_2:end) = matteLevelMaxCm/2 - 2 * tolCm;
    inputsTT.MatteThickness(SOUNDING_INDEX_2:end) = matteLevelMaxCm/2;
    inputsTT.SlagThickness(SOUNDING_INDEX_2:end) =  slagLevelMaxCm - 2 * tolCm;
    inputsTT.ConcThickness(SOUNDING_INDEX_2:end) = concLevelMaxCm - 2 * tolCm;

    [validMatteSoundingsCm, isValidationMatteSounding, validSlagSoundingsCm, isValidationSlagSounding, validConcSoundingsCm, isValidationConcSounding] = extractValidationSoundings(inputsTT, ...
        tolCm=tolCm, matteLevelMaxCm=matteLevelMaxCm, matteLevelMinCm=matteLevelMinCm, slagLevelMaxCm=slagLevelMaxCm, slagLevelMinCm=slagLevelMinCm, concLevelMaxCm=concLevelMaxCm, concLevelMinCm=concLevelMinCm);

    % expected outputs
    expectedMatteSoundingsCm = [matteLevelMinCm + 2 * tolCm; matteLevelMaxCm - 2 * tolCm];
    expectedSlagSoundingsCm = [slagLevelMinCm + 2 * tolCm; slagLevelMaxCm - 2 * tolCm];
    expectedConcSoundingsCm = [concLevelMinCm + 2 * tolCm; concLevelMaxCm - 2 * tolCm];

    verifyLessThan(testCase, abs(validMatteSoundingsCm - expectedMatteSoundingsCm), tolCm * ones(size(expectedMatteSoundingsCm)));
    verifyEqual(testCase, sum(isValidationMatteSounding), numel(expectedMatteSoundingsCm));    
    verifyLessThan(testCase, abs(validSlagSoundingsCm - expectedSlagSoundingsCm), tolCm * ones(size(expectedSlagSoundingsCm)));
    verifyEqual(testCase, sum(isValidationSlagSounding), numel(expectedSlagSoundingsCm));   
    verifyLessThan(testCase, abs(validConcSoundingsCm - expectedConcSoundingsCm), tolCm * ones(size(expectedConcSoundingsCm)));
    verifyEqual(testCase, sum(isValidationConcSounding), numel(expectedConcSoundingsCm));
end

function testValidAndInvalidSoundingsMix(testCase)
    inputsTT = testCase.TestData.defaultInputsTT;
    tolCm = testCase.TestData.tolCm;
    matteLevelMaxCm = testCase.TestData.matteLevelMaxCm;
    matteLevelMinCm = testCase.TestData.matteLevelMinCm;
    slagLevelMaxCm = testCase.TestData.slagLevelMaxCm;
    slagLevelMinCm = testCase.TestData.slagLevelMinCm;
    concLevelMaxCm = testCase.TestData.concLevelMaxCm;
    concLevelMinCm = testCase.TestData.concLevelMinCm;

    INVALID_SOUNDING_INDEX_1 = 100;
    INVALID_SOUNDING_INDEX_2 = 200;
    VALID_SOUNDING_INDEX_1 = 300;
    VALID_SOUNDING_INDEX_2 = 400;
    MIXED_SOUNDING_INDEX_1 = 500;
    MIXED_SOUNDING_INDEX_2 = 600;
    % invalid sounding 1: all below min 
    inputsTT.BuildUpThickness(INVALID_SOUNDING_INDEX_1:end) = matteLevelMinCm/2 - 2 * tolCm;
    inputsTT.MatteThickness(INVALID_SOUNDING_INDEX_1:end) = matteLevelMinCm/2;
    inputsTT.SlagThickness(INVALID_SOUNDING_INDEX_1:end) =  slagLevelMinCm - 2 * tolCm;
    inputsTT.ConcThickness(INVALID_SOUNDING_INDEX_1:end) = concLevelMinCm - 2 * tolCm;
    % invalid sounding 2: all above max
    inputsTT.BuildUpThickness(INVALID_SOUNDING_INDEX_2:end) = matteLevelMaxCm/2 + 2 * tolCm;
    inputsTT.MatteThickness(INVALID_SOUNDING_INDEX_2:end) = matteLevelMaxCm/2;
    inputsTT.SlagThickness(INVALID_SOUNDING_INDEX_2:end) =  slagLevelMaxCm + 2 * tolCm;
    inputsTT.ConcThickness(INVALID_SOUNDING_INDEX_2:end) = concLevelMaxCm + 2 * tolCm;

    % valid sounding 1: all just above min
    inputsTT.BuildUpThickness(VALID_SOUNDING_INDEX_1:end) = matteLevelMinCm/2 + 2 * tolCm;
    inputsTT.MatteThickness(VALID_SOUNDING_INDEX_1:end) = matteLevelMinCm/2;
    inputsTT.SlagThickness(VALID_SOUNDING_INDEX_1:end) =  slagLevelMinCm + 2 * tolCm;
    inputsTT.ConcThickness(VALID_SOUNDING_INDEX_1:end) = concLevelMinCm + 2 * tolCm;
    % valid sounding 2: all just below max
    inputsTT.BuildUpThickness(VALID_SOUNDING_INDEX_2:end) = matteLevelMaxCm/2 - 2 * tolCm;
    inputsTT.MatteThickness(VALID_SOUNDING_INDEX_2:end) = matteLevelMaxCm/2;
    inputsTT.SlagThickness(VALID_SOUNDING_INDEX_2:end) =  slagLevelMaxCm - 2 * tolCm;
    inputsTT.ConcThickness(VALID_SOUNDING_INDEX_2:end) = concLevelMaxCm - 2 * tolCm;

    % mixed sounding 1: valid matte, invalid slag, invalid conc
    matteLevelMix1 = (matteLevelMinCm + matteLevelMaxCm)/2; % valid since between min and max
    inputsTT.BuildUpThickness(MIXED_SOUNDING_INDEX_1:end) = matteLevelMix1/2;
    inputsTT.MatteThickness(MIXED_SOUNDING_INDEX_1:end) = matteLevelMix1/2;
    inputsTT.SlagThickness(MIXED_SOUNDING_INDEX_1:end) =  slagLevelMinCm - 10; % invalid
    inputsTT.ConcThickness(MIXED_SOUNDING_INDEX_1:end) = concLevelMaxCm + 10; % invalid
    % mixed sounding 1: no matte sounding, invalid slag, valid conc
    concLevelMix2 = (concLevelMinCm + concLevelMaxCm)/2;
    inputsTT.SlagThickness(MIXED_SOUNDING_INDEX_2:end) = slagLevelMaxCm + 10;
    inputsTT.ConcThickness(MIXED_SOUNDING_INDEX_2:end) = concLevelMix2;

    % actual outputs
    [validMatteSoundingsCm, isValidationMatteSounding, validSlagSoundingsCm, isValidationSlagSounding, validConcSoundingsCm, isValidationConcSounding] = extractValidationSoundings(inputsTT, ...
        tolCm=tolCm, matteLevelMaxCm=matteLevelMaxCm, matteLevelMinCm=matteLevelMinCm, slagLevelMaxCm=slagLevelMaxCm, slagLevelMinCm=slagLevelMinCm, concLevelMaxCm=concLevelMaxCm, concLevelMinCm=concLevelMinCm);

    % expected outputs
    expectedMatteSoundingsCm = [matteLevelMinCm + 2 * tolCm; matteLevelMaxCm - 2 * tolCm; matteLevelMix1];
    expectedSlagSoundingsCm = [slagLevelMinCm + 2 * tolCm; slagLevelMaxCm - 2 * tolCm];
    expectedConcSoundingsCm = [concLevelMinCm + 2 * tolCm; concLevelMaxCm - 2 * tolCm; concLevelMix2];

    verifyLessThan(testCase, abs(validMatteSoundingsCm - expectedMatteSoundingsCm), tolCm * ones(size(expectedMatteSoundingsCm)));
    verifyEqual(testCase, sum(isValidationMatteSounding), numel(expectedMatteSoundingsCm));    
    verifyLessThan(testCase, abs(validSlagSoundingsCm - expectedSlagSoundingsCm), tolCm * ones(size(expectedSlagSoundingsCm)));
    verifyEqual(testCase, sum(isValidationSlagSounding), numel(expectedSlagSoundingsCm));   
    verifyLessThan(testCase, abs(validConcSoundingsCm - expectedConcSoundingsCm), tolCm * ones(size(expectedConcSoundingsCm)));
    verifyEqual(testCase, sum(isValidationConcSounding), numel(expectedConcSoundingsCm));
end

