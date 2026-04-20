using System;
using System.Collections.Generic;
using SharedLogger;
using NetCalculationState;
using System.Linq;

namespace cceLethePeriodWeighting
{
    // Define inputs struct
    public struct Inputs
    {
        public double[] Input;
        public double[] Weight;
        public DateTime[] InputTimestamps;
        public DateTime[] WeightTimestamps;
    }

    // Define parameters struct
    public struct Parameters
    {
        public bool ForceToZero;

        public int CalculationPeriodsToRun;
        public int CalculationPeriod;
        public int CalculateAtTime;
        public string OutputTime;
        public int CalculationPeriodOffset;
    }

    // Define outputs struct
    public struct Outputs
    {
        public double[] Weighted;
        public DateTime[] Timestamp;
    }

    public class cceLethePeriodWeightingClass
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
                // Initialise outputs
                List<double> WeightedList = new List<double>();

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

                List<Tuple<DateTime, double>> InputList = new List<Tuple<DateTime, double>>();
                List<Tuple<DateTime, double>> WeightList = new List<Tuple<DateTime, double>>();

                for (int iTime = 0; iTime < sInputs.InputTimestamps.Length; iTime++)
                {
                    InputList.Add(new Tuple<DateTime, double>(sInputs.InputTimestamps[iTime], sInputs.Input[iTime]));
                }
                for (int iTime = 0; iTime < sInputs.InputTimestamps.Length; iTime++)
                {
                    WeightList.Add(new Tuple<DateTime, double>(sInputs.WeightTimestamps[iTime], sInputs.Weight[iTime]));
                }

                // Group Inputs
                var grouped = InputList.GroupJoin(WeightList, input => input.Item1, weight => weight.Item1, 
                    (input, weight) => new Tuple<DateTime, double, double>(input.Item1, input.Item2, 
                    weight.ToList().Select(r => r.Item2).DefaultIfEmpty(double.NaN).FirstOrDefault())).ToList();

                grouped.RemoveAll(g => double.IsNaN(g.Item2) | double.IsNaN(g.Item3));

                // Calculation logic goes here
                double Weighted;
                foreach (DateTime t in dateRange)
                {
                    List<Tuple<DateTime, double, double>> goodItemsInPeriod = new List<Tuple<DateTime, double, double>>();
                    goodItemsInPeriod.AddRange(grouped.Where(v => v.Item1.Date == t.Date));

                    if (goodItemsInPeriod.Count > 0)
                    {
                        double WeightSum = goodItemsInPeriod.Select(v => v.Item2 * v.Item3).Sum();
                        double TotalWeights = goodItemsInPeriod.Select(v => v.Item3).Sum();

                        Weighted = WeightSum / TotalWeights;
                        LogInstance.logTrace("Weighted value at: {0} is {1}", Weighted, t);
                    }
                    else
                    {
                        Weighted = double.NaN;
                        LogInstance.logError("Calculation period weighting Error. Day had a Bad result set from '{0}' ", t);
                    }

                    WeightedList.Add(Weighted);
                }


                sOutputs.Weighted = WeightedList.ToArray();
                sOutputs.Timestamp = dateRange;

                if (sOutputs.Weighted.Length == 0)
                {
                    sOutputs.Weighted = new double[] { double.NaN };
                    sOutputs.Timestamp = new DateTime[] { dateRange.Last() };
                }
            }
            catch (Exception e)
            {
                // Return empty outputs
                double[] tempArray = { };
                sOutputs.Weighted = tempArray;
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


