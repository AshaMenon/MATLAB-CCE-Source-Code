using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System.Diagnostics;
using OSIsoft.AF;
using OSIsoft.AF.Asset;
using OSIsoft.AF.Data;
using OSIsoft.AF.Time;
using Quartz;
using NLog;


namespace Amplats.AF.Lethe.Calculation.LetheCalculationMethods
{
    public class APLetheTime
    {

        public APLetheAF _APLeathAF = new APLetheAF();




        /// <summary>
        /// returns the last calculation time from the current time
        /// </summary>
        /// <param name="CalculationTime"></param>
        /// <param name="Period"></param>
        /// <param name="CalulateAtTime"></param>
        /// <returns></returns>
        public AFTime LastCalculationPeriod(DateTime CalculationTime, TimeSpan Period, TimeSpan CalulateAtTime)
        {
            AFTime CalTime = new AFTime(CalculationTime);
            //double ModTime = (CalTime.UtcSeconds - CalulateAtTime.TotalSeconds) % Period.TotalSeconds;
            long ModTime = (CalTime.LocalTime.Ticks - CalulateAtTime.Ticks) % Period.Ticks;
            //AFTime LastTime = new AFTime(CalTime.UtcSeconds - ModTime);
            DateTime LatDT = new DateTime(CalTime.LocalTime.Ticks - ModTime, DateTimeKind.Local);
            AFTime LastTime = new AFTime(LatDT);

            return LastTime;
        }


        /// <summary>
        /// returns an AFTimeRange for the calculation run times and the calculation period
        /// min time is at the start time
        /// </summary>
        /// <param name="CalcRunTimes"> AFCaclulation result time range, the time of the smallest time is used to determine the data times</param>
        /// <param name="DataRange"></param>
        /// <returns></returns>
        public AFTimeRange GetDataRangefromCalculationRange(AFTimeRange CalcRunTimes, string DataRange, TimeSpan CalculationPeriod, TimeSpan CalculateAtTime)
        {
            AFTimeRange outRange = new AFTimeRange();

            List<AFTime> Times = new List<AFTime> { CalcRunTimes.StartTime, CalcRunTimes.EndTime };

            outRange.StartTime = Times.Min();
            outRange.EndTime = Times.Max();


            outRange.StartTime = GetPeriodStart(outRange.StartTime, DataRange, CalculationPeriod, CalculateAtTime);

            return outRange;
        }

        /// <summary>
        /// returns the period start date and time relative to the input AFtime, the input timeofday and the aggregation date range. MTD, YTD, WTD (as metal accounting week starting Wednesday) or a moving period of x days back.
        /// </summary>
        /// <param name="Time"></param>
        /// <param name="DataRange"></param>
        /// <returns></returns>
        public AFTime GetPeriodStart(AFTime Time, string DataRange, TimeSpan CalculationPeriod, TimeSpan CalculateAtTime)
        {
            // add logic if time is before end of production day
            AFTime LastPeriod = LastCalculationPeriod(Time.LocalTime, CalculationPeriod, CalculateAtTime);

            //try a split on the sting to get specifics, like start day of the week
            string[] factors = DataRange.Split('.');

            string RangeString = factors.First();
            DayOfWeek StartDay = DayOfWeek.Wednesday;

            //check for YTD or MTD
            switch (RangeString.ToUpper())
            {

                case "YTD":
                    //change start time to start of year
                    return new AFTime(new DateTime(LastPeriod.LocalTime.Year, 1, 1, 0, 0, 0, DateTimeKind.Local) + CalculateAtTime);

                case "MTD":
                    //change start time to start of month
                    return new AFTime(new DateTime(LastPeriod.LocalTime.Year, LastPeriod.LocalTime.Month, 1, 0, 0, 0, DateTimeKind.Local) + CalculateAtTime);
                case "WTD":
                    // change start to start of metal accounting week start on previous Wednesday

                    

                    //check for parameter to specify start day
                    if (factors.Length > 1)
                    {
                        //try to convert to a day of the week
                        Enum.TryParse<DayOfWeek>(factors.Last(), out StartDay);
                    }

                    // days to go back to get start of period
                    int DayCorrection = -1 * (((int)LastPeriod.LocalTime.DayOfWeek + (int)StartDay + 1) % 7);
                    // 0 = Sunday, want Wednesday = 3;  =-1*(dayNo + 3 +1 Modulus 7)

                    return new AFTime(new DateTime(LastPeriod.LocalTime.Year, LastPeriod.LocalTime.Month, LastPeriod.LocalTime.Day, 0, 0, 0, DateTimeKind.Local).AddDays(DayCorrection) + CalculateAtTime);

                default:

                    //try parse to double to check if the period is a moving window of x days
                    double daysBack = 0;

                    if (Double.TryParse(RangeString, out daysBack))
                    {


                        int DayCorrectionR = 0;

                        //check for parameter to specify start day
                        if (factors.Length > 1)
                        {
                            //try to convert to a day of the week
                            Enum.TryParse<DayOfWeek>(factors.Last(), out StartDay);

                            // days to go back to get start of period
                            DayCorrectionR = -1 * (((int)LastPeriod.LocalTime.DayOfWeek - (int)StartDay + 7 ) % 7);
                            // 0 = Sunday, want Wednesday = 3;  =-1*(dayNo + 3 +1 Modulus 7) 

                        }




                        //must add 1 to days back otherwise an extra day is inclueded
                        return new AFTime(new DateTime(LastPeriod.LocalTime.Year, LastPeriod.LocalTime.Month, LastPeriod.LocalTime.Day, 0, 0, 0, DateTimeKind.Local).AddDays(-1 * daysBack + DayCorrectionR) + CalculateAtTime);



                    }
                    else
                    {

                        string message = String.Format("Calculation data period determination error. CalulationPeriodsToRun value '{0}' can not be converted to an integer or 'YTD' or 'MTD'  ", DataRange.ToString());
                        throw new Exception(message);
                    }

            }


        }

        /// <summary>
        /// returns an AFTime Range with one period added to the largest day to ensure all data is collected for some calculations - adding shift totals
        /// </summary>
        /// <param name="CalcRange"></param>
        /// <param name="CalculationPeriod"></param>
        /// <returns></returns>
        public AFTimeRange RangeAddPeriodToEndofBiggest(AFTimeRange CalcRange, TimeSpan CalculationPeriod)
        {
            AFTimeRange newRange = CalcRange;

            if (newRange.StartTime > newRange.EndTime)
            {
                newRange.StartTime = newRange.StartTime + CalculationPeriod;
            }
            else
            {
                newRange.EndTime = newRange.EndTime + CalculationPeriod;

            }

            return newRange;
        }


        /// <summary>
        /// return the calculation time range using the Calculation period, Calculations Period to Run
        /// , Calculation Period offset and the execution time.
        /// </summary>
        /// <param name="RunAt"></param>
        /// <returns>
        /// if Calc periods to run < 0 then run backward (StartTime = max, End time = min)
        ///  if Calc periods to run > 0 then run forwards (StartTime = min, End time = max)           
        ///  if Calc periods to run = 0 then (StartTime =  End time)  
        /// </returns>
        public AFTimeRange CalulationTimes(DateTime RunAt, TimeSpan CalculationPeriod, TimeSpan CalculatAtTime, int CalculationPeriodOffset, int CalulationPeriodsToRun)
        {
            //last calculation time from execution time

            AFTime LastTime = LastCalculationPeriod(RunAt, CalculationPeriod, CalculatAtTime);

            List<AFTime> TimesValues = new List<AFTime>();
            TimesValues.Add(new AFTime(LastTime.LocalTime + new TimeSpan(CalculationPeriodOffset * CalculationPeriod.Ticks)));
            //need to reduce the calculation period by one, otherwise Period + 1 time is returned. i.e. if period = 5, 6 timestamps are returned
            int adjustedCalcPeriods = System.Math.Sign(CalulationPeriodsToRun) * (System.Math.Abs(CalulationPeriodsToRun) - 1);
            TimesValues.Add(new AFTime(TimesValues.First().LocalTime + new TimeSpan(adjustedCalcPeriods * CalculationPeriod.Ticks)));

            //if Calc periods to run < 0 then run backward (StartTime = max, End time = min)
            //if Calc periods to run > 0 then run forwards (StartTime = min, End time = max)
            //if Calc periods to run = 0 then (StartTime =  End time)  
            if (CalulationPeriodsToRun > 0)
            {
                return new AFTimeRange(TimesValues.Min(), TimesValues.Max());
            }
            else if (CalulationPeriodsToRun < 0)
            {
                return new AFTimeRange(TimesValues.Max(), TimesValues.Min());
            }
            else
            {
                return new AFTimeRange(TimesValues.Min(), TimesValues.Min());
            }

        }


        /// <summary>
        /// Generates a list of AFtimes in the correct order to calculate at using the timeRange and Calculation Period
        /// if there is not an exact match the full calculation periods that fit into the range from the start time are returned
        /// </summary>
        /// <param name="timeRange"></param>
        /// <param name="Period"></param>
        /// <returns></returns>
        public List<AFTime> TimeRangeToList(AFTimeRange timeRange, TimeSpan Period)
        {
            //get the number of periods, take only full periods
            int periods = (int)(System.Math.Floor(System.Math.Abs(timeRange.Span.TotalSeconds / Period.TotalSeconds) + 1));

            //time range forward or backward. backwards = -1
            int TimeDir = System.Math.Sign(timeRange.Span.TotalSeconds);

            List<AFTime> TimeList = Enumerable.Range(0, System.Math.Abs(periods)).ToList().Select(i => new AFTime(timeRange.StartTime.LocalTime + new TimeSpan(TimeDir * i * Period.Ticks))).ToList();

            return TimeList;

        }
        /// <summary>
        /// returns an AFvalue from an AFValues for an attribute. If there is no value a bad value is created and returned
        /// </summary>
        /// <param name="AttributeValues"></param>
        /// <param name="Time"></param>
        /// <param name="ErrorStateForBad"></param>
        /// <returns></returns>
        public AFValue GetAFValueAtTime(AFValues AttributeValues, AFTime Time, AFSystemStateCode ErrorStateForMissing) //, AFSystemStateCode ErrorStateForBad)
        {
            AFValue res = new AFValue();
            res.Timestamp = Time;

            // A value could be bad or missing
            List<AFValue> lVals = AttributeValues.Where(v => v.Timestamp == Time).ToList();

            if (lVals != null)
            {
                if (lVals.Count > 0)
                {
                    //remove bad
                    //lVals.RemoveAll(v => !v.IsGood);                   

                    res = lVals.First();
                }
                else
                {
                    _APLeathAF.ConvertToErrorValue(res, ErrorStateForMissing);
                }
            }
            else
            {
                _APLeathAF.ConvertToErrorValue(res, ErrorStateForMissing);
            }

            return res;
        }

        /// <summary>
        /// returns all the values and times in the period as a tuple of double and AFTime and attribute name, the period goes from the Time forward. start time = time end time = Time + Calculation period
        /// </summary>
        /// <param name="AttributeValues"></param>
        /// <param name="Time"></param>
        /// <param name="CalculateTime"></param>
        /// <param name="CalculationPeriod"></param>
        /// <returns></returns>
        public static List<Tuple<double, AFTime, string>>  GetValuesInPeriod(AFValues AttributeValues, AFTime Time, TimeSpan CalculateTime, TimeSpan CalculationPeriod) //, List<AFTime> ValidTimes = null)
        {

            //if (ValidTimes == null) { ValidTimes = new List<AFTime>(); }

            //List<double> Rests = new List<double>();
            List<Tuple<double, AFTime, string>> Rests = new List<Tuple<double, AFTime, string>>();
            //get period start an end time
            if (CalculationPeriod.TotalSeconds > 0)
            {
                //set end time, less 1 second to not double account
                AFTime EndTime = new AFTime((Time.LocalTime + CalculationPeriod));

                // less than end time is used to ensure no double accounting
                List<AFValue> SlimList = new List<AFValue>();
                SlimList.AddRange(AttributeValues.Where(a => a.IsGood).Where(a => a.Timestamp >= Time & a.Timestamp < EndTime).ToList());


                foreach (AFValue val in SlimList)
                {
                    double t = double.NaN;
                    if (double.TryParse(val.Value.ToString(), out t))
                    {
                        //Rests.Add(t);
                        Rests.Add(new Tuple<double, AFTime, string>(t, val.Timestamp, val.Attribute.Name));
                        // ValidTimes.Add(val.Timestamp);
                    }

                }

            }
            else
            {
                throw new Exception("Calculation must have a period for function 'GetValuesInPeriod'");
            }

            return Rests;
        }



        /// <summary>
        /// compares the times in the two list and returns true if they match or false if they do not
        /// </summary>
        /// <param name="TimeSet1"></param>
        /// <param name="TimeSet2"></param>
        /// <returns></returns>
        public static Boolean  DoTimesCollate(List<AFTime> TimeSet1, List<AFTime> TimeSet2)
        {

            if (TimeSet1 == null | TimeSet2 == null) { return false; }

            if (TimeSet1.Count != TimeSet2.Count) { return false; }

            if (TimeSet1 == TimeSet2) { return true; }

            //items in first but not in second, does not do in second but not in first
            IEnumerable<AFTime> Missing1 = TimeSet1.Except(TimeSet2);
            if (Missing1.Count() > 0) { return false; }

            IEnumerable<AFTime> Missing2 = TimeSet2.Except(TimeSet1);
            if (Missing2.Count() > 0) { return false; }

            return true;
        }

        /// <summary>
        /// returns an AFvalue from an AFValues for an attribute where the times match the Calculated timespan 
        /// </summary>
        /// <param name="AttributeValues"></param>
        /// <param name="Time"></param>
        /// <param name="ErrorStateForMissing"></param>
        /// <param name="Period"></param>
        /// <returns></returns>
        public AFValue GetAFValuePeriodicorTime(AFValues AttributeValues, AFTime Time, AFSystemStateCode ErrorStateForMissing, TimeSpan CalculateTime, TimeSpan CalculationPeriod)
        {


            if ((CalculationPeriod.TotalHours == 24 | CalculationPeriod.TotalHours == 12 | CalculationPeriod.TotalHours == 8) & CalculateTime.Minutes == 0)
            {
                //period is daily, 12 or 8 hr shifts, then check for a value at shift change or one hour before
                // get required hour based on period, 6, 14, 18 or 22

                int adjHours = 0;
                //TimeSpan CalculateTime2 = CalculateTime;
                if (CalculateTime.Hours == 6)
                {
                    //or look for 5 if hour is 6
                    adjHours = -1;
                }
                else
                {
                    // or look for 6 if hour is 5
                    adjHours = 1;
                }


                AFValue res = new AFValue();
                res.Timestamp = Time;

                AFTime CheckTime1 = Time;
                AFTime CheckTime2 = new AFTime(Time.LocalTime.AddHours(adjHours));

                // A value could be bad or missing
                List<AFValue> lVals = AttributeValues.Where(v => v.Timestamp == CheckTime1 | v.Timestamp == CheckTime2).ToList();

                if (lVals != null)
                {
                    if (lVals.Count > 0)
                    {
              

                        res = lVals.First();
                    }
                    else
                    {
                        _APLeathAF.ConvertToErrorValue(res, ErrorStateForMissing);
                    }
                }
                else
                {
                    _APLeathAF.ConvertToErrorValue(res, ErrorStateForMissing);
                }

                return res;
            }
            else
            {
                // return a value at the exact time
                return GetAFValueAtTime(AttributeValues, Time, ErrorStateForMissing);

            }
        }

    }
}
