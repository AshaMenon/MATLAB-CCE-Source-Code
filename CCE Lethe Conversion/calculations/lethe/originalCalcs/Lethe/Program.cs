using SettingsReader.Readers;
using Topshelf;

namespace Amplats.AF.Lethe
{
    class Program
    {
        
        static void Main(string[] args)
        {

            var settings = new ConfigurationSectionReader().Read<AppSettings>("Lethe");

            HostFactory.Run(x =>
            {
                x.Service<CalculationService>(s =>
                {
                    s.ConstructUsing(name => new CalculationService(settings));
                    s.WhenStarted((CalculationService svc, HostControl hc) => svc.Start());
                    s.WhenStopped(tc => tc.Stop());
                });
                x.RunAsLocalSystem();
                x.SetDescription("Lethe AF calculation scheduler");
                x.SetDisplayName("Amplats Lethe");
                x.SetServiceName("Lethe");
                x.UseNLog();
                x.StartAutomaticallyDelayed();
            });      
        }
    }
}
