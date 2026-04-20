classdef AFDataPipe < handle
    %AFDataPipe
    
    %     properties (Access = 'private', Constant)
    %         DataConnector = af.AFDataConnector(cce.System.CalculationServerName, cce.System.CalculationDBName);
    %     end
    
    properties (SetAccess = 'private')
        SignedIDs (1, :) string = [];
    end
    properties (Access = 'private')
        DataPipe;
        Observer;
        
        SignedAttributeReferences (1, :) cell = {};
        SignedAttributeIDs (1, :) string = [];
    end
    
    methods (Static)
        function obj = getInstance()
            persistent singleton
            if isempty(singleton)
                singleton = cce.AFDataPipe();
            end
            obj = singleton;
        end
    end
    
    methods
        function addSignups(obj, attributes, ids)
            
            arguments
                obj
                attributes (1,:) cell
                ids (1,:) string
            end
            attIDs = strings(size(attributes));
            for c = 1:numel(attributes)
                dataReference = attributes{c}.DataReference;
                [dataReference] = cce.resolveDataReference(dataReference);
                if isempty(dataReference)
                    attIDs(c) = string(attributes{c}.UniqueID);
                else
                    if isa(dataReference, 'OSIsoft.AF.Asset.DataReference.PIPointDR')
                        attIDs(c) = string(dataReference.PIPoint.ID);
                    elseif isa(dataReference, 'OSIsoft.AF.Asset.AFAttribute')
                        attIDs(c) = string(dataReference.UniqueID);
                    elseif isa(dataReference, 'OSIsoft.AF.Asset.DataReference.FormulaDR')
                        attIDs(c) = string(dataReference.UniqueID);
                    end
                end
            end
            
            % Find attributes that are not already signed up for updates
            % If the attribute is not in the list, signup the attribute
            idxNewSignups = ~ismember(attIDs, obj.SignedAttributeIDs);
            indNewSignups = find(idxNewSignups);
            attributeList = NET.createGeneric('System.Collections.Generic.List', {'OSIsoft.AF.Asset.AFAttribute'}, 1);
            for c = 1:sum(idxNewSignups)
                Add(attributeList, attributes{indNewSignups(c)});
            end
            errs = obj.DataPipe.AddSignups(attributeList);
            obj.SignedAttributeReferences = [obj.SignedAttributeReferences, attributes(idxNewSignups)];
            obj.SignedIDs = [obj.SignedIDs, ids(idxNewSignups)];
            
            obj.SignedAttributeIDs = [obj.SignedAttributeIDs, attIDs(idxNewSignups)];
            
            % If the attribute is in the list and corresponds to a different ID, do not
            % signup again but add the attribute & the ID to the list
            if any(~idxNewSignups)
                locExisting = find(~idxNewSignups);
                existingAttIDs = attIDs(locExisting);
                mapIDs = ids(locExisting);
                idxAddMapping = false(size(existingAttIDs));
                
                for c = 1:numel(existingAttIDs)
                    idx = obj.SignedAttributeIDs == existingAttIDs(c);
                    existIDs = obj.SignedIDs(idx);
                    idxAddMapping(c) = all(existIDs ~= mapIDs(c));
                end
                
                mapAtts = attributes(locExisting);
                obj.SignedAttributeReferences = [obj.SignedAttributeReferences, mapAtts(idxAddMapping)];
                obj.SignedIDs = [obj.SignedIDs, mapIDs(idxAddMapping)];
                obj.SignedAttributeIDs = [obj.SignedAttributeIDs, existingAttIDs(idxAddMapping)];
            end
        end
        
        function removeSignUps(obj, ids)
            
            arguments
                obj
                ids (1,:) string
            end
            
            for c = 1:numel(ids)
                idxID = obj.SignedIDs == ids(c);
                attributeReferences = obj.SignedAttributeReferences(idxID);
                attributeList = convertToAttributeList(attributeReferences);
                for atts = 1:sum(idxID)
                    errs = obj.DataPipe.RemoveSignups(attributeList);
                end
                obj.SignedIDs(idxID) = [];
                obj.SignedAttributeReferences(idxID) = [];
                obj.SignedAttributeIDs(idxID) = [];
            end
        end
        
        function [ids, changeTime, action, previousAction, errs] = getNewEvents(obj)
            
            obj.Observer.Flush();
            obj.DataPipe.GetObserverEvents();
            
            ids = [];
            changeTime = [];
            action = [];
            previousAction = [];
            errs = [];
            for res = 1:obj.Observer.Results.Count
                result = obj.Observer.Results.Item(res-1);
                
                dataReference = result.Value.Attribute.DataReference;
                thisAction = string(result.Action);
                thisPrevAction = string(result.PreviousEventAction);
                [dataReference] = cce.resolveDataReference(dataReference);
                if isempty(dataReference)
                    attributeID = string(result.Value.Attribute.UniqueID);
                else
                    if isa(dataReference, 'OSIsoft.AF.Asset.DataReference.PIPointDR')
                        attributeID = string(dataReference.PIPoint.ID);
                    elseif isa(dataReference, 'OSIsoft.AF.Asset.AFAttribute')
                        attributeID = string(dataReference.UniqueID);
                    end
                end
                
                idx = obj.SignedAttributeIDs == attributeID;
                thisIds = unique(obj.SignedIDs(idx)); % This is the number of items we have
                ids = [ids, thisIds];  %#ok<AGROW>
                action = [action, repmat(thisAction,1, numel(thisIds))]; %#ok<AGROW> 
                previousAction = [previousAction, repmat(thisPrevAction,1, numel(thisIds))]; %#ok<AGROW> 
                if ismember(class(result), 'OSIsoft.AF.Data.AFDataPipeEvent')
                    updateTime = obj.Observer.Results.Item(res-1).Value.Timestamp.LocalTime;
                elseif ismember(class(result), 'OSIsoft.AF.Data.AFDataPipeEventWithChangeTime')
                    updateTime = result.ChangeTime.LocalTime;
                end
                changeTime = [changeTime, repmat(cce.parseNetDateTime(updateTime), 1, numel(thisIds))]; %#ok<AGROW>
            end
            if obj.Observer.Results.HasErrors
                
            end
        end
    end
    
    methods (Access = 'private')
        function obj = AFDataPipe()
            
            obj.DataPipe = OSIsoft.AF.Data.AFDataPipe();
            addObserver(obj);
        end
        
        function addObserver(obj)
            
            dataPipePath = fileparts(fileparts(mfilename('fullpath')));
            NET.addAssembly(fullfile(dataPipePath, 'coordinator', 'helpers', 'dataPipeObserver', 'DataPipeObserver.dll'));
            obj.Observer = DataPipeObserver.EventObserver;
            obj.DataPipe.Subscribe(obj.Observer);
        end
    end
    
    methods (Static, Access = 'private')
        function attributeList = convertToAttributeList(attributes)
            
            attributeList = NET.createGeneric('System.Collections.Generic.List', {'OSIsoft.AF.Asset.AFAttribute'}, 1);
            for c = 1:numel(attributes)
                Add(attributeList, attributes{c});
            end
        end
    end
end