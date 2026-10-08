function [dat3, traces] = convert_continous_to_traces (cont, demo, out_fn,  window)
    dat1 = load(cont);
    dat2 = load(demo);
    dat3 = struct();

    channels = 1:size(dat1.datastart,1);
    
    traces_loc = dat1.com(2:end,3); %the first row is the intensity, all of the rest are the MEP locations
    n_traces = length(traces_loc);
    L = sum(abs(window))+1;
    traces = {}; 
    n_channels = length(channels);
    
    for channel_index = 1:n_channels %channel index
        channel = channels(channel_index);
        traces{channel_index} = zeros(n_traces, L); %trace = [trace_location - window(1) : trace_location : trace-location+ window(2)]
        for trace = 1:n_traces
            traces{channel_index}(trace,:) = extract_trace(dat1.data, ...
                                        channels, ...
                                        dat1.datastart, ...
                                        dat1.dataend, ...
                                        traces_loc(trace), ...
                                        window);
                                                
        end
    end


    
    

    dat3.datastart = zeros(n_channels, n_traces);
    dat3.dataend = zeros(n_channels,n_traces);

    dat3.data = zeros(1,n_traces * L * n_channels);
    
    indx_from = 1;

    for trace = 1:n_traces
        for channel_index = 1:n_channels
            indx_to = indx_from + L - 1;
            dat3.data(indx_from:indx_to) = traces{channel_index}(trace,:);
            dat3.datastart(channel_index,trace) = indx_from;
            dat3.dataend(channel_index,trace) = indx_to;
    
            indx_from = indx_to + 1;
        end
    end

    dat3.comtext = dat1.comtext(1,:);
    dat3.titles = dat1.titles(channels,:);
    dat3.rangemin = ones(n_channels,n_traces) .* repmat(dat1.rangemin,1,n_traces);
    dat3.rangemax = ones(n_channels,n_traces) .* repmat(dat1.rangemax,1,n_traces);
    dat3.unittext = dat1.unittext;
    dat3.unittextmap = ones(n_channels,n_traces) .* repmat(dat1.unittextmap,1,n_traces);
    dat3.blocktimes = ones(1,n_traces) .* dat1.blocktimes;
    dat3.tickrate = ones(1,n_traces) .* dat1.tickrate;
    dat3.samplerate = ones(n_channels,n_traces) .* repmat(dat1.samplerate,1,n_traces);
    dat3.firstsampleoffset = ones(n_channels,n_traces) .* repmat(dat1.firstsampleoffset,1,n_traces);
    dat3.com = dat1.com(1,:);
    
    save(out_fn,'-struct','dat3');
    
end

function trace = extract_trace(data, channel, data_start, data_end, location, window)
    

    win1 = max(location + window(1), data_start(channel));
    win2 = min(location + window(2), data_end(channel));

    trace = data(win1:win2);


end

% <== Change this code to generate more than one channel