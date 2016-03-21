function OUTPUT = openNSxHL(fname)

% openNSxHL
% 
% Opens and reads an NSx file without the header information and returns
% the binary data. This can be used for specific applications that require
% this type of data, e.g. Klusters. Works with File Spec 2.1, 2.2 and 2.3.
% It does not support pauses at this time.
%
%
% Use OUTPUT = openNSx(fname)
% 
% All input arguments are optional.
%
%   fname:        Name of the file to be opened. If the fname is omitted
%                 the user will be prompted to select a file. 
%                 DEFAULT: Will open Open File UI.
%
%   OUTPUT:       Contains the binary data.
%
%   Example 1: 
%   openNSxHL('c:\data\sample.ns5');
%
%   In the example above, the file c:\data\sample.ns5 will be opened and
%   the data will be read and output through variable OUTPUT.
%
%   Example 2:
%   openNSxHL;
%
%   In the example above, the file user will be prompted for the file. The
%   selected file will be opened and the data will be read and output
%   through variable OUTPUT.
%
%   Kian Torab
%   kian@blackrockmicro.com
%   Blackrock Microsystems
%   Version 1.0.0.0
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Version History
%
% 1.0.0.0:
%   - Initial release.
%
% 1.1.0.0:
%   - Added support for paused files.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pausedData = 0;

%% Opening the file
% Popup the Open File UI. Also, process the file name, path, and extension
% for later use, and validate the entry.
if ~exist('fname', 'var')
    if ~ismac
        [fname, path] = getFile('*.ns*', 'Choose an NSx file...');
    else
        [fname, path] = getFile('*.*', 'Choose an NSx file...');
    end
    if fname == 0
        disp('No file was selected.');
        if nargout
            clear variables;
        end
        return;
    end
else
    if isempty(fileparts(fname))
        fname = which(fname);
    end
    [path,fname, fext] = fileparts(fname);
    fname = [fname fext];
    path  = [path '/'];
end
if fname==0
    return; 
end

%% Reading the file data
% Opening the file
FID          = fopen([path fname], 'r', 'ieee-le');
FileTypeID   = fread(FID, [1,8]   , '*char');
% Finding the begining of the data point in the file
if strcmpi(FileTypeID, 'NEURALSG')
    fseek(FID, 20, 'cof');
    ChannelCount  = double(fread(FID, 1, 'uint32=>double'));
    fread(FID, [ChannelCount 1], '*uint32');
    HeaderBytes   = ftell(FID);
elseif strcmpi(FileTypeID, 'NEURALCD')
    dataHeaderBytes = 9;
    BasicHeader   = fread(FID, 306, '*uint8');
    HeaderBytes   = double(typecast(BasicHeader(3:6), 'uint32'));
    ChannelCount  = double(typecast(BasicHeader(303:306), 'uint32'));
else
    disp('This version of NSxToHL can only read File Specs 2.1, 2.2 and 2.3');
    disp(['The selected file spec is ' NSx.MetaTags.FileSpec '.']);
    fclose(FID);
    clear variables;
    return;
end

% Skipping to the point where the data is saved, skipping the header info
fseek(FID, HeaderBytes, 'bof');


dataHeader = fread(FID, 9, '*uint8');
numberOfDataPoints = double(typecast(dataHeader(6:9), 'uint32'));

currentPos = ftell(FID);
fseek(FID, 0, 'eof');
endPos = ftell(FID);
lengthOfDataPoints = (endPos - currentPos)/(ChannelCount*2);
fseek(FID, currentPos, 'bof');

if lengthOfDataPoints > numberOfDataPoints
    pausedData = 1;
end

if not(pausedData)
    % Reading the header-less data
    disp(['Reading the data from file ' path fname '...']);
    OUTPUT = fread(FID, inf, '*int16');
    fclose(FID);
else
    disp('This version does not support paused files.');
    disp('Use splitNSx to split the data file into non-paused files first.');
    OUTPUT = -1;
end