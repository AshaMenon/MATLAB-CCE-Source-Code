import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import src.NiSlagModellingHelpers as helpNiSlag
from prettytable import PrettyTable
from scipy.stats import kurtosis, skew

#%% Generate Basicity vs change in silica curves

def getSilica(basicityTarget, deadBand):
    
    '''
    -   the basicity regression model outputs different results depending on which part
        of the silica curve you within range (below/above the basicity target).
        Shown here as low range vs high range
    -   for deployment
    '''
    
    lowRangeBasicity = np.linspace(1.25, basicityTarget, 7)
    highRangeBasicity = np.linspace(basicityTarget, 2.25, 7)
    
    # Low range
    baseData = np.array([1.2, 1.5, 1.7])
    basicity = baseData + basicityTarget - deadBand/2 - np.max(baseData)
    silica = np.array([-60, -15, 0])
    lowRangeCoeffs = np.polyfit(basicity, silica, 2)
    f = lambda x, coeffs : coeffs[0] * x**2 + coeffs[1] * x + coeffs[2]
    lowRangeSilica = f(lowRangeBasicity, lowRangeCoeffs)

    # High range
    baseData = np.array([1.7, 1.9, 2.2])
    basicity = baseData + basicityTarget - deadBand/2 - np.min(baseData)
    silica = np.array([0, 15, 60])
    highRangeCoeffs = np.polyfit(basicity, silica, 2)
    highRangeSilica = f(highRangeBasicity, highRangeCoeffs)
    
    
    lowRange = {'basicity' : lowRangeBasicity,
                'silica' : lowRangeSilica,
                'coeffs' : lowRangeCoeffs,
        }
    
    highRange = {'basicity' : highRangeBasicity,
                'silica' : highRangeSilica,
                'coeffs' : highRangeCoeffs,
        }
    
    return lowRange, highRange, f

#%% Visualise Basicity vs change in silica curve

def plotSpO2Curve(lowRangeBasicity, lowRangeSilica, highRangeBasicity, highRangeSilica):
    
    '''
    -   plots curve of change in Silica vs Basicity. 
    -   Shows both high and low range curves
    '''
    
    plt.figure()
    plt.plot(lowRangeBasicity,lowRangeSilica,'ro-',label='Low range')
    plt.plot(highRangeBasicity,highRangeSilica,'bo-',label='High range')
    plt.axhline(y=0, color='black', linestyle='-')
    plt.xlabel('Basicity')
    plt.ylabel('Silica change, UNITS')
    plt.xlim((0,12))
    plt.ylim((-15,15))
    plt.legend()
    plt.grid()

#%% Control sim - convert basicity model predicitions into Silica change for operators

def applySilicaModel(predBasicity, basicityTarget, deadBand):
    
    '''
    -   predBasicity is a Dataframe with the results from running one of the basicity models
        must contain the columns 'yhat'. The output Silica change is written to the same DF
    '''

    # Acquire predictedBasicity
    predictedBasicity = pd.DataFrame(predBasicity["yHat"])
    
    # Calculate the low range and high range coefficients
    [lowRange, highRange, f] = getSilica(basicityTarget, deadBand)
    
    # # Calculate change in silica compared to predicted basicity value
    # f = lambda x, coeffs : coeffs[0] * x**2 + coeffs[1] * x + coeffs[2]
    predictedBasicity["changeSilica"] = ""
    
    for i in range(0,len(predictedBasicity)):
        if predictedBasicity["yHat"][i] < basicityTarget:
            predictedBasicity["changeSilica"][i] = f(predictedBasicity["yHat"][i], lowRange['coeffs'])
        else:
            predictedBasicity["changeSilica"][i] = f(predictedBasicity["yHat"][i], highRange['coeffs'])
    
    return predictedBasicity


