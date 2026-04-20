function writeDependenciesReadyFailedTime(calcIDs, outputTimes, failTimes, logger)
    %WRITEDEPENDENCIESREADYFAILEDTIME writes data to the cce_FailedDependenciesReady table
    %on the sqlite database (cce.db)
    %
    % WRITEDEPENDENCIESREADYFAILEDTIME(CALCIDS, OUTPUTTIMES, FAILTIMES) write the time
    % that the Calculation (CALCIDS) failed the dependencies ready check (dependent inputs
    % don't have data available for the Calculation OUTPUTTIME) FAILTIMES, for the
    % OUTPUTTIMES to the cce_FailedDependenciesReady

    arguments
        calcIDs (:, 1) string;
        outputTimes (:, :) char;
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
        outputTimes = cellstr(outputTimes);
        failTimes = cellstr(failTimes);
        data = [calcIDs, outputTimes, failTimes];
        try
            conn.insert('cce_FailedDependenciesReady', ...
                {'CalculationID', 'OutputTime', 'FailureTime'}, data);
        catch err
            if err.identifier == "database:sqlite:interfaceError" && ...
                    contains(err.message, "no such table")
                queryFID = fopen('create_cce_FailedDependenciesReady.dsql', 'rt');
                createQueryText = fscanf(queryFID, '%c');
                fclose(queryFID);
                conn.exec(createQueryText); %TODO replace with execute - this will be removed in a future release
                conn.insert('cce_FailedDependenciesReady', ...
                    {'CalculationID', 'OutputTime', 'FailureTime'}, data); %TODO replace with sqlwrite - will be removed in a future release
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