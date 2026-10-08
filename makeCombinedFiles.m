% MAKECOMBINEDFILES - combine all the files into one for statistical analyses

function makeCombinedFiles

warning('off','MATLAB:table:RowsAddedExistingVars');

%%

% IO files
d = dir('csv/*_IO.csv');

% count the maximum number of rows
for k=1:numel(d)
    t1 = readtable(['csv/' d(k).name]);
    numrows(k) = size(t1,1);
end
maxrows = max(numrows);

IOtable = table;
for k=1:numel(d)
    t1 = readtable(['csv/' d(k).name]);
    IOtable.name{k} = d(k).name(1:end-4);
    IOtable.deltay(k) = t1.deltay(1);
    IOtable.s(k) = t1.s(1);
    IOtable.m(k) = t1.m(1);
    IOtable.R2(k) = t1.R2(1);
    IOtable.n_points(k) = t1.n_points(1);
    IOtable.OK(k) = t1.OK(1);
    for n=1:numrows(k)
        IOtable.(['percent_threshold' num2str(n)])(k) = t1.percent_threshold(n);
        IOtable.(['logMEPsMEP0_1' num2str(n)])(k) = t1.logMEPsMEP0_1(n);
        IOtable.(['logMEPsMEP0_2' num2str(n)])(k) = t1.logMEPsMEP0_1(n);
    end
    for n=numrows(k)+1:maxrows
        IOtable.(['percent_threshold' num2str(n)])(k) = NaN;
        IOtable.(['logMEPsMEP0_1' num2str(n)])(k) = NaN;
        IOtable.(['logMEPsMEP0_2' num2str(n)])(k) = NaN;
    end
end

writetable(IOtable,'csv/IO_combined.csv');

%%

d = dir('csv/*_measures_byblock.csv');
byblock = table;
count = 0;
for k=1:numel(d)
    t1 = readtable(['csv/' d(k).name]);

    f = fields(t1);
    for n=1:size(t1,1)
        count = count+1;
        byblock.name{count} = d(k).name(1:end-4);
        for m=1:numel(f)-3
            byblock.(f{m})(count) = t1.(f{m})(n);
        end
    end
end

writetable(byblock,'csv/measures_byblock_combined.csv');