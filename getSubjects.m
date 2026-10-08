% Return a list of subjects (directories in the results folder)
function dirnames = getSubjects

d = dir('results/');
count = 0;
for k=1:numel(d)
    if d(k).isdir && d(k).name(1) ~= '.'
        % Check that there are .mat files
        d2 = dir(['results/' d(k).name '/*.mat']);
        if ~isempty(d2)
            count = count+1;
            dirnames{count} = d(k).name;
        end
    end
end
