% Extract each sounding port and put into smaller timetables 
%Sort each row to ascend
CompressedBuildUpMatrix = CompressedSoundings(1:end,1:18);

%Port1 
CompBuildSoundingPort1 = sortrows(table2timetable(CompressedBuildUpMatrix(1:end,1:2)));
CompBuildSoundingPort1=CompBuildSoundingPort1(~any(ismissing(CompBuildSoundingPort1),2),:);


%Port 2
CompBuildSoundingPort2 = sortrows(table2timetable(CompressedBuildUpMatrix(1:end,3:4)));
CompBuildSoundingPort2 = CompBuildSoundingPort2(~any(ismissing(CompBuildSoundingPort2),2),:);



CompBuildSoundingPort3 = sortrows(table2timetable(CompressedBuildUpMatrix(1:end,5:6)));
CompBuildSoundingPort3 = CompBuildSoundingPort3(~any(ismissing(CompBuildSoundingPort3),2),:);



CompBuildSoundingPort4 = sortrows(table2timetable(CompressedBuildUpMatrix(1:end,7:8)));
CompBuildSoundingPort4 =CompBuildSoundingPort4(~any(ismissing(CompBuildSoundingPort4),2),:);



CompBuildSoundingPort5 = sortrows(table2timetable(CompressedBuildUpMatrix(1:end,9:10)));
CompBuildSoundingPort5 =CompBuildSoundingPort5(~any(ismissing(CompBuildSoundingPort5),2),:);


CompBuildSoundingPort6 = sortrows(table2timetable(CompressedBuildUpMatrix(1:end,11:12)));
CompBuildSoundingPort6 =CompBuildSoundingPort6(~any(ismissing(CompBuildSoundingPort6),2),:);


CompBuildSoundingPort7 = sortrows(table2timetable(CompressedBuildUpMatrix(1:end,13:14)));
CompBuildSoundingPort7 =CompBuildSoundingPort7(~any(ismissing(CompBuildSoundingPort7),2),:);


CompBuildSoundingPort8 = sortrows(table2timetable(CompressedBuildUpMatrix(1:end,15:16)));
CompBuildSoundingPort8 =CompBuildSoundingPort8(~any(ismissing(CompBuildSoundingPort8),2),:);


CompBuildSoundingPort10 = sortrows(table2timetable(CompressedBuildUpMatrix(1:end,17:18)));
CompBuildSoundingPort10 = CompBuildSoundingPort10(~any(ismissing(CompBuildSoundingPort10),2),:);

% Add all sounding port data together

TimetableCompMatrixBuildUp = synchronize(CompBuildSoundingPort1,CompBuildSoundingPort2,CompBuildSoundingPort3,CompBuildSoundingPort4,CompBuildSoundingPort5,CompBuildSoundingPort6,CompBuildSoundingPort7,CompBuildSoundingPort8,CompBuildSoundingPort10);
% Reformat the time to minutly data
TimetableCompMatrixBuildUp.VarName1.Format = "dd-MMM-uuuu HH:mm";

%% Matte
% Repeat above for Matte, Slag and Conc
CompressedMatteMatrix = CompressedSoundings(1:end,19:36);

CompMatteSoundingPort1 = sortrows(table2timetable(CompressedMatteMatrix(1:end,1:2)));
CompMatteSoundingPort1=CompMatteSoundingPort1(~any(ismissing(CompMatteSoundingPort1),2),:);


CompMatteSoundingPort2 = sortrows(table2timetable(CompressedMatteMatrix(1:end,3:4)));
CompMatteSoundingPort2 = CompMatteSoundingPort2(~any(ismissing(CompMatteSoundingPort2),2),:);

CompMatteSoundingPort3 = sortrows(table2timetable(CompressedMatteMatrix(1:end,5:6)));
CompMatteSoundingPort3 = CompMatteSoundingPort3(~any(ismissing(CompMatteSoundingPort3),2),:);

CompMatteSoundingPort4 = sortrows(table2timetable(CompressedMatteMatrix(1:end,7:8)));
CompMatteSoundingPort4 =CompMatteSoundingPort4(~any(ismissing(CompMatteSoundingPort4),2),:);

CompMatteSoundingPort5 = sortrows(table2timetable(CompressedMatteMatrix(1:end,9:10)));
CompMatteSoundingPort5 =CompMatteSoundingPort5(~any(ismissing(CompMatteSoundingPort5),2),:);

CompMatteSoundingPort6 = sortrows(table2timetable(CompressedMatteMatrix(1:end,11:12)));
CompMatteSoundingPort6 =CompMatteSoundingPort6(~any(ismissing(CompMatteSoundingPort6),2),:);

CompMatteSoundingPort7 = sortrows(table2timetable(CompressedMatteMatrix(1:end,13:14)));
CompMatteSoundingPort7 =CompMatteSoundingPort7(~any(ismissing(CompMatteSoundingPort7),2),:);

CompMatteSoundingPort8 = sortrows(table2timetable(CompressedMatteMatrix(1:end,15:16)));
CompMatteSoundingPort8 =CompMatteSoundingPort8(~any(ismissing(CompMatteSoundingPort8),2),:);

CompMatteSoundingPort10 = sortrows(table2timetable(CompressedMatteMatrix(1:end,17:18)));
CompMatteSoundingPort10 = CompMatteSoundingPort10(~any(ismissing(CompMatteSoundingPort10),2),:);


TimetableMatteCompMatrix = synchronize(CompMatteSoundingPort1,CompMatteSoundingPort2,CompMatteSoundingPort3,CompMatteSoundingPort4,CompMatteSoundingPort5,CompMatteSoundingPort6,CompMatteSoundingPort7,CompMatteSoundingPort8,CompMatteSoundingPort10);
TimetableMatteCompMatrix.VarName19.Format = "dd-MMM-uuuu HH:mm";

TableMatteCompMatrix = timetable2table(TimetableMatteCompMatrix);




%% Conc
CompressedConcMatrix = CompressedSoundings(1:end,55:72);

CompConcSoundingPort1 = sortrows(table2timetable(CompressedConcMatrix(1:end,1:2)));
CompConcSoundingPort1=CompConcSoundingPort1(~any(ismissing(CompConcSoundingPort1),2),:);


CompConcSoundingPort2 = sortrows(table2timetable(CompressedConcMatrix(1:end,3:4)));
CompConcSoundingPort2 = CompConcSoundingPort2(~any(ismissing(CompConcSoundingPort2),2),:);

CompConcSoundingPort3 = sortrows(table2timetable(CompressedConcMatrix(1:end,5:6)));
CompConcSoundingPort3 = CompConcSoundingPort3(~any(ismissing(CompConcSoundingPort3),2),:);

CompConcSoundingPort4 = sortrows(table2timetable(CompressedConcMatrix(1:end,7:8)));
CompConcSoundingPort4 =CompConcSoundingPort4(~any(ismissing(CompConcSoundingPort4),2),:);

CompConcSoundingPort5 = sortrows(table2timetable(CompressedConcMatrix(1:end,9:10)));
CompConcSoundingPort5 =CompConcSoundingPort5(~any(ismissing(CompConcSoundingPort5),2),:);

CompConcSoundingPort6 = sortrows(table2timetable(CompressedConcMatrix(1:end,11:12)));
CompConcSoundingPort6 =CompConcSoundingPort6(~any(ismissing(CompConcSoundingPort6),2),:);

CompConcSoundingPort7 = sortrows(table2timetable(CompressedConcMatrix(1:end,13:14)));
CompConcSoundingPort7 =CompConcSoundingPort7(~any(ismissing(CompConcSoundingPort7),2),:);

CompConcSoundingPort8 = sortrows(table2timetable(CompressedConcMatrix(1:end,15:16)));
CompConcSoundingPort8 =CompConcSoundingPort8(~any(ismissing(CompConcSoundingPort8),2),:);

CompConcSoundingPort10 = sortrows(table2timetable(CompressedConcMatrix(1:end,17:18)));
CompConcSoundingPort10 = CompConcSoundingPort10(~any(ismissing(CompConcSoundingPort10),2),:);


TimetableConcCompMatrix = synchronize(CompConcSoundingPort1,CompConcSoundingPort2,CompConcSoundingPort3,CompConcSoundingPort4,CompConcSoundingPort5,CompConcSoundingPort6,CompConcSoundingPort7,CompConcSoundingPort8,CompConcSoundingPort10);
TimetableConcCompMatrix.VarName55.Format = "dd-MMM-uuuu HH:mm";

%% Slag

CompressedSlagMatrix = CompressedSoundings(1:end,37:54);

CompSlagSoundingPort1 = sortrows(table2timetable(CompressedSlagMatrix(1:end,1:2)));
CompSlagSoundingPort1=CompSlagSoundingPort1(~any(ismissing(CompSlagSoundingPort1),2),:);


CompSlagSoundingPort2 = sortrows(table2timetable(CompressedSlagMatrix(1:end,3:4)));
CompSlagSoundingPort2 = CompSlagSoundingPort2(~any(ismissing(CompSlagSoundingPort2),2),:);

CompSlagSoundingPort3 = sortrows(table2timetable(CompressedSlagMatrix(1:end,5:6)));
CompSlagSoundingPort3 = CompSlagSoundingPort3(~any(ismissing(CompSlagSoundingPort3),2),:);

CompSlagSoundingPort4 = sortrows(table2timetable(CompressedSlagMatrix(1:end,7:8)));
CompSlagSoundingPort4 =CompSlagSoundingPort4(~any(ismissing(CompSlagSoundingPort4),2),:);

CompSlagSoundingPort5 = sortrows(table2timetable(CompressedSlagMatrix(1:end,9:10)));
CompSlagSoundingPort5 =CompSlagSoundingPort5(~any(ismissing(CompSlagSoundingPort5),2),:);

CompSlagSoundingPort6 = sortrows(table2timetable(CompressedSlagMatrix(1:end,11:12)));
CompSlagSoundingPort6 =CompSlagSoundingPort6(~any(ismissing(CompSlagSoundingPort6),2),:);

CompSlagSoundingPort7 = sortrows(table2timetable(CompressedSlagMatrix(1:end,13:14)));
CompSlagSoundingPort7 =CompSlagSoundingPort7(~any(ismissing(CompSlagSoundingPort7),2),:);

CompSlagSoundingPort8 = sortrows(table2timetable(CompressedSlagMatrix(1:end,15:16)));
CompSlagSoundingPort8 =CompSlagSoundingPort8(~any(ismissing(CompSlagSoundingPort8),2),:);

CompSlagSoundingPort10 = sortrows(table2timetable(CompressedSlagMatrix(1:end,17:18)));
CompSlagSoundingPort10 = CompSlagSoundingPort10(~any(ismissing(CompSlagSoundingPort10),2),:);


TimetableSlagCompMatrix = synchronize(CompSlagSoundingPort1,CompSlagSoundingPort2,CompSlagSoundingPort3,CompSlagSoundingPort4,CompSlagSoundingPort5,CompSlagSoundingPort6,CompSlagSoundingPort7,CompSlagSoundingPort8,CompSlagSoundingPort10);
TimetableSlagCompMatrix.VarName37.Format = "dd-MMM-uuuu HH:mm";

%% 
%Find common timestamps between all four tables
SoundingTimeIndexComp1 = intersect(TimetableCompMatrixBuildUp.VarName1,TimetableMatteCompMatrix.VarName19);
SoundingTimeIndexComp2 = intersect(TimetableSlagCompMatrix.VarName37,TimetableConcCompMatrix.VarName55);
SoundingTimeIndexComp = intersect(SoundingTimeIndexComp1,SoundingTimeIndexComp2);

%Find the index for soundings in each of the tables
SlagCompIndex = ismember(TimetableSlagCompMatrix.VarName37,SoundingTimeIndexComp);
ConcCompIndex = ismember(TimetableConcCompMatrix.VarName55,SoundingTimeIndexComp);
MatteCompIndex = ismember(TimetableMatteCompMatrix.VarName19,SoundingTimeIndexComp);
BuildUpCompIndex = ismember(TimetableCompMatrixBuildUp.VarName1,SoundingTimeIndexComp);

SlagCompTrim = TimetableSlagCompMatrix(SlagCompIndex,:);
ConcCompTrim = TimetableConcCompMatrix(ConcCompIndex,:);
MatteCompTrim = TimetableMatteCompMatrix(MatteCompIndex,:);
BuildUpCompTrim = TimetableCompMatrixBuildUp(BuildUpCompIndex,:);

MatteCompTrimTable = timetable2table(MatteCompTrim);
MatteCompTrimTableTrim = MatteCompTrimTable(1:end,2:10);

BuildUpCompTrimTable = timetable2table(BuildUpCompTrim);
BuildUpCompTrimTableTrim = BuildUpCompTrimTable(1:end,2:10);

MatteCompTrimTableTrimA = table2array(MatteCompTrimTableTrim);
MatteCompTrimTableTrimA(isnan(MatteCompTrimTableTrimA)) = 0;

BuildUpCompTrimTableTrimA = table2array(BuildUpCompTrimTableTrim);
BuildUpCompTrimTableTrimA(isnan(BuildUpCompTrimTableTrimA)) = 0;

MattePlusBuildCompFinal = double(MatteCompTrimTableTrimA) + double(BuildUpCompTrimTableTrimA);

MattePlusBuildCompHisto = reshape(MattePlusBuildCompFinal',[],1);
MattePlusBuildCompHisto(MattePlusBuildCompHisto == 0) = NaN;

tiledlayout(1,3)
nexttile
aa = nanstd(MattePlusBuildCompHisto)
histogram(MattePlusBuildCompHisto)
title('Matte + BuildUp Distribution')
xlabel('Matte + BuildUp Thickness')
ylabel('Count')

nexttile
SlagCompTrimTable = timetable2table(SlagCompTrim);
SlagCompTrimTableTrim = SlagCompTrimTable(1:end,2:10);
SlagCompTrimTableTrimA = table2array(SlagCompTrimTableTrim);
SlagCompTrimTableTrimA(isnan(SlagCompTrimTableTrimA)) = 0;

SlagCompHisto = reshape(SlagCompTrimTableTrimA',[],1);

SlagCompHisto(SlagCompHisto == 0) = NaN;
nanstd(SlagCompHisto)
histogram(SlagCompHisto)
title('Slag Distribution')
xlabel('Slag Thickness')
ylabel('Count')

nexttile
ConcCompTrimTable = timetable2table(ConcCompTrim);
ConcCompTrimTableTrim = ConcCompTrimTable(1:end,2:10);
ConcCompTrimTableTrimA = table2array(ConcCompTrimTableTrim);
ConcCompTrimTableTrimA(isnan(ConcCompTrimTableTrimA)) = 0;

ConcCompHisto = reshape(ConcCompTrimTableTrimA',[],1);
ConcCompHisto(ConcCompHisto == 0) = NaN;
nanstd(ConcCompHisto)
histogram(ConcCompHisto)
title('Concentrate Distribution')
xlabel('Concentrate Thickness')
ylabel('Count')

%% 

figure
MattePlusBuildCompFinalNum = MattePlusBuildCompFinal;
MattePlusBuildCompFinalNum(MattePlusBuildCompFinalNum == 0) = NaN;
CompMatteBuildNumberOfPorts = sum(~isnan(MattePlusBuildCompFinalNum),2);
CompMeanMatteBuildNumberOfPorts=mean(CompMatteBuildNumberOfPorts);
CompMatteBuildNumberOfPorts(CompMatteBuildNumberOfPorts == 0) = NaN;
histogram(CompMatteBuildNumberOfPorts);

hold on 
SlagCompTrimTableTrimANum = SlagCompTrimTableTrimA;
SlagCompTrimTableTrimANum(SlagCompTrimTableTrimANum == 0) = NaN;
CompSlagNumberOfPorts = sum(~isnan(SlagCompTrimTableTrimANum),2);
CompSlagNumberOfPorts(CompSlagNumberOfPorts == 0) = NaN;
CompMeanSlagNumberOfPorts=mean(CompSlagNumberOfPorts);

histogram(CompSlagNumberOfPorts);

ConcCompTrimTableTrimANum = ConcCompTrimTableTrimA;
ConcCompTrimTableTrimANum(ConcCompTrimTableTrimANum == 0) = NaN;
CompConcNumberOfPorts = sum(~isnan(ConcCompTrimTableTrimANum),2);
CompMeanConcNumberOfPorts=mean(CompConcNumberOfPorts);
histogram(CompConcNumberOfPorts,'FaceColor','g')

title('Number of ports per sounding')
xlabel('Number of Ports')
ylabel('Count')
legend('Matte + BuildUp','Slag','Conc')
hold off
% 




%%


