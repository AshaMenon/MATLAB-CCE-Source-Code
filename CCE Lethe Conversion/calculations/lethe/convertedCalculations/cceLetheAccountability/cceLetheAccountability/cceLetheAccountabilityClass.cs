using System;
using System.Collections.Generic;
using SharedLogger;
using NetCalculationState;
using System.Linq;

namespace cceLetheAccountability
{
    // Define inputs struct
    public struct Inputs
    {
        public double[] BUH;
        public DateTime[] BUHTimestamps;
        public double[] SampleHead;
        public DateTime[] SampleHeadTimestamps;

    }

    // Define parameters struct
    public struct Parameters
    {
        public int CalculationPeriodsToRun;
        public int CalculationPeriod;
        public string OutputTime;
        public int CalculateAtTime;
        public int CalculationPeriodOffset;
    }

    // Define outputs struct
    public struct Outputs
    {
        public double[] Accountability;
        public DateTime[] Timestamp;
    }

    public class cceLetheAccountabilityClass
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

                // Calculation logic goes here
                List<double> accountabilityList = new List<double>();
                List<DateTime> dateList = new List<DateTime>();

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

                List<DateTime> timeLims = new List<DateTime> { startTime, LastTime };

                List<Tuple<DateTime, double, double>> inputValues = new List<Tuple<DateTime, double, double>>();
                
                for (int iTime = 0; iTime < dateRange.Length; iTime++)
                {
                    inputValues.Add(new Tuple<DateTime, Double, Double>(dateRange[iTime], getVal(sInputs.BUH, sInputs.BUHTimestamps, dateRange[iTime], double.NaN),
                        getVal(sInputs.SampleHead, sInputs.SampleHeadTimestamps, dateRange[iTime], 0)));
                }

                List<Tuple<DateTime, double, double>> filteredInputValues = new List<Tuple<DateTime, double, double>>();
                filteredInputValues.AddRange(inputValues.Where(v => v.Item1 >= timeLims[0] & v.Item1 <= timeLims[1]));

                for (int iTime = 0; iTime < filteredInputValues.Count; iTime++)
                {
                    try
                    {
                        if (filteredInputValues[iTime].Item3 != 0)
                        {
                            double accountability = filteredInputValues[iTime].Item2 / filteredInputValues[iTime].Item3 * 100;
                            accountabilityList.Add(accountability);
                            dateList.Add(filteredInputValues[iTime].Item1);

                            var msg = string.Format("Accountability value at time: {0} is {1}", filteredInputValues[iTime].Item1.ToString(), accountability);
                            LogInstance.logTrace(msg);
                        }
                        else
                        {
                            double nanVal = double.NaN;
                            accountabilityList.Add(nanVal);

                            var msg = string.Format("Calculation Sum Error. No good results from '{0}' ", filteredInputValues[iTime].Item1.ToString());
                            LogInstance.logError(msg);
                            //ErrorCode = CalculationErrorState.BadInput;
                        }
                    }
                    catch (Exception e)
                    {
                        double nanVal = double.NaN;
                        accountabilityList.Add(nanVal);
                        dateList.Add(filteredInputValues[iTime].Item1);

                        var msg = string.Format("Calculation Accountability loop Error for calculation time '{0}'. Error message: {1} ", filteredInputValues[iTime].Item1.ToString(), e.Message);
                        LogInstance.logError(msg);
                        throw new Exception(msg);
                    }

                }

                sOutputs.Accountability = accountabilityList.ToArray();

                // Timestamps
                sOutputs.Timestamp = filteredInputValues.Select(v => v.Item1).ToArray();

                if (sOutputs.Accountability.Length == 0)
                {
                    sOutputs.Accountability = new double[] { double.NaN };
                    sOutputs.Timestamp = new DateTime[] { dateRange.Last() };
                }

            }
            catch (Exception e)
            {
                // Return empty outputs
                double[] tempArray = { };
                sOutputs.Accountability = tempArray;
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

        private static double getVal(double[] values, DateTime[] times, DateTime curDate, double defaultVal)
        {
            double outVal;

            int idx = Array.IndexOf(times, curDate);

            if (idx >= 0)
            {
                outVal = values[idx];
            }
            else
            {
                outVal = defaultVal;
            }

            return outVal;
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


