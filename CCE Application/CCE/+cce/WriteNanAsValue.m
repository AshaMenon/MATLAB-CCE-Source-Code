classdef WriteNanAsValue < uint32
    %WRITENANASVALUE Enumeration for NaN replacement values
    %   This contains all AFSystemStateCodes, along with NoOuput and NaN
    %

    % Copyright 2023 Opti-Num Solutions  (Pty) Ltd
    % Version: $Format:%ci$  ($Format:%h$)

    enumeration
        None (0)	            %No state specified. This state should not be used to create a system state set.
        NoOutput (1)             %Output not written for that timestamp
        NaN (2)                 %Value kept as a NaN
        AccessDenied (210)	    %AccessDenied state.
        NoSample (211)	        %No Sample state.
        NoResult (212)	        %No Result state.
        UnitDown (213)	        %Unit Down state.
        SampleBad (214)	        %Sample Bad state.
        EquipFail (215)	        %Equip Fail state.
        NoLabData (216)	        %No Lab Data state.
        Trace (217)	            %Trace state.
        DCSFailed (233)	        %DCS Failed state.
        BadOutput (237)	        %Bad Output state.
        ScanOff (238)	        %Scan Off state.
        ScanOn (239)	        %Scan On state.
        Configure (240)	        %Configure state.
        Failed (241)	        %Failed state.
        Error (242)	            %Error state.
        Execute (243)	        %Execute state.
        Filtered (244)	        %Filtered state.
        CalcOff (245)	        %Calculations Off state.
        IOTimeout (246)	        %Interfaces use this state to indicate that communication with a remote device has failed.
        SetToBad (247)	        %Set To Bad state.
        NoData (248)	        %Data-retrieval functions use this state for time periods where no archive values for a tag can exist 10 minutes into the future or before the oldest mounted archive.
        CalcFailed (249)	    %Calculation Failed state.
        CalcOverflow (250)	    %Calculation Overflow state.
        UnderRange (251)	    %For float16 point types, this state indicates a value that is less than the zero for the tag.
        OverRange (252)	        %For float16 point types, this state indicates a value that is greater than the top of range  (Zero+Span) for that tag.
        PointCreated (253)	    %This state is assigned to a tag when it is created. This is a tag's value before any value is entered into the system.
        Shutdown (254)	        %All tags that are configured to receive shutdown events are set to this state on system shutdown.
        BadInput (255)	        %Interfaces use this state to indicate that a device is reporting bad status.
        BadTotal (256)	        %Bad Total state.
        NoAlarm (257)	        %No Alarm state.
        OverUCL (258)	        %Over UCL state.
        UnderLCL (259)	        %Under LCL state.
        OverWL (260)	        %Over WL state.
        UnderWL (261)	        %Under WL state.
        Substituted (298)	    %Substituted state.
        InvalidData (299)	    %Invalid Data state.
        ScanTimeout (300)	    %Scan Timeout state.
        No_Sample (301)	        %No_Sample state.
        ArcOffline (302)	    %Used by data-retrieval functions to indicate a period of time not covered by any mounted archive.
        Good (305)	            %Good state.
        Bad (307)	            %Bad state.
        Doubtful (308)	        %Doubtful state.
        WrongType (309)	        %Wrong Type state.
        Overflow_st (310)	    %Overflow_st state.
        InterfaceShut (311)	    %Interface Shut state.
        OutOfService (312)	    %Out of Service state.
        CommFail (313)	        %Comm Fail state.
        NotConnect (314)	    %Not Connect state.
        CoercionFailed (315)	%Coercion Failed state.
        Snapfix	 (316)	        %Snapfix state.
        InvalidFloat (317)	    %Represents Nan  (Not a Number) in later some PI Data Archives.
        FutureDataUnsupported (318)	%Future Data Unsupported state, which represents the return from a data access call  (to a future tag) that is not supported.
    end

end

