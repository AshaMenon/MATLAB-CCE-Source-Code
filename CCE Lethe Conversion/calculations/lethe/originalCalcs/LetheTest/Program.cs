using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using OSIsoft.AF;
using OSIsoft.AF.Asset;
using OSIsoft.AF.Data;
using Amplats.AF.Lethe.Calculation;

namespace Amplats.AF.Lethe.LetheTest
{
    class Program
    {
        static void Main(string[] args)
        {

            //PISystem af = new PISystems()["cenmes"];
            //PISystem af = new PISystems()["WAR"];
            //PISystem af = new PISystems()["abmrmes"];
            //PISystem af = new PISystems()["aishexpidev01"];
            PISystem af = new PISystems()["mogmes"];
            //PISystem af = new PISystems()["motmes"];

            //AFDatabase _afdb = af.Databases["Training01"];
            //AFDatabase _afdb = af.Databases["WACP"];
            //AFDatabase _afdb = af.Databases["ABMR"];
            //AFDatabase _afdb = af.Databases["WAR"];
            AFDatabase _afdb = af.Databases["MOGN"];
            //AFDatabase _afdb = af.Databases["MOT"];

            //get calculations templates
            //Base template

            //AFElementTemplate ctemp = _afdb.ElementTemplates["APLetheCalculations"];
            //AFElementTemplate ctemp = _afdb.ElementTemplates["APLethePeriodWeighting"];
            //AFElementTemplate ctemp = _afdb.ElementTemplates["APLetheSum"];
            //AFElementTemplate ctemp = _afdb.ElementTemplates["APLetheSum"];
            //AFNamedCollectionList<AFElement> CalcElements = AFElement.FindElementsByTemplate(_afdb, null, ctemp, true, AFSortField.ID, AFSortOrder.Descending, 500);

            //get correct items

            // AFElement drymass = CalcElements["APLetheEstimateFeedMoisture"]; //["APLetheDryMass2"]; //["APLetheDryMass1"];
            //AFElement drymass = CalcElements["DailyEstimate"];
            // AFElement drymass = CalcElements["APLetheEstimateArray"];
            //AFElement drymass = CalcElements["APLetheDryMassYTD"];
            //AFElement drymass = CalcElements["APLetheConcDailyCr2O3Rollup"];
            //AFElement drymass = CalcElements["APLetheConc4TRollup"];
            //AFElement drymass = CalcElements["APLetheTails"];
            // AFElement drymass = CalcElements["APLetheRecovery4T"];
            //AFElement drymass = CalcElements["APLetheTails4T"];
            //AFElement drymass = CalcElements["APLetheMassPull"];
            //AFElement drymass = CalcElements["APLetheAccountability4T"];
            //AFElement drymass = CalcElements["APLetheWSMLStreamMapper"];
            //AFElement drymass = CalcElements["ConcRollup4TDaily"];
            //AFElement drymass = CalcElements["APLetheSubstitute"];
            //AFElement drymass = CalcElements["APLethePeriodSum"];
            //AFElement drymass = CalcElements["APLethePeriodWeighting"];
            //AFElement drymass = CalcElements.First();
            //create calc and pass in Element

            List <string> _afPath = new List<string>();
            //String ElemPAth = "\\\\mogmes\\MOGN\\Calculations\\MOGN\\Ni\\ConcMass\\Daily";
            //String ElemPAth = "\\\\mogmes\\MOGN\\Calculations\\MOGN\\DM\\FeedDryMass\\DailyEstimate";
            //String ElemPAth = "\\\\usmlmes\\USML\\Calculations\\Calculations\\APLetheHeartBeat"; 
            //String ElemPAth = "\\\\MogSMes\\MogS\\Calculations\\SiteMetalContent\\OM.Calculations\\MK_SOC_PC_STH_BDT.day.m53";
            //String ElemPAth = "\\\\abmrmes\\ABMR\\Calculations\\MC.UG21\\PM\\ConcAssay\\H20DailyEstimateWSML";
            //String ElemPAth = "\\\\abmrmes\\ABMR\\Calculations\\FeedCalculation\\PebblesAndSpillagesUG2";
            //String ElemPAth = "\\\\abmrmes\\ABMR\\Calculations\\MC.UG21\\DM\\ConcDryMass\\DailySubstituteWSML";
            //String ElemPAth = "\\\\rbmrmes\\RBMR\\Calculations\\L:P&T.Cu.Ni.Percents\\NiTHCathodeQualityClass1.Percent.Day";
            String ElemPAth = "\\\\mogmes\\MOGN\\Calculations\\MOGN\\4T\\TailsAssay\\DailySubstitute";

            _afPath.Add(ElemPAth);
            AFNamedCollectionList<AFElement> CalcElements = new AFNamedCollectionList<AFElement>();
            CalcElements.AddRange(AFElement.FindElementsByPath(_afPath.AsEnumerable(), _afdb));
            AFElement drymass = AFElement.FindElementsByPath(_afPath.AsEnumerable(), _afdb)[ElemPAth];



            //APLetheDryMass calc = new APLetheDryMass();
            //APLetheEstimate calc = new APLetheEstimate();
            APLetheSubstitute calc = new APLetheSubstitute();
            //APLethePeriodSum calc = new APLethePeriodSum();
            //APLethePeriodWeighting calc = new APLethePeriodWeighting();
            //APLetheSum calc = new APLetheSum();
            //APLetheDryMass calc = new APLetheDryMass();
            //APLetheTails calc = new APLetheTails();
            //APLetheRecovery calc = new APLetheRecovery();
            //APLetheComponent calc = new APLetheComponent();
            //APLetheAccountability calc = new APLetheAccountability();
            //APLetheStreamMapper calc = new APLetheStreamMapper();
            //APLetheAssay calc = new APLetheAssay();
            //APLetheAverage calc = new APLetheAverage();
            //APLetheMapReduce calc = new APLetheMapReduce();
            //APLetheHeartBeat calc = new APLetheHeartBeat();
            //APLethePeriodWeighting calc = new APLethePeriodWeighting();
            //APLetheMapReduce calc = new APLetheMapReduce();
            //APLethePebblesAndSpillagesUG calc = new APLethePebblesAndSpillagesUG();
            //APLethePeriodAverage calc = new APLethePeriodAverage();

            calc.Execute(drymass, DateTime.Parse("2022-02-27 09:00:00"));
            //calc.Execute(drymass,DateTime.Now);

        }
    }
}
