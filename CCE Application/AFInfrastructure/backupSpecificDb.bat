REM Script to backup a specific database in a specific folder. 
@ECHO OFF

REM Set folder name, and database to be backed up
SET db=CCETest
SET dataFolder=Database backups
SET fileName=CCETestDBBackup

REM Create output folder if needed. 
if not exist "%dataFolder%" mkdir "%dataFolder%"

REM Backup full DB
SET exeName="C:\Program Files\PIPC\AF\AFExport.exe"
start "Backing up" %exeName% "\\.\%db%" /file:"%dataFolder%\%fileName%.xml" /U
pause