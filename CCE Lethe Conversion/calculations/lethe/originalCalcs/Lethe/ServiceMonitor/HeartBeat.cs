using OSIsoft.AF.Asset;
using OSIsoft.AF.PI;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Amplats.AF.Lethe.ServiceMonitor
{
    /// <summary>
    /// A class to monitor the service
    /// </summary>
    class HeartBeat
    {
        #region Fields
        private PIPoint _HBPIPoint;
        private int _LastValue = -1;
        private string _HBPIPointName;
        #endregion

        #region Properties
        private string ComputerName
        {
            get
            {
                return System.Environment.MachineName;
            }
        }

        private string HBPIPointName
        {
            get
            {
                if (string.IsNullOrEmpty(_HBPIPointName))
                {
                    _HBPIPointName = string.Format("Lethe.{0}.HeartBeat", ComputerName);
                }
                return _HBPIPointName;
            }
        }

        public int HeartBeatValue
        {
            get
            {
                if (_LastValue >= 15)
                {
                    _LastValue = 0;
                    return _LastValue;
                }
                else
                {
                    _LastValue++;
                    return _LastValue;
                }
            }
        }

        #endregion
        public HeartBeat(AppSettings appSettings)
        {
            // TODO: make this a configuration parameter
            var piServer = ConnectPIServer(appSettings.PIServerName);

            if (!(string.IsNullOrEmpty(appSettings.HBPIPointName)))
            {
                _HBPIPointName = appSettings.HBPIPointName;
            }
            _HBPIPoint = GetHBPIPoint(piServer);  

        }

        #region Private methods
        private PIServer ConnectPIServer(string PIServerName)
        {
            var piServers = new PIServers();
            PIServer piServer;
            if (string.IsNullOrEmpty(PIServerName))
            {
                piServer = piServers.DefaultPIServer;
            }
            else
            {
                piServer = piServers[PIServerName];
            }          
            return piServer;

        }

        private PIPoint GetHBPIPoint(PIServer piServer)
        {
            PIPoint hbPIPoint;

            if (!(PIPoint.TryFindPIPoint(piServer, HBPIPointName, out hbPIPoint)))
            {
                hbPIPoint = CreatePIPoint(piServer);
            }

            return hbPIPoint;
        }
       
        private PIPoint CreatePIPoint(PIServer piServer)
        {
            var attrib = new Dictionary<string, object>();

            attrib.Add("descriptor", "Lethe heartbeat");
            attrib.Add("zero", 0);
            attrib.Add("span", 15);
            attrib.Add("typicalvalue", 0);
            attrib.Add("pointsource", "Lethe");
            attrib.Add("compressing", 0);
            attrib.Add("compdevpercent", 0);
            attrib.Add("excdevpercent", 0);
            attrib.Add("pointtype", "int32");
            attrib.Add("step", 1);

            var hbPIPoint = piServer.CreatePIPoint(HBPIPointName, attrib);
            return hbPIPoint;
        }

        #endregion

        #region Public Classes
        public void UpdateHeartBeat()
        {
            var hbValue = new AFValue(HeartBeatValue, DateTime.UtcNow);

            _HBPIPoint.UpdateValue(hbValue, OSIsoft.AF.Data.AFUpdateOption.Insert, OSIsoft.AF.Data.AFBufferOption.BufferIfPossible);
        }
        #endregion


    }
}
