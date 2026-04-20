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

using Amplats.AF.Lethe.Calculation.LetheCalculationMethods;

namespace Amplats.AF.Lethe.Calculation
{
    public abstract class LetheCalculation : IJob
    {
        protected AFAttributeList ConfigurationAttributes = new AFAttributeList();

        public TimeSpan CalculationFrequency { get; set; }
        public bool WriteOutBadValues { get; set; }
        public bool CalculationTest { get; set; }

        public Int32 Loglevel { get; set; }

        protected AFElement Element { get; set; }

        public static string catAFInput = "Input";
        public static string catAFInterpolate = "Interpolate";
        public static string catAFCompressed = "Compressed";

        private string AttNameCalcFrequ = "CalculationFrequency";
        private string AttNameTest = "CalculationTest";
        private string AttNameWriteOutBad = "WriteOutBadValues";
        private string AttNamelogLevel = "LogLevel";

        protected Logger Log { get; private set; }

       public APLetheTime _APLetheTime = new APLetheTime();
       public APLetheAF _APLeathAF = new APLetheAF();
       public APLetheGeneral _APLetheGeneral = new APLetheGeneral();

        /// <summary>
        /// constructor
        /// </summary>

        public LetheCalculation()
        {
            Log = LogManager.GetLogger(GetType().FullName);
        }

        /// <summary>
        /// constructor
        /// </summary>
        /// <param name="CalculationElement"></param>
        public LetheCalculation(AFElement CalculationElement)
        {
            Log = LogManager.GetLogger(GetType().FullName);
            Initialize(CalculationElement);
        }


        /// <summary>
        /// Initialize the object. However, this could be done in the create method
        /// </summary>
        public void Initialize(AFElement CalculationElement)
        {
            try
            {
                Element = CalculationElement;
                //get required attributes from element           

                AddAttributeToList(ConfigurationAttributes, AttNameCalcFrequ, true);
                AddAttributeToList(ConfigurationAttributes, AttNameTest, false);
                AddAttributeToList(ConfigurationAttributes, AttNameWriteOutBad, false);
                AddAttributeToList(ConfigurationAttributes, AttNamelogLevel, false);

                AFValues configVals = ConfigurationAttributes.GetValue();

                //set Attribute values or defaults
                Int32 tempInt32;
                bool tempBool;

                GetAfValueInt32(out tempInt32, GetLatestAFttributeValue(configVals, AttNameCalcFrequ), null, false);
                CalculationFrequency = new TimeSpan(0, 0, tempInt32);

                GetAfValueBolean(out tempBool, GetLatestAFttributeValue(configVals, AttNameWriteOutBad), false, false);
                WriteOutBadValues = tempBool;

                GetAfValueBolean(out tempBool, GetLatestAFttributeValue(configVals, AttNameTest), false, false);
                CalculationTest = tempBool;

                GetAfValueInt32(out tempInt32, GetLatestAFttributeValue(configVals, AttNamelogLevel), 1, false);
            }
            catch (Exception e)
            {
                Log.Fatal(e, "Calculation Initialize Error on '{0}'. Message: {1} ", CalculationElement.GetPath(), e.Message);
                throw new Exception("Calculation Initialization error", e.InnerException);

            }

            CalculationInitialize();
        }

        /// <summary>
        /// Initialize and execute the calculation with an element and time
        /// </summary>
        /// <param name="Element"></param>
        /// <param name="ExecutionTime"></param>
        public async Task Execute(AFElement Element, DateTime ExecutionTime) //20210823 change for version 3.3.3 Quartz, was 'public Void Execute'
        {

            //initialize, add for scheduler
            Initialize(Element);

            AFValues results = Evaluate(ExecutionTime);

            //write out
            if (!CalculationTest)
            {
                WriteToAF(results);
            }
            else
            {
                // results to log, file or console
            }

        }

        /// <summary>
        /// Execute the calculation from the scheduler
        /// </summary>
        public async Task Execute(IJobExecutionContext context) //20210823 change for version 3.3.3 Quartz, was 'public Void Execute'
        {

            JobDataMap dataMap = context.MergedJobDataMap;
            Element = (AFElement)dataMap["Element"];

            //needs to be supplied through context
            DateTime ExecuteAt = DateTime.Now;

            await Execute(Element, ExecuteAt);

        }

        /// <summary>
        /// Basically causes the element details to be refreshed
        /// </summary>
        public abstract void RefreshElement();

        /// <summary>
        /// method to override for calculation specific parameters
        /// </summary>
        public abstract void CalculationInitialize();

        /// <summary>
        /// method to override to run the specific calculation, it needs to return an AFValues object that gets written out
        /// </summary>
        /// <returns></returns>
        public abstract AFValues Evaluate(DateTime ExecuteAt);

        /// <summary>
        /// gets the newest value of attribute of name x, from an AF values of mixed attributes
        /// intended for getting configuration items from the result of AttributeList.GetValue()
        /// </summary>
        /// <param name="values"></param>
        /// <param name="AttributeName"></param>
        /// <returns></returns>
        public AFValue GetLatestAFttributeValue(AFValues values, string AttributeName)
        {

            List<AFValue> valsAtt = values.Where(v => v.Attribute.Name == AttributeName).Where(r => r.IsGood).ToList();

            if (valsAtt != null)
            {
                if (valsAtt.Count > 0)
                {
                    return valsAtt.OrderByDescending(v => v.Timestamp.LocalTime).First();
                }
            }
            return null;

        }

        /// <summary>
        /// converts the AFValue to a double and returns true if this succeeds. returns false or throws an exception if the AFvalue
        /// is Bad or NaN. A default value can be substituted and returned. if default = null, the above applies
        /// on a bad value and the exception is suppressed the value is set too NaN
        /// </summary>
        /// <param name="Value"></param>
        /// <param name="inAFvalue"></param>
        /// <param name="DefaultValue"></param>
        /// <param name="SuppresException"></param>
        /// <returns></returns>
        public bool GetAfValueDouble(out double Value, AFValue inAFvalue, double? DefaultValue, bool SuppresException)
        {

            if (inAFvalue != null)
            {
                if (inAFvalue.IsGood)
                {
                    double gotVal = inAFvalue.ValueAsDouble();
                    if (!double.IsNaN(gotVal))
                    {
                        Value = gotVal;
                        return true;
                    }
                }
            }

            if (DefaultValue.HasValue)
            {
                Value = DefaultValue.Value;
                return true;
            }
            else
            {
                if (!SuppresException)
                {
                    throw new ArgumentOutOfRangeException("A required Attribute on Element '" + Element.GetPath() + "' does not have a value and no default is specified");
                }
                else
                {
                    Value = Double.NaN;
                    return false;
                }
            }


        }

        /// <summary>
        /// converts the AFValue to a Int32 and returns true if this succeeds. returns false or throws an exception if the AFvalue
        /// is Bad. A default value can be substituted and returned. if default = null, the the above applies
        /// on a bad value and the exception is suppressed the value is set to 0
        /// </summary>
        /// <param name="Value"></param>
        /// <param name="inAFvalue"></param>
        /// <param name="DefaultValue"></param>
        /// <param name="SuppresException"></param>
        /// <returns></returns>
        public bool GetAfValueInt32(out Int32 Value, AFValue inAFvalue, Int32? DefaultValue, bool SuppresException)
        {

            if (inAFvalue != null)
            {
                if (inAFvalue.IsGood)
                {
                    Value = inAFvalue.ValueAsInt32();
                    return true;
                }
            }

            if (DefaultValue.HasValue)
            {
                Value = DefaultValue.Value;
                return true;
            }
            else
            {
                if (!SuppresException)
                {
                    throw new ArgumentOutOfRangeException("A required Attribute on Element '" + Element.GetPath() + "' does not have a value and no default is specified");
                }
                else
                {
                    Value = 0;
                    return false;
                }

            }


        }

        /// <summary>
        /// converts the AFValue to a bool and returns true if this succeeds. returns false or throws an exception if the AFvalue
        /// is Bad. A default value can be substituted and returned. if default = null, the the above applies
        /// on a bad value and the exception is suppressed the value is set to false
        /// </summary>
        /// <param name="Value"></param>
        /// <param name="inAFvalue"></param>
        /// <param name="DefaultValue"></param>
        /// <param name="SuppresException"></param>
        /// <returns></returns>
        public bool GetAfValueBolean(out bool Value, AFValue inAFvalue, bool? DefaultValue, bool SuppresException)
        {
            bool vl;
            if (inAFvalue != null)
            {
                if (inAFvalue.IsGood)
                {
                    if (bool.TryParse(inAFvalue.Value.ToString(), out vl))
                    {
                        Value = vl;
                        return true;
                    }
                }
            }

            if (DefaultValue.HasValue)
            {
                Value = DefaultValue.Value;
                return true;
            }

            if (!SuppresException)
            {
                throw new ArgumentOutOfRangeException("A required Attribute on Element '" + Element.GetPath() + "' does not have a value and no default is specified");
            }
            else
            {
                Value = false;
                return false;
            }



        }

        /// <summary>
        /// returns the string value of the AFValue in the output parameter and returns true if it is good and false if it is bad. An exception is thrown if the for bad or missing values unless suppressed
        /// </summary>
        /// <param name="Value"></param>
        /// <param name="inAFvalue"></param>
        /// <param name="DefaultValue"></param>
        /// <param name="SuppresException"></param>
        /// <returns></returns>
        public bool GetAfValueString(out String Value, AFValue inAFvalue, String DefaultValue, bool SuppresException)
        {

            if (inAFvalue != null)
            {
                if (inAFvalue.IsGood)
                {
                    Value = inAFvalue.Value.ToString();
                        return true;
                }
            }
            if (!SuppresException)
            {
                throw new ArgumentOutOfRangeException("A required Attribute on Element '" + Element.GetPath() + "' does not have a good value");
            }
            else
            {
                Value = DefaultValue;
                return false;
            }


        }
        /// <summary>
        /// Looks for an attribute of the given name, if it is required and not found an exception is thrown
        /// </summary>
        /// <param name="Name"></param>
        /// <param name="Required"></param>
        public void AddAttributeToList(AFAttributeList attList, string Name, bool Required)
        {
            if (Element.Attributes.Contains(Name))
            {
                attList.Add(Element.Attributes[Name]);
            }
            else
            {
                if (Required)
                {
                    Log.Error("Error: required Attribute '{0}' not found on Element '{1}'", Name, Element.GetPath());
                    throw new ArgumentException("A required Attribute '" + Name + "' not found on Element '" + Element.GetPath() + "'");

                }
                else
                {
                    //log message 
                }
            }
        }

        /// <summary>
        /// Looks for an attribute of the given name, if it is required and not found an exception is thrown
        /// </summary>
        /// <param name="Name"></param>
        /// <param name="Required"></param>
        public AFAttribute GetAttribute(string Name, bool Required)
        {
            if (Element.Attributes.Contains(Name))
            {
                return Element.Attributes[Name];
            }
            else
            {
                if (Required)
                {
                    Log.Error("Error: required Attribute '{0}' not found on Element '{1}'", Name, Element.GetPath());
                    throw new ArgumentException("A required Attribute '" + Name + "' not found on Element '" + Element.GetPath() + "'");

                }
                else
                {
                    //log message 
                }
            }

            return null;
        }



        /// <summary>
        /// writes out the values too the specified attributes
        /// </summary>
        /// <param name="Results"></param>
        public void WriteToAF(AFValues Results)
        {
            Log.Debug("Writing AF Values for {0}", Element.Name);            
            if (Results != null)
            {

                //only write out values with an attribute
                Results.RemoveAll(r => r.Attribute == null);

                Log.Trace("Writing {0} AF Values for {1}", Results.Count(),Element.Name);

                if (!WriteOutBadValues)
                { Results.RemoveAll(r => !r.IsGood); }

                AFErrors<AFValue> ErrorResults = new AFErrors<AFValue>();

                Log.Trace("Writing {0} AF Values for {1} (if enabled, after bad values were removed)", Results.Count(), Element.Name);

                foreach (AFAttribute att in Results.Select(r => r.Attribute).Distinct())
                {
                    
                    AFValues atVals = new AFValues();
                    atVals.AddRange(Results.Where(r => r.Attribute == att));

                    ErrorResults = att.Data.UpdateValues(atVals, AFUpdateOption.Replace, AFBufferOption.BufferIfPossible);

                }

                // log results depending on log level
                if (ErrorResults != null)
                {
                    if (ErrorResults.HasErrors)
                    {
                        foreach (KeyValuePair<AFValue, Exception> err in ErrorResults.Errors)
                        {
                            Log.Trace("Write to AF Error for Attribute path '{0}' :{1}", err.Key.Attribute.GetPath(), err.Value.Message);
                        }
                    }
                }
            }
            else
            {
                Log.Debug("Writing AF Values for {0}, Result list is Null", Element.Name);       
            }
        }



    }
}
