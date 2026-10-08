% FILTERDATA

function filterdata(filename)

if ~exist(filename,'file')
    error(['The file ' filename ' does not exist']);
end

data = load(filename);
samplerate = data.samplerate(1,1);

figure;
rows = 2;
cols = 2;
subplot(rows,cols,1);
plotfft(data.data,samplerate);

% Filter the data - from 1 Hz to 800 Hz
[B,A] = butter(2,[1/(samplerate/2) 450/(samplerate/2)],'bandpass');
filtered = filtfilt(B,A,data.data);

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

subplot(rows,cols,2);
plotfft(filtered,samplerate);

subplot(rows,cols,3);
plotfft(filtered2,samplerate);

subplot(rows,cols,4);
plotfft(filtered3,samplerate);

% save the file
data.data = filtered3;

[dirname, fn, extension] = fileparts(filename);

newname = [dirname '/F' fn extension];

save(newname,'-struct','data');

function plotfft(x,samplerate)

N = length(x);
X = fft(x);             % N-point FFT
X = X(1:floor(N/2)+1);  % keep non-negative frequencies

% Amplitude spectrum (scale for single-sided)
amp = abs(X)/N;
amp(2:end-1) = 2*amp(2:end-1);

% Frequency vector in Hz
f = (0:floor(N/2))*(samplerate/N);

% Plot
plot(f, amp)
xlabel('Frequency (Hz)')
ylabel('Amplitude')
title('Single-Sided Amplitude Spectrum');
xlim([0 151]);
