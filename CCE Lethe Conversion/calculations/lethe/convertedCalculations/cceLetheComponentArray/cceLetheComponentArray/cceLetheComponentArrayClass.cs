using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using NetCalculationState;
using SharedLogger;

namespace cceLetheComponentArray
{
    // Define inputs struct
    public struct Inputs
    {
        public double[,] Assay;
        public double[,] DryMass;
        public double[,] Estimate;

        public string[] AssaySuffixes;
        public string[] DryMassSuffixes;
        public string[] EstimateSuffixes;

        public DateTime[] AssayTimestamps;
        public DateTime[] DryMassTimestamps;
        public DateTime[] EstimateTimestamps;
    }

    // Define parameters struct
    public struct Parameters
    {
        public bool ComponentIsPercent;
        public bool DoRollupAssay;
        public bool DoRollupDry;
        public bool RequireAllAssayInputs;
        public int CalculationPeriodsToRun;
        public int CalculationPeriod;
        public string OutputTime;
        public int CalculateAtTime;
        public int CalculationPeriodOffset;
    }

    // Define outputs struct
    public struct Outputs
    {
        public double[] Component;
        public double[] RollupAssay;
        public double[] RollupDry;
        public DateTime[] Timestamp;
    }

    public class cceLetheComponentArrayClass
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
                // Calculation logic
                List<double> ComponentList = new List<double>();
                List<double> RollupAssayList = new List<double>();
                List<double> RollupDryList = new List<double>();

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



                for (int iTime = 0; iTime < dateRange.Length; iTime++)
                {
                    // Create dictionaries
                    Dictionary<string, double> dAssay = new Dictionary<string, double>();
                    AssignRollUpsToDictionary(ref dAssay, sInputs.AssaySuffixes, getValAtTime(sInputs.AssayTimestamps, sInputs.Assay, dateRange[iTime]));

                    Dictionary<string, double> dDry = new Dictionary<string, double>();
                    AssignRollUpsToDictionary(ref dDry, sInputs.DryMassSuffixes, getValAtTime(sInputs.DryMassTimestamps, sInputs.DryMass, dateRange[iTime]));

                    Dictionary<string, double> dEst = new Dictionary<string, double>();
                    AssignRollUpsToDictionary(ref dEst, sInputs.EstimateSuffixes, getValAtTime(sInputs.EstimateTimestamps, sInputs.Estimate, dateRange[iTime]));

                    Dictionary<string, double> dAssayVals = new Dictionary<string, double>();
                    Dictionary<string, double> dDryMassVals = new Dictionary<string, double>();
                    Dictionary<string, double> dEstVals = new Dictionary<string, double>();

                    foreach (string nameSuffix in dAssay.Keys)
                    {
                        dAssayVals.Add(nameSuffix, GetArrayValuesFromDict(nameSuffix, dAssay));
                        dDryMassVals.Add(nameSuffix, GetArrayValuesFromDict(nameSuffix, dDry));
                        dEstVals.Add(nameSuffix, GetArrayValuesFromDict(nameSuffix, dEst));
                    }

                    double totalDry = 0;
                    double totalComp = 0;
                    bool missingAssay = true;

                    foreach (string nameSuffix in dAssay.Keys)
                    {
                        double assayVal = dAssayVals[nameSuffix];
                        double dryVal = dDryMassVals[nameSuffix];
                        double estVal = dEstVals[nameSuffix];
                        CalculateComponent(dryVal, assayVal, estVal, ref totalComp, ref totalDry, ref missingAssay, sParams.ComponentIsPercent);

                        if (sParams.RequireAllAssayInputs & missingAssay)
                        { break; } //some assays are missing and all are required before doing the roll-up
                    }

                    //RequireAllInputs > 0, groupjoin on name suffix, then check inputs must = 2 where drymass > 0
                    //full list

                    //var Group = dAssay.Keys.GroupJoin()
                    if (sParams.RequireAllAssayInputs & missingAssay)
                    {
                        LogInstance.logInfo("Assay input missing");
                        ComponentList.Add(double.NaN);
                    }
                    else
                    {
                        ComponentList.Add(totalComp);

                        var msg = string.Format("Component at time: {0} is {1}", dateRange[iTime].ToString(), totalComp);
                        LogInstance.logTrace(msg);
                    }

                    if (sParams.DoRollupAssay)
                    {
                        if (sParams.RequireAllAssayInputs & missingAssay)
                        {
                            RollupAssayList.Add(double.NaN);
                        }
                        else
                        {

                            if (totalDry == 0 | totalComp == 0)
                            {
                                LogInstance.logInfo("Total comp or total dry zero, rollup assay not returned.");
                                RollupAssayList.Add(double.NaN);
                            }
                            else
                            {
                                if (sParams.ComponentIsPercent)
                                {
                                    double tempOut = totalComp / totalDry * 100;
                                    RollupAssayList.Add(tempOut);

                                    var msg = string.Format("RollupAssay at time: {0} is {1}", dateRange[iTime].ToString(), tempOut);
                                    LogInstance.logTrace(msg);
                                }
                                else
                                {
                                    double tempOut = totalComp / totalDry;
                                    RollupAssayList.Add(tempOut);

                                    var msg = string.Format("RollupAssay at time: {0} is {1}", dateRange[iTime].ToString(), tempOut);
                                    LogInstance.logTrace(msg);
                                }
                            }

                        }

                    }
                    else
                    {
                        RollupAssayList.Add(double.NaN);

                        var msg = string.Format("RollupAssay at time: {0} is {1}", dateRange[iTime].ToString(), double.NaN);
                        LogInstance.logTrace(msg);
                    }

                    if (sParams.DoRollupDry)
                    {
                        if (sParams.RequireAllAssayInputs & missingAssay)
                        {
                            RollupDryList.Add(double.NaN);

                            var msg = string.Format("RollupDry at time: {0} is {1}", dateRange[iTime].ToString(), double.NaN);
                            LogInstance.logTrace(msg);
                        }
                        else
                        {
                            RollupDryList.Add(totalDry);

                            var msg = string.Format("RollupDry at time: {0} is {1}", dateRange[iTime].ToString(), totalDry);
                            LogInstance.logTrace(msg);
                        }
                    }
                    else
                    {
                        RollupDryList.Add(double.NaN);

                        var msg = string.Format("RollupDryList at time: {0} is {1}", dateRange[iTime].ToString(), double.NaN);
                        LogInstance.logTrace(msg);
                    }

                }

                sOutputs.Component = ComponentList.ToArray();
                sOutputs.RollupAssay = RollupAssayList.ToArray();
                sOutputs.RollupDry = RollupDryList.ToArray();
                sOutputs.Timestamp = dateRange;
                return sOutputs;
            }
            catch (Exception e)
            {
                // Return empty outputs
                double[] tempOut = { };
                sOutputs.Component = tempOut;
                sOutputs.RollupAssay = tempOut;
                sOutputs.RollupDry = tempOut;
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

        private double[] getValAtTime(DateTime[] timestamps, double[,] values, DateTime dateToCompare)
        {
            int index;

            if (values.GetLength(0) >= timestamps.Length)
            {
                index = Array.IndexOf(timestamps, dateToCompare);
            }
            else
            {
                index = -1;
            }
            

            if (index >= 0)
            {
                double[]  output = GetRow(values, index);
                return output;
            }
            else
            {
                int numCols = values.GetLength(1);
                double[] output = new double[numCols];
                for (int i = 0; i < numCols; i++)
                {
                    output[i] = double.NaN;
                }
                return output;
            }

        }

        // AssignRollupsToDictionary adds suffixes as keys and corresponding values to dictionary
        // dict - Reference dictionary to add key-val pair to
        // suffixArray - string array which will make up keys
        // values - array of values
        private void AssignRollUpsToDictionary(ref Dictionary<string, double> dict, string[] suffixArray, double[] values)
        {
            for (int i = 0; i < suffixArray.Length; i++)
            {
                string s = suffixArray[i];
                dict.Add(s, values[i]);
            }
        }
        private double GetArrayValuesFromDict(string searchName, Dictionary<string, double> inputDict)
        {
            double data = double.NaN;
            if (inputDict.ContainsKey(searchName))
            {
                data = inputDict[searchName];
                return data;
            }
            return data;
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
                        componentTotal += 0;
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
                componentTotal += 0;
            }
        }

        private double[] GetRow(double[,] matrix, int rowNumber)
        {
            return Enumerable.Range(0, matrix.GetLength(1))
                    .Select(x => matrix[rowNumber, x])
                    .ToArray();
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