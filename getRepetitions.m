% GETREPETITIONS - get the repetitions for a given subject
function filenames = getRepetitions(subject)

d = dir(['results/' subject '/*.mat']);
for k=1:numel(d)
    filenames{k} = d(k).name(1:end-4);
end
