# -*- coding: utf-8 -*-
"""
Created on Mon Jun 20 06:25:34 2022

@author: verushen.coopoo
"""
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import src.NiSlagModellingHelpers as helpNiSlag
import src.preprocessingFunctions as prep
from prettytable import PrettyTable
from scipy.stats import kurtosis, skew
import src.featureEngineeringHelpers as feh

#%%
def preprocessDataForSpO2Modelling():
        
    responseTags = ['Basicity']
    highFreqPredictorsTags = ["Specific Oxygen Actual PV"]
    lowFrequencyPredictorTags = ['Matte temperatures','Ni Slag','Fe Matte', 
                                 'S Slag', 'Corrected Ni Slag',
                                 'Specific Oxygen Operator SP (SP1)',
                                 'Specific Oxygen Calculated SP (SP2)']
    referenceTags =     ["Specific Silica Actual PV", "Matte feed PV(filtered)",
                        "Lance oxygen flow rate PV", "Lance air flow rate PV",
                        "Lance feed PV", "Silica PV", "Lump Coal PV",
                        "Matte transfer air flow", "Fuel coal feed rate PV",
                        'Converter mode', 'Lance air & oxygen control',
                        'SumOfSpecies']
    predictorTags = lowFrequencyPredictorTags + highFreqPredictorsTags + referenceTags
    
    measDF_original = prep.readAndFormatData('Chemistry')
        
    measDF_original_1min = prep.preprocessingAndFeatureEngineering(measDF_original,
                                           removeTransientData = True,
                                           smoothBasicityResponse = True,
                                           addRollingSumPredictors = {'add': False, 'window': 30}, 
                                           addRollingMeanPredictors = {'add': False, 'window': 5},
                                           addMeasureIndicatorsAsPredictors = {'add': True, 'on': [
                                               'Fe Matte', 
                                               'Specific Oxygen Operator SP (SP1)',
                                               'Ni Slag',
                                               'Corrected Ni Slag',
                                               'S Slag']}, 
                                           addShiftsToPredictors = {'add': False, 'nLags':3},
                                           addResponsesAsPredictors = {'add': False, 'nLags': 1},
                                           resampleTime = '1min',
                                           resampleMethod = 'zero',
                                           predictorTags = predictorTags,
                                           responseTags = responseTags,
                                           highFrequencyPredictorTags = highFreqPredictorsTags,
                                           lowFrequencyPredictorTags = lowFrequencyPredictorTags,
                                           referenceTags = referenceTags) 
    
    measDF = measDF_original_1min[0]
    
    # Get unique points of Corr Ni and Fe Matte
    measDF = measDF_original_1min[0]
    _, irregularIdx_CorrNi = feh.getUniqueDataPoints(measDF['Corrected Ni Slag'])
    _, irregularIdx_FeMatte = feh.getUniqueDataPoints(measDF['Fe Matte'])
    measDF = measDF.loc[irregularIdx_CorrNi]
    FeMatte = measDF_original_1min[0].loc[irregularIdx_FeMatte]['Fe Matte']
    
    #measDF = measDF[measDF['S Slag'] < 0.8]
    
    # Remove double sampling
    validIdx = np.empty([len(measDF),], dtype=object)
    
    for i in range(1, len(measDF) - 1, 2):
        a = measDF.index.values[i-1]
        b = measDF.index.values[i]
        c = measDF.index.values[i+1]
        x1 = b - a
        x2 = c - b
        
        # Look at the ratio between distances of adjacent points
        if ((x1/x2)/(x2/x1)) >= 10:
            validIdx[i] = b
    
    validIdx = pd.to_datetime(validIdx)
    validIdx = validIdx[~np.isnat(validIdx)]
    
    measDF = measDF.loc[validIdx]
    groundTruthCorrNiSlag = measDF['Corrected Ni Slag']
    return measDF, groundTruthCorrNiSlag, FeMatte

#%%
def getSpO2(NiSlagTarget, deadBand):
    
    '''
    -   the SpO2 model outputs different results depending on which part
        of the SpO2 curve you are on (below/above the Ni Slag target).
        Shown here as low range vs high range
    -   for deployment
    '''
    
    lowRangeCorrNi = np.linspace(0, NiSlagTarget, 10)
    highRangeCorrNi = np.linspace(NiSlagTarget, 10, 10)
    
    # Low range
    baseData = np.array([0, 2, 3])
    Ni = baseData + NiSlagTarget - deadBand/2 - np.max(baseData)
    oxy = np.array([14, 6, 0])
    lowRangeCoeffs = np.polyfit(Ni, oxy, 2)
    f = lambda x, coeffs : coeffs[0] * x**2 + coeffs[1] * x + coeffs[2]
    lowRangeOxy = f(lowRangeCorrNi, lowRangeCoeffs)

    # High range
    baseData = np.array([4, 5.53, 10])
    Ni = baseData + NiSlagTarget - deadBand/2 - np.min(baseData)
    oxy = np.array([0, -4.7, -12])
    highRangeCoeffs = np.polyfit(Ni, oxy, 2)
    highRangeOxy = f(highRangeCorrNi, highRangeCoeffs)
    
    
    lowRange = {'corrNi' : lowRangeCorrNi,
                'oxy' : lowRangeOxy,
                'coeffs' : lowRangeCoeffs,
        }
    
    highRange = {'corrNi' : highRangeCorrNi,
                'oxy' : highRangeOxy,
                'coeffs' : highRangeCoeffs,
        }
    
    return lowRange, highRange, f

#%%
def plotSpO2Curve(lowRangeCorrNi, lowRangeOxy, highRangeCorrNi, highRangeOxy):
    
    '''
    -   plots curve of change in SpO2 vs corrected Ni. 
    -   Shows both high and low range curves
    '''
    
    plt.figure()
    plt.plot(lowRangeCorrNi,lowRangeOxy,'ro-',label='Low range')
    plt.plot(highRangeCorrNi,highRangeOxy,'bo-',label='High range')
    plt.axhline(y=0, color='black', linestyle='-')
    plt.xlabel('% Corrected Ni')
    plt.ylabel('SpO2 change, Nm3/t')
    plt.xlim((0,12))
    plt.ylim((-15,15))
    plt.legend()
    plt.grid()
#%%
def plot2DValidationWithPolynomialModel(thermoDF, basicityVals, tempVals, 
                                      thermoMdl, setFeMatteTarget, newArrayLength):
    
    # Temperature
    plt.figure()

    for i in range(0,len(tempVals)):
        idx = np.isclose(thermoDF['Basicity'],basicityVals[1]) & \
        np.isclose(thermoDF['Matte temperatures'],tempVals[i]) & \
        np.isclose(thermoDF['PSO2'],0.15)
        plt.scatter(thermoDF['Fe Matte'].loc[idx].values, thermoDF['Ni Slag'].loc[idx].values, 
                    marker="s", label='Polynom. model: T = {}'.format(round(tempVals[i],3)))
        
        theoreticalNiSlagPredictions, newDF = helpNiSlag.takeNewValuesAndPredictNi(
            tempVals[i], basicityVals[1], thermoMdl, setFeMatteTarget, newArrayLength)
        plt.plot(newDF['Fe Matte'], theoreticalNiSlagPredictions, "*-", 
                 label='Poisson model: T = {}'.format(round(tempVals[i],3)))

    plt.legend()
    plt.grid()
    plt.xlabel('% Fe Matte')
    plt.ylabel('% Theoretical Ni Slag')
    plt.title('Theoretical Ni Slag (calculated via Poisson & Polynomial models) for Basicity = 1.75 and PSO2 = 0.15 \n Varying temperature')

    # Basicity
    plt.figure()

    for i in range(0,len(tempVals)):
        idx = np.isclose(thermoDF['Matte temperatures'],tempVals[1]) & \
        np.isclose(thermoDF['Basicity'],basicityVals[i]) & \
        np.isclose(thermoDF['PSO2'],0.15)
        plt.scatter(thermoDF['Fe Matte'].loc[idx].values, thermoDF['Ni Slag'].loc[idx].values, 
                    marker="s", label='Polynom. model: B = {}'.format(round(basicityVals[i],3)))
        
        theoreticalNiSlagPredictions, newDF = helpNiSlag.takeNewValuesAndPredictNi(
            tempVals[1], basicityVals[i], thermoMdl, setFeMatteTarget, newArrayLength)
        plt.plot(newDF['Fe Matte'], theoreticalNiSlagPredictions, "*-", 
                 label='Poisson model: B = {}'.format(round(basicityVals[i],3)))

    plt.legend()
    plt.grid()
    plt.xlabel('% Fe Matte')
    plt.ylabel('% Theoretical Ni Slag')
    plt.title('Theoretical Ni Slag (calculated via Poisson & Polynomial models) for Temperature = 1250 and PSO2 = 0.15 \n Varying basicity')
#%%
def applySpO2Model(temperature, basicity, corrNiSlag, deadBand, thermoMdl):
    
    theoreticalNiSlagPredictions, _ = helpNiSlag.takeNewValuesAndPredictNi(
                                    temperature, 
                                    basicity, 
                                    thermoMdl,
                                    True,
                                    1)

    lowRange, highRange, f = getSpO2(theoreticalNiSlagPredictions, deadBand)
    if corrNiSlag < theoreticalNiSlagPredictions:
        requiredChangeInSpO2 = f(corrNiSlag, lowRange['coeffs'])
    else:
        requiredChangeInSpO2 = f(corrNiSlag, highRange['coeffs'])
      
    return requiredChangeInSpO2

#%%
def applyAndValidateSpO2ModelWithMeasurements(measDF, NiSlagTarget, deadBand, thermoMdl):
    
    '''
    -   measDF must contain the columns 'Corrected Ni Slag', 'Matte temperatures', 
        'Basicity'. The (dynamic) output SpO2 change is written to the same DF
    -   To return data to assist in validation of SpO2 model (what the operator did,
        constant SpO2 curve etc,) set returnValidationData = True
    -   for deployment
    '''

    # Dynamic curve
    corrNiSlag_outliers = measDF['Corrected Ni Slag'].values
    corrNiSlag, idx = helpNiSlag.removeOutliers(corrNiSlag_outliers, 25, False)
    theoreticalNiSlagPredictions, _ = helpNiSlag.takeNewValuesAndPredictNi(
                                    measDF['Matte temperatures'], 
                                    measDF['Basicity'], 
                                    thermoMdl,
                                    True,
                                    len(measDF))

    theoreticalNiSlagPredictions = theoreticalNiSlagPredictions[idx]
    
    
    # Dynamic curve
    measDF['SpO2Change_dynamicCurve'] = np.zeros((len(measDF),1))
    for i in range(0, len(measDF)):
        measDF['SpO2Change_dynamicCurve'][i] = applySpO2Model(measDF['Matte temperatures'][i], 
                                              measDF['Basicity'][i], 
                                              corrNiSlag[i], 
                                              deadBand, 
                                              thermoMdl)
        
    # Constant curve
    lowRange, highRange, f = getSpO2(NiSlagTarget, deadBand)
    measDF['SpO2Change_constCurve'] = np.zeros((len(measDF),1))
    for i in range(0, len(measDF)):

        if corrNiSlag[i] < NiSlagTarget:
            measDF['SpO2Change_constCurve'][i] = f(corrNiSlag[i], lowRange['coeffs'])
        else:
            measDF['SpO2Change_constCurve'][i] = f(corrNiSlag[i], highRange['coeffs'])



    # What did the operator do? - we did this to get rid of the large amount of zeros in the operator data
    # _, irregularIdx_SP1 = feh.getUniqueDataPoints(measDF['Specific Oxygen Operator SP (SP1)'])
    # measDF['WhatDidTheOperatorDo'] = measDF['Specific Oxygen Operator SP (SP1)'].loc[irregularIdx_SP1].diff()
    
    #_, irregularIdx_SP1 = feh.getUniqueDataPoints(measDF['Specific Oxygen Operator SP (SP1)'])
    measDF['WhatDidTheOperatorDo'] = measDF['Specific Oxygen Operator SP (SP1)'].diff()

    # Remove outliers - based on what the operator did
    x = measDF['WhatDidTheOperatorDo'].values
    boundary = 20.0
    idx = (x < boundary) & (x > -boundary)
    measDF['WhatDidTheOperatorDo'] = measDF['WhatDidTheOperatorDo'].loc[idx]

    # Get average time between samples
    times = measDF.index.values
    timeDiffs = np.diff(times)
    timeDiffs = timeDiffs / np.timedelta64(1, 'm')
    avg = sum(timeDiffs) / len(timeDiffs)
    #print(avg)

    # Do some resampling to get (red - blue)/(dynamic curve - what the operator did)
    newindex = measDF['WhatDidTheOperatorDo'].index.union(measDF['SpO2Change_dynamicCurve'].index)
    measDF['WhatDidTheOperatorDo'] = measDF['WhatDidTheOperatorDo'].reindex(newindex)
    measDF['SpO2Change_dynamicCurve'] = measDF['SpO2Change_dynamicCurve'].reindex(newindex)

    operatorVsDynamic = pd.DataFrame().assign(WhatDidTheOperatorDo = measDF['WhatDidTheOperatorDo'],
                              SpO2Change_dynamicCurve = measDF['SpO2Change_dynamicCurve'])

    operatorVsDynamic['WhatDidTheOperatorDo'] = operatorVsDynamic['WhatDidTheOperatorDo'].fillna(0)
    operatorVsDynamic['SpO2Change_dynamicCurve'] = operatorVsDynamic['SpO2Change_dynamicCurve'].fillna(0)
    
    
    shapeTable = PrettyTable(["SpO2 quantity", "Kurtosis", "Skewness"])

    shapeTable.add_row(["Existing constant curve",
                        kurtosis(measDF['SpO2Change_constCurve'].values),
                        skew(measDF['SpO2Change_constCurve'].values)
        ])
    shapeTable.add_row(["New dynamic curves",
                        kurtosis(measDF['SpO2Change_dynamicCurve'].values),
                        skew(measDF['SpO2Change_dynamicCurve'].values)
        ])
    shapeTable.add_row(["What the operator actually did",
                        kurtosis(measDF['WhatDidTheOperatorDo'].dropna().values),
                        skew(measDF['WhatDidTheOperatorDo'].dropna().values)
        ]) 
    #print(shapeTable)
    return measDF, timeDiffs, operatorVsDynamic, shapeTable

#%%
def plotTimeSeriesAndDistributionsForValidation(measDF, operatorVsDynamic, FeMatte, mainTitle):

    '''
    -   plots time series of various quantities
    -   plots distributions (as histograms) of various SpO2 measures
    -   for deployment
    '''
    
    fig = plt.figure()
    plt.suptitle(mainTitle)
    ax1 = plt.subplot2grid((6,2), (0,0))
    ax2 = plt.subplot2grid((6,2), (0,1), rowspan = 2)
    ax3 = plt.subplot2grid((6,2), (1,0))
    ax4 = plt.subplot2grid((6,2), (2,1), rowspan = 2)
    ax5 = plt.subplot2grid((6,2), (2,0))
    ax6 = plt.subplot2grid((6,2), (4,1), rowspan = 2)
    ax7 = plt.subplot2grid((6,2), (3,0))
    ax8 = plt.subplot2grid((6,2), (4,0), rowspan = 2)


    ax1.get_shared_x_axes().join(ax1, ax3)
    ax5.get_shared_x_axes().join(ax5, ax3)
    ax7.get_shared_x_axes().join(ax7, ax5)
    ax8.get_shared_x_axes().join(ax8, ax7)



    ax1.set_xticks([])
    ax1.plot(measDF.index.values, 
             measDF['SpO2Change_constCurve'].values,
             marker='*',
             label='Constant',
             color='green')
    ax1.plot(measDF.index.values, 
             measDF['SpO2Change_dynamicCurve'].values,
             marker='*',
             label='Dynamic',
             color='firebrick')
    ax1.plot(measDF['WhatDidTheOperatorDo'].dropna().index.values, 
              measDF['WhatDidTheOperatorDo'].dropna().values,
              marker='*',
              label='Operator',
              color='blue')
    ax1.legend()
    ax1.set_ylabel('Change SpO2')
    
    ax3.stem(measDF.index.values,
             (measDF['SpO2Change_dynamicCurve'].values - measDF['SpO2Change_constCurve'].values)
              )
    ax3.set_ylabel('Dynam. - Const.')
    ax3.set_xticks([])
    
    ax5.stem(operatorVsDynamic.index.values,
              (operatorVsDynamic['SpO2Change_dynamicCurve'].values - operatorVsDynamic['WhatDidTheOperatorDo'].values)
              )
    ax5.set_ylabel('Dynam. - Op.')
    ax5.set_xticks([])
    
    ax7.plot(measDF.index.values, 
             measDF['S Slag'].values,
             marker='*',
             label='S Slag',
             color='orange')
    ax7.axhline(y=0.8,color='red',linestyle='--') 
    ax7.set_ylabel('S Slag')
    ax7.set_xticks([])

    nbins=20
    ax2.hist(measDF['SpO2Change_constCurve'].values,
              bins=nbins,
              label='SpO2 using existing constant curve',
              color='green',
              alpha=0.5,
              edgecolor='black')
    ax2.set_xlim((-20, 20))
    #ax2.set_ylim((0, 100))
    ax2.legend()
    ax2.set_title('Distribution of changes in SpO2')
    ax2.set_xticks([])
    
    ax4.hist(measDF['SpO2Change_dynamicCurve'].values,
              bins=nbins,
              label='SpO2 using new dynamically changing curves',
              color='firebrick',
              alpha=0.5,
              edgecolor='black')
    ax4.set_xlim((-20, 20))
    #ax4.set_ylim((0, 100))
    ax4.legend()
    ax4.set_xticks([])
    
    ax6.hist(measDF['WhatDidTheOperatorDo'].values,
              bins=nbins,
              label='What did the operator actually do?',
              color='blue',
              alpha=0.5,
              edgecolor='black')
    ax6.set_xlim((-20, 20))
    #ax6.set_ylim((0, 100))
    ax6.legend()
    ax6.set_xlabel('Change in SpO2')
   

    
    ax8.plot(FeMatte.index.values, 
             FeMatte.values,
             marker='*',
             label='Fe Matte',
             color='indigo')
    ax8.set_ylabel('Fe Matte (%)')
    ax8.axhspan(2.5 ,3.5, alpha = 0.1, color = 'blue')
    ax8.axhline(y=2.5,color = 'blue',linestyle='--', linewidth = 2) 
    ax8.axhline(y=3.5,color = 'blue',linestyle='--', linewidth = 2) 
    ax8.axhline(y=3,color = 'blue',linestyle='--') 
    ax8.tick_params(axis = 'x', labelrotation = 45)
