using System;
using System.Collections.Generic;
using SharedLogger;
using NetCalculationState;
using System.Linq;

namespace cceLetheComponent
{
    // Define inputs struct
    public struct Inputs
    {
        public double[] Assay;
        public double[] DryMass;
        public double[] Estimate;
        public DateTime[] AssayTimestamps;
        public DateTime[] DryMassTimestamps;
        public DateTime[] EstimateTimestamps;
    }

    // Define parameters struct
    public struct Parameters
    {
        public int CalculationPeriodsToRun;
        public int CalculationPeriod;
        public int CalculateAtTime;
        public string OutputTime;
        public bool ComponentIsPercent;
        public int CalculationPeriodOffset;
    }

    // Define outputs struct
    public struct Outputs
    {
        public double[] Component;
        public DateTime[] Timestamp;
    }

    public class cceLetheComponentClass
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

                double TimestampLength = sInputs.AssayTimestamps.Length;

                if (sInputs.DryMass.Length == 0 | sInputs.Assay.Length == 0)
                {
                    sOutputs.Component = new double[]{ double.NaN};
                    sOutputs.Timestamp = new DateTime[] { dateRange.Last() };

                    return sOutputs;
                }

                List<Tuple<DateTime, double, double, double>> inputValues = new List<Tuple<DateTime, double, double, double>>();
                

                for (int iTime = 0; iTime < dateRange.Length; iTime++)
                {
                    inputValues.Add(new Tuple<DateTime, Double, Double, Double>(dateRange[iTime], getVal(sInputs.Assay, sInputs.AssayTimestamps, dateRange[iTime], double.NaN),
                        getVal(sInputs.DryMass, sInputs.DryMassTimestamps, dateRange[iTime], double.NaN),
                        getVal(sInputs.Estimate, sInputs.EstimateTimestamps, dateRange[iTime], double.NaN)));
                }


                List<double> ComponentList = new List<double>();

                for (int iTime = 0; iTime < dateRange.Length; iTime++)
                {
                    double totalDry = 0;
                    double totalComp = 0;
                    bool missingAssay = true;

                    double dryVal = inputValues[iTime].Item3;
                    double assayVal = inputValues[iTime].Item2;
                    double estVal = inputValues[iTime].Item4;

                    CalculateComponent(dryVal, assayVal, estVal, ref totalComp, ref totalDry, ref missingAssay, sParams.ComponentIsPercent);


                    ComponentList.Add(totalComp);

                    var msg = string.Format("Component at time: {0} is {1}", dateRange[iTime].ToString(), totalComp);
                    LogInstance.logTrace(msg);                        
                }

                sOutputs.Component = ComponentList.ToArray();
                sOutputs.Timestamp = dateRange;

                if (sOutputs.Component.Length == 0)
                {
                    sOutputs.Component = new double[] { double.NaN };
                    sOutputs.Timestamp = new DateTime[] { dateRange.Last() };
                }
            }
            catch (Exception e)
            {
                // Return empty outputs
                double[] tempArray = { };
                sOutputs.Component = tempArray;
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

        private void CalculateComponent(double dryMass, double assay, double est, ref double componentTotal, ref double dryMassTotal, ref bool missingAssay, bool isPercent)
        {
            //bool isQuestionable = false;

            if (!double.IsNaN(dryMass))
            {
                if (dryMass != 0)
                {
                    if (!double.IsNaN(assay))
                    {
                        if (!double.IsNaN(est))
                        {
                            assay = est;
                            //isQuestionable = true;
                            missingAssay = false;
                        }
                        else { missingAssay = true; }
                    }
                    else { missingAssay = false; }

                    if (!double.IsNaN(assay))
                    {
                        double comp;
                        if (isPercent)
                        {
                            comp = dryMass * assay / 100;
                        }
                        else
                        {
                            comp = dryMass * assay;
                        }
                        //Result.Value = comp;
                        //.Questionable = IsQuestionable;

                        componentTotal += comp;
                    }
                    else
                    {
                        //bad value or missing value from moisture mass use its error state if it has one
                        //throw new ArgumentNullException("Assay is NaN for attribute. Aborting calc.");
                        missingAssay = true;
                        componentTotal = double.NaN;
                    }
                }
                else
                {
                    //Result.Value = 0;
                    missingAssay = false;
                }
                dryMassTotal += dryMass;
            }
            else
            {
                //bad value or missing value from wet mass use its error state if it has one
                //throw new ArgumentNullException("Assay is NaN for attribute. Aborting calc.");
                missingAssay = true;
                componentTotal = double.NaN;
            }
        }
    }
}


