using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using CCELetheTheoreticalRecovery;

namespace CCELetheTheoreticalRecovery.Tests
{
    [TestClass]
    public class CCELetheTheoreticalRecoveryTests
    {
        [TestMethod]
        public void Deterministic_ScreenshotCase_Returns79Percent()
        {
            // Arrange: timestamp and inputs match screenshot (local)
            DateTime sTs = DateTime.SpecifyKind(DateTime.Parse("2026-02-01 06:00:01"), DateTimeKind.Local);

            var inputs = new Inputs
            {
                SHGrade = new double[] { 2.0 },
                TailsGrade = new double[] { 0.42 },
                TonsMilled = new double[] { 28500.0 },
                SHGradeTimestamps = new DateTime[] { sTs },
                TailsGradeTimestamps = new DateTime[] { sTs },
                TonsMilledTimestamps = new DateTime[] { sTs }
            };

            var @params = new Parameters
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

            var calc = new CCELetheTheoreticalRecoveryClass();
            // Provide required logging properties used by the calculation's Logger constructor
            calc.LogName = "UnitTestLog";
            calc.CalculationID = "UT001";
            calc.CalculationName = "TheoreticalRecoveryUnitTest";
            calc.LogLevel = 2;

            // Act
            var outputs = calc.RunCalc(@params, inputs);

            // Assert
            Assert.IsNotNull(outputs.TheoreticalRecovery);
            Assert.IsTrue(outputs.TheoreticalRecovery.Length > 0);
            double actual = outputs.TheoreticalRecovery[0];
            double expected = (2.0 - 0.42) / 2.0 * 100.0;

            Assert.AreEqual(expected, actual, 1e-6, "Theoretical recovery should match expected value (79%)");
        }
    }
}