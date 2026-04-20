function outputs = calcSoundingValues(dataTT, parameters)

dataTT = calculateValidSoundingAverages(dataTT, parameters);
newColIdx = contains(dataTT.Properties.VariableNames, 'NewMean');
rowsInvalid = sum(ismissing(dataTT(:, newColIdx), NaN),2)>0;
dataTT(rowsInvalid, :) = [];
dataTT.Timestamp = dateshift(dataTT.Timestamp, 'end', 'minute');

returnStartTime = parameters.exeTime - minutes(parameters.ExecutionFrequencyParam);
returnEndTime = parameters.exeTime;

dataTT = retime(dataTT, returnStartTime:minutes(1):returnEndTime, 'fillwithmissing');


returnIdx = returnStartTime < dataTT.Timestamp &  dataTT.Timestamp <= returnEndTime;

outputs = struct();
outputs.Timestamp = dataTT.Timestamp(returnIdx);
outputs.NewMeanMattePlusBuildupThickness = dataTT.NewMeanMattePlusBuildupThickness(returnIdx);
outputs.NewMeanSlagThickness = dataTT.NewMeanSlagThickness(returnIdx);
outputs.NewMeanConcThickness = dataTT.NewMeanConcThickness(returnIdx);
outputs.NewMeanTotalLiquidThickness = dataTT.NewMeanTotalLiquidThickness(returnIdx);
outputs.IsValidDeltaMatte = dataTT.IsValidDeltaMatte(returnIdx);
outputs.IsValidDeltaSlag = dataTT.IsValidDeltaSlag(returnIdx);
outputs.IsValidDeltaConc = dataTT.IsValidDeltaConc(returnIdx);
outputs.CombinedValidDeltaSounding = dataTT.CombinedValidDeltaSounding(returnIdx);

end