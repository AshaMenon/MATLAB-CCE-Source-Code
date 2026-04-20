
%Create wacp connector (default is LetheConversion)
connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); 

%Create an element at the root level
elementFolder = af.Element.addElementToRoot("CCETest", "Connector", connector); 

%Populate element
newElem = elementFolder.addElement("FeedProfileSixInLine_WSMLTest", "Template", 'cceACEFeedProfileSixInLine_WSML');
newElem.createPiPoints;
newElem.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 300);
newElem.setAttributeValue("CalculationState", "Idle");
newElem.setAttributeValue("CoordinatorID", 200);
newElem.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));

% inputs
newElem.setAttributeValue("Autofeed.Port1.tot", 21);
newElem.setAttributeValue("Autofeed.Port2.tot", 21);
newElem.setAttributeValue("Autofeed.Port3.tot", 21);
newElem.setAttributeValue("Autofeed.Port4.tot", 21);
newElem.setAttributeValue("Autofeed.Port5.tot", 21);
newElem.setAttributeValue("Autofeed.Port6.tot", 21);
newElem.setAttributeValue("Autofeed.Port7.tot", 21);

newElem.setAttributeValue("Manual.Port1.tot", 21);
newElem.setAttributeValue("Manual.Port2.tot", 21);
newElem.setAttributeValue("Manual.Port3.tot", 21);
newElem.setAttributeValue("Manual.Port4.tot", 21);
newElem.setAttributeValue("Manual.Port5.tot", 21);
newElem.setAttributeValue("Manual.Port6.tot", 21);
newElem.setAttributeValue("Manual.Port7.tot", 21);

newElem.setAttributeValue("TopUp.Port1.tot", 21);
newElem.setAttributeValue("TopUp.Port2.tot", 21);
newElem.setAttributeValue("TopUp.Port3.tot", 21);
newElem.setAttributeValue("TopUp.Port4.tot", 21);
newElem.setAttributeValue("TopUp.Port5.tot", 21);
newElem.setAttributeValue("TopUp.Port6.tot", 21);
newElem.setAttributeValue("TopUp.Port7.tot", 21);

elementFolder.applyAndCheckIn;

%Run single calculation
calcToRun = cce.Calculation.createSingleCalc(newElem, connector); %Create calc obj from element
testLogger = Logger("C:\CCE\calcLogs\testCalcs.log", "testNoCoordRun1", "testNoCoordRun1", "Debug"); %optionally specify specific logger
calcToRun.runSingleCalculation("Logger", testLogger); %Run calc obj
newElem.applyAndCheckIn;