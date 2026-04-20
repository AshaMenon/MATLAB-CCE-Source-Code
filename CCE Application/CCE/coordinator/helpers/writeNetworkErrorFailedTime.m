function writeNetworkErrorFailedTime(calcIDs, failTimes,logger)
    %writeNetworkErrorFailedTime writes data to the
    %cce_NetworkErrorFailTime table, overwriting any times with matching
    %calc ID's

    arguments
        calcIDs (:, 1) string;
        failTimes (:, :) char;
        logger Logger = Logger.empty;
    end

    try
        dbName = fullfile(cce.System.DbFolder, "cce.db");
        if exist(dbName, 'file')
            conn = sqlite(dbName);
        else
            if ~exist(cce.System.DbFolder, 'dir')
                mkdir(cce.System.DbFolder)
            end
            conn = sqlite(dbName, 'create');
        end

        calcIDs = cellstr(calcIDs);
        failTimes = cellstr(failTimes);
        data = [calcIDs, failTimes];
        try
            %First delete all entries with that calc ID
            queryText = "DELETE FROM cce_NetworkErrorFailTime WHERE CalculationID = " + ...
                "'" + data{1} + "'";
            conn.execute(queryText);

            %Add latest network failed time
            conn.insert('cce_NetworkErrorFailTime', ...
                {'CalculationID', 'FailureTime'}, data);
        catch err
            if err.identifier == "database:sqlite:interfaceError" && ...
                    contains(err.message, "no such table")
                queryFID = fopen('create_cce_NetworkErrorFailTime.dsql', 'rt');
                createQueryText = fscanf(queryFID, '%c');
                fclose(queryFID);
                conn.exec(createQueryText); %TODO replace with execute - this will be removed in a future release
                conn.insert('cce_NetworkErrorFailTime', ...
                    {'CalculationID', 'FailureTime'}, data); %TODO replace with sqlwrite - will be removed in a future release
            else
                rethrow(err)
            end
        end
    catch err
        if ~isempty(logger)
            logger.logError("Failed to write dependency ready failed times. Error: ", err.message)
        end
    end

    if exist('conn', 'var')
        conn.close()
    end
end