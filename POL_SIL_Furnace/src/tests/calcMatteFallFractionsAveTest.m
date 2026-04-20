function testArr = calcMatteFallFractionsAveTest
    testArr = functiontests(localfunctions);
end

function setupOnce(testCase)
    testCase.TestData.executionPeriodMins = 30;
    testCase.TestData.dataWindowMins = 12 * 60;
    testCase.TestData.tolFract = 0.0001;

    startDatetime = datetime(2024, 8, 1);
    endDatetime = datetime(2024, 8, 8);

    testCase.TestData.defaultInputs = table;
    testCase.TestData.defaultInputs.Timestamp =  (startDatetime:minutes(1):endDatetime)';

    testCase.TestData.defaultInputs.FeedMgO =  zeros(height(testCase.TestData.defaultInputs), 1);
    testCase.TestData.defaultInputs.FeedAl2O3 =  zeros(height(testCase.TestData.defaultInputs), 1);
    testCase.TestData.defaultInputs.FeedSiO2 =  zeros(height(testCase.TestData.defaultInputs), 1);
    testCase.TestData.defaultInputs.FeedS =  zeros(height(testCase.TestData.defaultInputs), 1);
    testCase.TestData.defaultInputs.FeedCaO =  zeros(height(testCase.TestData.defaultInputs), 1);
    testCase.TestData.defaultInputs.FeedCr2O3 =  zeros(height(testCase.TestData.defaultInputs), 1);
    testCase.TestData.defaultInputs.FeedFe =  zeros(height(testCase.TestData.defaultInputs), 1);
    testCase.TestData.defaultInputs.FeedCo =  zeros(height(testCase.TestData.defaultInputs), 1);
    testCase.TestData.defaultInputs.FeedNi =  zeros(height(testCase.TestData.defaultInputs), 1);
    testCase.TestData.defaultInputs.FeedCu =  zeros(height(testCase.TestData.defaultInputs), 1);

    testCase.TestData.nSamples = 3;
    testCase.TestData.delayHrs = 24;

end

function testOneSample(testCase)
    inputsT = testCase.TestData.defaultInputs;
    
    m_MgO = 19.5725;
    m_Al2O3 = 3.98;
    m_SiO2 = 44.31;
    m_S = 4.5425;
    m_CaO = 2.915;
    m_Cr2O3 = 1.3625;
    m_Fe = 11;
    m_Co = 0.0625;
    m_Ni = 2.19;
    m_Cu = 1.26;

    sampleIndex = 100;
    inputsT = addSample(inputsT, sampleIndex, m_MgO, m_Al2O3, m_SiO2, m_S, m_CaO, m_Cr2O3, m_Fe, m_Co, m_Ni, m_Cu);
    

    [matteFallFractions, sulphurFractions] = calcMatteFallFractionsAve(inputsT, testCase.TestData.nSamples, testCase.TestData.delayHrs);
    
    expectedMatteFallFraction = 0.1205;
    expectedMatteFallFractions = expectedMatteFallFraction * ones(height(inputsT), 1);
    expectedSulphurFraction = 0.0070;
    expectedSulphurFractions = expectedSulphurFraction * ones(height(inputsT), 1);
    
    errorMatteFall = abs(matteFallFractions - expectedMatteFallFractions);
    errorSulphur = abs(sulphurFractions - expectedSulphurFractions);
    verifyLessThan(testCase, errorMatteFall, testCase.TestData.tolFract);
    verifyLessThan(testCase, errorSulphur, testCase.TestData.tolFract);
    verifyWarning(testCase, @() calcMatteFallFractionsAve(inputsT, testCase.TestData.nSamples, testCase.TestData.delayHrs), "MatteFallFractionsAve:fewSamples");
end

function testOneValidSample(testCase)
    inputsT = testCase.TestData.defaultInputs;
    
    m_MgO_1 = 19.5725;
    m_Al2O3_1 = 3.98;
    m_SiO2_1 = 44.31;
    m_S_1 = 4.5425;
    m_CaO_1 = 2.915;
    m_Cr2O3_1 = 1.3625;
    m_Fe_1 = 11;
    m_Co_1 = 0.0625;
    m_Ni_1 = 2.19;
    m_Cu_1 = 1.26;
    sampleIndex1 = 100;

    m_MgO_2 = 20.1133804321289;
    m_Al2O3_2 = 4.15115022659302;
    m_SiO2_2 = 44.5078201293945;
    m_S_2 = 2.97656989097595; % INVALID SAMPLE
    m_CaO_2 = 2.86425995826721;
    m_Cr2O3_2 = 2.00044989585876;
    m_Fe_2 = 10.6185998916626;
    m_Co_2 = 0.0467200018465519;
    m_Ni_2 = 1.52860999107361;
    m_Cu_2 = 0.954209983348846;
    sampleIndex2 = 200;

    inputsT = addSample(inputsT, sampleIndex1, m_MgO_1, m_Al2O3_1, m_SiO2_1, m_S_1, m_CaO_1, m_Cr2O3_1, m_Fe_1, m_Co_1, m_Ni_1, m_Cu_1);
    inputsT = addSample(inputsT, sampleIndex2, m_MgO_2, m_Al2O3_2, m_SiO2_2, m_S_2, m_CaO_2, m_Cr2O3_2, m_Fe_2, m_Co_2, m_Ni_2, m_Cu_2);

   [matteFallFractions, sulphurFractions] = calcMatteFallFractionsAve(inputsT, testCase.TestData.nSamples, testCase.TestData.delayHrs);
    
    expectedMatteFallFraction = 0.1205;
    expectedMatteFallFractions = expectedMatteFallFraction * ones(height(inputsT), 1);
    expectedSulphurFraction = 0.0070;
    expectedSulphurFractions = expectedSulphurFraction * ones(height(inputsT), 1);
    
    errorMatteFall = abs(matteFallFractions - expectedMatteFallFractions);
    errorSulphur = abs(sulphurFractions - expectedSulphurFractions);
    verifyLessThan(testCase, errorMatteFall, testCase.TestData.tolFract);
    verifyLessThan(testCase, errorSulphur, testCase.TestData.tolFract);
    verifyWarning(testCase, @() calcMatteFallFractionsAve(inputsT, testCase.TestData.nSamples, testCase.TestData.delayHrs), "MatteFallFractionsAve:fewSamples");
end

% TODO: add tests with 3 and 4 samples, including edge cases

function inputsT = addSample(inputsT, sampleIndex, m_MgO, m_Al2O3, m_SiO2, m_S, m_CaO, m_Cr2O3, m_Fe, m_Co, m_Ni, m_Cu)
    inputsT.FeedMgO(sampleIndex:end) = m_MgO;
    inputsT.FeedAl2O3(sampleIndex:end) = m_Al2O3;
    inputsT.FeedSiO2(sampleIndex:end) = m_SiO2;
    inputsT.FeedS(sampleIndex:end) = m_S;
    inputsT.FeedCaO(sampleIndex:end) = m_CaO;
    inputsT.FeedCr2O3(sampleIndex:end) = m_Cr2O3;
    inputsT.FeedFe(sampleIndex:end) = m_Fe;
    inputsT.FeedCo(sampleIndex:end) = m_Co;
    inputsT.FeedNi(sampleIndex:end) = m_Ni;
    inputsT.FeedCu(sampleIndex:end) = m_Cu;
end


