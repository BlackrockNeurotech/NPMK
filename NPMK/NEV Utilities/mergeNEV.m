function [NEV] = mergeNEV()

%% 
% Saves a new NEV file that contains event data from one NEV and spike data
% from another
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Use: mergeNEV()

%mergeNEV version = '1.0.0.0';

%Author: Nick Halper
%Contact: nhalper@blackrockmicro.com

%% 
% Choose file that contains event data


uiwait(msgbox('Choose the file containing event data (comments, digital inputs, etc) that you want to keep','Choose Event Data','modal'));
EventNEV = openNEV();

uiwait(msgbox('Choose the file containing sorted spike data that you want to keep','Choose Spike Data','modal'));
SpikeNEV = openNEV();

EventNEV.MetaTags = SpikeNEV.MetaTags;
EventNEV.ElectrodesInfo = SpikeNEV.ElectrodesInfo;
EventNEV.Data.Spikes = SpikeNEV.Data.Spikes;

NEV = EventNEV;

[FileName,PathName] = uiputfile('.nev');


SavePath = fullfile(PathName,FileName);

saveNEV(NEV,fullfile(PathName,FileName));

end

