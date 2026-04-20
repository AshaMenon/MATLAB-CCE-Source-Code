function [dVal, dQual, dTime] = APCQuantExpression(varargin)
%APCQUANTEXPRESSION Evaluate expression
%   [dVal, dQual, dTime] = APCQuantExpression(varargin) computes
%   dVal based on specified expression.
%
%   Expected inputs: class, id, value, quality, timeStamp, active, condition, eu
% 
% The output instrument’s unit is used as the expected units as well as the resulting unit.
% 
% G2 calculation as obtained from ACM db

%% Read inputs
% Parse inputs
[derivedSensorClass,derivedSensorEU,derivedSensorSG,numInputs,id,value,quality,timeStamp,...
    active,condition,eu,sg,constants,leadingConstants,ignoreInd] = parseInputs(varargin,false,'');

%% Algorithm
inputs = zeros(1,2);
persistence = 0;
for i = 1:size(varargin,2)/numInputs
    if strfind(lower(id{i}),'expression')
        expression = id{i}(strfind(lower(id{i}),'{')+1:strfind(lower(id{i}),'}')-1);
        expression(strfind(expression,';')) = ',';
    elseif strfind(lower(id{i}),'persistence')
        persistence = i;
    else
        if strfind(lower(id{i}),'p')
            inputs(str2double(id{i}(2:end))+1,1) = i;
        elseif strfind(lower(id{i}),'th')
            inputs(str2double(id{i}(3:end))+1,2) = i;
        end
    end
end

% Set persistence
samples = 0;
if persistence > 0
    samplingTime = round(24*60*60*(timeStamp(2,persistence) - timeStamp(1,persistence)));
    persistence = value(1,persistence);
    samples = ceil(persistence/samplingTime);
end
% Calculate sampling time for potential time based expressions
try samplingTime = round(24*60*60*(timeStamp(2,1) - timeStamp(1,1))); catch, end
% Remove spaces
spaces = isspace(expression);
expression(spaces) = [];
% Replace functions
expressionMap = {'*'                    '.*'                    0;
                 '/'                    './'                    0;
                 '^'                    '.^'                    0;
                 'average'              'mean'                  0;
                 'ceiling'              'ceil'                  0;
                 'log'                  'log10'                 0;
                 'ln'                   'log'                   0;
                 'remainder'            'rem'                   0;
                 'truncate'             'fix'                   0;
                 'random'               'rand'                  0;
                 'math-clip'            'mathClip'              0;
                 'math-equal'           'mathEqual'             0;
                 'math-greater-equal'	'mathGreaterEqual'      0;
                 'math-greater'         'mathGreater'           0;
                 'math-less-equal'      'mathLessEqual'         0;
                 'math-less'            'mathLess'              0;
                 'math-not-equal'       'mathNotEqual'          0;
                 'math-not'             'mathNot'               0;
                 'math-if'              'mathIf'                0;
                 'math-avg'             'mathAvg'               1;
                 'math-median'          'mathMedian'            1;
                 'math-var'             'mathVar'               1;
                 'math-stdev'           'mathStdev'             1;
                 'math-integral'        'mathIntegral'          1;
                 'math-roc'             'mathRoc'               1;
                 'math-deadtime'        'mathDeadtime'          1};
for j = 1:size(expressionMap,1)
    replace = strfind(lower(expression),expressionMap{j,1});
    for i = size(replace,2):-1:1
        if expressionMap{j,3} == 0
            expression = [expression(1:replace(i)-1) expressionMap{j,2} expression(replace(i)+length(expressionMap{j,1}):end)];
        else
            expression = [expression(1:replace(i)-1) expressionMap{j,2} '(samplingTime,' expression(replace(i)+length(expressionMap{j,1})+1:end)];
        end
    end
end
% Fix for rand calculation format
replace = strfind(lower(expression),'rand');
% replaceOpen = strfind(lower(expression),'(');
% replaceClose = strfind(lower(expression),')');
for i = size(replace,2):-1:1
    replaceOpen = strfind(lower(expression),'(');
    replaceClose = strfind(lower(expression),')');
    open = 0; close = 0; found = -1;
    boundary = sort([replaceOpen(replaceOpen>replace(i)) replaceClose(replaceClose>replace(i))]);
    for j = 1:size(boundary,2)
        if strcmpi(expression(boundary(j)),'('), open = open + 1; elseif strcmpi(expression(boundary(j)),')'), close = close + 1; end
        if open == close && found == -1, found = boundary(j); end
    end
    replacementFunction = expression(replace(i):found);
    if max(size(strfind(replacementFunction,','))) == 0
        replacementFunction = [replacementFunction(6:end-1) '*rand()'];
    elseif max(size(strfind(replacementFunction,','))) > 0
        commaSep = strfind(replacementFunction,',');
        c1 = replacementFunction(6:commaSep-1);
        c2 = replacementFunction(commaSep+1:end-1);
        if str2double(c1) > str2double(c2)
            c1 = replacementFunction(commaSep+1:end-1);
            c2 = replacementFunction(6:commaSep-1);
        end
        replacementFunction = ['(' c1 '+(' c2 '-' c1 ')*rand())'];
    end
    if max(size(strfind(replacementFunction,'.'))) == 0
        replacementFunction = ['round(' replacementFunction ')'];
    end
    expression = [expression(1:replace(i)-1) replacementFunction expression(replace(i)+size(replace(i):found,2):end)];
end

% Fix for mean, min and max calculation format
history = [];
for k = 1:2
    if k == 1
        % Fix for mean calculation format
        replace = strfind(lower(expression),'mean');
    elseif k == 2
        % Fix for min/max calculation format
        replace = sort([strfind(lower(expression),'max') strfind(lower(expression),'min')]);
    end
%     replaceOpen = strfind(lower(expression),'(');
%     replaceClose = strfind(lower(expression),')');
    for i = size(replace,2):-1:1
        replaceOpen = strfind(lower(expression),'(');
        replaceClose = strfind(lower(expression),')');
        open = 0; close = 0; found = -1;
        boundary = sort([replaceOpen(replaceOpen>replace(i)) replaceClose(replaceClose>replace(i))]);
        for j = 1:size(boundary,2)
            if strcmpi(expression(boundary(j)),'('), open = open + 1; elseif strcmpi(expression(boundary(j)),')'), close = close + 1; end
            if open == close && found == -1, found = boundary(j); end
        end
        replacementFunction = expression(replace(i):found);
        histMarker = [];
        if ~isempty(history)
            histMarker = history - (replace(i)-1);
        end
%         replacementFunction = 'min(mathGreaterEqual(P1,99),P2)';
        % Need to NOT replace ',' in math functions
        bracketCounter = -1;
        for m = 1:size(replacementFunction,2)
            if strcmpi(replacementFunction(m),'(')
                bracketCounter = bracketCounter + 1;
            elseif strcmpi(replacementFunction(m),')')
                bracketCounter = bracketCounter - 1;
            elseif bracketCounter == 0 && strcmpi(replacementFunction(m),',')
                replacementFunction(m) = ' ';
            end
        end
%         replacementFunction(strfind(replacementFunction,',')) = ' ';
        if k == 1
            expFunc = replacementFunction(6:end-1);
            histMarker = histMarker - 5;
        elseif k == 2
            expFunc = replacementFunction(5:end-1);
            histMarker = histMarker - 4;
        end
        histMarkerIndex = 0*history;
        histMarkerIndex(histMarker > 0) = 1;
%         histMarker(histMarker < 1) = [];
%         expFunc = '(P1+P2) 1'
%         expFunc = '0.0,(P3-(P1.*P2))'
%         expFunc =  '(P1 / (max(0.5.*(P1 + P2) 1)))*100'
%         expFunc = '(P1.*max(P2,P3,P4,P5,P6,P7,P8,P9))'
        resultP = regexp(expFunc,'[P][0-9]');
        resultN = regexp(expFunc,'[0-9]');
        % Identify only numeric
        if ~isempty(resultP)
            resultP = resultP+1;
            for m = size(resultN,2):-1:1
                if ~isempty(find(resultP==resultN(m)))
                    resultN(m) = [];
                end
            end
        end
        % Identify decimal numbers'.'
        resultDot = strfind(expFunc,'.');
        % Remove entries from expression map
        for m = size(resultDot,2):-1:1
            if resultDot(m) ~= size(expFunc,2)
                if max(strcmpi(expFunc(resultDot(m):resultDot(m)+1),expressionMap(1:3,2))) > 0
                    resultDot(m) = [];
                end
            end
        end
        % Identify numbers
        combResult = sort([resultN resultDot]);
        if ~isempty(histMarker) && ~isempty(combResult)
%             combResult(combResult == histMarker) = [];
            [~,ind] = intersect(combResult,histMarker);
            combResult(ind) = [];
        end
        combResultDiff = [2 diff(combResult)];
        combResultPos = find(combResultDiff>1);
        if isempty(combResult)
            combResultPos = [];
        elseif size(combResultPos,2) == 1
            combResultPos(2,1) = combResult(end);
            combResultPos(1,1) = combResult(combResultPos(1,1));
        else
            combResultPos(2,:) = [combResult(combResultPos(2:end)-1) combResult(end)];
            combResultPos(1,:) = combResult(combResultPos(1,:));
        end
        for m = 1:size(combResultPos,2)
            combResultPos(3,m) = str2double(expFunc(combResultPos(1,m):combResultPos(2,m)));
        end
        for m = size(combResultPos,2):-1:1
            if ~isnan(combResultPos(3,m))
                if ~any(strcmpi('P0',id))
                    expFunc = [expFunc(1:combResultPos(1,m)-1) 'repmat(' num2str(combResultPos(3,m)) ',size(value,1),1)' expFunc(combResultPos(2,m)+1:end)];
                else
                    expFunc = [expFunc(1:combResultPos(1,m)-1) num2str(combResultPos(3,m)) expFunc(combResultPos(2,m)+1:end)];
                end
            end
        end
        if k == 1
            replacementFunction = [replacementFunction(1:5) '[' expFunc '],2' replacementFunction(end)];
            for m = 1:size(histMarker,2)
                if (histMarker(m) > 0) && (histMarker(m) < length(replacementFunction))
                    % Adjust for history within replacement function
                    history(m) = histMarker(m) + 6 + length(expression(1:replace(i)-1));
                elseif (histMarker(m) > 0) && (histMarker(m) > length(replacementFunction))
                    % Adjust for history after replacement function
                    history(m) = history(m) + (length(replacementFunction) - length(refReplacementFunction));
                end
            end
            % Add history resulting from replacement function
            history = [history length([expression(1:replace(i)-1) replacementFunction])-1];
        elseif k == 2
            refReplacementFunction = replacementFunction;
            replacementFunction = [replacementFunction(1:4) '[' expFunc '],[],2' replacementFunction(end)];
            for m = 1:size(histMarker,2)
                if (histMarker(m) > 0) && (histMarker(m) < length(replacementFunction))
                    % Adjust for history within replacement function
                    history(m) = histMarker(m) + 5 + length(expression(1:replace(i)-1));
                elseif (histMarker(m) > 0) && (histMarker(m) > length(replacementFunction))
                    % Adjust for history after replacement function
                    history(m) = history(m) + (length(replacementFunction) - length(refReplacementFunction));
                end
            end
            % Add history resulting from replacement function
            history = sort([history length([expression(1:replace(i)-1) replacementFunction])-1]);
        end
        expression = [expression(1:replace(i)-1) replacementFunction expression(replace(i)+size(replace(i):found,2):end)];
    end
end
% Calculate all inputs
for i = size(inputs,1):-1:1
    if sum(inputs(i,:)) ~= 0
%         value(:,inputs(i,1)) = value(:,inputs(i,1)) > value(:,inputs(i,2));
        replace = strfind(lower(expression),['p' num2str(i-1)]);
        if ~isempty(replace)
            for j = size(replace,2):-1:1
                % Handle for when P0 is present
                if ~any(strcmpi('P0',id))
                    expression = [expression(1:replace(j)-1) 'value(:,' num2str(inputs(i,1)) ,')' expression(replace(j)+1+length(num2str(i-1)):end)];
                else
                    expression = [expression(1:replace(j)-1) 'value(i,' num2str(inputs(i,1)) ,')' expression(replace(j)+1+length(num2str(i-1)):end)];
                end
            end
        end
    end
end

% Calc results
% goodQualityVal = ap.DataQuality.opmqualityval('good'); % Identify the missing values
% missingQualityVal = ap.DataQuality.opmqualityval('missing data'); % Identify the missing values
% mappedGoodQualityVal = ap.DataQuality.opmqualityval('mapped good'); % Identify the mapped good values
goodQualityVal = 0;
mappedGoodQualityVal = 65534;
missingQualityVal = 1;
dQual = goodQualityVal*ones(size(value(:,1),1),1);    % Assume all GOOD quality
rng('default');
if isempty(expression)
    dQual(:,1) = missingQualityVal;    % All data missing
    dVal = nan(size(value(:,1),1),1);    % All data missing
else
    dQual(:,1) = goodQualityVal;    % Assume all GOOD quality
    % If P0 exist in expression, solve iteratively
    if any(strcmpi('P0',id))
        for i = 1:size(value,1)
            eval(['dVal(i,1) = (' expression ');']);
            if i < size(value,1)
                value(i+1,strcmpi('P0',id)) = dVal(i,1);
            end
        end
    else
        eval(['dVal = (' expression ');']);
    end
    if samples > 0
        % Adjust data based on persistence
        dtVal = dVal(2:end) - dVal(1:end-1);
        for j = 1:2
            if j == 1
                % For positive changes
                findCnst = 1; result = 0;
            elseif j == 2
                % For negative changes
                findCnst = -1; result = 1;
            end
            dtValPos = find(dtVal == findCnst) + 1;
            dtRange = [];
            for i = 1:size(dtValPos,1)
                dtRange = [dtRange (dtValPos(i,:) : dtValPos(i,:) + samples - 1)];
            end
            dVal(dtRange) = result;
        end
    end
end
dQual(dQual==mappedGoodQualityVal) = goodQualityVal; % Map good quality back
dTime = timeStamp(:,1); % Assign timeStamps
dVal = dVal(1:size(timeStamp,1));