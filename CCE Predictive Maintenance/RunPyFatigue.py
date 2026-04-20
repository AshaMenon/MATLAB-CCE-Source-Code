# -*- coding: utf-8 -*-
import pandas as pd
import EvaluateFatigueModel as efm
import numpy as np
import os

def main():
    modelName = 'Fatigue'
    filesDirectory = r'D:\CCE Dependencies\CCE Predictive Maintenance\PythonFiles'

    # 1. Read the horizontal "Wide" CSV produced by MATLAB
    input_path = os.path.join(filesDirectory, f'inputs{modelName}.csv')
    df_raw = pd.read_csv(input_path)
    
    # 2. Pivot the columns back into lists
    tag_vals = df_raw.filter(regex='^Tag_\d+').values.flatten().tolist()
    tag_times = df_raw.filter(regex='^TagTimestamps_\d+').values.flatten().tolist()
    inputs_dict = {'Tag': tag_vals, 'TagTimestamps': tag_times}   

    # 3. Read Parameters
    df_p = pd.read_csv(os.path.join(filesDirectory, f'parameters{modelName}.csv'))
    parameters = df_p.iloc[0].to_dict()

    # 4. Run Logic
    [outputs, error_code] = efm.EvaluateFatigueModel(parameters, inputs_dict)

    # 5. Create final structure and save with index=True (Required for MATLAB)
    final_df = pd.DataFrame({'TotalDamage': outputs['TotalDamage'], 'Timestamp': outputs['Timestamp']})
    final_df.to_csv(os.path.join(filesDirectory, f'outputs{modelName}.csv'), index=True)
    
    # 6. Save error code
    np.savetxt(os.path.join(filesDirectory, f'error{modelName}.txt'), [error_code])

if __name__ == "__main__":
    main()