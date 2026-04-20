# -*- coding: utf-8 -*-
"""
Created on Tue Feb  7 12:17:52 2023

@author: antonio.peters
"""

import pandas as pd
import EvaluateSPO2
import numpy as np

def main():
    # Read in data as a csv
    inputs = pd.read_csv('D:/CCE Dependencies/CCE DataScienceModels/PythonFiles/inputsSPO2Dynamic.csv').to_dict('list')
        
    parameters = pd.read_csv('D:/CCE Dependencies/CCE DataScienceModels/PythonFiles/parametersSPO2Dynamic.csv').to_dict('list')
    for param in parameters:
        parameters[param] = parameters[param][0]
    
    [outputs, error_code] = EvaluateSPO2.EvaluateSPO2(parameters, inputs)
    
    pd.DataFrame(outputs).to_csv('D:/CCE Dependencies/CCE DataScienceModels/PythonFiles/outputsSPO2Dynamic.csv')
    np.savetxt('D:/CCE Dependencies/CCE DataScienceModels/PythonFiles/errorSPO2Dynamic.txt',[error_code])

if __name__ == "__main__":
    main()