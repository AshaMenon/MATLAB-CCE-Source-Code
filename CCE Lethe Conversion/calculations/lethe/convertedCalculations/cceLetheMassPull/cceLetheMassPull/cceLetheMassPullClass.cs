using System;
using System.Collections.Generic;
using SharedLogger;
using NetCalculationState;
using System.Linq;

namespace cceLetheMassPull
{
    // Define inputs struct
    public struct Inputs
    {
        public double[] Product;
        public double[] Feed;
        public DateTime[] ProductTimestamps;
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
        public double[] MassPull;
        public DateTime[] Timestamp;
    }

    public class cceLetheMassPullClass
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

                List<Tuple<DateTime, double, double>> inputValues = new List<Tuple<DateTime, double, double>>();
                for (int iTime = 0; iTime < sInputs.ProductTimestamps.Length; iTime++)
                {
                    if (iTime < sInputs.Product.Length & iTime < sInputs.Feed.Length)
                    {
                        inputValues.Add(new Tuple<DateTime, Double, Double>(sInputs.ProductTimestamps[iTime], sInputs.Product[iTime], sInputs.Feed[iTime]));
                    } else
                    {
                        inputValues.Add(new Tuple<DateTime, Double, Double>(sInputs.ProductTimestamps[iTime], sInputs.Product[iTime], double.NaN));
                    }
                }

                List<Tuple<DateTime, double, double>> filteredInputValues = new List<Tuple<DateTime, double, double>>();
                filteredInputValues.AddRange(inputValues.Where(v => v.Item1 <= LastTime && v.Item1 >= startTime));

                //Add missing dates and assign a value of -1 for Product and Feed
                foreach(DateTime calcDate in dateRange)
                {
                    if (filteredInputValues.Find(v => v.Item1.Date == calcDate.Date) == null)
                    {
                        filteredInputValues.Add(new Tuple<DateTime, Double, Double>(calcDate, -1, -1));
                    }
                }

                filteredInputValues.Sort();

                //Prep outputs
                List<double> MassPullList = new List<double>();

                for (int iTime = 0; iTime < filteredInputValues.Count; iTime++)

                {
                    
                    if (filteredInputValues[iTime].Item2 != -1)
                    {
                        if (filteredInputValues[iTime].Item3 != 0)
                        {
                            double massPull = filteredInputValues[iTime].Item2/filteredInputValues[iTime].Item3 * 100;
                            MassPullList.Add(massPull);
                            var msg = string.Format("MassPull value at time: {0} is {1}", filteredInputValues[iTime].Item1.ToString(), massPull);
                            LogInstance.logTrace(msg);
                        }
                        else
                        {
                             //got a bad or missing input
                             double nanVal = double.NaN;
                             MassPullList.Add(nanVal);

                             var msg = string.Format("Calculation Error. No good results from '{0}' ", filteredInputValues[iTime].Item1.ToString());
                             LogInstance.logWarning(msg);

                        }
                    }
                    else
                    {
                        //got a bad or missing input
                        double nanVal = double.NaN;
                        MassPullList.Add(nanVal);

                        var msg = string.Format("Estimates had a null result set. No good results from '{0}' ", filteredInputValues[iTime].Item1.ToString());
                        LogInstance.logError(msg);
                        ErrorCode = CalculationErrorState.BadInput;
                    }
                }


                // Dates
                sOutputs.Timestamp = dateRange;

                // Values
                sOutputs.MassPull = MassPullList.ToArray(); ;

                if (sOutputs.MassPull.Length == 0)
                {
                    sOutputs.MassPull = new double[] { double.NaN };
                    sOutputs.Timestamp = new DateTime[] { dateRange.Last() };
                }
            }
            catch (Exception e)
            {
                // Return empty outputs
                double[] tempArray = { };
                sOutputs.MassPull = tempArray;
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


