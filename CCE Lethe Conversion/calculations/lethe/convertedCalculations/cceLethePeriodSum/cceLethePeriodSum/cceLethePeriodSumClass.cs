using System;
using System.Collections.Generic;
using SharedLogger;
using NetCalculationState;
using System.Linq;
using System.Reflection;

namespace cceLethePeriodSum
{
    // Define inputs struct
    public struct Inputs
    {
        public double[] Input;
        public double[,] AdditionalInputs;
        public DateTime[] InputTimestamps;
        public DateTime[,] AdditionalTimestamps;
    }

    // Define parameters struct
    public struct Parameters
    {
        public int CalculationPeriodsToRun;
        public int CalculationPeriod;
        public int CalculateAtTime;
        public string OutputTime;
        public bool ForceTimeCollation;
        public bool ForceToZero;
        public int CalculationPeriodOffset;
    }

    // Define outputs struct
    public struct Outputs
    {
        public double[] Aggregate;
        public DateTime[] Timestamp;
    }

    public class cceLethePeriodSumClass
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
                List<double> AggregateList = new List<double>();

                foreach (DateTime calcTime in dateRange)
                {
                    double[] GoodInputsInPeriod = GetGoodItemsInPeriod2(calcTime, sParams.ForceTimeCollation, sInputs, sParams);

                    if (!GoodInputsInPeriod.AsQueryable().All(val => double.IsNaN(val)))
                    {
                        double aggregateValue = GoodInputsInPeriod.AsQueryable().Where(a => !double.IsNaN(a)).Sum(); //omit NaN's in sum
                        AggregateList.Add(aggregateValue);

                        var msg = string.Format("Aggregate value at time: {0} is {1}", calcTime.ToString(), aggregateValue);
                        LogInstance.logTrace(msg);
                    }
                    else
                    {

                        if (sParams.ForceToZero)
                        {
                            AggregateList.Add(0);

                            string msg = string.Format("No good input values at time '{0}', value forced to zero.", calcTime.ToString());
                            LogInstance.logWarning(msg);
                        }
                        else
                        {
                            // Bad or missing input
                            AggregateList.Add(double.NaN);
                            var msg = string.Format("Calculation Error. No good results from '{0}' ", calcTime.ToString());
                            LogInstance.logWarning(msg);
                        }
                    }
                }

                sOutputs.Aggregate = AggregateList.ToArray();
                sOutputs.Timestamp = dateRange;

                if (sOutputs.Aggregate.Length == 0)
                {
                    sOutputs.Aggregate = new double[] { double.NaN };
                    sOutputs.Timestamp = new DateTime[] { dateRange.Last() };
                }

            }
            catch (Exception e)
            {
                // Return empty outputs
                double[] tempArray = { };
                sOutputs.Aggregate = tempArray;
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

        public static double[] GetValuesInRange(DateTime[] dates, Double[] values, DateTime startTime, DateTime endTime)
        {
            List<Double> outputList = new List<double>();

            for (int i = 0; i < dates.Length; i++)
            {
                if (dates[i] >= startTime & dates[i] <= endTime)
                {
                    outputList.Add(values[i]);
                }
            }

            return outputList.ToArray();
        }

        public static double[] GetGoodItemsInPeriod2(DateTime calcTime, bool ForceTimeCollation, Inputs sInputs, Parameters sParams)
        {
            double[] output = { };
            bool timesMatch = true;
            DateTime EndTime = calcTime.AddSeconds(sParams.CalculationPeriod);
            int numAdditionalInputs;

            if (sInputs.AdditionalInputs != null)
            {
                numAdditionalInputs = sInputs.AdditionalInputs.GetLength(1);
            }
            else
            {
                numAdditionalInputs = 0;
            }

            if (numAdditionalInputs == 0)
            {
                output = GetValuesInRange(sInputs.InputTimestamps, sInputs.Input, calcTime, EndTime);
            }
            else
            {
                List<double> inputsList = new List<double>();
                double[] inputsInRange;
                inputsInRange = GetValuesInRange(sInputs.InputTimestamps, sInputs.Input, calcTime, EndTime);
                inputsList.AddRange(inputsInRange);

                int numInputs = inputsInRange.Length;

                for (int i = 0; i < numAdditionalInputs; i++)
                {
                    double[] values = Enumerable.Range(0, sInputs.AdditionalInputs.GetLength(0)).Select(x => sInputs.AdditionalInputs[x, i]).ToArray();
                    DateTime[] timestamps = Enumerable.Range(0, sInputs.AdditionalTimestamps.GetLength(0)).Select(x => sInputs.AdditionalTimestamps[x, i]).ToArray();

                    inputsInRange = GetValuesInRange(timestamps, values, calcTime, EndTime);
                    inputsList.AddRange(inputsInRange);

                    if (inputsInRange.Length != numInputs)
                    {
                        timesMatch = false;
                    }
                }

                output = inputsList.ToArray();

                if (ForceTimeCollation)
                {
                    if (!timesMatch)
                    {
                        output = new double[] { double.NaN };
                    }
                }

            }
            return output;
        }
        public static double[] GetGoodItemsInPeriod(DateTime calcTime, bool ForceTimeCollation, Inputs sInputs)
        {
            int InputIdx = Array.IndexOf(sInputs.InputTimestamps, calcTime);

            int numAdditionalInputs;

            if (sInputs.AdditionalInputs.Length != 0)
            {
                numAdditionalInputs = sInputs.AdditionalInputs.GetLength(1);
            } else
            {
                numAdditionalInputs = 0;
            }

            int[] idxArray = new int[1 + numAdditionalInputs];
            double[] outputArray = new double[1 + numAdditionalInputs];

            idxArray[0] = InputIdx;

            if (numAdditionalInputs > 0)
            {
                DateTime[] timestamps;
                for (int colIdx = 1; colIdx <= numAdditionalInputs; colIdx++)
                {
                    timestamps = Enumerable.Range(0, sInputs.AdditionalTimestamps.GetLength(0))
                    .Select(x => sInputs.AdditionalTimestamps[x, colIdx-1])
                    .ToArray();

                    int idx = Array.IndexOf(timestamps, calcTime);
                    idxArray[colIdx] = idx;
                }
            }

            if (idxArray.Contains(-1))
            {
                if (ForceTimeCollation)
                {
                    for (int idx = 0; idx < outputArray.Length; idx++)
                    {
                        outputArray[idx] = double.NaN;
                    }

                }
                else
                {
                    try { outputArray[0] = sInputs.Input[InputIdx]; } catch { outputArray[0] = double.NaN; }
                    if (numAdditionalInputs > 0)
                    {
                        double[] values;

                        for (int colIdx = 1; colIdx <= numAdditionalInputs; colIdx++)
                        {
                            values = Enumerable.Range(0, sInputs.AdditionalInputs.GetLength(0))
                            .Select(x => sInputs.AdditionalInputs[x, colIdx - 1])
                            .ToArray();

                            try { outputArray[colIdx] = values[idxArray[colIdx]]; } catch { outputArray[colIdx] = double.NaN; }
                        }
                    }
                }

            }else
            {
                outputArray[0] = sInputs.Input[InputIdx];

                if (numAdditionalInputs > 0)
                {
                    double[] values;

                    for (int colIdx = 1; colIdx <= numAdditionalInputs; colIdx++)
                    {
                        values = Enumerable.Range(0, sInputs.AdditionalInputs.GetLength(0))
                        .Select(x => sInputs.AdditionalInputs[x, colIdx - 1])
                        .ToArray();

                        outputArray[colIdx] = values[idxArray[colIdx]];
                    }
                }

            }

            return outputArray;
        }
    }
}


