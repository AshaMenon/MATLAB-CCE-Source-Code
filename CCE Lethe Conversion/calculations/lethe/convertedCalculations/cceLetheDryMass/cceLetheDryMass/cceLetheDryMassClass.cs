using System;
using System.Collections.Generic;
using SharedLogger;
using NetCalculationState;
using System.Linq;

namespace cceLetheDryMass
{
    // Define inputs struct
    public struct Inputs
    {
        public double[] Estimate;
        public double[] Moisture;
        public double[] WetMass;

        public DateTime[] EstimateTimestamps;
        public DateTime[] MoistureTimestamps;
        public DateTime[] WetMassTimestamps;
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
        public double[] DryMass;
        public double[] Water;
        public DateTime[] Timestamp;
    }

    public class cceLetheDryMassClass
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
                //Initialize outputs
                List<double> DryMassList = new List<double>();
                List<double> WaterList = new List<double>();

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
                for (int iTime = 0; iTime < dateRange.Length; iTime++)
                {
                    double Water = double.NaN;
                    double DryMass = double.NaN;

                    GetInputsAtTime(out double Wet, out double Moisture, out double Estimate, dateRange[iTime], sInputs);

                    CalculateDryMass(ref DryMass, ref Water, Wet, Moisture, Estimate);

                    DryMassList.Add(DryMass);
                    WaterList.Add(Water);

                    var msg = string.Format("DryMass at time: {0} is: {1}", dateRange[iTime], DryMass);
                    LogInstance.logTrace(msg);

                }

                sOutputs.DryMass = DryMassList.ToArray();
                sOutputs.Water = WaterList.ToArray();
                sOutputs.Timestamp = dateRange;
            }
            catch (Exception e)
            {
                // Return empty outputs
                double[] tempArray = { };
                sOutputs.DryMass = tempArray;
                sOutputs.Water = tempArray;
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

        private void GetInputsAtTime(out double wet, out double moisture, out double estimate, DateTime dateTime, Inputs sInputs)
        {
            int idx;

            //Get WetMass input
            idx = Array.IndexOf(sInputs.WetMassTimestamps.Select(x => x.Date).ToArray(), dateTime.Date);

            if (idx >= 0)
            {
                wet = sInputs.WetMass[idx];
            }
            else
            {
                wet = double.NaN;
            }

            //Get Moisture input
            idx = Array.IndexOf(sInputs.MoistureTimestamps, dateTime);

            if (idx >= 0)
            {
                moisture = sInputs.Moisture[idx];
            }
            else
            {
                moisture = double.NaN;
            }

            //Get Estimate input
            idx = Array.IndexOf(sInputs.EstimateTimestamps, dateTime);

            if (idx >= 0)
            {
                estimate = sInputs.Estimate[idx];
            }
            else
            {
                estimate = double.NaN;
            }
            
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

        public void CalculateDryMass(ref double DryMass, ref double Water, double WetMass, double Moisture, double? Estimate)
        {

            double WM = WetMass;

            if (!double.IsNaN(WM))
            {
                if (WM != 0)
                {
                    //moisture

                    double Mo = Moisture;

                    if (double.IsNaN(Mo))
                    {
                        // no moisture check estimate
                        if (Estimate.HasValue)
                        {
                            //got estimate therefore item is an estimate
                            Mo = Estimate.Value;
                        }
                    }

                    if (!double.IsNaN(Mo))
                    {
                        DryMass = WM * (1 - Mo / 100);
                        if (Water != null)
                        {
                            Water = WM - DryMass;
                        }
                    }
                    else
                    {
                        DryMass = double.NaN;
                        if (Water != null) { Water = double.NaN; }
                        LogInstance.logError(" Error on calc moisture is missing or bad");
                    }
                }
                else
                {
                    DryMass = 0;
                    if (Water != null) { Water = 0; }
                }
            }
            else
            {
                DryMass = double.NaN;
                if (Water != null) { Water = double.NaN; }
                LogInstance.logError(" Error on calc Wet Mass is missing or bad");
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


