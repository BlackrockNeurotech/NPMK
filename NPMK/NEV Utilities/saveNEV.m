function saveNEV(NEV,varargin)

%% 
% Save an .NEV file from an NEV structure (gained by using openNEV)
% Works with file spec 2.3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Use: saveNEV(NEV,optionalinputarguments)
%   NEV:        The NEV data structure.
%   All arguments below are optional:
%   Filename:   A complete filepath for the output file.
%               Default: CurrentFilename-out.nev

%saveNEV version = '1.0.0.0';

%% 
% Verify FilePath and establish overwrite paramaters
if not(NEV.MetaTags.FileSpec == '2.3')
    disp(strcat('This function only functions on file spec 2.3,;this is your file spec:',NEV.MetaTags.FileSpec));
    return
end

if not(isempty(varargin))
    FilePath = varargin;
else
    FilePath = [fullfile(NEV.MetaTags.FilePath,NEV.MetaTags.Filename) '-out.nev'];
    OldPath = cd(NEV.MetaTags.FilePath);
    [File,Path] = uiputfile;
    FilePath = [fullfile(Path,NEV.MetaTags.Filename) '-out.nev'];
end


Accept = input('This script will save a new file with the .NEV extensions, but you should retain the previous file. Do you acknowledge the risk inherent in saving modified versions of data files? (Y/N)','s');
if strcmpi(Accept,'y')
else
    disp('Ending Script...');
    return
end
%%
% Write the basic header into the file
%FullFile

CheckAgain = 1;
while CheckAgain >= 1

if exist(FilePath)
        if exist(FilePath)
            disp('File already exists!');
            disp('Changing output filename!');
            cd(Path)
            %%[File,Path] = uiputfile;
            FilePath = strcat(fullfile(Path,NEV.MetaTags.Filename),'-out',num2str(CheckAgain),'.nev');
            disp(strcat('New filepath is:',FilePath));
            CheckAgain = CheckAgain + 1;
        end
else
    CheckAgain = 0;
end
end

clear Overwrite
clear OverwritePrompt
clear varargin

FileID = fopen(FilePath, 'w', 'ieee-le');
    
if (FileID <= 0)
    disp('Error with file creation. It is possible that the destination selection was cancelled.');
    return;
end

disp('Writing Basic Header...');

fwrite(FileID,NEV.MetaTags.FileTypeID(1:8));
fwrite(FileID, [str2double(NEV.MetaTags.FileSpec(1)) str2double(NEV.MetaTags.FileSpec(3))], 'uint8');
fwrite(FileID,str2double(NEV.MetaTags.Flags),'uint16');
fwrite(FileID,NEV.MetaTags.HeaderOffset,'uint32');
fwrite(FileID,NEV.MetaTags.PacketBytes,'uint32');
fwrite(FileID,NEV.MetaTags.SampleRes,'uint32');
fwrite(FileID,NEV.MetaTags.TimeRes,'uint32');
fwrite(FileID,NEV.MetaTags.DateTimeRaw,'uint16');
fwrite(FileID,'saveNEV$version1001$$$$$$$$$$$$$'); 
fwrite(FileID,NEV.MetaTags.Comment); 
ExtendedHeaderBytes = NEV.MetaTags.HeaderOffset-ftell(FileID)+4;
fwrite(FileID,ExtendedHeaderBytes/32,'uint32');

%EndOfBasicHeader = ftell(FileID)

%%
% Write the extended header into the file. 

%Handling packets with array information
if isfield(NEV,'ArrayInfo')
    disp('Writing Array Header...');
    if isfield(NEV.ArrayInfo,'ElectrodeName')
        fwrite(FileID,'ARRAYNME');
        fwrite(FileID,NEV.ArrayInfo.ElectrodeName); %Must null terminate
    end
    if isfield(NEV.ArrayInfo,'ArrayComment')
        fwrite(FileID,'ECOMMENT');
        fwrite(FileID,NEV.ArrayInfo.ArrayComment); %Must null terminate
    end
    if isfield(NEV.ArrayInfo,'ArrayCommentCont')
        fwrite(FileID,'CCOMMENT');
        fwrite(FileID,NEV.ArrayInfo.ArrayCommentCont); %Must null terminate
    end
    if isfield(NEV.ArrayInfo,'MapFile')
        fwrite(FileID,'MAPFILE'); %+NULL
        fwrite(FileID,NEV.ArrayInfo.MapFile); %Must null terminate
    end
end

if isfield(NEV,'ElectrodesInfo')
    disp('Writing Electrode Header...');
    if (isfield(NEV.ElectrodesInfo(1),'ElectrodeID'))
        
    %Find length of electrode count, loop through for that count and fill
    %in  NEUEVWAV packets. 
        for IDX = 1:length(NEV.ElectrodesInfo)
            Before = ftell(FileID);
            fwrite(FileID,'NEUEVWAV');
            fwrite(FileID,NEV.ElectrodesInfo(IDX).ElectrodeID,'uint16');
            fwrite(FileID,NEV.ElectrodesInfo(IDX).ConnectorBank);
            fwrite(FileID,NEV.ElectrodesInfo(IDX).ConnectorPin,'uint8');
            fwrite(FileID,NEV.ElectrodesInfo(IDX).DigitalFactor,'uint16');
            fwrite(FileID,NEV.ElectrodesInfo(IDX).EnergyThreshold,'uint16');
            fwrite(FileID,NEV.ElectrodesInfo(IDX).HighThreshold,'int16');
            fwrite(FileID,NEV.ElectrodesInfo(IDX).LowThreshold,'int16');
            fwrite(FileID,NEV.ElectrodesInfo(IDX).Units,'uint8');
            fwrite(FileID,NEV.ElectrodesInfo(IDX).WaveformBytes,'uint8');
            if isempty(NEV.Data.Spikes.Waveform)
                fwrite(FileID,48,'uint16');
                SpikeLength = 48;
            else
                fwrite(FileID,length(NEV.Data.Spikes.Waveform(:,1)),'uint16');
                SpikeLength = length(NEV.Data.Spikes.Waveform(:,1));
            end
            %if file type is 2.2, don't need previous field and end in 10
            %zeros
            fwrite(FileID,zeros(8,1),'uint8');
            After = ftell(FileID);
            if After-Before ~= 32
                disp('Broken')
            end
        end
    end
    if (isfield(NEV.ElectrodesInfo(1),'ElectrodeLabel'))
        for IDX = 1:length(NEV.ElectrodesInfo)
        Before = ftell(FileID);
        fwrite(FileID,'NEUEVLBL');
        fwrite(FileID, NEV.ElectrodesInfo(IDX).ElectrodeID,'uint16');
        fwrite(FileID, NEV.ElectrodesInfo(IDX).ElectrodeLabel);%Must be nulll terminated
        fwrite(FileID, zeros(6,1),'uint8');
        After = ftell(FileID);
        if After-Before ~= 32
            disp('Broken')
        end
        end
    end
    if (isfield(NEV.ElectrodesInfo(1),'HighFreqCorner'))
        for IDX = 1:length(NEV.ElectrodesInfo)
        Before = ftell(FileID);
        fwrite(FileID,'NEUEVFLT');
        fwrite(FileID, NEV.ElectrodesInfo(IDX).ElectrodeID,'uint16');
        fwrite(FileID, NEV.ElectrodesInfo(IDX).HighFreqCorner,'uint32');
        fwrite(FileID, NEV.ElectrodesInfo(IDX).HighFreqOrder,'uint32');
        fwrite(FileID, NEV.ElectrodesInfo(IDX).HighFilterType,'uint16');
        fwrite(FileID, NEV.ElectrodesInfo(IDX).LowFreqCorner,'uint32');
        fwrite(FileID, NEV.ElectrodesInfo(IDX).LowFreqOrder,'uint32');
        fwrite(FileID, NEV.ElectrodesInfo(IDX).LowFilterType,'uint16');
        fwrite(FileID, zeros(2,1), 'uint8');
        After = ftell(FileID);
        if After-Before ~= 32
            disp('Broken')
        end
        end
    end   
end
%Digital inputs
if isfield(NEV,'IOLabels')
    disp('Writing IOLabels Header...');
    for IDX = [1,2]
    Before = ftell(FileID);
    fwrite(FileID,'DIGLABEL');
    fwrite(FileID,NEV.IOLabels{IDX},'uint8');
    fwrite(FileID, IDX - 1, 'uint8');
    fwrite(FileID, zeros(7,1),'uint8');
    After = ftell(FileID);
    if After-Before ~= 32
       disp('Broken')
    end
    end
end
    
%Video Packets
if isfield(NEV,'VideoSyncInfo')
    disp('Writing Video Header...');
    for IDX = 1:length(NEV.VideoSyncInfo)
    Before = ftell(FileID);
    fwrite(FileID,'VIDEOSYN');
    fwrite(FileID, NEV.VideoSyncInfo(IDX).SourceID, 'uint16');
    fwrite(FileID, NEV.VideoSyncInfo(IDX).SourceName(1:16));
    fwrite(FileID, NEV.VideoSyncInfo(IDX).FrameRateFPS,'single');
    fwrite(FileID, zeros(2,1),'uint8');
    After = ftell(FileID);
    if After-Before ~= 32
       disp('Broken')
       PacketNumber = IDX
       TotalPackets = length(NEV.VideoSyncInfo)
    end
    end
end

if isfield(NEV,'NSAS')
    %This might exist in a future version of Central
end

if isfield(NEV,'ObjTrackInfo')
    disp('Writing Tracking Header...');
    for IDX = 1:length(NEV.ObjTrackInfo)
    Before = ftell(FileID);
    fwrite(FileID,'TRACKOBJ');
    %ftell(FileID)-Before
    fwrite(FileID, NEV.ObjTrackInfo(IDX).TrackableType,'uint16');
    %ftell(FileID)-Before
    fwrite(FileID, NEV.ObjTrackInfo(IDX).TrackableID,'uint32');%This is an error and should be two different uint16 values, but we can read it back into file this way.
    %ftell(FileID)-Before
    fwrite(FileID, NEV.ObjTrackInfo(IDX).TrackableName);
    %ftell(FileID)-Before
    fwrite(FileID, zeros(2,1),'uint8');
    After = ftell(FileID);
    if After-Before ~= 32
       disp('Broken')
    end
    end
end

if isfield(NEV,'Rabbits')
    %Fill in the details about Rabbits at some point in the future.
end

%EndOfExtendedHeader = ftell(FileID)

%%
% Write Data GOOD UP TO THIS POINT
BytesInPackets = NEV.MetaTags.PacketBytes;
Broken = 0;

%SerialDigitalIO CHECK
if ~isempty(NEV.Data.SerialDigitalIO.TimeStamp)
    disp('Writing Serial/Digital Data...');
    for IDX = 1:length(NEV.Data.SerialDigitalIO.TimeStamp)
        Before = ftell(FileID);
        fwrite(FileID, NEV.Data.SerialDigitalIO.TimeStamp(IDX),'uint32');
        %ftell(FileID)-Before
        fwrite(FileID, 0,'uint16');
        %ftell(FileID)-Before
        fwrite(FileID, NEV.Data.SerialDigitalIO.InsertionReason(IDX));
        %ftell(FileID)-Before
        fwrite(FileID, '0');
        %ftell(FileID)-Before
        if ~isempty(NEV.Data.SerialDigitalIO.Value)
            fwrite(FileID, NEV.Data.SerialDigitalIO.Value(IDX),'uint16');
        else
            fwrite(FileID, NEV.Data.SerialDigitalIO.UnparsedData(IDX),'uint16');
        end
        %ftell(FileID)-Before
        fwrite(FileID, zeros(BytesInPackets-10,1),'uint8');
        %ftell(FileID)-Before
        After = ftell(FileID);
        if After-Before ~= BytesInPackets
            Broken = 1;
            %After-Before
            %CurrentPacket = IDX
            %TotalPackets = length(NEV.Data.SerialDigitalIO.TimeStamp)
        end
    end
    if Broken == 1
        disp('Serial Digital Packet Corrupted')
        Broken = 0;
    end
end

%Spikes CHECK
if ~isempty(NEV.Data.Spikes.TimeStamp)
    disp('Writing Spike Data...');
    for IDX = 1:length(NEV.Data.Spikes.TimeStamp)
        Before = ftell(FileID);
        fwrite(FileID, NEV.Data.Spikes.TimeStamp(IDX),'uint32');

        fwrite(FileID, NEV.Data.Spikes.Electrode(IDX),'uint16');

        fwrite(FileID, NEV.Data.Spikes.Unit(IDX),'uchar');

        fwrite(FileID, 0,'uchar');

        fwrite(FileID, NEV.Data.Spikes.Waveform(:,IDX)','int16');
        
        
        
        %for Value = 1:SpikeLength
        %    fwrite(FileID, NEV.Data.Spikes.Waveform(Value,IDX),'int16');
        %end
        
        After = ftell(FileID);
        if After-Before ~= BytesInPackets
            Broken = 1;
        end
    end
    if Broken == 1
        disp('Spike Packet Corrupted')
        Broken = 0;
    end
end
%disp('done')
%Comments CHECK
if ~isempty(NEV.Data.Comments.TimeStamp)
    disp('Writing Comment Data...');
    for IDX = 1:length(NEV.Data.Comments.TimeStamp)
        Before = ftell(FileID);
        fwrite(FileID, NEV.Data.Comments.TimeStamp(IDX),'uint32');
        %ftell(FileID)-Before
        fwrite(FileID, 65535, 'uint16');
        %ftell(FileID)-Before
        fwrite(FileID, NEV.Data.Comments.CharSet(IDX),'uint8');
        %ftell(FileID)-Before
        fwrite(FileID, 0,'uint8');
        %ftell(FileID)-Before
        fwrite(FileID, NEV.Data.Comments.Color(IDX),'uint32');
        %ftell(FileID)-Before
        fwrite(FileID, NEV.Data.Comments.Text(IDX,:));
        %ftell(FileID)-Before
        %Need to handle extra characters here etc
        fwrite(FileID, zeros(BytesInPackets-(ftell(FileID)-Before),1),'uint8');
        After = ftell(FileID);
        if After-Before ~= BytesInPackets
            Broken = 1;
            %After-Before
            %CurrentPacket = IDX
            %TotalPackets = length(NEV.Data.Comments.TimeStamp)
        end
    end
    if Broken == 1
        disp('Comment Packet Corrupted')
        Broken = 0;
    end
end

if ~isempty(NEV.Data.VideoSync.TimeStamp)
    disp('Writing VideoSync Data...');
    for IDX = 1:length(NEV.Data.VideoSync.TimeStamp)
        Before = ftell(FileID);
        fwrite(FileID, NEV.Data.VideoSync.TimeStamp(IDX),'uint32');
        %ftell(FileID)-Before
        fwrite(FileID, 65534, 'uint16');
        %ftell(FileID)-Before
        fwrite(FileID, NEV.Data.VideoSync.FileNumber(IDX),'uint16');
        %ftell(FileID)-Before
        fwrite(FileID, NEV.Data.VideoSync.FrameNumber(IDX),'uint32');%Wrong Size
        %ftell(FileID)-Before
        fwrite(FileID, NEV.Data.VideoSync.ElapsedTime(IDX),'uint32');%Wrong Size
        %ftell(FileID)-Before
        fwrite(FileID, NEV.Data.VideoSync.SourceID(IDX),'uint32');
        %ftell(FileID)-Before
        fwrite(FileID, zeros(BytesInPackets - 20,1),'uint8');
        %ftell(FileID)-Before
        After = ftell(FileID);
        if After-Before ~= BytesInPackets
            Broken = 1;
            %After-Before
            %CurrentPacket = IDX
            %TotalPackets = length(NEV.Data.VideoSync.TimeStamp)
        end
        
    end
    if Broken == 1
        disp('Video Sync Packet Corrupted')
        Broken = 0;
    end
end

if ~isempty(NEV.Data.Tracking)
    disp('Writing Tracking Data...');
    TrackingFieldNames = fieldnames(NEV.Data.Tracking);
        for TrackingField = 1:numel(TrackingFieldNames)
            for IDX = 1:length(NEV.Data.Tracking.(TrackingFieldNames{TrackingField}).TimeStamp)
                Before = ftell(FileID);
                fwrite(FileID, NEV.Data.Tracking.(TrackingFieldNames{TrackingField}).TimeStamp(IDX),'uint32');
                %ftell(FileID)-Before
                fwrite(FileID, 65533, 'uint16');
                %ftell(FileID)-Before
                fwrite(FileID, NEV.Data.Tracking.(TrackingFieldNames{TrackingField}).ParentID(IDX),'uint16');
                %ftell(FileID)-Before
                fwrite(FileID, NEV.Data.Tracking.(TrackingFieldNames{TrackingField}).NodeCount(IDX),'uint16');
                %ftell(FileID)-Before
                fwrite(FileID, NEV.Data.Tracking.(TrackingFieldNames{TrackingField}).MarkerCount(IDX),'uint16');
                %ftell(FileID)-Before
                fwrite(FileID, NEV.Data.Tracking.(TrackingFieldNames{TrackingField}).MarkerCoordinates(IDX).X,'uint16');
                %ftell(FileID)-Before
                fwrite(FileID, NEV.Data.Tracking.(TrackingFieldNames{TrackingField}).MarkerCoordinates(IDX).Y,'uint16');
                %ftell(FileID)-Before
                After = ftell(FileID);
                if After-Before ~= BytesInPackets
                    Broken = 1;
                    %After-Before
                    %CurrentPacket = IDX
                    %TotalPackets = length(NEV.Data.VideoSync.TimeStamp)
                end
                %Must somehow terminate in correct number of zeros
            end
            if Broken == 1
                disp('Tracking Packet Corrupted')
                Broken = 0;
            end
        end
end

if ~isempty(NEV.Data.PatientTrigger.TimeStamp)
    disp('Writing Patient Trigger Data...');
    for IDX = 1:length(NEV.Data.PatientTrigger.TimeStamp)
        Before = ftell(FileID);
        fwrite(FileID, NEV.Data.PatientTrigger.TimeStamp(IDX),'uint32');
        %ftell(FileID)-Before
        fwrite(FileID, 65532, 'uint16');
        %ftell(FileID)-Before
        fwrite(FileID, NEV.Data.PatientTrigger.TriggerType(IDX),'uint16');
        %ftell(FileID)-Before
        fwrite(FileID, zeros(BytesInPackets - 8, 1),'uint8');
        %ftell(FileID)-Before
        After = ftell(FileID);
        if After-Before ~= BytesInPackets
            Broken = 1;
            %After-Before
            %CurrentPacket = IDX
            %TotalPackets = length(NEV.Data.PatientTrigger.TimeStamp)
        end
    end
    if Broken == 1
        disp('Patient Trigger Packet Corrupted')
        Broken = 0;
    end
    
end

if ~isempty(NEV.Data.Reconfig.TimeStamp)
    disp('Writing Reconfig Data...');
    for IDX = 1:length(NEV.Data.Reconfig.TimeStamp)
        Before = ftell(FileID);
        fwrite(FileID, NEV.Data.Reconfig.TimeStamp(IDX),'uint32');
        %ftell(FileID)-Before
        fwrite(FileID, 65531, 'uint16');
        %ftell(FileID)-Before
        fwrite(FileID, NEV.Data.Reconfig.ChangeType(IDX),'uint16');
        %ftell(FileID)-Before
        fwrite(FileID, zeros(BytesInPackets - 8,1),'uint8');
        %ftell(FileID)-Before
        After = ftell(FileID);
        if After-Before ~= BytesInPackets
            Broken = 1;
            %After-Before
            %CurrentPacket = IDX
            %TotalPackets = length(NEV.Data.Reconfig.TimeStamp)
        end
    end
    if Broken == 1
        disp('Reconfig Packet Corrupted')
        Broken = 0;
    end
end

disp('Finished!')

clear After
clear Before
clear Broken
clear BytesInPackeets
clear ExtendedHederBytes
clear FilePath
clear IDX
clear SpikeLength
clear Value

cd(OldPath);

clear OldPath

fclose('all');
