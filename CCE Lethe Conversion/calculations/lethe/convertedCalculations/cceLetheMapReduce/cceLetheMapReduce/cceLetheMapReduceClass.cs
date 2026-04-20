using System;
using System.Collections.Generic;
using SharedLogger;
using NetCalculationState;
using System.Linq;

namespace cceLetheMapReduce
{
    // Define inputs struct
    public struct Inputs
    {
        public double[] CountPeriod;
        public double[] MeanPeriod;
        public double[] StdDevPeriod;
        public double[] TimePeriod;

        public DateTime[] CountPeriodTimestamps;
        public DateTime[] MeanPeriodTimestamps;
        public DateTime[] StdDevPeriodTimestamps;
        public DateTime[] TimePeriodTimestamps;
    }

    // Define parameters struct
    public struct Parameters
    {
        public int AllowedBadValuesPerPeriod;
        public String DataRange;
        public bool TotaliserFilter;

        public int CalculationPeriodsToRun;
        public int CalculationPeriod;
        public int CalculateAtTime;
        public string OutputTime;
        public int CalculationPeriodOffset;
    }

    // Define outputs struct
    public struct Outputs
    {
        public double[] Mean;
        public double[] StdDev;
        public DateTime[] Timestamp;
    }

    public class cceLetheMapReduceClass
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
                List<double> MeanList = new List<double>();
                List<double> StdDevList = new List<double>();

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
                    DateTime DataStartTime = GetPeriodStart(dateRange[iTime], sParams.DataRange);

                    DateTime[] MapReduceTimeList = GetDateRange(DataStartTime, dateRange[iTime], sParams.CalculationPeriod);

                    double mMeanCounter = double.NaN;
                    double nCountCounter = double.NaN;
                    double cVarianceCounter = double.NaN;
                    double tTimeCounter = double.NaN;
                    Boolean FirstRun = true;

                    int BadValCount = 0;

                    //Check Debug for Order, Must be oldest to newest
                    foreach (DateTime t in MapReduceTimeList)
                    {
                        //Loop through each input time to calculate progressively for each period
                        //need data range here

                        GetInputsAtTime(out double Mean, out double Count, out double StdDev, out double Time, t, sInputs);
                        
                        double _mMeanCounter = double.NaN;
                        double _nCountCounter = double.NaN;
                        double _cVarianceCounter = double.NaN;
                        double _tTimeCounter = double.NaN;
                        //runVals = colVals.Where(t => t.Item1 >= DataStartTime.LocalTime && t.Item1 <= tim.LocalTime).ToList();
                        Boolean AllGood = !double.IsNaN(Mean) & !double.IsNaN(Count) & !double.IsNaN(StdDev) & !double.IsNaN(Time);
                        if (AllGood)
                        {
                            if (FirstRun)
                            {
                                _mMeanCounter = (Count * Mean) / Count;
                                _nCountCounter = Count;
                                _cVarianceCounter = (StdDev * StdDev);
                                _tTimeCounter = Time;

                                FirstRun = false;
                            }
                            else
                            {
                                _nCountCounter = nCountCounter + Count;
                                _tTimeCounter = tTimeCounter + Time;
                                if (Count > 0)
                                {
                                    _mMeanCounter = (nCountCounter * mMeanCounter + Count * Mean) / _nCountCounter;
                                    _cVarianceCounter = (nCountCounter * cVarianceCounter + Count * StdDev + nCountCounter * (mMeanCounter - _mMeanCounter) * (mMeanCounter - _mMeanCounter) + Count * (Mean - _mMeanCounter)) / _nCountCounter;
                                }
                                else
                                {
                                    _mMeanCounter = mMeanCounter;
                                    _cVarianceCounter = cVarianceCounter;
                                }

                            }

                            cVarianceCounter = _cVarianceCounter;
                            mMeanCounter = _mMeanCounter;
                            nCountCounter = _nCountCounter;
                            tTimeCounter = _tTimeCounter;

                        }
                        else
                        {
                            //got bad data
                            BadValCount += 1;

                            if (sParams.AllowedBadValuesPerPeriod > -1)
                            { //negative numbers no bad value period check
                                if (BadValCount > sParams.AllowedBadValuesPerPeriod)
                                {
                                    string Message = "Too many bad values for calculation; got " + BadValCount + " bad value periods";
                                    throw new InvalidOperationException(Message);
                                }

                            }

                        }
                    } // end each time in period loop

                    if (!double.IsNaN(mMeanCounter) || !double.IsNaN(cVarianceCounter))
                    {
                        MeanList.Add(mMeanCounter);
                        StdDevList.Add(Math.Sqrt(cVarianceCounter));

                        LogInstance.logTrace("Mean Value at: {0} is {1}", mMeanCounter, dateRange[iTime]);
                        LogInstance.logTrace("StdDev Value at: {0} is {1}", Math.Sqrt(cVarianceCounter), dateRange[iTime]);
                    }
                    else
                    {
                        MeanList.Add(double.NaN);
                        StdDevList.Add(double.NaN);
                        LogInstance.logError("Calculation Map Reduce Error. Day had a Bad result set from '{0}' ",  dateRange[iTime]);

                    }
                }

                sOutputs.Mean = MeanList.ToArray();
                sOutputs.StdDev = StdDevList.ToArray();
                sOutputs.Timestamp = dateRange;
            }
            catch (Exception e)
            {
                // Return empty outputs
                double[] tempArray = { };
                sOutputs.Mean = tempArray;
                sOutputs.StdDev = tempArray;
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

        private void GetInputsAtTime(out double mean, out double count, out double stdDev, out double time, DateTime t, Inputs sInputs)
        {
            int idx;
            //Get Mean Period input
            idx = Array.IndexOf(sInputs.MeanPeriodTimestamps.Select(x => x.Date).ToArray(), t.Date);

            if (idx >= 0)
            {
                mean = sInputs.MeanPeriod[idx];
            }
            else
            {
                mean = double.NaN;
            }

            //Get Count Period input
            idx = Array.IndexOf(sInputs.CountPeriodTimestamps.Select(x => x.Date).ToArray(), t.Date);

            if (idx >= 0)
            {
                count = sInputs.CountPeriod[idx];
            }
            else
            {
                count = double.NaN;
            }

            //Get StdDev Period input
            idx = Array.IndexOf(sInputs.StdDevPeriodTimestamps.Select(x => x.Date).ToArray(), t.Date);

            if (idx >= 0)
            {
                stdDev = sInputs.StdDevPeriod[idx];
            }
            else
            {
                stdDev = double.NaN;
            }

            //Get Time Period input
            idx = Array.IndexOf(sInputs.TimePeriodTimestamps.Select(x => x.Date).ToArray(), t.Date);

            if (idx >= 0)
            {
                time = sInputs.TimePeriod[idx];
            }
            else
            {
                time = double.NaN;
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
                        return new DateTime(dateArray.Year, dateArray.Month, dateArray.Day, 0, 0, 0, DateTimeKind.Local).AddDays((-1 * (daysBack - 1)) + dayCorrectionR) + dateArray.TimeOfDay;

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


