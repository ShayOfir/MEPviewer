% EXPORT SUBJECT DATA TO CSV FILES

function exportToCSV(subject, channels, repetition)

if nargin==0 || isempty(subject)
    subjects = getSubjects;
    for k=1:numel(subjects)
        exportToCSV(subjects{k});
    end
    makeCombinedFiles;
    fprintf('Made summary files csv/IOcombined.csv and csv/measures_byblock_combined.csv\n');
    return
end

if nargin<3 || isempty(repetition)
    repetitions = getRepetitions(subject);
    for k=1:numel(repetitions)
        if nargin<2 || isempty(channels)
            fn = ['results/' subject '/' repetitions{k} '_channelDescription.csv'];
            if isfile(fn)
             channelDescriptions = readtable(fn);
             channels = channelDescriptions.channels;
            end
        end
        if exist("channels")
            exportToCSV(subject,channels,repetitions{k});
        end
    end
    return
end

fprintf(['Preparing csv/' subject '_' repetition '_measures_bytrial.csv\n']);

[measuresByTrial,measuresByBlock] = calculateMeasuresRepetition(subject,repetition,channels);

if (isempty(measuresByTrial))
    return
end

% Removed for now
% [result,percent_threshold,logMEPsMEP0,r2] = fitIOcurveRepetition(subject,repetition,channels,0);
% 
% IOcurve_params = get_IOcurve_params(subject, repetition);
% 
% IOtable = table;
% IOtable.channels = channels;
% IOtable.percent_threshold = percent_threshold';
% IOtable.logMEPsMEP0 = logMEPsMEP0';
% % pad with NaNs
% padL = NaN(numel(percent_threshold)-2,1);
% IOtable.deltay = [result(:,1); padL];
% IOtable.s = [result(:,2); padL];
% IOtable.m = [result(:,3); padL];
% IOtable.R2 = [r2';padL];
% IOtable.n_points = [size(logMEPsMEP0,1); size(logMEPsMEP0,1); padL];
% IOtable.OK = [IOcurve_params.IOcurve_OK; IOcurve_params.IOcurve_OK; padL];

if ~exist('csv','dir')
    mkdir('csv');
end

% Remove unneccessary fields
measuresByTrial = removevars(measuresByTrial,{'latencyJose_ms','latency_regular','latency_regular_ms'});
fn = ['csv/' subject '_' repetition '_measures_bytrial.csv'];
writetable(measuresByTrial,fn);

measuresByBlock = removevars(measuresByBlock,{'latency_regular_ms','latencyJose_ms'});
fn2 = ['csv/' subject '_' repetition '_measures_byblock.csv'];
writetable(measuresByBlock,fn2);

% fn3 = ['csv/' subject '_' repetition '_IO.csv'];
% writetable(IOtable,fn3);

%fprintf('Saved to csv files: csv/%s, csv/%s and csv/%s\n',fn,fn2,fn3);
fprintf('Saved to csv files: csv/%s and csv/%s\n',fn,fn2);
