function lastErr = getLastError(errMessage)
    persistent ignorableExceptionsTbl

    if isempty(ignorableExceptionsTbl)
        dataConnector = af.AFDataConnector(cce.System.CalculationServerName, cce.System.CalculationDBName);
        ignorableExceptionsTbl = dataConnector.getTable("CCEIgnorableExceptions");
    end

    if isIgnorableException(errMessage)
        idx = arrayfun(@(x) contains(errMessage, x, "IgnoreCase",true), ignorableExceptionsTbl.ExceptionMessage);
        idx = find(idx, 1, 'first');

        try
            lastErr = cce.CalculationErrorState.(ignorableExceptionsTbl.LastError(idx));
        catch
            lastErr = cce.CalculationErrorState.UnhandledException;
        end
    else
        lastErr = cce.CalculationErrorState.UnhandledException;
    end
end