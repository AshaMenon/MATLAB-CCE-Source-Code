import numpy as np

def calculate_level_average(data):
    """
    Calculates the average of columns where there's a change in data.

    :param data: 2D numpy array of data
    :param columns: 1D boolean array specifying which columns to consider
    :return: 1D numpy array of average values
    """

    data = data.astype(float)
    
    # Find the indices where data changes
    diff_indices = np.vstack((np.zeros(data.shape[1], dtype=bool), np.diff(data, axis=0) != 0))
    
    # Replace unchanged values in the original data with NaN
    data[~diff_indices] = np.nan
    data[data == 0] = np.nan
    
    # Compute mean across columns for each row
    avg_values = np.nanmean(data, axis=1)
    
    # Carry forward the average value for rows with NaN
    for i in range(1, len(avg_values)):
        if np.isnan(avg_values[i]):
            avg_values[i] = avg_values[i-1]
    
    return avg_values

def calculate_level_maximum(data):
    """
    Calculates the maximum of columns where there's a change in data.

    :param data: 2D numpy array of data
    :param columns: 1D boolean array specifying which columns to consider
    :return: 1D numpy array of maximum values
    """

    data = data.astype(float)
    
    # Find the indices where data changes
    diff_indices = np.vstack((np.zeros(data.shape[1], dtype=bool), np.diff(data, axis=0) != 0))
    
    # Replace unchanged values in the original data with NaN
    data[~diff_indices] = np.nan
    data[data == 0] = np.nan
    
    # Compute mean across columns for each row
    max_values = np.nanmax(data, axis=1)
    
    # Carry forward the average value for rows with NaN
    for i in range(1, len(max_values)):
        if np.isnan(max_values[i]):
            max_values[i] = max_values[i-1]
    
    return max_values


def add_combined_level(data_df):
    """
    Adds a 'CombinedLevel' column to the dataframe based on the max or average values 
    
    :param data_df: The input DataFrame.
    :return: The updated DataFrame.
    """

    #%% Matte Levels
    
    matte_columns = [col for col in data_df.columns if 'Matte Levels' in col]
    data = data_df[matte_columns]

    max_matte_values = calculate_level_maximum(data) 
    data_df['Matte Combined Level'] = max_matte_values

    #%% Slag Levels

    slag_columns = [col for col in data_df.columns if 'Slag Levels' in col]
    data = data_df[slag_columns]

    max_slag_values = calculate_level_average(data) 
    data_df['Slag Combined Level'] = max_slag_values

    #%% Bath Levels

    bath_columns = [col for col in data_df.columns if 'Bath Levels' in col]
    data = data_df[bath_columns]

    max_bath_values = calculate_level_average(data) 
    data_df['Bath Combined Level'] = max_bath_values

    #%% Bonedry Levels

    bonedry_columns = [col for col in data_df.columns if 'Concentrate Levels' in col]
    data = data_df[bonedry_columns]

    max_bonedry_values = calculate_level_average(data) 
    data_df['Bonedry Combined Level'] = max_bonedry_values

    return data_df