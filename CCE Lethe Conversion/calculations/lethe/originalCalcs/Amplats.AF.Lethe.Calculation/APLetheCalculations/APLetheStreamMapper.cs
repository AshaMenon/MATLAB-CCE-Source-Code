using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System.Net;
using OSIsoft.AF.Asset;
using OSIsoft.AF.Data;
using OSIsoft.AF.Time;
using OSIsoft.AF.PI;
using Quartz;
using Amplats.AF.Lethe.Factory;
using Amplats.AF.Lethe.Calculation.StreamDataDomainServiceData;

namespace Amplats.AF.Lethe.Calculation
{
    public class APLetheStreamMapper : LetheCalculation
    {
        public TimeSpan CalculationPeriod { get; set; }
        public TimeSpan CalculatAtTime { get; set; }
        public Int32 CalculationPeriodOffset { get; set; }
        public Int32 CalulationPeriodsToRun { get; set; }
        private string OdataService { get; set; }
        private string OdataParameters { get; set; }
        private string ODataMethod { get; set; }


        private string AttNameCalculationPeriod = "CalculationPeriod";
        private string AttNameCalculateAtTime = "CalculateAtTime";
        private string AttNameCalculationPeriodOffset = "CalculationPeriodOffset";
        private string AttNameCalculationPeriodsToRun = "CalculationPeriodsToRun";

        private string AttNameOdataService = "OdataService";
        private string AttNameOdataParameters = "OdataParameters";
        private string AttNameODataMethod = "ODataMethod";


        /// <summary>
        /// 
        /// </summary>
        public APLetheStreamMapper() : base() { }

        /// <summary>
        /// construct calc
        /// </summary>
        /// <param name="CalculationElement"></param>
        public APLetheStreamMapper(AFElement CalculationElement) : base(CalculationElement) { }

        /// <summary>
        /// initialize the calculation specific variables
        /// </summary>
        public override void CalculationInitialize()
        {
            try
            {

                Log.Info("Calculation APLetheStremMapperWriteout initialization starting for:'{0}'", Element.GetPath());

                //load calculation specific parameters
                AddAttributeToList( ConfigurationAttributes, AttNameCalculationPeriod, true);
                AddAttributeToList( ConfigurationAttributes, AttNameCalculateAtTime, true);
                AddAttributeToList( ConfigurationAttributes, AttNameCalculationPeriodOffset, true);
                AddAttributeToList( ConfigurationAttributes, AttNameCalculationPeriodsToRun, true);

                AddAttributeToList(ConfigurationAttributes, AttNameOdataService, true);
                AddAttributeToList(ConfigurationAttributes, AttNameOdataParameters, true);
                AddAttributeToList(ConfigurationAttributes, AttNameODataMethod, true);



                AFValues configVals = ConfigurationAttributes.GetValue();

                Int32 tempInt32;
                GetAfValueInt32(out tempInt32, GetLatestAFttributeValue(configVals, AttNameCalculationPeriod), null, false);
                CalculationPeriod = new TimeSpan(0, 0, 0, tempInt32);

                GetAfValueInt32(out tempInt32, GetLatestAFttributeValue(configVals, AttNameCalculateAtTime), null, false);
                CalculatAtTime = new TimeSpan(0, 0, 0, tempInt32);

                GetAfValueInt32(out tempInt32, GetLatestAFttributeValue(configVals, AttNameCalculationPeriodOffset), null, false);
                CalculationPeriodOffset = tempInt32;

                GetAfValueInt32(out tempInt32, GetLatestAFttributeValue(configVals, AttNameCalculationPeriodsToRun), null, false);
                CalulationPeriodsToRun = tempInt32;

                String tempString;
                GetAfValueString(out tempString,GetLatestAFttributeValue(configVals, AttNameOdataService),null,false);
                OdataService = tempString;

                GetAfValueString(out tempString, GetLatestAFttributeValue(configVals, AttNameOdataParameters), null, false);
                OdataParameters = tempString;

                GetAfValueString(out tempString, GetLatestAFttributeValue(configVals, AttNameODataMethod), null, false);
                ODataMethod = tempString;




            }
            catch(Exception e)
            {
                Log.Fatal(e, "Calculation StremMapperWriteout Initialize Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
                throw new Exception("Calculation StremMapperWriteout Initialization error", e.InnerException);

            }

        }


        public override AFValues Evaluate(DateTime CalculationTime)
        {
            AFValues results = new AFValues(); // needed but has no outputs

            try
            {


                //set times an range
                AFTimeRange afRange = _APLetheTime.CalulationTimes(CalculationTime, CalculationPeriod, CalculatAtTime, CalculationPeriodOffset, CalulationPeriodsToRun);

                //Calculation times
                //List<AFTime> TimeList = TimeRangeToList(afRange, CalculationPeriod);

                //get as min and max dates
                List<AFTime> Tim = new List<AFTime>(){afRange.StartTime, afRange.EndTime};

                //substitute dates into parameters
                string _ODataParam = OdataParameters.Replace("#StartDate#", Tim.Min().LocalTime.ToString());
                _ODataParam = _ODataParam.Replace("#EndDate#", Tim.Max().LocalTime.ToString());

                System.Uri queryURI = new System.Uri(OdataService + ODataMethod + _ODataParam);
                StreamDataDomainServiceData.StreamServiceData StreamMapper = new StreamDataDomainServiceData.StreamServiceData(new System.Uri(OdataService));

                ICredentials credentials  = CredentialCache.DefaultCredentials;
                NetworkCredential currCred = credentials.GetCredential(queryURI, "Windows");
                StreamMapper.Credentials = currCred;

                
                // get inputs
               // StreamMapper.StreamTotals.Execute();
                //how to execute ? service
                List<StreamDataDomainServiceData.StreamTotal> resultList = new List<StreamDataDomainServiceData.StreamTotal>(StreamMapper.Execute<StreamDataDomainServiceData.StreamTotal>(queryURI));
                //List<StreamDataDomainServiceData.StreamTotal> resultList = new List<StreamDataDomainServiceData.StreamTotal>(); // (StreamMapper.Execute(new StreamDataDomainServiceData.StreamTotal(queryURI)));



                //create attribute list from results
                AFAttributeList attrList = new AFAttributeList();
                

                //get all stream totals by name that have a pi tag
               foreach(StreamDataDomainServiceData.StreamTotal Tot in resultList.Where(r => r.PITag.Length > 0))
               {
                       try
                       {

                           if (!attrList.Contains(Tot.StreamTotalName))
                           {

                               AFAttribute Att = new AFAttribute(String.Format(Tot.PITag));
                               Att.Name = Tot.StreamTotalName;
                               attrList.Add(Att);
                               //tt = new AFAttribute(String.Format(CultureInfo.InvariantCulture, @"\\{0}\{1}", piServer.Name, point.Name));
                           }
                       }
                       catch (Exception e)
                       {
                           Log.Error(e, " Error on StreamMapper calc for '{0}' failed to create output Attribute '{1}' for PItag '{2}' : Message: {3} ", Element.GetPath(), Tot.StreamTotalName, Tot.PITag, e.Message);
                       }

                       if (attrList.Contains(Tot.StreamTotalName))
                       {
                           try
                           {
                               //get time, force output to specified time of day at local time kind otherwise af gets the time zone correction added
                               DateTime reT = new DateTime(Tot.Day.Date.Ticks + CalculatAtTime.Ticks, DateTimeKind.Local);
                               

                               AFValue afSM = new AFValue();
                               afSM.Timestamp = new AFTime(reT);
                               afSM.Attribute = attrList[Tot.StreamTotalName];

                               if (Tot.Message != null)
                               {
                                   if (Tot.Message.ToLower().Contains("error"))
                                   {
                                       //write out bad value
                                   }


                                   if (Tot.Message.ToLower().Contains("estimate"))
                                   {
                                       afSM.Questionable = true;
                                   }
                                   else
                                   {
                                       afSM.Questionable = false;
                                   }
                               }

                               //add value if double otherwise write bad state
                               if (double.IsNaN(Tot.Result))
                               {
                                   _APLeathAF.ConvertToErrorValue(afSM, AFSystemStateCode.Bad, null);
                               }
                               else
                               {
                                   afSM.Value = Tot.Result;
                                   afSM.IsGood = true;
                               }


                               results.Add(afSM);
                           }
                           catch (Exception e)
                           {
                               Log.Error(e, " Error on StreamMapper calc for '{0}' AFValue add error '{1}' at {2}, for PItag '{3}' : Message: {4} ", Element.GetPath(), Tot.StreamTotalName, Tot.Day.ToLongDateString(), Tot.PITag, e.Message);
                           }

                       }

               }



            }
            catch (Exception e)
            {
                Log.Fatal(e, "Calculation StremMapperWriteout Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
            }
                        // the results are automatically written out to the AFAttribute set on the each AFValue 
           
            
            return results;

        }

        public override void RefreshElement()
        {
            throw new NotImplementedException();
        }


    }
}
