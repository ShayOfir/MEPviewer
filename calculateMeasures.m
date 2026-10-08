% CALCUATEMEASURES - calculate some MEP measures

function [results,resultsTable] = calculateMeasures(data,block,params,touse)

delsys_delay=61.1; %ms, delsys delay for analogue connection
trig_pos=500; % ms, position of trigger in window (for 1sec windows, usually in middle)
latency_search_start=1;  % if see initial spike, delay search point for latency (default 0)
baseline_start=1500;
baseline_length=500;

min_mean=mink(data,3); % find top and bottom 3 values
min_mean=mean(min_mean);
max_mean=maxk(data,3);
max_mean=mean(max_mean);
ptp=max_mean-min_mean;

results.PeakToPeak = ptp; % Peak-to-peak
results.toUse = touse;

block_mean = mean(block,2);

block_mean_bs= block_mean(baseline_start:baseline_start+baseline_length); % baseline
block_mean_bs_mean = mean(block_mean_bs);
block_mean_bs_std = std(block_mean_bs);

% simple baseline correction
block_mean_bc = block_mean - block_mean_bs_mean;

% rectify the baseline-corrected data
block_mean_bc_abs=abs(block_mean_bc);

% calculate the latency (note that this is calcualted on a block-by-block basis)
latency = find((block_mean_bc_abs(latency_search_start:end)>params.std*block_mean_bs_std),1 )+latency_search_start;
results.latency_ms = latency ./ params.samplerate * 1000 -trig_pos-delsys_delay;

f = fields(results);
for k=1:numel(f)
    Measure{k,1} = f{k};
    Value(k,1) = results.(f{k});
end

resultsTable = table(Measure,Value);