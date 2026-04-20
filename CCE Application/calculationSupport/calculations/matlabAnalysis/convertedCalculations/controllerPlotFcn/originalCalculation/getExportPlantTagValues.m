function [exportTagValue,exportPlantValue] = getExportPlantTagValues(entity)
% GETEXPORTDETAILS create the necessary export tag and plant values
%   exportDetails = getExportDetails(sensor,varargin) creates a structure EXPORTDETAILS with
%   fields EXPORTTAGVALUE and PLANTNAME for the export tag and plant values respectively. The
%   SENSOR export tag value and plant (either as a sensor object or structure)

if isa(entity,'ap.OPMSensor')
    
    % Find the tag name regardless of sensor type
    exportTagValue = {entity.getExportTag('Value')};
    exportPlantValue = {entity.Plant};
    % Find plant name and overwrite tag name if necessary
    if entity.IsDerivedType || entity.IsReferenceType ||...
            (strcmpi(entity.SourceTag(1),'[') && strcmpi(entity.SourceTag(end),']'))% derived or constant sensor
        % Find the plant name
%         if isempty(entity.DataSource)
%             exportPlantValue = 'NaN';
%         else
%             exportPlantValue = entity.DataSource.Plant;
%         end
        % Overwrite tag name if necessary
        if strcmpi(exportTagValue,'NAN')
            exportTagValue = {entity.NameInTree};
        end
    else % primary sensor
        if  ~isempty(entity.Data)
            % Overwrite tag name if necessary
            if strcmpi(exportTagValue,'NAN') && ~entity.Data(1).IsConstant
                activeImporter = entity.Data.getActiveImporter;
                
                % report primary source tag
                exportTagValue = {entity.SourceTag};
                
                % report secondary tag
                secImporter = findobj(entity.Data,'Precedence',2);
                if ~isempty(secImporter)
                    if ~isempty(activeImporter) && (activeImporter.Precedence == 2 || strcmpi(activeImporter.DataSource.DataSourceType,'AFAttribute'))
                        exportTagValue = {secImporter.SourceTag};
                    end
                end
                
                % report tertiary tag
                terImporter = findobj(entity.Data,'Precedence',3);
                if ~isempty(terImporter)
                    if ~isempty(activeImporter) && activeImporter.Precedence == 3
                        exportTagValue = {terImporter.SourceTag};
                    end
                end
            else % if isConstant
                if strcmpi(exportTagValue,'NAN')
                    exportTagValue = {entity.NameInTree};
                end
            end
%             % Find the plant name
%             exportPlantValue = entity.Data(1).DataSource.Plant;
%             % report secondary tag
%             secImporter = findobj(entity.Data,'Precedence',2);
%             if ~isempty(secImporter)
%                 if ~isempty(activeImporter) && activeImporter.Precedence == 2
%                     % Overwrite plant name
%                     exportPlantValue = secImporter.DataSource.Plant;
%                 end
%             end
%             
%             % report tertiary tag
%             terImporter = findobj(entity.Data,'Precedence',3);
%             if ~isempty(terImporter)
%                 if ~isempty(activeImporter) && activeImporter.Precedence == 3
%                     % Overwrite plant name
%                     exportPlantValue = terImporter.DataSource.Plant;
%                 end
%             end
%         else
%             exportPlantValue = 'NaN';
        end
    end
elseif isa(entity,'ap.SensorData')
    % Find the tag name regardless of sensor type
    exportTagValue = {entity.Context.getExportTag('Value')};
    exportPlantValue = {entity.Context.Plant};
    % Find plant name and overwrite tag name if necessary
    if entity.Context.IsDerivedType % derived sensor
        % Find the plant name
%         if isempty(entity.Context.DataSource)
%             exportPlantValue = 'NaN';
%         else
%             exportPlantValue = entity.Context.DataSource.Plant;
%         end
        % Overwrite tag name if necessary
        if strcmpi(exportTagValue,'NAN')
            exportTagValue = {entity.Context.NameInTree};
        end
    else % primary sensor
        if  ~isempty(entity.Context.Data)
            % Overwrite tag name if necessary
            if strcmpi(exportTagValue,'NAN')
                activeImporter = entity.Context.Data.getActiveImporter;
                
                % report primary source tag
                exportTagValue = {entity.Context.SourceTag};
                
                % report secondary tag
                secImporter = findobj(entity.Context.Data,'Precedence',2);
                if ~isempty(secImporter)
                    if ~isempty(activeImporter) && (activeImporter.Precedence == 2 || strcmpi(activeImporter.DataSource.DataSourceType,'AFAttribute'))
                        exportTagValue = {secImporter.SourceTag};
                    end
                end
                
                % report tertiary tag
                terImporter = findobj(entity.Context.Data,'Precedence',3);
                if ~isempty(terImporter)
                    if ~isempty(activeImporter) && activeImporter.Precedence == 3
                        exportTagValue = {terImporter.SourceTag};
                    end
                end
            end
%             % Find the plant name
%             exportPlantValue = entity.Context.Data(1).DataSource.Plant;
%             % report secondary tag
%             secImporter = findobj(entity.Context.Data,'Precedence',2);
%             if ~isempty(secImporter)
%                 if ~isempty(activeImporter) && activeImporter.Precedence == 2
%                     % Overwrite plant name
%                     exportPlantValue = secImporter.DataSource.Plant;
%                 end
%             end
%             
%             % report tertiary tag
%             terImporter = findobj(entity.Context.Data,'Precedence',3);
%             if ~isempty(terImporter)
%                 if ~isempty(activeImporter) && activeImporter.Precedence == 3
%                     % Overwrite plant name
%                     exportPlantValue = terImporter.DataSource.Plant;
%                 end
%             end
%         else
%             exportPlantValue = 'NaN';
        end
    end
elseif isa(entity,'struct')
    % Currently only when exporting analysis technique results the sensor from which
    % the tag name and plant name will be made up from is passed in as a structure
    
%     exportTagValue = entity.Context.ExportDetails.ExportTagValue;
    exportTagValue = {entity.Context.ExportTagValue};
%     exportPlantValue = entity.Context.ExportDetails.PlantName;
    exportPlantValue = {entity.Context.ExportPlantValue};
end

% Export plant as a string if it is a double (exp. 'NaN' if NaN)
indxNanPlant = cellfun(@isnumeric,exportPlantValue,'UniformOutput',false);
if any(cell2mat(indxNanPlant))
    for thisPlant = 1:numel(exportPlantValue)
        if numel(indxNanPlant{thisPlant}) == 1 % otherwise plant value a string
            exportPlantValue{thisPlant} = num2str(exportPlantValue{thisPlant});
        end
    end
end

% Replace 'NaN' with a 'NAN'. SQL sees 'NaN' as an NULL input for a string
indxNanPlant = cellfun(@(x)strcmpi(x,'NaN'),exportPlantValue,'UniformOutput',false);
if any(cell2mat(indxNanPlant))
    for thisPlant = 1:numel(exportPlantValue)
        if numel(indxNanPlant{thisPlant}) == 1 % otherwise plant value a string
            exportPlantValue{thisPlant} = 'NAN';
        end
    end
end

% % Specific tag name
% if iscell(exportTagValue)
%     if isempty(strfind(exportTagValue{1},'OPM:')) || strfind(exportTagValue{1},'OPM:') ~= 1 % exportTagValue is a cell for sensorStats
%         exportTagValue = strcat('OPM:',exportTagValue);
%     end
% else
%     if isempty(strfind(exportTagValue,'OPM:')) || strfind(exportTagValue,'OPM:') ~= 1 % exportTagValue is a char for sensorfftanalysisFcn
%         exportTagValue = strcat('OPM:',exportTagValue);
%     end
% end