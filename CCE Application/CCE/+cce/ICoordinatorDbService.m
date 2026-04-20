classdef (Abstract) ICoordinatorDbService < handle
    %ICoordinatorDbService Coordinator Database interface
    %   This abstract class provides the interface to a Coordinator Record. A Coordinator Record
    %   serialises a Coordinator into a specific database. Each database implements a different
    %   serialisation process for each of the properties.
    %
    %   The Coordinator Database Service allows the user to commit changes to properties immediately, or
    %   through a final commit() method. To control this, use the AutoCommit property.

    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)
    
    methods (Static)
        cObj = findCoordinators(obj, id) % Find Coordinators with specific id
        cObj = findAllCoordinators(obj) % Find all Coordinators in teh database
        cObj = createCoordinator(obj, id, mode, frequency, offset, lifetime, calcLoad) % Create a new coordinator in the database
        removeCoordinator(obj, id) % Remove a Coordinator from the database
    end

end

