function [sorted_power, block_mean,reject_array,latency_ms,area,ptp,ptp_std,ptp_SEmean,ptp_mean] ...
    = labchart_comments_chann(file, baseline_start, baseline_length, zero_start, zero_end, ...
    n_std_array, latency_override, MEP_length_override, plot_ind, discard_array, ...
    block_start, block_length, block_power, channel) 
% e.g.,
% [output,rej_array,latency_ms,area,ptp]=labchart_comments('fig8_15av_data.mat',1500,500,n_std_array, discard_array);
% [power1, block_mean1,reject_array1,latency_ms1,area1,ptp1]=labchart_comments('Gaby_Fig8_MEP_IOcurve.mat',1500,500,n_std_array, discard_array);

% First run with 0 as last index to see if any entries in reject_array.
% If see that there are some obvious outliers that didn't come up in
% reject_array, then can change std level (default at 10 for upper)
% or open in signalanalyzer and decide which indices to remove;
% then re-run with last entry of function call containing this area of rejections.
% For latency, observe position of red dot on trace and if it's not in
% place due to noise affecting calc, change n_std (ideally 3-5) to move the point accordingly, 
% or change start point of latency search 
% (e.g., if see initial TMS artefact, move search point past there).
    

    MEP_length=40; % assume that endpoint at least MEP_length pts (40, corresponds to 40/2=20ms) after latency 
    latency_search_start=1;  % if see initial spike, delay search point for latency (default 0)
    delsys_delay=61.1; %ms, delsys delay for analogue connection
    trig_pos=500; % ms, position of trigger in window (for 1sec windows, usually in middle)
    tick_fs = 5e-4; % tick rate in sec (frequency=1/tick_fs, i.e., 2kHz for these acquisitions)
    
	% file extension
    %[~,~,ext] = fileparts(which(file));
    [~,~,ext] = fileparts(file);


	% in case of .mat file
	if strcmp(ext,'.mat')
		% load mat file
		in_file=load(file);
        	
        % deal with different record lengths (2002,2003, etc) by finding
        % max of array and padding to that value (hope that signal aligns!)
        max_record_length=max(max(in_file.dataend-in_file.datastart));
        % 'e' contains the data from each record (approx 2000x40)
        e=zeros(max_record_length,size(in_file.datastart,2));
        % Note: e.g., the 1 in datastart(1,i) since there may be 3 channels of data stored
		for i=1:size(in_file.datastart,2)
            record_length=in_file.dataend(channel,i)-in_file.datastart(channel,i)+1;
			e(1:record_length,i)=in_file.data(in_file.datastart(channel,i):in_file.dataend(channel,i));
		end

		% fill up blocks
        % note: block size has to be consistent (i.e., can't have one block
        % of 6 records and another of 5) as otherwise causes problem with 2nd index!
		for j=1:length(block_start)
			block{j}=e(:,block_start(j):block_start(j)+block_length(j)-1); % cell so allows different block sizes
		end
		
	else % native file format (.adicht)
		in_file=adi.readFile(file); % using JimHokanson-adinstruments_EMG toolbox
		e1=in_file.getChannelByName('FDI'); % pick channel1
        for j=1:in_file.n_records
            e(:,j)=e1.getData(j);  % note: will need to implement the padding (see above)
        end
          		
		% fill up blocks 
		for j=1:length(block_start)
			block(:,:,j)=e(:,block_start(j):block_start(j)+block_length-1);
		end
		
    end
	
	% Go through data array block by block
	for k=1:length(block_start)  
	
		% zero parts of array (e.g., in case of secondary peak)
		if zero_start>0 & zero_end>0
			block{k}(zero_start:zero_end,:)=block{k}(end-zero_end+zero_start:end,:);  
		end

		% simple outlier detection according to peak-to-peak over the 15 traces
		min_arr=mink(block{k},6); % find top 6 values
		min_arr=mean(min_arr); 
		max_arr=maxk(block{k},6);
		max_arr=mean(max_arr);
		diff_arr=max_arr-min_arr;
		std_diff_arr=std(max_arr-min_arr);
		mean_diff_arr=mean(max_arr-min_arr);
		reject_array{k}=find(abs(diff_arr)>(3*std_diff_arr+mean_diff_arr) | abs(diff_arr)<+mean_diff_arr-3*std_diff_arr );
        if length(reject_array{k}) ~= 0
            disp(['reject_array found in block ' num2str(k)]);
        end
        
		if plot_ind==1 
			% plot all traces of each block together
			for i=1:block_length(k)  
				figure((k-1)*block_length(k)+i) % GSP I had block_length(i) here and it crashed for 2 entries ([10] [10])
				plot(block{k}(:,i))
				title(['power=' num2str(block_power(k)) '%, block=' num2str(k) ', record=' num2str(i)]);
			end

        elseif plot_ind==2
			% plot all traces separately
			figure(k) % check
			for i=1:block_length(k) 
			  plot(block{k}(:,i))
			  hold on
			end
			title(['Block traces: power=' num2str(block_power(k)) '%, block=' num2str(k)]);
        else
            disp(''); % need else?
        end
 

		% delete traces based on "rejection array" (this can be empirically output from function, see reject_array)
		% note: this feature doesn't work. If discard_array in not 0, can't set dimentions of 3D-array to null to remove them (only can for 2D array)
        if length(discard_array) ~= 0 && length(discard_array{k}) ~= 0
            disp(['Discarding in block: ' num2str(k)]);
			block{k}(:,discard_array{k})=[]; 
        end
        
		% calculate mean 
		block_mean(:,k)=mean(block{k},2);
        
        % std of ptp in each trace
        ptp_ind=zeros(block_length(k),1);
        for i=1:block_length(k)  
            min_mean_indiv=mink(block{k}(:,i),3); % find top 6 values
            min_mean_indiv=mean(min_mean_indiv); 
            max_mean_indiv=maxk(block{k}(:,i),3);
            max_mean_indiv=mean(max_mean_indiv);
            ptp_indiv(i)=max_mean_indiv-min_mean_indiv;	        
        end
        ptp_std(k)=std(ptp_indiv); % SD
        ptp_SEmean(k)=sqrt(ptp_std(k).^2/block_length(k)); % SE in mean
        ptp_mean(k)=mean(ptp_indiv); % mean (individual ptp)
        
		block_mean_bs= block_mean(baseline_start:baseline_start+baseline_length,k); % baseline
		block_mean_bs_mean = mean(block_mean_bs);
		block_mean_bs_std = std(block_mean_bs);

		% simple baseline correction
		block_mean_bc = block_mean(:,k) - block_mean_bs_mean;

		% find simple peak-to-peak (ptp)
		min_mean=mink(block_mean_bc,3); % find top 6 values
		min_mean=mean(min_mean); 
		max_mean=maxk(block_mean_bc,3);
		max_mean=mean(max_mean);
		ptp(k)=max_mean-min_mean;	

		% plot mean baseline-corrected
		if plot_ind==2
			figure(length(block_length)+k) 
        elseif plot_ind==1
			figure(sum(block_length)+k); % already plotted each individual trace
        else
            figure(k);
        end
		
		plot(block_mean_bc);
		title(['Mean bc: power=' num2str(block_power(k)) '%, block=' num2str(k)]);

		% rectify the baseline-corrected data
		block_mean_bc_abs=abs(block_mean_bc);

        % Latency calculation
        % based latency search on deviation according to std, with option to override
        if length(latency_override)==0
            % find latency where signal goes above a certain number of within-mean-trace std
            %latency = find((block_mean_bc>3*block_mean_bs_std || block_mean_bc<3*block_mean_bs_std),1 ) %ms
            latency = find((block_mean_bc_abs(latency_search_start:end)>n_std_array(k)*block_mean_bs_std),1 )+latency_search_start; 
            % ms (but is it fair to do this on absolute?)
        else
            latency=latency_override(k);
            disp('latency override');
        end
        
		if length(latency)==0 % i.e. latency doesn't "exist" (relevant for 90%)
            latency=10; % set to low value but remove this point from latency and area plots
            disp(['Note: No signal for latency calc (ideally remove from area and latency plots), power:' num2str(block_power(k)) '%']); 
        end

        latency_ms(k) = (latency*tick_fs*1e3)-trig_pos-delsys_delay;  % units of ms
		% find endpoint (assume that endpoint at least MEP_length (set to 4ms) after latency)
        if length(MEP_length_override)==0
           % use fixed estimate defined above for MEP length for area calc [pts]
            endpoint = find(block_mean_bc_abs(latency+MEP_length:end)<n_std_array*block_mean_bs_std,5)+latency+MEP_length-1;  % check since might find the middle cross-point around zero
        else   
            % use array defined in script file
            endpoint = find(block_mean_bc_abs(latency+MEP_length_override{k}:end)<n_std_array*block_mean_bs_std,5)+latency+MEP_length_override{k}-1;  % check since might find the middle cross-point around zero            
            disp('MEP length override');
        end
        
        % plot latency and endpoint dots on mean block plot
		hold on;
		plot(latency, block_mean_bc(latency),'r*')
		plot(endpoint(1),block_mean_bc(endpoint(1)),'b*');

		% calculate area between these two points
		area(k) = trapz(latency:endpoint(1), block_mean_bc_abs(latency:endpoint(1)))*tick_fs*1e3; % units of [ms.mV]

		%signalanalyzer

    end % end of k loop
    
	% plot io-curves
	[sorted_power ind]=sort(block_power); % sort the entries according to power
	block_mean=block_mean(:,ind); area=area(ind); ptp=ptp(ind); latency_ms=latency_ms(ind); reject_array=reject_array([ind]);
	%figure(60);	plot(sorted_power, latency_ms,'go--');	title('Latency (ms)'); xlabel('stimulation power(%)');
	%figure(61);	plot(sorted_power, ptp,'bo--');	title('Amplitude (peak-to-peak)'); xlabel('stimulation power(%)');
	%figure(62);	plot(sorted_power, area,'ro--'); title('Area'); xlabel('stimulation power(%)');
	
end
