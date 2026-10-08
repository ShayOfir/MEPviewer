classdef MEP_viewer_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        IsMEPCheckBox                matlab.ui.control.CheckBox
        ResetlatencyendpointButton   matlab.ui.control.Button
        lambdaEditField              matlab.ui.control.NumericEditField
        lambdaLabel                  matlab.ui.control.Label
        BaselineendEditField         matlab.ui.control.NumericEditField
        BaselineendEditFieldLabel    matlab.ui.control.Label
        BaselinestartEditField       matlab.ui.control.NumericEditField
        BaselinestartEditFieldLabel  matlab.ui.control.Label
        SelectendpointButton         matlab.ui.control.Button
        SelectlatencyonsetButton     matlab.ui.control.Button
        OpeninnewwindowButton        matlab.ui.control.Button
        ExportallsubjectsButton      matlab.ui.control.Button
        repetitionSelector           matlab.ui.control.DropDown
        ZoominCheckBox               matlab.ui.control.CheckBox
        BlockbasedmeasuresLabel      matlab.ui.control.Label
        TrialbasedmeasuresLabel      matlab.ui.control.Label
        BlockMEPTable                matlab.ui.control.Table
        ExportsubjectButton          matlab.ui.control.Button
        SingleMEPTable               matlab.ui.control.Table
        UseDataCheckBox              matlab.ui.control.CheckBox
        trialsTable                  matlab.ui.control.Table
        MEPSelector                  matlab.ui.control.DropDown
        Panel                        matlab.ui.container.Panel
        quantitySelector             matlab.ui.control.DropDown
        subjectSelector              matlab.ui.control.DropDown
    end

    
    properties (Access = private)
        subject % subject name
        repetition % repetition (within the subject folder)
        data % Data for the current subject
        toUseTable % whether to use a trial
    end
    
    methods (Access = private)
        function updateSubject(app)
            thisSubject = app.subjectSelector.Value;
            app.subject = thisSubject;

            filenames = getRepetitions(app.subject);
            app.repetitionSelector.Items = filenames;
            updateRepetition(app);
        end

        function fn = getToUseLocation(app)
            fn = ['results/' app.subject '/' app.repetition '_touse.csv'];
        end

        function fn = getBlockDescriptionsLocation(app)
            fn = ['results/' app.subject '/' app.repetition '.csv'];

        end

        function updateRepetition(app)
            thisSubject = app.subjectSelector.Value;
            thisRepetition = app.repetitionSelector.Value;
            app.subject = thisSubject;
            app.repetition= thisRepetition;
            app.data=loaddata(['results/' app.subject '/' app.repetition]);
            if ~isstruct(app.data) && isnan(app.data)
                return
            end
            % Update the table
            fn_blockdescriptions = getBlockDescriptionsLocation(app);
            if exist(fn_blockdescriptions,'file')
                t = readtable(fn_blockdescriptions);
            else
                t = app.data.blockdescriptions;
            end
            app.trialsTable.Data = t;
            
            toUseFilename = getToUseLocation(app);

            if exist(toUseFilename,'file')
                app.toUseTable = readtable(toUseFilename);
            else
                app.toUseTable = table;
                N = size(app.data.e,2);
                app.toUseTable.trial = (1:N)';
                app.toUseTable.toUse = ones(N,1);
                app.toUseTable.latencyOnset = -1 * ones(N,1); %-1 indicates has not been set (yet)
                app.toUseTable.endpoint = -1 * ones(N,1);
                app.toUseTable.isMEP = ones(N,1);
                params = globalparameters;
                app.toUseTable.baselineStart = ((params.baseline_start-1000)./app.data.samplerate) * 1000 * ones(N,1);
                app.toUseTable.baselineEnd = params.baseline_length * ones(N,1)/2 + app.toUseTable.baselineStart;
                app.toUseTable.lambda = 3 * ones(N,1);
            end

            count = 0;
            for k=1:size(app.trialsTable.Data,1)
                % don't include if there are no entries
                if app.trialsTable.Data.blockend(k) >= app.trialsTable.Data.blockstart(k)
                    count = count+1;
                    allMEPs{count}   = sprintf('All MEPs - block %d',k);
                    meanMEPs{count}   = sprintf('Mean rectified MEPs - block %d',k);
                    individualMEPs{count} = sprintf('Individual MEPs - block %d',k);
                end
            end
            quantity = [{'Whole Trial'} allMEPs meanMEPs individualMEPs {'PeakToPeak','Latency','Area','IO curve'}];
            app.quantitySelector.Items = quantity;
            updateGraphs(app);
        end

        function updateGraphs(app,f)
            if nargin<2 || isempty(f)
                f = app.Panel;
            end
            quantity = app.quantitySelector.Value;
            s = subplot(1,1,1,'Parent',f);
            cla(s);
            ylabel(s,'mV');
            xlabel(s,''); 
            title(s,'');
            xlim(s,'auto');
            if strcmp(quantity,'Whole Trial')
                time = (1:numel(app.data.alldata.data)) ./ app.data.samplerate * 1000;
                plot(s,time,app.data.alldata.data)
                xlabel(s,'time (ms)')
                ylabel(s,'mV');
                app.UseDataCheckBox.Visible = 'off';
                app.IsMEPCheckBox.Visible = 'off';
                app.BaselineendEditField.Visible = 'off';
                app.BaselineendEditFieldLabel.Visible = 'off';
                app.BaselinestartEditField.Visible = 'off';
                app.BaselinestartEditFieldLabel.Visible = 'off';
                app.SelectendpointButton.Visible = 'off';
                app.ResetlatencyendpointButton.Visible = 'off';
                app.SelectlatencyonsetButton.Visible = 'off';
                app.lambdaEditField.Visible = 'off';
                app.lambdaLabel.Visible = 'off';
                app.MEPSelector.Visible = 'off';
                app.SingleMEPTable.Visible = 'off';
                app.TrialbasedmeasuresLabel.Visible = 'off';
                app.BlockMEPTable.Visible = 'off';
                app.BlockbasedmeasuresLabel.Visible = 'off';
                app.ZoominCheckBox.Visible = 'off';

            elseif strncmp(quantity,'All MEPs - block',8) || strncmp(quantity,'Mean rectified MEPs - block',19)
                if strncmp(quantity,'All MEPs - block',8)
                    blockNum = str2double(quantity(18:end));
                else
                    blockNum = str2double(quantity(29:end));
                end
                thisblock = app.data.block{blockNum};

                blockstart = app.trialsTable.Data.blockstart(blockNum);
                blockend = app.trialsTable.Data.blockend(blockNum);

                params = globalparameters;
                params.std = app.trialsTable.Data.n_std(blockNum);
                params.samplerate = app.data.samplerate;
                touseBlock = app.toUseTable.toUse(blockstart:blockend);

                % calculate block level calculations
                [blockResults,app.BlockMEPTable.Data,blockdata] = calculateMeasuresBlock(thisblock,params,touseBlock);
                app.BlockMEPTable.Visible = 'on';
                app.BlockbasedmeasuresLabel.Visible = 'on';

                for k=blockstart:blockend
                    if app.toUseTable.toUse(k)
                        time = (1:size(app.data.e,1)) ./ app.data.samplerate * 1000;
                        if strncmp(quantity,'All MEPs - block',8)
                            plot(s,time-params.delsys_delay-params.trig_pos,app.data.e(:,k));
                            hold(s,'on');
                        end
                    end
                end
                if strncmp(quantity,'Mean rectified MEPs - block',9)
                    plot(s,time-params.delsys_delay-params.trig_pos,blockdata.block_mean_bc_abs);
                    hold (s,'on');
                    if ~isempty(blockResults.latency_ms) && ~isnan(blockResults.latency_ms)
                        xline(s,blockResults.latency_ms,'k');
                    end
                    if ~isempty(blockResults.endpoint_ms) && ~isnan(blockResults.endpoint_ms)
                        xline(s,blockResults.endpoint_ms,'k--');
                    end

                end
                xlabel(s,'time (ms)')
                ylabel(s,'mV');

                app.UseDataCheckBox.Visible = 'off';
                app.IsMEPCheckBox.Visible = 'off';
                app.BaselineendEditField.Visible = 'off';
                app.BaselineendEditFieldLabel.Visible = 'off';
                app.BaselinestartEditField.Visible = 'off';
                app.BaselinestartEditFieldLabel.Visible = 'off';
                app.SelectendpointButton.Visible = 'off';
                app.SelectlatencyonsetButton.Visible = 'off';
                app.ResetlatencyendpointButton.Visible = 'off';
                app.lambdaEditField.Visible = 'off';
                app.lambdaLabel.Visible = 'off';
                app.MEPSelector.Visible = 'off';
                app.SingleMEPTable.Visible = 'off';
                app.TrialbasedmeasuresLabel.Visible = 'off';
                app.ZoominCheckBox.Visible = 'off';

            elseif strncmp(quantity,'Individual MEPs',15) 
                app.ZoominCheckBox.Visible = 'on';

                MEPnumber = str2double(app.MEPSelector.Value(5:end));
                % Which block are we in?
                blockNum = str2double(quantity(25:end));
                thisblock = app.data.block{blockNum};
                thisdata = app.data.e(:,MEPnumber);
                time = (1:size(app.data.e,1)) ./ app.data.samplerate * 1000;
                touse = app.toUseTable.toUse(MEPnumber);
                isMEP = app.toUseTable.isMEP(MEPnumber);

                blockstart = app.trialsTable.Data.blockstart(blockNum);
                blockend = app.trialsTable.Data.blockend(blockNum);
                touseBlock = app.toUseTable.toUse(blockstart:blockend);

                params = globalparameters;
                params.std = app.trialsTable.Data.n_std(blockNum);
                params.samplerate = app.data.samplerate;

                app.lambdaEditField.Value = app.toUseTable.lambda(MEPnumber);

                if touse
                    app.UseDataCheckBox.Value = true;
                    plot(s,time-params.delsys_delay-params.trig_pos,thisdata);
                else
                    app.UseDataCheckBox.Value = false;
                    plot(s,time-params.delsys_delay-params.trig_pos,thisdata,'Color',[0.5 0.5 0.5]);
                end

                app.IsMEPCheckBox.Value = isMEP;              

                app.BaselinestartEditField.Value = app.toUseTable.baselineStart(MEPnumber);
                app.BaselineendEditField.Value =  app.toUseTable.baselineEnd(MEPnumber);
                app.lambdaEditField.Value = app.toUseTable.lambda(MEPnumber);

                % Plot the baseline
                bl_start = app.BaselinestartEditField.Value;
                bl_end = app.BaselineendEditField.Value;
                hold(s,'on');
                yy = 0.05;
                fill(s,[bl_start bl_end bl_end bl_start],[-yy -yy yy yy],[0.5 0.5 0.5],'FaceAlpha',0.2,'EdgeAlpha',0.2);

                xlabel(s,'time (ms)')
                ylabel(s,'mV');

                app.UseDataCheckBox.Visible = 'on';
                app.IsMEPCheckBox.Visible = 'on';
                app.BaselineendEditField.Visible = 'on';
                app.BaselineendEditFieldLabel.Visible = 'on';
                app.BaselinestartEditField.Visible = 'on';
                app.BaselinestartEditFieldLabel.Visible = 'on';
                app.SelectendpointButton.Visible = 'on';
                app.SelectlatencyonsetButton.Visible = 'on';
                app.ResetlatencyendpointButton.Visible = 'on';
                app.lambdaEditField.Visible = 'on';
                app.lambdaLabel.Visible = 'on';
                app.MEPSelector.Visible = 'on';

                % Trial level calculations               
                latency_ms = app.toUseTable.latencyOnset(MEPnumber);
                endpoint_ms = app.toUseTable.endpoint(MEPnumber);
                baseline_start = app.toUseTable.baselineStart(MEPnumber);
                baseline_end = app.toUseTable.baselineEnd(MEPnumber);
                alldata = app.data.alldata.data;
                isMEP = app.toUseTable.isMEP(MEPnumber);
                lambda = app.toUseTable.lambda(MEPnumber);
                [trialResults,app.SingleMEPTable.Data] = calculateMeasuresTrial(thisdata,alldata,thisblock,params,touse,isMEP,...
                    latency_ms,endpoint_ms,baseline_start,baseline_end);
                app.SingleMEPTable.Visible = 'on';
                app.TrialbasedmeasuresLabel.Visible = 'on';
                proportionNoisyIndex = find(strcmp(app.SingleMEPTable.Data.Measure,'proportionNoisy'));
                proportionNoisy = app.SingleMEPTable.Data.Value(proportionNoisyIndex);
                relativeMaxPeakToPeakBaselineIndex = find(strcmp(app.SingleMEPTable.Data.Measure,'relativeMaxPeakToPeakBaseline'));
                relativeMaxPeakToPeakBaseline = app.SingleMEPTable.Data.Value(relativeMaxPeakToPeakBaselineIndex);
                bgColorRed = uistyle("BackgroundColor",[1 0.6 0.6]);
                bgColorWhite = uistyle("BackgroundColor",[1 1 1]);

                if proportionNoisy >= 0.5
                    addStyle(app.SingleMEPTable,bgColorRed,"cell",[proportionNoisyIndex,2]);
                else
                    addStyle(app.SingleMEPTable,bgColorWhite,"cell",[proportionNoisyIndex,2]);
                end
                if relativeMaxPeakToPeakBaseline > lambda
                    addStyle(app.SingleMEPTable,bgColorRed,"cell",[relativeMaxPeakToPeakBaselineIndex,2]);
                else
                    addStyle(app.SingleMEPTable,bgColorWhite,"cell",[relativeMaxPeakToPeakBaselineIndex,2]);
                end

                if ~isempty(trialResults.latency_ms) && ~isnan(trialResults.latency_ms)
                    xline(s,trialResults.latency_ms,'k');
                end

                if ~isempty(trialResults.latencyJose_ms) && ~isnan(trialResults.latencyJose_ms)
                    xline(s,trialResults.latencyJose_ms,'r');
                end


                if ~isempty(trialResults.endpoint_ms) && ~isnan(trialResults.endpoint_ms)
                    xline(s,trialResults.endpoint_ms,'k--');
                end

                if touse && app.ZoominCheckBox.Value && ...
                        ~isempty(trialResults.latency_ms) && ~isnan(trialResults.latency_ms) && ...
                        ~isempty(trialResults.endpoint_ms) && ~isnan(trialResults.latency_ms)
                        xlim(s,[trialResults.latency_ms-100 trialResults.endpoint_ms+100]);
                else
                    xlim(s,'auto');
                end

                % calculate block level calculations
                [~,app.BlockMEPTable.Data] = calculateMeasuresBlock(thisblock,params,touseBlock);
                app.BlockMEPTable.Visible = 'on';
                app.BlockbasedmeasuresLabel.Visible = 'on';
            elseif any(strcmp(quantity,{'PeakToPeak','Latency','Area'}))
                numBlocks = size(app.trialsTable.Data.blockstart);
                params = globalparameters;
                params.samplerate = app.data.samplerate;
                alldata = app.data.alldata.data;

                for blockNum=1:numBlocks
                    params.std = app.trialsTable.Data.n_std(blockNum);

                    blockstart = app.trialsTable.Data.blockstart(blockNum);
                    blockend = app.trialsTable.Data.blockend(blockNum);
                    for MEPnumber=blockstart:blockend
                        thisdata = app.data.e(:,MEPnumber);
                        thisblock = app.data.block{blockNum};
                        time = (1:size(app.data.e,1)) ./ app.data.samplerate * 1000;
                        touse = app.toUseTable.toUse(MEPnumber);
                        isMEP = app.toUseTable.isMEP(MEPnumber);
                        latency_ms = app.toUseTable.latencyOnset(MEPnumber);
                        endpoint_ms = app.toUseTable.endpoint(MEPnumber);
                        baseline_start = app.toUseTable.baselineStart(MEPnumber);
                        baseline_end = app.toUseTable.baselineEnd(MEPnumber);
                        %lambda = app.toUseTable.lambda(MEPnumber);
                        [trialResults(MEPnumber),tmpData] = calculateMeasuresTrial(thisdata,alldata,thisblock,params,touse,isMEP,...
                            latency_ms,endpoint_ms,baseline_start,baseline_end);
                    end
                end
                for blockNum=1:numBlocks
                    colors = colororder;
                    blockstart = app.trialsTable.Data.blockstart(blockNum);
                    blockend = app.trialsTable.Data.blockend(blockNum);
                    
                    for MEPnumber=blockstart:blockend
                        if strcmp(quantity,'PeakToPeak')
                            plot(s,MEPnumber,trialResults(MEPnumber).PeakToPeak,'*','Color',colors(blockNum,:));
                            hold(s,'on');
                            ylabel(s,'Peak to peak (mV)');
                        elseif strcmp(quantity,'Latency')
                            plot(s,MEPnumber,trialResults(MEPnumber).latency_ms,'*','Color',colors(blockNum,:));
                            hold(s,'on');
                            ylabel(s,'Latency (ms)');
                        elseif strcmp(quantity,'Area')
                            plot(s,MEPnumber,trialResults(MEPnumber).area,'*','Color',colors(blockNum,:));
                            hold(s,'on');
                            ylabel(s,'Area');

                        end
                    end
                end
            elseif strcmp(quantity,'IO curve')
                app.ZoominCheckBox.Visible = 'off';
                [result,percent_threshold,logMEPsMEP0] = ...
                    fitIOcurveRepetition(app.subjectSelector.Value,...
                    app.repetitionSelector.Value);
                x = percent_threshold;
                y = logMEPsMEP0;
                hold(s,'off');
                minx = 0; %min(x);
                maxx = 200; %max(x);
                xs = linspace(minx,maxx,100);
                yfit = evaluateIOfunction(xs,result(1),result(2),result(3));
                plot(s,xs,yfit);
                hold(s,'on');
                scatter(s,x,y,40,'filled');
                xlabel(s,'% motor threshold');
                ylabel(s,'log10 PeakToPeak (log10 mV)');
                y = evaluateIOfunction(percent_threshold,result(1),result(2),result(3));
                cost = sum((logMEPsMEP0 - y).^2);
                title(s,sprintf('Δy = %.4f, s = %.4f, m = %.4f, cost = %.4f',...
                    result(1),result(2),result(3),cost));
            else
                error(['Unknown quantity: ' quantity]);
            end

        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            d = dir('results/*/*.mat');
            if numel(d)==0
                errordlg('There needs to be a directory ''results'' containing folders with .mat files');
                delete(app)
                return
            end
            
            dirnames = getSubjects;
            
            set(app.subjectSelector,'Items',dirnames);
            updateSubject(app);
        end

        % Cell edit callback: trialsTable
        function trialsTableCellEdit(app, event)
            % Save the table
            t = app.trialsTable.Data;
            writetable(t,['results/' app.subject '/' app.repetition '.csv']);
            updateSubject(app);
        end

        % Value changed function: subjectSelector
        function subjectSelectorValueChanged(app, event)
            updateSubject(app);            
        end

        % Value changed function: quantitySelector
        function quantitySelectorValueChanged(app, event)
            quantity = app.quantitySelector.Value;
            if strncmp(quantity,'Individual',10)
                blockNum = str2double(quantity(25:end));
                blockstart = app.trialsTable.Data.blockstart(blockNum);
                blockend = app.trialsTable.Data.blockend(blockNum);
                for k=blockstart:blockend
                    v{k-blockstart+1} = sprintf('MEP %d',k);
                end
                app.MEPSelector.Items = v;

                app.MEPSelector.Visible = 'on';
                app.UseDataCheckBox.Visible = 'on';
                app.IsMEPCheckBox.Visible = 'on';
                app.BaselineendEditField.Visible = 'on';
                app.BaselineendEditFieldLabel.Visible = 'on';
                app.BaselinestartEditField.Visible = 'on';
                app.BaselinestartEditFieldLabel.Visible = 'on';
                app.SelectendpointButton.Visible = 'on';
                app.SelectlatencyonsetButton.Visible = 'on';
                app.ResetlatencyendpointButton.Visible = 'on';
                app.lambdaEditField.Visible = 'on';
                app.lambdaLabel.Visible = 'on';
            else
                app.MEPSelector.Visible = 'off';
                app.UseDataCheckBox.Visible = 'off';
                app.IsMEPCheckBox.Visible = 'off';
                app.BaselineendEditField.Visible = 'off';
                app.BaselineendEditFieldLabel.Visible = 'off';
                app.BaselinestartEditField.Visible = 'off';
                app.BaselinestartEditFieldLabel.Visible = 'off';
                app.SelectendpointButton.Visible = 'off';
                app.SelectlatencyonsetButton.Visible = 'off';
                app.ResetlatencyendpointButton.Visible = 'off';
                app.lambdaEditField.Visible = 'off';
                app.lambdaLabel.Visible = 'off';
            end
            updateGraphs(app);
        end

        % Value changed function: MEPSelector
        function MEPSelectorValueChanged(app, event)
            updateGraphs(app);            
        end

        % Callback function
        function channelSelectorValueChanged(app, event)
            updateGraphs(app);
        end

        % Value changed function: UseDataCheckBox
        function UseDataCheckBoxValueChanged(app, event)
            MEPnumber = str2double(app.MEPSelector.Value(5:end));
            app.toUseTable.toUse(MEPnumber) = app.UseDataCheckBox.Value;
            writetable(app.toUseTable,getToUseLocation(app));
            updateGraphs(app);
        end

        % Button pushed function: ExportsubjectButton
        function ExportsubjectButtonPushed(app, event)
            app.ExportsubjectButton.Enable = 'off';
            app.ExportsubjectButton.Text = 'calculating . . .';
            pause(1);
            exportToCSV(app.subjectSelector.Value);
            app.ExportsubjectButton.Enable = 'on';
            app.ExportsubjectButton.Text = 'Export subject';
        end

        % Value changed function: ZoominCheckBox
        function ZoominCheckBoxValueChanged(app, event)
            value = app.ZoominCheckBox.Value;
            updateGraphs(app);
        end

        % Value changed function: repetitionSelector
        function repetitionSelectorValueChanged(app, event)
            value = app.repetitionSelector.Value;
            updateRepetition(app);
        end

        % Button pushed function: ExportallsubjectsButton
        function ExportallsubjectsButtonPushed(app, event)
            app.ExportallsubjectsButton.Enable = 'off';
            app.ExportallsubjectsButton.Text = 'calculating . . .';
            pause(1);
            exportToCSV;
            app.ExportallsubjectsButton.Enable = 'on';
            app.ExportallsubjectsButton.Text = 'Export all subjects';

        end

        % Button pushed function: OpeninnewwindowButton
        function OpeninnewwindowButtonPushed(app, event)
            f = figure;
            updateGraphs(app,f);
        end

        % Button pushed function: SelectlatencyonsetButton
        function SelectlatencyonsetButtonPushed(app, event)
            ax = subplot(1,1,1,'Parent',app.Panel);
            roi = drawpoint(ax,'Visible','off');
            x = roi.Position(1);
            MEPnumber = str2double(app.MEPSelector.Value(5:end));
            app.toUseTable.latencyOnset(MEPnumber) = x;
            writetable(app.toUseTable,getToUseLocation(app));

            updateGraphs(app);
        end

        % Callback function
        function PanelButtonDown(app, event)

        end

        % Button pushed function: SelectendpointButton
        function SelectendpointButtonPushed(app, event)
            ax = subplot(1,1,1,'Parent',app.Panel);
            roi = drawpoint(ax,'Visible','off');
            x = roi.Position(1);

            MEPnumber = str2double(app.MEPSelector.Value(5:end));
            app.toUseTable.endpoint(MEPnumber) = x;
            writetable(app.toUseTable,getToUseLocation(app));

            updateGraphs(app);
        end

        % Button pushed function: ResetlatencyendpointButton
        function ResetlatencyendpointButtonPushed(app, event)
            MEPnumber = str2double(app.MEPSelector.Value(5:end));
            app.toUseTable.latencyOnset(MEPnumber) = -1;
            app.toUseTable.endpoint(MEPnumber) = -1;
            writetable(app.toUseTable,getToUseLocation(app));

            updateGraphs(app);
        end

        % Value changed function: BaselineendEditField
        function BaselineendEditFieldValueChanged(app, event)
            MEPnumber = str2double(app.MEPSelector.Value(5:end));
            app.toUseTable.baselineEnd(MEPnumber) = app.BaselineendEditField.Value;
            writetable(app.toUseTable,getToUseLocation(app));

            updateGraphs(app);
        end

        % Value changed function: BaselinestartEditField
        function BaselinestartEditFieldValueChanged(app, event)
            MEPnumber = str2double(app.MEPSelector.Value(5:end));
            app.toUseTable.baselineStart(MEPnumber) = app.BaselinestartEditField.Value;
            writetable(app.toUseTable,getToUseLocation(app));

            updateGraphs(app);
        end

        % Value changed function: lambdaEditField
        function lambdaEditFieldValueChanged(app, event)
            MEPnumber = str2double(app.MEPSelector.Value(5:end));
            app.toUseTable.lambda(MEPnumber) = app.lambdaEditField.Value;
            writetable(app.toUseTable,getToUseLocation(app));

            updateGraphs(app);
        end

        % Value changed function: IsMEPCheckBox
        function IsMEPCheckBoxValueChanged(app, event)
            value = app.IsMEPCheckBox.Value;
            MEPnumber = str2double(app.MEPSelector.Value(5:end));
            app.toUseTable.isMEP(MEPnumber) = value;
            writetable(app.toUseTable,getToUseLocation(app));
            updateGraphs(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1377 726];
            app.UIFigure.Name = 'MATLAB App';

            % Create subjectSelector
            app.subjectSelector = uidropdown(app.UIFigure);
            app.subjectSelector.ValueChangedFcn = createCallbackFcn(app, @subjectSelectorValueChanged, true);
            app.subjectSelector.Position = [34 683 294 22];

            % Create quantitySelector
            app.quantitySelector = uidropdown(app.UIFigure);
            app.quantitySelector.Items = {'Whole Trial', 'All MEPs', 'Individual MEPs'};
            app.quantitySelector.ValueChangedFcn = createCallbackFcn(app, @quantitySelectorValueChanged, true);
            app.quantitySelector.Position = [661 683 216 22];
            app.quantitySelector.Value = 'Whole Trial';

            % Create Panel
            app.Panel = uipanel(app.UIFigure);
            app.Panel.AutoResizeChildren = 'off';
            app.Panel.Position = [35 189 1328 409];

            % Create MEPSelector
            app.MEPSelector = uidropdown(app.UIFigure);
            app.MEPSelector.Items = {'MEP 1'};
            app.MEPSelector.ValueChangedFcn = createCallbackFcn(app, @MEPSelectorValueChanged, true);
            app.MEPSelector.Position = [892 683 195 22];
            app.MEPSelector.Value = 'MEP 1';

            % Create trialsTable
            app.trialsTable = uitable(app.UIFigure);
            app.trialsTable.ColumnName = {'Num'; 'Description'; '% motor threshold'; 'machine setting'; 'Block start'; 'Block end'; '# std'};
            app.trialsTable.RowName = {};
            app.trialsTable.ColumnEditable = [false true true true true true true];
            app.trialsTable.CellEditCallback = createCallbackFcn(app, @trialsTableCellEdit, true);
            app.trialsTable.Position = [742 11 628 170];

            % Create UseDataCheckBox
            app.UseDataCheckBox = uicheckbox(app.UIFigure);
            app.UseDataCheckBox.ValueChangedFcn = createCallbackFcn(app, @UseDataCheckBoxValueChanged, true);
            app.UseDataCheckBox.Text = 'Use Data';
            app.UseDataCheckBox.Position = [821 616 72 22];

            % Create SingleMEPTable
            app.SingleMEPTable = uitable(app.UIFigure);
            app.SingleMEPTable.ColumnName = {'Measure'; 'Value'};
            app.SingleMEPTable.RowName = {};
            app.SingleMEPTable.Position = [46 11 378 143];

            % Create ExportsubjectButton
            app.ExportsubjectButton = uibutton(app.UIFigure, 'push');
            app.ExportsubjectButton.ButtonPushedFcn = createCallbackFcn(app, @ExportsubjectButtonPushed, true);
            app.ExportsubjectButton.Position = [34 646 135 23];
            app.ExportsubjectButton.Text = 'Export subject';

            % Create BlockMEPTable
            app.BlockMEPTable = uitable(app.UIFigure);
            app.BlockMEPTable.ColumnName = {'Measure'; 'Value'};
            app.BlockMEPTable.RowName = {};
            app.BlockMEPTable.Position = [445 11 283 143];

            % Create TrialbasedmeasuresLabel
            app.TrialbasedmeasuresLabel = uilabel(app.UIFigure);
            app.TrialbasedmeasuresLabel.Position = [49 168 120 22];
            app.TrialbasedmeasuresLabel.Text = 'Trial-based measures';

            % Create BlockbasedmeasuresLabel
            app.BlockbasedmeasuresLabel = uilabel(app.UIFigure);
            app.BlockbasedmeasuresLabel.Position = [426 168 129 22];
            app.BlockbasedmeasuresLabel.Text = 'Block-based measures';

            % Create ZoominCheckBox
            app.ZoominCheckBox = uicheckbox(app.UIFigure);
            app.ZoominCheckBox.ValueChangedFcn = createCallbackFcn(app, @ZoominCheckBoxValueChanged, true);
            app.ZoominCheckBox.Text = 'Zoom in';
            app.ZoominCheckBox.Position = [1108 683 66 22];

            % Create repetitionSelector
            app.repetitionSelector = uidropdown(app.UIFigure);
            app.repetitionSelector.ValueChangedFcn = createCallbackFcn(app, @repetitionSelectorValueChanged, true);
            app.repetitionSelector.Position = [344 683 294 22];

            % Create ExportallsubjectsButton
            app.ExportallsubjectsButton = uibutton(app.UIFigure, 'push');
            app.ExportallsubjectsButton.ButtonPushedFcn = createCallbackFcn(app, @ExportallsubjectsButtonPushed, true);
            app.ExportallsubjectsButton.Position = [185 646 135 23];
            app.ExportallsubjectsButton.Text = 'Export all subjects';

            % Create OpeninnewwindowButton
            app.OpeninnewwindowButton = uibutton(app.UIFigure, 'push');
            app.OpeninnewwindowButton.ButtonPushedFcn = createCallbackFcn(app, @OpeninnewwindowButtonPushed, true);
            app.OpeninnewwindowButton.Position = [1192 683 170 23];
            app.OpeninnewwindowButton.Text = 'Open in new window';

            % Create SelectlatencyonsetButton
            app.SelectlatencyonsetButton = uibutton(app.UIFigure, 'push');
            app.SelectlatencyonsetButton.ButtonPushedFcn = createCallbackFcn(app, @SelectlatencyonsetButtonPushed, true);
            app.SelectlatencyonsetButton.Visible = 'off';
            app.SelectlatencyonsetButton.Position = [566 645 123 23];
            app.SelectlatencyonsetButton.Text = 'Select latency onset';

            % Create SelectendpointButton
            app.SelectendpointButton = uibutton(app.UIFigure, 'push');
            app.SelectendpointButton.ButtonPushedFcn = createCallbackFcn(app, @SelectendpointButtonPushed, true);
            app.SelectendpointButton.Visible = 'off';
            app.SelectendpointButton.Position = [777 645 100 23];
            app.SelectendpointButton.Text = 'Select endpoint';

            % Create BaselinestartEditFieldLabel
            app.BaselinestartEditFieldLabel = uilabel(app.UIFigure);
            app.BaselinestartEditFieldLabel.HorizontalAlignment = 'right';
            app.BaselinestartEditFieldLabel.Position = [909 646 78 22];
            app.BaselinestartEditFieldLabel.Text = 'Baseline start';

            % Create BaselinestartEditField
            app.BaselinestartEditField = uieditfield(app.UIFigure, 'numeric');
            app.BaselinestartEditField.ValueChangedFcn = createCallbackFcn(app, @BaselinestartEditFieldValueChanged, true);
            app.BaselinestartEditField.Visible = 'off';
            app.BaselinestartEditField.Position = [1002 646 50 22];
            app.BaselinestartEditField.Value = -100;

            % Create BaselineendEditFieldLabel
            app.BaselineendEditFieldLabel = uilabel(app.UIFigure);
            app.BaselineendEditFieldLabel.HorizontalAlignment = 'right';
            app.BaselineendEditFieldLabel.Position = [1071 645 74 22];
            app.BaselineendEditFieldLabel.Text = 'Baseline end';

            % Create BaselineendEditField
            app.BaselineendEditField = uieditfield(app.UIFigure, 'numeric');
            app.BaselineendEditField.ValueChangedFcn = createCallbackFcn(app, @BaselineendEditFieldValueChanged, true);
            app.BaselineendEditField.Visible = 'off';
            app.BaselineendEditField.Position = [1160 645 54 22];

            % Create lambdaLabel
            app.lambdaLabel = uilabel(app.UIFigure);
            app.lambdaLabel.HorizontalAlignment = 'right';
            app.lambdaLabel.Visible = 'off';
            app.lambdaLabel.Position = [1252 646 25 22];
            app.lambdaLabel.Text = 'λ';

            % Create lambdaEditField
            app.lambdaEditField = uieditfield(app.UIFigure, 'numeric');
            app.lambdaEditField.ValueChangedFcn = createCallbackFcn(app, @lambdaEditFieldValueChanged, true);
            app.lambdaEditField.Visible = 'off';
            app.lambdaEditField.Position = [1293 646 54 22];
            app.lambdaEditField.Value = 3;

            % Create ResetlatencyendpointButton
            app.ResetlatencyendpointButton = uibutton(app.UIFigure, 'push');
            app.ResetlatencyendpointButton.ButtonPushedFcn = createCallbackFcn(app, @ResetlatencyendpointButtonPushed, true);
            app.ResetlatencyendpointButton.Visible = 'off';
            app.ResetlatencyendpointButton.Position = [357 645 146 23];
            app.ResetlatencyendpointButton.Text = 'Reset latency / endpoint';

            % Create IsMEPCheckBox
            app.IsMEPCheckBox = uicheckbox(app.UIFigure);
            app.IsMEPCheckBox.ValueChangedFcn = createCallbackFcn(app, @IsMEPCheckBoxValueChanged, true);
            app.IsMEPCheckBox.Text = 'Is MEP?';
            app.IsMEPCheckBox.Position = [742 616 67 22];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = MEP_viewer_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end