
%Create wacp connector (default is LetheConversion)
connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); 

%Create an element at the root level
elementFolder = af.Element.addElementToRoot("ProgrammaticallyCreatedTests", "Connector", connector); 

%Populate element
newElem = elementFolder.addElement("testNoCoordRun", "Template", 'sensorAdd');
newElem.createPiPoints;
newElem.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 300);
newElem.setAttributeValue("SensorReference", 21);
newElem.setHistoricalAttributeValue("SensorReference", 21, datetime("yesterday")); %Optionally set historical timestamp

newElem.setAttributeValue("CalculationState", "Idle");
newElem.setAttributeValue("CoordinatorID", 200);
newElem.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
elementFolder.applyAndCheckIn;

%Run single calculation
calcToRun = cce.Calculation.createSingleCalc(newElem, connector); %Create calc obj from element
testLogger = Logger("C:\CCE\calcLogs\testCalcs.log", "testNoCoordRun1", "testNoCoordRun1", "Debug"); %optionally specify specific logger
% calcToRun.runSingleCalculation("Logger", testLogger); %Run calc obj

calcToRun.runSingleCalculation("Logger", testLogger, "CalcTime", datetime(2023, 06, 12, 24, 0, 0)); %Optionally run calculation at specific time
newElem.applyAndCheckIn;