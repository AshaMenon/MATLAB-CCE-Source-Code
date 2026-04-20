function inputStruct = importfile1(workbookFile, sheetName, dataLines)
%IMPORTFILE1 Import data from a spreadsheet
%  [BUILDUPSOUNDINGPORT1TIMESTAMPS, BUILDUPSOUNDINGPORT1,
%  BUILDUPSOUNDINGPORT2TIMESTAMPS, BUILDUPSOUNDINGPORT2,
%  BUILDUPSOUNDINGPORT3TIMESTAMPS, BUILDUPSOUNDINGPORT3,
%  BUILDUPSOUNDINGPORT4TIMESTAMPS, BUILDUPSOUNDINGPORT4,
%  BUILDUPSOUNDINGPORT5TIMESTAMPS, BUILDUPSOUNDINGPORT5,
%  BUILDUPSOUNDINGPORT6TIMESTAMPS, BUILDUPSOUNDINGPORT6,
%  BUILDUPSOUNDINGPORT7TIMESTAMPS, BUILDUPSOUNDINGPORT7,
%  BUILDUPSOUNDINGPORT8TIMESTAMPS, BUILDUPSOUNDINGPORT8,
%  BUILDUPSOUNDINGPORT10TIMESTAMPS, BUILDUPSOUNDINGPORT10,
%  MATTESOUNDINGPORT1TIMESTAMPS, MATTESOUNDINGPORT1,
%  MATTESOUNDINGPORT2TIMESTAMPS, MATTESOUNDINGPORT2,
%  MATTESOUNDINGPORT3TIMESTAMPS, MATTESOUNDINGPORT3,
%  MATTESOUNDINGPORT4TIMESTAMPS, MATTESOUNDINGPORT4,
%  MATTESOUNDINGPORT5TIMESTAMPS, MATTESOUNDINGPORT5,
%  MATTESOUNDINGPORT6TIMESTAMPS, MATTESOUNDINGPORT6,
%  MATTESOUNDINGPORT7TIMESTAMPS, MATTESOUNDINGPORT7,
%  MATTESOUNDINGPORT8TIMESTAMPS, MATTESOUNDINGPORT8,
%  MATTESOUNDINGPORT10TIMESTAMPS, MATTESOUNDINGPORT10,
%  SLAGSOUNDINGPORT1TIMESTAMPS, SLAGSOUNDINGPORT1,
%  SLAGSOUNDINGPORT2TIMESTAMPS, SLAGSOUNDINGPORT2,
%  SLAGSOUNDINGPORT3TIMESTAMPS, SLAGSOUNDINGPORT3,
%  SLAGSOUNDINGPORT4TIMESTAMPS, SLAGSOUNDINGPORT4,
%  SLAGSOUNDINGPORT5TIMESTAMPS, SLAGSOUNDINGPORT5,
%  SLAGSOUNDINGPORT6TIMESTAMPS, SLAGSOUNDINGPORT6,
%  SLAGSOUNDINGPORT7TIMESTAMPS, SLAGSOUNDINGPORT7,
%  SLAGSOUNDINGPORT8TIMESTAMPS, SLAGSOUNDINGPORT8,
%  SLAGSOUNDINGPORT10TIMESTAMPS, SLAGSOUNDINGPORT10,
%  CONCENTRATESOUNDINGPORT1TIMESTAMPS, CONCENTRATESOUNDINGPORT1,
%  CONCENTRATESOUNDINGPORT2TIMESTAMPS, CONCENTRATESOUNDINGPORT2,
%  CONCENTRATESOUNDINGPORT3TIMESTAMPS, CONCENTRATESOUNDINGPORT3,
%  CONCENTRATESOUNDINGPORT4TIMESTAMPS, CONCENTRATESOUNDINGPORT4,
%  CONCENTRATESOUNDINGPORT5TIMESTAMPS, CONCENTRATESOUNDINGPORT5,
%  CONCENTRATESOUNDINGPORT6TIMESTAMPS, CONCENTRATESOUNDINGPORT6,
%  CONCENTRATESOUNDINGPORT7TIMESTAMPS, CONCENTRATESOUNDINGPORT7,
%  CONCENTRATESOUNDINGPORT8TIMESTAMPS, CONCENTRATESOUNDINGPORT8,
%  CONCENTRATESOUNDINGPORT10TIMESTAMPS, CONCENTRATESOUNDINGPORT10] =
%  IMPORTFILE1(FILE) reads data from the first worksheet in the
%  Microsoft Excel spreadsheet file named FILE.  Returns the data as
%  column vectors.
%
%  [BUILDUPSOUNDINGPORT1TIMESTAMPS, BUILDUPSOUNDINGPORT1,
%  BUILDUPSOUNDINGPORT2TIMESTAMPS, BUILDUPSOUNDINGPORT2,
%  BUILDUPSOUNDINGPORT3TIMESTAMPS, BUILDUPSOUNDINGPORT3,
%  BUILDUPSOUNDINGPORT4TIMESTAMPS, BUILDUPSOUNDINGPORT4,
%  BUILDUPSOUNDINGPORT5TIMESTAMPS, BUILDUPSOUNDINGPORT5,
%  BUILDUPSOUNDINGPORT6TIMESTAMPS, BUILDUPSOUNDINGPORT6,
%  BUILDUPSOUNDINGPORT7TIMESTAMPS, BUILDUPSOUNDINGPORT7,
%  BUILDUPSOUNDINGPORT8TIMESTAMPS, BUILDUPSOUNDINGPORT8,
%  BUILDUPSOUNDINGPORT10TIMESTAMPS, BUILDUPSOUNDINGPORT10,
%  MATTESOUNDINGPORT1TIMESTAMPS, MATTESOUNDINGPORT1,
%  MATTESOUNDINGPORT2TIMESTAMPS, MATTESOUNDINGPORT2,
%  MATTESOUNDINGPORT3TIMESTAMPS, MATTESOUNDINGPORT3,
%  MATTESOUNDINGPORT4TIMESTAMPS, MATTESOUNDINGPORT4,
%  MATTESOUNDINGPORT5TIMESTAMPS, MATTESOUNDINGPORT5,
%  MATTESOUNDINGPORT6TIMESTAMPS, MATTESOUNDINGPORT6,
%  MATTESOUNDINGPORT7TIMESTAMPS, MATTESOUNDINGPORT7,
%  MATTESOUNDINGPORT8TIMESTAMPS, MATTESOUNDINGPORT8,
%  MATTESOUNDINGPORT10TIMESTAMPS, MATTESOUNDINGPORT10,
%  SLAGSOUNDINGPORT1TIMESTAMPS, SLAGSOUNDINGPORT1,
%  SLAGSOUNDINGPORT2TIMESTAMPS, SLAGSOUNDINGPORT2,
%  SLAGSOUNDINGPORT3TIMESTAMPS, SLAGSOUNDINGPORT3,
%  SLAGSOUNDINGPORT4TIMESTAMPS, SLAGSOUNDINGPORT4,
%  SLAGSOUNDINGPORT5TIMESTAMPS, SLAGSOUNDINGPORT5,
%  SLAGSOUNDINGPORT6TIMESTAMPS, SLAGSOUNDINGPORT6,
%  SLAGSOUNDINGPORT7TIMESTAMPS, SLAGSOUNDINGPORT7,
%  SLAGSOUNDINGPORT8TIMESTAMPS, SLAGSOUNDINGPORT8,
%  SLAGSOUNDINGPORT10TIMESTAMPS, SLAGSOUNDINGPORT10,
%  CONCENTRATESOUNDINGPORT1TIMESTAMPS, CONCENTRATESOUNDINGPORT1,
%  CONCENTRATESOUNDINGPORT2TIMESTAMPS, CONCENTRATESOUNDINGPORT2,
%  CONCENTRATESOUNDINGPORT3TIMESTAMPS, CONCENTRATESOUNDINGPORT3,
%  CONCENTRATESOUNDINGPORT4TIMESTAMPS, CONCENTRATESOUNDINGPORT4,
%  CONCENTRATESOUNDINGPORT5TIMESTAMPS, CONCENTRATESOUNDINGPORT5,
%  CONCENTRATESOUNDINGPORT6TIMESTAMPS, CONCENTRATESOUNDINGPORT6,
%  CONCENTRATESOUNDINGPORT7TIMESTAMPS, CONCENTRATESOUNDINGPORT7,
%  CONCENTRATESOUNDINGPORT8TIMESTAMPS, CONCENTRATESOUNDINGPORT8,
%  CONCENTRATESOUNDINGPORT10TIMESTAMPS, CONCENTRATESOUNDINGPORT10] =
%  IMPORTFILE1(FILE, SHEET) reads from the specified worksheet.
%
%  [BUILDUPSOUNDINGPORT1TIMESTAMPS, BUILDUPSOUNDINGPORT1,
%  BUILDUPSOUNDINGPORT2TIMESTAMPS, BUILDUPSOUNDINGPORT2,
%  BUILDUPSOUNDINGPORT3TIMESTAMPS, BUILDUPSOUNDINGPORT3,
%  BUILDUPSOUNDINGPORT4TIMESTAMPS, BUILDUPSOUNDINGPORT4,
%  BUILDUPSOUNDINGPORT5TIMESTAMPS, BUILDUPSOUNDINGPORT5,
%  BUILDUPSOUNDINGPORT6TIMESTAMPS, BUILDUPSOUNDINGPORT6,
%  BUILDUPSOUNDINGPORT7TIMESTAMPS, BUILDUPSOUNDINGPORT7,
%  BUILDUPSOUNDINGPORT8TIMESTAMPS, BUILDUPSOUNDINGPORT8,
%  BUILDUPSOUNDINGPORT10TIMESTAMPS, BUILDUPSOUNDINGPORT10,
%  MATTESOUNDINGPORT1TIMESTAMPS, MATTESOUNDINGPORT1,
%  MATTESOUNDINGPORT2TIMESTAMPS, MATTESOUNDINGPORT2,
%  MATTESOUNDINGPORT3TIMESTAMPS, MATTESOUNDINGPORT3,
%  MATTESOUNDINGPORT4TIMESTAMPS, MATTESOUNDINGPORT4,
%  MATTESOUNDINGPORT5TIMESTAMPS, MATTESOUNDINGPORT5,
%  MATTESOUNDINGPORT6TIMESTAMPS, MATTESOUNDINGPORT6,
%  MATTESOUNDINGPORT7TIMESTAMPS, MATTESOUNDINGPORT7,
%  MATTESOUNDINGPORT8TIMESTAMPS, MATTESOUNDINGPORT8,
%  MATTESOUNDINGPORT10TIMESTAMPS, MATTESOUNDINGPORT10,
%  SLAGSOUNDINGPORT1TIMESTAMPS, SLAGSOUNDINGPORT1,
%  SLAGSOUNDINGPORT2TIMESTAMPS, SLAGSOUNDINGPORT2,
%  SLAGSOUNDINGPORT3TIMESTAMPS, SLAGSOUNDINGPORT3,
%  SLAGSOUNDINGPORT4TIMESTAMPS, SLAGSOUNDINGPORT4,
%  SLAGSOUNDINGPORT5TIMESTAMPS, SLAGSOUNDINGPORT5,
%  SLAGSOUNDINGPORT6TIMESTAMPS, SLAGSOUNDINGPORT6,
%  SLAGSOUNDINGPORT7TIMESTAMPS, SLAGSOUNDINGPORT7,
%  SLAGSOUNDINGPORT8TIMESTAMPS, SLAGSOUNDINGPORT8,
%  SLAGSOUNDINGPORT10TIMESTAMPS, SLAGSOUNDINGPORT10,
%  CONCENTRATESOUNDINGPORT1TIMESTAMPS, CONCENTRATESOUNDINGPORT1,
%  CONCENTRATESOUNDINGPORT2TIMESTAMPS, CONCENTRATESOUNDINGPORT2,
%  CONCENTRATESOUNDINGPORT3TIMESTAMPS, CONCENTRATESOUNDINGPORT3,
%  CONCENTRATESOUNDINGPORT4TIMESTAMPS, CONCENTRATESOUNDINGPORT4,
%  CONCENTRATESOUNDINGPORT5TIMESTAMPS, CONCENTRATESOUNDINGPORT5,
%  CONCENTRATESOUNDINGPORT6TIMESTAMPS, CONCENTRATESOUNDINGPORT6,
%  CONCENTRATESOUNDINGPORT7TIMESTAMPS, CONCENTRATESOUNDINGPORT7,
%  CONCENTRATESOUNDINGPORT8TIMESTAMPS, CONCENTRATESOUNDINGPORT8,
%  CONCENTRATESOUNDINGPORT10TIMESTAMPS, CONCENTRATESOUNDINGPORT10] =
%  IMPORTFILE1(FILE, SHEET, DATALINES) reads from the specified
%  worksheet for the specified row interval(s). Specify DATALINES as a
%  positive scalar integer or a N-by-2 array of positive scalar integers
%  for dis-contiguous row intervals.
%
%  Example:
%  inputStruct = importfile1("D:\eunice\Projects\Amplats\SILFurnaceModelling\data\Compressed_Soundings_20241125_2024Aug.xlsx", "Sheet1", [2, Inf]);
%
%  See also READTABLE.
%
% Auto-generated by MATLAB on 03-Dec-2024 07:51:33

%% Input handling

% If no sheet is specified, read from Sheet1
if nargin == 1 || isempty(sheetName)
    sheetName = "Sheet1";
end

% If row start and end points are not specified, define defaults
if nargin <= 2
    dataLines = [2, Inf];
end

%% Set up the Import Options and import the data
opts = spreadsheetImportOptions("NumVariables", 72);

% Specify sheet and range
opts.Sheet = sheetName;
opts.DataRange = dataLines(1, :);

% Specify column names and types
opts.VariableNames = ["BuildUpSoundingPort1Timestamps", "BuildUpSoundingPort1", "BuildUpSoundingPort2Timestamps", "BuildUpSoundingPort2", "BuildUpSoundingPort3Timestamps", "BuildUpSoundingPort3", "BuildUpSoundingPort4Timestamps", "BuildUpSoundingPort4", "BuildUpSoundingPort5Timestamps", "BuildUpSoundingPort5", "BuildUpSoundingPort6Timestamps", "BuildUpSoundingPort6", "BuildUpSoundingPort7Timestamps", "BuildUpSoundingPort7", "BuildUpSoundingPort8Timestamps", "BuildUpSoundingPort8", "BuildUpSoundingPort10Timestamps", "BuildUpSoundingPort10", "MatteSoundingPort1Timestamps", "MatteSoundingPort1", "MatteSoundingPort2Timestamps", "MatteSoundingPort2", "MatteSoundingPort3Timestamps", "MatteSoundingPort3", "MatteSoundingPort4Timestamps", "MatteSoundingPort4", "MatteSoundingPort5Timestamps", "MatteSoundingPort5", "MatteSoundingPort6Timestamps", "MatteSoundingPort6", "MatteSoundingPort7Timestamps", "MatteSoundingPort7", "MatteSoundingPort8Timestamps", "MatteSoundingPort8", "MatteSoundingPort10Timestamps", "MatteSoundingPort10", "SlagSoundingPort1Timestamps", "SlagSoundingPort1", "SlagSoundingPort2Timestamps", "SlagSoundingPort2", "SlagSoundingPort3Timestamps", "SlagSoundingPort3", "SlagSoundingPort4Timestamps", "SlagSoundingPort4", "SlagSoundingPort5Timestamps", "SlagSoundingPort5", "SlagSoundingPort6Timestamps", "SlagSoundingPort6", "SlagSoundingPort7Timestamps", "SlagSoundingPort7", "SlagSoundingPort8Timestamps", "SlagSoundingPort8", "SlagSoundingPort10Timestamps", "SlagSoundingPort10", "ConcentrateSoundingPort1Timestamps", "ConcentrateSoundingPort1", "ConcentrateSoundingPort2Timestamps", "ConcentrateSoundingPort2", "ConcentrateSoundingPort3Timestamps", "ConcentrateSoundingPort3", "ConcentrateSoundingPort4Timestamps", "ConcentrateSoundingPort4", "ConcentrateSoundingPort5Timestamps", "ConcentrateSoundingPort5", "ConcentrateSoundingPort6Timestamps", "ConcentrateSoundingPort6", "ConcentrateSoundingPort7Timestamps", "ConcentrateSoundingPort7", "ConcentrateSoundingPort8Timestamps", "ConcentrateSoundingPort8", "ConcentrateSoundingPort10Timestamps", "ConcentrateSoundingPort10"];
opts.VariableTypes = ["datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double", "datetime", "double"];

% Import the data
tbl = readtable(workbookFile, opts, "UseExcel", false);

for idx = 2:size(dataLines, 1)
    opts.DataRange = dataLines(idx, :);
    tb = readtable(workbookFile, opts, "UseExcel", false);
    tbl = [tbl; tb]; %#ok<AGROW>
end

%% Convert to output type
inputStruct = struct();
inputStruct.BuildUpSoundingPort1Timestamps = tbl.BuildUpSoundingPort1Timestamps;
inputStruct.BuildUpSoundingPort1 = tbl.BuildUpSoundingPort1;
inputStruct.BuildUpSoundingPort2Timestamps = tbl.BuildUpSoundingPort2Timestamps;
inputStruct.BuildUpSoundingPort2 = tbl.BuildUpSoundingPort2;
inputStruct.BuildUpSoundingPort3Timestamps = tbl.BuildUpSoundingPort3Timestamps;
inputStruct.BuildUpSoundingPort3 = tbl.BuildUpSoundingPort3;
inputStruct.BuildUpSoundingPort4Timestamps = tbl.BuildUpSoundingPort4Timestamps;
inputStruct.BuildUpSoundingPort4 = tbl.BuildUpSoundingPort4;
inputStruct.BuildUpSoundingPort5Timestamps = tbl.BuildUpSoundingPort5Timestamps;
inputStruct.BuildUpSoundingPort5 = tbl.BuildUpSoundingPort5;
inputStruct.BuildUpSoundingPort6Timestamps = tbl.BuildUpSoundingPort6Timestamps;
inputStruct.BuildUpSoundingPort6 = tbl.BuildUpSoundingPort6;
inputStruct.BuildUpSoundingPort7Timestamps = tbl.BuildUpSoundingPort7Timestamps;
inputStruct.BuildUpSoundingPort7 = tbl.BuildUpSoundingPort7;
inputStruct.BuildUpSoundingPort8Timestamps = tbl.BuildUpSoundingPort8Timestamps;
inputStruct.BuildUpSoundingPort8 = tbl.BuildUpSoundingPort8;
inputStruct.BuildUpSoundingPort10Timestamps = tbl.BuildUpSoundingPort10Timestamps;
inputStruct.BuildUpSoundingPort10 = tbl.BuildUpSoundingPort10;
inputStruct.MatteSoundingPort1Timestamps = tbl.MatteSoundingPort1Timestamps;
inputStruct.MatteSoundingPort1 = tbl.MatteSoundingPort1;
inputStruct.MatteSoundingPort2Timestamps = tbl.MatteSoundingPort2Timestamps;
inputStruct.MatteSoundingPort2 = tbl.MatteSoundingPort2;
inputStruct.MatteSoundingPort3Timestamps = tbl.MatteSoundingPort3Timestamps;
inputStruct.MatteSoundingPort3 = tbl.MatteSoundingPort3;
inputStruct.MatteSoundingPort4Timestamps = tbl.MatteSoundingPort4Timestamps;
inputStruct.MatteSoundingPort4 = tbl.MatteSoundingPort4;
inputStruct.MatteSoundingPort5Timestamps = tbl.MatteSoundingPort5Timestamps;
inputStruct.MatteSoundingPort5 = tbl.MatteSoundingPort5;
inputStruct.MatteSoundingPort6Timestamps = tbl.MatteSoundingPort6Timestamps;
inputStruct.MatteSoundingPort6 = tbl.MatteSoundingPort6;
inputStruct.MatteSoundingPort7Timestamps = tbl.MatteSoundingPort7Timestamps;
inputStruct.MatteSoundingPort7 = tbl.MatteSoundingPort7;
inputStruct.MatteSoundingPort8Timestamps = tbl.MatteSoundingPort8Timestamps;
inputStruct.MatteSoundingPort8 = tbl.MatteSoundingPort8;
inputStruct.MatteSoundingPort10Timestamps = tbl.MatteSoundingPort10Timestamps;
inputStruct.MatteSoundingPort10 = tbl.MatteSoundingPort10;
inputStruct.SlagSoundingPort1Timestamps = tbl.SlagSoundingPort1Timestamps;
inputStruct.SlagSoundingPort1 = tbl.SlagSoundingPort1;
inputStruct.SlagSoundingPort2Timestamps = tbl.SlagSoundingPort2Timestamps;
inputStruct.SlagSoundingPort2 = tbl.SlagSoundingPort2;
inputStruct.SlagSoundingPort3Timestamps = tbl.SlagSoundingPort3Timestamps;
inputStruct.SlagSoundingPort3 = tbl.SlagSoundingPort3;
inputStruct.SlagSoundingPort4Timestamps = tbl.SlagSoundingPort4Timestamps;
inputStruct.SlagSoundingPort4 = tbl.SlagSoundingPort4;
inputStruct.SlagSoundingPort5Timestamps = tbl.SlagSoundingPort5Timestamps;
inputStruct.SlagSoundingPort5 = tbl.SlagSoundingPort5;
inputStruct.SlagSoundingPort6Timestamps = tbl.SlagSoundingPort6Timestamps;
inputStruct.SlagSoundingPort6 = tbl.SlagSoundingPort6;
inputStruct.SlagSoundingPort7Timestamps = tbl.SlagSoundingPort7Timestamps;
inputStruct.SlagSoundingPort7 = tbl.SlagSoundingPort7;
inputStruct.SlagSoundingPort8Timestamps = tbl.SlagSoundingPort8Timestamps;
inputStruct.SlagSoundingPort8 = tbl.SlagSoundingPort8;
inputStruct.SlagSoundingPort10Timestamps = tbl.SlagSoundingPort10Timestamps;
inputStruct.SlagSoundingPort10 = tbl.SlagSoundingPort10;
inputStruct.ConcentrateSoundingPort1Timestamps = tbl.ConcentrateSoundingPort1Timestamps;
inputStruct.ConcentrateSoundingPort1 = tbl.ConcentrateSoundingPort1;
inputStruct.ConcentrateSoundingPort2Timestamps = tbl.ConcentrateSoundingPort2Timestamps;
inputStruct.ConcentrateSoundingPort2 = tbl.ConcentrateSoundingPort2;
inputStruct.ConcentrateSoundingPort3Timestamps = tbl.ConcentrateSoundingPort3Timestamps;
inputStruct.ConcentrateSoundingPort3 = tbl.ConcentrateSoundingPort3;
inputStruct.ConcentrateSoundingPort4Timestamps = tbl.ConcentrateSoundingPort4Timestamps;
inputStruct.ConcentrateSoundingPort4 = tbl.ConcentrateSoundingPort4;
inputStruct.ConcentrateSoundingPort5Timestamps = tbl.ConcentrateSoundingPort5Timestamps;
inputStruct.ConcentrateSoundingPort5 = tbl.ConcentrateSoundingPort5;
inputStruct.ConcentrateSoundingPort6Timestamps = tbl.ConcentrateSoundingPort6Timestamps;
inputStruct.ConcentrateSoundingPort6 = tbl.ConcentrateSoundingPort6;
inputStruct.ConcentrateSoundingPort7Timestamps = tbl.ConcentrateSoundingPort7Timestamps;
inputStruct.ConcentrateSoundingPort7 = tbl.ConcentrateSoundingPort7;
inputStruct.ConcentrateSoundingPort8Timestamps = tbl.ConcentrateSoundingPort8Timestamps;
inputStruct.ConcentrateSoundingPort8 = tbl.ConcentrateSoundingPort8;
inputStruct.ConcentrateSoundingPort10Timestamps = tbl.ConcentrateSoundingPort10Timestamps;
inputStruct.ConcentrateSoundingPort10 = tbl.ConcentrateSoundingPort10;
end