classdef runTestData
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties
        TestConfigPath {string} = "C:\Temp\OPMEventDetection\pcaData_modelEvalData\";
        TestDataConfigurationFileName {string} = "POLSFCE1FlankerL2PCA_L.csv";
        TestDataFileName {string} = "data_POLSFCE1FlankerL2PCA_L20000.csv";
        TestConfigFilePath {string} = TestConfigPath & TestDataConfigurationFileName;
        TestDataFilePath {string} = TestConfigPath & TestDataFileName;
        TestResultPath {string} = TestConfigPath & "RunResultsL\";
        TestDataEventHistoryPath {string} = TestResultPath & "History" & TestDataFileName;
        TestDataResult {string} = TestResultPath & "Result" & TestDataFileName;
        timestepSeconds {integer} = 10;
        TestStartFromDate {dateTime} = DateTime("2016-06-01 06:00:00");
    end

    methods
        function obj = untitled(inputArg1,inputArg2)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end

        function Lines = testFileLines(TestDataFilePath)
            % Get all text data corresponding to the provided column names
            try
               Lines = extractFileText(TestDataFilePath);
            catch
                 throw("The test data file could not be read")
            end
        end

        function ConvertRowtoAndUpdateAFAttributes(CalcTime, TagAttList, RowData)
            input = strsplit(RowData.Split,",");

          for id = 1:numel(input)

            if ismember(string(id),TagAttList)

                nVal.Value = input(id);
                nVal.Timestamp = CalcTime;

                % TagAttList(id.ToString).SetValue(nVal)

            end 

          end
        end
    end
end