% Extract MEP features
% Based on the article:
% Automatic selection and feature extraction of motor-evoked potentials by transcranial magnetic stimulation in stroke patients
% Tecuapetla-Trejo et al., 2021
% https://doi.org/10.1007/s11517-021-02315-z

%Input 
% X: Matrix of m×n which contains m elements (EMG signal samples) of n trials that comprise one TMS session
% Fs: Scalar containing sampling rate (must be of at least 468Hz)
% K: Scalar within the 0 to n−1 range, which indicates how many trials will be discarded
%Output 
% MEPAmp: Vector of n elements with the calculated MEP amplitudes of each trial (μV)
% MEPLat: Vector of n elements with the calculated MEP latency of every trial (ms)
% MEPIndexes: Vector of n elements, taking values of 0 or 1, if the trial was discarded or not, respectively

function [MEPAmp,MEPLat,MEPIndexes] = MEP_Features(X,Fs,K)

m = size(X,1);
n = size(X,2);

t= 0:(1000/Fs):(1000*(m-1)/Fs); % Time vector from 0 to 1000 (m−1) / Fs, with steps of 1000/Fs (in ms)

for i = 1:n
    x = X(:,i); % the ith column from X
    xfilt = Filter_N(x,Fs);
    
    clear POW t1 t2;
    for j = 1:ceil(45*Fs/1000)
        t1(j) = find(t>=5,1) + (j-1);% location in t equal to 5 ms + (j−1)
        t2(j) = find(t>t(t1(j)) + 10.7,1);% location in t equal to 10.7ms after t1
        the_range = t1(j):t2(j);
        N = numel(the_range);

        Y = fft(xfilt(the_range));
        P2 = abs(Y/N);
        P1 = P2(1:ceil(N/2)+1);
        P1(2:end-1) = 2*P1(2:end-1);
        f = Fs/N*(0:(N/2));
        %plot(f,P1);
        freqrange = find(f<=234);
        POW(j) = sum(P1(freqrange).^2);
    end
    [~,WMaxi(i)] = max(POW);  % Find window j that has the maximum power for trial i within POWi(j)    
    MEPLat(i) = t(t1(WMaxi(i))); % Calculate the first sample t1 of WMaxi for computing the latency of the ith trial
    the_range = t1(WMaxi(i)):t2(WMaxi(i));
    signal = xfilt(the_range);
    MEPAmp(i) = max(signal) - min(signal);  % Calculate amplitude using the highest and lowest values of the EMG signal in WMaxi
    Mediani(i) = median(POW); % Calculate POWi median
    MEPFit(i) = POW(WMaxi(i)) ./ Mediani(i); % MEPFit (i) = WMaxi
end
% Finally, delete the K trials with the lowest fitness function values and save them on MEPIndexes
[~,inds] = mink(MEPFit,K);
MEPIndexes = ones(1,n);
MEPIndexes(inds) = 0;


%Input 
% RawSignal: Vector of m elements (signal samples)
% m: Number of samples of the signal
%Output 
% Filteredsignal: Vector with m elements (signal samples)

function Filteredsignal = Filter_N(RawSignal,Fs)

[B,A] = butter(4, [49 51]./(Fs/2), 'stop');
Filteredsignal = filtfilt(B,A,RawSignal);

