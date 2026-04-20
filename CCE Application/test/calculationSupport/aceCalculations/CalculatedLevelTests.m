classdef CalculatedLevelTests < matlab.unittest.TestCase
    
    properties
        Parameters
        DataTbl1
        DataTbl2
    end
    
    methods (TestMethodSetup)
        function  setup(~)
            testRootFolder = fileparts(mfilename("fullpath"));
            acePath = fullfile(testRootFolder, '..', '..', '..',...
                'calculationSupport', 'calculations', 'aceCalculations');
            addpath(acePath);
            setupAceCalcs;
        end
        
        function setProps(testCase)
            % Load Data
            load([getpref('CCECalcDev', 'DataFolder'), '\AceCalcs\calculatedLevelData1.mat'], 'calculatedLevelPt1Data');
            load([getpref('CCECalcDev', 'DataFolder'), '\AceCalcs\calculatedLevelData2.mat'], 'calculatedData2');
            testCase.DataTbl1 = calculatedLevelPt1Data;
            testCase.DataTbl2 = calculatedData2;
            
            %Parameters
            parameters = struct();
            parameters.LogName = [getpref('CCECalcDev', 'DataFolder'), '\AceCalcs\calculatedLevelTestLog'];
            parameters.CalculationID =  'calcLevel_001';
            parameters.LogLevel =  255;
            parameters.CalculationName =  "Calculated Level";
            testCase.Parameters = parameters;
            
            warning off
        end
    end
    methods (Test)
        function testCalculatedLevel1(testCase)

            %Parameters
            parameters = testCase.Parameters;
            parameters.MeasuredStock1ConvFactor = 1;
            parameters.Surveyed1ConvFactor = 1;
            parameters.Add1ConvFactor = 1;
            parameters.Add2ConvFactor = 1;
            parameters.Add3ConvFactor = 1;
            parameters.Subtract1ConvFactor = 1;
            parameters.Subtract2ConvFactor = 1;
            parameters.PlantMeasures1ConvFactor = 1;
            
            %Inputs
            dataTab = testCase.DataTbl1(2, :);
            prevDataTab = testCase.DataTbl1(1, :);
            
            inputs = struct();
            inputs.MeasuredStock1 = dataTab.MeasuredStock;
            inputs.MeasuredStock1Timestamps = datetime('now');
            inputs.Surveyed1 = dataTab.SurveyedStock;
            inputs.Add1 = dataTab.Add1;
            inputs.Add2 = dataTab.Add2;
            inputs.Add3 = dataTab.Add3;
            inputs.Subtract1 = dataTab.Subtract1;
            inputs.Subtract2 = dataTab.Subtract2;
            inputs.PlantMeasures1 = dataTab.PlantMeasures;
            inputs.PreviousStock = prevDataTab.TheoreticalStock;
            
            %Expected outputs
            expectOut.MeasStock = dataTab.MeasuredStock;
            expectOut.TheorStock = dataTab.TheoreticalStock;
            expectOut.SurveStock = dataTab.SurveyedStock;
          
            
            %Run function
            [outputs, ~] = calculatedLevel(parameters,...
                inputs);
            
            expectOutCell = {expectOut.MeasStock,...
                expectOut.TheorStock,...
                expectOut.SurveStock};
            
            actualOutCell = {outputs.MeasStock,...
                outputs.TheorStock,...
                outputs.SurveStock};
            
            testCase.verifyEqual(expectOutCell, actualOutCell, 'RelTol', 1e-6);
        end
        
        function testCalculatedLevel2(testCase)
            %Parameters
            parameters = testCase.Parameters;
            
            parameters.MeasuredStock1ConvFactor = 1;
            parameters.TheoreticalStock1ConvFactor = 1;
            parameters.SurveyedConvFactor = 1;
            
            parameters.Add1ConvFactor = 1;
            parameters.Add2ConvFactor = 1;
            parameters.Add3ConvFactor = 1;
            parameters.Add4ConvFactor = 1;
            
            parameters.Subtract1ConvFactor = 1;
            parameters.Subtract2ConvFactor = 1;
            parameters.Subtract3ConvFactor = 1;
            parameters.Subtract4ConvFactor = 1;
            parameters.Subtract5ConvFactor = 1;
            parameters.Subtract6ConvFactor = 1;
            
            parameters.Surveyed1ConvFactor = 1;
            parameters.Surveyed2ConvFactor = 1;
            parameters.Surveyed3ConvFactor = 1;
            parameters.Surveyed4ConvFactor = 1;
            parameters.Surveyed5ConvFactor = 1;
            parameters.Surveyed6ConvFactor = 1;
            
            %Inputs
            dataTab = testCase.DataTbl2(2, :);
            prevDataTab = testCase.DataTbl2(1, :);
            
            inputs = struct();
            inputs.MeasuredStock1 = dataTab.MeasuredStock;
            inputs.MeasuredStock1Timestamps = datetime('now');

            inputs.Surveyed1 = dataTab.Surveyed1;
            inputs.Surveyed2 = dataTab.Surveyed2;
            inputs.Surveyed3 = dataTab.Surveyed3;
            inputs.Surveyed4 = dataTab.Surveyed4;
            inputs.Surveyed5 = dataTab.Surveyed5;
            inputs.Surveyed6 = dataTab.Surveyed6;
            
            inputs.Add1 = dataTab.Add1;
            inputs.Add2 = dataTab.Add2;
            inputs.Add3 = dataTab.Add3;
            inputs.Add4 = dataTab.Add4;
            
            inputs.Subtract1 = dataTab.Subtract1;
            inputs.Subtract2 = dataTab.Subtract2;
            inputs.Subtract3 = dataTab.Subtract3;
            inputs.Subtract4 = dataTab.Subtract4;
            inputs.Subtract5 = dataTab.Subtract5;
            inputs.Subtract6 = dataTab.Subtract6;
            
            inputs.PreviousStock = prevDataTab.TheoreticalStock; 
            
            %Expected outputs
            expectOut.MeasStock = dataTab.MeasuredStock;
            expectOut.TheorStock = dataTab.TheoreticalStock;
            expectOut.SurveStock = dataTab.SurveyedStock;
          
            %Run function
            [outputs, ~] = calculatedLevel(parameters,...
                inputs);
            
            expectOutCell = {expectOut.MeasStock,...
                expectOut.TheorStock,...
                expectOut.SurveStock};
            
            actualOutCell = {outputs.MeasStock,...
                outputs.TheorStock,...
                outputs.SurveStock};
            
            testCase.verifyEqual(expectOutCell, actualOutCell, 'RelTol', 1e-6);
        end
        
        function testCalculatedLevelCalcServer(testCase)
            numTimes = 30;
            
            %Parameters
            parameters = testCase.Parameters;
            parameters.MeasuredStock1ConvFactor = 1;
            parameters.Surveyed1ConvFactor = 1;
            parameters.Add1ConvFactor = 1;
            parameters.Add2ConvFactor = 1;
            parameters.Add3ConvFactor = 1;
            parameters.Subtract1ConvFactor = 1;
            parameters.Subtract2ConvFactor = 1;
            parameters.PlantMeasures1ConvFactor = 1;
            
            %Inputs
            dataTab = testCase.DataTbl1(2:end, :);
            prevDataTab = testCase.DataTbl1(1:end - 1, :);
            
            inputsArray = struct();
            inputsArray.MeasuredStock1 = dataTab.MeasuredStock;
            inputsArray.MeasuredStock1Timestamps = dataTab.Time;
            inputsArray.Surveyed1 = dataTab.SurveyedStock;
            inputsArray.Add1 = dataTab.Add1;
            inputsArray.Add2 = dataTab.Add2;
            inputsArray.Add3 = dataTab.Add3;
            inputsArray.Subtract1 = dataTab.Subtract1;
            inputsArray.Subtract2 = dataTab.Subtract2;
            inputsArray.PlantMeasures1 = dataTab.PlantMeasures;
            inputsArray.PreviousStock = prevDataTab.TheoreticalStock;
            
            
            errorCode = zeros(numTimes,1);
            expectedErrorCode = ones(numTimes, 1) * double(cce.CalculationErrorState.Good);
            
            MeasStock_val = nan(numTimes, 1);
            SurveStock_val = nan(numTimes, 1);
            TheorStock_val = nan(numTimes, 1);
            
            hostName = 'ons-mps:9920';
            archive = 'calculatedLevel';
            functionName = 'calculatedLevel';
            numOfOutputs = 2;
            
            for iTimeStamp = 1:numTimes
                %Inputs
                inputs = struct();
                inputs.MeasuredStock1 = inputsArray.MeasuredStock1(iTimeStamp);
                inputs.MeasuredStock1Timestamps = inputsArray.MeasuredStock1Timestamps(iTimeStamp);
                inputs.Surveyed1 = inputsArray.Surveyed1(iTimeStamp);
                inputs.Add1 = inputsArray.Add1(iTimeStamp);
                inputs.Add2 = inputsArray.Add2(iTimeStamp);
                inputs.Add3 = inputsArray.Add3(iTimeStamp);
                inputs.Subtract1 = inputsArray.Subtract1(iTimeStamp);
                inputs.Subtract2 = inputsArray.Subtract2(iTimeStamp);
                inputs.PlantMeasures1 = inputsArray.PlantMeasures1(iTimeStamp);
                inputs.PreviousStock = inputsArray.PreviousStock(iTimeStamp);
                
                %Expected outputs
                functionInputs = {parameters, inputs};
                
                result = callMLProdServer(hostName, archive,...
                    functionName, functionInputs, numOfOutputs);
                
                outputs = result.lhs(1).mwdata;
                errorCode(iTimeStamp) = result.lhs(2).mwdata;
                
                MeasStock_val(iTimeStamp) = outputs.MeasStock.mwdata;
                SurveStock_val(iTimeStamp) = outputs.SurveStock.mwdata;
                TheorStock_val(iTimeStamp) = outputs.TheorStock.mwdata;
            end
            
            expectOut = struct();
            expectOut.MeasStock = dataTab.MeasuredStock;
            expectOut.TheorStock = dataTab.TheoreticalStock;
            expectOut.SurveStock = dataTab.SurveyedStock;
              
            expectOutCell = {expectOut.MeasStock,...
                expectOut.TheorStock,...
                expectOut.SurveStock,...
                expectedErrorCode};
            
            actualOutCell = {MeasStock_val,...
                SurveStock_val,...
                TheorStock_val,...
                errorCode};

            testCase.verifyEqual(expectOutCell,...
                actualOutCell, 'RelTol', 1e-6);
        end
    end
end
