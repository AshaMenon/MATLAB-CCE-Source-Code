import pytest
import pandas as pd
import numpy as np
import os
import sys
from pathlib import Path

# TODO: Quick workaround, to add in set up script
path = str(Path(os.path.dirname(os.path.abspath(__file__))).parent)
print(path)
sys.path.append(path)
from Data import Data

@pytest.fixture()
def addRollingSumDataSheet():
    return 'addRollingSumPredictors'
def test_addRollingSumPredictorsAllColumns(addRollingSumDataSheet):
    fileName = os.path.join(path, 'test', 'data', 'addRollingSumPredictors.xlsx')
    
    testData = pd.read_excel(fileName, sheet_name=addRollingSumDataSheet, index_col=0)

    predictorTags = testData.columns

    fullDF, predictorTagsSums = Data._addRollingSumPredictors(
                testData,predictorTags, 5)

    expectedFilename = os.path.join(path, 'test', 'data', 'expectedAddRollingSumPredictors.xlsx')

    expectedTestData = pd.read_excel(expectedFilename, sheet_name="allColumnsRollingSum", index_col=0)

    expectedColumnNames = expectedTestData.columns
    actualColumnNames = fullDF.columns

    actualFilename = os.path.join(path, 'test', 'data', 'actual', 'allColumnsRollingSum.xlsx')
    fullDF.to_excel(actualFilename, index=True)

    assert np.array_equal(expectedTestData.to_numpy(), fullDF.to_numpy(), equal_nan = True)
    assert (actualColumnNames == expectedColumnNames).all()

def test_addRollingSumPredictorsOneColumn(addRollingSumDataSheet):

    fileName = os.path.join(path, 'test', 'data', 'addRollingSumPredictors.xlsx')

    testData = pd.read_excel(fileName, sheet_name=addRollingSumDataSheet, index_col=0)

    addRollingSumPredictors = {'add': True, 'window': 5, 'on' : ['Column 1']}

    fullDF, predictorTagsSums = Data._addRollingSumPredictors(
                testData,addRollingSumPredictors['on'], addRollingSumPredictors['window'])

    expectedFilename = os.path.join(path, 'test', 'data', 'expectedAddRollingSumPredictors.xlsx')

    expectedTestData = pd.read_excel(expectedFilename, sheet_name="oneColumnRollingSum", index_col=0)
        
    expectedColumnNames = expectedTestData.columns
    actualColumnNames = fullDF.columns

    actualFilename = os.path.join(path, 'test', 'data', 'actual', 'oneColumnRollingSum.xlsx')
    fullDF.to_excel(actualFilename, index=True)


    assert np.array_equal(expectedTestData.to_numpy(), fullDF.to_numpy(), equal_nan = True)
    assert (actualColumnNames == expectedColumnNames).all()

def test_addRollingSumPredictorsTwoColumn(addRollingSumDataSheet):

    fileName = os.path.join(path, 'test', 'data', 'addRollingSumPredictors.xlsx')
    
    testData = pd.read_excel(fileName, sheet_name=addRollingSumDataSheet, index_col=0)

    addRollingSumPredictors = {'add': True, 'window': 5, 'on' : ['Column 1', 'Column 2']}

    fullDF, predictorTagsSums = Data._addRollingSumPredictors(
                testData,addRollingSumPredictors['on'], addRollingSumPredictors['window'])

    expectedFilename = os.path.join(path, 'test', 'data', 'expectedAddRollingSumPredictors.xlsx')

    expectedTestData = pd.read_excel(expectedFilename, sheet_name="twoColumnRollingSum", index_col=0)
        
    expectedColumnNames = expectedTestData.columns
    actualColumnNames = fullDF.columns

    actualFilename = os.path.join(path, 'test', 'data', 'actual', 'twoColumnRollingSum.xlsx')
    fullDF.to_excel(actualFilename, index=True)

    assert np.array_equal(expectedTestData.to_numpy(), fullDF.to_numpy(), equal_nan = True)
    assert (actualColumnNames == expectedColumnNames).all()