dataTT = table2timetable(readtable("data\POL_SIL_Data_20241107_2024AugData.xlsx"));
dataTT.Properties.DimensionNames{1} = 'Timestamp';

%% Smaller dataset for easier visualisation
MINS_PER_WEEK = 60 * 24 * 7;
dataTT1Wk = dataTT(1:MINS_PER_WEEK, :);


%% Investigate Offgas SO2 percentage, flow rate, and total SO2 vs Power
offgasSo2TonPerHr = calcOffgasSo2TonPerHr(dataTT.OffgasSO2Percent, dataTT.OffgasFlowRateNormalM3PerHr);
matteFallFractions = calcMatteFallFractionsAve(dataTT, 3, 24);


figure
tiledlayout(5, 1)

ax1 = nexttile;
plot(dataTT.Timestamp, dataTT.PowerMw)
title("Power (MW)")

ax5 = nexttile;
plot(dataTT.Timestamp, matteFallFractions)
title("Matte fall fraction")

ax2 = nexttile;
plot(dataTT.Timestamp, dataTT.OffgasSO2Percent)
ylim([0, 2.5])
title("Offgas SO2 %")

ax3 = nexttile;
plot(dataTT.Timestamp, dataTT.OffgasFlowRateNormalM3PerHr)
title("Offgas flow rate (Nm^3/hr)")



ax4 = nexttile;
plot(dataTT.Timestamp, offgasSo2TonPerHr)
ylim([0, 150])
title("Offgas SO2 flow rate (ton/hr)")

linkaxes([ax1 ax2 ax3 ax4 ax5], 'x')


%% Data Cleaning
% clip
SO2_MAX_PERCENT = 3; 
dataTT1Wk.OffgasSO2Percent(dataTT1Wk.OffgasSO2Percent > 3) = 3;
offgasSo2OneWkCleanedTonPerHr = dataTT1Wk.OffgasSO2Percent .* dataTT1Wk.OffgasFlowRateNormalM3PerHr;

%% 
rho_matteFallFract_to_so2Percent = corr(matteFallFractions(1:MINS_PER_WEEK), dataTT1Wk.OffgasSO2Percent)
rho_matteFallFract_to_offgasFlow = corr(matteFallFractions(1:MINS_PER_WEEK), dataTT1Wk.OffgasFlowRateNormalM3PerHr)
rho_matteFallFract_to_so2Flow = corr(matteFallFractions(1:MINS_PER_WEEK), offgasSo2OneWkCleanedTonPerHr)
%%
figure
tiledlayout(2, 1)
ax1 = nexttile;
plot(dataTT.Timestamp, offgasSo2TonPerHr)
title("Offgas SO2")
ax2 = nexttile;
plot(dataTT.Timestamp, dataTT.PowerMw)
title("Power")
linkaxes([ax1 ax2], 'x')

%% Investigate vs matte fall fraction
matteFallFractions = calcMatteFallFractionsAve(dataTT, 3, 24);
figure
plot(offgasSo2TonPerHr, matteFallFractions, 'o')
%% 
offgasSo2TonPerHr(isnan(offgasSo2TonPerHr)) = 100; % TODO: channge
R = corrcoef(offgasSo2TonPerHr, matteFallFractions);
disp(R)

%% investigate relationship with matte fall flow rate
matteLevelMaxCm = 76;
matteLevelMinCm = 54;
tolCm = 0.1;
[~, isValidationMatteSounding] = extractValidationSoundings(dataTT.MatteThickness + dataTT.BuildUpThickness, tolCm, matteLevelMaxCm, matteLevelMinCm);

so2AnalysisTT = dataTT(:, ["MatteThickness", "BuildUpThickness"]);
so2AnalysisTT.MatteAndBuildupThickness = so2AnalysisTT.MatteThickness + so2AnalysisTT.BuildUpThickness;
so2AnalysisTT.MatteTapRateTonPerHr = calcMatteTapRatesHybrid(dataTT, 32, 10);
matteTappedDailyTon = retime(so2AnalysisTT, "daily", "sum").MatteTapRateTonPerHr/60;
validationDailyFirstSoundingTT = retime(so2AnalysisTT(isValidationMatteSounding, "MatteAndBuildupThickness"), "daily", "firstvalue");
matteLevelChangeDailyCm = [diff(validationDailyFirstSoundingTT.MatteAndBuildupThickness); so2AnalysisTT.MatteAndBuildupThickness(end) - validationDailyFirstSoundingTT.MatteAndBuildupThickness(end)];
MATTE_DENSITY_TON_PER_M3 = 4.5; % TODO: get from data dictionary
matteMassChangeDailyTon = matteLevelChangeDailyCm * MATTE_DENSITY_TON_PER_M3;
matteFallDailyTon = matteTappedDailyTon + matteMassChangeDailyTon;

so2AnalysisTT.OffgasSo2TonPerHr = offgasSo2TonPerHr;
offgasSo2DailyTon = retime(so2AnalysisTT, "daily", "sum").OffgasSo2TonPerHr/60;
figure
plot(matteFallDailyTon, offgasSo2DailyTon, 'o')
title("Daily matte fall vs Daily Offgas SO2")
xlabel("Daily matte fal (ton)")
ylabel("Daily offgas SO2 (ton)")
%% 

R_dailyOffgasSo2_vs_dailyMatteFall = corrcoef(offgasSo2DailyTon, matteFallDailyTon);
%% Validation
R_dailyMatteFallFraction = retime()


    




function [validationSoundings, isValidationSounding] = extractValidationSoundings(values, tolerance, max, min)
    isValidationSounding = [1; abs(diff(values)) > tolerance] & values <= max & values >= min;
    validationSoundings = values(isValidationSounding);
end
    








