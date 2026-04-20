# -*- coding: utf-8 -*-
"""
Created on [Current Date]

@author: Asa Shinu
"""

import pandas as pd
import EvaluateFatigueModel  # This imports my logic
import numpy as np

def main():
    # Parameterise with Model Name and Files Directory
    modelName = 'Fatigue'
    filesDirectory = 'D:/CCE Dependencies/CCE Predictive Maintenance/PythonFiles'

    #inputs = pd.read_csv(f'{filesDirectory}/inputs{modelName}.csv').to_dict('list')
    # 1. Read Wide Inputs (reconstruct Tag_1, Tag_2... into lists)
    df_raw_inputs = pd.read_csv(os.path.join(path, f'inputs{modelName}.csv'))
     # Bundle columns into lists for the math logic
    tag_values = df_raw_inputs.filter(regex='^Tag_\d+').values.flatten().tolist()
    tag_times = df_raw_inputs.filter(regex='^TagTimestamps_\d+').values.flatten().tolist()
    
    inputs_dict = {
        'Tag': tag_values,
        'TagTimestamps': tag_times
    }   
    # 2. Read in parameters and flatten (MATLAB tables read as lists of 1 item)
    parameters = pd.read_csv(f'{filesDirectory}/parameters{modelName}.csv').to_dict('list')
    for param in parameters:
        parameters[param] = parameters[param][0]
    
    # 3. Run the evaluation logic
    [outputs, error_code] = EvaluateFatigueModel.EvaluateFatigueModel(parameters, inputs)
    
    # 4. Save results back for MATLAB to pick up
    pd.DataFrame(outputs).to_csv(f'{filesDirectory}/outputs{modelName}.csv', index=False)
    np.savetxt(f'{filesDirectory}/error{modelName}.txt', [error_code])

if __name__ == "__main__":
    main()