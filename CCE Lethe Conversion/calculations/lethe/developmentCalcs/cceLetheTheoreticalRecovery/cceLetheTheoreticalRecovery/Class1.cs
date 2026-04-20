using System;
using System.Collections.Generic;
using SharedLogger;
using NetCalculationState;

namespace calculationTemplate
{
    // Define inputs struct
    public struct Inputs
    {
        public int[] Input1;
        public int[] Input2;
        public double[] Input3;
        public string[] Input3Suffixes;
    }

    // Define parameters struct
    public struct Parameters
    {
        public int Parameter1;
        public int Parameter2;

        public int CalculationPeriodsToRun;
        public int CalculationPeriod;
        public int CalculateAtTime;
        public string OutputTime;
        public int CalculationPeriodOffset;
    }

    // Define outputs struct
    public struct Outputs
    {
        public int[] Output1;
        public int[] Output2;
        public DateTime[] Timestamp;
    }

    public class Class1
    {
        // Log Info
        public string LogName;
        public string CalculationID;
        public int LogLevel;
        public string CalculationName;
        public CalculationErrorState ErrorCode = (CalculationErrorState)305;
        public Logger LogInstance;

        public Outputs RunCalc(Parameters sParams, Inputs sInputs)
        {
            // Create Instance of output struct
            Outputs sOutputs;

            // Create logger
            Logger LogInstance = new Logger(LogName, CalculationID, CalculationName, (LogMessageLevel)LogLevel, "CCE_Calc_Logs");

            try
            {
                // Create dictionaries (optional, remove if none needed)
                Dictionary<string, double> egDict = new Dictionary<string, double>();
                AssignRollUpsToDictionary(ref egDict, sInputs.Input3Suffixes, sInputs.Input3);

                // Compute date range for calculation
                DateTime OutputTime = DateTime.Parse(sParams.OutputTime);
                OutputTime = OutputTime.ToLocalTime();

                TimeSpan calcPeriod = new TimeSpan(0, 0, sParams.CalculationPeriod);
                TimeSpan calcAtTime = new TimeSpan(0, 0, sParams.CalculateAtTime);

                // Get the last calculation time from the current time
                long ModTime = (OutputTime.Ticks - calcAtTime.Ticks) % calcPeriod.Ticks;
                DateTime LastTime = new DateTime(OutputTime.Ticks - ModTime, DateTimeKind.Local) + new TimeSpan(sParams.CalculationPeriodOffset * calcPeriod.Ticks);

                var lastTimeTraceMsg = string.Format("Current LastTime being used: {0} ", LastTime.ToString());
                LogInstance.logTrace(lastTimeTraceMsg);

                TimeSpan initTimeSpan = new TimeSpan(calcPeriod.Ticks * (sParams.CalculationPeriodsToRun - Math.Sign(sParams.CalculationPeriodsToRun)));
                DateTime startTime = LastTime + initTimeSpan;

                DateTime[] dateRange;
                dateRange = GetDateRange(startTime, LastTime, sParams.CalculationPeriod);

                // Calculation logic goes here
                int[] tempArray = { sInputs.Input1[0] + sParams.Parameter1 };
                sOutputs.Output1 = tempArray;
                sOutputs.Output2 = tempArray;
                sOutputs.Timestamp = new DateTime[] { new DateTime(2021, 10, 19, 10, 30, 50) };
            }
            catch (Exception e)
            {
                // Return empty outputs
                int[] tempArray = { };
                sOutputs.Output1 = tempArray;
                sOutputs.Output2 = tempArray;
                DateTime[] tempDate = { };
                sOutputs.Timestamp = tempDate;

                // Log issue
                string msg = e.Source + e.StackTrace + "." + e.Message;
                LogInstance.logError(msg);
                if (ErrorCode == CalculationErrorState.Good)
                {
                    ErrorCode = CalculationErrorState.CalcFailed;
                }
            }

            return sOutputs;
        }

        // AssignRollupsToDictionary adds suffixes as keys and corresponding values to dictionary
        // dict - Reference dictionary to add key-val pair to
        // suffixArray - string array which will make up keys
        // values - 1D array of values
        private void AssignRollUpsToDictionary(ref Dictionary<string, double> dict, string[] suffixArray, double[] values)
        {
            for (int i = 0; i < suffixArray.Length; i++)
            {
                string s = suffixArray[i];
                dict.Add(s, values[i]);
            }
        }

        public static DateTime[] GetDateRange(DateTime startDate, DateTime endDate, int secondsValue)
        {
            List<DateTime> datesList = new List<DateTime>();
            DateTime currentDate = startDate;

            while (currentDate <= endDate)
            {
                datesList.Add(currentDate);
                currentDate = currentDate.AddSeconds(secondsValue);
            }

            return datesList.ToArray();
        }
    }
}


