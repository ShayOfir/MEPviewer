% CALCUATEMEASURES - calculate some MEP measures for a single trial (a single MEP)

function [results,resultsTable] = calculateMeasuresTrial_old(data, alldata, block, params, touse, channels, isMEP, latency_ms, endpoint_ms, baseline_start, baseline_end)

if nargin<8 || isempty(latency_ms)
    latency_ms = [-1 -1];
end

if nargin<9 || isempty(endpoint_ms)
    endpoint_ms = [-1 -1];
end

if nargin<10 || isempty(baseline_start)
    baseline_start = [-1 -1];
end

if nargin<11 || isempty(baseline_end)
    baseline_end = [-1 -1];
end

if isscalar(latency_ms)
    latency_ms = [latency_ms latency_ms];
end

if isscalar(endpoint_ms)
    endpoint_ms = [endpoint_ms endpoint_ms];
end

if isscalar(baseline_start)
    baseline_start = [baseline_start baseline_start];
end

if isscalar(baseline_end)
    baseline_end = [baseline_end baseline_end];
end

if isscalar(touse)
    touse = [touse touse];
end

for c=1:2
    if baseline_start(c)==-1
        baseline_start_sample = params.baseline_start;
    else
        % convert to sample number
        baseline_start_sample = round( (baseline_start(c) + params.trig_pos + params.delsys_delay) * params.samplerate / 1000);
    end

    if baseline_end(c)==-1
        baseline_end_sample = params.baseline_start+params.baseline_length;
    else
        baseline_end_sample = round( (baseline_end(c) + params.trig_pos + params.delsys_delay) * params.samplerate / 1000);
    end
    
    channel = channels(c);
    
    % this handles an error that occurs when there is a mismatch between
    % the channels items in the different coils
    if channel > size(data,1)
        warning('Channel %d is not exist for this repetition. Using channel %d instead. If you need this specific channel, please repeat the procedure for each repetition and make sure to save the files under different names.\n',channel,size(data,1));
        channel = size(data,1);
    end

    min_mean(c)=mean(mink(data(channel,:),3)); % find top and bottom 3 values
    max_mean(c)=mean(maxk(data(channel,:),3));
    ptp(c)=max_mean(c)-min_mean(c);


    % Need the block for the baseline
    bs = block(channel,baseline_start_sample:baseline_end_sample); % baseline
    bs_mean(c) = mean(bs);
    bs_std(c) = std(bs);

    % simple baseline correction
    bc(c,:) = data(channel,:) - bs_mean(c);

    % rectify the baseline-corrected data
    bc_abs(c,:) = abs(bc(c,:));

    % From Hussain et al., 2019
    % https://doi.org/10.1093/cercor/bhy255
    %
    % EMG signal power was calculated in a −25 to −5 ms prestimulus window, and trials in which more than half of the samples exceeded an upper limit
    % (defined as the 75th percentile+3*InterQuartile Range of EMG power) were excluded due to excessive EMG background activity.
    %
    % It is not clearly defined what they mean by "power", we will use absolute
    % value of EMG
    
    abs_all = abs(alldata(channel,:) - mean(alldata(channel,:)));
    cutoff = quantile(abs_all,0.75) + 3 * iqr(abs_all);
    EMGwindow = round(((params.trig_pos + params.delsys_delay) + [-25 5]) ./ 1000 * params.samplerate);
    results.proportionNoisy(c) = mean(abs_all(EMGwindow(1):EMGwindow(2)) > cutoff);

    % From Schilberg et al., 2021
    % https://doi.org/10.1371/journal.pone.0255815
    %
    % To prevent any effects of pre-TMS muscle contraction on MEP amplitudes, all single trials with a pre-pulse peak-to-peak resting EMG amplitude that
    % were further than 3 times away from the median absolute distance of every point to the median for a time window of 100ms prior to TMS, were excluded
    % from the analysis [27].
    bs_abs = abs(bs);
    baseline_median = median(bs_abs);
    p2p_baseline = max(bs) - min(bs);
    results.relativeMaxPeakToPeakBaseline(c) = p2p_baseline / (3*baseline_median);

    latency_search_end = params.latency_search_start + params.samplerate * 0.10; % look until +50 ms (provide until +100 ms)
    [results.PeakToPeakJose(c),results.latencyJose_ms(c)] = MEP_Features(data(channel,params.latency_search_start:latency_search_end)',params.samplerate,0);
    results.latencyJose_ms(c) = results.latencyJose_ms(c) + 10; % starts looking at +10ms

    % calculate the latency
    latency = find( (bc_abs(c,params.latency_search_start:end) > params.std*bs_std(c)) ,1 )+params.latency_search_start;
    if isempty(latency)
        results.latency_regular(c) = NaN;
        results.latency_regular_ms(c) = NaN;
    else
        results.latency_regular(c) = latency;
        results.latency_regular_ms(c) = latency ./ params.samplerate * 1000 - params.trig_pos - params.delsys_delay;
    end

    if latency_ms(c)==-1 % i.e. not overridden
        results.latency_semi_manual_ms(c) = results.latencyJose_ms(c);
        results.latency_semi_manual(c) = round( (results.latency_regular_ms(c) + params.trig_pos + params.delsys_delay) * params.samplerate / 1000);
    else
        results.latency_semi_manual_ms(c) = latency_ms(c);
        results.latency_semi_manual(c) = round( (results.latency_semi_manual_ms(c) + params.trig_pos + params.delsys_delay) * params.samplerate / 1000);
        latency = results.latency_semi_manual(c);
    end

    if isempty(results.latency_regular(c)) || isMEP == 0
        results.latency_regular(c) = NaN;
        results.latency_regular_ms(c) = NaN;
    end

    if endpoint_ms(c)==-1 % i.e. not overridden
        endpoint = find(bc_abs(c,latency+params.MEP_length:end)<params.std*bs_std(c),5)+latency+params.MEP_length-1;  % check since might find the middle cross-point around zero
        if numel(endpoint)>1
            results.endpoint(c) = endpoint(1);
            results.endpoint_ms(c) = endpoint(1) ./ params.samplerate * 1000 - params.trig_pos - params.delsys_delay;
            area = trapz(latency:endpoint(1), bc_abs(c,latency:endpoint(1))) / params.samplerate * 1000; % units of [ms.mV]
            results.area(c) = area;
        else
            results.endpoint(c) = NaN;
            results.endpoint_ms(c) = NaN;
            results.area(c) = NaN;
        end
    else
        results.endpoint_ms(c) = endpoint_ms(c);
        results.endpoint(c) = round( (results.endpoint_ms(c) + params.trig_pos + params.delsys_delay) * params.samplerate / 1000);
        endpoint = results.endpoint(c);
        results.area(c) = trapz(latency:endpoint(1), bc_abs(latency:endpoint(1))) / params.samplerate * 1000; % units of [ms.mV]
    end

    results.PeakToPeak(c) = ptp(c); % Peak-to-peak
    results.toUse(c) = touse(c);

end

f = fields(results);
count=-1;
for k=1:numel(f)
    if numel(results.(f{k}))==2
        count = count+2;
        for c=1:2
            Measure{count+c-1,1} = [f{k} num2str(c)];
            Value(count+c-1,1) = results.(f{k})(c);
        end
    end
end

resultsTable = table(Measure,Value);
