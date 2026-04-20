# -*- coding: utf-8 -*-
"""

"""

import pandas as pd
import EvalMockModel
import numpy as np

def main():
    # Read in data as a csv
    inputs = pd.read_csv('D:/PythonFiles/inputsMockModel.csv').to_dict('list')
        
    parameters = pd.read_csv('D:/PythonFiles/parametersMockModel.csv').to_dict('list')
    for param in parameters:
        parameters[param] = parameters[param][0]
        
    for i in inputs:
        inputs[i] = inputs[i][0]
    
    [outputs, error_code] = EvalMockModel.EvalMockModel(parameters, inputs)
    
    pd.DataFrame([outputs], columns=outputs.keys()).to_csv('D:/PythonFiles/outputsMockModel.csv')
    np.savetxt('D:/PythonFiles/errorMockModel.txt',[error_code])

if __name__ == "__main__":
    main()