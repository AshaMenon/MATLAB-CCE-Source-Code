function lastFailedTime = getNetworkFailedTime(calcID)
    %GETCHECKFAILEDTIME finds the first time that the calculation failed
    
    dbName = fullfile(cce.System.DbFolder, "cce.db");
    %If the database doesn't exist in this location, it means that no errors have been
    %found to now, and so there is no prior failed time
    if ~exist(dbName, 'file')
        lastFailedTime = NaT;
        return
    end
    
    conn = sqlite(dbName);
    
    queryFID = fopen('lastNetworkErrorCheckTime.dsql', 'rt');
    queryText = fscanf(queryFID, '%c');
    fclose(queryFID);
    placeHolders = {'%CALCULATIONID%'};
    actualStrings = {calcID};
    queryText = cce.replaceTextPlaceHolders(queryText, placeHolders, actualStrings);
    
    results = conn.fetch(queryText);
    results = results{:, :};
    if ~isempty(results)
        lastFailedTime = datetime(results);
    else
        lastFailedTime = NaT;
    end
    
    conn.close();
end