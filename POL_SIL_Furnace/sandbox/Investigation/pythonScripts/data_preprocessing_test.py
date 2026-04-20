import unittest
import pandas as pd
import data_preprocessing as dp

class TestRemoveThresholdOutliers(unittest.TestCase):

    def setUp(self):
        self.sample_data = {
            'Furnace Pressure A': [95, 100, 97, 96, 101, 98],
            'Furnace Pressure B': [80, 99, 81, 102, 83, 84]
        }

    def test_threshold_and_forward_fill(self):
        df = pd.DataFrame(self.sample_data)
        processed_df = dp.remove_threshold_outliers(df, ['Furnace Pressure A', 'Furnace Pressure B'], 99, fill_method='ffill')
        
        expected_pressure = [95, 95, 97, 96, 96, 98]
        expected_another_tag = [80, 80, 81, 81, 83, 84]

        self.assertListEqual(processed_df['Furnace Pressure A'].tolist(), expected_pressure)
        self.assertListEqual(processed_df['Furnace Pressure B'].tolist(), expected_another_tag)

    def test_threshold_and_backward_fill(self):
        df = pd.DataFrame(self.sample_data)
        processed_df = dp.remove_threshold_outliers(df, ['Furnace Pressure A', 'Furnace Pressure B'], 99, fill_method='bfill')
        
        expected_pressure = [95, 97, 97, 96, 98, 98]
        expected_another_tag = [80, 81, 81, 83, 83, 84]

        self.assertListEqual(processed_df['Furnace Pressure A'].tolist(), expected_pressure)
        self.assertListEqual(processed_df['Furnace Pressure B'].tolist(), expected_another_tag)


if __name__ == '__main__':
    unittest.main()
