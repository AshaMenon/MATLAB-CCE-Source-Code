# -*- coding: utf-8 -*-
"""
Created on Mon Jan 30 11:00:36 2023

@author: antonio.peters
"""

import pandas as pd
import EvaluateXGEBoostBasicity
import numpy as np

def main():
    # Read in data as a csv
    inputs = pd.read_csv('D:/CCE Dependencies/CCE DataScienceModels/PythonFiles/inputsBasicity.csv').to_dict('list')
        
    parameters = pd.read_csv('D:/CCE Dependencies/CCE DataScienceModels/PythonFiles/parametersBasicity.csv').to_dict('list')
    for param in parameters:
        parameters[param] = parameters[param][0]
    
    [outputs, error_code] = EvaluateXGEBoostBasicity.EvaluateXGEBoostBasicity(parameters, inputs)
    
    pd.DataFrame(outputs).to_csv('D:/CCE Dependencies/CCE DataScienceModels/PythonFiles/outputsBasicity.csv')
    np.savetxt('D:/CCE Dependencies/CCE DataScienceModels/PythonFiles/errorBasicity.txt',[error_code])

if __name__ == "__main__":
    main()
