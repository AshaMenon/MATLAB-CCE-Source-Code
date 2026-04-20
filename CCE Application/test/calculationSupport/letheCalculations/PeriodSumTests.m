classdef PeriodSumTests < matlab.unittest.TestCase
    
    properties
        DataTb1
        Parameters
    end
    
    methods (TestMethodSetup)
        function  setup(~)
            testRootFolder = fileparts(mfilename("fullpath"));
            lethePath = fullfile(testRootFolder, '..', '..', '..',...
                'calculationSupport', 'calculations', 'lethe');
            addpath(lethePath);
            setupLetheCalcs;
        end
        
        function setProps(testCase)
            % Load Data & Parameters
            parameters = struct();
            parameters.CalculationName = "Period Sum";
            parameters.CalculationID = "PeriodSum01";
            parameters.LogName = 'data\LetheCalcs\periodSumLog';
            parameters.LogLevel = 255;
            
            parameters.RollupInputs = "SumInput";
            parameters.ForceToZero = false;
            
            testCase.Parameters = parameters;
            
            load('LetheCalcs\periodSum\periodSumInputs.mat', 'dataTab1')
            testCase.DataTb1 = dataTab1;
            warning off
        end
    end
    methods (Test)
        function testPeriodSum1(testCase)
            %Parameters
            parameters = testCase.Parameters;
            
            %Inputs
            data1 = testCase.DataTb1(1, :);
            inputs = struct();
            
            inputs.SumInput1 = data1.Input;
            inputs.SumInput2 = data1.UG21;
            inputs.SumInput3 = data1.UG22;
            inputs.SumInput1Timestamps = datetime('now');
            
            %Expected outputs
            expectOut.Aggregate = data1.Aggregate;
            
            %Run function
            [outputs, ~] = periodSum(parameters,...
                inputs);
            
            expectOutCell = {expectOut.Aggregate};
            actualOutCell = {empty2nan(outputs.Aggregate)};
            
            testCase.verifyEqual(expectOutCell, actualOutCell, 'RelTol', 1e-6);
        end
        
        function testPeriodSum2(testCase)
            %Parameters
            parameters = testCase.Parameters;
            
            %Inputs
            data1 = testCase.DataTb1(2, :);
            inputs = struct();
            
            inputs.SumInput1 = data1.Input;
            inputs.SumInput2 = data1.UG21;
            inputs.SumInput3 = data1.UG22;
            inputs.SumInput1Timestamps = datetime('now');
            
            %Expected outputs
            expectOut.Aggregate = data1.Aggregate;
            
            %Run function
            [outputs, ~] = periodSum(parameters,...
                inputs);
            
            expectOutCell = {expectOut.Aggregate};
            actualOutCell = {empty2nan(outputs.Aggregate)};
            
            testCase.verifyEqual(expectOutCell, actualOutCell, 'RelTol', 1e-6);
        end
        
        function testPeriodSumCalcServer(testCase)
            numTimes = 18;
            errorCode = zeros(numTimes, 1);
            expectedErrorCode = ones(numTimes, 1) * double(cce.CalculationErrorState.Good);           
            
            hostName = 'ons-opcdev:9910';
            archive = 'periodSum';
            functionName = 'periodSum';
            numOfOutputs = 2;
            
            %Parameters
            parameters = testCase.Parameters;
            
            %Inputs
            data1 = testCase.DataTb1;
            
            for iTimeStamp = 1:numTimes
                %Inputs
                inputs = struct();
                inputs.SumInput1 = data1.Input(iTimeStamp);
                inputs.SumInput2 = data1.UG21(iTimeStamp);
                inputs.SumInput3 = data1.UG22(iTimeStamp);
                inputs.SumInput1Timestamps = datetime('now');
                
                %Outputs
                functionInputs = {parameters, inputs};
                
                result = callMLProdServer(hostName, archive,...
                    functionName, functionInputs, numOfOutputs);
                
                outputs = result.lhs(1).mwdata;
                errorCode(iTimeStamp) = result.lhs(2).mwdata;
                aggregateVal(iTimeStamp) = empty2nan(outputs.Aggregate.mwdata);
            end
            
            expectOut = struct();
            %Expected outputs
            expectOut.Aggregate = data1.Aggregate;
            
            expectOutCell = {expectOut.Aggregate';
                expectedErrorCode};
            
            actualOutCell = {aggregateVal;
                errorCode};
            
            testCase.verifyEqual(expectOutCell,...
                actualOutCell, 'RelTol', 1e-6);
        end
        
    end
end
