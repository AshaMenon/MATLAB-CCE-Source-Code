
%Create wacp connector (default is LetheConversion)
connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); 

%Create an element at the root level
elementFolder = af.Element.addElementToRoot("CCETest", "Connector", connector); 

%Populate element
newElem = elementFolder.addElement("FeedProfile_SCF1", "Template", 'cceACEFeedProfile_SCF');
newElem.createPiPoints;
newElem.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 300);
newElem.setAttributeValue("CalculationState", "Idle");
newElem.setAttributeValue("CoordinatorID", 200);
newElem.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));

% inputs
newElem.setAttributeValue("WACS_Centre_Port11_tot", 21);
newElem.setAttributeValue("WACS_Delta_Port13_tot", 21);
newElem.setAttributeValue("WACS_Delta_Port6_tot", 21);
newElem.setAttributeValue("WACS_Delta_Port9_tot", 21);
newElem.setAttributeValue("WACS_Wall_Port10_tot", 21);
newElem.setAttributeValue("WACS_Wall_Port12_tot", 21);
newElem.setAttributeValue("WACS_Wall_Port14_tot", 21);
newElem.setAttributeValue("WACS_Wall_Port5_tot", 21);
newElem.setAttributeValue("WACS_Wall_Port7_tot", 21);
newElem.setAttributeValue("WACS_Wall_Port8_tot", 21);

elementFolder.applyAndCheckIn;

%Run single calculation
calcToRun = cce.Calculation.createSingleCalc(newElem, connector); %Create calc obj from element
testLogger = Logger("C:\CCE\calcLogs\testCalcs.log", "testNoCoordRun1", "testNoCoordRun1", "Debug"); %optionally specify specific logger
calcToRun.runSingleCalculation("Logger", testLogger); %Run calc obj
newElem.applyAndCheckIn;