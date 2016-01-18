function output = ntrodeGroups(ccf)

% ntrodeGroups
%
% This script takes in a CCF file and displays the information on the
% ntrode groups within the data file.
%
%   ccf:       Pass the CCF of interest. If no CCF is passed, the user will
%              be prompted to choose a CCF file.
%              DEFAULT: Will open Open File UI.
%    
%   Kian Torab
%   support@blackrockmicro.com
%   Blackrock Microsystems
%   Version 1.1.1.0
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Kian Torab
%   support@blackrockmicro.com
%   Blackrock Microsystems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Version History
%
% 1.0.0.0: October, 2014
%   - Initial release.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if ~exist('ccf', 'var')
    [ccf version] = openCCF;
end

if ~strcmpi(version, '3.9') || strcmpi(version, '3.8') || strcmpi(version, '3.7')
    disp('Not implemented yet.');
else
    for idx = 1:length(ccf.NTrodeInfo.NTrodeID)
        fprintf('NTrode group %d members: %s\n', idx, int2str(ccf.NTrodeInfo.NTrodeMembers{idx}));
    end
end

output = ccf.NTrodeInfo.NTrodeMembers;
