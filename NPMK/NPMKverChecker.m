function NPMKverChecker()

% NPMKverChecker
%
% Checks to see if there is a newer version of NPMK is available for
% download.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Use NPMKverChecker
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Kian Torab
%   support@blackrockmicro.com
%   Blackrock Microsystems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Version History
%
% 1.0.0.0: September 13, 2017
%   - Initial release.
%
% 1.0.1.0: September 13, 2017
%   - Fixed a crash in case there is no Internet connection.
%

%% Check for the latest version fo NPMK
try
    FIDv = fopen('Versions.txt');
    verFile = fscanf(FIDv, '%s'); 
    fclose(FIDv);
    latestVersion = verFile(findstr('LATEST', verFile)+7:findstr('LATEST', verFile)+13);
    gitHubPage = urlread('https://github.com/BlackrockMicrosystems/NPMK/releases/latest');
    newVersionAvailable = findstr(latestVersion, gitHubPage);
    if isempty(newVersionAvailable)
        disp('A new version of NPMK may be available.');
        disp('Please visit https://github.com/BlackrockMicrosystems/NPMK/releases/latest to get the latest version.');
    end
catch
end