using System;
using System.Collections.Generic;
using SharedLogger;
using NetCalculationState;
using System.Linq;

namespace cceLetheSubstitute
{
    // Define inputs struct
    public struct Inputs
    {
        public double[] Estimate;
        public double[] Ma;
        public double[] Input;
        public double[] Minpas;
        public double[] Mog;

        public string[] EstimateSuffixes;
        public string[] MaSuffixes;
        public string[] InputSuffixes;
        public string[] MinpasSuffixes;
        public string[] MogSuffixes;

        public DateTime[] EstimateTimestamps;
        public DateTime[] MaTimestamps;
        public DateTime[] InputTimestamps;
        public DateTime[] MinpasTimestamps;
        public DateTime[] MogTimestamps;
    }

    // Define parameters struct
    public struct Parameters
    {
        public int CalculationPeriodsToRun;
        public double InputMax;
        public double InputMin;
        public int CalculationPeriod;
        public string OutputTime;
        public int CalculateAtTime;
        public int CalculationPeriodOffset;
    }

    // Define outputs struct
    public struct Outputs
    {
        public double[] Output;
        public double[] LevelUsed;
        public DateTime[] Timestamp;
    }

    public class cceLetheSubstituteClass
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
                DateTime[] combinedDates;

                combinedDates = sInputs.EstimateTimestamps.Concat(sInputs.InputTimestamps).ToArray();
                combinedDates = combinedDates.Concat(sInputs.MaTimestamps).ToArray();
                combinedDates = combinedDates.Concat(sInputs.MinpasTimestamps).ToArray();
                combinedDates = combinedDates.Concat(sInputs.MogTimestamps).ToArray();

                combinedDates = combinedDates.Distinct().ToArray();

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

                List<Tuple<DateTime>> inputValues = new List<Tuple<DateTime>>();
                for (int iTime = 0; iTime < combinedDates.Length; iTime++)
                {
                    inputValues.Add(new Tuple<DateTime>(combinedDates[iTime]));
                }

                List<Tuple<DateTime>> filteredInputValues = new List<Tuple<DateTime>>();
                filteredInputValues.AddRange(inputValues.Where(v => v.Item1 >= timeLims[0] & v.Item1 <= timeLims[1]));

                List<double> subList = new List<double>();
                List<double> levelList = new List<double>();
                List<DateTime> dateList = new List<DateTime>();
                

                for (int iTime = 0; iTime < dateRange.Length; iTime++)
                {
                    DateTime currentDate = dateRange[iTime];


                    List<Tuple<double, DateTime, double>> substitutes = new List<Tuple<double, DateTime, double>>();
                    try
                    {
                        substitutes.Add(new Tuple<double, DateTime, double>(GetSuffix(sInputs.EstimateSuffixes), GetLatestDate(sInputs.EstimateTimestamps, currentDate), GetValueAtTime(sInputs.EstimateTimestamps, currentDate, sInputs.Estimate)));
                    }
                    catch { }

                    try
                    {
                        substitutes.Add(new Tuple<double, DateTime, double>(GetSuffix(sInputs.InputSuffixes), GetLatestDate(sInputs.InputTimestamps, currentDate), GetValueAtTime(sInputs.InputTimestamps, currentDate, sInputs.Input)));
                    }
                    catch { }

                    try
                    {
                        substitutes.Add(new Tuple<double, DateTime, double>(GetSuffix(sInputs.MaSuffixes), GetLatestDate(sInputs.MaTimestamps, currentDate), GetValueAtTime(sInputs.MaTimestamps, currentDate, sInputs.Ma)));
                    }
                    catch { }

                    try
                    {
                        substitutes.Add(new Tuple<double, DateTime, double>(GetSuffix(sInputs.MinpasSuffixes), GetLatestDate(sInputs.MinpasTimestamps, currentDate), GetValueAtTime(sInputs.MinpasTimestamps, currentDate, sInputs.Minpas)));
                    }
                    catch { }

                    try
                    {
                        substitutes.Add(new Tuple<double, DateTime, double>(GetSuffix(sInputs.MogSuffixes), GetLatestDate(sInputs.MogTimestamps, currentDate), GetValueAtTime(sInputs.MogTimestamps, currentDate, sInputs.Mog)));
                    }
                    catch { }

                    var orderdSubs = substitutes.OrderByDescending(i => i.Item2).ToList();

                    double sub;
                    double level;

                    try
                    {
                        sub = orderdSubs[0].Item3;
                        level = orderdSubs[0].Item1;
                    }
                    catch {
                        sub = double.NaN;
                        level = double.NaN;
                    }

                    if (sub < sParams.InputMin || sub > sParams.InputMax) //If not in range level = 99
                    {
                        level = 99;
                    }

                    subList.Add(sub);
                    levelList.Add(level);
                    dateList.Add(dateRange[iTime]);

                    var msg = string.Format("Substitute at time: {0} is {1}", currentDate.ToString(), sub);
                    LogInstance.logTrace(msg);

                    var levelMsg = string.Format("Level at time: {0} is {1}", currentDate.ToString(), level);
                    LogInstance.logTrace(levelMsg);
                    }
                
                sOutputs.Output = subList.ToArray();
                sOutputs.LevelUsed = levelList.ToArray();
                sOutputs.Timestamp = dateList.ToArray();

                if (sOutputs.Output.Length == 0 & sOutputs.LevelUsed.Length == 0)
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
            filteredDates.OrderByDescending(i => i);

            return filteredDates.Last();
        }

        private double GetLatestValue(DateTime[] dateArray, DateTime currentDate, double[] valArray)
        {
            DateTime latestDate = GetLatestDate(dateArray, currentDate);
            int index = Array.IndexOf(dateArray, latestDate);

            return valArray[index];
        }

        private double GetValueAtTime(DateTime[] dateArray, DateTime currentDate, double[] valArray)
        {
            double output;
            int index = Array.IndexOf(dateArray, currentDate);

            if (index >= 0)
            {
                output = valArray[index];
            } else
            {
                output = double.NaN;
            }
            return output;
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


