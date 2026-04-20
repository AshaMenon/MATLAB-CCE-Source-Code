using System;
using System.Collections.Generic;
using SharedLogger;
using NetCalculationState;
using System.Linq;

namespace CCELetheTheoreticalRecovery
{
    // Define inputs struct
    public struct Inputs
    {
        public double[] SHGrade;
        public double[] TailsGrade;
        public double[] TonsMilled;
        public DateTime[] SHGradeTimestamps;
        public DateTime[] TailsGradeTimestamps;
        public DateTime[] TonsMilledTimestamps;
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
        public double[] TheoreticalRecovery;
        public DateTime[] Timestamp;
    }

    public class CCELetheTheoreticalRecoveryClass
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
            Outputs sOutputs;

            Logger LogInstance = new Logger(LogName, CalculationID, CalculationName, (LogMessageLevel)LogLevel, "CCE_Calc_Logs");

            try
            {
                List<double> TheoreticalrecoveryList = new List<double>();

                // Compute date range for calculation
                DateTime OutputTime = DateTime.Parse(sParams.OutputTime);
                OutputTime = OutputTime.ToLocalTime();

                TimeSpan calcPeriod = new TimeSpan(0, 0, sParams.CalculationPeriod);
                TimeSpan calcAtTime = new TimeSpan(0, 0, sParams.CalculateAtTime);

                long ModTime = (OutputTime.Ticks - calcAtTime.Ticks) % calcPeriod.Ticks;
                DateTime LastTime = new DateTime(OutputTime.Ticks - ModTime, DateTimeKind.Local) + new TimeSpan(sParams.CalculationPeriodOffset * calcPeriod.Ticks);
                LogInstance.logTrace($"Current LastTime being used: {LastTime}");

                TimeSpan initTimeSpan = new TimeSpan(calcPeriod.Ticks * (sParams.CalculationPeriodsToRun - Math.Sign(sParams.CalculationPeriodsToRun)));
                DateTime startTime = LastTime + initTimeSpan;

                DateTime[] dateRange = GetDateRange(startTime, LastTime, sParams.CalculationPeriod);
                List<DateTime> timeLims = new List<DateTime> { startTime, LastTime };

                // Build aligned inputValues using dateRange
                List<Tuple<DateTime, double, double, double>> inputValues = new List<Tuple<DateTime, double, double, double>>();

                for (int iTime = 0; iTime < dateRange.Length; iTime++)
                {
                    DateTime cur = dateRange[iTime];
                    double sh = getVal(sInputs.SHGrade, sInputs.SHGradeTimestamps, cur, double.NaN);
                    double tails = getVal(sInputs.TailsGrade, sInputs.TailsGradeTimestamps, cur, double.NaN);
                    double tons = getVal(sInputs.TonsMilled, sInputs.TonsMilledTimestamps, cur, double.NaN);
                    inputValues.Add(new Tuple<DateTime, Double, Double, Double>(cur, sh, tails, tons));
                }

                List<Tuple<DateTime, double, double, double>> filteredInputValues = new List<Tuple<DateTime, double, double, double>>();
                filteredInputValues.AddRange(inputValues.Where(v => v.Item1 >= timeLims[0] && v.Item1 <= timeLims[1]));

                for (int iTime = 0; iTime < filteredInputValues.Count; iTime++)
                {
                    try
                    {
                        double sh = filteredInputValues[iTime].Item2;
                        double tails = filteredInputValues[iTime].Item3;
                        DateTime ts = filteredInputValues[iTime].Item1;

                        if (!double.IsNaN(sh) && sh != 0 && !double.IsNaN(tails))
                        {
                            double Theoreticalrecovery = (sh - tails) / sh * 100.0;
                            TheoreticalrecoveryList.Add(Theoreticalrecovery);
                            LogInstance.logTrace($"Recovery value at time: {ts} is {Theoreticalrecovery}");
                        }
                        else
                        {
                            TheoreticalrecoveryList.Add(double.NaN);
                            LogInstance.logWarning($"Calculation Sum Error. No good results for time '{ts}'");
                            ErrorCode = CalculationErrorState.BadInput;
                        }

                    }
                    catch (Exception e)
                    {
                        throw new Exception($"Calculation Recovery loop Error for calculation time '{filteredInputValues[iTime].Item1}'. Error message: {e.Message}");
                    }
                }

                sOutputs.TheoreticalRecovery = TheoreticalrecoveryList.ToArray();
                sOutputs.Timestamp = filteredInputValues.Select(v => v.Item1).ToArray();

                if (sOutputs.TheoreticalRecovery.Length == 0)
                {
                    sOutputs.TheoreticalRecovery = new double[] { double.NaN };
                    sOutputs.Timestamp = new DateTime[] { dateRange.Last() };
                }
            }
            catch (Exception e)
            {
                sOutputs.TheoreticalRecovery = new double[] { };
                sOutputs.Timestamp = new DateTime[] { };
                LogInstance.logError(e.Source + e.StackTrace + "." + e.Message);
                if (ErrorCode == CalculationErrorState.Good)
                {
                    ErrorCode = CalculationErrorState.CalcFailed;
                }
            }

            return sOutputs;
        }

        private static double getVal(double[] values, DateTime[] times, DateTime curDate, double defaultVal)
        {
            if (times == null || values == null) return defaultVal;
            int idx = Array.IndexOf(times, curDate);
            if (idx >= 0 && idx < values.Length)
            {
                return values[idx];
            }
            return defaultVal;
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