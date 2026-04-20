from enum import Enum

class CalculationErrorState(Enum):
    #CALCULATIONERRORSTATE Uses AF System Digital States for the error code.
    #Specific enumerations can be added to allow for the extension of Calculation Error States.
        
    CALCULATIONSERVERINVALID = 0 #The CalculationServer parameter is incorrectly configured.
    CALCULATIONNAMEUNKNOWN = 1 #The ComponentName parameter is not known on the server.
    EXECUTIONFREQUENCYINVALID = 2 #The execution frequency is set to 0 or is missing for a Cyclic calculation.
    LOGNAMEINVALID = 3 #The LogName is not a valid file name.
    CALCULATIONSTATEINVALID = 4 #The CalculationState parameter is not a PI Point or the PI Point is not available or is not a digital state type.
    LASTCALCTIMEINVALID = 5 #The LastCalculationTime parameter is not a PI Point or the PI Point is not available.
    INPUTCONFIGINVALID = 6 #An input configuration is not defined properly.
    INPUTTIMERANGEINVALID = 7 #An input’s RelativeTimeRange is not valid.
    OUTPUTCONFIGINVALID = 8 #An output does not specify a valid or reachable PI Point.
    SERVEROFFLINE = 9 #The CalculationServer cannot be reached.
    QUEUETIMEOUT = 10 #The Calculation remained in the queue for too long.
    UNHANDLEDEXCEPTION = 11 #The calculation failed and did not handle the error internally.
    CIRCULARDEPENDENCYCHAIN = 12 #The Calculation is part of a circular dependency chain.
    RETIREDCALCULATIONDEPENDENCY = 13 #The Calculation is dependent on a retired Calculation.
    CONFIGURATIONERROR = 14 #General Calculation configuration error - missing PI Points or Attributes are unexpected datatypes.


    NORESULT = 212 #No Result.
    NOLABDATA = 216 #No Lab Data.
    CALCOFF = 245 #Calculations Off state.
    #NoData - Data-retrieval functions use this state for time periods where no archive values
    #for a tag can exist 10 minutes into the future or before the oldest mounted
    #archive.
    NODATA = 248 
    CALCFAILED = 249 #Calculation Failed state.
    UNDERRANGE = 251 #Indicates a value that is less than the zero for the tag.
    OVERRANGE = 252 #Indicates a value that is greater than the top of range (Zero+Span) for that tag.
    BADINPUT = 255 #Interfaces use this state to indicate that a device is reporting bad status.
    GOOD = 305 #Good state.
    BAD = 307 #Bad state.
    COMMFAIL = 313 #Comm Fail state.
