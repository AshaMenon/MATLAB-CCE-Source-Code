import unittest
import numpy as np
import os
import pandas as pd
from level_combination import calculate_level_average, calculate_level_maximum, add_combined_level


class TestCalculateLevelAverage(unittest.TestCase):
    
    def test_average_calculation(self):
        data = np.array([[0, 61,	0,	55,	0,	0,	52,	0,	34,	0], 
                         [0, 61,	0,	55,	0,	0,	52,	0,	34,	0], 
                         [0, 50,	0,	55,	0,	0,	52,	0,	34,	0], 
                         [0, 50,	0,	55,	0,	0,	52,	0,	34,	0],
                         [0, 61,	0,	50,	0,	0,	62,	0,	34,	0], 
                         [0, 61,	0,	50,	0,	0,	62,	0,	34,	0], 
                         [0, 61,	0,	55,	0,	0,	52,	0,	45,	0], 
                         [0, 0,	0,	65,	0,	0,	62,	0,	34,	0]])
       
        
        result = calculate_level_average(data)
        expected = np.array([np.nan, np.nan, 50, 50, 57.67, 57.67, 50.67, 53.67]) 
        
        np.testing.assert_array_almost_equal(result, expected, decimal=2)  

    def test_zeros(self):
        data = np.array([[0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
                         [0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
                         [np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan]])
        
        
        result = calculate_level_average(data)
        expected = np.array([np.nan, np.nan, np.nan])  
        
        np.testing.assert_array_almost_equal(result, expected, decimal=7)

class TestCalculateMaxAverage(unittest.TestCase):
    
    def test_max_calculation(self):
        data = np.array([[0, 61,	0,	55,	0,	0,	52,	0,	34,	0], 
                         [0, 61,	0,	55,	0,	0,	52,	0,	34,	0], 
                         [0, 50,	0,	55,	0,	0,	52,	0,	34,	0], 
                         [0, 50,	0,	55,	0,	0,	52,	0,	34,	0],
                         [0, 61,	0,	50,	0,	0,	62,	0,	34,	0], 
                         [0, 61,	0,	50,	0,	0,	62,	0,	34,	0], 
                         [0, 61,	0,	55,	0,	0,	52,	0,	45,	0], 
                         [0, 61,	0,	65,	0,	0,	62,	0,	34,	0]])
       
        
        result = calculate_level_maximum(data)
        expected = np.array([np.nan, np.nan, 50, 50, 62, 62, 55, 65]) 
        
        np.testing.assert_array_almost_equal(result, expected, decimal=2)  

    def test_zeros(self):
        data = np.array([[0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
                         [0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
                         [np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan]])
        
        
        result = calculate_level_maximum(data)
        expected = np.array([np.nan, np.nan, np.nan])  
        
        np.testing.assert_array_almost_equal(result, expected, decimal=7)

class TestAddCombinedLevel(unittest.TestCase):

    def test_add_combined_level(self):
        #cwd = os.path.dirname(os.path.dirname(os.getcwd()))
        cwd = os.getcwd()
        path = os.path.join(cwd, 'data', 'Polokwane_SIL_Level_data_Jan_Aug23_v1.csv')

        columns = pd.read_csv(path, nrows=0).columns.tolist()
        df = pd.read_csv(path)
        df = df.apply(lambda col: pd.to_numeric(col, errors='coerce') if col.name != 'Timestamp' else col)

        updated_df = add_combined_level(df)

        path = os.path.join(cwd, 'data', 'combinedLevels.csv')
        columns = pd.read_csv(path, nrows=0).columns.tolist()
        expected_df = pd.read_csv(path)
        expected_df = expected_df.apply(lambda col: pd.to_numeric(col, errors='coerce') if col.name != 'Timestamp' else col)
        
        levelType = ['Slag', 'Matte', 'Bath', 'Bonedry']
        for i in levelType:
            expected_col = f'{i} Combined Level'
            pd.testing.assert_series_equal(updated_df[expected_col], expected_df[expected_col])


        

if __name__ == '__main__':
    unittest.main()
