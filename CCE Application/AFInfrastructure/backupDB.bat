REM Script to backup the 3 PI AF test databases used for CCECalculation development
@ECHO OFF

SET exeName="C:\Program Files\PIPC\AF\AFExport.exe"
SET dataFolder = %cd%

set day=%Date:~8,2%
set mth=%Date:~5,2%
set yr=%Date:~0,4%
set theDate=%day%-%mth%-%yr%

REM Backup full CCETest DB
start "CCETest DB" %exeName% "\\.\CCETest" /file:CCETest\CCETestDB_Export_%theDate%.xml

REM Backup full CCEProd DB
start "CCEProd DB" %exeName% "\\.\CCEProd" /file:CCEProd\CCEProdDB_Export_%theDate%.xml

REM Backup WACP Coordinator Template, Calculation Templats and Calculation Elements
REM including referenced items. 
start "WACP_Coordinator" %exeName% "\\.\WACP\ElementTemplates[CCECoordinator]" ^
/file:WACP\WACP_Coordinator_Export_%theDate%.xml /A
start "WACP_CalcTemplate" %exeName% "\\.\WACP\ElementTemplates[CCECalculation]" ^
/file:WACP\WACP_CalcTemplate_Export_%theDate%.xml /A
start "WACP_Elements" %exeName% "\\.\WACP\CCETest" ^
/file:WACP\WACP_Elements_Export_%theDate%.xml /A