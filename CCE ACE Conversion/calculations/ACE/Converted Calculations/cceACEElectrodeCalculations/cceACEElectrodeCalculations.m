function [outputs,errorCode] = cceACEElectrodeCalculations(parameters,inputs)

logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

newOutTime = strrep(parameters.OutputTime, "T", " ");
newOutTime = extractBefore(newOutTime, ".");

ExeTime = datetime(newOutTime);

logger.logTrace("Current execution time being used: " + string(ExeTime))

errorCode = cce.CalculationErrorState.Good;

try

    try % Get Parameters
        CMElectrodePerPasteBlock = parameters.CMElectrodePerPasteBlock;
        pasteBlockMaxAdd = parameters.pasteBlockMaxAdd;
        pasteBlockSize = parameters.pasteBlockSize;
        % pasteLimitLower = parameters.PasteLimitLower;
        pasteLimitUpper = parameters.pasteLimitUpper;
        unsmeltedPasteMax = parameters.unsmeltedPasteMax;
        upperRingToContactShoe = parameters.upperRingToContactShoe;
    catch err
        CMElectrodePerPasteBlock = [];
        pasteBlockMaxAdd = [];
        pasteBlockSize = [];
        % pasteLimitLower = parameters.PasteLimitLower;
        pasteLimitUpper = [];
        unsmeltedPasteMax = [];
        upperRingToContactShoe = [];

        logger.logError(err.message)
    end
    try % Calculate average casingToLiquidDistance
        cTlValues1 = inputs.M_CasingToLiquidDistance1(end);
        % if cTlValues1 == 0 throw exception
        cTlValues2 = inputs.M_CasingToLiquidDistance2(end);
        cTlValues3 = inputs.M_CasingToLiquidDistance3(end);
        cTlValues4 = inputs.M_CasingToLiquidDistance4(end);
        valsToAvg = [cTlValues1;cTlValues2;cTlValues3;cTlValues4];
        valsToAvg = rmmissing(valsToAvg);
        casingToLiquidDistanceAvg = mean(valsToAvg);
    catch err
        logger.logError(err.message)
        casingToLiquidDistanceAvg = [];
    end

    % Calculate UpperRingToLiquid
    casingToUpperRing = inputs.M_CasingToUpperRing(end);
    UpperRingtoLiquid = casingToLiquidDistanceAvg - casingToUpperRing;

    %Calculate LiquidPasteLevel
    LiquidPasteLevel = upperRingToContactShoe - UpperRingtoLiquid;

    % Calculate SolidPasteLevelBefore
    casingToSolidPaste = inputs.M_CasingToSolidPaste(end);
    SolidPasteLevelAboveLiquid = casingToLiquidDistanceAvg - casingToSolidPaste;

    % Calculate ExpectedPasteLevelBefore
    ExpectedPasteLevelBefore = LiquidPasteLevel + SolidPasteLevelAboveLiquid/pasteBlockSize * CMElectrodePerPasteBlock;

    % Calculate PasteBlocksToAdd
    if ExpectedPasteLevelBefore > pasteLimitUpper
        PasteBlocksToAdd = 0;
    else
        BlocksAdd = min(pasteBlockMaxAdd, max(0, (pasteLimitUpper - ExpectedPasteLevelBefore) / CMElectrodePerPasteBlock));
        BlocksAdd = min(BlocksAdd, max(0, unsmeltedPasteMax - SolidPasteLevelAboveLiquid / pasteBlockSize));
        PasteBlocksToAdd = round(BlocksAdd);
    end

    if isnan(ExpectedPasteLevelBefore) || isempty(ExpectedPasteLevelBefore)
        PasteBlocksToAdd = nan;
    end

    % Calculate PredictedPasteLevelAfter
    PredictedPasteLevelAfter = LiquidPasteLevel + (SolidPasteLevelAboveLiquid / pasteBlockSize + PasteBlocksToAdd) * CMElectrodePerPasteBlock;

    outputs.UpperRingtoLiquid = UpperRingtoLiquid;
    outputs.LiquidPasteLevel = LiquidPasteLevel;
    outputs.SolidPasteLevelAboveLiquid = SolidPasteLevelAboveLiquid;
    outputs.ExpectedPasteLevelBefore = ExpectedPasteLevelBefore;
    outputs.PasteBlocksToAdd = PasteBlocksToAdd;
    outputs.PredictedPasteLevelAfter = PredictedPasteLevelAfter;

    valTime = inputs.M_CasingToLiquidDistance1Timestamps(end);
    if isdatetime(valTime) && ~ismissing(valTime)
        outputs.Timestamp = valTime;
    else
        outputs.Timestamp = ExeTime;
    end

    outputNames = string(fieldnames(outputs));

    for nOut = 1:length(outputNames)
        curOut = outputs.(outputNames(nOut));

        if isempty(curOut)
            outputs.(outputNames(nOut)) = nan; % Set to nan if output empty
        end
    end
catch err
    outputs.UpperRingtoLiquid = [];
    outputs.LiquidPasteLevel = [];
    outputs.SolidPasteLevelAboveLiquid = [];
    outputs.ExpectedPasteLevelBefore = [];
    outputs.PasteBlocksToAdd = [];
    outputs.PredictedPasteLevelAfter = [];
    outputs.Timestamp = [];
    msg = [err.stack(1).name, ' Line ',...
        num2str(err.stack(1).line), '. ', err.message];

    logger.logError(msg);
    if errorCode == cce.CalculationErrorState.Good || isempty(errorCode)
        errorCode = cce.CalculationErrorState.CalcFailed;
    end
    
end

end

% function output = GetParentElectrodeContext(currentContext)
%  try
%      parentContext = "";
%      splits = strsplit(currentContext,"\");
%      for i = 1:(numel(splits) -1)
%          parentContext = parentContext + splits(i) + "\";
%      end
%      output = extractBefore(parentContext,strlength(parentContext));
%  catch
%      output = "";
%  end
% end

function output = QuickAverage(vals)
try
    numericArray = cellfun(@isnumeric, vals);
    output = mean([vals{numericArray}],2);
catch
    output = [];
end
end

function events = GetValueAtTime(ACETag, ACETagTimes, GetTime, Tol, pTol, Range)

arguments
    ACETag
    ACETagTimes
    GetTime
    Tol
    pTol = 0.25;
    Range = 30;
end

%Need to minus clockdrift, the server adds the drift to the local machine time for data extraction

SearchTime = GetTime;
events = [];

% ACETag.AdjustClockOffset = True;

try

    PIInVals = []; % input values from PI

    try %get input data

        % PIInVals = ACETag.Values(SearchTime - Range - CDbl(ACETag.ClockDrift), SearchTime + Range - CDbl(ACETag.ClockDrift), BoundaryTypeConstants.btInside)
        idx = isbetween(ACETagTimes, SearchTime - seconds(Range), SearchTime + seconds(Range));
        PIInVals.Values = ACETag(idx);
        PIInVals.Times = ACETagTimes(idx);

    catch 
        PIInVals.Values = [];
        PIInVals.Times = [];
    end

    %Dim Res As Double
    ResList.Times = NaT;
    ResList.Values = nan;
    ResList.Diff = nan;

    PIInVals.Diff = seconds(PIInVals.Times - SearchTime);

    %get values meeting time range
    for PIVal = 1:length(PIInVals.Values)
        Diff = seconds(PIInVals.Times(PIVal) - SearchTime);
        if Diff > -Tol && Diff < pTol
            %meets criteria add to match list, if a match with the same tolerance exists discard second
            if ~ismember(ResList.Diff, abs(Diff))
                ResList.Values = [ResList.Values; PIInVals.Values(PIVal)];
                ResList.Times = [ResList.Times; PIInVals.Times(PIVal)];
                ResList.Diff = [ResList.Diff; abs(Diff)];
            end
        end
    end

    if ~isempty(ResList.Diff) % extract best match
        [~, BestDiff] = min(ResList.Diff);
        events.Value = ResList.Values(BestDiff);
        events.Time = ResList.Times(BestDiff);
    end

    events.Value = PIInVals.Values(end);
    events.Time = PIInVals.Times(end);

catch 
    events.Value = [];
    events.Time = [];
end
end
