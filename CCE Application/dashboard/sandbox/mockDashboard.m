clear
DataConnector = af.AFDataConnector('ons-opcdev.optinum.local', 'CCEProd');
record = DataConnector.findRecords('CoordinatorSearch', 'Name:=sensorAdd03');
record = record{1};

%% CalculationState
csField = DataConnector.getFieldByName(record, "CalculationState");
[value, timestamp] = DataConnector.readFieldRecordedHistory(csField, ["*-10m"; "*"]);
cs = cce.CalculationState(value);
[x,y]=enumeration(cs);
subplot(2,1,1);
stairs(timestamp, cs, Marker='.');yticks(int32(x));yticklabels(y); ylim([min(x)-0.1,max(x)+0.1]);
subplot(2,1,2);
hist(seconds(diff(timestamp)),100)
xlabel("diff(Timestamps) in seconds")

%% LastCalcTime
tsField = DataConnector.getFieldByName(record, "LastCalculationTime");
[calcTime, ctTimestamp] = DataConnector.readFieldRecordedHistory(tsField, ["*-10m"; "*"]);
figure;plot(ctTimestamp, calcTime,'.'); xlabel('CalculationTime'); ylabel('Write time')