classdef SimultaneousEventsNoQueue < handle
    %SIMULTANEOUSEVENTSNOQUEUE is a demonstration of events raised with no event queue.
    %The event listener property is set to false (default), preventing continued listening
    %for (and queueing of) events while the event callback is executing.
    
    properties
        TimerEvents
        EventCount
    end
    
    methods
        function this = SimultaneousEventsNoQueue()
            %SIMULTANEOUSEVENTSNOQUEUE Construct an instance of this class
            
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
            %Set the Recursive property to false (default) prevents queueing of events in
            %MATLAB. While executing the callback MATLAB will not be listening for new
            %events. Events raise during callback execution will be missed.
            elistener.Recursive = false; 
            
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
            fprintf('\tEvent Triggered. Event Data Returned: %i\n', this.EventCount);
            pause(1.5)
            fprintf('\t\t%i Rest of callback execution after a pause\n', this.EventCount);
        end
    end
end

