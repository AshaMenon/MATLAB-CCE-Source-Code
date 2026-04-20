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

@pytest.fixture
def addRollingMeanDataSheet():
    return 'addRollingMeanPredictors'


def test_addRollingMeanPredictorsAllColumns(addRollingMeanDataSheet):
    #Test 5 rolling mean on all columns
    fileName = os.path.join(path, 'test', 'data', 'addRollingMeanPredictors.xlsx')
    
    testData = pd.read_excel(fileName, sheet_name=addRollingMeanDataSheet, index_col=0)

    predictorTags = testData.columns

    fullDF, predictorTagsSums = Data._addRollingMeanPredictors(
                testData, predictorTags, 5)

    expectedFilename = os.path.join(path, 'test', 'data', 'expectedAddRollingMeanPredictors.xlsx')

    expectedTestData = pd.read_excel(expectedFilename, sheet_name="allColumnsRollingMean", index_col=0)

    expectedColumnNames = expectedTestData.columns
    actualColumnNames = fullDF.columns

    actualFilename = os.path.join(path, 'test', 'data', 'actual', 'allColumnRollingMean.xlsx')
    fullDF.to_excel(actualFilename, index=True)

    assert np.array_equal(expectedTestData.to_numpy(), fullDF.to_numpy(), equal_nan = True)
    assert actualColumnNames.tolist() == expectedColumnNames.tolist()

def test_addRollingMeanPredictorsOneColumn(addRollingMeanDataSheet):

    fileName = os.path.join(path, 'test', 'data', 'addRollingMeanPredictors.xlsx')
    
    testData = pd.read_excel(fileName, sheet_name=addRollingMeanDataSheet, index_col=0)

    addRollingSumPredictors = {'add': True, 'window': 5, 'on' : ['Column 1']}

    fullDF, predictorTagsSums = Data._addRollingMeanPredictors(
                testData, addRollingSumPredictors['on'], 5)

    expectedFilename = os.path.join(path, 'test', 'data', 'expectedAddRollingMeanPredictors.xlsx')

    expectedTestData = pd.read_excel(expectedFilename, sheet_name="oneColumnRollingMean", index_col=0)

    expectedColumnNames = expectedTestData.columns
    actualColumnNames = fullDF.columns

    actualFilename = os.path.join(path, 'test', 'data', 'actual', 'oneColumnRollingMean.xlsx')
    fullDF.to_excel(actualFilename, index=True)

    assert np.array_equal(expectedTestData.to_numpy(), fullDF.to_numpy(), equal_nan = True)
    assert actualColumnNames.tolist() == expectedColumnNames.tolist()

def test_addRollingMeanPredictorsTwoColumn(addRollingMeanDataSheet):

    fileName = os.path.join(path, 'test', 'data', 'addRollingMeanPredictors.xlsx')
    
    testData = pd.read_excel(fileName, sheet_name=addRollingMeanDataSheet, index_col=0)

    addRollingSumPredictors = {'add': True, 'window': 5, 'on' : ['Column 1', 'Column 2']}

    fullDF, _ = Data._addRollingMeanPredictors(
                testData, addRollingSumPredictors['on'], 5)

    expectedFilename = os.path.join(path, 'test', 'data', 'expectedAddRollingMeanPredictors.xlsx')

    expectedTestData = pd.read_excel(expectedFilename, sheet_name="twoColumnRollingMean", index_col=0)

    expectedColumnNames = expectedTestData.columns
    actualColumnNames = fullDF.columns

    actualFilename = os.path.join(path, 'test', 'data', 'actual', 'twoColumnRollingMean.xlsx')
    fullDF.to_excel(actualFilename, index=True)

    assert np.array_equal(expectedTestData.to_numpy(), fullDF.to_numpy(), equal_nan = True)
    assert actualColumnNames.tolist() == expectedColumnNames.tolist()