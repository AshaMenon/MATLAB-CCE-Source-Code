
%Create wacp connector (default is LetheConversion)
connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); 

%Create an element at the root level
elementFolder = af.Element.addElementToRoot("CCETest", "Connector", connector); 

%Populate element
newElem = elementFolder.addElement("cceACEFeedProfilePOLS_All1", "Template", 'cceACEFeedProfilePOLS_All');
newElem.createPiPoints;
newElem.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 300);
newElem.setAttributeValue("CalculationState", "Idle");
newElem.setAttributeValue("CoordinatorID", 200);
newElem.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));

% inputs
newElem.setAttributeValue("FeedBatch_Port1_tot", 21);
newElem.setAttributeValue("FeedBatch_Port2_tot", 21);
newElem.setAttributeValue("FeedBatch_Port3_tot", 21);
newElem.setAttributeValue("FeedBatch_Port4_tot", 21);
newElem.setAttributeValue("FeedBatch_Port5_tot", 21);
newElem.setAttributeValue("FeedBatch_Port6_tot", 21);
newElem.setAttributeValue("FeedBatch_Port7_tot", 21);
newElem.setAttributeValue("FeedBatch_Port8_tot", 21);
newElem.setAttributeValue("FeedBatch_Port9_tot", 21);
newElem.setAttributeValue("FeedBatch_Port1_tot_2", 21);
newElem.setAttributeValue("FeedBatch_Port2_tot_2", 21);
newElem.setAttributeValue("FeedBatch_Port3_tot_2", 21);
newElem.setAttributeValue("FeedBatch_Port4_tot_2", 21);
newElem.setAttributeValue("FeedBatch_Port5_tot_2", 21);
newElem.setAttributeValue("FeedBatch_Port6_tot_2", 21);
newElem.setAttributeValue("FeedBatch_Port7_tot_2", 21);
newElem.setAttributeValue("FeedBatch_Port8_tot_2", 21);
newElem.setAttributeValue("FeedBatch_Port9_tot_2", 21);

elementFolder.applyAndCheckIn;

%Run single calculation
calcToRun = cce.Calculation.createSingleCalc(newElem, connector); %Create calc obj from element
testLogger = Logger("C:\CCE\calcLogs\testCalcs.log", "testNoCoordRun1", "testNoCoordRun1", "Debug"); %optionally specify specific logger
calcToRun.runSingleCalculation("Logger", testLogger); %Run calc obj
newElem.applyAndCheckIn;