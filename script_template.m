%%
filemat='results/Nachum_LT_fig8.mat';  % CHANGE: enter filename here!
a=load(filemat);
plot(a.data); title('all data');
a1=a.datastart-a.dataend;
%plot(a1(1,:)); title('record durations');  
a.com
a.comtext

%%
% check for "artefactual" signals
zero_start = 0; 
zero_end = 0;  

% baseline calc (alternatively take start of scan
baseline_start=1500;
baseline_length=500;

%%
plot_index=0; % Plotting choice:  1: each MEP (lots of figures!), 2: each block, 0: only Means (least amount of figures). CHANGE

discard_array={[],[],[],[],[],[],[]}; % CHANGE remove artefactual traces {[],[2],[],[4],[3,5],[],[]};
n_std_array=[2,2,2,2,2,2,2]; % CHANGE threshold for finding MEP start for e.g., spiky (150%?) or noisy (90%?) data [2,5,5,2,3,1,1]
MEP_length_override=[]; % option to override search for MEP endpoint used in area calc (otherwise defaults in fn to MEP_length) (units of pts, e.g., 40=>20ms); e.g., MEP_length_override={[40],[40],[70],[70],[70],[70],[70]};  
latency_override_pts=[]; % option to override latency search, e.g., latency_override_pts=[1175 1171 1180 1172 1174 1175 1176];
chann=1; % channel (usually 1)
block_start=[1 6 11 16 21 26 31]; % CHANGE work this out from in_file.com and in_file.comtext
block_length=[5 5 5 5 5 5 5]; % usually 5 records/block used for averaging in the io curve 
block_power=[90 100 110 120 130 140 150]; % MSO

[power1,block_mean1,reject_array1,latency_ms1,area1,ptp1,ptp1_std,ptp1_SEmean,ptp1_mean]= ...
    labchart_comments_chann(filemat,baseline_start,baseline_length,zero_start, zero_end, ...
    n_std_array,latency_override_pts, MEP_length_override, plot_index, ...
    discard_array,block_start,block_length,block_power,chann);

%%
figure(100); plot(power1(2:end), latency_ms1(2:end),'go--'); title('Latency (ms)'); xlabel('%RMT'); ylim([20 25]); % for latency, avoid 90%
figure(101); plot(power1, ptp1,'bo--');	title('Amplitude (peak-to-peak [V])'); xlabel('%RMT'); ylim([0 1.0]);
figure(102); plot(power1, area1,'ro--'); title('Area'); xlabel('%RMT'); ylim([0 4]);

% ptp: standard error in mean
figure(103); errorbar(power1,ptp1_mean,ptp1_SEmean,'bo--'); title('Amplitude (ptp-indiv with SE-mean [V])'); xlabel('%RMT'); ylim([0 4]);

