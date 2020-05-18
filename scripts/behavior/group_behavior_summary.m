function allData = group_behavior_summary(sublist, session_name, idx_fig)



% check the input arguments
% subject list
if nargin<1 | isempty(sublist)
    
    sublist = {
        'CM10006';
        'DC10004';
        'DD8455';
        'IA10010';
        'JM10021';
        'KC10014';
        'KD3603';
        'KL10012';
        'NB8419';
        'NN8813';
        'QH10013';
        'QW3602';
        'SA10005';
        'TC10003';
        'TQ3600';
        'TT8602';
        };
    
else
    if ~iscell(sublist)
        sublist = {sublist};
    end
end
nSubj = numel(sublist);

% session
if nargin<2
    session_name = 'scan';
end

% whether to draw figures
if nargin<3
    idx_fig = 1;
end
fig_output = 1;



% directory
dirVariable = '../../behavior_variables';
dirFig = '../../figures';
mkdir(dirFig);


% setting
list_block = {'LN','HN'};
nBlock = numel(list_block);

% list_model
list_model = {
    'RB';
    'RL';
    'RB_RL_weighting';
    'RB_stay';
    };
nModel = numel(list_model);

% list_errMag
list_errMag = [0:5];
nErrMag = numel(list_errMag);

% list_errMag_max3
list_errMag_max3 = [0, 1, 2, 3];
nErrMag_max3 = numel(list_errMag_max3);

% list_trial_after_cp
list_trial_after_cp = [0:20];
n_tac = numel(list_trial_after_cp);

% list_feedback_history
list_feedback_history = [
    0,0,0;
    0,0,1;
    0,1,0;
    0,1,1;
    1,0,0;
    1,0,1;
    1,1,0;
    1,1,1;
    ];
nHistory = size(list_feedback_history,1);

for s = 1:nSubj
    
    % subname
    subname = sublist{s};
    
    % load data
    behavior_variable_file = fullfile(dirVariable, sprintf('%s_%s.mat', session_name, subname));
    load(behavior_variable_file);
    
    for b = 1:nBlock
        
        
        %%%%% block data %%%%%
        block_name = list_block{b};
        blockData = exp_var.(block_name);
        
        % remove non-choice trials
        idx_choice = ([blockData.idx_choice]'==1);
        
        blockData = blockData(idx_choice);
        
        % organize data
        design_errMag = [blockData.errMag]';
        design_errMag_max3 = design_errMag;
        design_errMag_max3(design_errMag_max3>3) = 3;
        
        design_trial_after_cp = [blockData.trial_after_cp]';
        design_cp_idx = [blockData.cp_idx]';
        design_bestTarget = [blockData.bestTarget]';
        design_choice = [blockData.choice]';
        
        data_update = [blockData.update]';
        data_switch = double(data_update>=0.5);
        
        design_correct = double(design_errMag_max3==0);
        
        design_feedback_n1 = [NaN; design_correct(1:end-1)];
        design_feedback_n2 = [NaN; NaN; design_correct(1:end-2)];
        design_feedback_n3 = [NaN; NaN; NaN; design_correct(1:end-3)];
        design_feedback_history = [design_feedback_n1, design_feedback_n2, design_feedback_n3];
        
        
        % keep trials with good update
        idx_goodupdate = logical([blockData.idx_goodupdate]');
        
        design_errMag = design_errMag(idx_goodupdate);
        design_errMag_max3 = design_errMag_max3(idx_goodupdate);
        design_trial_after_cp = design_trial_after_cp(idx_goodupdate);
        design_cp_idx = design_cp_idx(idx_goodupdate);
        design_bestTarget = design_bestTarget(idx_goodupdate);
        design_choice = design_choice(idx_goodupdate);
        
        data_switch = data_switch(idx_goodupdate);
        
        design_feedback_history = design_feedback_history(idx_goodupdate, :);
        
        % nTrial
        nTrial = numel(design_choice);
        
        %%%%% model prediction %%%%%
        for m = 1:nModel
            
            % model_name
            model_name = list_model{m};
            
            % organize data
            modelData = model_prediction.(model_name).(block_name);
            modelData = modelData(idx_choice);
            
            model_choice = [modelData.choice]';
            model_update = [modelData.update]';
            model_switch = double(model_update>=0.5);
            
            % keep trials with good update
            model_choice = model_choice(idx_goodupdate);
            model_switch = model_switch(idx_goodupdate);
            
            % merge data
            model_data.(model_name).choice = model_choice;
            model_data.(model_name).switch = model_switch;
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% p(switch) against errMag %%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for i = 1:nErrMag
            
            % idx_select
            idx_errMag = (design_errMag==list_errMag(i));
            
            %%%%% data %%%%%
            % average
            if sum(idx_errMag)>0
                p_switch = mean(data_switch(idx_errMag));
            else
                p_switch = NaN;
            end
            allData.data.p_switch_errMag.(block_name)(s,i) = p_switch;
            
            %%%%% model %%%%%
            for m = 1:nModel
                
                % model_name
                model_name = list_model{m};
                
                % model_var
                model_switch = model_data.(model_name).switch;
                
                % average
                if sum(idx_errMag)>0
                    p_switch = mean(model_switch(idx_errMag));
                else
                    p_switch = NaN;
                end
                allData.model.(model_name).p_switch_errMag.(block_name)(s,i) = p_switch;
                
            end % end of model
            
        end % end of errMag
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% p(switch) against error history by errMag %%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for c = 1:nErrMag_max3
            
            % idx_errMag
            errMag_val = list_errMag_max3(c);
            idx_errMag = (design_errMag_max3==errMag_val);
            
            for h = 1:nHistory
                
                % idx_history
                current_history = list_feedback_history(h,:);
                current_history = repmat(current_history, nTrial, 1);
                
                idx_history = (sum(abs(design_feedback_history - current_history),2)==0);
                
                % idx_select
                idx_select = idx_errMag&idx_history;
                
                %%%%% data %%%%%
                % average
                if sum(idx_select)>0
                    p_switch = mean(data_switch(idx_select));
                else
                    p_switch = NaN;
                end
                allData.data.p_switch_error_history_by_errMag.(block_name)(s,h,c) = p_switch;
                
                %%%%% model %%%%%
                for m = 1:nModel
                    
                    % model_name
                    model_name = list_model{m};
                    
                    % model_var
                    model_switch = model_data.(model_name).switch;
                    
                    % average
                    if sum(idx_select)>0
                        p_switch = mean(model_switch(idx_select));
                    else
                        p_switch = NaN;
                    end
                    allData.model.(model_name).p_switch_error_history_by_errMag.(block_name)(s,h,c) = p_switch;
                    
                end % end of model
                
            end % end of errMag_history
            
        end % end of errMag_max3
        
        
        %%%%% slope: data %%%%%
        for c = 1:nErrMag_max3
            
            data = allData.data.p_switch_error_history_by_errMag.(block_name)(s,:,c);
            
            x = linspace(-0.5,0.5,nHistory)';
            y = data';
            [reg_beta] = glmfit(x,y);
            slope_subject = reg_beta(2);
            
            allData.data.p_switch_error_history_by_errMag_slope.(block_name)(s,c) = slope_subject;
            
        end
        
        
        
        %%%%% slope: model %%%%%
        for m = 1:nModel
            
            % model_name
            model_name = list_model{m};
            
            for c = 1:nErrMag_max3
                
                data = allData.model.(model_name).p_switch_error_history_by_errMag.(block_name)(s,:,c);
                
                x = linspace(-0.5,0.5,nHistory)';
                y = data';
                [reg_beta] = glmfit(x,y);
                slope_subject = reg_beta(2);
                
                allData.model.(model_name).p_switch_error_history_by_errMag_slope.(block_name)(s,c) = slope_subject;
                
            end
            
        end % end of model
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% p(best) after change-point %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        max_cp = max(design_cp_idx);
        
        %%%%% data %%%%%
        cp_choice_best = NaN(max_cp, n_tac);
        for c = 1:max_cp
            
            idx_cp = (design_cp_idx==c);
            current_choice_best = double(design_choice(idx_cp)==design_bestTarget(idx_cp));
            current_list_tac = design_trial_after_cp(idx_cp);
            
            for i = 1:min(n_tac, numel(current_list_tac))
                
                cp_choice_best(c,i) = current_choice_best(i);
                
            end
        end
        allData.data.p_best_after_cp.(block_name)(s,:) = nanmean(cp_choice_best);
        
        %%%%% model %%%%%
        for m = 1:nModel
            
            % model_name
            model_name = list_model{m};
            
            % model_var
            model_choice = model_data.(model_name).choice;
            
            % average
            cp_choice_best = NaN(max_cp, n_tac);
            for c = 1:max_cp
                
                idx_cp = (design_cp_idx==c);
                current_choice_best = double(model_choice(idx_cp)==design_bestTarget(idx_cp));
                current_list_tac = design_trial_after_cp(idx_cp);
                
                for i = 1:min(n_tac, numel(current_list_tac))
                    
                    cp_choice_best(c,i) = current_choice_best(i);
                    
                end
            end
            allData.model.(model_name).p_best_after_cp.(block_name)(s,:) = nanmean(cp_choice_best);
            
        end % end of model
        
        
    end % end of block
    
end % end of subject



% graph
model_best = 'RB';
list_model{end+1} = 'data';
list_model{end+1} = 'data_and_model';
nModel = numel(list_model);
if idx_fig
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% p(switch) against errMag %%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    x_adjust = [-0.04, 0.04];
    facecolor = {[0.8320, 0.3672, 0],[0, 0.4453, 0.6953]};
    edgecolor = {'k','k'};
    
    
    for m = 1:nModel
        
        % model_name
        model_name = list_model{m};
        
        
        figure;
        fg = fig_setting_default;
        hold on
        
        h = [];
        idx_legend = 0;
        
        switch model_name
            case {'data'}
                
            otherwise
                
                switch model_name
                    case {'data_and_model'}
                        model_select = model_best;
                    otherwise
                        model_select = model_name;
                end
                
                for b = 1:nBlock
                    
                    idx_legend = idx_legend + 1;
                    
                    block_name = list_block{b};
                    data = allData.model.(model_select).p_switch_errMag.(block_name);
                    meanData = nanmean(data,1);
                    stdData = nanstd(data,1);
                    nSubj = sum(~isnan(data),1);
                    semData = stdData./sqrt(nSubj);
                    
                    xData = list_errMag + x_adjust(b);
                    e = errorbar(xData, meanData, semData,...
                        'Marker', 'none',...
                        'LineStyle', 'none'...
                        );
                    
                    set(e,...
                        'Color', [0,0,0],...
                        'LineWidth', 2 ...
                        );
                    
                    h(idx_legend) = plot(xData, meanData,...
                        'LineWidth', 2,...
                        'LineStyle', 'none',...
                        'Marker', 'd',...
                        'MarkerSize', 16,...
                        'MarkerFaceColor', 'w',...
                        'MarkerEdgeColor', facecolor{b} ...
                        );
                    
                end
        end
        
        switch model_name
            case {'data', 'data_and_model'}
                
                for b = 1:nBlock
                    
                    idx_legend = idx_legend + 1;
                    
                    block_name = list_block{b};
                    data = allData.data.p_switch_errMag.(block_name);
                    meanData = nanmean(data,1);
                    stdData = nanstd(data,1);
                    nSubj = sum(~isnan(data),1);
                    semData = stdData./sqrt(nSubj);
                    
                    xData = list_errMag + x_adjust(b);
                    e = errorbar(xData, meanData, semData,...
                        'Marker', 'none',...
                        'LineStyle', 'none'...
                        );
                    
                    set(e,...
                        'Color', [0,0,0],...
                        'LineWidth', 2 ...
                        );
                    
                    h(idx_legend) = plot(xData, meanData,...
                        'LineWidth', 2,...
                        'LineStyle', 'none',...
                        'Marker', 'o',...
                        'MarkerSize', 16,...
                        'MarkerFaceColor', facecolor{b},...
                        'MarkerEdgeColor', edgecolor{b} ...
                        );
                    
                end
                
        end
        
        hold off
        xlim([list_errMag(1)-0.5, list_errMag(end)+0.5]);
        ylim([0,1]);
        
        set(gca, 'XTick', list_errMag, 'YTick', [0:0.2:1]);
        set(gca, 'fontsize', 32, 'linewidth', 4);
        
        xlabel('Error magnitude', 'fontsize', 32);
        ylabel('P(switch)', 'fontsize', 32);
        
        switch model_name
            case {'data'}
                
                legend_text = {
                    'Unstable';
                    'High-noise';
                    };
                legend(h, legend_text,...
                    'location', 'SouthEast',...
                    'fontsize', 24 ...
                    );
                
            case {'data_and_model'}
                
                legend_text = {
                    'Model: Unstable';
                    'Model: High-noise';
                    'Data: Unstable';
                    'Data: High-noise';
                    };
                legend(h, legend_text,...
                    'location', 'SouthEast',...
                    'fontsize', 24 ...
                    );
                
        end
        
        % output figure
        if fig_output
            
            figure_file = fullfile(dirFig,sprintf('behavior_p_switch_errMag_group_%s', model_name));
            print(figure_file,'-depsc');
            
        end
        
    end
    
    %%%%% statistical testing %%%%%
    x_diff = (allData.data.p_switch_errMag.HN - allData.data.p_switch_errMag.LN);
    for i = 1:nErrMag
        
        current_data = x_diff(:,i);
        idx_notnan = ~isnan(current_data);
        current_data = current_data(idx_notnan);
        
        [pval] = signtest(current_data);
        data_median = median(current_data);
        iqr = quantile(current_data, [0.25, 0.75]);
        
        fprintf('errMag=%d: median=%.3f, IQR=[%.3f, %.3f], pval=%.4f\n',...
            list_errMag(i), data_median, iqr(1), iqr(2), pval);
        
    end
    
    
    
    
    %%%%% distribution %%%%%
    switch_rate_subject = cat(3,allData.data.p_switch_errMag.LN,allData.data.p_switch_errMag.HN);
    
    text_legend = {'errMag=2', 'errMag=1'};
    list_location = [3,2];
    nLocation = numel(list_location);
    list_marker = {'^','s'};
    list_facecolor = {
        'w';
        [0.5,0.5,0.5];
        };
    list_edgecolor = {
        'k';
        'k';
        };
    
    figure;
    fg = fig_setting_default;
    
    axis('image')
    hold on
    plot([0;1],[0;1],...
        'linestyle', '-',...
        'linewidth', 4,...
        'color', 'k');
    h = NaN(1,nLocation);
    for i = 1:nLocation
        
        x1 = switch_rate_subject(:,list_location(i),1);
        x2 = switch_rate_subject(:,list_location(i),2);
        
        h(i) = plot(x1,x2,...
            'linestyle', 'none',...
            'linewidth', 2,...
            'marker', list_marker{i},...
            'markersize', 16,...
            'markerfacecolor', list_facecolor{i},...
            'markeredgecolor', list_edgecolor{i});
    end
    hold off
    set(gca, 'XTick', [0:0.2:1], 'YTick', [0:0.2:1]);
    set(gca, 'fontsize', 32, 'linewidth', 4);
    xlabel('P(switch): Unstable', 'fontsize', 32);
    ylabel('P(switch): High-noise', 'fontsize', 32);
    xlim([0,1]);
    ylim([0,1]);
    
    h = h(end:-1:1);
    text_legend = text_legend(end:-1:1);
    legend(h, text_legend, 'location', 'NorthWest','fontsize',24);
    
    % output figure
    if fig_output
        
        figure_file = fullfile(dirFig,sprintf('behavior_p_switch_by_errMag_distribution_uncertain'));
        print(figure_file,'-depsc');
        
    end
    
    
    
    
    
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% p(best) after change-point %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    facecolor = {[0.8320, 0.3672, 0],[0, 0.4453, 0.6953]};
    edgecolor = {'k','k'};
    
    
    for m = 1:nModel
        
        % model_name
        model_name = list_model{m};
        
        figure;
        fg = fig_setting_default;
        
        hold on
        
        h = [];
        idx_legend = 0;
        
        switch model_name
            case {'data'}
                
            otherwise
                
                switch model_name
                    case {'data_and_model'}
                        model_select = model_best;
                    otherwise
                        model_select = model_name;
                end
                
                for b = 1:nBlock
                    
                    idx_legend = idx_legend + 1;
                    
                    block_name = list_block{b};
                    data = allData.model.(model_select).p_best_after_cp.(block_name);
                    meanData = nanmean(data,1);
                    stdData = nanstd(data,1);
                    nSubj = sum(~isnan(data),1);
                    semData = stdData./sqrt(nSubj);
                    
                    e = errorbar(list_trial_after_cp, meanData, semData,...
                        'Marker', 'none',...
                        'LineStyle', 'none'...
                        );
                    
                    set(e,...
                        'Color', [0,0,0],...
                        'LineWidth', 2 ...
                        );
                    
                    h(idx_legend) = plot(list_trial_after_cp, meanData,...
                        'LineWidth', 2,...
                        'LineStyle', 'none',...
                        'Marker', 'd',...
                        'MarkerSize', 16,...
                        'MarkerFaceColor', 'w',...
                        'MarkerEdgeColor', facecolor{b} ...
                        );
                    
                    
                    
                end
                
        end
        
        
        switch model_name
            case {'data', 'data_and_model'}
                
                for b = 1:nBlock
                    
                    idx_legend = idx_legend + 1;
                    
                    block_name = list_block{b};
                    data = allData.data.p_best_after_cp.(block_name);
                    meanData = nanmean(data,1);
                    stdData = nanstd(data,1);
                    nSubj = sum(~isnan(data),1);
                    semData = stdData./sqrt(nSubj);
                    
                    e = errorbar(list_trial_after_cp, meanData, semData,...
                        'Marker', 'none',...
                        'LineStyle', 'none'...
                        );
                    
                    set(e,...
                        'Color', [0,0,0],...
                        'LineWidth', 2 ...
                        );
                    
                    h(idx_legend) = plot(list_trial_after_cp, meanData,...
                        'LineWidth', 2,...
                        'LineStyle', 'none',...
                        'Marker', 'o',...
                        'MarkerSize', 16,...
                        'MarkerFaceColor', facecolor{b},...
                        'MarkerEdgeColor', edgecolor{b} ...
                        );
                    
                end
                
        end
        
        hold off
        xlim([list_trial_after_cp(1)-0.5, list_trial_after_cp(end)+0.5]);
        ylim([0,1]);
        
        set(gca, 'XTick', [0,5:5:20], 'YTick', [0:0.2:1]);
        set(gca, 'fontsize', 32, 'linewidth', 4);
        
        xlabel('Trial after change-point', 'fontsize', 32);
        ylabel('P(choice = state)', 'fontsize', 32);
        
        switch model_name
            case {'data'}
                
                legend_text = {
                    'Unstable';
                    'High-noise';
                    };
                
                legend(h, legend_text,...
                    'location', 'SouthEast',...
                    'fontsize', 24 ...
                    );
                
            case {'data_and_model'}
                
                legend_text = {
                    'Model: Unstable';
                    'Model: High-noise';
                    'Data: Unstable';
                    'Data: High-noise';
                    };
                
                legend(h, legend_text,...
                    'location', 'SouthEast',...
                    'fontsize', 24 ...
                    );
        end
        
        % output figure
        if fig_output
            
            figure_file = fullfile(dirFig,sprintf('behavior_p_best_after_cp_group_%s',model_name));
            print(figure_file,'-depsc');
            
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% p(switch) against error history by errMag %%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    clear plotData plotParameter meanData stdData semData
    
    colormap{1}(:,1) = linspace(0.8320, 0.9, 64);
    colormap{1}(:,2) = linspace(0.3672, 0.9, 64);
    colormap{1}(:,3) = linspace(0, 0.9, 64);
    colormap{2}(:,1) = linspace(0, 0.9, 64);
    colormap{2}(:,2) = linspace(0.4453, 0.9, 64);
    colormap{2}(:,3) = linspace(0.6953, 0.9, 64);
    
    %     list_error_history_name = list_feedback_history;
    %     list_error_history_name(list_feedback_history==0) = 'E';
    %     list_error_history_name(list_feedback_history==1) = 'C';
    %     list_error_history_name = char(list_error_history_name);
    
    for b = 1:nBlock
        
        idx_color = round(linspace(1,64,nHistory));
        facecolor = cell(nHistory,1);
        edgecolor = cell(nHistory,1);
        text_legend = cell(nHistory,1);
        text_legend_data_model = cell(nHistory,1);
        for h = 1:nHistory
            custom_color = colormap{b};
            facecolor{h} = custom_color(idx_color(h),:);
            edgecolor{h} = 'k';
            text_history = [];
%             for i = 1:3
%                 text_history = [text_history, sprintf('%d', list_feedback_history(h,i))];
%             end
            for i = 1:3
                if list_feedback_history(h,i)==0
                    text_history = [text_history, 'X'];
                elseif list_feedback_history(h,i)==1
                    text_history = [text_history, 'O'];
                end
            end
            text_legend{h} = text_history;
            text_legend_data_model{h} = text_history;
            text_legend_data_model{h} = ['   ', text_legend_data_model{h}];
        end
        xoffset = linspace(-0.09*nHistory/2,0.09*nHistory/2,nHistory);
        
        block_name = list_block{b};
        
        
        for m = 1:nModel
            
            % model_name
            model_name = list_model{m};
            
            
            figure;
            fg = fig_setting_default;
            
            xlim([list_errMag_max3(1)-0.5, list_errMag_max3(end)+0.5]);
            ylim([0,1]);
            
            hold on
            
            h_marker = [];
            
            switch model_name
                case {'data'}
                    
                otherwise
                    
                    switch model_name
                        case {'data_and_model'}
                            model_select = model_best;
                        otherwise
                            model_select = model_name;
                    end
                    
                    for c = 1:nErrMag_max3
                        
                        data = allData.model.(model_select).p_switch_error_history_by_errMag.(block_name)(:,:,c);
                        meanData = nanmean(data,1);
                        stdData = nanstd(data,1);
                        nSubj = sum(~isnan(data),1);
                        semData = stdData./sqrt(nSubj);
                        
                        
                        for h = 1:nHistory
                            xpos = list_errMag_max3(c)+xoffset(h);
                            ypos = meanData(h);
                            
                            e = errorbar(xpos, ypos, semData(h),...
                                'Marker', 'none',...
                                'LineStyle', 'none'...
                                );
                            
                            set(e,...
                                'Color', [0,0,0],...
                                'LineWidth', 2 ...
                                );
                            
                            h_marker(h) = plot(xpos, ypos,...
                                'LineWidth', 2,...
                                'LineStyle', 'none',...
                                'Marker', 'd',...
                                'MarkerSize', 16,...
                                'MarkerFaceColor', 'w',...
                                'MarkerEdgeColor', facecolor{h});
                            
                        end
                        
                    end
                    
            end
            
            h_marker_data = [];
            switch model_name
                case {'data', 'data_and_model'}
                    
                    for c = 1:nErrMag_max3
                        
                        data = allData.data.p_switch_error_history_by_errMag.(block_name)(:,:,c);
                        meanData = nanmean(data,1);
                        stdData = nanstd(data,1);
                        nSubj = sum(~isnan(data),1);
                        semData = stdData./sqrt(nSubj);
                        
                        
                        for h = 1:nHistory
                            xpos = list_errMag_max3(c)+xoffset(h);
                            ypos = meanData(h);
                            
                            e = errorbar(xpos, ypos, semData(h),...
                                'Marker', 'none',...
                                'LineStyle', 'none'...
                                );
                            
                            set(e,...
                                'Color', [0,0,0],...
                                'LineWidth', 2 ...
                                );
                            
                            h_marker_data(h) = plot(xpos, ypos,...
                                'LineWidth', 2,...
                                'LineStyle', 'none',...
                                'Marker', 'o',...
                                'MarkerSize', 16,...
                                'MarkerFaceColor', facecolor{h},...
                                'MarkerEdgeColor', edgecolor{h});
                            
                        end
                        
                    end
                    
            end
            
            h_marker_text = [];
            switch model_name
                case {'data_and_model'}
                    h_marker_text(1) = plot(NaN,NaN,...
                        'LineWidth', 2,...
                        'LineStyle', 'none',...
                        'Marker', 'd',...
                        'MarkerSize', 16,...
                        'MarkerFaceColor', 'w',...
                        'MarkerEdgeColor', facecolor{1});
                    h_marker_text(2) = plot(NaN,NaN,...
                        'LineWidth', 2,...
                        'LineStyle', 'none',...
                        'Marker', 'o',...
                        'MarkerSize', 16,...
                        'MarkerFaceColor', facecolor{1},...
                        'MarkerEdgeColor', edgecolor{1});
            end
            
            hold off
            
            set(gca, 'XTick', list_errMag_max3, 'XTickLabel', {'0', '1', '2', '3+'}, 'YTick', [0:0.2:1]);
            set(gca, 'fontsize', 32, 'linewidth', 4);
            
            xlabel('Error magnitude', 'fontsize', 32);
            ylabel('P(switch)', 'fontsize', 32);
            
            
            
            switch model_name
                case {'data'}
                    
                    lh = legend(h_marker_data, text_legend, 'location', 'NorthWest','fontsize',24);
                    lh.Position(1) = lh.Position(1)-0.008;
                    
                case {'data_and_model'}
                    
                    lh_model = legend(h_marker, text_legend_data_model, 'location', 'EastOutside', 'fontsize', 24);
                    
                    new_ax = axes;
                    set(new_ax, 'fontsize', 32, 'linewidth', 4);
                    axis(new_ax,'off');
                    lh = legend(new_ax, h_marker_data, text_legend_data_model, 'location', 'EastOutside','fontsize',24, 'TextColor', 'none', 'box', 'off');
                    lh.Position(1) = lh_model.Position(1)+0.035;
                    lh.Position(2) = lh_model.Position(2);
                    
                    new_ax = axes;
                    set(new_ax, 'fontsize', 32, 'linewidth', 4);
                    axis(new_ax,'off');
                    
                    lh_text = legend(new_ax, h_marker_text, {'Model'; 'Data'}, 'location', 'EastOutside', 'fontsize', 24);
                    lh_text.Position(1) = lh_model.Position(1);
                    lh_text.Position(2) = lh_model.Position(2) - lh_text.Position(4) - 0.02;
                    lh_text.Position(3) = lh_model.Position(3);
                    
            end
            
            % output figure
            if fig_output
                
                figure_file = fullfile(dirFig,sprintf('behavior_p_switch_error_history_by_errMag_%s_%s',block_name, model_name));
                print(figure_file,'-depsc');
                
            end
            
        end
        
    end
    
    
    %%%%% slope %%%%%
    clear plotData plotParameter meanData stdData semData
    
    %%%%% slope: statistics %%%%%
    for b = 1:nBlock
        
        % blockname
        block_name = list_block{b};
        
        for c = 1:nErrMag_max3
            
            current_data = allData.data.p_switch_error_history_by_errMag_slope.(block_name)(:,c);
            idx_notnan = ~isnan(current_data);
            current_data = current_data(idx_notnan);
            
            [pval] = signtest(current_data);
            data_median = median(current_data);
            iqr = quantile(current_data, [0.25, 0.75]);
            
            fprintf('%s, errMag=%d: median=%.3f, IQR=[%.3f, %.3f], pval=%.4f\n',...
                block_name, list_errMag_max3(c), data_median, iqr(1), iqr(2), pval);
            
        end
    end
    
    
    
    
    %%%%% slope: distribution %%%%%
    text_legend = {'errMag=2', 'errMag=1'};
    list_location = [3,2];
    nLocation = numel(list_location);
    list_marker = {'^','s'};
    list_facecolor = {
        'w';
        [0.5,0.5,0.5];
        };
    list_edgecolor = {
        'k';
        'k';
        };
    
    figure;
    fg = fig_setting_default;
    axis('image');
    hold on
    plot([-0.8;0.8],[-0.8;0.8],...
        'linestyle', '-',...
        'linewidth', 4,...
        'color', 'k');
    plot([0;0],[-0.8;0.8],...
        'linestyle', '--',...
        'linewidth', 4,...
        'color', [0.5,0.5,0.5]);
    plot([-0.8;0.8],[-0;0],...
        'linestyle', '--',...
        'linewidth', 4,...
        'color', [0.5,0.5,0.5]);
    
    h = NaN(1,nLocation);
    for i = 1:nLocation
        
        x1 = allData.data.p_switch_error_history_by_errMag_slope.LN(:,list_location(i));
        x2 = allData.data.p_switch_error_history_by_errMag_slope.HN(:,list_location(i));
        
        h(i) = plot(x1,x2,...
            'linestyle', 'none',...
            'linewidth', 2,...
            'marker', list_marker{i},...
            'markersize', 16,...
            'markerfacecolor', list_facecolor{i},...
            'markeredgecolor', list_edgecolor{i});
    end
    hold off
    set(gca, 'fontsize', 32, 'linewidth', 4);
    xlabel('Slope: Unstable (a. u.)', 'fontsize', 32);
    ylabel('Slope: High-noise (a. u.)', 'fontsize', 32);
    xlim([-0.8,0.8]);
    ylim([-0.8,0.8]);
    set(gca,'XTick',[-0.8:0.4:0.8],'YTick',[-0.8:0.4:0.8]);
    
    h = h(end:-1:1);
    text_legend = text_legend(end:-1:1);
    legend(h, text_legend, 'location', 'NorthWest','fontsize',24);
    
    
    % output figure
    if fig_output
        
        figure_file = fullfile(dirFig,sprintf('behavior_p_switch_error_history_by_errMag_slope_distribution_uncertain'));
        print(figure_file,'-depsc');
        
    end
    
    
end
