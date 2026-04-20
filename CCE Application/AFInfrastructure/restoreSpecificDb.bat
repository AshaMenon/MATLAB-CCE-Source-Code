REM Script to restore a specific database from an xml file
@ECHO OFF

REM Set folder name, and database to be backed up
REM this is the database that the restore will occur in
SET db=testDevRyan
SET dataFolder=Database backups
SET fileName=CCETestDBBackup

SET exeName="C:\Program Files\PIPC\AF\AFImport.exe"

REM Restore full backup
start "Restoring" %exeName% "\\.\%db%" /File:"%dataFolder%\%fileName%.xml" /P
pause