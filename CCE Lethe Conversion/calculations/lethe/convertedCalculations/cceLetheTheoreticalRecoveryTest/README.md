# cceLetheTheoreticalRecovery Test Harness

Quick test harness to run `CCELetheTheoreticalRecoveryClass` with dummy inputs.

How to run

- Build & run with `dotnet` (requires .NET SDK and .NET Framework 4.8 targeting pack installed):
  - Open a Developer PowerShell in this folder and run: `dotnet run` (it will build the test project and project reference)

- Or open the solution/project in Visual Studio and press F5 / Run.

What it does

- Constructs three timestamps 60s apart and provides SHGrade/TailsGrade arrays including edge cases (zero, NaN).
- Runs `RunCalc` and prints actual vs expected theoretical recovery for each timestamp.

Notes

- If build fails due to missing references (e.g., SharedLogger/CCELogger), build the `CCELetheTheoreticalRecovery` project first (open its project and build in Visual Studio) so the referenced DLLs are available to the test project.
