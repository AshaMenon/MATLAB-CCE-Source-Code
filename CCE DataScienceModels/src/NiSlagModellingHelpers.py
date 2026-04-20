# -*- coding: utf-8 -*-
"""
Created on Fri Apr 29 11:51:11 2022

@author: verushen.coopoo
"""
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import sklearn
import matplotlib as mpl
from sklearn.preprocessing import PolynomialFeatures
from sklearn.model_selection import KFold, cross_val_score, train_test_split
from sklearn.linear_model import PoissonRegressor
from sklearn.metrics import mean_squared_error, r2_score
from math import sqrt    
from sklearn.preprocessing import RobustScaler
from skopt import BayesSearchCV
from sklearn.pipeline import Pipeline
import src.preprocessingFunctions as prep
import pickle

#%%    
def trainThermoModel(thermoDF, writeTermsToSpreadsheet, refit):
    
    '''
    -   Trains thermodynamic model using ideal thermodynamic data
    -   to write the terms of the final equation to a speadsheet, 
        set writeTermsToSpreadsheet = True
    -   for deployment
    '''
    
    thermoDF = thermoDF.drop_duplicates()
    predictorTags = ['Fe Matte','Basicity','Matte temperatures', 'PSO2']
    responseTag = ['Ni Slag']

    # Test-train split
    X = thermoDF[predictorTags]
    Y = thermoDF[responseTag]
    X_train, X_test, y_train, y_test = train_test_split(X, Y, test_size=0.3, random_state=42)

    # Build pipeline
    tscv = KFold(n_splits = 10, shuffle = True)

    pipe = Pipeline(
            [
                 ('scaler',RobustScaler()),
                 ('preprocessor', PolynomialFeatures()),
                 ('regressor', PoissonRegressor())
             ]
    )

    param = {
                'preprocessor__degree': np.linspace(1, 2, 2, dtype = 'int'),
                'regressor__alpha': np.logspace(-7, 1, num = 1000)
    }

    # Refit the model, else load the saved model from a pickle file
    if refit == True:
        randomSearch = BayesSearchCV(estimator = pipe, search_spaces = param, 
                                     n_iter = 50, cv = tscv,verbose = 5, n_jobs = 5, 
                                     scoring = 'neg_root_mean_squared_error', 
                                     refit = True)
    
        searchResults = randomSearch.fit(X_train, np.ravel(y_train.values))

        pipe_updated = searchResults.best_estimator_
    
        # Fit model
        thermoMdl = pipe_updated.fit(X_train,np.ravel(y_train.values))
       
        with open('thermoMdl_Pickle_file.pickle', 'wb') as handle:
            pickle.dump([thermoMdl, searchResults, pipe_updated], handle, protocol=pickle.HIGHEST_PROTOCOL)
    else:
        with open('thermoMdl_Pickle_file.pickle', 'rb') as handle:
            mdlData = pickle.load(handle)
            
            thermoMdl = mdlData[0]
            searchResults = mdlData[1]
            pipe_updated = mdlData[2]
    # Get predictions using model
    # No need to use cross_val_score - we are not training/cross validating anything
    ytest_hat = thermoMdl.predict(X_test) 

    # Calculate metrics and terms of equation
    scaler = RobustScaler()
    scaledPredictors = scaler.fit_transform(X_train)
    degree = searchResults.best_params_.get('preprocessor__degree')
    poly = PolynomialFeatures(degree=degree, include_bias=True)
    scaledPredictors = poly.fit_transform(scaledPredictors)
    alpha = searchResults.best_params_.get('regressor__alpha')
    thermoMdl_forTerms = PoissonRegressor(alpha = alpha)
    thermoMdl_forTerms = thermoMdl_forTerms.fit(scaledPredictors, y_train.values.ravel())

    rmse = sqrt(mean_squared_error(y_test.values, ytest_hat))
    r2_outOfSample = r2_score(y_test.values, ytest_hat)
    crossValScore = cross_val_score(pipe_updated, X_test, np.ravel(y_test.values), cv = tscv)
    r2_crossVal = np.mean(crossValScore)

    # Terms
    terms = sklearn.preprocessing.PolynomialFeatures.get_feature_names(poly)
    terms = [w.replace('x0', ' ⋅ FeMatte') for w in terms]
    terms = [w.replace('x1', ' ⋅ B') for w in terms]
    terms = [w.replace('x2', ' ⋅ T') for w in terms]
    terms = [w.replace('x3', ' ⋅ PSO2') for w in terms]

    # Get metrics
    thermoMdlStats = {
        'RMSE' : rmse,
        'R2 test' : r2_outOfSample,
        'R2 cross-val' : r2_crossVal,
        'Polynomial degree' : degree,
        'Poisson alpha' : alpha,
        'Number of terms' : len(terms)
        }
    

    # Write terms to spreadsheet
    if writeTermsToSpreadsheet == True:
        coeffs = thermoMdl_forTerms.coef_
        coeffs = coeffs.tolist()
        coeffs = np.char.mod('%f',coeffs)
        termsOfEqn = np.char.add(coeffs,terms)
        dataDir = prep.getDataPreferences()
        plusses = ['+'] * len(termsOfEqn)
        termsDF = pd.DataFrame([termsOfEqn, plusses])
        termsDF = termsDF.T
        termsDF.loc[len(termsDF)-1,1] = ' '
        termsDF.to_excel(dataDir + '\\NiSlagEquationOrder2.xlsx', index=False, header=False,startcol = 1)
    

    return thermoMdl, thermoMdlStats, X_test, y_test

#%%
def plotSurface(inputDict, thermoMdl, measDF):
    
    '''
    -   Plots surface of thermo model as a function of 2 other variables
    '''
    
    n =  len(inputDict["const1Value"])    
    const1Name = inputDict["const1Name"] 
    const2Name = inputDict["const2Name"]
    colors = inputDict["colors"]
    yVarName = inputDict['yVarName']
    yvarBounds = inputDict['yvarBounds']
    
    
    fig = plt.figure()
    ax = fig.add_subplot(projection='3d')
    ax.set_ylabel(yVarName)
    ax.set_xlabel('Fe Matte')
    ax.set_zlabel('Ni Slag')
    surfaceLegends = []
    legendText = [' '] * (n + 1)
    surfaceLegends = [' '] * (n + 1)

    plt.title('Ni in Slag = f(Fe Matte, {}); {} and {} constant'.format(yVarName, const1Name, const2Name))
    
    
    for i in range(0 , n):    
            
            const1Value = inputDict["const1Value"][i]
            const2Value = inputDict["const2Value"][i]
            
            factor = 0
            FeMatte_ = np.arange(0,10,0.5)
            yvar_ = np.linspace(yvarBounds[0] - yvarBounds[0]*factor, yvarBounds[1] + yvarBounds[1]*factor, np.shape(FeMatte_)[0]) 
            
            FeMatte, yvar = np.meshgrid(FeMatte_, yvar_)
            arr = np.array([FeMatte,yvar]).T
            arr = np.reshape(arr,(len(FeMatte_)*len(FeMatte_),2))
            
            if (yVarName == 'Basicity') & (const1Name == 'Matte temperatures'):
                const1 = np.ones((np.shape(arr)[0],1)) * const1Value
                const2 = np.ones((np.shape(arr)[0],1)) * const2Value
                arr = np.concatenate((arr,const1,const2),axis=1)
                df = pd.DataFrame(arr,columns=['Fe Matte', 'Basicity', 'Matte temperatures', 'PSO2'])
                flatteners = ['F','F','F']
            elif (yVarName == 'Basicity') & (const1Name == 'PSO2'):
                const1 = np.ones((np.shape(arr)[0],1)) * const1Value
                const2 = np.ones((np.shape(arr)[0],1)) * const2Value
                arr = np.concatenate((arr,const2,const1),axis=1)
                df = pd.DataFrame(arr,columns=['Fe Matte', 'Basicity', 'Matte temperatures', 'PSO2'])
                flatteners = ['F','F','F']
            elif (yVarName == 'Matte temperatures') & (const1Name == 'PSO2'):
                const1 = np.ones((np.shape(arr)[0],1)) * const1Value
                const2 = np.ones((np.shape(arr)[0],1)) * const2Value
                arr = np.concatenate((np.expand_dims(arr[:,0],axis=1),
                const2,
                np.expand_dims(arr[:,1],axis=1),
                const1
                ),axis=1)
                df = pd.DataFrame(arr,columns=['Fe Matte', 'Basicity', 'Matte temperatures', 'PSO2'])
                flatteners = ['F','F','C']
            elif (yVarName == 'Matte temperatures') & (const1Name == 'Basicity'):
                const1 = np.ones((np.shape(arr)[0],1)) * const1Value
                const2 = np.ones((np.shape(arr)[0],1)) * const2Value
                arr = np.concatenate((np.expand_dims(arr[:,0],axis=1),
                const1,
                np.expand_dims(arr[:,1],axis=1),
                const2
                ),axis=1)
                df = pd.DataFrame(arr,columns=['Fe Matte', 'Basicity', 'Matte temperatures', 'PSO2'])
                flatteners = ['F','F','C']
            elif (yVarName == 'PSO2') & (const1Name == 'Matte temperatures'):
                const1 = np.ones((np.shape(arr)[0],1)) * const1Value
                const2 = np.ones((np.shape(arr)[0],1)) * const2Value
                arr = np.concatenate((np.expand_dims(arr[:,0],axis=1),
                const2,
                const1,
                np.expand_dims(arr[:,1],axis=1)
                ),axis=1)
                df = pd.DataFrame(arr,columns=['Fe Matte', 'Basicity', 'Matte temperatures', 'PSO2'])
                flatteners = ['F','F','C']
            elif (yVarName == 'PSO2') & (const1Name == 'Basicity'):
                const1 = np.ones((np.shape(arr)[0],1)) * const1Value
                const2 = np.ones((np.shape(arr)[0],1)) * const2Value
                arr = np.concatenate((np.expand_dims(arr[:,0],axis=1),
                const1,
                const2,
                np.expand_dims(arr[:,1],axis=1)
                ),axis=1)
                df = pd.DataFrame(arr,columns=['Fe Matte', 'Basicity', 'Matte temperatures', 'PSO2'])
                flatteners = ['F','F','C']
            
        
            NiSlag_pred = thermoMdl.predict(df)
            
            feMatte_flat = FeMatte.flatten(flatteners[0])
            yvar_flat = yvar.flatten(flatteners[1])
            Ni_flat = NiSlag_pred.flatten(flatteners[2])

            # Plot surface
            surf = ax.plot_trisurf(feMatte_flat,yvar_flat,Ni_flat, color=colors[i], alpha=0.2)
            

            # Get colors for custom legend
            surfaceLegends[i] =  mpl.lines.Line2D([0],[0], linestyle="none", c=colors[i], marker = 's',alpha=0.2)
            
            # Get text for custom legend
            legendText[i] = '{} = {}; {} = {}'.format(const1Name, const1Value, const2Name, const2Value)
            
    surfaceLegends[n] = mpl.lines.Line2D([0],[0], linestyle="none", c='black', marker = '*')
    legendText[n] = 'Actual measurements'    
    ax.scatter(measDF['Fe Matte'], measDF[yVarName], measDF['Ni Slag'], marker = '*', c='black')
    
    plt.show()
    plt.legend(surfaceLegends,legendText,loc='upper right')
#%%
def plot2DProjections(testValsDict, X_test, y_test, thermoMdl):

    '''
    -   Plots projection of 3D surface of thermo model into 2D
    '''    

    T_test_val_single = testValsDict["T_test_val"]
    B_test_val_single = testValsDict["B_test_val"]
    PSO2_test_val_single = testValsDict["PSO2_test_val"]
    
    # Basicity ================================================================
    
    test_idx = np.isclose(X_test['Matte temperatures'],T_test_val_single) & np.isclose(X_test['PSO2'],PSO2_test_val_single)
    X_test_reduced = X_test.loc[test_idx]
    Y_test_reduced = y_test.loc[test_idx]
    
    B_test_val = sorted(X_test_reduced['Basicity'].unique())

    fig, axs = plt.subplots(3,3,sharex=True,sharey=True)

    for i in range(0,3):
        
        testIdx = np.isclose(X_test_reduced['Basicity'],B_test_val[i])
        X_test_reduced_specificVal = X_test_reduced.loc[testIdx]
        Y_test_reduced_specificVal = Y_test_reduced.loc[testIdx]
    
        #scaledPredictors = scaler.transform(testDF.values)
        NiSlag_pred = thermoMdl.predict(X_test_reduced_specificVal)
        NiSlag_pred = np.reshape(NiSlag_pred,np.shape(X_test_reduced_specificVal['Fe Matte'].values))
        
        MSE = mean_squared_error(Y_test_reduced_specificVal.values,NiSlag_pred.T)
        
        axs[i,0].scatter(X_test_reduced_specificVal['Fe Matte'].values,NiSlag_pred.T,marker='*',color='black',label='Generated from linear model',s=500)
        axs[i,0].scatter(X_test_reduced_specificVal['Fe Matte'],Y_test_reduced_specificVal['Ni Slag'],marker='s',color='mediumturquoise',label='Original thermodynamic data')
        axs[i,0].set_title('Basicity = {} | MSE = {}'.format(B_test_val[i],MSE))
        axs[i,0].grid()
    axs[i,0].legend()
    
    # Matte temperatures ======================================================
    
    test_idx = np.isclose(X_test['Basicity'],B_test_val_single) & np.isclose(X_test['PSO2'],PSO2_test_val_single)
    X_test_reduced = X_test.loc[test_idx]
    Y_test_reduced = y_test.loc[test_idx]
    

    T_test_val = sorted(X_test_reduced['Matte temperatures'].unique())
    
    for i in range(0,3):
        
        testIdx = np.isclose(X_test_reduced['Matte temperatures'],T_test_val[i])
        X_test_reduced_specificVal = X_test_reduced.loc[testIdx]
        Y_test_reduced_specificVal = Y_test_reduced.loc[testIdx]
    
        #scaledPredictors = scaler.transform(testDF.values)
        NiSlag_pred = thermoMdl.predict(X_test_reduced_specificVal)
        NiSlag_pred = np.reshape(NiSlag_pred,np.shape(X_test_reduced_specificVal['Fe Matte'].values))
        
        MSE = mean_squared_error(Y_test_reduced_specificVal.values,NiSlag_pred.T)
        
        axs[i,1].scatter(X_test_reduced_specificVal['Fe Matte'].values,NiSlag_pred.T,marker='*',color='black',label='Generated from linear model',s=500)
        axs[i,1].scatter(X_test_reduced_specificVal['Fe Matte'],Y_test_reduced_specificVal['Ni Slag'],marker='s',color='firebrick',label='Original thermodynamic data')
        axs[i,1].set_title('T = {} | MSE = {}'.format(T_test_val[i],MSE))
        axs[i,1].grid()
    axs[i,1].legend()
    
    # PSO2 ====================================================================
    
    test_idx = np.isclose(X_test['Basicity'],B_test_val_single) & np.isclose(X_test['Matte temperatures'],T_test_val_single)
    X_test_reduced = X_test.loc[test_idx]
    Y_test_reduced = y_test.loc[test_idx]

  
    PSO2_test_val = sorted(X_test_reduced['PSO2'].unique())
    
    for i in range(0,3):
        
        testIdx = np.isclose(X_test_reduced['PSO2'],PSO2_test_val[i])
        X_test_reduced_specificVal = X_test_reduced.loc[testIdx]
        Y_test_reduced_specificVal = Y_test_reduced.loc[testIdx]
    
        #scaledPredictors = scaler.transform(testDF.values)
        NiSlag_pred = thermoMdl.predict(X_test_reduced_specificVal)
        NiSlag_pred = np.reshape(NiSlag_pred,np.shape(X_test_reduced_specificVal['Fe Matte'].values))
        
        MSE = mean_squared_error(Y_test_reduced_specificVal.values,NiSlag_pred.T)
        
        axs[i,2].scatter(X_test_reduced_specificVal['Fe Matte'].values,NiSlag_pred.T,marker='*',color='black',label='Generated from linear model',s=500)
        axs[i,2].scatter(X_test_reduced_specificVal['Fe Matte'],Y_test_reduced_specificVal['Ni Slag'],marker='s',color='goldenrod',label='Original thermodynamic data')
        axs[i,2].set_title('PSO2 = {} | MSE = {}'.format(PSO2_test_val[i],MSE))
        axs[i,2].grid()
    axs[i,2].legend()
    fig.text(0.5, 0.04, 'Fe Matte %', ha='center')
    fig.text(0.04, 0.5, 'Ni Slag % (not corrected)', va='center', rotation='vertical')
    
    fig.suptitle('Constant Temperature & PSO2 | Constant Basicity & PSO2 | Constant Basicity & Temperature')

#%%
def plot2DValidationWithRandomNumbers(nCurves, basicityBounds, temperatureBounds, 
                                      thermoMdl, setFeMatteTarget, newArrayLength):
    
    '''
    -   Validates thermodynamic model for random values of basicity and
        temperature
    '''
    
    newTemp = np.random.uniform(1150, 1350, size = nCurves)
    newTemp[0] = temperatureBounds[0]
    newTemp[-1] = temperatureBounds[1]

    newBasicity = np.random.uniform(1.55, 2.05, size = nCurves)
    newBasicity[0] = basicityBounds[0]
    newBasicity[-1] = basicityBounds[1]

    plt.figure()
    # Plot boundaries
    theoreticalNiSlagPredictions, newDF = takeNewValuesAndPredictNi(
        newTemp[0], newBasicity[0], thermoMdl, False, newArrayLength)
    plt.plot(newDF['Fe Matte'], theoreticalNiSlagPredictions, '*-', 
             label='MINIMUM BOUND: B = {}; T = {}'.format(round(newBasicity[0],3), 
                                                          round(newTemp[0],3)))
    theoreticalNiSlagPredictions, newDF = takeNewValuesAndPredictNi(
        newTemp[-1], newBasicity[-1], thermoMdl, False,newArrayLength)
    plt.plot(newDF['Fe Matte'], theoreticalNiSlagPredictions, '*-', 
             label='MAXIMUM BOUND: B = {}; T = {}'.format(round(newBasicity[-1],3), 
                                                          round(newTemp[-1],3)))

    # Plot random in-betweeners
    for i in range(1, len(newBasicity)-1):
        theoreticalNiSlagPredictions, newDF = takeNewValuesAndPredictNi(
            newTemp[i], newBasicity[i], thermoMdl, False, newArrayLength)
        plt.plot(newDF['Fe Matte'],theoreticalNiSlagPredictions,
                 label='B = {}; T = {}'.format(round(newBasicity[i],3), round(newTemp[i],3)))

    plt.legend()
    plt.grid()
    plt.xlabel('% Fe Matte')
    plt.ylabel('% Theoretical Ni Slag')
    plt.title('Theoretical Ni Slag for random basicity & temperatures; constant PSO2')

#%%
def plot2DValidationWithPolynomialModel(thermoDF, basicityVals, tempVals, 
                                      thermoMdl, setFeMatteTarget, newArrayLength):
    
    '''
    -   validates thermo model with the ideal thermo data for basicity and
        temperature
    '''
    
    # Temperature
    plt.figure()

    for i in range(0,len(tempVals)):
        idx = np.isclose(thermoDF['Basicity'],basicityVals[1]) & \
        np.isclose(thermoDF['Matte temperatures'],tempVals[i]) & \
        np.isclose(thermoDF['PSO2'],0.15)
        plt.scatter(thermoDF['Fe Matte'].loc[idx].values, thermoDF['Ni Slag'].loc[idx].values, 
                    marker="s", label='Polynom. model: T = {}'.format(round(tempVals[i],3)))
        
        theoreticalNiSlagPredictions, newDF = takeNewValuesAndPredictNi(
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
        
        theoreticalNiSlagPredictions, newDF = takeNewValuesAndPredictNi(
            tempVals[1], basicityVals[i], thermoMdl, setFeMatteTarget, newArrayLength)
        plt.plot(newDF['Fe Matte'], theoreticalNiSlagPredictions, "*-", 
                 label='Poisson model: B = {}'.format(round(basicityVals[i],3)))

    plt.legend()
    plt.grid()
    plt.xlabel('% Fe Matte')
    plt.ylabel('% Theoretical Ni Slag')
    plt.title('Theoretical Ni Slag (calculated via Poisson & Polynomial models) for Temperature = 1250 and PSO2 = 0.15 \n Varying basicity')
#%%
def takeNewValuesAndPredictNi(newTemp, newBasicity, thermoMdl, setFeMatteTarget, newArrayLength):
    
    '''
    -   Predict new predictions for theoretical Ni Slag using thermo model
    '''
    
    if (setFeMatteTarget == True):
        FeMatte = np.ones((newArrayLength)) * 3 
    else:
        FeMatte = np.linspace(0,10,newArrayLength)
        # FeMatte = [ 1. ,  2. ,  2.5,  3. ,  3.5,  4. ,  5. ,  6. ,  7. ,  8. ,  9. ,
        #        10. ]
        
        
    PSO2_const = 0.15
    PSO2 = np.ones((newArrayLength)) * PSO2_const
   
    temperatures = np.ones((newArrayLength)) * newTemp
    basicity = np.ones((newArrayLength)) * newBasicity
    arr = np.column_stack((FeMatte, 
                           basicity,
                           temperatures,
                           PSO2
                           ))
    newDF = pd.DataFrame(arr,columns=['Fe Matte','Basicity','Matte temperatures', 'PSO2'])
    
    theoreticalNiSlagPredictions = thermoMdl.predict(newDF)
    return theoreticalNiSlagPredictions, newDF    
#%%
def calculateCorrNiSlag(NiSlag, SSlag, subtractionParam, multiplierParam, thresholdParam):
    
    '''
    -   Using format of existing Ni Slag correction, apply an updated correction
        using three parameters (subtraction, multiplier, threshold)
    -   for deployment
    '''
    
    SSlag[SSlag > thresholdParam] = thresholdParam
    corrNiSlag = NiSlag.values - (SSlag.values - subtractionParam) * multiplierParam
    
    return corrNiSlag

#%% 
def removeOutliers(dataWithOutliers, a, symmetrical):
    '''
    -   Helper function to remove outliers
    -   assumes data is symmetrically distributed
    -   for deployment
    '''
    Q1, Q2, Q3 = np.percentile(dataWithOutliers, [25,50,75])
    if symmetrical:
        lowerBound = Q2 - a * (Q3 - Q1)
        upperBound = Q2 + a * (Q3 - Q1)
    else:
        lowerBound = Q2 - a * (Q2 - Q1)
        upperBound = Q2 + a * (Q3 - Q2)
        
    idx = (dataWithOutliers > lowerBound) & \
                            (dataWithOutliers < upperBound)
    
    data = dataWithOutliers[idx]

    return data, idx