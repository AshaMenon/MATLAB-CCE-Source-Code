classdef EventsFromObserver < handle
    %EVENTSFROMOBSERVER demonstrates how to use the .NET Observer Pattern Interface and
    %listen for 
    
    properties
        Observer
        Observable
    end
    
    methods
        function this = EventsFromObserver()
            %EVENTSFROMOBSERVER Construct an instance of this class
            
            NET.addAssembly('D:\Users\Projects\cce\cce\piEventListener\examples\IObserverPattern\NET\ObserverPatternRaiseEvents.dll');
            
        end
        
        function subscribeObserver(this, gpsType)
            % SUBSCRIBEOBSERVER instantiates the Observable and the Observer and
            % Subscribe the Observer with the Observable (to receive events)
            this.Observable = ObserverPatternRaiseEvents.LocationTracker;
            this.Observer = ObserverPatternRaiseEvents.LocationReporter(gpsType);
            this.Observable.Subscribe(this.Observer);
        end
        
        function updateLocation(this, lat, long)
            % UPDATELOCATION adds a new location to the Observable. 
            % The TrackLocation method makes a call to the OnNext method of the Observable
            % class resulting in a new event raised
            t = ObserverPatternRaiseEvents.Location(lat, long);
            this.Observable.TrackLocation(t);
        end
                
        function [elistener] = attachListener(this)
            %ATTACHLISTENERS create event listeners for the Observer event
            %"LocationTrackerUpdate"
            
            elistener = addlistener( ...
                this.Observer, ...
                "LocationTrackerUpdate", ...
                @this.eventTriggered);
            elistener.Recursive = true; %Set the Recursive property to true to allow for event queueing in MATLAB
        end
        
        function eventTriggered(this, ~, args, ~)
            %EVENTTRIGGERED callback for "LocationTrackerUpdate" event using event data
            %from the Observer class in the .NET assembly
            
            fprintf('\tEvent Triggered. \n\tLatitude: %.4f \n\tLongitude: %.4f \n\n', args.lat, args.lon);
        end
    end
end

