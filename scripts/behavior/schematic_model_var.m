function allData = schematic_model_var()

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
nSub = numel(sublist);

% directory
dirVariable = '../../behavior_variables';
dirFig = '../../figures';
mkdir(dirFig);

% session
session_name = 'scan';

% setting
list_block = {'LN', 'HN'};
nBlock = numel(list_block);

list_errMag = [0:5];
nErrMag = numel(list_errMag);

list_feedback_n1 = [1, 0];
nFeedback_n1 = numel(list_feedback_n1);

list_var = {
    'cpp', 'CPP';
    'ru', 'RU';
    'isSwitch', 'P(switch)';
    'legend', 'legend';
    };
nVar = size(list_var,1);

% model_name = 'RB_ideal';
model_name = 'RB';

for s = 1:nSub
    
    % subname
    subname = sublist{s};
    
    % load file
    filename = sprintf('%s_%s.mat', session_name, subname);
    filename = fullfile(dirVariable, filename);
    load(filename);
    
    for b = 1:nBlock
        
        % blockname
        blockname = list_block{b};
        
        %%%%% block data %%%%%
        block_name = list_block{b};
        blockData = exp_var.(block_name);
        modelData = model_prediction.(model_name).(blockname);
        
        % remove non-choice trials
        idx_choice = ([blockData.idx_choice]'==1)&...
            ([blockData.idx_valid_trial_first]'~=1)&...
            ([blockData.idx_valid_trial_last]'~=1);
        
        blockData = blockData(idx_choice);
        modelData = modelData(idx_choice);
        
        % organize data
        cpp_all = [modelData.cpp]';
        ru_all = [modelData.ru]';
        
        errMag_all = [blockData.errMag]';
        errMag_n1_all = [NaN; errMag_all(1:end-1)];
        
        feedback_all = double(errMag_all==0);
        feedback_n1_all = [NaN;feedback_all(1:end-1)];
        
        % keep trials with good update
        idx_goodupdate = logical([blockData.idx_goodupdate]');
        
        cpp_all = cpp_all(idx_goodupdate);
        ru_all = ru_all(idx_goodupdate);
        errMag_all = errMag_all(idx_goodupdate);
        errMag_n1_all = errMag_n1_all(idx_goodupdate);
        feedback_all = feedback_all(idx_goodupdate);
        feedback_n1_all = feedback_n1_all(idx_goodupdate);
        
        
        % model_var
        nTrial = numel(cpp_all);
        LR_all = cpp_all + (1-cpp_all).*ru_all;
        update_all = LR_all.*errMag_all;
        isSwitch = (update_all>=0.5);
        
        model_var.cpp = cpp_all;
        model_var.ru = ru_all;
        model_var.LR = LR_all;
        model_var.update = update_all;
        model_var.isSwitch = isSwitch;
        model_var.legend = NaN(nTrial,1);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% model_var vs errMag conditional on feedback_n1 %%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for e = 1:nErrMag
            
            % current_errMag
            current_errMag = list_errMag(e);
            idx_errMag = (errMag_all==current_errMag);
            
            for f = 1:nFeedback_n1
                
                % current_feedback_n1
                current_feedback_n1 = list_feedback_n1(f);
                idx_feedback_n1 = (feedback_n1_all==current_feedback_n1);
                
                idx_select = idx_errMag&idx_feedback_n1;
                
                for v = 1:nVar
                    
                    % var_name
                    var_name = list_var{v,1};
                    current_var = model_var.(var_name);
                    
                    % mean
                    meanVal = nanmean(current_var(idx_select));
                    allData.errMag_feedback_n1.(var_name){b}(s,e,f) = meanVal;
                    
                end % end of var
                
            end % end of feedback_n1
        end % end of errMag
        
        
    end % end of block
end % end of subject


%%%%%%%%%%%%%%%%%%
%%%%% figure %%%%%
%%%%%%%%%%%%%%%%%%
color_block = {
    [0.8320, 0.3672, 0];
    [0, 0.4453, 0.6953]};

%%%%% errMag conditional on feedback_n1 %%%%%
for v = 1:nVar
    
    % var_name
    var_name = list_var{v,1};
    
    % figure;
    figure;
    fig_setting_default;
    hold on
    clear h_line
    idx_line = 0;
    
    for b = 1:nBlock
        for f = 1:nFeedback_n1
            
            idx_line = idx_line + 1;
            
            subData = allData.errMag_feedback_n1.(var_name){b}(:,:,f);
            meanData = nanmean(subData,1);
            
            switch f
                case {1}
                    h_line(idx_line) = plot(list_errMag, meanData,...
                        'linestyle', '-',...
                        'color', color_block{b},...
                        'linewidth', 4,...
                        'marker', 'o',...
                        'markersize', 20,...
                        'markerfacecolor', 'none',...
                        'markeredgecolor', color_block{b});
                case {2}
                    h_line(idx_line) = plot(list_errMag, meanData,...
                        'linestyle', '--',...
                        'color', color_block{b},...
                        'linewidth', 4,...
                        'marker', 'x',...
                        'markersize', 20,...
                        'markerfacecolor', 'none',...
                        'markeredgecolor', color_block{b});
            end
            
        end
    end
    hold off
    
    set(gca, 'fontsize', 32, 'linewidth', 4);
    
    xlim([-0.5,5.5]);
    switch var_name
        case {'cpp', 'ru', 'LR', 'isSwitch'}
            ylim([0,1.05]);
        case {'update'}
            ylim([0,5.25]);
    end
    
    xlabel('Error magnitude', 'fontsize', 32);
    ylabel('Value', 'fontsize', 32);
    
    set(gca, 'XTick', list_errMag);
    
    title_name = list_var{v,2};
    title(title_name, 'fontsize', 32);
    
    switch var_name
        case {'legend'}
            axis off
            legend_name = {
                'Unstable: past correct';
                'Unstable: past error';
                'High-noise: past correct';
                'High-noise: past error'};
            [h_legend, icons] = legend(h_line, legend_name,...
                'fontsize', 20,...
                'location', 'South');
            
            h_legend.Position(3) = 0.5;
            
            icons(1).FontSize = 20;
            icons(1).Position(1) = 0.22;
            icons(2).FontSize = 20;
            icons(2).Position(1) = 0.22;
            icons(3).FontSize = 20;
            icons(3).Position(1) = 0.22;
            icons(4).FontSize = 20;
            icons(4).Position(1) = 0.22;
            
            icons(5).XData = [0.01, 0.2];
            icons(5).LineWidth = 4;
            icons(6).XData = 0.09;
            icons(6).LineWidth = 4;
            icons(7).XData = [0.01, 0.2];
            icons(7).LineWidth = 4;
            icons(8).XData = 0.09;
            icons(8).LineWidth = 4;
            icons(9).XData = [0.01, 0.2];
            icons(9).LineWidth = 4;
            icons(10).XData = 0.09;
            icons(10).LineWidth = 4;
            icons(11).XData = [0.01, 0.2];
            icons(11).LineWidth = 4;
            icons(12).XData = 0.09;
            icons(12).LineWidth = 4;
            
    end
    
    % output
    figure_file = fullfile(dirFig,sprintf('schematic_errMag_feedback_n1_%s_%s', model_name, var_name));
    print(figure_file,'-depsc');
    
end







