function plotfft(x,samplerate,varargin)

N = length(x);
X = fft(x);             % N-point FFT
X = X(1:floor(N/2)+1);  % keep non-negative frequencies

% Amplitude spectrum (scale for single-sided)
amp = abs(X)/N;
amp(2:end-1) = 2*amp(2:end-1);

% Frequency vector in Hz
f = (0:floor(N/2))*(samplerate/N);

% Plot
if ~isempty(varargin)
    color = varargin{1};
else
    color = 'k';
end
plot(f, amp, color)
xlabel('Frequency (Hz)')
ylabel('Amplitude')
title('Single-Sided Amplitude Spectrum');
xlim([0 151]);