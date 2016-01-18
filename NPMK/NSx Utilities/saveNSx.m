function saveNSx(NSx,varargin)

%% 
% Save an .NSx file from an NSx structure (gained by using openNSx)
% Works with file spec 2.3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Use: saveNSx(NSx,optionalinputarguments)
%   NSx:        The NSx data structure.
%   All arguments below are optional:
%   Filename:   A complete filepath for the output file.
%               Default: CurrentFilename-Modified.NSx

%saveNSx version = '1.0.0.0';


%% 
% Verify FilePath and establish overwrite paramaters
if not(isempty(varargin))
    FilePath = varargin{1};
else
    FilePath = [fullfile(NSx.MetaTags.FilePath,NSx.MetaTags.Filename) NSx.MetaTags.FileExt];
    [File,Path] = uiputfile;
    FilePath = [fullfile(Path,NSx.MetaTags.Filename(1:end-4)),'-Modified',  NSx.MetaTags.FileExt];
end


Accept = input('This script will save a new file with the proper .NSx extensions, but you should retain the previous file. Do you acknowledge the risk inherent in saving modified versions of data files? (Y/N)','s');
if strcmpi(Accept,'y')
else
    disp('Ending Script...');
    return
end

%%
% Write the basic header into the file
%FullFile
Debug = 1;

if exist(FilePath)
        if exist(FilePath)
        disp('File already exists!');
        OverwritePrompt = input('Would you like to overwrite? (Y/N)','s');
        if strcmpi(OverwritePrompt,'y')
            Overwrite = 1;
            delete(FilePath);
        else
            return
        end
        end
end

clear Overwrite
clear OverwritePrompt
clear varargin

%PausedFile?
if iscell(NSx.Data)
    Paused = 1;
    NumberOfSegments = length(NSx.Data);
else
    Paused = 0;
  
end

FileID = fopen(FilePath, 'w', 'ieee-le');

%Basic header stuff
BytesInBasicHeader = 8+2+4+16+256+4+4+16+4;
BytesInExtendedHeader = 2+2+16+1+1+2+2+2+2+16+4+4+2+4+4+2;
if Paused == 1
    for SegmentCount = 1:NumberOfSegments
    [NumberOfChannels,LengthOfData{SegmentCount}] = size(NSx.Data{SegmentCount});
    end
elseif Paused == 0
    [NumberOfChannels,LengthOfData] = size(NSx.Data);
end



%File Type ID
Before = 0;
fwrite(FileID,NSx.MetaTags.FileTypeID(1:8));
    After = ftell(FileID);
    if not(After-Before == 8) && Debug == 1
        disp('error FildID')
    end
%File spec
    Before = ftell(FileID);
fwrite(FileID, [str2double(NSx.MetaTags.FileSpec(1)) str2double(NSx.MetaTags.FileSpec(3))], 'uint8');
    After = ftell(FileID);
    if not(After-Before == 2) && Debug == 1
        disp('error File Spec')
    end
%Bytes in Headers
    Before = ftell(FileID);
fwrite(FileID, BytesInBasicHeader+NumberOfChannels*BytesInExtendedHeader,'uint32');
    After = ftell(FileID);
    if not(After-Before == 4) && Debug == 1
        disp('error BytesInHeaders')
    end
%Label
    Before = ftell(FileID);
fwrite(FileID, NSx.MetaTags.SamplingLabel);
    After = ftell(FileID);
    if After-Before ~= 16 && Debug == 1
        disp('error label')
    end
%Comment
    Before = ftell(FileID);
fwrite(FileID, NSx.MetaTags.Comment);
    After = ftell(FileID);
    if After-Before ~= 256 && Debug == 1
        disp('error comment')
    end
%Period
    Before = ftell(FileID);
fwrite(FileID, (1/NSx.MetaTags.SamplingFreq)*30000, 'uint32');
    After = ftell(FileID);
    if After-Before ~= 4 && Debug == 1
        disp('error period')
    end
%Time Resolution of time stamps
    Before = ftell(FileID);
fwrite(FileID, NSx.MetaTags.TimeRes,'uint32');
    After = ftell(FileID);
    if After-Before ~= 4 && Debug == 1
        disp('error time resolution')
    end
%Time Origin
    Before = ftell(FileID);
fwrite(FileID, NSx.MetaTags.DateTimeRaw,'uint16');
    After = ftell(FileID);
    if After-Before ~= 16 && Debug == 1
        disp('error Time Origin')
    end
%Channel Count
    Before = ftell(FileID);
fwrite(FileID, NumberOfChannels,'uint32');
    After = ftell(FileID);
    if After-Before ~= 4 && Debug == 1
        disp('error Channel Count')
    end



%Extended header stuff
%Number of these equal to number of channels
for i = 1:NumberOfChannels
    
%Type
    Before = ftell(FileID);
fwrite(FileID, 'CC');
    After = ftell(FileID);
    if After-Before ~= 2 && Debug == 1
        disp('error Type')
    end
%ElectrodeID
    Before = ftell(FileID);
fwrite(FileID, NSx.ElectrodesInfo(i).ElectrodeID,'uint16');
    After = ftell(FileID);
    if After-Before ~= 2 && Debug == 1
        disp('error ElectrodeID')
    end
%Electrode label
    Before = ftell(FileID);
fwrite(FileID, NSx.ElectrodesInfo(i).Label);
    After = ftell(FileID);
    if After-Before ~= 16 && Debug == 1
        disp('error Electrode Label')
    end
%Physical connector
    Before = ftell(FileID);
fwrite(FileID, NSx.ElectrodesInfo(i).ConnectorBank);
    After = ftell(FileID);
    if After-Before ~= 1 && Debug == 1
        disp('error Physical Connector')
    end
%Physical pin
    Before = ftell(FileID);
fwrite(FileID, NSx.ElectrodesInfo(i).ConnectorPin);
    After = ftell(FileID);
    if After-Before ~= 1 && Debug == 1
        disp('error Physical Pin')
    end
%Min Digital Value
    Before = ftell(FileID);
fwrite(FileID, NSx.ElectrodesInfo(i).MinDigiValue,'int16');
    After = ftell(FileID);
    if After-Before ~= 2 && Debug == 1
        disp('error min Digital Value')
    end
%Max Digital Value
    Before = ftell(FileID);
fwrite(FileID, NSx.ElectrodesInfo(i).MaxDigiValue,'int16');
    After = ftell(FileID);
    if After-Before ~= 2 && Debug == 1
        disp('error Max Digital value')
    end
%Min Analog Value
    Before = ftell(FileID);
fwrite(FileID, NSx.ElectrodesInfo(i).MinAnalogValue,'int16');
    After = ftell(FileID);
    if After-Before ~= 2 && Debug == 1
        disp('error Min Analog Value')
    end
%Max Analog Value
    Before = ftell(FileID);
fwrite(FileID, NSx.ElectrodesInfo(i).MaxAnalogValue,'int16');
    After = ftell(FileID);
    if After-Before ~= 2 && Debug == 1
        disp('error Max Aanalog value')
    end
%Units
    Before = ftell(FileID);
fwrite(FileID, NSx.ElectrodesInfo(i).AnalogUnits,'char');
    After = ftell(FileID);
    if After-Before ~= 16 && Debug == 1
        disp('error Units')
    end
%High Freq Corner (High frequency cutoff in mHz)
    Before = ftell(FileID);
fwrite(FileID, NSx.ElectrodesInfo(i).HighFreqCorner,'uint32');
    After = ftell(FileID);
    if After-Before ~= 4 && Debug == 1
        disp('error High Corner')
    end
%High Freq Order (Order of the filter used)
    Before = ftell(FileID);
fwrite(FileID, NSx.ElectrodesInfo(i).HighFreqOrder,'uint32');
    After = ftell(FileID);
    if After-Before ~= 4 && Debug == 1
        disp('error high Order')
    end
%High Filter Type (0 = none, 1 = butterworth)
    Before = ftell(FileID);
fwrite(FileID, NSx.ElectrodesInfo(i).HighFilterType,'uint16');
    After = ftell(FileID);
    if After-Before ~= 2 && Debug == 1
        disp('error High Type')
    end
%Low Freq Corner (Low frequency cutoff in mHz)
    Before = ftell(FileID);
fwrite(FileID, NSx.ElectrodesInfo(i).LowFreqCorner,'uint32');
    After = ftell(FileID);
    if After-Before ~= 4 && Debug == 1
        disp('error Low Corner')
    end
%Low Freq Order (0 = none)
    Before = ftell(FileID);
fwrite(FileID, NSx.ElectrodesInfo(i).LowFreqOrder,'uint32');
    After = ftell(FileID);
    if After-Before ~= 4 && Debug == 1
        disp('error Low Order')
    end
%Low Filter Type (0 = none, 1 = butterworth)
    Before = ftell(FileID);
fwrite(FileID, NSx.ElectrodesInfo(i).LowFilterType,'uint16');
    After = ftell(FileID);
    if After-Before ~= 2 && Debug == 1
        disp('error Low Type')
    end

end


    %DataPackets
if Paused == 0
    %Header
    fwrite(FileID, NSx.RawData.DataHeader(1));
    %Timestamp
    fwrite(FileID, NSx.MetaTags.Timestamp,'uint32');
    %Number of data points
    fwrite(FileID, LengthOfData, 'uint32');

    TotalDataPoints = LengthOfData * NumberOfChannels;
    %for i = 1:TotalDataPoints
    %Data points
    %fwrite(FileID, NSx.Data(i),'int16');
    fwrite(FileID, NSx.Data,'int16');
    %end
elseif Paused == 1
    for SegmentNumber = 1:NumberOfSegments
        %Header
        fwrite(FileID, NSx.RawData.DataHeader(1+9*(SegmentNumber-1)));
        %Timestamp
        fwrite(FileID, NSx.MetaTags.Timestamp(SegmentNumber),'uint32');
        %Number of data points
        fwrite(FileID, LengthOfData{SegmentNumber}, 'uint32');

        TotalDataPoints = LengthOfData{SegmentNumber} * NumberOfChannels;
        %for i = 1:TotalDataPoints
        %Data points
        %fwrite(FileID, NSx.Data(i),'int16');
        fwrite(FileID, NSx.Data{SegmentNumber},'int16');
        %end
    end
end

fclose(FileID);













