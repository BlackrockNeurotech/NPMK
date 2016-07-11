function splitNSxNTrode

% splitNEVNTrode
% 
% Opens and splits an NEV file based on its NTrode groups. It depends on
% openCCF file.
%
% Use splitNEVNTrode
% 
% This function does not take any inputs.
%
%   Example 1: 
%   splitNEVNTrode;
%
%   In the example above, the user will be prompted to select a CCF file
%   first. The CCF contains the ntrode grouping infromation. Then the user
%   will be prompted to select a NEV file. The script will then split the
%   NEV file into smaller NEV files containing channels in given ntrode
%   groups. For example, if ntrode group one consists of channels 1,3,5,
%   and 12, then using splitNEVNTrode will split the file into a smaller
%   NEV files that contains those channels only. If there are multiple
%   ntrodes then the files will split into multiple smaller files, equal in
%   number of the ntrode groups.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Kian Torab
%   support@blackrockmicro.com
%   Blackrock Microsystems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Version History
%
% 1.0.0.0: January 18, 2016
%   - Initial release.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Validating input parameter
ccf = openCCF;
splitCount = length(ccf.NTrodeInfo.NTrodeID);

% Getting the file name
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
fext = fname(end-3:end);
    
% Loading the file    
for idx = 1:splitCount
    % Determining whether tetrode channel is recorded and valid in NSx
    tetrodeChannels = ccf.NTrodeInfo.NTrodeMembers{idx};
    NEV = openNEV([path, fname], ['c:' num2str(tetrodeChannels)]);
    newFileName = [path fname(1:end-4) '-tet' sprintf('%03d', idx) fname(end-3:end)];
    saveNEV(NEV, newFileName, 'noreport');
end