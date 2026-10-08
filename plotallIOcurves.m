% PLOTALLIOCURVES

IOtable = readtable('csv/IO_combined.csv');

for k=1:size(IOtable,1)
    subjectname{k} = IOtable.name{k}(1:4);
end

subjectnames = unique(subjectname);

f = fields(IOtable);
maxpoints = str2double(f{end-3}(end));

for k=1:numel(subjectnames)
    thissubject = find(strcmp(subjectname,subjectnames{k}));
    for m=1:numel(thissubject)
        for n=1:maxpoints
            IOdata{k}.percent_threshold(m,n) = IOtable.(['percent_threshold' num2str(n)])(thissubject(m));
            IOdata{k}.logMEPsMEP(m,n) = IOtable.(['logMEPsMEP' sprintf('%02d',n)])(thissubject(m));
        end
        IOdata{k}.deltay(m) = IOtable.deltay(thissubject(m));
        IOdata{k}.s(m) = IOtable.s(thissubject(m));
        IOdata{k}.m(m) = IOtable.m(thissubject(m));
        IOdata{k}.R2(m) = IOtable.R2(thissubject(m));
        if contains(IOtable.name{thissubject(m)},'fig8','IgnoreCase',true)
            IOdata{k}.coiltype(m) = 1;
        elseif contains(IOtable.name{thissubject(m)},'H7','IgnoreCase',true)
            IOdata{k}.coiltype(m) = 2;
        elseif contains(IOtable.name{thissubject(m)},'rf','IgnoreCase',true)
            IOdata{k}.coiltype(m) = 3;
        else
            error(['Could not find coil type: ' IOtable.name{thissubject(m)}]);
        end
    end
end

%%
rows = ceil(sqrt(numel(IOdata)));
cols = ceil(numel(IOdata) / rows);
colors = colororder;

figure;
x = 0:1:150;

for k=1:numel(subjectnames)
    subplot(rows,cols,k);
    for m=1:numel(IOdata{k}.deltay)
        coiltype = IOdata{k}.coiltype(m);
        plot(IOdata{k}.percent_threshold(m,:),IOdata{k}.logMEPsMEP(m,:),'.','Color',colors(coiltype,:));
        hold on;
        y = evaluateIOfunction(x,IOdata{k}.deltay(m),IOdata{k}.s(m),IOdata{k}.m(m));
        plot(x,y,'Color',colors(coiltype,:));
    end
    xlim([0 150]);
    title(subjectnames{k});
end