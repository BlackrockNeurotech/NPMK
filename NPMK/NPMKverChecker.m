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
persistent new_version
gitHubURL = 'https://github.com/BlackrockMicrosystems/NPMK/releases/latest';

if isempty(new_version)
    %% Check for the latest version fo NPMK
    try
        % Local copy
        FIDv = fopen('Versions.txt');
        verFile = fscanf(FIDv, '%s');
        fclose(FIDv);
        latestVersion = verFile(findstr('LATEST', verFile)+7:findstr('LATEST', verFile)+13);

        % Remote copy
        gitHubPage = urlread(gitHubURL);
        gitVersion = regexp(gitHubPage, '\<title\>.*(\d+\.\d+\.\d+\.\d+).*\</title\>', 'tokens');
        gitVersion = gitVersion{1}{1};
   
        new_version = compare_semver(gitVersion, latestVersion) == -1;
    catch
    end
end

if new_version
    disp('A new version of NPMK may be available.');
    fprintf('Please visit <a href="%s">GitHub NPMK Page</a> to get the latest version.\n', gitHubURL)
end
end

function cmp = compare_semver(a, b)
%% COMPARE_SEMVAR: Compare two "semantic version" strings
% INPUT:
% - a, b: Semantic version strings (as char arrays)
% OUTPUT:
% - cmp: Comparison value (like C's strcmp)
%    -1 if a is more recent than b
%    0  if a and b are the same
%    1  if b is more recent than a
% NOTES:
% - In brief, semantic versions are MAJOR.MINOR.PATCH (etc). These are
% slightly different from "regular" decimals, in that version 1.2 is
% newer than 1.1, but 17 minor releases older than 1.19
% - This doesn't yet handle pre-release or other metadata stuff

a = strsplit(a, '.');
b = strsplit(b, '.');

if length(b) > length(a)
    tmp = a;
    a=b;
    b=tmp;
end

while length(a) > length(b)
    b{end+1} = 0;
end
a = str2double(a);
b = str2double(b);

for ii=1:length(a)
    if a(ii) > b(ii)
        cmp = -1;
        return
    elseif a(ii) < b(ii)
        cmp = 1;
        return;
    end
end
cmp = 0;
end
