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
def addMeasureIndicatorsAsPredictors():
    return 'addMeasureIndicatorsAsPredictor'


def test_addMeasureIndicatorsAsPredictorsAll(addMeasureIndicatorsAsPredictors):
    fileName = os.path.join(path, 'test', 'data', 'addMeasureIndicatorsAsPredicators.xlsx')

    testData = pd.read_excel(fileName, sheet_name=addMeasureIndicatorsAsPredictors, index_col=0)

    predictorTags = testData.columns.tolist()

    processedData, measureIndicators = \
            Data._addMeasureIndicatorsAsPredictors(testData, predictorTags, predictorTags)

    expectedFilename = os.path.join(path, 'test', 'data', 'expectedAddMeasureIndicatorAsPredictors.xlsx')

    expectedTestData = pd.read_excel(expectedFilename, sheet_name='allColumnsAsPredictors', index_col=0)

    expectedColumnNames = expectedTestData.columns
    actualColumnNames = processedData.columns

    actualFilename = os.path.join(path, 'test', 'data', 'actual', 'allColumnsAsPredictors.xlsx')
    processedData.to_excel(actualFilename, index=True)


    assert np.array_equal(expectedTestData.to_numpy(), processedData.to_numpy(), equal_nan = True)
    assert actualColumnNames.to_list() == expectedColumnNames.to_list()


def test_addMeasureIndicatorsAsPredictorsOneColume(addMeasureIndicatorsAsPredictors):
    
    
    fileName = os.path.join(path, 'test', 'data', 'addMeasureIndicatorsAsPredicators.xlsx')

    testData = pd.read_excel(fileName, sheet_name=addMeasureIndicatorsAsPredictors, index_col=0)

    addMeasureIndicatorsAsPredictors= {'add': False, 'on': ['Column 1']}

    predictorTags = testData.columns

    processedData, measureIndicators = \
            Data._addMeasureIndicatorsAsPredictors(testData, predictorTags, addMeasureIndicatorsAsPredictors['on'] )

    expectedFilename = os.path.join(path, 'test', 'data', 'expectedAddMeasureIndicatorAsPredictors.xlsx')

    expectedTestData = pd.read_excel(expectedFilename, sheet_name='oneColumnAsPredictor', index_col=0)
    
    expectedColumnNames = expectedTestData.columns
    actualColumnNames = processedData.columns

    actualFilename = os.path.join(path, 'test', 'data', 'actual', 'oneColumnAsPredictor.xlsx')
    processedData.to_excel(actualFilename, index=True)

    assert np.array_equal(expectedTestData.to_numpy(), processedData.to_numpy(), equal_nan = True)
    assert actualColumnNames.to_list() == expectedColumnNames.to_list()
