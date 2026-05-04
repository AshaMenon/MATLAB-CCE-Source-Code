using System;
using System.Collections.Generic;
using System.Linq;
using SharedLogger;
using NetCalculationState;

namespace cceLetheControlledSubstitute
{
    // Define inputs struct
    public struct Inputs
    {
        public double[] FeedDrymass;        // control / interlock (no numeric suffix needed)
        public double[] OverrideAction;     // 1 = Override active
        public double[] OverrideSelection;  // not used
        public double[] UserOverride;       // usually suffix 8

        // Candidate signals (suffix controls priority)
        public double[] Mog;
        public double[] Minpas;
        public double[] Input;              // suffix 1 (rarely used but highest priority when present)
        public double[] Ma;
        public double[] Estimate;
        public double[] UserEstimate;

        // Suffix arrays (strings that end with ".N" or "_N")
        public string[] FeedDrymassSuffixes;
        public string[] OverrideActionSuffixes;
        public string[] OverrideSelectionSuffixes;
        public string[] UserOverrideSuffixes;
        public string[] MogSuffixes;
        public string[] MinpasSuffixes;
        public string[] InputSuffixes;
        public string[] MaSuffixes;
        public string[] EstimateSuffixes;
        public string[] UserEstimateSuffixes;

        // Timestamps
        public DateTime[] FeedDrymassTimestamps;
        public DateTime[] OverrideActionTimestamps;
        public DateTime[] OverrideSelectionTimestamps;
        public DateTime[] UserOverrideTimestamps;
        public DateTime[] MogTimestamps;
        public DateTime[] MinpasTimestamps;
        public DateTime[] InputTimestamps;
        public DateTime[] MaTimestamps;
        public DateTime[] EstimateTimestamps;
        public DateTime[] UserEstimateTimestamps;
    }

    // Define parameters struct
    public struct Parameters
    {
        public double InputMin;
        public double InputMax;
        public int CalculationPeriodsToRun;
        public int CalculationPeriod;   // seconds
        public int CalculateAtTime;     // seconds
        public string OutputTime;
        public int CalculationPeriodOffset;
    }

    // Define outputs struct
    public struct Outputs
    {
        public double[] Output;
        public double[] LevelUsed;
        public DateTime[] Timestamp;
    }

    public class cceLetheControlledSubstituteClass
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
            LogInstance = new Logger(LogName, CalculationID, CalculationName, (LogMessageLevel)LogLevel, "CCE_Calc_Logs");

            try
            {
                // --- Time grid ---
                DateTime baseOutputTime = DateTime.Parse(sParams.OutputTime).ToLocalTime();
                TimeSpan calcPeriod = TimeSpan.FromSeconds(sParams.CalculationPeriod);
                TimeSpan calcAtTime = TimeSpan.FromSeconds(sParams.CalculateAtTime);

                long modTime = (baseOutputTime.Ticks - calcAtTime.Ticks) % calcPeriod.Ticks;
                DateTime lastTime = new DateTime(baseOutputTime.Ticks - modTime, DateTimeKind.Local)
                                    + new TimeSpan(sParams.CalculationPeriodOffset * calcPeriod.Ticks);

                var lastTimeTraceMsg = string.Format("Current LastTime being used: {0} ", lastTime.ToString());
                LogInstance.logTrace(lastTimeTraceMsg);

                TimeSpan initTimeSpan = new TimeSpan(calcPeriod.Ticks * (sParams.CalculationPeriodsToRun - Math.Sign(sParams.CalculationPeriodsToRun)));
                DateTime startTime = lastTime + initTimeSpan;

                DateTime[] dateRange = GetDateRange(startTime, lastTime, sParams.CalculationPeriod);

                List<double> subList = new List<double>();
                List<double> levelList = new List<double>();
                List<DateTime> dateList = new List<DateTime>();

                for (int iTime = 0; iTime < dateRange.Length; iTime++)
                {
                    DateTime currentDate = dateRange[iTime];

                    double sub;
                    double level;

                    // --- FeedDrymass interlock ---
                    // If no feed is present the substitute is not meaningful.
                    double feedDrymass = GetLatestValue(sInputs.FeedDrymassTimestamps, currentDate, sInputs.FeedDrymass);
                    if (double.IsNaN(feedDrymass) || feedDrymass <= 0.0)
                    {
                        sub = double.NaN;
                        level = double.NaN;
                    }
                    else
                    {
                        // --- Override check ---
                        double overrideAction = GetLatestValue(sInputs.OverrideActionTimestamps, currentDate, sInputs.OverrideAction);

                        if (overrideAction == 1.0)
                        {
                            // Use operator UserOverride value directly.
                            sub = GetLatestValue(sInputs.UserOverrideTimestamps, currentDate, sInputs.UserOverride);
                            level = GetSuffix(sInputs.UserOverrideSuffixes);
                        }
                        else
                        {
                            // --- Build candidate map ordered by suffix number ---
                            // This is what makes "whoever is priority 2 is the master" automatically.
                            var candidates = new SortedDictionary<double, Tuple<double, DateTime>>();

                            TryAddCandidate(candidates, sInputs.InputSuffixes, sInputs.InputTimestamps, sInputs.Input, currentDate);
                            TryAddCandidate(candidates, sInputs.MogSuffixes, sInputs.MogTimestamps, sInputs.Mog, currentDate);
                            TryAddCandidate(candidates, sInputs.MinpasSuffixes, sInputs.MinpasTimestamps, sInputs.Minpas, currentDate);
                            TryAddCandidate(candidates, sInputs.MaSuffixes, sInputs.MaTimestamps, sInputs.Ma, currentDate);
                            TryAddCandidate(candidates, sInputs.EstimateSuffixes, sInputs.EstimateTimestamps, sInputs.Estimate, currentDate);
                            TryAddCandidate(candidates, sInputs.UserEstimateSuffixes, sInputs.UserEstimateTimestamps, sInputs.UserEstimate, currentDate);

                            if (candidates.Count > 0)
                            {
                                // First entry has the lowest suffix number = highest priority.
                                var best = candidates.First();
                                sub = best.Value.Item1;
                                level = best.Key;
                            }
                            else
                            {
                                sub = double.NaN;
                                level = double.NaN;
                            }
                        }
                    }

                    // --- Range check ---
                    if (!double.IsNaN(sub) && (sub < sParams.InputMin || sub > sParams.InputMax))
                    {
                        level = 99;
                    }

                    subList.Add(sub);
                    levelList.Add(level);
                    dateList.Add(currentDate);

                    var msg = string.Format("Substitute at time: {0} is {1}", currentDate.ToString(), sub);
                    LogInstance.logTrace(msg);

                    var levelMsg = string.Format("Level at time: {0} is {1}", currentDate.ToString(), level);
                    LogInstance.logTrace(levelMsg);
                }

                sOutputs.Output = subList.ToArray();
                sOutputs.LevelUsed = levelList.ToArray();
                sOutputs.Timestamp = dateList.ToArray();

                if (sOutputs.Output.Length == 0 && sOutputs.LevelUsed.Length == 0)
                {
                    sOutputs.Output = new double[] { double.NaN };
                    sOutputs.LevelUsed = new double[] { double.NaN };
                    sOutputs.Timestamp = new DateTime[] { dateRange.Last() };
                }
            }
            catch (Exception e)
            {
                // Return empty outputs
                double[] tempArray = { };
                sOutputs.Output = tempArray;
                sOutputs.LevelUsed = tempArray;
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

        // TryAddCandidate adds a candidate to the sorted dictionary if it has a valid
        // (non-NaN) latest value at or before currentDate.  The suffix number is used
        // as the key so that the SortedDictionary automatically orders candidates by
        // priority (lowest suffix = highest priority).
        private void TryAddCandidate(
            SortedDictionary<double, Tuple<double, DateTime>> dict,
            string[] suffixes,
            DateTime[] timestamps,
            double[] values,
            DateTime currentDate)
        {
            try
            {
                double suffix = GetSuffix(suffixes);
                DateTime latestDate = GetLatestDate(timestamps, currentDate);
                double value = GetLatestValue(timestamps, currentDate, values);

                if (!double.IsNaN(value) && !dict.ContainsKey(suffix))
                {
                    dict.Add(suffix, new Tuple<double, DateTime>(value, latestDate));
                }
            }
            catch { }
        }

        private double GetSuffix(string[] suffixArray)
        {
            string s = suffixArray[0];
            double d = 0;

            if (s.Contains("."))
            {
                string[] splitS = s.Split('.');
                d = Convert.ToDouble(splitS.Last());
            }
            else if (s.Contains("_"))
            {
                string[] splitS = s.Split('_');
                d = Convert.ToDouble(splitS.Last());
            }

            return d;
        }

        private DateTime GetLatestDate(DateTime[] dateArray, DateTime currentDate)
        {
            List<DateTime> filteredDates = new List<DateTime>();
            filteredDates.AddRange(dateArray.Where(dA => dA <= currentDate));
            filteredDates = filteredDates.OrderByDescending(i => i).ToList();

            return filteredDates.First();
        }

        private double GetLatestValue(DateTime[] dateArray, DateTime currentDate, double[] valArray)
        {
            DateTime latestDate = GetLatestDate(dateArray, currentDate);
            int index = Array.IndexOf(dateArray, latestDate);

            return valArray[index];
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
