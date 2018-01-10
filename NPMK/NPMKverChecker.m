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
% 1.0.2.0: January 10, 2018
%   - Added a clickable URL to the prompt.
%

gitHubURL = 'https://github.com/BlackrockMicrosystems/NPMK/releases/latest';

%% Check for the latest version fo NPMK
try
    FIDv = fopen('Versions.txt');
    verFile = fscanf(FIDv, '%s'); 
    fclose(FIDv);
    latestVersion = verFile(findstr('LATEST', verFile)+7:findstr('LATEST', verFile)+13);
    gitHubPage = urlread(gitHubURL);
    newVersionAvailable = findstr(latestVersion, gitHubPage);
    if isempty(newVersionAvailable)
        disp('A new version of NPMK may be available.');
        fprintf('Please visit <a href="%s">GitHub NPMK Page</a> to get the latest version.\n', gitHubURL)
    end
catch
end