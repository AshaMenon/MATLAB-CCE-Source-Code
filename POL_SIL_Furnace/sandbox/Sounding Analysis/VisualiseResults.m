buildUpIdx = contains(dataTT.Properties.VariableNames, "BuildUp");
concIdx = contains(dataTT.Properties.VariableNames, "Concentrate");
matteIdx = contains(dataTT.Properties.VariableNames, "Matte");
slagIdx = contains(dataTT.Properties.VariableNames, "Slag");
matteBuildIdx = contains(dataTT.Properties.VariableNames, "Matte+BuildUp");

scatter(outputs.Timestamp, outputs.NewMeanMattePlusBuildupThickness)
hold on
scatter(outputs.Timestamp, outputs.NewMeanSlagThickness)
scatter(outputs.Timestamp, outputs.NewMeanConcThickness)
grid on

scatter(dataTT.Timestamp, dataTT(:, matteBuildIdx))
hold on
scatter(dataTT.Timestamp, dataTT(:, slagIdx))
scatter(dataTT.Timestamp, dataTT(:, concIdx))
grid on
hold off

hold off