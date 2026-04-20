# -*- coding: utf-8 -*-
"""
BPFStatsFcn Tests
"""
import unittest
import numpy as np
import os
import sys

class BPFStatsTest(unittest.TestCase):
    input_name = '../../../data/inputs1.npy'
    parameter_name = '../../../data/parameters.npy'
    output_name = '../../../data/expectedOutput1.npy'
    
    def setUp(self):
        filepath = os.path.abspath("../../../calculationSupport/python/pythonDeployFolder/BPFstatsFcnCCE.py")
        filepath = filepath[:-18]
        if filepath not in sys.path:
            sys.path.append(filepath)
         
        
    def test_bpf_stats_fcn(self):

        import BPFstatsFcnCCE
        parameter_array = np.load(self.parameter_name, allow_pickle=True)
        input_array = np.load(self.input_name, allow_pickle=True)
        inputs = input_array.item()
        parameters = parameter_array.item()
        parameters['LogName'] = 'pythonCalc'
        parameters['CalculationID'] = 'py001'
        parameters['LogLevel'] = 255
        parameters['CalculationName'] = 'bpf_stats'
        expected_output_array = np.load(self.output_name, allow_pickle=True)
        expected_output = expected_output_array.item()
        [output, error_code] = BPFstatsFcnCCE.bpf_stats(parameters,inputs)
        assert np.allclose([output['C80'][0], output['EstStdev'][0], output['LCL'][0], output['Mean'][0], 
                output['P75'][0], output['UCL'][0], error_code],[expected_output['C80'], expected_output['estStdev'],
                expected_output['LCL'], expected_output['Mean'], expected_output['P75'], expected_output['UCL'], 305], equal_nan=True)
                                                     
    def test_bpf_stats_error1(self):
        import BPFstatsFcnCCE
        parameter_array = np.load(self.parameter_name, allow_pickle=True)
        input_array = np.load(self.input_name, allow_pickle=True)
        inputs = input_array.item()
        inputs['InputSensor'] = [] 
        parameters = parameter_array.item()
        parameters['LogName'] = 'pythonCalc'
        parameters['CalculationID'] = 'py001'
        parameters['LogLevel'] = 255
        parameters['CalculationName'] = 'bpf_stats'
        [output, error_code] = BPFstatsFcnCCE.bpf_stats(parameters,inputs)
        self.assertEqual([output['C80'], output['EstStdev'], output['LCL'], output['Mean'], 
                output['P75'], output['UCL'], error_code], [[], [], [], [], [], [], 248])
        
    def test_bpf_stats_error2(self):
        import BPFstatsFcnCCE
        parameter_array = np.load(self.parameter_name, allow_pickle=True)
        input_array = np.load(self.input_name, allow_pickle=True)
        inputs = input_array.item()
        inputs['InputSensorTimestamps'] = [] 
        parameters = parameter_array.item()
        parameters['LogName'] = 'pythonCalc'
        parameters['CalculationID'] = 'py001'
        parameters['LogLevel'] = 255
        parameters['CalculationName'] = 'bpf_stats'
        [output, error_code] = BPFstatsFcnCCE.bpf_stats(parameters,inputs)
        self.assertEqual([output['C80'], output['EstStdev'], output['LCL'], output['Mean'], 
                output['P75'], output['UCL'], error_code], [[], [], [], [], [], [], 249])
                    

if __name__ == '__main__':
    BPFStatsTest.input_name = '../../../data/inputs1.npy'
    BPFStatsTest.output_name = '../../../data/expectedOutput1.npy'
    unittest.main()   
    BPFStatsTest.input_name = '../../../data/inputs2.npy'
    BPFStatsTest.output_name = '../../../data/expectedOutput2.npy'
    unittest.main()                                                  
    BPFStatsTest.input_name = '../../../data/inputs3.npy'
    BPFStatsTest.output_name = '../../../data/expectedOutput3.npy'
    unittest.main()                                                                                                 