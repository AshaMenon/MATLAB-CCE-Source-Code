function [outputs,errorCode] = cceACEEventDetection(parameters,inputs)


    logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime);

    errorCode = cce.CalculationErrorState.Good;

    logger.logTrace("Current execution time being used: " + string(ExeTime))

    try
        paramFile = strcat(parameters.OPMAnalysisName,".csv");
        % paramFileData = readtable("D://OPMEventDetection//" + paramFile);
        % vars = paramFileData.Properties.VariableNames;
        % paramFileData = convertvars(paramFileData,vars,'string');
        % paramFileData = paramFileData{:,:};
        fid = fopen("D://OPMEventDetection//" + paramFile);
        paramFileData = textscan(fid,"%s");
        paramFileData = paramFileData{1,1};
        CalcParam = fileRead(paramFileData);

        inputFields = string(fieldnames(inputs));
        inputFields(contains(inputFields,"Timestamps")) = [];

        eventTags = inputFields(contains(inputFields,"Event"));
        rawMeanTags = inputFields(contains(inputFields,"RawMean"));
        sigmaTags = inputFields(contains(inputFields,"Sigma"));
        waterTags = inputFields(contains(inputFields,"WaterTag"));

        TagsRaw = rawMeanTags;
        Tags = TagsRaw;

        %If dt Then modify tag names and load water tags?
        try
            if CalcParam.calcExpression == "dt"
                Tags = TagsRaw;
            else
                Tags = waterTags;
            end
        catch
            CalcParam.calcExpression = "dt";
        end

        %%

        afDTVal = zeros(length(rawMeanTags),1);
        if CalcParam.calcExpression == "dt"
            for n=1:length(rawMeanTags)
                val1 = inputs.(rawMeanTags(n))(1);
                val2 = inputs.(waterTags(n))(1);

                if isempty(val1) || isnan(val1)
                    val1 = 0;
                end

                if isempty(val2) || isnan(val2)
                    val2 = 0;
                end
                afDTVal(n) = val1-val2;
            end
        else
            for n=1:length(rawMeanTags)
                val = inputs.(rawMeanTags(n))(1);

                if isempty(val) || isnan(val)
                    val = 0;
                end

                afDTVal(n) = val;
            end
        end

        afrawVal = zeros(length(Tags),1);
        for n=1:length(Tags)
            afrawVal(n) = inputs.(Tags(n))(1);
        end


        %%
        rawDTVals = afDTVal;

        rawRawVals = afrawVal;

        %normalize data = value - mean/std
        NormalVals = rawDTVals - double(CalcParam.pcaRefMean')./double(CalcParam.pcaRefStd');

        for n= 1:size(NormalVals,2)
            NormalVals(isnan(NormalVals(:,n)),n) = 0;
        end

        % reduce EigenVectores with the principle components. number Columns = number_PC
        %PCscore_EigenVector = CalcParam.pcaRefEigenvectors.SubMatrix(0, (CalcParam.pcaRefEigenvectors), 0, double(CalcParam.num_pcs(1)));
        PCscore_EigenVector = double(CalcParam.pcaRefEigenvectors);

        for n= 1:size(PCscore_EigenVector,2)
            PCscore_EigenVector(isnan(PCscore_EigenVector(:,n)),n) = 0;
        end

        PCscore_EigenVector = reshape(PCscore_EigenVector,length(NormalVals),length(NormalVals));
        %Calculate Scores, reduce columns of eigenvectors to = number of principle components no_PC
        ScoreVales = NormalVals'*(PCscore_EigenVector);

        for n= 1:size(ScoreVales,2)
            ScoreVales(isnan(ScoreVales(:,n)),n) = 0;
        end

        %reconstruct data
        reconstrucVales = ScoreVales*(PCscore_EigenVector');

        for n= 1:size(reconstrucVales,2)
            reconstrucVales(isnan(reconstrucVales(:,n)),n) = 0;
        end

        %Calculate residuals
        residualVals = NormalVals-reconstrucVales';

        for n= 1:size(residualVals,2)
            residualVals(isnan(residualVals(:,n)),n) = 0;
        end

        %Calc SPE result should have 1 row
        SPE = sum(residualVals.^(2),"omitmissing");

        %Calc T²
        %reduce Eigen values to principle components
        %PC_pcaRefEigenvalues = CalcParam.pcaRefEigenvalues.SubMatrix(0, CalcParam.num_pcs.Item(0, 0), 0, 1).Transpose;
        PC_pcaRefEigenvalues = double(CalcParam.pcaRefEigenvalues)';
        T2 = sum((ScoreVales.^(2))./PC_pcaRefEigenvalues,"all","omitmissing");

        SPEtolimits = CheckHi(SPE, double(CalcParam.ssresidualslim_S(1)), double(CalcParam.ssresidualslim_S(end)));
        T2tolimits = CheckHi(T2, double(CalcParam.tsquareCL_S(1)), double(CalcParam.tsquareCL_S(end)));

        Event_RunState = min([SPEtolimits; T2tolimits]);
        outputs.Event = Event_RunState;
        outputs.EventInt = Event_RunState;

        SigmaExceded = false(length(rawRawVals),1);

        for nn =1:length(rawRawVals)
            %
            % check direction: Direction = CalcDirection.negative

            if ChecktoCalcDirection(rawRawVals(nn), double(CalcParam.nRawSigma_S(nn)), CalcParam.eventDirection) && Event_RunState == 2
                SigmaExceded(nn) = true;
            end

        end

        tagsOutofSigmaCount = nnz(SigmaExceded==true);

        if tagsOutofSigmaCount > 0
            if Event_RunState ~= 1
                Event_RunState = 1;
            end
            ActiveTagsCount = tagsOutofSigmaCount;
            ActiveTags = double(strjoin(string(find(SigmaExceded==true)),"0"));
        else
            ActiveTagsCount = 0;
            ActiveTags = nan;
        end

        if Event_RunState == 0
            outputs.EventActive = 0;
        else
            outputs.EventActive = 1;
        end

        outputs.EventActiveInt = outputs.EventActive;

        outputs.Timestamp = ExeTime;
        outputs.ActiveTags = ActiveTags;
        outputs.ActiveTagsCount = ActiveTagsCount;
        outputs.Active = nan;

        %%
        outputNames = string(fieldnames(outputs));

        for nOut = 1:length(outputNames)
            curOut = outputs.(outputNames(nOut));

            if isempty(curOut)
                outputs.(outputNames(nOut)) = nan; % Set to nan if output empty
            end
        end

    catch err
        outputs.Event = 0;  % Alarm state
        outputs.EventActiveInt = 0;  % OPMEventActive
        outputs.ActiveTagsCount = nan;  % Number of active events
        outputs.EventActive = 0;   % On or off
        outputs.ActiveTags = nan;
        outputs.EventInt = 0;
        outputs.Active = nan;
        outputs.Timestamp = ExeTime;

        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];

        logger.logError(msg);
        if errorCode == cce.CalculationErrorState.Good || isempty(errorCode)
            errorCode = cce.CalculationErrorState.CalcFailed;
        end
    end
end

function out = CheckHi(Val, hi, hihi)
    if isnan(Val)
        out = CalcError;
    else
        if Val > hihi
            out = 2; %HiHi;
        elseif Val > hi
            out = 1; %Hi;
        else
            out = 0; %NoAlarm; %this event state is not carried through to the final output
        end
    end
end

function out = ChecktoCalcDirection(Raw, Raw_Sigma, CalDirection)

    switch lower(CalDirection)
        case "negative"
            out = Raw < Raw_Sigma;
        case "both"
            out = (Raw > Raw_Sigma) || (Raw < Raw_Sigma);
        otherwise % default and positive direction
            out = Raw > Raw_Sigma;
    end
end

function out = CheckForChaneg(oldVal, newVal)

    if oldVal ~= newVal
        out = true;
    else
        out = false;
    end

end