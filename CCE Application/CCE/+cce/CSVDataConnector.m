classdef CSVDataConnector < handle
    %CSVDataConnector Implement the data connections for a CSV serialiser
    %   Provides infrastructure to write tables as CSV files.  The table must have a "CoordinatorID" column.
    %
    %   DC = CSVDataConnector(FolderPath, RecordType) creates a persistent storage area using the
    %   pre-existing folder FolderPath. Each file is saved as the name "RecordType".
    
    properties (SetAccess = private)
        FolderPath (1,1) string
        RecordType (1,1) string
    end
    
    methods
        function obj = CSVDataConnector(folderPath, recordType)
            % Constructor
            arguments
                folderPath (1,1) string = tempname % Deferred default tempname
                recordType (1,1) string = "Record"
            end
            if ~exist(folderPath, "dir")
                % Automatically create the folder if it doesn't exist. Issue a warning.
                warning("cce:CSVDataConnector:FolderCreated", "%s\n%s", ...
                    "Folder path '" + folderPath + "' could not be found. Creating the path.");
                mkdir(folderPath);
                disp(sprintf('<a href="matlab:rmdir(''%s'',''s'');disp(''Folder removed.'')">Remove the folder</a> if this is a mistake.', ...
                    folderPath)); %#ok<DSPS>
            end
            obj.FolderPath = folderPath;
            obj.RecordType = recordType;
        end
        
        function tf = recordExists(obj, id)
            tf = exist(makeFileName(obj, id), "file") > 0;
        end
        function fileName = writeRecord(obj, record)
            arguments
                obj
                record (1,:) table {mustHaveField(record, "CoordinatorID")}
            end
            fileName = makeFileName(obj, record.CoordinatorID);
            writetable(record, fileName);
        end
        function tbl = readRecord(obj, id)
            if recordExists(obj, id)
                tbl = readtable(makeFileName(obj, id));
            else
                error("cce:CSVDataConnector:RecordNotFound", ...
                    "Cannot find record %d in database.", id);
            end
        end
        function ids = findRecords(obj)
            dirList = dir(fullfile(obj.FolderPath, obj.RecordType + "*.csv"));
            if isempty(dirList)
                ids = [];
            else
                ids = arrayfun(@(d)uint32(str2double(d.name(strlength(obj.RecordType)+1:end-4))), dirList, "UniformOutput",true);
            end
        end
        function removeRecord(obj, id)
            %removeRecord  Remove a record from the CSV Database
            fName = makeFileName(obj, id);
            if exist(fName, "file")
                delete(fName);
            end
        end
    end
    methods (Access = private)
        function fileName = makeFileName(obj, id)
            fileName = fullfile(obj.FolderPath, obj.RecordType + id + ".csv");
        end
    end
end

function mustHaveField(tbl, fieldName)
    mustBeMember(fieldName, tbl.Properties.VariableNames);
end