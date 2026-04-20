using NLog;
using OSIsoft.AF;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace Amplats.AF.Lethe
{
    public class AFConnection
    {
        #region Fields
        private static Logger Log = LogManager.GetCurrentClassLogger();
        const string _AFDBURIPattern = @"\\\\(?<PISystemName>\S+)\\(?<AFDatabaseName>\S+)";

        #endregion

        #region Public Properties

        #endregion

        public static AFDatabase Connect(string AFDatabaseURI)
        {
            var _afConnection = new AFConnection();

            Regex regexPattern = new Regex(_AFDBURIPattern);
            MatchCollection mc = regexPattern.Matches(AFDatabaseURI);

            string piSystemName;
            string afDatabaseName;

            if (mc.Count == 1)
            {
                piSystemName = mc[0].Groups["PISystemName"].Value;
                afDatabaseName = mc[0].Groups["AFDatabaseName"].Value;
            }
            else
            {
                throw new ArgumentException("The URI ({0}) is incorrectly formatted.", AFDatabaseURI);
            }

            PISystem piSystem = _afConnection.GetPISystem(piSystemName);
            AFDatabase afDatabase = _afConnection.GetAFDatabase(piSystem, afDatabaseName);

            return afDatabase;
        }

        #region Private Methods
        private PISystem GetPISystem(string PISystemName)
        {
            PISystems piSystems = new PISystems();
            PISystem piSystem;
            if (string.IsNullOrEmpty(PISystemName))
            {
                piSystem = piSystems.DefaultPISystem;
            }
            else
            {
                piSystem = piSystems[PISystemName];
            }

            if (piSystem == null)
            {
                Log.Fatal("Unknown PI System in configuarion ({0}).", PISystemName);
                throw new ArgumentException("Unknown PI System {0}.", PISystemName);
            }
            return piSystem;
        }

        private AFDatabase GetAFDatabase(PISystem piSystem, string AFDatabaseName)
        {
            AFDatabase afDatabase;
            if (string.IsNullOrEmpty(AFDatabaseName))
            {
                afDatabase = piSystem.Databases.DefaultDatabase;
            }
            else
            {
                afDatabase = piSystem.Databases[AFDatabaseName];
            }

            if (afDatabase == null)
            {
                Log.Fatal("Unknown AF Database in configuration ({0}).", AFDatabaseName);
                throw new ArgumentException("Unknown AF Database {0}.", AFDatabaseName);
            }
            return afDatabase;
        }
        
        #endregion
    }
}
