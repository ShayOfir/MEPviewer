function merged = merge_files (fn_out, folder, fnames)
%%merge MEP files


L = length(fnames);
dat = cell(1,L);
for k=1:L
    dat{k} = load([fnames(k).folder ,'\' fnames(k).name]);   
end

field_names = fields(dat{1});
%intialize
%merged = cell2struct(cell(1,length(field_names)), field_names, 2);
groups = struct('data',0,'datastart',4,'dataend',4,'titles',2,'rangemin',0,'rangemax',0,...
                'unittextmap',0,'unittext',2,'blocktimes',0,'tickrate',0,'samplerate',0,'firstsampleoffset',0,'com',5,...
                'comtext',3);

%First record is the type of the data (option for data option)
%Second record is whether or not to modify the numbers accordingl:
% 0=don't
% 1=modify 


%pay attention for the position datastart and dataend and com - they should be
%modified from the second file and on!

%go over the files:
merged = dat{1};
for k=2:L
    %com
    merged.com = add_data(merged.com, dat{k}.com, 5, size(merged.datastart,2));


    %datastart, dataend
    data_start_end = add_data_pointers(merged.datastart, merged.dataend, dat{k}.datastart, dat{k}.dataend);
    merged.datastart = data_start_end{1};
    merged.dataend = data_start_end{2};
    
    
    %other fields

    for j=1:length(field_names)
        f=field_names{j};
        if ~ismember(f,{'datastart','dataend','com'})
            source = getfield(merged,f);
            target = getfield(dat{k},f);
            add_the_data = add_data(source, target, getfield(groups,f));
            merged = setfield(merged,f,add_the_data);
        end
    end
end

for i=1:length(field_names)
    f = field_names{i};
    eval([f,'  = merged.' f ';']);
end
save([folder,'\',fn_out], field_names{:});

end



function result = add_data(x, y, option, varargin)
    result = [];
        switch option
            case 0
                result = [x, y];
            case 1
                result = [x; y];
            case 2
                are_equal = true;
                for j=1:size(x,1)
                    for k=1:size(x,2)
                        if x(j,k) ~= y(j,k)
                            are_equal = false;
                        end
                    end
                end
                if ~(are_equal)
                    warning("Fields are not the same but should be.")
                else
                    result = x;
                end
            case 3 %for comtext
                result = char(pad([string(x); string(y)]));
            case 4 %for datastart, dataend
                res = add_data_pointers(x{1}, x{2}, y{1}, y{2});
                result{1} = res(1);
                result{2} = res(2);
            case 5 %for com
                n_total_blocks = varargin{1};
                y1 = y;
                y1(:,2) = y1(:,2) + n_total_blocks;
                y1(:,5) = y1(:,5) + x(end,5);
                result = [x; y1];
           
        end
 
end

