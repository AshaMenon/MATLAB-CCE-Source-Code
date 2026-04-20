using System;
using CCELetheTheoreticalRecovery;

namespace CCELetheTheoreticalRecoveryTest
{
    class Program
    {
        static int Main(string[] args)
        {
            // Fixed timestamps (Local) spaced by 60s
            DateTime t0 = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Local);
            DateTime t1 = t0.AddSeconds(60);
            DateTime t2 = t0.AddSeconds(120);

            var inputs = new Inputs
            {
                SHGrade = new double[] { 100.0, 0.0, 110.0 },       // second SH=0 -> expect NaN
                TailsGrade = new double[] { 10.0, double.NaN, 11.0 }, // second tails NaN -> NaN
                TonsMilled = new double[] { 1.0, 2.0, 3.0 },
                SHGradeTimestamps = new DateTime[] { t0, t1, t2 },
                TailsGradeTimestamps = new DateTime[] { t0, t1, t2 },
                TonsMilledTimestamps = new DateTime[] { t0, t1, t2 }
            };

            var @params = new Parameters
            {
                CalcLoopLimit = 0,
                CalcBackdays = 0,
                OutputNegTailsAcc = false,
                CalculationPeriodsToRun = -3,  // negative so startTime <= LastTime in this algo
                CalculationPeriod = 60,         // seconds between samples
                CalculateAtTime = 0,
                OutputTime = t2.ToString("yyyy-MM-dd HH:mm:ss"),
                CalculationPeriodOffset = 0
            };

            var calc = new CCELetheTheoreticalRecoveryClass
            {
                // Use a unique log name to avoid file name collisions with other processes
                LogName = $"Run_{DateTime.Now.Ticks}",
                CalculationID = "Test001",
                CalculationName = "TheoreticalRecoveryTest",
                // minimize logging to reduce background file activity during interactive runs
                LogLevel = 0
            };

            var outputs = calc.RunCalc(@params, inputs);

            // Debug: print input timestamps (ticks & kind)
            Console.WriteLine("Input timestamps:");
            for (int j = 0; j < inputs.SHGradeTimestamps.Length; j++)
            {
                var it = inputs.SHGradeTimestamps[j];
                Console.WriteLine($"  idx={j}  {it:u}  ticks={it.Ticks}  kind={it.Kind}");
            }
            Console.WriteLine();

            Console.WriteLine("Timestamps and TheoreticalRecovery (actual vs expected):\n");

            Console.WriteLine("Output details (one row per output timestamp):\n");
            Console.WriteLine("OutputTs (UTC) | Actual | Expected | Diff | SH (ts,kind,ticks) | Tails (ts,kind,ticks) | Tons (ts,kind,ticks)");
            Console.WriteLine(new string('-', 120));

            for (int i = 0; i < outputs.Timestamp.Length; i++)
            {
                DateTime ts = outputs.Timestamp[i];
                double actual = outputs.TheoreticalRecovery.Length > i ? outputs.TheoreticalRecovery[i] : double.NaN;

                // Find nearest matching index by timestamp tolerance (timestamps may be normalized internally)
                int idx = -1;
                for (int j = 0; j < inputs.SHGradeTimestamps.Length; j++)
                {
                    if (Math.Abs((inputs.SHGradeTimestamps[j] - ts).TotalSeconds) < 0.5)
                    {
                        idx = j;
                        break;
                    }
                }

                double expected = double.NaN;
                double shVal = double.NaN;
                double tailsVal = double.NaN;
                double tonsVal = double.NaN;
                DateTime? shTs = null, tailsTs = null, tonsTs = null;

                if (idx >= 0 && idx < inputs.SHGrade.Length)
                {
                    shVal = inputs.SHGrade[idx];
                    tailsVal = inputs.TailsGrade[idx];
                    tonsVal = inputs.TonsMilled[idx];
                    shTs = inputs.SHGradeTimestamps[idx];
                    tailsTs = inputs.TailsGradeTimestamps[idx];
                    tonsTs = inputs.TonsMilledTimestamps[idx];

                    if (!double.IsNaN(shVal) && shVal != 0 && !double.IsNaN(tailsVal))
                    {
                        expected = (shVal - tailsVal) / shVal * 100.0;
                    }
                }

                string aStr = double.IsNaN(actual) ? "NaN" : actual.ToString("F6");
                string eStr = double.IsNaN(expected) ? "NaN" : expected.ToString("F6");
                string diff = (double.IsNaN(actual) && double.IsNaN(expected)) ? "OK" : Math.Abs(actual - expected).ToString("F6");

                string shInfo = shTs.HasValue ? $"{shVal:F6} ({shTs.Value:u}, {shTs.Value.Kind}, {shTs.Value.Ticks})" : "missing";
                string tailsInfo = tailsTs.HasValue ? $"{tailsVal:F6} ({tailsTs.Value:u}, {tailsTs.Value.Kind}, {tailsTs.Value.Ticks})" : "missing";
                string tonsInfo = tonsTs.HasValue ? $"{tonsVal:F6} ({tonsTs.Value:u}, {tonsTs.Value.Kind}, {tonsTs.Value.Ticks})" : "missing";

                Console.WriteLine($"{ts:u} | {aStr} | {eStr} | {diff} | {shInfo} | {tailsInfo} | {tonsInfo}");
            }

            // Deterministic screenshot-based test (SH=2, Tails=0.42 at 2026-02-01 06:00:01 local)
            Console.WriteLine();
            Console.WriteLine("Running deterministic screenshot test (detailed output)...");

            DateTime sTs = DateTime.SpecifyKind(DateTime.Parse("2026-02-01 06:00:01"), DateTimeKind.Local);
            var inputs2 = new Inputs
            {
                SHGrade = new double[] { 2.0 },
                TailsGrade = new double[] { 0.42 },
                TonsMilled = new double[] { 28500.0 },
                SHGradeTimestamps = new DateTime[] { sTs },
                TailsGradeTimestamps = new DateTime[] { sTs },
                TonsMilledTimestamps = new DateTime[] { sTs }
            };

            var params2 = new Parameters
            {
                CalcLoopLimit = 0,
                CalcBackdays = 0,
                OutputNegTailsAcc = false,
                CalculationPeriodsToRun = -1,
                CalculationPeriod = 86400,
                CalculateAtTime = 21601,
                OutputTime = sTs.ToString("yyyy-MM-dd HH:mm:ss"),
                CalculationPeriodOffset = 0
            };

            var outputs2 = calc.RunCalc(params2, inputs2);

            // Print detailed output table for deterministic case
            Console.WriteLine();
            Console.WriteLine("Deterministic case: output details");
            Console.WriteLine("OutputTs (UTC) | Actual | Expected | Diff | SH (ts,kind,ticks) | Tails (ts,kind,ticks) | Tons (ts,kind,ticks)");
            Console.WriteLine(new string('-', 120));

            for (int i = 0; i < outputs2.Timestamp.Length; i++)
            {
                DateTime ts = outputs2.Timestamp[i];
                double actual = outputs2.TheoreticalRecovery.Length > i ? outputs2.TheoreticalRecovery[i] : double.NaN;

                // match input by tolerance (should match exactly)
                int idx = -1;
                for (int j = 0; j < inputs2.SHGradeTimestamps.Length; j++)
                {
                    if (Math.Abs((inputs2.SHGradeTimestamps[j] - ts).TotalSeconds) < 0.5)
                    {
                        idx = j; break;
                    }
                }

                double expected = double.NaN;
                string shInfo = "missing";
                string tailsInfo = "missing";
                string tonsInfo = "missing";

                if (idx >= 0)
                {
                    double shVal = inputs2.SHGrade[idx];
                    double tailsVal = inputs2.TailsGrade[idx];
                    double tonsVal = inputs2.TonsMilled[idx];
                    DateTime shTs = inputs2.SHGradeTimestamps[idx];
                    DateTime tailsTs = inputs2.TailsGradeTimestamps[idx];
                    DateTime tonsTs = inputs2.TonsMilledTimestamps[idx];

                    if (!double.IsNaN(shVal) && shVal != 0 && !double.IsNaN(tailsVal))
                        expected = (shVal - tailsVal) / shVal * 100.0;

                    shInfo = $"{shVal:F6} ({shTs:u}, {shTs.Kind}, {shTs.Ticks})";
                    tailsInfo = $"{tailsVal:F6} ({tailsTs:u}, {tailsTs.Kind}, {tailsTs.Ticks})";
                    tonsInfo = $"{tonsVal:F6} ({tonsTs:u}, {tonsTs.Kind}, {tonsTs.Ticks})";
                }

                string aStr = double.IsNaN(actual) ? "NaN" : actual.ToString("F6");
                string eStr = double.IsNaN(expected) ? "NaN" : expected.ToString("F6");
                string diff = (double.IsNaN(actual) && double.IsNaN(expected)) ? "OK" : Math.Abs(actual - expected).ToString("F6");

                Console.WriteLine($"{ts:u} | {aStr} | {eStr} | {diff} | {shInfo} | {tailsInfo} | {tonsInfo}");
            }

            // Summary pass/fail
            double actual2 = (outputs2.TheoreticalRecovery.Length > 0) ? outputs2.TheoreticalRecovery[0] : double.NaN;
            double expected2 = (2.0 - 0.42) / 2.0 * 100.0;

            if (double.IsNaN(actual2))
            {
                Console.WriteLine($"\nDeterministic test FAILED: actual is NaN (expected {expected2:F6})");
            }
            else if (Math.Abs(actual2 - expected2) < 1e-6)
            {
                Console.WriteLine($"\nDeterministic test PASSED: actual={actual2:F6} expected={expected2:F6}");
            }
            else
            {
                Console.WriteLine($"\nDeterministic test FAILED: actual={actual2:F6} expected={expected2:F6}");
            }

            // Interactive mode: allow the user to enter a single timestamp + SH/Tails/Tons and parameters
            Console.WriteLine();
            Console.Write("Enter 'i' to run interactive input, or press Enter to finish: ");
            string mode = Console.ReadLine();
            if (!string.IsNullOrEmpty(mode) && (mode.Equals("i", StringComparison.OrdinalIgnoreCase)))
            {
                Console.WriteLine("Interactive mode - provide values or press Enter to use defaults.");
                Console.Write("Timestamp (yyyy-MM-dd HH:mm:ss) [default: 2026-02-01 06:00:01]: ");
                string tsStr = Console.ReadLine();
                if (string.IsNullOrWhiteSpace(tsStr)) tsStr = "2026-02-01 06:00:01";

                DateTime iTs = DateTime.SpecifyKind(DateTime.Parse(tsStr), DateTimeKind.Local);

                double ReadDouble(string prompt, double defaultVal)
                {
                    Console.Write(prompt);
                    string s = Console.ReadLine();
                    if (string.IsNullOrWhiteSpace(s)) return defaultVal;
                    if (double.TryParse(s, out double v)) return v;
                    Console.WriteLine("Invalid number, using default.");
                    return defaultVal;
                }

                int ReadInt(string prompt, int defaultVal)
                {
                    Console.Write(prompt);
                    string s = Console.ReadLine();
                    if (string.IsNullOrWhiteSpace(s)) return defaultVal;
                    if (int.TryParse(s, out int v)) return v;
                    Console.WriteLine("Invalid int, using default.");
                    return defaultVal;
                }

                double shIn = ReadDouble("SH Grade [default 2.0]: ", 2.0);
                double tailsIn = ReadDouble("Tails Grade [default 0.42]: ", 0.42);
                double tonsIn = ReadDouble("Tons Milled [default 28500]: ", 28500.0);

                int calcPeriod = ReadInt("CalculationPeriod seconds [default 86400]: ", 86400);
                int calcAtTime = ReadInt("CalculateAtTime seconds [default 21601]: ", 21601);
                int periodsToRun = ReadInt("CalculationPeriodsToRun (negative for backward) [default -1]: ", -1);
                int periodOffset = ReadInt("CalculationPeriodOffset [default 0]: ", 0);

                var iInputs = new Inputs
                {
                    SHGrade = new double[] { shIn },
                    TailsGrade = new double[] { tailsIn },
                    TonsMilled = new double[] { tonsIn },
                    SHGradeTimestamps = new DateTime[] { iTs },
                    TailsGradeTimestamps = new DateTime[] { iTs },
                    TonsMilledTimestamps = new DateTime[] { iTs }
                };

                var iParams = new Parameters
                {
                    CalcLoopLimit = 0,
                    CalcBackdays = 0,
                    OutputNegTailsAcc = false,
                    CalculationPeriodsToRun = periodsToRun,
                    CalculationPeriod = calcPeriod,
                    CalculateAtTime = calcAtTime,
                    OutputTime = iTs.ToString("yyyy-MM-dd HH:mm:ss"),
                    CalculationPeriodOffset = periodOffset
                };

                // Use a unique log name for interactive runs and reduce logging level to avoid file-lock errors
                calc.LogName = $"Interactive_{DateTime.Now.Ticks}";
                calc.CalculationID = "Interactive";
                calc.CalculationName = "InteractiveRun";
                calc.LogLevel = 0;

                var outputs3 = calc.RunCalc(iParams, iInputs);

                Console.WriteLine();
                Console.WriteLine("Interactive case: output details");
                Console.WriteLine("OutputTs (UTC) | Actual | Expected | Diff | SH (ts,kind,ticks) | Tails (ts,kind,ticks) | Tons (ts,kind,ticks)");
                Console.WriteLine(new string('-', 120));

                for (int i = 0; i < outputs3.Timestamp.Length; i++)
                {
                    DateTime ts = outputs3.Timestamp[i];
                    double actual = outputs3.TheoreticalRecovery.Length > i ? outputs3.TheoreticalRecovery[i] : double.NaN;

                    int idx = -1; // only one input row so idx 0 if close
                    if (Math.Abs((iInputs.SHGradeTimestamps[0] - ts).TotalSeconds) < 0.5) idx = 0;

                    double expected = double.NaN;
                    string shInfo = "missing";
                    string tailsInfo = "missing";
                    string tonsInfo = "missing";

                    if (idx >= 0)
                    {
                        double shVal = iInputs.SHGrade[idx];
                        double tailsVal = iInputs.TailsGrade[idx];
                        double tonsVal = iInputs.TonsMilled[idx];
                        DateTime shTs = iInputs.SHGradeTimestamps[idx];
                        DateTime tailsTs = iInputs.TailsGradeTimestamps[idx];
                        DateTime tonsTs = iInputs.TonsMilledTimestamps[idx];

                        if (!double.IsNaN(shVal) && shVal != 0 && !double.IsNaN(tailsVal))
                            expected = (shVal - tailsVal) / shVal * 100.0;

                        shInfo = $"{shVal:F6} ({shTs:u}, {shTs.Kind}, {shTs.Ticks})";
                        tailsInfo = $"{tailsVal:F6} ({tailsTs:u}, {tailsTs.Kind}, {tailsTs.Ticks})";
                        tonsInfo = $"{tonsVal:F6} ({tonsTs:u}, {tonsTs.Kind}, {tonsTs.Ticks})";
                    }

                    string aStr = double.IsNaN(actual) ? "NaN" : actual.ToString("F6");
                    string eStr = double.IsNaN(expected) ? "NaN" : expected.ToString("F6");
                    string diff = (double.IsNaN(actual) && double.IsNaN(expected)) ? "OK" : Math.Abs(actual - expected).ToString("F6");

                    Console.WriteLine($"{ts:u} | {aStr} | {eStr} | {diff} | {shInfo} | {tailsInfo} | {tonsInfo}");
                }
            }

            Console.WriteLine("\nDone.");
            return 0;
        }
    }
}
