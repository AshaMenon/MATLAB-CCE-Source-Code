%%
outTT = combineSoundingsExample(soundingData);
fields = outTT.Properties.VariableNames;


%%
ax1 = subplot(3,1,1);
title(ax1, "Matte + Build Up")
for idx = 1:10
timeName = "BuildUpSoundingPort" + idx + "Timestamps";
colName1 = "BuildUpSoundingPort" + idx;
colName2 = "MatteSoundingPort" + idx;

    if ~(idx == 9)
        scatter(outTT.Timestamp ,outTT.(colName1) + outTT.(colName2))
        hold on
    end

end
plot(outputs.Timestamp,outputs.NewMeanMattePlusBuildupThickness, '*-k')
xline(outputs.Timestamp(outputs.CombinedValidDeltaSounding))
hold off

ax2 = subplot(3,1,2);
title(ax2, "Slag")
for idx = 1:10
colName1 = "SlagSoundingPort" + idx;

    if ~(idx == 9)
        scatter(outTT.Timestamp ,outTT.(colName1))
        hold on
    end

end
plot(outputs.Timestamp,outputs.NewMeanSlagThickness, '*-k')
xline(outputs.Timestamp(outputs.CombinedValidDeltaSounding))
hold off

ax3 = subplot(3,1,3);
title(ax3, "Concentrate")
for idx = 1:10
colName1 = "ConcentrateSoundingPort" + idx;

    if ~(idx == 9)
        scatter(outTT.Timestamp ,outTT.(colName1))
        hold on
    end

end
plot(outputs.Timestamp,outputs.NewMeanConcThickness, '*-k')
xline(outputs.Timestamp(outputs.CombinedValidDeltaSounding))
hold off


linkaxes([ax1, ax2, ax3], 'x'); % Link the x-axes only