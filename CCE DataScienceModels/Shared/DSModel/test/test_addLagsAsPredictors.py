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
def addLagsAsPredictorsData():
    return 'addLagsAsPredictors'

def test_addLagsAsPredictorsAllColumns(addLagsAsPredictorsData):
    #Test Add Lags as Predictors without specifying columns

    fileName = os.path.join(path, 'test', 'data', 'addLagsAsPredictors.xlsx')
    print(fileName)
    testData = pd.read_excel(fileName, sheet_name=addLagsAsPredictorsData, index_col=0)

    predictorTags = testData.columns

    fullDF, predictorTagsSums = Data._addLagsAsPredictors(
                testData, predictorTags, 5)

    expectedFilename = os.path.join(path, 'test', 'data', 'expectedAddLagsAsPredictorsNew.xlsx')

    expectedTestData = pd.read_excel(expectedFilename, sheet_name="allColumnsAllLags", index_col=0)

    expectedColumnNames = expectedTestData.columns
    actualColumnNames = fullDF.columns

    actualFilename = os.path.join(path, 'test', 'data', 'actual', 'allColumnsAllLags.xlsx')
    fullDF.to_excel(actualFilename, index=True)

    assert np.array_equal(expectedTestData.to_numpy(), fullDF.to_numpy(), equal_nan = True)
    assert actualColumnNames.tolist() == expectedColumnNames.tolist()

def test_addLagsAsPredictorsSingleColumns(addLagsAsPredictorsData):
    #Test Add Lags as Predictors specifying a single column

    fileName = os.path.join(path, 'test', 'data', 'addLagsAsPredictors.xlsx')
    
    testData = pd.read_excel(fileName, sheet_name=addLagsAsPredictorsData, index_col=0)

    addShiftsToPredictors = {'add': True, 'nLags': 5, 'on': ['Column 1']}

    fullDF, predictorTagsSums = Data._addLagsAsPredictors(
                testData, addShiftsToPredictors['on'], addShiftsToPredictors['nLags'])

    expectedFilename = os.path.join(path, 'test', 'data', 'expectedAddLagsAsPredictorsNew.xlsx')

    expectedTestData = pd.read_excel(expectedFilename, sheet_name="singleColumnAllLags", index_col=0)

    expectedColumnNames = expectedTestData.columns
    actualColumnNames = fullDF.columns

    actualFilename = os.path.join(path, 'test', 'data', 'actual', 'singleColumnAllLags.xlsx')
    fullDF.to_excel(actualFilename, index=True)

    assert np.array_equal(expectedTestData.to_numpy(), fullDF.to_numpy(), equal_nan = True)
    assert actualColumnNames.tolist() == expectedColumnNames.tolist()

def test_addLagsAsPredictorsTwoColumnsThreeLags(addLagsAsPredictorsData):
    #Test Add Lags as Predictors specifying two columns
    fileName = os.path.join(path, 'test', 'data', 'addLagsAsPredictors.xlsx')
    
    testData = pd.read_excel(fileName, sheet_name=addLagsAsPredictorsData, index_col=0)

    addShiftsToPredictors = {'add': True, 'nLags': 3, 'on': ['Column 1', 'Column 2']}

    fullDF, predictorTagsSums = Data._addLagsAsPredictors(
                testData, addShiftsToPredictors['on'], addShiftsToPredictors['nLags'])

    expectedFilename = os.path.join(path, 'test', 'data', 'expectedAddLagsAsPredictorsNew.xlsx')

    expectedTestData = pd.read_excel(expectedFilename, sheet_name="twoColumnsThreeLags", index_col=0)

    expectedColumnNames = expectedTestData.columns
    actualColumnNames = fullDF.columns

    actualFilename = os.path.join(path, 'test', 'data', 'actual', 'twoColumnsThreeLags.xlsx')
    fullDF.to_excel(actualFilename, index=True)

    assert np.array_equal(expectedTestData.to_numpy(), fullDF.to_numpy(), equal_nan = True)
    assert actualColumnNames.tolist() == expectedColumnNames.tolist()

def test_addLagsAsPredictorsThreeLags(addLagsAsPredictorsData):
    #Test Add Lags as Predictors specifying all columns with 3 lags
    fileName = os.path.join(path, 'test', 'data', 'addLagsAsPredictors.xlsx')
    
    testData = pd.read_excel(fileName, sheet_name=addLagsAsPredictorsData, index_col=0)

    predictorTags = testData.columns

    fullDF, _ = Data._addLagsAsPredictors(
                testData, predictorTags, 3)

    expectedFilename = os.path.join(path, 'test', 'data', 'expectedAddLagsAsPredictorsNew.xlsx')

    expectedTestData = pd.read_excel(expectedFilename, sheet_name="allColumnsThreeLags", index_col=0)

    expectedColumnNames = expectedTestData.columns
    actualColumnNames = fullDF.columns

    actualFilename = os.path.join(path, 'test', 'data', 'actual', 'allColumnsThreeLags.xlsx')
    fullDF.to_excel(actualFilename, index=True)


    assert np.array_equal(expectedTestData.to_numpy(), fullDF.to_numpy(), equal_nan = True)
    assert actualColumnNames.tolist() == expectedColumnNames.tolist()