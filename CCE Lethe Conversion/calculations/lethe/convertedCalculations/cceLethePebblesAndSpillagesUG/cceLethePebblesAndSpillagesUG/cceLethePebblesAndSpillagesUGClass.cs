using System;
using System.Collections.Generic;
using SharedLogger;
using NetCalculationState;

namespace cceLethePebblesAndSpillagesUG
{
    // Define inputs struct
    public struct Inputs
    {
        public double[] DryFeedUG1;
        public double[] DryFeedUG2;
        public double[] Pebbles;
        public double[] Run;
        public double[] Spillages;

        public DateTime[] DryFeedUG1Timestamps;
        public DateTime[] DryFeedUG2Timestamps;
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
        public double[] MilledUG1;
        public double[] PebblesUG1;
        public double[] SpillagesUG1;

        public double[] MilledUG2;
        public double[] PebblesUG2;
        public double[] SpillagesUG2;

        public DateTime[] Timestamp;
    }

    public class cceLethePebblesAndSpillagesUGClass
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
                List<double> MilledUG1List = new List<double>();
                List<double> PebblesUG1List = new List<double>();
                List<double> SpillagesUG1List = new List<double>();

                List<double> MilledUG2List = new List<double>();
                List<double> PebblesUG2List = new List<double>();
                List<double> SpillagesUG2List = new List<double>();

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
                    double MilledUG1 = GetValueAtTime(sInputs.DryFeedUG1, sInputs.DryFeedUG1Timestamps, t);
                    double MilledUG2 = GetValueAtTime(sInputs.DryFeedUG2, sInputs.DryFeedUG1Timestamps, t);

                    double PebbleD = 0;
                    double SpillageD = 0;
                    double MilledDUG1 = 0;
                    double MilledDUG2 = 0;

                    if (!double.IsNaN(Pebble))
                    {
                        PebbleD = Pebble;
                    }
                    if (!double.IsNaN(Spillages))
                    {
                        SpillageD = Spillages;
                    }
                    if (!double.IsNaN(MilledUG1))
                    {
                        MilledDUG1 = MilledUG1;
                    }
                    if (!double.IsNaN(MilledUG2))
                    {
                        MilledDUG2 = MilledUG2;
                    }

                    if (PebbleD > 0 || SpillageD > 0)
                    {
                        foreach (DateTime d in dateRange)
                        {
                            if (MilledDUG1 > 0)
                            {
                                PebblesnSpillagesCalc(MilledUG1, MilledUG2, Spillages, Pebble, out double TotalMilledUG1,
                                    out double TotalPebblesUG1, out double TotalSpillagesUG1, out double TotalMilledUG2,
                                    out double TotalPebblesUG2, out double TotalSpillagesUG2, d);

                                MilledUG1List.Add(TotalMilledUG1);
                                PebblesUG1List.Add(TotalPebblesUG1);
                                SpillagesUG1List.Add(TotalSpillagesUG1);

                                MilledUG2List.Add(TotalMilledUG2);
                                PebblesUG2List.Add(TotalPebblesUG2);
                                SpillagesUG2List.Add(TotalSpillagesUG2);
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
                        double TotalMilledUG1 = MilledUG1;
                        double TotalPebblesUG1 = PebbleD;
                        double TotalSpillagesUG1 = SpillageD;

                        double TotalMilledUG2 = MilledUG2;
                        double TotalPebblesUG2 = PebbleD;
                        double TotalSpillagesUG2 = SpillageD;
                        outputRun = false;

                        MilledUG1List.Add(TotalMilledUG1);
                        PebblesUG1List.Add(TotalPebblesUG1);
                        SpillagesUG1List.Add(TotalSpillagesUG1);

                        MilledUG2List.Add(TotalMilledUG2);
                        PebblesUG2List.Add(TotalPebblesUG2);
                        SpillagesUG2List.Add(TotalSpillagesUG2);

                        LogInstance.logTrace("MilledUG1 Value at: {0} is {1}", TotalMilledUG1, t);
                        LogInstance.logTrace("PebblesUG1 Value at: {0} is {1}", TotalPebblesUG1, t);
                        LogInstance.logTrace("SpillagesUG1 Value at: {0} is {1}", TotalSpillagesUG1, t);

                        LogInstance.logTrace("MilledUG2 Value at: {0} is {1}", TotalMilledUG2, t);
                        LogInstance.logTrace("PebblesUG2 Value at: {0} is {1}", TotalPebblesUG2, t);
                        LogInstance.logTrace("SpillagesUG2 Value at: {0} is {1}", TotalSpillagesUG2, t);
                    }
                }


                sOutputs.MilledUG1 = MilledUG1List.ToArray();
                sOutputs.PebblesUG1 = PebblesUG1List.ToArray();
                sOutputs.SpillagesUG1 = SpillagesUG1List.ToArray();
                sOutputs.MilledUG2 = MilledUG2List.ToArray();
                sOutputs.PebblesUG2 = PebblesUG2List.ToArray();
                sOutputs.SpillagesUG2 = SpillagesUG2List.ToArray();
                sOutputs.Timestamp = dateRange;
            }
            catch (Exception e)
            {
                // Return empty outputs
                double[] tempArray = { };
                sOutputs.MilledUG1 = tempArray;
                sOutputs.PebblesUG1 = tempArray;
                sOutputs.SpillagesUG1 = tempArray;
                sOutputs.MilledUG2 = tempArray;
                sOutputs.PebblesUG2 = tempArray;
                sOutputs.SpillagesUG2 = tempArray;
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
            }
            else
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

        private void PebblesnSpillagesCalc(double MilledUG1, double MilledUG2, double Spillages, double Pebbles, out double TotalMilledUG1,
                        out double TotalPebblesUG1, out double TotalSpillagesUG1, out double TotalMilledUG2,
                        out double TotalPebblesUG2, out double TotalSpillagesUG2, DateTime d)
        {
            TotalPebblesUG1 = 0;
            TotalSpillagesUG1 = 0;
            TotalMilledUG1 = double.NaN;

            TotalPebblesUG2 = 0;
            TotalSpillagesUG2 = 0;
            TotalMilledUG2 = double.NaN;

            try
            {

                if (!double.IsNaN(MilledUG1) | !double.IsNaN(MilledUG2))
                {

                    double rawMilledUG1 = MilledUG1;
                    double rawMilledUG2 = MilledUG2;

                    if (rawMilledUG1 > 0 && rawMilledUG2 > 0)
                    {
                        TotalPebblesUG1 = Pebbles / 2;
                        TotalPebblesUG2 = Pebbles / 2;

                        TotalSpillagesUG1 = Spillages / 2;
                        TotalSpillagesUG2 = Spillages / 2;

                        TotalMilledUG1 = rawMilledUG1 - TotalPebblesUG1 - TotalSpillagesUG1;
                        TotalMilledUG2 = rawMilledUG2 - TotalPebblesUG2 - TotalSpillagesUG2;
                    }
                    else if(rawMilledUG1 > 0 && rawMilledUG2 <= 0){

                        TotalPebblesUG1 = Pebbles;
                        TotalSpillagesUG1 = Spillages;
                        TotalMilledUG1 = rawMilledUG1 - Pebbles - Spillages;

                        TotalPebblesUG2 = 0;
                        TotalSpillagesUG2 = 0;
                        TotalMilledUG2 = 0;
                    } 
                    else if (rawMilledUG1 <= 0 && rawMilledUG2 > 0)
                    {
                        TotalPebblesUG2 = Pebbles;
                        TotalSpillagesUG2 = Spillages;
                        TotalMilledUG2 = rawMilledUG2 - Pebbles - Spillages;

                        TotalPebblesUG1 = 0;
                        TotalSpillagesUG1 = 0;
                        TotalMilledUG1 = 0;
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


