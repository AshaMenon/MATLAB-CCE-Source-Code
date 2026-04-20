# -*- coding: utf-8 -*-
"""
Created on Mon Jan 30 11:00:36 2023

@author: antonio.peters
"""

import pandas as pd
import EvaluateKilkenModel
import numpy as np

def main():
    # Parameterise with Model Name and Files Directory - otherwise many files of many models in one location
    modelName = 'Kilken'
    filesDirectory = 'D:/CCE Dependencies/CCE DataScienceModels/PythonFiles'

    # Read in data as a csv
    inputs = pd.read_csv(f'{filesDirectory}/inputs{modelName}csv').to_dict('list')
        
    parameters = pd.read_csv(f'{filesDirectory}/parameters{modelName}.csv').to_dict('list')
    for param in parameters:
        parameters[param] = parameters[param][0]
    
    [outputs, error_code] = EvaluateKilkenModel.EvaluateKilkenModel(parameters, inputs)
    
    pd.DataFrame(outputs).to_csv(f'{filesDirectory}/outputs{modelName}.csv')
    np.savetxt(f'{filesDirectory}/error{modelName}.txt',[error_code])

if __name__ == "__main__":
    main()
