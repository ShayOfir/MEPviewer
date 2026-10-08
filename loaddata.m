% LOADDATA - load the data - currently only works for .mat files
% In this version, we load all channels

function data = loaddata(subject)

if strcmp(subject(end-3:end),'.mat')
    subject = subject(1:end-4);
end

in_file = load([subject '.mat']);


if ~isfield(in_file,'com')
    errordlg(['The mat file ' subject '.mat does not have a field com so cannot continute to load it']);
    data = NaN;
    return
end

if isempty(in_file.com)
    errordlg(['The mat file ' subject '.mat has an empty field com so cannot continute to load it']);
    data = NaN;
    return
end


numchannels = size(in_file.titles,1);
channelnames = in_file.titles;

blockstart = in_file.com(:,2);
blockend = [blockstart(2:end)-1; size(in_file.datastart,2);];

% deal with different record lengths (2002,2003, etc) by finding
% max of array and padding to that value (hope that signal aligns!)
max_record_length=max(max(in_file.dataend-in_file.datastart));
% 'e' contains the data from each record (approx 2000x40) for each channel
e=zeros(numchannels,max_record_length,size(in_file.datastart,2));
alldata = zeros(numchannels,max_record_length*size(in_file.datastart,2));
% Note: e.g., the 1 in datastart(1,i) since there may be 3 channels of data stored
for channel=1:numchannels
    last = 0;
    for i=1:size(in_file.datastart,2)
        if (in_file.datastart(channel,i) == -1)
            continue
        end
        record_length=in_file.dataend(channel,i)-in_file.datastart(channel,i)+1;
        e(channel,1:record_length,i)=in_file.data(in_file.datastart(channel,i):in_file.dataend(channel,i));
        alldata(channel,last+1:last+record_length)=in_file.data(in_file.datastart(channel,i):in_file.dataend(channel,i));
        last = last+record_length;
    end
end

% fill up blocks
% note: block size has to be consistent (i.e., can't have one block
% of 6 records and another of 5) as otherwise causes problem with 2nd index!
for j=1:length(blockstart)
    block{j}=e(:,:,blockstart(j):blockend(j)); % cell so allows different block sizes
end

data.alldata = in_file;
data.alldata.data = alldata;
% if std(in_file.samplerate(:))~=0
%     error('The sample rate does not seem to be constant across the repetitions');
% end
data.samplerate = in_file.samplerate(1,1);
data.block = block;
data.record_length = record_length;
data.comtext = in_file.comtext;
data.e = e;
data.channelnames = cellstr(channelnames);

for k=1:size(in_file.comtext,1)
    r = regexp(in_file.comtext(k,:),'([^\s=]+)','tokens');
    description{k,1} = in_file.comtext(k,:);
    if numel(r)>=1
        if r{1}{1}(end)=='%'
            r{1}{1} = r{1}{1}(1:end-1);
        end
        percent_threshold(k,1) = str2double(r{1}{1});
    else
        percent_threshold(k,1) = NaN;
    end
    if numel(r)>=2
        machine_setting(k,1) = str2double(r{2}{1});
    else
        machine_setting(k,1) = NaN;
    end
end
% how many std from the mean is needed to mark the start of the MEP
% Default is 2, this can be changed if necessary on a block-by-block basis
n_std = 2 * ones(numel(blockstart),1);
blocknumber = (1:numel(blockstart))';
% pad with empty descriptions at the beginning if necessary
if numel(description)<numel(blocknumber)
    toadd = numel(blocknumber) - numel(description);
    description(toadd+1:numel(description)+toadd) = description;
    for k=1:toadd
        description{k} = repmat(' ',1,numel(description{end}));
    end
    percent_threshold(toadd+1:numel(percent_threshold)+toadd) = percent_threshold;
    percent_threshold(1:toadd) = NaN;
    
    machine_setting(toadd+1:numel(machine_setting)+toadd) = machine_setting;
    machine_setting(1:toadd) = NaN;
end
data.blockdescriptions = table(blocknumber,description,percent_threshold,machine_setting,blockstart,blockend,n_std);
