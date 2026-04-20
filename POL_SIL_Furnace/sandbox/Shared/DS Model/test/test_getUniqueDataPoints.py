import pytest
import pandas as pd
import os
import sys
from pathlib import Path

# TODO: Quick workaround, to add in set up script
path = str(Path(os.path.dirname(os.path.abspath(__file__))).parent)
print(path)
sys.path.append(path)
from Data import Data

@pytest.fixture

def getUniqueDataPointsData():
    return 'getUniqueDataPoints'

def test_getUniqueDataPoints(getUniqueDataPointsData):

    # Tests that unique observations are pulled from a duplicated dataframe
    fileName = os.path.join(path, 'test', 'data', 'getUniqueDataPoints.xlsx')
    
    testData = pd.read_excel(fileName, sheet_name=getUniqueDataPointsData, index_col=0)

    testSeries = testData['Column 1']

    uniqueDataSeries, irregularIdx = Data._getUniqueDataPoints(testSeries )
    expectedFilename = os.path.join(path, 'test', 'data', 'expectedGetUniqueDataPoints.xlsx')
    expectedData = pd.read_excel(expectedFilename, sheet_name="getUniqueDataPoints", index_col=0)

    actualFilename = os.path.join(path, 'test', 'data', 'actual', 'getUniqueDataPoints.xlsx')
    uniqueDataSeries.to_excel(actualFilename, index=True)

    assert uniqueDataSeries.tolist() == expectedData['Column 1'].tolist()