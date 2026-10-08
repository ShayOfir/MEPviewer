% CALCUATEMEASURES2 - calculate some MEP measures for a single trial (a single MEP)
% Uses the Garvey method (MCD-based threshold with minimum duration criterion)
% for MEP onset and offset detection, with fallback to simple threshold,
% and final fallback to a fixed default duration.

function [results,resultsTable] = calculateMeasuresTrial(data, alldata, block, params, touse, channels, isMEP, latency_ms, endpoint_ms, baseline_start, baseline_end)

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
if isscalar(latency_ms),     latency_ms    = [latency_ms    latency_ms];    end
if isscalar(endpoint_ms),    endpoint_ms   = [endpoint_ms   endpoint_ms];   end
if isscalar(baseline_start), baseline_start= [baseline_start baseline_start];end
if isscalar(baseline_end),   baseline_end  = [baseline_end  baseline_end];  end
if isscalar(touse),          touse         = [touse         touse];         end

% -------------------------------------------------------------------------
% Hard-coded Garvey method parameters
% -------------------------------------------------------------------------
GARVEY_MCD_CONSTANT       = 8;      % multiplier on MCD for threshold
GARVEY_MIN_ONSET_DUR_MS   = 2.0;    % min consecutive ms above threshold for onset
GARVEY_MIN_OFFSET_DUR_MS  = 2.0;    % min consecutive ms below threshold for offset
GARVEY_ONSET_FIFTY_PCT    = true;   % true = 50% rule; false = 100% rule
GARVEY_OFFSET_FIFTY_PCT   = true;
DEFAULT_MEP_DURATION_MS   = 120;    % fallback MEP duration (ms) when both methods fail
% -------------------------------------------------------------------------

for c = 1:2
    if baseline_start(c) == -1
        baseline_start_sample = params.baseline_start;
    else
        baseline_start_sample = round((baseline_start(c) + params.trig_pos + params.delsys_delay) * params.samplerate / 1000);
    end
    if baseline_end(c) == -1
        baseline_end_sample = params.baseline_start + params.baseline_length;
    else
        baseline_end_sample = round((baseline_end(c) + params.trig_pos + params.delsys_delay) * params.samplerate / 1000);
    end

    channel = channels(c);
    if channel > size(data,1)
        warning('Channel %d does not exist. Using channel %d instead.\n', channel, size(data,1));
        channel = size(data,1);
    end

    min_mean(c) = mean(mink(data(channel,:), 3));
    max_mean(c) = mean(maxk(data(channel,:), 3));
    ptp(c)      = max_mean(c) - min_mean(c);

    % baseline from the block-mean (consistent with calculateMeasuresBlock)
    bs         = block(channel, baseline_start_sample:baseline_end_sample);
    bs_mean(c) = mean(bs);
    bs_std(c)  = std(bs);

    % baseline correction and rectification
    bc(c,:)     = data(channel,:) - bs_mean(c);
    bc_abs(c,:) = abs(bc(c,:));

    % Hussain et al. 2019 noisy trial metric
    abs_all   = abs(alldata(channel,:) - mean(alldata(channel,:)));
    cutoff    = quantile(abs_all, 0.75) + 3 * iqr(abs_all);
    EMGwindow = round(((params.trig_pos + params.delsys_delay) + [-25 5]) ./ 1000 * params.samplerate);
    results.proportionNoisy(c) = mean(abs_all(EMGwindow(1):EMGwindow(2)) > cutoff);

    % Schilberg et al. 2021 baseline peak-to-peak metric
    bs_abs_vec      = abs(bs);
    baseline_median = median(bs_abs_vec);
    p2p_baseline    = max(bs) - min(bs);
    results.relativeMaxPeakToPeakBaseline(c) = p2p_baseline / (3 * baseline_median);

    % Jose method (unchanged) — always computed, used as onset candidate below
    latency_search_end = params.latency_search_start + params.samplerate * 0.10;
    [results.PeakToPeakJose(c), results.latencyJose_ms(c)] = ...
        MEP_Features(data(channel, params.latency_search_start:latency_search_end)', params.samplerate, 0);
    results.latencyJose_ms(c) = results.latencyJose_ms(c) + 10;
    jose_latency_sample = round((results.latencyJose_ms(c) + params.trig_pos + params.delsys_delay) * params.samplerate / 1000);

    % Garvey MCD threshold — scalar for this single trial's baseline vector
    bs_diff_vec      = abs(bs_abs_vec(1:end-1) - bs_abs_vec(2:end));
    mcd_val          = mean(bs_diff_vec);
    mcd_mean_val     = mean(bs_abs_vec);
    garvey_threshold = mcd_mean_val + GARVEY_MCD_CONSTANT * mcd_val;

    % -----------------------------------------------------------------
    % ONSET DETECTION
    % -----------------------------------------------------------------
    if latency_ms(c) == -1
        min_onset_samples = max(1, round(GARVEY_MIN_ONSET_DUR_MS * params.samplerate / 1000));
        search_data_on    = bc_abs(c, params.latency_search_start:end);

        % 1) Garvey onset
        latency_local = findGarveyOnset(search_data_on, garvey_threshold, min_onset_samples, GARVEY_ONSET_FIFTY_PCT);

        % 2) Simple threshold fallback for onset
        if isnan(latency_local)
            fb = find(search_data_on > params.std * bs_std(c), 1);
            if ~isempty(fb)
                latency_local = fb;
            end
        end

        % Convert local index (within search window) to absolute sample index
        if ~isnan(latency_local)
            latency_garvey = latency_local + params.latency_search_start - 1;
        else
            latency_garvey = NaN;
        end

        % 3) Take the minimum (earliest) onset across Garvey and Jose
        candidates = [latency_garvey, jose_latency_sample];
        candidates = candidates(~isnan(candidates));
        if isempty(candidates)
            latency = NaN;
            results.latency_regular(c)    = NaN;
            results.latency_regular_ms(c) = NaN;
        else
            latency = min(candidates);
            results.latency_regular(c)    = latency;
            results.latency_regular_ms(c) = latency / params.samplerate * 1000 - params.trig_pos - params.delsys_delay;
        end

        results.latency_semi_manual_ms(c) = results.latency_regular_ms(c);
        results.latency_semi_manual(c)    = latency;

    else
        % manually overridden latency
        results.latency_regular(c)        = NaN;
        results.latency_regular_ms(c)     = NaN;
        results.latency_semi_manual_ms(c) = latency_ms(c);
        results.latency_semi_manual(c)    = round((latency_ms(c) + params.trig_pos + params.delsys_delay) * params.samplerate / 1000);
        latency = results.latency_semi_manual(c);
    end

    if isMEP == 0
        results.latency_regular(c)    = NaN;
        results.latency_regular_ms(c) = NaN;
    end

    % -----------------------------------------------------------------
    % OFFSET DETECTION
    % -----------------------------------------------------------------
    if endpoint_ms(c) == -1
        if isnan(latency)
            results.endpoint(c)        = NaN;
            results.endpoint_ms(c)     = NaN;
            results.endpoint_method(c) = NaN;
            results.area(c)            = NaN;
        else
            min_offset_samples = max(1, round(GARVEY_MIN_OFFSET_DUR_MS * params.samplerate / 1000));
            search_start        = latency + params.MEP_length;

            % maximum allowed endpoint (DEFAULT_MEP_DURATION_MS from onset)
            ep_max = min(latency + round(DEFAULT_MEP_DURATION_MS * params.samplerate / 1000), size(bc_abs,2));

            if search_start > length(bc_abs(c,:))
                ep_garvey = NaN;
                ep_simple = NaN;
            else
                search_data_off = bc_abs(c, search_start:end);

                % 1) Garvey offset
                ep_local = findGarveyOffset(search_data_off, garvey_threshold, min_offset_samples, GARVEY_OFFSET_FIFTY_PCT);
                if ~isnan(ep_local)
                    ep_garvey = ep_local + search_start - 1;
                else
                    ep_garvey = NaN;
                end

                % 2) Simple threshold offset (original method)
                ep_simple_local = find(search_data_off < params.std * bs_std(c), 5);
                if numel(ep_simple_local) > 1
                    ep_simple = ep_simple_local(1) + search_start - 1;
                else
                    ep_simple = NaN;
                end
            end

            % 3) Choose: Garvey > simple > default duration
            %    each candidate is only accepted if it does not exceed ep_max
            if ~isnan(ep_garvey) && ep_garvey <= ep_max
                ep = ep_garvey;
                results.endpoint_method(c) = 1; % 1 = Garvey
            elseif ~isnan(ep_simple) && ep_simple <= ep_max
                ep = ep_simple;
                results.endpoint_method(c) = 2; % 2 = simple threshold
            else
                ep = ep_max;
                results.endpoint_method(c) = 3; % 3 = default duration
            end

            results.endpoint(c)    = ep;
            results.endpoint_ms(c) = ep / params.samplerate * 1000 - params.trig_pos - params.delsys_delay;
            results.area(c)        = trapz(latency:ep, bc_abs(c, latency:ep)) / params.samplerate * 1000;
        end
    else
        % manually overridden endpoint
        results.endpoint_ms(c)     = endpoint_ms(c);
        results.endpoint(c)        = round((endpoint_ms(c) + params.trig_pos + params.delsys_delay) * params.samplerate / 1000);
        results.endpoint_method(c) = 0; % 0 = manual
        ep = results.endpoint(c);
        if ~isnan(latency)
            results.area(c) = trapz(latency:ep, bc_abs(c, latency:ep)) / params.samplerate * 1000;
        else
            results.area(c) = NaN;
        end
    end

    results.PeakToPeak(c) = ptp(c);
    results.toUse(c)      = touse(c);
end

f = fields(results);
count = -1;
for k = 1:numel(f)
    if numel(results.(f{k})) == 2
        count = count + 2;
        for c = 1:2
            Measure{count+c-1, 1} = [f{k} num2str(c)];
            Value(count+c-1, 1)   = results.(f{k})(c);
        end
    end
end
resultsTable = table(Measure, Value);

end % main function


% =========================================================================
% LOCAL HELPER: Garvey onset
% Returns 1-based index within search_data of the onset sample, or NaN.
% =========================================================================
function idx = findGarveyOnset(search_data, threshold, min_samples, fifty_pct_rule)
    idx = NaN;
    n   = length(search_data);
    for i = 2:n
        if search_data(i) > threshold && search_data(i-1) <= threshold
            dur_end = i + min_samples - 1;
            if dur_end > n
                return  % too close to end — no valid onset
            end
            window = search_data(i:dur_end);
            above  = sum(window > threshold);
            if fifty_pct_rule
                if above / min_samples >= 0.5
                    idx = i;
                    return
                end
            else
                if above == min_samples
                    idx = i;
                    return
                end
            end
        end
    end
end


% =========================================================================
% LOCAL HELPER: Garvey offset
% Returns 1-based index within search_data of the offset sample, or NaN.
% =========================================================================
function idx = findGarveyOffset(search_data, threshold, min_samples, fifty_pct_rule)
    idx = NaN;
    n   = length(search_data);
    for i = 2:n
        if search_data(i) < threshold && search_data(i-1) >= threshold
            dur_end = i + min_samples - 1;
            if dur_end > n
                return  % too close to end — no valid offset
            end
            window = search_data(i:dur_end);
            below  = sum(window < threshold);
            if fifty_pct_rule
                if below / min_samples >= 0.5
                    idx = i;
                    return
                end
            else
                if below == min_samples
                    idx = i;
                    return
                end
            end
        end
    end
end