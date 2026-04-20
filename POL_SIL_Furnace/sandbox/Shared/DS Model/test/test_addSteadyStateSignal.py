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

@pytest.mark.parametrize("steadyStateSheetName",
                         ["Peaks"])
@pytest.fixture
def addSteadyStateData():
    return 'addSteadyState'

def test_addSteadyStatePeaks(addSteadyStateData):
    # Test that the correct steady state signal has been added
    #  to processed dataframe. This test is based on the expected blows in the Lance air & oxygen control 
    fileName = os.path.join(path, 'test', 'data', 'addSteadyState.xlsx')

    testData = pd.read_excel(fileName, sheet_name=addSteadyStateData, index_col=0)

    offPeriod = 1
    nPeaksOff = 1
    responseTags = 'Response'
    processedDataSet = Data._addSteadyStateSignal(testData,
                                                offPeriod, nPeaksOff, responseTags)

    expectedFilename = os.path.join(path, 'test', 'data', 'expectedAddSteadyState.xlsx')
    expectedSignal = pd.read_excel(expectedFilename, sheet_name='Peaks', index_col=0)

    actualFilename = os.path.join(path, 'test', 'data', 'actual', 'Peaks.xlsx')
    processedDataSet.to_excel(actualFilename, index=True)

    assert processedDataSet.Steadystate.tolist() == expectedSignal['Steadystate'].tolist()

def test_addSteadyStatePeaksOffPeriod(addSteadyStateData):
    # Test that the correct steady state signal has been added
    #  to processed dataframe. This test is based on the time stamp

    fileName = os.path.join(path, 'test', 'data', 'addSteadyState.xlsx')

    testData = pd.read_excel(fileName, sheet_name=addSteadyStateData, index_col=0)

    offPeriod = 1
    nPeaksOff = 1
    responseTags = 'Response'
    processedDataSet = Data._addSteadyStateSignal(testData,
                                                offPeriod, nPeaksOff, responseTags)

    expectedFilename = os.path.join(path, 'test', 'data', 'expectedAddSteadyState.xlsx')
    expectedSignal = pd.read_excel(expectedFilename, sheet_name='Peaks', index_col=0)

    actualFilename = os.path.join(path, 'test', 'data', 'actual', 'PeaksOff.xlsx')
    processedDataSet.to_excel(actualFilename, index=True)

    assert processedDataSet.Steadystate.tolist() == expectedSignal['Steadystate'].tolist()