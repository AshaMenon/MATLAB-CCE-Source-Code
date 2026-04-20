
%Create wacp connector (default is LetheConversion)
connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); 

%Create an element at the root level
elementFolder = af.Element.addElementToRoot("CCETest", "Connector", connector); 

%Populate element
newElem = elementFolder.addElement("cceACECalculatedLevel1", "Template", 'cceACECalculatedLevel');
newElem.createPiPoints;
newElem.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 300);
newElem.setAttributeValue("CalculationState", "Idle");
newElem.setAttributeValue("CoordinatorID", 200);
newElem.setAttributeValue("LastCalculationTime", datetime("01/01/1970 06:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));

% inputs
newElem.setAttributeValue("AddACE_MatteInPFM_86400_21601_STot", 21);
newElem.setAttributeValue("AddACE_MatteInWFM_86400_21601_STot", 21);
newElem.setAttributeValue("AddACE_MatteProd_24_6_2Tot", 21);
newElem.setAttributeValue("AddStockAdjustment_24_6_STot", 21);
newElem.setAttributeValue("SubtractOut_Matte_86400_21601_STot", 21);
newElem.setAttributeValue("SurveyedFurnace_24_6_ETot", 21);
newElem.setAttributeValue("SurveyedPFM_24_6_ETot", 21);
newElem.setAttributeValue("SurveyedUFM_24_6_ETot", 21);
newElem.setAttributeValue("SurveyedUFMSilo_24_6_ETot", 21);
newElem.setAttributeValue("SurveyedWFM_24_6_ETot", 21);
newElem.setAttributeValue("MeasuredPFM_86400_21601_STot", 21);
newElem.setAttributeValue("MeasuredUFM_86400_21601_STot", 21);

elementFolder.applyAndCheckIn;

%Run single calculation
calcToRun = cce.Calculation.createSingleCalc(newElem, connector); %Create calc obj from element
testLogger = Logger("C:\CCE\calcLogs\testCalcs.log", "testNoCoordRun1", "testNoCoordRun1", "Debug"); %optionally specify specific logger
calcToRun.runSingleCalculation("Logger", testLogger); %Run calc obj
newElem.applyAndCheckIn;