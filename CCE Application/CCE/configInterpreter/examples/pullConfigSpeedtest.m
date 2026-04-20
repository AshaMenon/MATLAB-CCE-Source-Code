
clear

this = cce.AFInterface();
connectToAFDatabase(this, 'ONS-OPCDEV', 'WACP');

fprintf('\nGet elements: ')
tic;
this.findElementsByTemplate('tempSearch', 'CCECalculation');
toc

fprintf('\nGet attributes: ')
tic
getElementAttributes(this)
toc

fprintf('\nReformat Data into a useable form: ')
tic
calcData = cell(1, numel(this.Attributes));
for iElement = 1:numel(this.Attributes)
    calcData{1, iElement} = cell(this.AttributeCurrentValues{iElement}.Count, 2);
    for iAttribute = 1:this.AttributeCurrentValues{iElement}.Count
        value = this.AttributeCurrentValues{iElement}.Item(iAttribute - 1).Value;
        name = this.AttributeCurrentValues{iElement}.Item(iAttribute - 1).Attribute.Name;
        calcData{1, iElement}{iAttribute, 1} = name;
        calcData{1, iElement}{iAttribute, 2} = value;
    end
end
toc


