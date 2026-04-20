using System;
using System.Collections.Generic;
using SharedLogger;
using NetCalculationState;
using System.Linq;

namespace cceLetheTails
{
    // Define inputs struct
    public struct Inputs
    {
        public double[] DryConcentrate;
        public double[] DryFeed;
        public DateTime[] DryConcentrateTimestamps;
        public DateTime[] DryFeedTimestamps;
    }

    // Define parameters struct
    public struct Parameters
    {
        public int CalcLoopLimit;
        public int CalcBackdays;
        public bool OutputNegTailsAcc;
        public int CalculationPeriodsToRun;
        public int CalculationPeriod;
        public int CalculateAtTime;
        public string OutputTime;
        public int CalculationPeriodOffset;
    }

    // Define outputs struct
    public struct Outputs
    {
        public double[] Tails;
        public double[] negTailsAccumulator;
        public DateTime[] Timestamp;
    }

    public class cceLetheTailsClass
    {
        // Log Info
        public string LogName;
        public string CalculationID;
        public int LogLevel;
        public string CalculationName;
        public CalculationErrorState ErrorCode = (CalculationErrorState)305;
        public Logger LogInstance { get; set; }

        public Outputs RunCalc(Parameters sParams, Inputs sInputs)
        {
            // Create Instance of output struct
            Outputs sOutputs;

            // Create logger
            Logger LogInstance = new Logger(LogName, CalculationID, CalculationName, (LogMessageLevel)LogLevel, "CCE_Calc_Logs");

            try
            {


                // Calculation logic goes here

                // Get timestamps start and end - end is the last available data point
                // Start is the end time minus the Periods to run.
                // 

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

                //Prep inputs for loop
                bool endWhenTailsAccIsZero = false;
                double LastNegTailsAcc = 0;

                List<Tuple<DateTime, double, double>> inputValues = new List<Tuple<DateTime, double, double>>();
                
                for (int iTime = 0; iTime < dateRange.Length; iTime++)
                {
                    inputValues.Add(new Tuple<DateTime, Double, Double>(dateRange[iTime], getVal(sInputs.DryConcentrate, sInputs.DryConcentrateTimestamps, dateRange[iTime], double.NaN),
                        getVal(sInputs.DryFeed, sInputs.DryFeedTimestamps, dateRange[iTime], double.NaN)));
                }

                List<Tuple<DateTime, double, double>> filteredInputValues = new List<Tuple<DateTime, double, double>>();


                //Prep outputs for loop
                List<Tuple<DateTime, double, double>> outputValues = new List<Tuple<DateTime, double, double>>();

                //Start loop - if calc ends on a negative tails go back further
                for (int getItteration = 1; getItteration <= sParams.CalcLoopLimit; getItteration++)
                {
                    //Restrict input values
                    filteredInputValues.AddRange(inputValues.Where(v => v.Item1 >= timeLims[0] & v.Item1 <= timeLims[1]));


                    //calculate tails for range
                    if (filteredInputValues.Count() >= 1)
                    {
                        CalcTailsForTimeRange(filteredInputValues, ref LastNegTailsAcc, endWhenTailsAccIsZero, sParams.OutputNegTailsAcc, ref outputValues);
                    }
                    else
                    {
                        var msg = string.Format(" Error on calc. Tails calculation ended on negative tails at '{0}", timeLims[1].ToString());
                        LogInstance.logError(msg);
                        break;
                    }

                    //end the tails calculation as soon as the tails accumulator is zero - no adjustments for that day
                    endWhenTailsAccIsZero = true;

                    if (LastNegTailsAcc < 0)
                    {
                        // tails ends on negative, reset range and loop through
                        //last day or last iteration

                        TimeSpan newTimeSpan = new TimeSpan(calcPeriod.Ticks * (sParams.CalcBackdays - Math.Sign(sParams.CalcBackdays)));
                        DateTime endTime = filteredInputValues[0].Item1 - calcPeriod;
                        DateTime newStartTime = endTime + newTimeSpan;
                        timeLims[0] = newStartTime;
                        timeLims[1] = endTime;
                        filteredInputValues.Clear();
                    }
                    else
                    {
                        //last is no tails adjustment - end
                        break;
                    }

                    if (getItteration < sParams.CalcLoopLimit)
                    {
                        var msg = string.Format("Tails Calculation running loop {0}", getItteration.ToString());
                        //LogInstance.logTrace(msg);
                    }
                    else
                    {
                        var msg = string.Format(" Error on calc. Tails calculation ended on negative tails at '{0}", timeLims[1].ToString());
                        LogInstance.logError(msg);
                    }

                }


                //Write outputs
                // Tails
                sOutputs.Tails = outputValues.Select(v => v.Item2).ToArray();

                // NegValueThingy
                sOutputs.negTailsAccumulator = outputValues.Select(v => v.Item3).ToArray();

                // Timestamps
                sOutputs.Timestamp = outputValues.Select(v => v.Item1).ToArray();

                if (sOutputs.Tails.Length == 0 | sOutputs.negTailsAccumulator.Length == 0)
                {
                    sOutputs.Tails = new double[] { double.NaN };
                    sOutputs.negTailsAccumulator = new double[] { double.NaN };
                    sOutputs.Timestamp = new DateTime[] { dateRange.Last() };
                }

            }
            catch (Exception e)
            {
                // Return empty outputs
                double[] tempArray = { };
                DateTime[] tempDateArray = { };

                sOutputs.Tails = tempArray;
                sOutputs.negTailsAccumulator = tempArray;
                sOutputs.Timestamp = tempDateArray;

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

        private void CalcTailsForTimeRange(List<Tuple<DateTime, double, double>> filteredInputValues, ref double LastNegTailsAcc,
            bool endWhenTailsAccisZero, bool outputNegTailsAcc, ref List<Tuple<DateTime, double, double>> outputValues)

        {
            try
            {
                //must go backwards from start time
                for (int iTime = filteredInputValues.Count() - 1; iTime >= 0; iTime--)

                {
                    // Get double values
                    double newNegTailAcc = 0;
                    double dryFeed = filteredInputValues[iTime].Item3;
                    double dryConcentrate = filteredInputValues[iTime].Item2;
                    DateTime timeStamp = filteredInputValues[iTime].Item1;
                    double tails = TailsCalc(dryFeed, dryConcentrate, LastNegTailsAcc, ref newNegTailAcc, timeStamp);

                    //Update negative tails
                    LastNegTailsAcc = newNegTailAcc;

                    //Check whether negTails should be written out or not - set to NaN accordingly
                    double negTailsOut;
                    if (outputNegTailsAcc)
                    {
                        negTailsOut = LastNegTailsAcc;
                    }
                    else
                    {
                        //Set to NaN
                        negTailsOut = double.NaN;
                    }

                    //Remove existing timestamps as to not have duplicates
                    outputValues.RemoveAll(t => t.Item1 == filteredInputValues[iTime].Item1);

                    // Update output array
                    Tuple<DateTime, double, double> tempOutTuple = new Tuple<DateTime, double, double>(filteredInputValues[iTime].Item1, tails, negTailsOut);
                    outputValues.Add(tempOutTuple);

                    if (endWhenTailsAccisZero)
                    {
                        if (LastNegTailsAcc == 0) { break; }
                    }

                }
            }

            catch (Exception e)
            {
                var msg = string.Format("Calculation Tails Error on upper time range loop. Message: {0} line {1} ", e.Message, e.StackTrace);
                throw new Exception(msg);
            }
        }

        private double TailsCalc(double dryFeed, double dryConcentrate, double LastNegTailsAcc, ref double newNegTailAcc, DateTime timeStamp)
        {
            //double tails = new double.NaN;
            double tail;
            double nT;
            try
            {

                bool tempBool = double.IsNaN(dryFeed) | double.IsNaN(dryConcentrate);
                if (!tempBool)
                {
                    //check conversion first
                    double rawTail = dryFeed - dryConcentrate;

                    //adjust tails with negative value
                    if (rawTail + LastNegTailsAcc < 0)
                    {
                        tail = 0;
                    }
                    else
                    {
                        tail = rawTail + LastNegTailsAcc;
                    }

                    //new accumulate negative tails
                    if (rawTail + LastNegTailsAcc < 0)
                    {
                        nT = LastNegTailsAcc + rawTail;
                    }
                    else
                    {
                        nT = 0;
                    }

                }
                else
                {
                    //bad value or missing value from DryConcentrate mass use its error state if it has one
                    tail = double.NaN;
                    //var msg = string.Format("Error on calc. DryConcentrate or DryFeed returned null for {0}", timeStamp.ToString());
                    //LogInstance.logDebug(msg);
                    nT = LastNegTailsAcc;
                }
            }
            catch (Exception e)
            {
                var msg = string.Format("Calculation Tails Error on value calculation: '{0}'. Stack: {1} ", e.Message, e.StackTrace);
                throw new Exception(msg);
            }

            newNegTailAcc = nT;

            return tail;
        }
    }
}


