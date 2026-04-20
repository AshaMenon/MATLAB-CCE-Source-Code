classdef ElectrodeCalculationsTests < matlab.unittest.TestCase
    
    properties
        ParameterTbl
        DataTbl
        Parameters
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
            % Load Data & Parameters
            load(fullfile(getpref('CCEPref', 'DataFolder'),'\AceCalcs\electrodeCalculationsParams.mat'), 'parameters');
            testCase.ParameterTbl = parameters;
            parameters = struct();
            parameters.LogName = [getpref('CCEPref', 'DataFolder'), '\AceCalcs\electrodeCalculationsTestLog'];
            parameters.CalculationID =  'elecCalc_001';
            parameters.LogLevel =  255;
            parameters.CalculationName =  "Electrode Calculations";
            testCase.Parameters = parameters;
            
            load([getpref('CCEPref', 'DataFolder'), '\AceCalcs\electrodeCalculationsData.mat'], 'data')
            testCase.DataTbl = data;
            
            warning off
        end
    end
    methods (Test)
        function testElectrodCalculations1(testCase)
            %Slag furnace 1
            %Parameters
            paramsTbl = testCase.ParameterTbl(2:8, :);
            parameters = testCase.Parameters;
            parameters.CMElectrodePerPasteBlock = paramsTbl{paramsTbl{:, 1} == "CMElectrodePerPasteBlock", 2};
            parameters.PasteBlockMaxAdd = paramsTbl{paramsTbl{:, 1} == "PasteBlockMaxAdd", 2};
            parameters.PasteBlockSize = paramsTbl{paramsTbl{:, 1} == "PasteBlockSize", 2};
            parameters.PasteLimitUpper = paramsTbl{paramsTbl{:, 1} == "PasteLimitUpper", 2};
            parameters.UnsmeltedPasteMax = paramsTbl{paramsTbl{:, 1} == "UnsmeltedPasteMax", 2};
            parameters.UpperRingToContactShoe = paramsTbl{paramsTbl{:, 1} == "UpperRingToContactShoe", 2};
            
            %Inputs
            data = testCase.DataTbl(2:15, [1, 3]);
            inputs = struct();
            inputs.CasingToLiquidDistance1 = data{data{:, 1} == "M.CasingToLiquidDistance1", 2};
            inputs.CasingToLiquidDistance2 = data{data{:, 1} == "M.CasingToLiquidDistance2", 2};
            inputs.CasingToLiquidDistance3 = data{data{:, 1} == "M.CasingToLiquidDistance3", 2};
            inputs.CasingToLiquidDistance4 = data{data{:, 1} == "M.CasingToLiquidDistance4", 2};
            inputs.CasingToSolidPaste = data{data{:, 1} == "M.CasingToSolidPaste", 2};
            inputs.CasingToUpperRing = data{data{:, 1} == "M.CasingToUpperRing", 2};
            inputs.CasingToLiquidDistance1Timestamps = datetime(2021, 05, 05, 00, 00, 00);
            
            %Expected outputs
            expectOut.LiquidPasteLevel = data{data{:, 1} == "ACE.LiquidPasteLevel", 2};
            expectOut.SolidPasteLevelAboveLiquid = data{data{:, 1} == "ACE.SolidPasteLevelAboveLiquid", 2};
            expectOut.ExpectedPasteLevelBefore = data{data{:, 1} == "ACE.ExpectedPasteLevelBefore", 2};
            expectOut.PasteBlocksToAdd = data{data{:, 1} == "ACE.PasteBlocksToAdd", 2};
            expectOut.PredictedPasteLevelAfter = data{data{:, 1} == "ACE.PredictedPasteLevelAfter", 2};
            
            %Run function
            [outputs, ~] = electrodeCalculations(parameters,...
                inputs);
            
            expectOutCell = {expectOut.LiquidPasteLevel,...
                expectOut.SolidPasteLevelAboveLiquid,...
                expectOut.ExpectedPasteLevelBefore,...
                expectOut.PasteBlocksToAdd,...
                expectOut.PredictedPasteLevelAfter};
            
            actualOutCell = {outputs.LiquidPasteLevel,...
                outputs.SolidPasteLevelAboveLiquid,...
                outputs.ExpectedPasteLevelBefore,...
                outputs.PasteBlocksToAdd,...
                outputs.PredictedPasteLevelAfter};
            
            testCase.verifyEqual(expectOutCell, actualOutCell, 'RelTol', 1e-6);
        end
        
        function testElectrodCalculations2(testCase)
            %Furnace 2
            
            %Parameters
            paramsTbl = testCase.ParameterTbl(10:16, :);
            parameters = testCase.Parameters;
            parameters.CMElectrodePerPasteBlock = paramsTbl{paramsTbl{:, 1} == "CMElectrodePerPasteBlock", 2};
            parameters.PasteBlockMaxAdd = paramsTbl{paramsTbl{:, 1} == "PasteBlockMaxAdd", 2};
            parameters.PasteBlockSize = paramsTbl{paramsTbl{:, 1} == "PasteBlockSize", 2};
            parameters.PasteLimitUpper = paramsTbl{paramsTbl{:, 1} == "PasteLimitUpper", 2};
            parameters.UnsmeltedPasteMax = paramsTbl{paramsTbl{:, 1} == "UnsmeltedPasteMax", 2};
            parameters.UpperRingToContactShoe = paramsTbl{paramsTbl{:, 1} == "UpperRingToContactShoe", 2};
            
            %Inputs
            data = testCase.DataTbl(47:60, [1, 3]);
            inputs = struct();
            inputs.CasingToLiquidDistance1 = data{data{:, 1} == "M.CasingToLiquidDistance1", 2};
            inputs.CasingToLiquidDistance2 = data{data{:, 1} == "M.CasingToLiquidDistance2", 2};
            inputs.CasingToLiquidDistance3 = data{data{:, 1} == "M.CasingToLiquidDistance3", 2};
            inputs.CasingToLiquidDistance4 = data{data{:, 1} == "M.CasingToLiquidDistance4", 2};
            inputs.CasingToSolidPaste = data{data{:, 1} == "M.CasingToSolidPaste", 2};
            inputs.CasingToUpperRing = data{data{:, 1} == "M.CasingToUpperRing", 2};
            inputs.CasingToLiquidDistance1Timestamps = datetime(2021, 05, 05, 00, 00, 00);
            
            %Expected outputs
            expectOut.LiquidPasteLevel = data{data{:, 1} == "ACE.LiquidPasteLevel", 2};
            expectOut.SolidPasteLevelAboveLiquid = data{data{:, 1} == "ACE.SolidPasteLevelAboveLiquid", 2};
            expectOut.ExpectedPasteLevelBefore = data{data{:, 1} == "ACE.ExpectedPasteLevelBefore", 2};
            expectOut.PasteBlocksToAdd = data{data{:, 1} == "ACE.PasteBlocksToAdd", 2};
            expectOut.PredictedPasteLevelAfter = data{data{:, 1} == "ACE.PredictedPasteLevelAfter", 2};
            
            
            %Run function
            [outputs, ~] = electrodeCalculations(parameters,...
                inputs);
            
            expectOutCell = {expectOut.LiquidPasteLevel,...
                expectOut.SolidPasteLevelAboveLiquid,...
                expectOut.ExpectedPasteLevelBefore,...
                expectOut.PasteBlocksToAdd,...
                expectOut.PredictedPasteLevelAfter};
            
            actualOutCell = {outputs.LiquidPasteLevel,...
                outputs.SolidPasteLevelAboveLiquid,...
                outputs.ExpectedPasteLevelBefore,...
                outputs.PasteBlocksToAdd,...
                outputs.PredictedPasteLevelAfter};
            
            testCase.verifyEqual(expectOutCell, actualOutCell, 'RelTol', 1e-6);
        end
        
        function testElectroCalculationsCalcServer(testCase)
            numTimes = 7;
            errorCode = zeros(numTimes,1);
            expectedErrorCode = ones(numTimes, 1) * double(cce.CalculationErrorState.Good);
            liquidPasteLevel_val = nan(numTimes, 1);
            solidPasteLevelAboveLiquid_val = nan(numTimes, 1);
            expectedPasteLevelBefore_val = nan(numTimes, 1);
            pasteBlocksToAdd_val = nan(numTimes, 1);
            predictedPasteLevelAfter_val = nan(numTimes, 1);
            
            hostName = 'ons-mps:9920';
            archive = 'electrodeCalculations';
            functionName = 'electrodeCalculations';
            numOfOutputs = 2;
            
            %Parameters
            paramsTbl = testCase.ParameterTbl(2:8, :);
            parameters = testCase.Parameters;
            parameters.CMElectrodePerPasteBlock = paramsTbl{paramsTbl{:, 1} == "CMElectrodePerPasteBlock", 2};
            parameters.PasteBlockMaxAdd = paramsTbl{paramsTbl{:, 1} == "PasteBlockMaxAdd", 2};
            parameters.PasteBlockSize = paramsTbl{paramsTbl{:, 1} == "PasteBlockSize", 2};
            parameters.PasteLimitUpper = paramsTbl{paramsTbl{:, 1} == "PasteLimitUpper", 2};
            parameters.UnsmeltedPasteMax = paramsTbl{paramsTbl{:, 1} == "UnsmeltedPasteMax", 2};
            parameters.UpperRingToContactShoe = paramsTbl{paramsTbl{:, 1} == "UpperRingToContactShoe", 2};
            
            data = testCase.DataTbl(2:15, :);
            CasingToLiquidDistance1Idx = data{:, 1} == "M.CasingToLiquidDistance1";
            CasingToLiquidDistance2Idx = data{:, 1} == "M.CasingToLiquidDistance2";
            CasingToLiquidDistance3Idx = data{:, 1} == "M.CasingToLiquidDistance3";
            CasingToLiquidDistance4Idx = data{:, 1} == "M.CasingToLiquidDistance4";
            CasingToSolidPasteIdx = data{:, 1} == "M.CasingToSolidPaste";
            CasingToUpperRingIdx = data{:, 1} == "M.CasingToUpperRing";
            
            for iTimeStamp = 1:numTimes
                %Inputs
                inputs = struct();
                inputs.CasingToLiquidDistance1 = data{CasingToLiquidDistance1Idx, 2 + iTimeStamp};
                inputs.CasingToLiquidDistance2 = data{CasingToLiquidDistance2Idx, 2 + iTimeStamp};
                inputs.CasingToLiquidDistance3 = data{CasingToLiquidDistance3Idx, 2 + iTimeStamp};
                inputs.CasingToLiquidDistance4 = data{CasingToLiquidDistance4Idx, 2 + iTimeStamp};
                inputs.CasingToSolidPaste = data{CasingToSolidPasteIdx, 2 + iTimeStamp};
                inputs.CasingToUpperRing = data{CasingToUpperRingIdx, 2 + iTimeStamp};
                inputs.CasingToLiquidDistance1Timestamps = datetime(2021, 05, 05, 00, 00, 00);
                
                %Expected outputs
                functionInputs = {parameters, inputs};
                
                result = callMLProdServer(hostName, archive,...
                    functionName, functionInputs, numOfOutputs);
                
                outputs = result.lhs(1).mwdata;
                errorCode(iTimeStamp) = result.lhs(2).mwdata;
                liquidPasteLevel_val(iTimeStamp) = outputs.LiquidPasteLevel.mwdata;
                solidPasteLevelAboveLiquid_val(iTimeStamp) = outputs.SolidPasteLevelAboveLiquid.mwdata;
                expectedPasteLevelBefore_val(iTimeStamp) = outputs.ExpectedPasteLevelBefore.mwdata;
                pasteBlocksToAdd_val(iTimeStamp) = outputs.PasteBlocksToAdd.mwdata;
                predictedPasteLevelAfter_val(iTimeStamp) = outputs.PredictedPasteLevelAfter.mwdata;
            end
            
            expectOut = struct();
            expectOut.LiquidPasteLevel = data{data{:, 1} == "ACE.LiquidPasteLevel", 3:2 + numTimes};
            expectOut.SolidPasteLevelAboveLiquid = data{data{:, 1} == "ACE.SolidPasteLevelAboveLiquid", 3:2 + numTimes};
            expectOut.ExpectedPasteLevelBefore = data{data{:, 1} == "ACE.ExpectedPasteLevelBefore", 3:2 + numTimes};
            expectOut.PasteBlocksToAdd = data{data{:, 1} == "ACE.PasteBlocksToAdd", 3:2 + numTimes};
            expectOut.PredictedPasteLevelAfter = data{data{:, 1} == "ACE.PredictedPasteLevelAfter", 3:2 + numTimes};
            
            expectOutCell = {expectOut.LiquidPasteLevel',...
                expectOut.SolidPasteLevelAboveLiquid',...
                expectOut.ExpectedPasteLevelBefore',...
                expectOut.PasteBlocksToAdd',...
                expectOut.PredictedPasteLevelAfter',...
                expectedErrorCode};
            
            actualOutCell = {liquidPasteLevel_val,...
                solidPasteLevelAboveLiquid_val,...
                expectedPasteLevelBefore_val,...
                pasteBlocksToAdd_val,...
                predictedPasteLevelAfter_val,...
                errorCode};
            
            
            testCase.verifyEqual(expectOutCell,...
                actualOutCell, 'RelTol', 1e-6);
        end
    end
end
