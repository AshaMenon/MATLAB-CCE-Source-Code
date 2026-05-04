using System;

namespace NetCalculationState
{
    public enum CalculationErrorState
    {
        CalculationServerInvalid = 0, //The CalculationServer parameter is incorrectly configured.
        CalculationNameUnknown = 1, //The ComponentName parameter is not known on the server.
        ExecutionFrequencyInvalid = 2, //The execution frequency is set to 0 or is missing for a Cyclic calculation.
        LogNameInvalid = 3, //The LogName is not a valid file name.
        CalculationStateInvalid = 4, //The CalculationState parameter is not a PI Point, or the PI Point is not available or is not a digital state type.
        LastCalcTimeInvalid = 5, //The LastCalculationTime parameter is not a PI Point, or the PI Point is not available.
        InputConfigInvalid = 6, //An input configuration is not defined properly.
        InputTimeRangeInvalid = 7, //An input's RelativeTimeRange is not valid.
        OutputConfigInvalid = 8, //An output does not specify a valid or reachable PI Point.
        ServerOffline = 9, //The CalculationServer cannot be reached.
        QueueTimeout = 10, //The Calculation remained in the queue for too long.
        UnhandledException = 11, //The calculation failed and did not handle the error internally.
        CircularDependencyChain = 12, //The Calculation is part of a circular dependency chain.
        RetiredCalculationDependency = 13, //The Calculation is dependent on a retired Calculation.
        ConfigurationError = 14, //General Calculation configuration error - missing PI Points or Attributes are unexpected datatypes.


        NoResult = 212, //No Result.
        NoLabData = 216, //No Lab Data.
        CalcOff = 245, //Calculations Off state.
        //NoData - Data-retrieval functions use this state for time periods where no archive values
        //for a tag can exist 10 minutes into the future or before the oldest mounted
        //archive.
        NoData = 248,
        CalcFailed = 249, //Calculation Failed state.
        UnderRange = 251, //Indicates a value that is less than the zero for the tag.
        OverRange = 252, //Indicates a value that is greater than the top of range (Zero+Span) for that tag.
        BadInput = 255, //Interfaces use this state to indicate that a device is reporting bad status.
        Good = 305, //Good state.
        Bad = 307, //Bad state.
        CommFail = 313 //Comm Fail state.

    }
}
