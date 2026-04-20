import unittest
import pandas as pd


from levelcategory import assign_level_categories, categorise_slag_level, categorise_matte_level, categorise_bath_level, categorise_bonedry_level

class TestLevelFunctions(unittest.TestCase):

    def test_categorise_slag_level(self):
        self.assertEqual(categorise_slag_level(150), 'Extremely High')
        self.assertEqual(categorise_slag_level(135), 'Very High')
        self.assertEqual(categorise_slag_level(125), 'High')
        self.assertEqual(categorise_slag_level(110), 'Normal')
        self.assertEqual(categorise_slag_level(95), 'Low')
        self.assertEqual(categorise_slag_level(85), 'Very Low')
        self.assertEqual(categorise_slag_level(75), 'Extremely Low')

    def test_categorise_matte_level(self):
        self.assertEqual(categorise_matte_level(80), 'Run Out')
        self.assertEqual(categorise_matte_level(71), 'Very High')
        self.assertEqual(categorise_matte_level(69), 'High')
        self.assertEqual(categorise_matte_level(65), 'Normal')
        self.assertEqual(categorise_matte_level(60), 'Very Low')
        self.assertEqual(categorise_matte_level(50), 'Extremely Low')

    def test_categorise_bath_level(self):
        self.assertEqual(categorise_bath_level(230), 'Extremely High')
        self.assertEqual(categorise_bath_level(210), 'Above Waffle Coolers')
        self.assertEqual(categorise_bath_level(195), 'Very High')
        self.assertEqual(categorise_bath_level(190), 'High')
        self.assertEqual(categorise_bath_level(170), 'Normal')
        self.assertEqual(categorise_bath_level(150), 'Low')

    def test_categorise_bonedry_level(self):
        self.assertEqual(categorise_bonedry_level(130), 'Extremely High')
        self.assertEqual(categorise_bonedry_level(110), 'High')
        self.assertEqual(categorise_bonedry_level(90), 'Normal')
        self.assertEqual(categorise_bonedry_level(50), 'Low')
        

    def test_assign_level_categories(self):
        test_data = {
            'tag1': [150, 135, 95],
            'tag2': [85, 125, 110]
        }
        df = pd.DataFrame(test_data)
        result_df = assign_level_categories(df, ['Extremely Low', 'Very Low', 'Low', 'Normal', 'High', 'Very High', 'Extremely High'], ['tag1', 'tag2'], 'slag')
        
        expected_data = {
        'tag1': [150, 135, 95],
        'tag2': [85, 125, 110],
        'tag1Cat': ['Extremely High', 'Very High', 'Low'],
        'tag2Cat': ['Very Low', 'High', 'Normal']
        }
        expected_df = pd.DataFrame(expected_data)
    
   
        cat_dtype = pd.CategoricalDtype(categories=['Extremely Low', 'Very Low', 'Low', 'Normal', 'High', 'Very High', 'Extremely High'], ordered=True)
        expected_df['tag1Cat'] = expected_df['tag1Cat'].astype(cat_dtype)
        expected_df['tag2Cat'] = expected_df['tag2Cat'].astype(cat_dtype)
    
        pd.testing.assert_frame_equal(result_df, expected_df)

if __name__ == '__main__':
    unittest.main()
