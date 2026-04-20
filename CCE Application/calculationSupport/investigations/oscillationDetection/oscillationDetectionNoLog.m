function outputs = oscillationDetectionNoLog(parameters,inputs)
    % OSCILLATIONDETECTION Detect PV reversal oscillations
    %
    % Input:
    %       data: n x 1 double array containing PV data matrix
    %       timestamp: timestamps for PV data matrix
    %       rrCountRef: current rrCount
    %       oscCountRef: current oscCount
    %       parameters: struct with the function parameters
    %
    % Output:
    %       rrCount = number of reversals detected
    %       oscCount = number of reversal oscillations detected
    
    % Log Creation
    logFile = parameters.LogName;
    calculationID = parameters.CalculationID;
    logLevel = parameters.LogLevel;
    calculationName = parameters.CalculationName;
    log = Logger(logFile, calculationName, calculationID,logLevel);
    
    
    try
        % Fixed Variables
        tSample = parameters.TSample;
        fs = parameters.Fs;
        rrWsize = parameters.RRWsize;
        pvThreshold = parameters.PVThreshold;
        tIntegral = parameters.TIntegral;
        Rmax = parameters.Rmax;
        unsteadyInd = [];
        % convert the time format
        % timeStamp = datetime(timeStamp,'ConvertFrom','posixtime');
         % Inputs 
        pv = inputs.PV;
        pvTimeStamp = inputs.PVTimestamps;
        rrCountRef = inputs.RRCount;
        oscCountRef = inputs.OscCount;
        
        if parameters.Fs < 900
            log.logWarning('Fs value below threshold');
        end
        
        %%% Account for execution rate
        if isempty(rrCountRef)|| isempty(oscCountRef)
            outputs.RRCount = rrCount;
            outputs.OscCount = oscCount;
        else
            supervisoryWindowSize = floor(5*Rmax*tIntegral/tSample) + fs/tSample; % as per reversalIndex requirements
            results_timeStamp = pvTimeStamp(supervisoryWindowSize:length(pv));
            results_rrInd = zeros(size(results_timeStamp));
            results_oscInd = zeros(size(results_timeStamp));
            results_pvFilt = zeros(size(results_timeStamp));
            for i = supervisoryWindowSize:length(pv)
                % Calculate reversals
                [~,rrCount,~,oscCount,pvFilt] = reversalIndex(pv(i-supervisoryWindowSize+1:i),tSample,fs,rrWsize,unsteadyInd,pvThreshold,tIntegral,Rmax,'mode','online');
                % Process results
                results_rrInd(i-supervisoryWindowSize+1) = rrCount > rrCountRef;
                outputs.RRCount = rrCount;
                results_oscInd(i-supervisoryWindowSize+1) = oscCount > oscCountRef;
                outputs.OscCount = oscCount;
                results_pvFilt(i-supervisoryWindowSize+1) = pvFilt(end);
            end
        end
    catch err
        outputs.RRCount = NaN;
        outputs.OscCount = NaN;
        log.logError(err.message);
    end
end


