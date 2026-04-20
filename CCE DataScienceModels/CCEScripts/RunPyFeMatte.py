# -*- coding: utf-8 -*-
"""
Created on Fri Apr 14 09:40:36 2023

@author: antonio.peters
"""

import pandas as pd
import EvaluateAlignedFeMatte
import numpy as np

def main():
    # Read in data as a csv
    inputs = pd.read_csv('D:/CCE Dependencies/CCE DataScienceModels/PythonFiles/inputsFeMatte.csv').to_dict('list')
        
    parameters = pd.read_csv('D:/CCE Dependencies/CCE DataScienceModels/PythonFiles/parametersFeMatte.csv').to_dict('list')
    for param in parameters:
        parameters[param] = parameters[param][0]
    
    [outputs, error_code] = EvaluateAlignedFeMatte.EvaluateAlignedFeMatte(parameters, inputs)
    
    pd.DataFrame(outputs).to_csv('D:/CCE Dependencies/CCE DataScienceModels/PythonFiles/outputsFeMatte.csv')
    np.savetxt('D:/CCE Dependencies/CCE DataScienceModels/PythonFiles/errorFeMatte.txt',[error_code])

if __name__ == "__main__":
    main()
