%Temperature Plots example script

%Get data from MatteTemperatureModelTest script and fundamental.mat file
MatteTemperatureModelTest;
load fundamental.mat

%Matte and slag temperatures from simOut
matteTemperature = timeseries2timetable(simout);
slagTemperature = timeseries2timetable(slagTemp);

%Matte and slag temperatures from the fundamental model
matteTemperatureF = timeseries2timetable(logsout{29}.Values);
slagTemperatureF = timeseries2timetable(logsout{30}.Values);
slagTapping = timeseries2timetable(logsout{2}.Values);

%Date range on data
% matteTemperatureF.Time.Format = 'hh:mm';
% matteTemperatureF.Time = minute(matteTemperatureF.Time);
% startDate = string(matteTemperatureF.Time(idx(1)));
% endDate = string(matteTemperatureF.Time(end));
% dates = sprintf('This is data ranging from %s to %s continuously',startDate,endDate);
% disp(dates);

%Matte and Slag temperature difference
isIt = find(matteTemperature.("Tm [C]")(matteTemperature.("Tm [C]") - matteTemperatureF.("Tm [C]") ~= 0));
isIt1 = find(slagTemperature.("Ts [C]")(slagTemperature.("Ts [C]") - slagTemperatureF.("Ts [C]") ~= 0));
matteDifferenceIDX = matteTemperature;
matteDifferenceIDX.("Tm [C]") = matteTemperature.("Tm [C]") - matteTemperatureF.("Tm [C]");
slagDifferenceIDX = slagTemperature;
slagDifferenceIDX.("Ts [C]") = slagTemperature.("Ts [C]") - slagTemperatureF.("Ts [C]");

datacursormode.Enable = 'on';
%Fundamental vs simOut Plots
a = figure();
plot(matteTemperature.Time,matteTemperature.("Tm [C]"),'r')
hold on
plot(matteTemperatureF.Time,matteTemperatureF.("Tm [C]"),'g')
hold on
plot(slagTemperature.Time,slagTemperature.("Ts [C]"),'k')
hold on
plot(slagTemperatureF.Time,slagTemperatureF.("Ts [C]"),'m')
hold on
plot(matteDifferenceIDX.Time, matteDifferenceIDX.("Tm [C]"),'*b')
hold on
plot(slagDifferenceIDX.Time,slagDifferenceIDX.("Ts [C]"),'.r')
hold off
legend('simOut Tm','fundamental Tm','simOut Ts','fundamental Ts','Matte Temperature Difference', 'Slag Temperature Difference',Location='bestoutside')
Date= sprintf('Simulink model vs MatteTemperatureModelTest script for %s',string(dates));
title(Date)
xlabel('Time range (seconds)')
ylabel(['Temperature [' char(176) 'C]'])
% set(gca,'Color','k')
grid minor

%simOut Matte Temperature Plots
a1 = figure();
plot(matteTemperature.Time,matteTemperature.("Tm [C]"),'m')
hold on
plot(mean(matteTemperature.Time),mean(matteTemperature.("Tm [C]")),'*r')
hold on
[maxMatteTemp,idx] = max(matteTemperature.("Tm [C]"));
plot(matteTemperature.Time(idx),maxMatteTemp,'*r')
hold on
[minMatteTemp,idxx] = min(matteTemperature.("Tm [C]"));
plot(matteTemperature.Time(idxx),minMatteTemp,'*r')
hold on
ma = matteTemperature.("Tm [C]");
ma(1:length(ma)) = 1200;
plot(matteTemperature.Time,ma,':b');
hold on
ma = matteTemperature.("Tm [C]");
ma(1:length(ma)) =1300;
plot(matteTemperature.Time,ma,':b');
hold on
x2 = [matteTemperature.Time, fliplr(matteTemperature.Time)];
inBetween = [curve1, fliplr(curve2)];
fill(x2, inBetween, 'g');
hold off
legend('simOut Tm','Matte Temperature mean','Matte Temperature Max Value','Matte Temperature Min Value','Matte Temperature Lower Boundary','Matte Temperature Upper Boundary',Location='bestoutside')
Date= sprintf('Matte Temperature analysis for %s',string(dates));
title(Date)
% datetick('x','hh:mm');
xlabel('Time range (seconds)')
ylabel(['Temperature [' char(176) 'C]'])
% set(gca,'Color','k')
grid minor


%simOut Slag Temperature Plots
a11 = figure();
plot(slagTemperature.Time,slagTemperature.("Ts [C]"),'m')
hold on
plot(mean(slagTemperature.Time),mean(slagTemperature.("Ts [C]")),'*r')
hold on
[maxSlagTemp,idx] = max(slagTemperature.("Ts [C]"));
plot(slagTemperature.Time(idx),maxSlagTemp,'*r')
hold on
[minSlagTemp,idxx] = min(slagTemperature.("Ts [C]"));
plot(slagTemperature.Time(idxx),minSlagTemp,'*r')
hold on
ma = slagTemperature.("Ts [C]");
ma(1:length(ma)) = 1300;
plot(slagTemperature.Time,ma,':b');
hold on
ma = slagTemperature.("Ts [C]");
ma(1:length(ma)) =1400;
plot(slagTemperature.Time,ma,':b');
hold off
legend('simOut Ts','Slag Temperature Mean','Slag Temperature Max Value','Slag Temperature Min Value','Slag Temperature Lower Boundary','Slag Temperature Upper Boundary',Location='bestoutside')
Date= sprintf('Slag Temperature analysis for %s',string(dates));
title(Date)
% datetick('x','hh:mm');
xlabel('Time range (seconds)')
ylabel(['Temperature [' char(176) 'C]'])
% set(gca,'Color','k')
grid minor

%Matte Temperature Model Status based on Convertor mode
b = figure();
yyaxis left
plot(matteTemperature.Time,matteTemperature.("Tm [C]"),'m')
ylabel(['Matte Temperature [' char(176) 'C]'])
hold on
ma = matteTemperature.("Tm [C]");
ma(1:length(ma)) = 1200;
plot(matteTemperature.Time,ma,':b');
hold on
ma = matteTemperature.("Tm [C]");
ma(1:length(ma)) = 1300;
plot(matteTemperature.Time,ma,':b');
yyaxis right
scatter(data.Timestamp,data.ConverterMode,'g')
Date= sprintf('Matte Temperature analysis for %s based on the Convertor Mode',string(dates));
title(Date)
xlabel('Time range (seconds)')
ylabel('Slag Tapping')
legend('Matte Temperature','Matte Temperature Lower Boundary','Matte Temperature Upper Boundary','Convertor Mode')
% set(gca,'Color','k')
grid minor

b1 = figure();
yyaxis left
plot(slagTemperature.Time,slagTemperature.("Ts [C]"),'m')
ylabel(['Slag Temperature [' char(176) 'C]'])
hold on
ma = slagTemperature.("Ts [C]");
ma(1:length(ma)) = 1300;
plot(slagTemperature.Time,ma,':b');
hold on
ma = slagTemperature.("Ts [C]");
ma(1:length(ma)) = 1400;
plot(slagTemperature.Time,ma,':b');
yyaxis right
scatter(data.Timestamp,data.ConverterMode,'g')
Date= sprintf('Slag Temperature analysis for %s based on the Convertor Mode',string(dates));
title(Date)
xlabel('Time range (seconds)')
ylabel('Slag Tapping')
legend('Slag Temperature','Slag Temperature Lower Boundary','Slag Temperature Upper Boundary','Convertor Mode')
% set(gca,'Color','k')
grid minor

c = figure();
yyaxis left
plot(matteTemperature.Time,matteTemperature.("Tm [C]"))
ylabel(['Matte Temperature [' char(176) 'C]'])
hold on
ma = matteTemperature.("Tm [C]");
ma(1:length(ma)) = 1250;
plot(matteTemperature.Time,ma,':g');
hold on
ma = matteTemperature.("Tm [C]");
ma(1:length(ma)) =1300;
plot(matteTemperature.Time,ma,':g');
yyaxis right
slagT = find(slagTapping.("Slag Tapping") == 1);
scatter(matteTemperature.Time(slagT),slagTapping.("Slag Tapping")(slagTapping.("Slag Tapping") == 1),'cyan')
Date= sprintf('Matte Temperature analysis for %s based on the slag tapping status',string(dates));
title(Date)
xlabel('Time range (seconds)')
ylabel('Slag Tapping')
legend('Matte Temperature','Matte Temperature Lower Boundary','Matte Temperature Upper Boundary','Model tapping')
% set(gca,'Color','k')
grid minor
