function codeKeeper = syncPatternFinderNSx(filenameNSx)

%% Opening the file to get the header information
if ~exist('filenameNSx', 'var')
    NSx = openNSx('noread');
    % Determining the file name read
    filenameNSx = fullfile(NSx.MetaTags.FilePath, NSx.MetaTags.Filename);
else
    NSx = openNSx(filenameNSx, 'noread');
end

if ~isstruct(NSx)
    disp('Error reading the NSx file. Most likely the file name did not exist.');
    return;
end

%% Calculating the variables for the sync signal
% Figuring out the channel that recorded the sync pulse. This assums that
% the sync pulse was recorded on analog input 16 on the Cerebus or analog
% input 3 on the Direct system.
numberOfChannels = NSx.MetaTags.ChannelCount;

% Calculating the maximum number of points to read
maxPacketsToRead = 30 * NSx.MetaTags.SamplingFreq;
if maxPacketsToRead > NSx.MetaTags.DataPoints
    maxPacketsToRead = NSx.MetaTags.DataPoints;
end

%% Reading the sync signal
NSxSync = openNSx(filenameNSx, ['c:' num2str(numberOfChannels)], ['t:1:' num2str(maxPacketsToRead)], 'read');

codeKeeper = syncPatternDetectNSx(NSxSync.Data(1,:));