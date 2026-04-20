classdef TagStates

    properties
        Order 
        tagName string
        RawtagName string
        currentEvent datetime
        lastEvent  datetime
        eventHistory  datetime
        OPMEventActive boolean
    end

    methods
        function obj = TagState(TagoutOfSigma,EventwindowStartTime,CurrentCalculationTime,...
                TimeToCheck,ActivateState,DeactivateState)
           
        obj.Order = Order;
        obj.tagName = strtrim(Name);
        obj.RawtagName = strtrim(RawName);
        obj.currentEvent = [];
        obj.lastEvent = [];
        obj.eventHistory = [];
        obj.OPMEventActive = 0;

        
        Update(obj,ModelState, TagoutOfSigma, EventwindowStartTime, CurrentCalculationTime, [], TimeToCheck, ...
                ActivateState, DeactivateState)

        end


        function Update(obj,ModelState, TagoutOfSigma, EventwindowStartTime, CurrentCalculationTime, ~, TimeToCheck, ...
                ActivateState, DeactivateState)

            % Set current tag state
            % If any sensor TRUE & ALARM STATUS (.Event tag) is "HIHI" then that sensor is assigned a SENSOR STATUS of "HIHI" else  No Alarm”
            TagState = OPMEnums.State.NoAlarm;

            if ModelState == OPMEnums.State.HiHi && TagoutOfSigma==1
                TagState = OPMEnums.State.HiHi;
            end


            % Update state lists
            % On first run Me.currentEvent = Nothing, then set current event = to input event
            if isnan(obj.currentEvent)
                obj.currentEvent = EventPeriod(TagState, CurrentCalculationTime, CurrentCalculationTime);

            else
                % Update current event to calculation time, any old states extent to the current calculation time
                % Update current event to time - this is only relevant here.
                Me.currentEvent.activeTo = CurrentCalculationTime;

                obj.currentEvent.activeTo = CurrentCalculationTime;
                activeToIdx =  obj.currentEvent.activeTo <  EventwindowStartTime ...
                    && obj.currentEvent.activeTo > CurrentCalculationTime;
                obj.currentEvent.activeTo(activeToIdx) = [];

                activeFromIdx =  obj.currentEvent.activeFrom <  EventwindowStartTime ...
                    && obj.currentEvent.activeFrom > CurrentCalculationTime;
                obj.currentEvent.activeFrom(activeFromIdx) = [];

            end


            if obj.currentEvent.eventState ~= TagState

                % Move current event to history and add a new current event
                idx = ismember(obj.currentEvent.activeFrom,obj.eventHistor);
                if sum(idx) ~= 0
                    % Do nothing because date already matches

                else
                    obj.eventHistory = [obj.eventHistory; obj.currentEvent.activeFrom, obj.currentEvent];
                end

                obj.currentEvent = EventPeriod(TagState, CurrentCalculationTime, CurrentCalculationTime);

            end


            % If 1 state then other operations are not needed
            if Me.currentEvent.activeFrom > EventwindowStartTime

                if numel(obj.eventHistory) > 0
                    % Find events in history to remove and find new evetn to become last event.
                    oldEvents = obj.eventHistory.activeFrom(obj.eventHistory.activeFrom <= EventwindowStartTime);

                    if numel(oldEvents) > 0
                        % Get last event in history to become new last event
                        obj.lastEvent = obj.eventHistory(max(oldEvents));

                        % Remove old history, could remove all
                        oldEvents =[];

                    end
                end

                % Trim last event to window
                if ~isnan(obj.lastEvent)
                    % Update last event to window times

                    activeFromIdx =  obj.lastEvent.activeFrom <  EventwindowStartTime ...
                        && obj.lastEvent.activeFrom > CurrentCalculationTime;
                    obj.lastEvent.activeFrom(activeFromIdx) = [];

                    activeToIdx =  obj.lastEvent.active <  EventwindowStartTime ...
                        && obj.lastEvent.activeTo > CurrentCalculationTime;
                    obj.lastEvent.activeTo(activeToIdx) = [];

                end


            else
                % Current event spans the window period
                obj.eventHistory = [];
                if obj.currentEvent.Duration ~= 0
                    if ~isnan(obj.lastEvent)
                        obj.lastEvent.EventwindowStartTime = 0;
                    end
                end
            end

            UpdateEventIsActive(ModelState, TimeToCheck, ActivateState, DeactivateState)

    
      end

        function Update_old(obj,ModelState, TagState, EventwindowStartTime, CurrentCalculationTime,...
                ~, TimeToCheck, ActivateState, DeactivateState)

            % On first run Me.currentEvent = Nothing, then set current event = to input event
            if isnan(obj.currentEvent)
                obj.currentEvent = EventPeriod(obj.currentEvent,TagState, CurrentCalculationTime, CurrentCalculationTime);
            else
                % Update current event to calculation time, any old states extent to the current calculation time
                % Update current event to time - this is only relevant here.
                obj.currentEvent.activeTo = CurrentCalculationTime;
                activeToIdx =  obj.currentEvent.activeTo <  EventwindowStartTime ...
                    && obj.currentEvent.activeTo > CurrentCalculationTime;
                obj.currentEvent.activeTo(activeToIdx) = [];

                activeFromIdx =  obj.currentEvent.activeFrom <  EventwindowStartTime ...
                    && obj.currentEvent.activeFrom > CurrentCalculationTime;
                obj.currentEvent.activeFrom(activeFromIdx) = [];
            end 


            if obj.currentEvent.eventState ~= TagState 
  
                % Move current event to history and add a new current event
                idx = ismember(obj.currentEvent.activeFrom,obj.eventHistor);
                if sum(idx) ~= 0
                    % Do nothing because date already matches
                    
                else
                    obj.eventHistory = [obj.eventHistory; obj.currentEvent.activeFrom, obj.currentEvent];
                end 

                obj.currentEvent = EventPeriod(TagState, CurrentCalculationTime, CurrentCalculationTime);

            end 


            % If 1 state then other operations are not needed
            if Me.currentEvent.activeFrom > EventwindowStartTime

                if numel(obj.eventHistory) > 0
                    % Find events in history to remove and find new evetn to become last event.
                    oldEvents = obj.eventHistory.activeFrom(obj.eventHistory.activeFrom <= EventwindowStartTime);

                    if numel(oldEvents) > 0
                        % Get last event in history to become new last event
                        obj.lastEvent = obj.eventHistory(max(oldEvents));

                        % Remove old history, could remove all
                        oldEvents = [];

                    end
                end

                % Trim last event to window
                if ~isnan(obj.lastEvent)
                    % Update last event to window times

                    activeFromIdx =  obj.lastEvent.activeFrom <  EventwindowStartTime ...
                        && obj.lastEvent.activeFrom > CurrentCalculationTime;
                    obj.lastEvent.activeFrom(activeFromIdx) = [];

                    activeToIdx =  obj.lastEvent.active <  EventwindowStartTime ...
                        && obj.lastEvent.activeTo > CurrentCalculationTime;
                    obj.lastEvent.activeTo(activeToIdx) = [];

                end


            else
                % Current event spans the window period
                obj.eventHistory = [];
                if obj.currentEvent.Duration ~= 0
                    if ~isnan(obj.lastEvent)
                        obj.lastEvent.EventwindowStartTime = 0;
                    end 
                end 
            end

            UpdateEventIsActive(ModelState, TimeToCheck, ActivateState, DeactivateState)

    end 

        function UpdateEventIsActive(obj,ModleState, TimeToCheck, ActivateState, DeactivateState)

            if obj.OPMEventActive == 1
              % state already active, model state to deactivate state, if  equal or less then end state
               if ModleState <= DeactivateState 
                   obj.OPMEventActive = 0;
               end 
            % Use time of state above to update time

            else
            % To activate, check activate state time is greater than or equal to time
                if TimeOfState(ActivateState) >= TimeToCheck 
                  obj.OPMEventActive = 1;
                end 
            end 


         end 
        function TotalSeconds = TimeOfState(obj,State) 

            TotalSeconds = 0;

            if numel(obj.eventHistory) > 0 
               TotalSeconds = sum(DurationForStateGE(obj,obj.eventHistory,State));
            end 
        

            if ~isnan(obj.currentEvent)
               TotalSeconds = TotalSeconds + DurationForStateGE(obj,obj.currentEvent,State);
            end 

            if ~isnan(Me.lastEvent) 
               TotalSeconds = TotalSeconds + DurationForStateGE(obj,obj.lastEvent,State);
            end 

        end 

        function duration = DurationForStateGE(obj,eventDate,State) 

            if (obj.eventState) >= (State)
                duration = seconds(eventDate);

            else
                duration = 0;
            end

        end 

        function retSt = ToStringList(obj) 
  
            retSt = [];

            retSt = [retSt; (Orderfilename(num2str(obj.Order)) + ", " + obj.Order)];
            retSt = [retSt;(Namefilename(num2str(obj.Order)) + ", " + obj.tagName)];
            retSt = [retSt; (RawNamefilename(num2str(obj.Order)) + ", " + obj.RawtagName)];

            if isnan(obj.currentEvent) 
              retSt = [retSt; (currentEventfilename(num2str(obj.Order)) + ", " + "Nothing")];
            else
              retSt = [retSt; (currentEventfilename(num2str(obj.Order)) + ", " + obj.currentEvent.ToString)];
            end 

            if isnan(obj.lastEvent) 
              retSt = [retSt; (lastEventfilename(num2str(obj.Order)) + ", " + "Nothing")];
            else
              retSt = [retSt;(lastEventfilename(um2str(obj.Order)) + ", " + Me.lastEvent.ToString)];
            end 


            c = 1;
            for iEv = 1:numel(obj.eventHistory)
               ev = Me.eventHistory(iEv);
               retSt = [retSt;(historyEventfilename(num2str(obj.Order), num2str(c)) + ", " + datestr(ev))];
               c = c + 1;
            end

        end

        function combinedStr = Orderfilename(Order) 
            combinedStr = Order + "-Order";
        end 

        function combinedStr = Namefilename(Order) 
          combinedStr =  Order + "-Name";
        end 

        function combinedStr = RawNamefilename(Order) 
          combinedStr = Order + "-RawName";
        end 

        function combinedStr = currentEventfilename(Order) 
          combinedStr =  Order + "-currentEvent";
        end 

        function combinedStr = lastEventfilename(Order)
          combinedStr = Order + "-lastEvent";
        end 

        function combinedStr = historyEventfilename(Order, SubOrder) 
          combinedStr = Order + "-History" + SubOrder;
        end 
        function EventPeriod(obj,eventState, activeFrom, activeTo)

            obj.eventState = eventState;
            obj.activeFrom = activeFrom;
            obj.activeTo = activeTo;

        end
     end
    
end