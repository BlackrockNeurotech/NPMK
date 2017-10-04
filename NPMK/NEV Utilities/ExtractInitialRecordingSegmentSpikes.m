function NEVData=ExtractInitialRecordingSegmentSpikes

[fname,dname]=uigetfile({'*.nev;*.ns*','BR Formats';...
    '*.*','All Files' },'Select data file');

NSxInfo = openNSx('noread', [dname fname(1:end-3) 'ns6']);
NEVData = openNEV('nosave',[dname fname(1:end-3) 'nev']);

initialSectionTimeIdx=[find(NEVData.Data.Spikes.TimeStamp>=NSxInfo.MetaTags.Timestamp(1),1),...
    find(NEVData.Data.Spikes.TimeStamp<=NSxInfo.MetaTags.Timestamp(2),1,'last')];

NEVData.MetaTags.DataDuration=diff(NEVData.Data.Spikes.TimeStamp(initialSectionTimeIdx))+1;
NEVData.MetaTags.DataDurationSec=NEVData.MetaTags.DataDuration/NEVData.MetaTags.SampleRes;

disp(['initial recording segment lasted ' num2str(NEVData.MetaTags.DataDurationSec/60) 'mn']);

NEVData.Data.Spikes.TimeStamp=NEVData.Data.Spikes.TimeStamp(initialSectionTimeIdx(1):initialSectionTimeIdx(2));
NEVData.Data.Spikes.Electrode=NEVData.Data.Spikes.Electrode(initialSectionTimeIdx(1):initialSectionTimeIdx(2));
NEVData.Data.Spikes.Unit=NEVData.Data.Spikes.Unit(initialSectionTimeIdx(1):initialSectionTimeIdx(2));
NEVData.Data.Spikes.Waveform=NEVData.Data.Spikes.Waveform(:,initialSectionTimeIdx(1):initialSectionTimeIdx(2));

saveNEV(NEVData, [dname fname(1:end-4) '_InitialRecordingSegment.nev'], 'noreport')