classdef EventTriggeredByTimerCount < handle
    %EVENTTRIGGEREDBYTIMERCOUNT is a demonstration of how to listen/ register for events
    %raised in a .NET assembly
    
    properties
        TimerEvents
        EventCount
    end
    
    methods
        function this = EventTriggeredByTimerCount()
            %EVENTTRIGGEREDBYTIMERCOUNT Construct an instance of this class
            
            NET.addAssembly('D:\Users\Projects\cce\cce\piEventListener\examples\ListenForDotNetEvents\NET\TimerEventsWithEventData.dll');
            this.TimerEvents = TimerEventsWithEventData.TimerEvents();
        end
        
        function startTimer(this, timerTickSeconds)
            %STARTTIMER Begin the .NET Timer with the input time interval,
            %TIMERTICKSECONDS (seconds) to invoke the Timer callback
            
            import System.*;
            import System.Threading.*;
            this.TimerEvents.StartTimer(TimeSpan.FromSeconds(timerTickSeconds));
        end
        
        function stopTimer(this)
            %STOPTIMER call the TimerEvents StopTimer method
            this.TimerEvents.StopTimer;
        end
        
        function [elistener, stopEvListener] = attachListeners(this)
            %ATTACHLISTENERS create event listeners for the TimerEvents events:
            %"TimerTriggered", and "TimerStopped".
            
            elistener = addlistener( ...
                this.TimerEvents, ...
                "TimerTriggered", ...
                @this.eventTriggered);
            elistener.Recursive = true; %Set the Recursive property to true to allow for event queueing in MATLAB
            
            stopEvListener = addlistener( ...
                this.TimerEvents, ...
                "TimerStopped", ...
                @this.countStopEventTriggered);
        end
        
        function countStopEventTriggered(~, ~, ~, ~)
            %COUNTSTOPEVENTTRIGGERED callback for TimerStopped event
            fprintf('\n\tStop Triggered\n');
        end
        
        function eventTriggered(this, ~, event, ~)
            %EVENTTRIGGERED callback for TimerTriggered event using event data from the
            %TimerEvents .NET assembly
            this.EventCount = event.CountTimerTicks;
            fprintf('\tEvent Triggered. Event Data Returned: %i\n', event.CountTimerTicks);
        end
    end
end

