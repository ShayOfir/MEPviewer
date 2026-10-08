% CALCUATEMEASURESBLOCK - calculate some MEP measures for a block (multiple trials, all with the same machine settings)

function [results,resultsTable,data] = calculateMeasuresBlock(block,params,touse,channels,latency_ms,endpoint_ms,baseline_start,baseline_end)

results = [];
resultsTable = [];
data = [];

if nargin<5 || isempty(latency_ms)
    latency_ms = -1 * ones(1,numel(touse));
end

if nargin<6 || isempty(endpoint_ms)
    endpoint_ms = -1 * ones(1,numel(touse));
end

if nargin<7 || isempty(baseline_start)
    baseline_start = -1 * ones(1,numel(touse));
end

if nargin<8 || isempty(baseline_end)
    baseline_end = -1 * ones(1,numel(touse));
end

if all(touse==0)
    results.PeakToPeak_individual = NaN;
    results.PeakToPeak_mean = NaN;
    results.PeakToPeak_std = NaN;
    results.PeakToPeak_SEmean = NaN;
    results.PeakToPeak = NaN;
    results.PeakToPeakJose = NaN;
    results.toUse = NaN;
    results.latency_regular_ms = NaN;
    results.latencyJose_ms = NaN;
    results.endpoint = NaN;
    results.endpoint_ms = NaN;
    results.area = NaN;
    f = fields(results);
    count = 0;
    for k=1:numel(f)
        if numel(results.(f{k}))==1 && ~strcmp(f{k},'PeakToPeak_individual') && ~strcmp(f{k},'toUse')
            count = count+1;
            Measure{count,1} = f{k};
            Value(count,1) = results.(f{k});
        end
    end
    resultsTable = table(Measure,Value);

    if nargout>2
        data.block_mean_bc_abs = NaN;
        data.block_mean_bc = NaN;
        data.block_mean = NaN;
        data.block_mean_bs_mean = NaN;
    end
    return
end

block_initial = block;
%size(block_initial)
latency_ms_initial = latency_ms;
endpoint_ms_initial = endpoint_ms;
baseline_start_initial = baseline_start;
baseline_end_initial = baseline_end;


% std of ptp in each trace
for c=1:2
    % extract only the appropriate movements (where touse = 1)
    to_use = find(touse(:,c));
    if isempty(to_use)
        fprintf('Could not find any traces to use... skipping\n')
        continue
    end

    block = block_initial(:,:,find(touse(:,c)));
    latency_ms = latency_ms_initial(:,find(touse(:,c)));
    endpoint_ms = endpoint_ms_initial(:,find(touse(:,c)));
    baseline_start = baseline_start_initial(:,find(touse(:,c)));
    baseline_end = baseline_end_initial(:,find(touse(:,c)));
    block_length = size(block,3);

    channel = channels(c);

    if channel > size(block,1)
        warning('Channel %d is not exist for this repetition. Using channel %d instead. If you need this specific channel, please repeat the procedure for each repetition and make sure to save the files under different names.\n',channel,size(block,1));
        channel = size(block,1);
    end
    for i=1:block_length
        min_mean_indiv=mean(mink(block(channel,:,i),3)); % find top 3 values
        max_mean_indiv=mean(maxk(block(channel,:,i),3));
        ptp_indiv(c,i)=max_mean_indiv-min_mean_indiv;
        if baseline_start(i)==-1 || baseline_end(i)==-1
            baseline_start_sample = params.baseline_start;
            baseline_end_sample = params.baseline_start+params.baseline_length;
        else
            % convert to sample number
            baseline_start_sample = round( (baseline_start(i) + params.trig_pos + params.delsys_delay) * params.samplerate / 1000);
            baseline_end_sample = round( (baseline_end(i) + params.trig_pos + params.delsys_delay) * params.samplerate / 1000);
        end
        min_bs_indiv(c,i) = mean(mink(block(channel,baseline_start_sample:baseline_end_sample,i),3));
        max_bs_indiv(c,i) = mean(maxk(block(channel,baseline_start_sample:baseline_end_sample,i),3));
        ptp_bs_indiv(c,i) = max_bs_indiv(c,i) - min_bs_indiv(c,i);
    end
    ptp_std(c)=std(ptp_indiv(c,:)); % SD
    ptp_SEmean(c)=sqrt(ptp_std(c).^2/block_length); % SE in mean
    ptp_mean(c)=mean(ptp_indiv(c,:)); % mean (individual ptp)
    ptp_bs_mean(c) = mean(ptp_bs_indiv(c,:));
    results.PeakToPeakBaseline(c) = ptp_bs_mean(c);
    
    if size(block,3)==1
        block_mean(c,:) = squeeze(block(channel,:,:)); % no need to take mean because there is just 1 repetition
    else
        block_mean(c,:) = mean(squeeze(block(channel,:,:)),2);
    end
    block_mean_bs(c,:) = block_mean(c,params.baseline_start:params.baseline_start+params.baseline_length); % baseline
    block_mean_bs_mean(c) = mean(block_mean_bs(c,:));
    block_mean_bs_std(c) = std(block_mean_bs(c,:));
    min_block_mean_bs(c) = mean(mink(block_mean_bs(c),3));
    max_block_mean_bs(c) = mean(maxk(block_mean_bs(c),3));
    ptp_bs(c) = max_block_mean_bs(c) - min_block_mean_bs(c);
    results.PeakToPeakMeanBaseline(c) = ptp_bs(c);

    % simple baseline correction
    block_mean_bc(c,:) = block_mean(c,:) - block_mean_bs_mean(c);

    % find simple peak-to-peak (ptp)
    min_mean(c,:)=mink(block_mean_bc(c,:),3); % find top 3 values
    min_mean(c,:)=mean(min_mean(c,:));
    max_mean(c,:)=maxk(block_mean_bc(c,:),3);
    max_mean(c,:)=mean(max_mean(c,:));
    ptp(c,:)=max_mean(c,:)-min_mean(c,:);

    % rectify the baseline-corrected data
    block_mean_bc_abs(c,:)=abs(block_mean_bc(c,:));

    % calculate the latency
    latency = find((block_mean_bc_abs(c,params.latency_search_start:end)>params.std*block_mean_bs_std(c)),1 )+params.latency_search_start;
    if isempty(latency)
        results.latency_regular_ms(c) = NaN;
    else
        results.latency_regular_ms(c) = latency ./ params.samplerate * 1000 - params.trig_pos - params.delsys_delay;
    end

    latency_search_end = params.latency_search_start + params.samplerate * 0.10; % look until +50 ms (provide until +100 ms)
    [results.PeakToPeakJose(c),results.latencyJose_ms(c)] = MEP_Features(block_mean_bc_abs(c,params.latency_search_start:latency_search_end)',params.samplerate,0);
    results.latencyJose_ms(c) = results.latencyJose_ms(c) + 10; % starts looking at +10ms

    endpoint = find(block_mean_bc_abs(c,latency+params.MEP_length:end)<params.std*block_mean_bs_std(c),5)+latency+params.MEP_length-1;  % check since might find the middle cross-point around zero
    if numel(endpoint)>1
        results.endpoint(c) = endpoint(1);
        results.endpoint_ms(c) = endpoint(1) ./ params.samplerate * 1000 - params.trig_pos - params.delsys_delay;
        area = trapz(latency:endpoint(1), block_mean_bc_abs(c,latency:endpoint(1))) / params.samplerate * 1000; % units of [ms.mV]
        results.area(c) = area;
    else
        results.endpoint(c) = NaN;
        results.endpoint_ms(c) = NaN;
        results.area(c) = NaN;
    end
end

results.PeakToPeak_individual = ptp_indiv;
results.PeakToPeak_mean = ptp_mean;
results.PeakToPeak_std = ptp_std;
results.PeakToPeak_SEmean = ptp_SEmean;
results.PeakToPeak = ptp;
results.toUse = touse;

f = fields(results);
count = -1;
for k=1:numel(f)
    if numel(results.(f{k}))==2 && ~strcmp(f{k},'PeakToPeak_individual') && ~strcmp(f{k},'toUse')
        count = count+2;
        Measure{count,1} = [f{k} '_1'];
        Value(count,1) = results.(f{k})(1);
        Measure{count+1,1} = [f{k} '_2'];
        Value(count+1,1) = results.(f{k})(2);
    end
end
resultsTable = table(Measure,Value);


if nargout>2
    data.block_mean_bc_abs = block_mean_bc_abs;
    data.block_mean_bc = block_mean_bc;
    data.block_mean = block_mean;
    data.block_mean_bs_mean = block_mean_bs_mean;
end