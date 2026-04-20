
%Create wacp connector (default is LetheConversion)
connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); 

%Create an element at the root level
elementFolder = af.Element.addElementToRoot("CCETest", "Connector", connector); 

%Populate element
newElem = elementFolder.addElement("cceACEUSMLFurnaceFeed2", "Template", 'cceACEUSMLFurnaceFeed');
newElem.createPiPoints;
newElem.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 300);
newElem.setAttributeValue("CalculationState", "Idle");
newElem.setAttributeValue("CoordinatorID", 200);
newElem.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));

% inputs
newElem.setAttributeValue("M_RecyleRatio", 21);
newElem.setAttributeValue("ACE_Recycle_Tot", 21);
newElem.setAttributeValue("ACE_xfr_2tot", 21);
newElem.setAttributeValue("M_Correcton_Factor_xfer", 21);
newElem.setAttributeValue("M_DailyCorrection_xfer", 21);
newElem.setAttributeValue("M_Lime_Fed", 21);
newElem.setAttributeValue("M_On", 21);
newElem.setAttributeValue("M_Sec_Feedcalc", 21);
newElem.setAttributeValue("MW", 21);
newElem.setAttributeValue("MWhr_Tot", 21);

elementFolder.applyAndCheckIn;

%Run single calculation
calcToRun = cce.Calculation.createSingleCalc(newElem, connector); %Create calc obj from element
testLogger = Logger("C:\CCE\calcLogs\testCalcs.log", "testNoCoordRun1", "testNoCoordRun1", "Debug"); %optionally specify specific logger
calcToRun.runSingleCalculation("Logger", testLogger); %Run calc obj
newElem.applyAndCheckIn;