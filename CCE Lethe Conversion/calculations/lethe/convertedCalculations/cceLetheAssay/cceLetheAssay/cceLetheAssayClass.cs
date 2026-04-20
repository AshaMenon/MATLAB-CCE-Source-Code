using System;
using System.Collections.Generic;
using SharedLogger;
using NetCalculationState;
using System.Linq;

namespace cceLetheAssay
{
    // Define inputs struct
    public struct Inputs
    {
        public double[] DryMass;
        public double[] Component;
        public DateTime[] ComponentTimestamps;

    }

    // Define parameters struct
    public struct Parameters
    {
        public bool ComponentIsPercent;
        public int CalculationPeriodsToRun;
        public int CalculationPeriod;
        public string OutputTime;
        public int CalculateAtTime;
        public int CalculationPeriodOffset;

    }

    // Define outputs struct
    public struct Outputs
    {
        public double[] Assay;
        public DateTime[] Timestamp;
    }

    public class cceLetheAssayClass
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
                List<double> assayList = new List<double>();
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
                for (int iTime = 0; iTime < sInputs.ComponentTimestamps.Length; iTime++)
                {
                    if (iTime < sInputs.Component.Length & iTime < sInputs.DryMass.Length)
                    {
                        inputValues.Add(new Tuple<DateTime, Double, Double>(sInputs.ComponentTimestamps[iTime], sInputs.DryMass[iTime], sInputs.Component[iTime]));
                    } else
                    {
                        inputValues.Add(new Tuple<DateTime, Double, Double>(sInputs.ComponentTimestamps[iTime], sInputs.DryMass.Last(), sInputs.Component[iTime]));
                    }
                }

                List<Tuple<DateTime, double, double>> filteredInputValues = new List<Tuple<DateTime, double, double>>();
                filteredInputValues.AddRange(inputValues.Where(v => v.Item1 >= timeLims[0] & v.Item1 <= timeLims[1]));

                for (int iTime = 0; iTime < filteredInputValues.Count; iTime++)
                {
                    try
                    {
                        if (filteredInputValues[iTime].Item2 != 0)
                        {
                            if (sParams.ComponentIsPercent)
                            {
                                double assay = filteredInputValues[iTime].Item3 / filteredInputValues[iTime].Item2 * 100;
                                assayList.Add(assay);

                                var msg = string.Format("Assay at time: {0} is {1}", filteredInputValues[iTime].Item1.ToString(), assay);
                                LogInstance.logTrace(msg);
                            }
                            else
                            {
                                double assay = filteredInputValues[iTime].Item3 / filteredInputValues[iTime].Item2;
                                assayList.Add(assay);

                                var msg = string.Format("Assay at time: {0} is {1}", filteredInputValues[iTime].Item1.ToString(), assay);
                                LogInstance.logTrace(msg);
                            }
                        }
                        else
                        {
                            double nanVal = double.NaN;
                            assayList.Add(nanVal);

                            var msg = string.Format("Calculation Sum Error. No good results from '{0}' ", filteredInputValues.Last().Item1.ToString());
                            LogInstance.logError(msg);
                        }

                        dateList.Add(filteredInputValues[iTime].Item1);
                    }
                    catch (Exception e)
                    {
                        var msg = string.Format("Calculation Assay loop Error for calculation time '{0}'. Error message: {1} ", filteredInputValues[iTime].Item1.ToString(), e.Message);
                        throw new Exception(msg);
                    }

                }

                sOutputs.Assay = assayList.ToArray();
                //sOutputs.Timestamp = dateList.ToArray();
                sOutputs.Timestamp = filteredInputValues.Select(v => v.Item1).ToArray();

                if (sOutputs.Assay.Length == 0)
                {
                    sOutputs.Assay = new double[] { double.NaN };
                    sOutputs.Timestamp = new DateTime[] { dateRange.Last() };
                }
            }
            catch (Exception e)
            {
                // Return empty outputs
                double[] tempArray = { };
                sOutputs.Assay = tempArray;
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


