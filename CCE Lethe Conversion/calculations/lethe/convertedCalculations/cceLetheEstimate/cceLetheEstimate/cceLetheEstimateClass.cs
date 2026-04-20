using System;
using System.Collections.Generic;
using SharedLogger;
using NetCalculationState;
using System.Linq;

namespace cceLetheEstimate
{
    // Define inputs struct
    public struct Inputs
    {
        public double[] Assay;
        public double[] Weighting;
        public DateTime[] AssayTimestamps;
        public DateTime[] WeightingTimestamps;
    }

    // Define parameters struct
    public struct Parameters
    {
        public int LastGoodDataPoints;
        public int CalculateAtTime;
        public int CalculationPeriod;
        public string OutputTime;
        public int CalculationPeriodOffset;
    }

    // Define outputs struct
    public struct Outputs
    {
        public Double[] Estimate;
        public DateTime[] Timestamp;
    }

    public class cceLetheEstimateClass
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
            Logger LogInstance = new Logger(LogName, CalculationID, CalculationName, (LogMessageLevel)LogLevel);

            try
            {
                double weightAve = 0;

                DateTime OutputTime = DateTime.Parse(sParams.OutputTime);
                OutputTime = OutputTime.ToLocalTime();

                TimeSpan calcAtTime = new TimeSpan(0, 0, sParams.CalculateAtTime);
                TimeSpan calcPeriod = new TimeSpan(0, 0, sParams.CalculationPeriod);

                // Get the last calculation time from the current time
                long ModTime = (OutputTime.Ticks - calcAtTime.Ticks) % calcPeriod.Ticks;
                DateTime LastTime = new DateTime(OutputTime.Ticks - ModTime, DateTimeKind.Local) + new TimeSpan(sParams.CalculationPeriodOffset * calcPeriod.Ticks);

                var lastTimeTraceMsg = string.Format("Current LastTime being used: {0} ", LastTime.ToString());
                LogInstance.logTrace(lastTimeTraceMsg);

                List<Tuple<DateTime, double>> AssayValues = new List<Tuple<DateTime, double>>();
                for (int iTime = 0; iTime < sInputs.AssayTimestamps.Length; iTime++)
                {
                    AssayValues.Add(new Tuple<DateTime, Double>(sInputs.AssayTimestamps[iTime], sInputs.Assay[iTime]));
                }

                List<Tuple<DateTime, double>> WeightingValues = new List<Tuple<DateTime, double>>();
                for (int iTime = 0; iTime < sInputs.WeightingTimestamps.Length; iTime++)
                {
                    WeightingValues.Add(new Tuple<DateTime, Double>(sInputs.WeightingTimestamps[iTime], sInputs.Weighting[iTime]));
                }

                AssayValues.RemoveAll(v => v.Item1.Date > LastTime.Date);
                AssayValues.RemoveAll(v => double.IsNaN(v.Item2));
                WeightingValues.RemoveAll(v => v.Item1.Date > LastTime.Date);
                DateTime[] WeightingTimes = WeightingValues.Select(v => v.Item1).ToArray();

                List<Tuple<DateTime, double, double>> inputValues = new List<Tuple<DateTime, double, double>>();
                for (int valIdx = 0; valIdx < AssayValues.Count; valIdx++)
                {
                    DateTime AssayTime = AssayValues[valIdx].Item1;
                    int weightingIdx = Array.IndexOf(WeightingTimes, AssayTime);

                    if (weightingIdx >= 0)
                    {
                        inputValues.Add(new Tuple<DateTime, Double, Double>(AssayTime, AssayValues[valIdx].Item2, WeightingValues[weightingIdx].Item2));
                    } else
                    {
                        inputValues.Add(new Tuple<DateTime, Double, Double>(AssayTime, AssayValues[valIdx].Item2, 1));
                    }
                }

                if (inputValues != null)
                {

                    // order estimates and trim unneeded
                    inputValues.Reverse();
                    if (inputValues.Count() > sParams.LastGoodDataPoints)
                    {
                        inputValues.RemoveRange(sParams.LastGoodDataPoints, inputValues.Count() - sParams.LastGoodDataPoints);

                    }

                    if (inputValues.Count > 0)
                    {
                        if (inputValues.Count < sParams.LastGoodDataPoints)
                        {
                            var msg = string.Format("Calculation Estimate Error required number of values for estimate is not met. only {0} of {1} values returned ", inputValues.Count, sParams.LastGoodDataPoints);
                            LogInstance.logError(msg);

                        }
                        else
                        {
                            //sum weighting
                            double TotWeighting = inputValues.Select(t => t.Item3).Sum();


                            // do weighting
                            List<Double> weightList = new List<double>(inputValues.Select(t => t.Item2 * t.Item3));

                            weightAve = weightList.Sum() / TotWeighting;

                        }
                    }
                    else
                    {
                        var msg = string.Format("Calculation Estimate Error no good results from '{0}' ", sParams.OutputTime);
                        LogInstance.logError(msg);
                    }
                }
                else
                {
                    var msg = string.Format("Calculation Estimate Error no good results from '{0}' ", sParams.OutputTime);
                    LogInstance.logError(msg);

                }

                double[] estVal = { weightAve };
                DateTime[] timeVal = { LastTime };

                sOutputs.Estimate = estVal;
                sOutputs.Timestamp = timeVal;

                if (sOutputs.Estimate.Length == 0)
                {
                    sOutputs.Estimate = new double[] { double.NaN };
                    sOutputs.Timestamp = new DateTime[] { LastTime };
                }

            }
            catch (Exception e)
            {
                // Return empty outputs
                double[] tempArray = { };
                sOutputs.Estimate = tempArray;
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

        public DateTime LastCalculationPeriod(DateTime CalculationTime, TimeSpan Period, TimeSpan CalulateAtTime)
        {

            //double ModTime = (CalTime.UtcSeconds - CalulateAtTime.TotalSeconds) % Period.TotalSeconds;
            long ModTime = (CalculationTime.Ticks - CalulateAtTime.Ticks) % Period.Ticks;
            //AFTime LastTime = new AFTime(CalTime.UtcSeconds - ModTime);
            DateTime LastTime = new DateTime(CalculationTime.Ticks - ModTime, DateTimeKind.Local);

            return LastTime;
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
    }
}


