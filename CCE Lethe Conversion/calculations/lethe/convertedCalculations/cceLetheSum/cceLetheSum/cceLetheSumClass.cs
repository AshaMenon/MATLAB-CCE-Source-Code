using System;
using System.Collections.Generic;
using SharedLogger;
using NetCalculationState;
using System.Linq;

namespace cceLetheSum
{
    // Define inputs struct
    public struct Inputs
    {
        public double[] Input;
        public DateTime[] InputTimestamps;
    }

    // Define parameters struct
    public struct Parameters
    {
        public bool ForceToZero;
        public string DataRange;
        public int CalculationPeriodsToRun;
        public int CalculationPeriod;
        public int CalculateAtTime;
        public string OutputTime;
        public int CalculationPeriodOffset;
    }

    // Define outputs struct
    public struct Outputs
    {
        public double[] Aggregate;
        public DateTime[] Timestamp;
    }

    public class cceLetheSumClass
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

                List<Tuple<DateTime, double>> inputValues = new List<Tuple<DateTime, double>>();
                for (int iTime = 0; iTime < sInputs.InputTimestamps.Length; iTime++)
                {
                    inputValues.Add(new Tuple<DateTime, Double>(sInputs.InputTimestamps[iTime], sInputs.Input[iTime]));
                }

                //Prep outputs
                List<double> aggregateList = new List<double>();

                for (int iTime = 0; iTime < dateRange.Length; iTime++)

                {
                    // Filter time values to use
                    DateTime startDate = GetPeriodStart(dateRange[iTime], sParams.DataRange);

                    //Get array to use for current time
                    List<Tuple<DateTime, double>> sumValues = new List<Tuple<DateTime, Double>>();
                    sumValues.AddRange(inputValues.Where(v => v.Item1 <= dateRange[iTime] && v.Item1 >= startDate));

                    //Filter out NaN values
                    List<Tuple<DateTime, double>> validValues = sumValues.Where(d => !double.IsNaN(d.Item2)).ToList();

                    if (validValues != null)
                    {
                        if (validValues.Count > 0)
                        {
                            double tempArray = validValues.Sum(v => v.Item2);
                            aggregateList.Add(tempArray);
                            var msg = string.Format("Aggregate at time: {0} is {1}", dateRange[iTime].ToString(), tempArray);
                            LogInstance.logTrace(msg);
                        }
                        else
                        {
                            if (sParams.ForceToZero)
                            {
                                string msg = "No good input values, value forced to zero.";
                                LogInstance.logWarning(msg);
                                double zeroVal = 0;
                                aggregateList.Add(zeroVal);
                            }
                            else
                            {
                                //got a bad or missing input
                                double nanVal = double.NaN;
                                aggregateList.Add(nanVal);

                                var msg = string.Format("Calculation Sum Error. No good results from '{0}' ", dateRange[iTime].ToString());
                                LogInstance.logWarning(msg);
                            }

                        }
                    }
                    else
                    {
                        //got a bad or missing input
                        double nanVal = double.NaN;
                        aggregateList.Add(nanVal);

                        var msg = string.Format("Estimates had a null result set. No good results from '{0}' ", dateRange[iTime].ToString());
                        LogInstance.logError(msg);
                        ErrorCode = CalculationErrorState.BadInput;
                    }
                }


                // Dates
                sOutputs.Timestamp = dateRange;

                // Values
                double[] aggregateArray = aggregateList.ToArray();
                sOutputs.Aggregate = aggregateArray;

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

        public DateTime GetPeriodStart(DateTime dateArray, string dateRange)
        {

            //try a split on the sting to get specifics, like start day of the week
            string[] factors = dateRange.Split('.');

            string rangeString = factors.First();
            DayOfWeek startDay = DayOfWeek.Wednesday;

            //check for YTD or MTD
            switch (rangeString.ToUpper())
            {

                case "YTD":
                    //change start time to start of year
                    return new DateTime(dateArray.Year, 1, 1, 0, 0, 0, DateTimeKind.Local) + dateArray.TimeOfDay;

                case "MTD":
                    //change start time to start of month
                    return new DateTime(dateArray.Year, dateArray.Month, 1, 0, 0, 0, DateTimeKind.Local) + dateArray.TimeOfDay;
                case "WTD":
                    // change start to start of metal accounting week start on previous Wednesday

                    //check for parameter to specify start day
                    if (factors.Length > 1)
                    {
                        //try to convert to a day of the week
                        Enum.TryParse<DayOfWeek>(factors.Last(), out startDay);
                    }


                    // days to go back to get start of period
                    int dayCorrection = -1 * (((int)dateArray.DayOfWeek + (int)startDay + 1) % 7);
                    // 0 = Sunday, want Wednesday = 3;  =-1*(dayNo + 3 +1 Modulus 7)

                    return new DateTime(dateArray.Year, dateArray.Month, dateArray.Day, 0, 0, 0, DateTimeKind.Local).AddDays(dayCorrection) + dateArray.TimeOfDay;

                default:

                    //try parse to double to check if the period is a moving window of x days
                    double daysBack = 0;

                    if (Double.TryParse(rangeString, out daysBack))
                    {


                        int dayCorrectionR = 0;

                        //check for parameter to specify start day
                        if (factors.Length > 1)
                        {
                            //try to convert to a day of the week
                            Enum.TryParse<DayOfWeek>(factors.Last(), out startDay);

                            // days to go back to get start of period
                            dayCorrectionR = -1 * (((int)dateArray.DayOfWeek + (int)startDay + 1) % 7);
                            // 0 = Sunday, want Wednesday = 3;  =-1*(dayNo + 3 +1 Modulus 7) 

                        }

                        //must add 1 to days back otherwise an extra day is inclueded
                        return new DateTime(dateArray.Year, dateArray.Month, dateArray.Day, 0, 0, 0, DateTimeKind.Local).AddDays(-1 * daysBack + dayCorrectionR) + dateArray.TimeOfDay;

                    }
                    else
                    {
                        string message = String.Format("Calculation data period determination error. DataRange value '{0}' can not be converted to an integer or 'YTD' or 'MTD'  ", dateRange.ToString());
                        throw new Exception(message);
                    }

            }

        }


    }
}


