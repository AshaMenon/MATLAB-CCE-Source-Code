%elementClassExamples contains a few examples of practical uses of the
%Element.m class


%% Find elements
%Create wacp connector (default is LetheConversion)
connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); 

%find - a search pattern can be made use of - see "Search
%Query Syntax" documentation
%Note the "\" between different folder levels
searchPattern = "Template:CCECalculation Root:'CCETest\ComplexDependencies'";
elements1 = af.Element.find(searchPattern, "Connector",  connector); 

%findByTemplate - automatically adds Template to the search pattern.
%Additional args such as Root can be added. 
%Slightly different notation, ".\" required at beginning to show root level
elements2 = af.Element.findByTemplate("CCECalculation", "Connector", connector,...
    "Root", ".\CCETest\ComplexDependencies");

%findByPath automatically adds path to the search pattern.
%"\" required at the end
elements3 = af.Element.findByPath(".\CCETest\ComplexDependencies\", Connector=connector);

%Find by name
elements4 = af.Element.findByName("ACP", "Connector",  connector);

%% Create elements
%At Root level (no parent element required)

%Create wacp connector (default is LetheConversion)
connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); 

%Note how this is called since it is a static method - ie does not require existing obj
rootElem = af.Element.addElementToRoot("RootElem1", "Connector", connector); 

% Create element in parent element - use rootElem obj just created - this
% is the parent element
newChildElem = addElement(rootElem, "childElement1", "Description",...
    "This is a child element of 'Root Elem1'", "Template", 'sensorAdd');
newChildElem.applyAndCheckIn;

%% Add and change attribute values
%First we need an element. The elements created above will be used.

%Find attributes
attributeTab1 = newChildElem.findAttributes;
attributeTab2 = newChildElem.findAttributes("Category", "CCEOutput");
attributeTab3 = newChildElem.findFullAttributes; %Note that child attributes will be included here too. 

%Get attribute value
%Note that for multi level attributes that an array is used 
attrVal1 = newChildElem.getAttributeValue(["ExecutionParameters", "ExecutionMode"]); 

%Note that it sends a pipoint invalid - we havent created a pi point yet
attrVal2Attempt1 = newChildElem.getAttributeValue(attributeTab2.Row); 

%Create PI Points
newChildElem.createPiPoints;
%Use this if child attributes contain data references that need to be
%created e.g. 
newChildElem.createPiPoints("ChildInclusion", true); 

attrVal2 = newChildElem.getAttributeValue(attributeTab2.Row);

%Set attribute value
newChildElem.setAttributeValue("SensorReference", 35);

%Add attribute
%Simple addition
newAttr = newChildElem.addAttribute("SensorReference2", 25, "Categories", "CCEInput",...
    "CheckIn", true);

% Multi level not implemented yet - ability to add child attributes still
% needed
% newAttrChild = newChildElem.addAttribute(["SensorReference2", "RelativeTimeRange"], "*", "CheckIn", true); -

%Specify pi point reference value
newChildElem.addPIPointReference("SensorReference3",...
    "\\ons-opcdev\WACP.cceLethePebblesAndSpillagesMer1.DryFeedMer;ReadOnly=False",...
    "Categories", "CCEInput");

%Set attribute value at specific time (attribute must have a data
%reference)
newChildElem.setHistoricalAttributeValue("SensorReference", 20, datetime("now"));
newChildElem.setHistoricalAttributeValue("SensorReference", 11, datetime("yesterday"));
newChildElem.setHistoricalAttributeValue("SensorReference", 0.01, datetime(2023, 05, 17, 0, 0, 0));

%Get historic attribute values over specified time range
[values, timestamps, quals] = newChildElem.getHistoricalAttributeValues("SensorReference",...
    ["*-10m"; "*"]);


%% Delete elements/remove attributes
%Remove an attribute (and children) 
newChildElem.removeAttribute("SensorReference2");
newChildElem.removeAttribute("SensorReference200"); %This should error

%Remove element (and children)
%First create a couple of elements to be deleted
newChildElemArray(1) = addElement(rootElem, "childElement2");
newChildElemArray(2) = addElement(rootElem, "childElement3");
newChildElemArray(3) = addElement(rootElem, "childElement4");
newChildElemArray(4) = addElement(rootElem, "childElement5");

%Delete the first 3
deleteElement(newChildElemArray(1:3));

%Delete the parent
deleteElement(rootElem); %The child elements will be deleted automatically

%Note that items still exist in matlab, even after refresh - this must still be looked at. 
rootElem.refresh