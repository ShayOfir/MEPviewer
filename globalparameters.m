% GLOBALPARAMETERS - set of global parameters

function params = globalparameters

params.delsys_delay=61.1; %ms, delsys delay for analogue connection
params.trig_pos=500; % ms, position of trigger in window (for 1sec windows, usually in middle)
params.latency_search_start = round((params.trig_pos + params.delsys_delay + 10)/1000 * 2000); % start 10 ms after the stimulation, in sample number
params.baseline_start=800; % ms, i.e. -100 ms 
params.baseline_length=200; % i.e., end at 0 ms
params.MEP_length=80; % assume that endpoint at least MEP_length pts (40, corresponds to 40/2=20ms) after latency

