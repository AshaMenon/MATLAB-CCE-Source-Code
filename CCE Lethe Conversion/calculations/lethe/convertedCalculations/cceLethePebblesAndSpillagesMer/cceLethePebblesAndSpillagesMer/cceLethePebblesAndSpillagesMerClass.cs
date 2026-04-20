using System;
using System.Collections.Generic;
using SharedLogger;
using NetCalculationState;

namespace cceLethePebblesAndSpillagesMer
{
    // Define inputs struct
    public struct Inputs
    {
        public double[] DryFeedMer;
        public double[] Pebbles;
        public double[] Run;
        public double[] Spillages;

        public DateTime[] DryFeedMerTimestamps;
        public DateTime[] PebblesTimestamps;
        public DateTime[] SpillagesTimestamps;
    }

    // Define parameters struct
    public struct Parameters
    {
        public int CalculationPeriodsToRun;
        public int CalculationPeriod;
        public int CalculateAtTime;
        public string OutputTime;
        public int CalculationPeriodOffset;
    }

    // Define outputs struct
    public struct Outputs
    {
        public double[] MilledMer;
        public double[] PebblesMer;
        public double[] SpillagesMer;
        public DateTime[] Timestamp;
    }

    public class cceLethePebblesAndSpillagesMerClass
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
                List<double> MilledMerList = new List<double>();
                List<double> PebblesMerList = new List<double>();
                List<double> SpillagesMerList = new List<double>();

                bool outputRun = false;

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

                foreach (DateTime t in dateRange)
                {

                    double Pebble = GetValueAtTime(sInputs.Pebbles, sInputs.PebblesTimestamps, t);
                    double Spillages = GetValueAtTime(sInputs.Spillages, sInputs.SpillagesTimestamps, t);
                    double MilledMer = GetValueAtTime(sInputs.DryFeedMer, sInputs.DryFeedMerTimestamps, t);

                    double PebbleD = 0;
                    double SpillageD = 0;
                    double MilledD = 0;

                    if (!double.IsNaN(Pebble))
                    {
                        PebbleD = Pebble;
                    }
                    if (!double.IsNaN(Spillages))
                    {
                        SpillageD = Spillages;
                    }
                    if (!double.IsNaN(MilledMer))
                    {
                        MilledD = MilledMer;
                    }

                    if (PebbleD > 0 || SpillageD > 0)
                    {
                        foreach (DateTime d in dateRange)
                        {
                            if (MilledD > 0)
                            {
                                PebblesnSpillagesCalc(MilledMer, Spillages, Pebble, out double TotalMilledMer,
                                    out double TotalPebblesMer, out double TotalSpillagesMer, d);

                                MilledMerList.Add(TotalMilledMer);
                                PebblesMerList.Add(TotalPebblesMer);
                                SpillagesMerList.Add(TotalSpillagesMer);
                                outputRun = true;
                            }

                            else
                            {
                                outputRun = false;
                            }

                            if (outputRun)
                            {
                                { break; }
                            }
                        }
                    }
                    else
                    {
                        double TotalMilledMer = MilledMer;
                        double TotalPebblesMer = PebbleD;
                        double TotalSpillagesMer = SpillageD;
                        outputRun = false;

                        MilledMerList.Add(TotalMilledMer);
                        PebblesMerList.Add(TotalPebblesMer);
                        SpillagesMerList.Add(TotalSpillagesMer);

                        LogInstance.logTrace("MilledMer Value at: {0} is {1}", TotalMilledMer, t);
                        LogInstance.logTrace("PebblesMer Value at: {0} is {1}", TotalPebblesMer, t);
                        LogInstance.logTrace("SpillagesMer Value at: {0} is {1}", TotalSpillagesMer, t);
                    }
                }


                sOutputs.MilledMer = MilledMerList.ToArray();
                sOutputs.PebblesMer = PebblesMerList.ToArray();
                sOutputs.SpillagesMer = SpillagesMerList.ToArray();
                sOutputs.Timestamp = dateRange;
            }
            catch (Exception e)
            {
                // Return empty outputs
                double[] tempArray = { };
                sOutputs.MilledMer = tempArray;
                sOutputs.PebblesMer = tempArray;
                sOutputs.SpillagesMer = tempArray;
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

        private double GetValueAtTime(double[] inputVals, DateTime[] inputTimestamps, DateTime t)
        {
            double outputVal;
            int idx = Array.IndexOf(inputTimestamps, t);

            if (idx >= 0)
            {
                outputVal = inputVals[idx];
            } else
            {
                outputVal = double.NaN;
            }

            return outputVal;
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

        private void PebblesnSpillagesCalc(double MilledMer, double Spillages, double Pebbles, out double TotalMilledMer,
                        out double TotalPebblesMer, out double TotalSpillagesMer, DateTime d)
        {
            TotalPebblesMer = 0;
            TotalSpillagesMer = 0;
            TotalMilledMer = double.NaN;

            try
            {

                if (!double.IsNaN(MilledMer))
                {

                    double rawMilledMer = MilledMer;

                    if (rawMilledMer > 0)
                    {
                        TotalPebblesMer = Pebbles;

                        TotalSpillagesMer = Spillages;

                        TotalMilledMer = rawMilledMer - Pebbles - Spillages;
                    }

                }
                else
                {
                    //bad value or missing value from DryConcentrate mass use its error state if it has one
                    LogInstance.logError(" Error on calc Mer or UG2 returned no values for '{0}", d.ToString());
                }
            }
            catch (Exception e)
            {
                LogInstance.logError("Calculation Pepples Error on value calculation at '{0}'. Message: {1} ", d.ToString(), e.Message);
            }
        }
    }
}


