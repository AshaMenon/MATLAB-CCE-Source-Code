function testArr = calcMatteFallFractionTest
    testArr = functiontests(localfunctions);
end

function setupOnce(testCase)
    testCase.TestData.tolFract = 0.0001;
end

function testRealWorldExample(testCase)
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

    [matteFallFraction, labileSulphurFraction] = calcMatteFallFraction(m_MgO, m_Al2O3, ... 
        m_SiO2, m_S, m_CaO, m_Cr2O3, m_Fe, m_Co, m_Ni, m_Cu );
    
    expectedMatteFallFraction = 0.1205;
    expectedLabileSulphurFraction = 0.0070;
    verifyLessThan(testCase, abs(matteFallFraction - expectedMatteFallFraction), testCase.TestData.tolFract)
    verifyLessThan(testCase, abs(labileSulphurFraction - expectedLabileSulphurFraction), testCase.TestData.tolFract)
end
