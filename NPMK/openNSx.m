function varargout = openNSx(varargin)

% openNSx
% 
% Opens and reads an NSx file then returns all file information in a NSx
% structure. Works with File Spec 2.1, 2.2, 2.3, and 3.0.
% 
% OUTPUT = openNSx('ver')
% OUTPUT = openNSx(FNAME, 'read', 'report', 'e:xx:xx', 'c:xx:xx', 't:xx:xx', MODE, 'precision', 'skipfactor', 'nozeropad').
% 
% All input arguments are optional. Input arguments can be in any order.
%
%   'ver':        Immediately return version information for openNSx
%                 without processing any files.
%
%   FNAME:        Path of the file to be opened. If FNAME is omitted, a
%                 file selection dialog box will appear.
%
%   'noread':     Do not read the data contained in the file. Return only
%                 header information. ('read' input still accepted for
%                 legacy purposes, but is redundant with default behavior.)
%                 DEFAULT: 'read'
%
%   'report':     Show a summary report if user passes this argument.
%                 DEFAULT: No report.
%
%   'electrodes',XX:YY
%   'e:XX:YY':    User can specify which electrodes need to be read. The
%                 number of electrodes can be greater than or equal to 1
%                 and less than or equal to 256. The electrodes can be
%                 selected either by specifying a range (e.g. 20:45) or by
%                 indicating individual electrodes (e.g. 3,6,7,90) or both.
%                 Note that, when individual channels are to be read, all
%                 channels in between will also be read. The prorgam will
%                 then remove the unwanted channels. This may result in a
%                 large memory footprint. If memory issues arrise please
%                 consider placing openNSx in a for loop and reading
%                 individual channels.
%                 This field needs to be preceded by the prefix 'e:'. See
%                 example for more details. If this option is selected the
%                 user will be promped for a CMP mapfile (see: KTUEAMapFile)
%                 provided by Blackrock Microsystems. This feature requires
%                 KTUEAMapFile to be present in path.
%                 DEFAULT: will read all existing electrodes.
%
%   'channels',XX:YY
%   'c:XX:YY':    User can specify which channels need to be read. The
%                 number of channels can be greater than or equal to 1
%                 and less than or equal to 272. The channels can be
%                 selected either by specifying a range (e.g. 20:45) or by
%                 indicating individual channels (e.g. 3,6,7,90) or both.
%                 Note that, when individual channels are to be read, all
%                 channels in between will also be read. The prorgam will
%                 then remove the unwanted channels. This may result in a
%                 large memory footprint. If memory issues arrise please
%                 consider placing openNSx in a for loop and reading
%                 individual channels.
%                 This field needs to be preceded by the prefix 'c:'. See
%                 example for more details.
%                 DEFAULT: will read all existing analog channels.
%
%   'duration',XX:YY
%   't:XX:YY':    User can specify the beginning and end of the data
%                 segment to be read. If the start time is greater than the
%                 length of data the program will exit with an errorNS
%                 message. If the end time is greater than the length of
%                 data the end packet will be selected for end of data. The
%                 user can specify the start and end values by comma 
%                 (e.g. [20,50]) or by a colon (e.g. [20:50]). To use this
%                 argument the user must specify the [electrodes] or the
%                 interval will be used for [electrodes] automatically.
%                 This field needs to be preceded by the prefix 't:'. 
%                 Note that if 'mode' is 'sample' the start duration cannot
%                 be less than 1. The duration is inclusive.
%                 See example for more details.
%                 DEFAULT: will read the entire file.
%
%   MODE:         Specify the units of duration values specified with 
%                 'duration' (or 't:XX:YY') input. Valid values of MODE are
%                 'sec', 'min', 'hour', or 'sample'.
%                 DEFAULT: 'sample'
%
%   'uV':         Read the recording waveforms in unit of uV instead of raw
%                 values. Note that this conversion requires 'double'
%                 precision; if precision has been set to 'int16' or 
%                 'short', it will be updated to 'double' if this argument
%                 is provided.
%
%   'precision',P
%   'p:P':        Specify the precision P for data read from the NSx file.
%                 Valid options are 'double' (64-bit floating point) or
%                 'int16' (or, equivalently, 'short'; 16-bit signed
%                 integer). While 'int16' uses less memory, be mindful of
%                 the limitations of integer data types
%                 (https://www.mathworks.com/help/matlab/numeric-types.html).
%                 Note that if the argument 'uV' is provided (conversion
%                 from raw values to uV units), the precision will be
%                 automatically set to 'double' if it is not already.
%                 DEFAULT: 'int16'.
%
%   'skipfactor',S
%   's:S':        Decimate data read from disk, e.g., to quickly preview
%                 data. The integer S will determine how many samples to
%                 skip. For example, if skipfactor is 2 then every other
%                 sample is read. This action is only decimation: no
%                 anti-aliasing filter is applied.
%                 DEFAULT: 1 (every sample read)
%
%   'zeropad':    Prepend the data with zeros to compensate for non-zero 
%                 start time. Note that the time origin of newer data files
%                 is not 0, and timestamps may be in the 10^18 range.
%                 Prepending this many zeros is not possible for normal
%                 computer systems.
%                 DEFAULT: No zero padding.
%
%   'noalign':    Do not apply bug fix for clock drift in Central release
%                 7.6.0. In executing the bug fix (if this argument is not
%                 provided), samples may be added or removed to restore
%                 synchronization. Changes are made at evenly spaced points
%                 throughout the file. Samples are added by duplicating the
%                 prior sample.
%                 DEFAULT: Alignment occurs with warnings.
%
%   'max_tick_multiple', M:
%                 Newer data files use PTP (precision time protocol) to
%                 timestamp each sample of data, instead of only the first
%                 sample in a frame of contiguous samples. To detect pauses
%                 in a PTP recording, openNSx processes the file in frames:
%                 it reads the timestamp of the first and last packets in
%                 each frame (see 'packets_per_frame') and checks whether
%                 the elapsed time is greater than it should be, assuming
%                 contiguously recorded packets at the expected sampling
%                 rate. The threshold M for the difference of elapsed time
%                 is set as a multiple of the expected sampling interval.
%                 If M is too small, openNSx will detect spurious pauses.
%                 If it is too high, pauses will be missed. Note that due
%                 to jitter in sample timing, this value should be set in
%                 coordination with the number of packets in each frame
%                 (see 'packets_per_frame'), to ensure that the sum of the
%                 jitter does not exceed the detection threshold.
%                 DEFAULT: 2 (equivalent to missing one sample)
%
%   'packets_per_frame', P:
%                 Newer data files use PTP (precision time protocol) to
%                 timestamp each sample of data, instead of only the first
%                 sample in a frame of contiguous samples. To detect pauses
%                 in a PTP recording, openNSx processes the file in frames:
%                 it reads the timestamp of the first and last packets in
%                 each frame and checks whether the elapsed time is greater
%                 than it should be, assuming contiguously recorded packets
%                 at the expected sampling rate (see 'max_tick_multiple').
%                 The number of frames F is given by CEIL(TOTAL_PACKETS/P),
%                 where TOTAL_PACKETS is the number of packets in the file.
%                 Note that this method reads only F+1 timestamps from disk
%                 if there are no pauses detected. For each frame
%                 containing one or more detected pauses, all P timestamps
%                 in the frame are read from disk to identify the specific
%                 samples between which the pauses occur. Thus, P can be
%                 increased to lower F, but it should not be so large that
%                 a vector of P doubles would not fit in memory. Note also
%                 that because of jitter in sample timing, setting this
%                 value too large may lead to spurious detections (i.e.,
%                 the sum of jitter could be greater than the detection
%                 threshold).
%                 DEFAULT: 1,000 packets per frame.
%
%   OUTPUT:       The NSx structure.
%
%   Example 1: 
%   openNSx('report','read','c:\data\sample.ns5', 'e:15:30', 't:3:10','min', 'p:short', 's:5');
%
%   or equivalently
%   openNSx('report','read','c:\data\sample.ns5', 'electrodes', 15:30, 'duration', 3:10, 'min', 'precision', 'short', 'skipfactor', 5);
%
%   In the example above, the file c:\data\sample.ns5 will be used. A
%   report of the file contents will be shown. The data will be read from
%   electrodes 15 through 50 in the 3-10 minute time interval. A decimated 
%   version of the datafile will be read, where only every 5th sample is read.
%   If any of the arguments above are omitted the default values will be used.
%
%   Example 2:
%   openNSx('read','c:15:30');
%
%   In the example above, the user will be prompted for the file. The file
%   will be read using 'int16' precision as default. All time points of
%   channels 15 through 30 will be read.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Kian Torab
%   support@blackrockmicro.com
%   Blackrock Microsystems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Version History
%
% 5.1.8.2:
%   - Fixed the way DayOfWeek is read in MetaTags.
%
% 5.1.9.0:
%   - Fixed a bug where with skipFactor being read correctly as a num.
%
% 5.1.10.0:
%   - Updated feature to save data headers for a paused file. It is a
%     dependent feature for seperatePausedNSx.
%
% 5.1.11.0:
%   - Fixed an issue where 1 sample would not be read when using the
%     t:xx:xx argument and 'sample'.
%   - Fixed an error when 'duration' was used to load specific data length.
%
% 5.1.12.0:
%   - Better error handling if a file is not provided and an output
%     variable was requested by the calling function.
%
% 5.2.0.0: June 12, 2014
%   - It removes the extra ElectrodesInfo entried for channels not
%     read if 'c:XX:XX' or 'e:XX:XX' are used.
%   - It reports variable ChannelCount under MetaTags correctly.
%   - It automatically compensate for any NSx file with non-0 beginnings
%     and adds 0s for to the begining of the file to properly align the
%     timestamps.
%
% 5.2.1.0: June 12, 2014
%   - Fixed a small bug where extra 0s were tacked on to the beginning of
%     paused file segments.
%   - Updated the version.
%
% 5.2.2.0: June 13, 2014
%   - Fixed bug for when 'noread' was used on a paused file.
%
% 6.0.1.0: December 2, 2014
%   - Fixed a bug related to file format 2.1 not being read correctly.
%   - Corrected the way Filename, FileExt, and FilePath was being
%     processed.
%   - File dialogue now only shows NSx files on non Windows-based
%     computers.
%   - Added 512 synchronized reading capability.
%   - Now on non-Windows computers only NSx files are shown in the file
%     dialogue.
%   - Fixed the date in NSx.MetaTags.DateTime.
%
% 6.1.0.0: March, 15 2015
%   - Added the ability to read from networked drives in Windows.
%   - Fixed the DateTime variable in MetaTags.
%   - Fixed the date in NSx.MetaTags.DateTime (again).
%   - Fixed a bug related to starting and stopping packets when a specific
%     time is passed to the function.
%   - Fixed a bug where 512+ ch rules were being applied to smaller channel
%     count configuration.
%
% 6.1.1.0: June 15, 2015
%   - Bug fixes related to timestamps when the recording didn't start at
%     proctime 0.
%
% 6.2.0.0: October 1, 2015
%   - Fixed a bug related to reading the correct length of time when a skip
%     factor was used.
%   - Bug fixes related to information that separatePausedNSx depends on.
%   - Added 'uV' as an option to read the data in the unit of uV.
%
% 6.2.1.0: April 16, 2016
%   - Fixed a bug related to converting the unit to uV in case of having
%     multiple data segments (paused file).
%
% 6.2.2.0: July 6, 2016
%   - Fixed another bug related to converting the unit to uV.
%
% 6.3.0.0: August 3, 2016
%   - Added support for loading a segment of paused files.
%
% 6.3.1.0: August 31, 2016
%   - Fixed a bug when reading a non-o start across a paused segment.
%
% 6.4.0.0: December 1, 2016
%   - Fixed a serious bug related to loading paused files.
%   - Fixed a bug where an empty data segment resulted in a cell structure.
%
% 6.4.1.0: June 15, 2017
%   - It is no longer necessary to provide the full path for loading a
%     file.
%
% 6.4.2.0: September 1, 2017
%   - Fixed a bug related to reading data from sample that is not 1 and
%     timestamp that used to get reset to 0.
%
% 6.4.3.0: September 13, 2017
%   - Removed a redundant block of code that was accidentally placed in the
%     script twice.
%   - Checks to see if there's a newer version of NPMK is available.
%
% 6.4.3.1: January 24, 2020
%   - Changed file opening access from r+ to r.
%
% 7.0.0.0: January 27, 2020
%   - Added support for 64-bit timestamps in NEV and NSx.
%
% 7.1.0.0: April 14, 2020
%   - Added option to load the data without zero padding to compensate for 
%     a non-zero start time. (David Kluger)
%   - Bug fixes and documentation updates (David Kluger)
%
% 7.1.1.0: June 11, 2020
%   - Fixed a bug related to fread and MATLAB 2020a.
%
% 7.3.0.0: September 11, 2020
%   - Fixed a bug related to fread and MATLAB 2020a.
%   - Gives a warning about FileSpec 3.0 and gives the user options for how 
%     to proceed.
%   - Added a warning about the data unit and that by default it in the
%     unit of 250 nV or 1/4 �V.
%   - If the units are in "raw", ths correct information is now written to
%     the electrodes header: 250 nV (raw). 
%
% 7.3.1.0: October 2, 2020
%   - If the units are in �V (openNSx('uv'), ths correct information is now 
%     written to the electrodes header: 1000 nV (raw). 
%
% 7.3.2.0: October 23, 2020
%   - Fixed a typo.
%
% 7.4.0.0: October 29, 2020
%   - Undid changes made to AnalogUnit and instead implemented
%     NSx.ElectrodesInfo.Resolution to show what the resolution of the data
%     is. By default, the resolution is set to 0.250 �V. If used with
%     parameter 'uv', the resolution will be 1 �V. To always convert the
%     data to �V, divide NSx.Data(CHANNEL,:) by
%     NSx.ElectrodesInfo(CHANNEL).Resolution.
%
% 7.4.1.0: April 20, 2021
%   - Fixed a bug related to file opening.
%
% 7.4.2.0: May 5, 2021
%   - Fixed a bug related to NeuralSG file format (File Spec 2.1).
%
% 7.4.3.0: July 16, 2021
%   - Fixed a minor bug for when the data header is not written properly
%     and the data needs to be used to calculate the data length.
%
% 7.4.4.0: April 1, 2023
%   - Accounts for many segments in files for clock drift correction
%   - Changed 'zeropad' default behavior to be 'no'
%
% 7.4.5.0: December 6, 2023
%   - Better support for reading files recorded from Gemini systems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Defining the NSx data structure and sub-branches.
NSx          = struct('MetaTags',[],'Data',[], 'RawData', []);
NSx.MetaTags = struct('FileTypeID',[],'SamplingLabel',[],'ChannelCount',[],'SamplingFreq',[], 'TimeRes', [], ...
                      'ChannelID',[],'DateTime',[],'DateTimeRaw',[], 'Comment', [], 'FileSpec', [], ...
                      'Timestamp', [], 'DataPoints', [], 'DataDurationSec', [], 'openNSxver', [], 'Filename', [], 'FilePath', [], ...
                      'FileExt', []);
                                    
NSx.MetaTags.openNSxver = '7.4.5.0';
                  
%% Check for the latest version fo NPMK
NPMKverChecker

% Defining constants
ExtHeaderLength = 66;
elecReading     = 0;
NSx.RawData.PausedFile = 0;
syncShift = 0;

% Default values
Report = 0;
ReadData = 1;
TimeScale = 'sample';
precisionType = 'int16';
skipFactor = 1;
modifiedTime = 0;
multinsp = 1;
waveformUnits = 'raw';
zeropad = 0;
align = true;
packets_per_frame = 1000;
max_tick_multiple = 2;
userRequestedChanRow = [];
fname = '';

%% Validating the input arguments. Exit with error message if error occurs.
next = '';
for i=1:length(varargin)
    inputArgument = varargin{i};
    if strcmpi(inputArgument, 'ver')
        varargout{1} = NSx.MetaTags.openNSxver;
        return;
    elseif strcmpi(inputArgument, 'channels')
        next = 'channels';
    elseif strcmpi(inputArgument, 'skipfactor')
        next = 'skipfactor';
    elseif strcmpi(inputArgument, 'electrodes')
        next = 'electrodes';
    elseif strcmpi(inputArgument, 'duration')
        next = 'duration';
    elseif strcmpi(inputArgument, 'precision')
        next = 'precision';
    elseif strcmpi(inputArgument, 'packets_per_frame')
        next = 'packets_per_frame';
    elseif strcmpi(inputArgument, 'max_tick_multiple')
        next = 'max_tick_multiple';
    elseif strcmpi(inputArgument, 'report')
        Report = 1;
    elseif strcmpi(inputArgument, 'noread')
        ReadData = 0;
    elseif strcmpi(inputArgument, 'nomultinsp')
        multinsp = 0;
    elseif strcmpi(inputArgument, 'zeropad')
        zeropad = 1;
    elseif strcmpi(inputArgument, 'uV')
        waveformUnits = 'uV';
    elseif strcmpi(inputArgument, 'noalign')
        align = false;
    elseif strcmpi(inputArgument, 'read')
        ReadData = 1;
    elseif (strncmp(inputArgument, 't:', 2) && inputArgument(3) ~= '\' && inputArgument(3) ~= '/') || strcmpi(next, 'duration')
        if strncmp(inputArgument, 't:', 2)
            inputArgument(1:2) = [];
            inputArgument = str2num(inputArgument); %#ok<ST2NM>
        elseif ischar(inputArgument)
            inputArgument = str2num(inputArgument); %#ok<ST2NM>
        end
        modifiedTime = 1;
        StartPacket = inputArgument(1);
        EndPacket = inputArgument(end);
        next = '';
    elseif (strncmp(inputArgument, 'e:', 2) && inputArgument(3) ~= '\' && inputArgument(3) ~= '/') || strcmpi(next, 'electrodes')
        assert(exist('KTUEAMapFile','file')==2,'To read data by ''electrodes'' the function KTUEAMapFile needs to be in path.');
        Mapfile = KTUEAMapFile;
        Elec = str2num(inputArgument(3:end)); %#ok<ST2NM>
        if min(Elec)<1 || max(Elec)>128
            assert(min(Elec)>=1 && max(Elec)<=128, 'The electrode number cannot be less than 1 or greater than 128.');
        end
        userRequestedChannels = nan(1,length(Elec));
        for chanIDX = 1:length(Elec)
            userRequestedChannels(chanIDX) = Mapfile.Electrode2Channel(Elec(chanIDX));
        end
        elecReading = 1;
        next = '';
    elseif (strncmp(inputArgument, 's:', 2) && inputArgument(3) ~= '\' && inputArgument(3) ~= '/') || strcmpi(next, 'skipFactor')
        if strncmp(inputArgument, 's:', 2)
            skipFactor = str2num(inputArgument(3:end)); %#ok<ST2NM>
        elseif ischar(inputArgument)
            skipFactor = str2num(inputArgument); %#ok<ST2NM>
        else
            skipFactor = inputArgument;
        end
        next = '';
    elseif (strncmp(inputArgument, 'c:', 2) && inputArgument(3) ~= '\' && inputArgument(3) ~= '/') || strcmpi(next, 'channels')
        if strncmp(inputArgument, 'c:', 2)
            userRequestedChanRow = str2num(inputArgument(3:end)); %#ok<ST2NM>
        elseif ischar(inputArgument)
            userRequestedChanRow = str2num(inputArgument(3:end)); %#ok<ST2NM>
        else
            userRequestedChanRow = inputArgument;
        end
        next = '';
    elseif (strncmp(varargin{i}, 'p:', 2) && inputArgument(3) ~= '\' && inputArgument(3) ~= '/') || strcmpi(next, 'precision')
        if strncmp(varargin{i}, 'p:', 2)
            precisionTypeRaw = varargin{i}(3:end);
        else
            precisionTypeRaw = varargin{i};
        end
        switch precisionTypeRaw
            case {'int16','short'}
                precisionType = 'int16';
            case 'double'
                precisionType = 'double';
            otherwise
                error('Precision type is not valid. Refer to ''help'' for more information.');
        end
        clear precisionTypeRaw;
        next = '';
    elseif strcmpi(next, 'packets_per_frame')
        if ischar(inputArgument)
            packets_per_frame = str2double(inputArgument);
        else
            packets_per_frame = inputArgument;
        end
    elseif strcmpi(next, 'max_tick_multiple')
        if ischar(inputArgument)
            max_tick_multiple = str2double(inputArgument);
        else
            max_tick_multiple = inputArgument;
        end
    elseif strfind(' hour hours min mins minute minutes sec secs second seconds sample samples ', [' ' inputArgument ' ']) ~= 0
        TimeScale = inputArgument;
    else
        temp = char(inputArgument);
        if length(temp)>3 && ...
                (strcmpi(temp(3),'\') || ...
                strcmpi(temp(1),'/') || ...
                strcmpi(temp(2),'/') || ...
                strcmpi(temp(1:2), '\\') || ...
                strcmpi(temp(end-3), '.'))
            fname = inputArgument;
            assert(exist(fname, 'file')==2,'The file does not exist.');
        else
            error(['Invalid argument ''' inputArgument '''.']);
        end
    end
end
clear next;

% check uV conversion versus data type
if strcmpi(waveformUnits,'uV') && ~strcmpi(precisionType,'double')
    warning('Conversion to uV requires double precision; updating from %s to comply',precisionType);
    precisionType = 'double';
end

%% Popup the Open File UI. Also, process the file name, path, and extension
%  for later use, and validate the entry.
if ~exist('fname', 'var')
    [fname, path] = getFile('*.ns1;*.ns2;*.ns3;*.ns4;*.ns5;*.ns6;*.ns6m', 'Choose an NSx file...');
    assert(fname~=0,'No file selected');
    [~, ~, fext] = fileparts(fname);
else
    if isempty(fileparts(fname))
        fname = which(fname);
    end
    [path,fname, fext] = fileparts(fname);
    fname = [fname fext];
    path  = [path '/'];
end
if fname==0
    if nargout; varargout{1} = -1; end
    return;
end

%% Loading .x files for multiNSP configuration
if strcmpi(fext(2:4), 'ns6') && length(fext) == 5
    path(1) = fname(end);
    fname(end) = [];
end

tic;

%% Give all input arguments a default value. All input argumens are
%  optional.

% Check to see if 512 setup and calculate offset
if multinsp
    fiveTwelveFlag = regexp(fname, '-i[0123]-', 'ONCE');
    if ~isempty(fiveTwelveFlag)
        syncShift = multiNSPSync(fullfile(path, fname));
    else
        multinsp = 0;
    end
end

if ~ReadData
    warning('Reading the header information only.');
end

if Report
    disp(['openNSx ' NSx.MetaTags.openNSxver]);
end



%% Reading Basic Header from file into NSx structure.
fileFullPath = fullfile(path, fname);
[NSx.MetaTags.FilePath, NSx.MetaTags.Filename, NSx.MetaTags.FileExt] = fileparts(fileFullPath);

FID = fopen([path fname], 'r', 'ieee-le');
try
    NSx.MetaTags.FileTypeID = fread(FID, [1,8], 'uint8=>char');
    if strcmpi(NSx.MetaTags.FileTypeID, 'NEURALSG')
        timeStampBytes             = 4;
        NSx.MetaTags.FileSpec      = '2.1';
        NSx.MetaTags.SamplingLabel = fread(FID, [1,16], 'uint8=>char');
        NSx.MetaTags.TimeRes       = double(30000);
        NSx.MetaTags.SamplingFreq  = NSx.MetaTags.TimeRes / fread(FID, 1, 'uint32=>double');
        ChannelCount               = fread(FID, 1, 'uint32=>double');
        NSx.MetaTags.ChannelCount  = ChannelCount;
        NSx.MetaTags.ChannelID     = fread(FID, [ChannelCount 1], '*uint32');
        try
            t                          = dir(fileFullPath);
            NSx.MetaTags.DateTime      = t.date;
        catch ME2
            warning('Could not compute date from file.')
            NSx.MetaTags.DateTime  = '';
            disp(ME2)
        end
    elseif or(strcmpi(NSx.MetaTags.FileTypeID, 'NEURALCD'), strcmpi(NSx.MetaTags.FileTypeID, 'BRSMPGRP'))
        BasicHeader                = fread(FID, 306, '*uint8');
        NSx.MetaTags.FileSpec      = [num2str(double(BasicHeader(1))) '.' num2str(double(BasicHeader(2)))];
        %HeaderBytes                = double(typecast(BasicHeader(3:6), 'uint32'));
        NSx.MetaTags.SamplingLabel = char(BasicHeader(7:22))';
        NSx.MetaTags.Comment       = char(BasicHeader(23:278))';
        NSx.MetaTags.TimeRes       = double(typecast(BasicHeader(283:286), 'uint32'));
        NSx.MetaTags.SamplingFreq  = double(30000 / double(typecast(BasicHeader(279:282), 'uint32')));
        t                          = double(typecast(BasicHeader(287:302), 'uint16'));
        ChannelCount               = double(typecast(BasicHeader(303:306), 'uint32'));
        NSx.MetaTags.ChannelCount  = ChannelCount;
        readSize                   = double(ChannelCount * ExtHeaderLength);
        ExtendedHeader             = fread(FID, readSize, '*uint8');
        if strcmpi(NSx.MetaTags.FileTypeID, 'NEURALCD')
            timeStampBytes = 4;
        elseif strcmpi(NSx.MetaTags.FileTypeID, 'BRSMPGRP')
            timeStampBytes = 8;
        end
        
        %% Removing extra garbage characters from the Comment field.
        NSx.MetaTags.Comment(find(NSx.MetaTags.Comment==0,1):end) = 0;
        
        %% Populating extended header information
        for headerIDX = 1:ChannelCount
            offset = double((headerIDX-1)*ExtHeaderLength);
            NSx.ElectrodesInfo(headerIDX).Type = char(ExtendedHeader((1:2)+offset))';
            assert(strcmpi(NSx.ElectrodesInfo(headerIDX).Type, 'CC'),'extended header not supported');
            
            NSx.ElectrodesInfo(headerIDX).ElectrodeID = typecast(ExtendedHeader((3:4)+offset), 'uint16');
            NSx.ElectrodesInfo(headerIDX).Label = char(ExtendedHeader((5:20)+offset))';
            NSx.ElectrodesInfo(headerIDX).ConnectorBank = char(ExtendedHeader(21+offset) + ('A' - 1));
            NSx.ElectrodesInfo(headerIDX).ConnectorPin   = ExtendedHeader(22+offset);
            NSx.ElectrodesInfo(headerIDX).MinDigiValue   = typecast(ExtendedHeader((23:24)+offset), 'int16');
            NSx.ElectrodesInfo(headerIDX).MaxDigiValue   = typecast(ExtendedHeader((25:26)+offset), 'int16');
            NSx.ElectrodesInfo(headerIDX).MinAnalogValue = typecast(ExtendedHeader((27:28)+offset), 'int16');
            NSx.ElectrodesInfo(headerIDX).MaxAnalogValue = typecast(ExtendedHeader((29:30)+offset), 'int16');
            NSx.ElectrodesInfo(headerIDX).AnalogUnits    = char(ExtendedHeader((31:46)+offset))';
            if strcmpi(waveformUnits, 'uV')
                NSx.ElectrodesInfo(headerIDX).Resolution = 1;
            else
                NSx.ElectrodesInfo(headerIDX).Resolution = ...
                    round(double(NSx.ElectrodesInfo(headerIDX).MaxAnalogValue) / double(NSx.ElectrodesInfo(headerIDX).MaxDigiValue),4);
            end
            %         if strcmpi(waveformUnits, 'uV')
            %             NSx.ElectrodesInfo(headerIDX).AnalogUnits    = '1000 nV (raw)   ';
            %         else
            %             conversion = int16(double(NSx.ElectrodesInfo(headerIDX).MaxAnalogValue) / double(NSx.ElectrodesInfo(headerIDX).MaxDigiValue)*1000);
            %             NSx.ElectrodesInfo(headerIDX).AnalogUnits    = [num2str(conversion), ' nV (raw)    '];
            %         end
            NSx.ElectrodesInfo(headerIDX).HighFreqCorner = typecast(ExtendedHeader((47:50)+offset), 'uint32');
            NSx.ElectrodesInfo(headerIDX).HighFreqOrder  = typecast(ExtendedHeader((51:54)+offset), 'uint32');
            NSx.ElectrodesInfo(headerIDX).HighFilterType = typecast(ExtendedHeader((55:56)+offset), 'uint16');
            NSx.ElectrodesInfo(headerIDX).LowFreqCorner  = typecast(ExtendedHeader((57:60)+offset), 'uint32');
            NSx.ElectrodesInfo(headerIDX).LowFreqOrder   = typecast(ExtendedHeader((61:64)+offset), 'uint32');
            NSx.ElectrodesInfo(headerIDX).LowFilterType  = typecast(ExtendedHeader((65:66)+offset), 'uint16');
        end
        clear ExtendedHeader;
        %% Parsing and validating FileSpec and DateTime variables
        NSx.MetaTags.DateTimeRaw = t.';
        NSx.MetaTags.DateTime = datestr(datenum(t(1), t(2), t(4), t(5), t(6), t(7)));
        clear t;
    else
        error('Unsupported file spec %s', NSx.MetaTags.FileSpec);
    end
    
    %% Copying ChannelID to MetaTags for filespec 2.2, 2.3, and 3.0 for compatibility with filespec 2.1
    if or(strcmpi(NSx.MetaTags.FileTypeID, 'NEURALCD'), strcmpi(NSx.MetaTags.FileTypeID, 'BRSMPGRP'))
        NSx.MetaTags.ChannelID = [NSx.ElectrodesInfo.ElectrodeID]';
    end
    
    
    %% Determining the number of channels to read and validating the input
    % Moved higher up - DK 20230303
    if ~elecReading
        if isempty(userRequestedChanRow)
            userRequestedChannels = NSx.MetaTags.ChannelID;
        else
            assert(all(userRequestedChanRow<=ChannelCount),'Channel numbers must be less than or equal to the total number of channels in the file (%d)',ChannelCount);
            userRequestedChannels = NSx.MetaTags.ChannelID(userRequestedChanRow);
            NSx.MetaTags.ChannelCount = length(userRequestedChannels);
        end
    else
        NSx.MetaTags.ChannelCount = length(userRequestedChannels);
    end
    
    if isempty(userRequestedChanRow)
        userRequestedChanRow = nan(1,length(userRequestedChannels));
        for idx = 1:length(userRequestedChannels)
            assert(ismember(userRequestedChannels(idx), NSx.MetaTags.ChannelID),'Channel %d does not exist in this file',userRequestedChannels(idx));
            userRequestedChanRow(idx) = find(NSx.MetaTags.ChannelID == userRequestedChannels(idx),1);
        end
    end
    numChansToRead = double(length(min(userRequestedChanRow):max(userRequestedChanRow)));
    
    % Determining the length of file and storing the value of fEOF
    f.EOexH = double(ftell(FID));
    fseek(FID, 0, 'eof');
    f.EOF = double(ftell(FID));
    
    % Read Raw Header for saveNSx
    fseek(FID, 0, 'bof');
    NSx.RawData.Headers = fread(FID, f.EOexH, '*uint8');
    % if strcmpi(NSx.MetaTags.FileTypeID, 'NEURALCD')
    NSx.RawData.DataHeader = fread(FID, timeStampBytes+5, '*uint8');
    % end
    fseek(FID, f.EOexH, 'bof');
    
    %% Central v7.6.0 needs corrections for PTP clock drift - DK 20230303
    isPTP = false;
    if NSx.MetaTags.TimeRes > 1e5
        PacketSize = 1 + 8 + 4 + ChannelCount*2; % byte (Header) + uint64 (Timestamp) + uint32 (Samples, always 1) + int16*nChan (Data)
        %npackets = floor((f.EOF - f.EOexH)/PacketSize);
        fseek(FID,1 + 8,'cof'); % byte (Header) + uint64 (Timestamp)
        patchcheck = fread(FID,10,'uint32',PacketSize-4);
        if sum(patchcheck) == length(patchcheck)
            isPTP = true;
        end
    end
    fseek(FID, f.EOexH, 'bof');
    
    %% Reading all data headers and calculating all the file pointers for data
    % and headers
    if strcmpi(NSx.MetaTags.FileTypeID, 'NEURALSG')
        % Determining DataPoints
        f.BOData = f.EOexH;
        f.EOData = f.EOF;
        NSx.MetaTags.DataPoints = double(f.EOF-f.EOexH)/(ChannelCount*2);
        NSx.MetaTags.DataDurationSec = NSx.MetaTags.DataPoints/NSx.MetaTags.SamplingFreq;
    elseif or(strcmpi(NSx.MetaTags.FileTypeID, 'NEURALCD'), strcmpi(NSx.MetaTags.FileTypeID, 'BRSMPGRP'))
        % Adding logic for Central v7.6 clock drift - DK 20230303
        if ~isPTP
            segmentCount = 0;
            while double(ftell(FID)) < f.EOF
                if (fread(FID, 1, 'uint8') ~= 1)
                    % Fixing another bug in Central 6.01.00.00 TOC where DataPoints is
                    % not written back into the Data Header
                    %% BIG NEEDS TO BE FIXED
                    NSx.MetaTags.DataPoints = floor(double(f.EOF - f.BOData)/(ChannelCount*2));
                    NSx.MetaTags.DataDurationSec = NSx.MetaTags.DataPoints/NSx.MetaTags.SamplingFreq;
                    break;
                end
                segmentCount = segmentCount + 1;
                if strcmpi(NSx.MetaTags.FileTypeID, 'NEURALCD')
                    startTimeStamp = fread(FID, 1, 'uint32');
                elseif strcmpi(NSx.MetaTags.FileTypeID, 'BRSMPGRP')
                    startTimeStamp = fread(FID, 1, 'uint64');
                end
                if multinsp
                    
                    % close existing (read-only) file descriptor
                    curr_pos = ftell(FID);
                    fclose(FID);
                    
                    % open a file descriptor for read/write, write, and close
                    FID = fopen([path fname], 'r+', 'ieee-le');
                    startTimeStamp = startTimeStamp + syncShift;
                    fseek(FID, -timeStampBytes, 'cof');
                    fwrite(FID, startTimeStamp, '*uint32');
                    fclose(FID);
                    
                    % re-open read-only and seek to remembered position
                    FID = fopen([path fname], 'r', 'ieee-le');
                    fseek(FID,curr_pos,'bof');
                end
                NSx.MetaTags.Timestamp(segmentCount)  = startTimeStamp;
                NSx.MetaTags.DataPoints(segmentCount) = fread(FID, 1, 'uint32=>double');
                NSx.MetaTags.DataDurationSec(segmentCount) = NSx.MetaTags.DataPoints(segmentCount)/NSx.MetaTags.SamplingFreq;
                file.MetaTags.DataDurationTimeRes(segmentCount) = startTimeStamp*NSx.MetaTags.TimeRes/NSx.MetaTags.SamplingFreq;
                f.BOData(segmentCount) = double(ftell(FID));
                fseek(FID, NSx.MetaTags.DataPoints(segmentCount) * ChannelCount * 2, 'cof');
                f.EOData(segmentCount) = double(ftell(FID));
                % Fixing the bug in 6.01.00.00 TOC where DataPoints is not
                % updated and is left as 0
                % NSx.MetaTags.DataPoints(segmentCount) = (f.EOData(segmentCount)-f.BOData(segmentCount))/(ChannelCount*2);
            end
        else
            
            % Clock drift patch kills ability to segment files. This check will
            % allow segments to be reintroduced into the data structures if a
            % timestamp difference of 200% greater than expected is identified
            fseek(FID,f.EOexH + 1,'bof'); % + byte (header)
            
            % Process file in frames. initialize with the first packet's
            % timestamp.
            % For each frame, read the timestamp of the last packet.
            % if the difference from the previous frame's last timestamp is
            % larger than expected given consistent sampling rates, define a
            % segment.
            % Move to the next frame.
            ticks_per_sample = NSx.MetaTags.TimeRes/NSx.MetaTags.SamplingFreq;
            minimum_pause_length = max_tick_multiple*ticks_per_sample;
            timestamp_first = fread(FID,1,'uint64');
            num_packets_processed = 0;
            segment_timestamps = nan(1,1e3);
            segment_timestamps(1) = timestamp_first;
            segment_datapoints = nan(1,1e3);
            segment_durations = nan(1,1e3);
            curr_segment = 1;
            while double(ftell(FID)) < (f.EOF-(PacketSize-1-8))
                
                % frames have 'packets_per_frame' packets until the end of the
                % file, when the frame may have fewer packets
                % number of packets per frame includes first/last packet, which
                % means there is one fewer gap than the number of packets
                curr_packet_start_byte = double(ftell(FID)) - 8 - 1;
                frame_num_packets = min(packets_per_frame, (f.EOF - curr_packet_start_byte)/PacketSize);
                if abs(round(frame_num_packets)-frame_num_packets)>0.1
                    warning('File not packet-aligned')
                end
                bytes_to_last_frame_timestamp = PacketSize*(frame_num_packets-1) - 8;
                
                % compute the ticks expected to elapse in this frame with the
                % smallest detectable pause (2x sample time, or 66.6 usec)
                expected_ticks_elapsed_nopause = (frame_num_packets-1) * ticks_per_sample;
                expected_ticks_elapsed_minpause = expected_ticks_elapsed_nopause + (minimum_pause_length - ticks_per_sample);
                
                % seek to last packet of this frame and read timestamp
                fseek(FID, bytes_to_last_frame_timestamp, 'cof');
                timestamp_last = fread(FID,1,'uint64');
                
                % check whether elapsed time for this frame meets or exceeds
                % expected length with minimum gap
                actual_ticks_elapsed = timestamp_last - timestamp_first;
                if actual_ticks_elapsed >= expected_ticks_elapsed_minpause
                    
                    % a gap exists in this frame; we need to identify where it
                    % occurs
                    % save file pointer position
                    curr_pos = ftell(FID);
                    
                    % rewind to prior last_timestamp
                    fseek(FID, -(bytes_to_last_frame_timestamp+8+8), 'cof');
                    
                    % read all timestamps in this frame
                    timestamps = fread(FID, frame_num_packets, 'uint64', PacketSize-8)';
                    
                    % find gaps and store if found
                    ts_diffs = diff(timestamps);
                    vals = find(ts_diffs > minimum_pause_length);
                    for jj=1:length(vals)
                        num_datapoints_last_segment = num_packets_processed - nansum(segment_datapoints) + vals(jj);
                        segment_datapoints(curr_segment) = num_datapoints_last_segment;
                        segment_durations(curr_segment) = timestamps(vals(jj)) - segment_timestamps(curr_segment) + 1;
                        segment_timestamps(curr_segment + 1) = timestamps(vals(jj) + 1);
                        curr_segment = curr_segment + 1;
                    end
                    
                    % restore file pointer position
                    fseek(FID, curr_pos, 'bof');
                end
                
                % update for next round
                % -1 on the number of packets processed because the last packet
                % is included in the next frame also
                timestamp_first = timestamp_last;
                num_packets_processed = num_packets_processed + frame_num_packets - 1;
            end
            num_packets_processed = num_packets_processed + 1; % account for the overlapped sample on each frame
            assert(num_packets_processed == (f.EOF - f.EOexH)/PacketSize, 'Incosistent number of packets processed (%d) versus number of packets in file (%d)',num_packets_processed,(f.EOF-f.EOexH)/PacketSize);
            
            % compute number of datapoints in the last segment
            % add one to the number of packets processed to account for the
            % last packet of the file not being included in a subsequent frame
            segment_datapoints(curr_segment) = num_packets_processed - nansum(segment_datapoints);
            segment_durations(curr_segment) = timestamp_last - segment_timestamps(curr_segment) + 1;
            
            % add into NSx structure
            NSx.MetaTags.Timestamp = segment_timestamps(1:curr_segment);
            NSx.MetaTags.DataPoints = segment_datapoints(1:curr_segment);
            NSx.MetaTags.DataDurationSec = segment_durations(1:curr_segment)/NSx.MetaTags.TimeRes;
            file.MetaTags.DataDurationTimeRes = segment_durations(1:curr_segment);
            
            % may or may not be required
            f.BOData = [f.EOexH+1+8 f.EOexH+1+8+PacketSize*cumsum(segment_datapoints(1:curr_segment-1))];
            f.EOData = f.EOexH + PacketSize*cumsum(segment_datapoints(1:curr_segment));
        end
    end
    
    % Determining if the file has a pause in it
    if length(NSx.MetaTags.DataPoints) > 1
        NSx.RawData.PausedFile = 1;
    end
    
    
    %% Added by NH - Feb 19, 2014
    % Create incrementing loop to skip from dataheader to dataheader and
    % collect the dataheader data in individual cells
    headerCount = 0;
    % Adding logic for Central v7.6 clock drift - DK 20230303
    if and(NSx.RawData.PausedFile == 1, ~isPTP)
        DataHeader = cell(1,1e3);
        DataPoints = cell(1,1e3);
        while double(ftell(FID)) < f.EOF
            headerCount = headerCount + 1;
            fseek(FID, f.EOexH, 'bof');
            DataHeader{headerCount} = fread(FID, 9, '*uint8');
            DataPoints(headerCount) = typecast(DataHeader{headerCount}(6:9), 'uint32');
            
            f.BOData(headerCount) = double(ftell(FID));
            fseek(FID, DataPoints(headerCount) * ChannelCount * 2, 'cof');
            f.EOData(headerCount) = double(ftell(FID));
        end
        
        % Create an array that will contain all of the dataheader data
        % collected in the cells above
        FinalDataHeader = [];
        
        %Fill the above mentioned pre-created array
        for i = 1:headerCount
            FinalDataHeader = cat(1,FinalDataHeader,DataHeader(i));
        end
        
        % Convert to correct type for interpreting in separatingPausedNSx
        FinalDataHeader = cell2mat(FinalDataHeader);
        
        NSx.RawData.DataHeader = FinalDataHeader;
        
        fseek(FID, f.EOexH, 'bof');
    end
    
    %% Removing extra ElectrodesInfo for channels not read
    if or(strcmpi(NSx.MetaTags.FileTypeID, 'NEURALCD'), strcmpi(NSx.MetaTags.FileTypeID, 'BRSMPGRP'))
        for headerIDX = length(NSx.ElectrodesInfo):-1:1
            if ~ismember(headerIDX, userRequestedChanRow)
                NSx.ElectrodesInfo(headerIDX) = [];
            end
        end
    end
    
    %% Adjusts StartPacket and EndPacket based on what time setting (sec, min,
    %  hour, or packets) the user has indicated in the input argument.
    if ~modifiedTime
        StartPacket = 1;
        EndPacket = sum(NSx.MetaTags.DataPoints);
    else
        % needs to be updated to use knowledge of sample-by-sample timestamps in
        % Gemini files
        switch TimeScale
            case {'sec', 'secs', 'second', 'seconds'}
                StartPacket = StartPacket * NSx.MetaTags.SamplingFreq + 1;
                EndPacket = EndPacket * NSx.MetaTags.SamplingFreq;
            case {'min', 'mins', 'minute', 'minutes'}
                StartPacket = StartPacket * NSx.MetaTags.SamplingFreq * 60 + 1;
                EndPacket = EndPacket * NSx.MetaTags.SamplingFreq * 60;
            case {'hour', 'hours'}
                StartPacket = StartPacket * NSx.MetaTags.SamplingFreq * 3600 + 1;
                EndPacket = EndPacket * NSx.MetaTags.SamplingFreq * 3600;
        end
    end
    
    %% Validate StartPacket and EndPacket to make sure they do not exceed the
    %  length of packets in the file. If EndPacket is over then the last packet
    %  will be set for EndPacket. If StartPacket is over then will exist with an
    %  error message.
    assert(EndPacket>StartPacket,'Start packet (%d) must be less than the end packet (%d)',StartPacket,EndPacket);
    if StartPacket <= 0
        warning('Start packet (%d) must be greater than or equal to 1; updating to comply.',StartPacket);
        StartPacket = 1;
    end
    if EndPacket > sum(NSx.MetaTags.DataPoints)
        assert(StartPacket<sum(NSx.MetaTags.DataPoints),'Start packet (%d) is greater than total number of packets (%d)',StartPacket,sum(NSx.MetaTags.DataPoints));
        warning('End packet (%d) must be less than or equal to the total number of packets (%d).',EndPacket,sum(NSx.MetaTags.DataPoints));
        response = input('Do you wish to update EndPacket to last packet and continue? (y/N) ', 's');
        if strcmpi(response,'y')
            EndPacket = sum(NSx.MetaTags.DataPoints);
        else
            error('Invalid EndPacket');
        end
    end
    
    % Adjusting the endPacket for the skipFactor to reduce the length of
    % the data read.
    % DEBUG: This is not needed since the same length of data is to be
    % read.
    EndPacket = EndPacket / skipFactor;
    
    % Finding which data segment the StartPacket is falling in-between
    % Adding logic for Central v7.6 clock drift - DK 20230303
    segmentCounters = nan(1,2);
    startTimeStampShift = 0;
    if NSx.RawData.PausedFile
        dataPointOfInterest = StartPacket;
        segmentStartPacket = zeros(1,length(NSx.MetaTags.DataPoints));
        segmentDataPoints = zeros(1,length(NSx.MetaTags.DataPoints));
        for idx = 1:length(NSx.MetaTags.DataPoints)
            if dataPointOfInterest <= sum(NSx.MetaTags.DataPoints(1:idx))
                if all(isnan(segmentCounters))
                    if idx == 1
                        segmentStartPacket(idx) = dataPointOfInterest;
                    else
                        segmentStartPacket(idx) = dataPointOfInterest - sum(NSx.MetaTags.DataPoints(1:idx-1));
                    end
                    startTimeStampShift = (segmentStartPacket(idx)-1) * NSx.MetaTags.TimeRes / NSx.MetaTags.SamplingFreq;
                    if EndPacket <= sum(NSx.MetaTags.DataPoints(1:idx))
                        segmentDataPoints(idx) = EndPacket - sum(NSx.MetaTags.DataPoints(1:idx-1)) - segmentStartPacket(idx) + 1;
                        segmentCounters = [idx idx];
                        break;
                    end
                    segmentDataPoints(idx) = sum(NSx.MetaTags.DataPoints(1:idx)) - dataPointOfInterest + 1;
                    dataPointOfInterest = EndPacket;
                else
                    segmentStartPacket(idx) = 1;
                    if idx == 1
                        segmentDataPoints(idx) = dataPointOfInterest;
                    else
                        segmentDataPoints(idx) = dataPointOfInterest - sum(NSx.MetaTags.DataPoints(1:idx-1));
                        segmentCounters(2) = idx;
                    end
                    break;
                end
                segmentCounters(1) = idx;
            else
                if all(isnan(segmentCounters))
                    segmentStartPacket(idx) = NSx.MetaTags.DataPoints(idx);
                    segmentDataPoints(idx) = 0;
                elseif isnan(segmentCounters(2))
                    segmentStartPacket(idx) = 1;
                    segmentDataPoints(idx) = NSx.MetaTags.DataPoints(idx);
                else
                    segmentStartPacket(idx) = 1;
                    segmentDataPoints(idx) = 0;
                end
            end
        end
    end
    
    DataLength = EndPacket - StartPacket + 1;
    
    % from now StartPacket and EndPacket are in terms of Samples and are zero-based
    clear TimeScale
    
    %% Reading the data if flag 'read' is used
    file.MetaTags.DataPoints = NSx.MetaTags.DataPoints;
    file.MetaTags.DataDurationSec = NSx.MetaTags.DataDurationSec;
    file.MetaTags.Timestamp = NSx.MetaTags.Timestamp;
    if ReadData
        % Adding logic for Central v7.6 clock drift - DK 20230303
        if ~isPTP
            
            % Determine what channels to read
            if NSx.RawData.PausedFile
                NSx.Data = cell(1,diff(segmentCounters(1:2))+1);
                for dataIDX = segmentCounters(1):segmentCounters(2) %1:length(NSx.MetaTags.DataPoints)
                    cellIDX = dataIDX - segmentCounters(1) + 1;
                    fseek(FID, f.BOData(dataIDX), 'bof');
                    % Skip the file to the beginning of the time requsted, if not 0
                    fseek(FID, (segmentStartPacket(dataIDX) - 1) * 2 * ChannelCount, 'cof');
                    % Skip the file to the first channel to read
                    fseek(FID, (find(NSx.MetaTags.ChannelID == min(userRequestedChannels))-1) * 2, 'cof');
                    % Read data
                    NSx.Data{cellIDX} = fread(FID, [numChansToRead segmentDataPoints(dataIDX)], sprintf('%d*int16=>%s',numChansToRead,precisionType), double((ChannelCount-numChansToRead)*2 + ChannelCount*(skipFactor-1)*2));
                end
                
                NSx.MetaTags.Timestamp = NSx.MetaTags.Timestamp(segmentCounters(1):segmentCounters(2));
                NSx.MetaTags.Timestamp(1) = NSx.MetaTags.Timestamp(1) + startTimeStampShift;
                NSx.MetaTags.DataPoints = cellfun(@(x) size(x,2), NSx.Data, 'UniformOutput', true);
                NSx.MetaTags.DataDurationSec = NSx.MetaTags.DataDurationSec(segmentCounters(1):segmentCounters(2));
                NSx.MetaTags.DataDurationSec(1) = NSx.MetaTags.DataDurationSec(1) - (segmentStartPacket(segmentCounters(1))-1)/NSx.MetaTags.SamplingFreq;
                NSx.MetaTags.DataDurationSec(end) = NSx.MetaTags.DataPoints(end)/NSx.MetaTags.SamplingFreq;
            else
                fseek(FID, f.BOData(1), 'bof');
                % Skip the file to the beginning of the time requsted, if not 0
                fseek(FID, (StartPacket - 1) * 2 * ChannelCount, 'cof');
                % Skip the file to the first channel to read
                fseek(FID, (find(NSx.MetaTags.ChannelID == min(userRequestedChannels))-1) * 2, 'cof');
                % Read data
                NSx.Data = {fread(FID, [numChansToRead DataLength], sprintf('%d*int16=>%s',numChansToRead,precisionType), double((ChannelCount-numChansToRead)*2 + ChannelCount*(skipFactor-1)*2))};
                
                NSx.MetaTags.Timestamp(1) = NSx.MetaTags.Timestamp(1) + startTimeStampShift;
                NSx.MetaTags.DataPoints = size(NSx.Data{1},2);
                NSx.MetaTags.DataDurationSec = NSx.MetaTags.DataPoints/NSx.MetaTags.SamplingFreq;
            end
        else
            
            if NSx.RawData.PausedFile
                NSx.Data = cell(1,diff(segmentCounters)+1);
                for dataIDX = segmentCounters(1):segmentCounters(2)
                    cellIDX = dataIDX - segmentCounters(1) + 1;
                    fseek(FID, f.BOData(dataIDX), 'bof');
                    fseek(FID, (segmentStartPacket(dataIDX) - 1) * PacketSize, 'cof');
                    fseek(FID, (find(NSx.MetaTags.ChannelID == min(userRequestedChannels))-1) * 2, 'cof');
                    NSx.Data{cellIDX} = fread(FID, [numChansToRead segmentDataPoints(dataIDX)], sprintf('%d*int16=>%s',numChansToRead,precisionType), PacketSize - numChansToRead*2);
                end
                
                % define user tags: info specific to data being read
                NSx.MetaTags.Timestamp = NSx.MetaTags.Timestamp(segmentCounters(1):segmentCounters(2));
                NSx.MetaTags.Timestamp(1) = NSx.MetaTags.Timestamp(1) + startTimeStampShift;
                NSx.MetaTags.DataPoints = cellfun(@(x) size(x,2), NSx.Data, 'UniformOutput', true);
                NSx.MetaTags.DataDurationSec = NSx.MetaTags.DataDurationSec(segmentCounters(1):segmentCounters(2));
                NSx.MetaTags.DataDurationSec(1) = NSx.MetaTags.DataDurationSec(1) - (segmentStartPacket(segmentCounters(1))-1)/NSx.MetaTags.SamplingFreq;
                NSx.MetaTags.DataDurationSec(end) = NSx.MetaTags.DataPoints(end)/NSx.MetaTags.SamplingFreq;
            else
                % seek to start of data
                fseek(FID, f.BOData, 'bof');
                
                % seek to start of requested data
                % at this point, each packet retains the full header so we seek in
                % multiples of the PacketSize
                fseek(FID, (StartPacket - 1) * PacketSize, 'cof');
                
                % skip to first channel to read
                % within the packet, we only skip past 2-byte samples for the
                % unwanted channels
                fseek(FID, (find(NSx.MetaTags.ChannelID == min(userRequestedChannels))-1) * 2, 'cof');
                
                % read the data
                NSx.Data = {fread(FID, [numChansToRead DataLength], sprintf('%d*int16=>%s',numChansToRead,precisionType), PacketSize - numChansToRead*2)};
                
                % define user tags: info specific to data being read
                NSx.MetaTags.DataPoints = size(NSx.Data{1},2);
                NSx.MetaTags.DataDurationSec = NSx.MetaTags.DataPoints/NSx.MetaTags.SamplingFreq;
                NSx.MetaTags.Timestamp = NSx.MetaTags.Timestamp;
                NSx.MetaTags.Timestamp(1) = NSx.MetaTags.Timestamp(1) + startTimeStampShift;
            end
        end
    end
catch ME
    fclose(FID);
    rethrow(ME);
end

%% Fixing a bug in 6.03 TOC where an extra 0-length packet is introduced
if NSx.RawData.PausedFile && ReadData && ~isPTP
    if isempty(NSx.Data{1})
        NSx.Data = cell2mat(NSx.Data(2));
    end
end

% Fixing a bug in 6.03 where data packets with 0 lengh may be added
if any(NSx.MetaTags.DataPoints == 0) && ReadData
    segmentsThatAreZero = find(NSx.MetaTags.DataPoints == 0);
    NSx.MetaTags.DataPoints(segmentsThatAreZero) = [];
    NSx.MetaTags.Timestamp(segmentsThatAreZero) = [];
    NSx.Data(segmentsThatAreZero) = [];
end

%% Removing extra channels that were read, but weren't supposed to be read
% Commenting this section out since I think that previous code should
% capture this - DK 20230303
% channelThatWereRead = min(userRequestedChanRow):max(userRequestedChanRow);
% if ~isempty(setdiff(channelThatWereRead,userRequestedChanRow))
% 	deleteChannels = setdiff(channelThatWereRead, userRequestedChanRow) - min(userRequestedChanRow) + 1;
%     if NSx.RawData.PausedFile
%         for segIDX = 1:size(NSx.Data,2)
%             NSx.Data{segIDX}(deleteChannels,:) = [];
%         end
%     else
%         NSx.Data(deleteChannels,:) = [];
%     end
% end

%% Adjusting the ChannelID variable to match the read electrodes
channelIDToDelete = setdiff(1:ChannelCount, userRequestedChanRow);
NSx.MetaTags.ChannelID(channelIDToDelete) = [];

%% Adjusting the file for a non-0 timestamp start
if strcmpi(NSx.MetaTags.FileTypeID, 'BRSMPGRP') && zeropad
    NPMKSettings = settingsManager;
    if NSx.MetaTags.Timestamp(1) > 30000 && NPMKSettings.ShowZeroPadWarning == 1
        if isPTP
            error('PTP time has nanosecond precision. Data will generate too many zeros with "zeropad" argument.\n%s',...
                'Align data instead using NSx.MetaTags.Timestamp. Contact Blackrock Support for help adjusting your analysis workflows.');
        end
        disp(' ');
        disp('You have chosen to zeropad the NSx file that contains a large timestamp gap.');
        disp('For more information please refer to our <a href = "https://support.blackrockmicro.com/portal/en/kb/articles/nozeropad-in-opennsx">knowledge base article</a> on this subject.');
        disp('https://support.blackrockmicro.com/portal/en/kb/articles/nozeropad-in-opennsx');
        response = input('This could take a while. Do you wish to continue? ', 's');
        if strcmpi(response, 'n')
            return;
        end
        response = input('Do you want NPMK to continue to ask you about this every time? ', 's');
        if strcmpi(response, 'n')
            NPMKSettings.ShowZeroPadWarning = 0;
            settingsManager(NPMKSettings);
        end
    end
end

% Adding logic for Central v7.6 clock drift - DK 20230303
if ~NSx.RawData.PausedFile && StartPacket == 1 && zeropad && ~isPTP
    
    cellIDX = 1; % only do this for the first cell segment and not modify the subsequent segments
    if ReadData
        NSx.Data{cellIDX} = [zeros(NSx.MetaTags.ChannelCount, floor(NSx.MetaTags.Timestamp(cellIDX) / skipFactor), precisionType) NSx.Data{cellIDX}];
    end
    NSx.MetaTags.DataPoints(cellIDX) = size(NSx.Data{cellIDX},2);
    NSx.MetaTags.Timestamp(cellIDX) = 0;

    if multinsp
        NSx.Data{cellIDX} = [zeros(NSx.MetaTags.ChannelCount, syncShift, precisionType) NSx.Data{cellIDX}];
        NSx.MetaTags.DataPoints = size(NSx.Data{cellIDX},2);
    end
end


%% Adjusting for the data's unit.
if strcmpi(waveformUnits, 'uV')
    NSx.Data = cellfun(@(x) bsxfun(@rdivide, x, 1./(double([NSx.ElectrodesInfo.MaxAnalogValue])./double([NSx.ElectrodesInfo.MaxDigiValue]))'),NSx.Data ,'UniformOutput',false);
else
    NPMKSettings = settingsManager;
    if NPMKSettings.ShowuVWarning == 1
        disp(' ');
        disp('The data is in unit of 1/4 µV. This means that 100 in the NSx file equals to 25 µV. All values must be divided by 4.');
        disp('To read the data in unit of µV, use openNSx(''uv''). For more information type: help openNSx');

        response = input('Do you want NPMK to continue to ask you about this every time? ', 's');
        if strcmpi(response, 'n')
            NPMKSettings.ShowuVWarning = 0;
            settingsManager(NPMKSettings);
        end
    end
end

%% Adding implementation of samplealign for cases where it is needed
if isPTP && align
    for ii = 1:length(NSx.Data)
        file_datalength = file.MetaTags.DataPoints(ii);
        file_duration = file.MetaTags.DataDurationTimeRes(ii);

        % Calculate the ratio between time gaps and expected time gap
        % based on the sampling rate of the recording. A recording
        % where the claimed sampling rate and true sampling rate based
        % off PTP time are identical will have a ratio of 1;
        samplingrates = file_duration/file_datalength/NSx.MetaTags.TimeRes*NSx.MetaTags.SamplingFreq;

        % Calculate the number of samples that should be added or
        % removed
        addedsamples = round((samplingrates-1)*file_datalength);

        % Establish where the points should be added or removed
        gapind = round(file.MetaTags.DataPoints(ii)/(abs(addedsamples)+1));

        % calculate the portion of samples added/subtracted to the
        % requested data, which may be shorter than the full file
        addedsamples = round(addedsamples * NSx.MetaTags.DataPoints(ii)/file_datalength);
        
        % split into cell arrays
        dim1_sz = size(NSx.Data{ii},1);
        if gapind >= size(NSx.Data{ii},2)
            if abs(addedsamples)>1
                warning('Expected to add or remove only one sample')
            end
            dim2_sz = [round(size(NSx.Data{ii},2)/2) size(NSx.Data{ii},2)-round(size(NSx.Data{ii},2)/2)];
        else
            dim2_sz = [repmat(gapind,1,abs(addedsamples)) size(NSx.Data{ii},2) - sum(repmat(gapind,1,abs(addedsamples)))];
        end
        NSx.Data{ii} = mat2cell(NSx.Data{ii},dim1_sz,dim2_sz);

        % add or subtract
        if abs(addedsamples)==1
            sample_string = sprintf('%d sample',abs(addedsamples));
            where_string = 'at midpoint';
        else
            sample_string = sprintf('%d samples',abs(addedsamples));
            where_string = 'evenly spaced';
        end
        if length(NSx.Data)==1
            segment_string = 'the data';
        else
            segment_string = sprintf('data segment %d/%d',ii,length(NSx.Data));
        end
        if addedsamples>0
            NSx.Data{ii}(1:end-1) = cellfun(@(x) [x x(:,end)], NSx.Data{ii}(1:end-1), 'UniformOutput',false);
            warning('Added %s to %s (%s) for clock drift alignment',sample_string,segment_string,where_string)
        elseif addedsamples<0
            NSx.Data{ii}(1:end-1) = cellfun(@(x) x(:,1:end-1), NSx.Data{ii}(1:end-1), 'UniformOutput',false);
            warning('Removed %s from %s (%s) for clock drift alignment',sample_string,segment_string,where_string)
        end

        % combine to form the full data again
        NSx.Data{ii} = cat(2,NSx.Data{ii}{:});

        % recompute some metadata
        NSx.MetaTags.DataPoints(ii) = size(NSx.Data{ii},2);
        NSx.MetaTags.DataDurationSec(ii) = size(NSx.Data{ii},2)/NSx.MetaTags.SamplingFreq;
    end
end

%% Converting the data points in sample to seconds
NSx.MetaTags.DataPointsSec = double(NSx.MetaTags.DataPoints)/NSx.MetaTags.SamplingFreq;

%% Remove the cell if there is only one recorded segment present
% Adding logic for Central v7.6 clock drift - DK 20230303
if iscell(NSx.Data) && length(NSx.Data)==1
    NSx.Data = NSx.Data{1};
end

%% Displaying a report of basic file information and the Basic Header.
if Report
    disp( '*** FILE INFO **************************');
    disp(['File Path          = '  NSx.MetaTags.FilePath]);
    disp(['File Name          = '  NSx.MetaTags.Filename]);
    disp(['File Extension     = '  NSx.MetaTags.FileExt]);
	disp(['File Version       = '  NSx.MetaTags.FileSpec]);
    disp(['Duration (seconds) = '  num2str(NSx.MetaTags.DataDurationSec)]);
    disp(['Total Data Points  = '  num2str(NSx.MetaTags.DataPoints)]);
    disp(' ');
    disp( '*** BASIC HEADER ***********************');
    disp(['File Type ID       = '  NSx.MetaTags.FileTypeID]);
    disp(['Sample Frequency   = '  num2str(double(NSx.MetaTags.SamplingFreq))]);
    disp(['Electrodes Read    = '  num2str(double(NSx.MetaTags.ChannelCount))]);
    disp(['Data Point Read    = '  num2str(size(NSx.Data,2))]);
end

%% If user does not specify an output argument it will automatically create
%  a structure.
outputName = ['NS' fext(4)];
if (nargout == 0)
    assignin('caller', outputName, NSx);
else
    varargout{1} = NSx;
end

if Report
	disp(['The load time for ' outputName ' file was ' num2str(toc, '%0.1f') ' seconds.']);
end
fclose(FID);

end