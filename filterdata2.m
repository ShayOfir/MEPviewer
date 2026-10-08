% FILTERDATA2

function filterdata2(filename)

    if ~exist(filename,'file')
        error(['The file ' filename ' does not exist']);
    end
    
    data = load(filename);
    samplerate = data.samplerate(1,1);
    
    % figure;
    % rows = 2;
    % cols = 2;
    % subplot(rows,cols,1);
    % plotfft(data.data,samplerate);
    
    filtered_data = zeros(1,length(data.data));

    [n_rows, n_cols] = size(data.datastart);
    for j=1:n_rows
        for k=1:n_cols
            start_pos = data.datastart(j,k);
            end_pos = data.dataend(j,k);
            sub_data = data.data(data.datastart(j,k):data.dataend(j,k));
            filtered_sub = filter_vec(sub_data, samplerate);
            filtered_data(start_pos : end_pos) = filtered_sub;
        end
    end

    % save the file
    data.data = filtered_data;

    [dirname, fn, extension] = fileparts(filename);

    newname = [dirname '/FF' fn extension];

    save(newname,'-struct','data');

end


function y = filter_vec (x, samplerate)
    % Filter the data - from 1 Hz to 800 Hz
    [B,A] = butter(2,[1/(samplerate/2) 800/(samplerate/2)],'bandpass');
    filtered = filtfilt(B,A,x);

    f0 = 50;                % Frequency to remove
    Q  = 100;                % Quality factor (higher = narrower notch)
    
    % 1. Design the filter
    % Normalized frequency (0 to 1, where 1 is Nyquist)
    wo = f0 / (samplerate/2);  
    bw = wo / Q;
    [b, a] = iirnotch(wo, bw);

    % 2. Apply the filter
    % Use 'filtfilt' for zero-phase distortion (essential for EEG timing)
    filtered2 = filtfilt(b, a, filtered);

    %Also remove 100 Hz
    f0 = 100;
    wo = f0 / (samplerate/2);  
    bw = wo / Q;
    [b, a] = iirnotch(wo, bw);
    filtered3 = filtfilt(b, a, filtered2);

    y = filtered3;
end 

% subplot(rows,cols,2);
% plotfft(filtered,samplerate);
% 
% subplot(rows,cols,3);
% plotfft(filtered2,samplerate);
% 
% subplot(rows,cols,4);
% plotfft(filtered3,samplerate);



