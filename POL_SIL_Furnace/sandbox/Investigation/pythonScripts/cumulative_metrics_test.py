import unittest
import pandas as pd
from cumulative_metrics import rolling_cumulative_time_online

class TestCumulativeMetrics(unittest.TestCase):

    def test_rolling_cumulative_time_online(self):
        # Create a sample dataframe
        data_df = pd.DataFrame({'Total Electrode Power': [68, 2.435, 32.283, 40.925, 40.24, 69.64]})

        # Expected output (using a window size of 3)
        expected_output = [None, None, 0.5035,	0.3707,	0.5561,	0.7392]

        # Call the function
        output = rolling_cumulative_time_online(data_df, 3).tolist()

        # Check if the expected output matches the result from the function
        for i in range(len(expected_output)):
            if expected_output[i] is not None:
                self.assertAlmostEqual(output[i], expected_output[i], places=3)
            else:
                self.assertTrue(pd.isna(output[i]))

# Run the tests
if __name__ == '__main__':
    unittest.main()
