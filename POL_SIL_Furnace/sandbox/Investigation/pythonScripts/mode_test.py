import unittest
import pandas as pd
import numpy as np
from mode import create_mode_proxy

class TestCreateModeProxy(unittest.TestCase):

    def test_basic_functionality(self):
        dates = pd.date_range("2023-01-01", periods=10, freq="T")  # minutely frequency
        data = {'Timestamp': dates,
            'Furnace Power SP': [68, 68, 0.3, 45.9, 46.1144, 30.24, 21.635, 13.652, 68, 68.067],
            'Total Electrode Power': [68.8, 70.25, 0.02, 43, 45, 30, 22.14, 13.547, 65.83, 66.067]
        }
        df = pd.DataFrame(data)

        result_df = create_mode_proxy(df)
        
        expected_modes = ["Normal", "Normal", "Off", "Ramp", "Ramp", "Ramp", "Ramp", "Ramp", "Normal", "Normal"]
        self.assertListEqual(result_df['mode'].tolist(), expected_modes)

    def test_all_off(self):
        dates = pd.date_range("2023-01-01", periods=4, freq="T")
        data = {'Timestamp': dates,
            'Furnace Power SP': [0.3, 0.3, 0.3, 0.3],
            'Total Electrode Power': [0.02, 0.02, 0.02, 0.02]
        }
        df = pd.DataFrame(data)

        result_df = create_mode_proxy(df)

        expected_modes = ["Off", "Off", "Off", "Off"]
        self.assertListEqual(result_df['mode'].tolist(), expected_modes)

    def test_lost_capacity(self):
        dates = pd.date_range("2023-01-01", periods=10, freq="T")  # minutely frequency
        data = {'Timestamp': dates,
            'Furnace Power SP': [68, 67.1, 67.5, 67, 67.1, 67.4, 67.1, 68, 68, 67.5],
            'Total Electrode Power': [68.8, 70.25, 67, 67.1, 67, 67, 67.2, 67.9, 68.1, 67.5]
        }
        df = pd.DataFrame(data)

        result_df = create_mode_proxy(df)

        expected_modes = ["Normal", "Lost Capacity", "Lost Capacity", "Lost Capacity", "Lost Capacity", "Lost Capacity", "Lost Capacity", "Normal", "Normal", "Normal"]
        self.assertListEqual(result_df['mode'].tolist(), expected_modes)

if __name__ == '__main__':
    unittest.main()
