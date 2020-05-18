function run_behavior_model_fitting(sublist, blocklist, model_name)

% behavior model fitting
%
% Chang-Hao Kao, 05-26-2018

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

% block list
if nargin<2 | isempty(blocklist)
    
    blocklist = {
        'LN';
        'HN';
        };
    
else
    if ~iscell(blocklist)
        blocklist = {blocklist};
    end
end
nBlock = numel(blocklist);

% setting
session_name = 'scan';

% directory
dirVariable = '../../behavior_variables';
dirMLE = '../../model_mle';
mkdir(dirMLE);


% model fitting
for s = 1:nSubj
    
    % subname
    subname = sublist{s};
    
    % load data
    behavior_variable_file = fullfile(dirVariable, sprintf('%s_%s.mat', session_name, subname));
    load(behavior_variable_file);
    
    for b = 1:nBlock
        
        % blockname
        blockname = blocklist{b};
        
        blockData = exp_var.(blockname);
        
        % remove non-choice trials
        idx_valid = ([blockData.idx_choice]'==1);
        blockData = blockData(idx_valid);
        
        % organize data
        data.choice = [blockData.choice]';
        data.errMag = [blockData.errMag]';
        data.errMag_sign = [blockData.errMag_sign]';
        data.idx_goodupdate = [blockData.idx_goodupdate]';
        
        nTrial = sum(data.idx_goodupdate);
        
        %%%%% model fitting %%%%%
        switch model_name
            case {'RB_ideal'} % reduced bayesian
                
                nameParameter = {'H', 'K'};
                
                lb = [-999, -999]; % lower bound
                ub = [-999, -999]; % upper bound
                cutinterval = [1, 1]; % grid
                nParameter = numel(cutinterval);
                
                % multiple start seeds
                x0 = zeros(prod(cutinterval), nParameter);
                idx = 0;
                for i = 1:cutinterval(1)
                    for j = 1:cutinterval(2)
                        idx = idx + 1;
                        x0(idx, :) = [...
                            lb(1)+(i-1)*(ub(1)-lb(1))/cutinterval(1),...
                            lb(2)+(j-1)*(ub(2)-lb(2))/cutinterval(2)...
                            ];
                    end
                end
                
                mleModel = @(x) model_RB(x, data, blockname);
                
            case {'RB'} % reduced bayesian
                
                nameParameter = {'H', 'K'};
                lb = [0.0001, 0.0001]; % lower bound
                ub = [0.9999, 10]; % upper bound
                cutinterval = [5, 5]; % grid
                nParameter = numel(cutinterval);
                
                % multiple start seeds
                x0 = zeros(prod(cutinterval), nParameter);
                idx = 0;
                for i = 1:cutinterval(1)
                    for j = 1:cutinterval(2)
                        idx = idx + 1;
                        x0(idx, :) = [...
                            lb(1)+(i-1)*(ub(1)-lb(1))/cutinterval(1),...
                            lb(2)+(j-1)*(ub(2)-lb(2))/cutinterval(2)...
                            ];
                    end
                end
                
                mleModel = @(x) model_RB(x, data);
                
            case {'RB_stay'} % reduced bayesian
                
                nameParameter = {'H', 'K', 'prob_stay'};
                lb = [0.0001, 0.0001, 0.0001]; % lower bound
                ub = [0.9999,     10, 0.9999]; % upper bound
                cutinterval = [5, 5, 5]; % grid
                nParameter = numel(cutinterval);
                
                % multiple start seeds
                x0 = zeros(prod(cutinterval), nParameter);
                idx = 0;
                for i = 1:cutinterval(1)
                    for j = 1:cutinterval(2)
                        for k = 1:cutinterval(3)
                            idx = idx + 1;
                            x0(idx, :) = [...
                                lb(1)+(i-1)*(ub(1)-lb(1))/cutinterval(1),...
                                lb(2)+(j-1)*(ub(2)-lb(2))/cutinterval(2),...
                                lb(3)+(k-1)*(ub(3)-lb(3))/cutinterval(3)...
                                ];
                        end
                    end
                end
                
                mleModel = @(x) model_RB(x, data);
                
                
            case {'RL'} % reinforcement learning
                
                nameParameter = {'fixed_alpha'};
                lb = [0.0001]; % lower bound
                ub = [0.9999]; % upper bound
                cutinterval = [5]; % grid
                nParameter = numel(cutinterval);
                
                % multiple start seeds
                x0 = zeros(prod(cutinterval), nParameter);
                idx = 0;
                for i = 1:cutinterval(1)
                    idx = idx + 1;
                    x0(idx, :) = [...
                        lb(1)+(i-1)*(ub(1)-lb(1))/cutinterval(1),...
                        ];
                end
                
                mleModel = @(x) model_RL(x, data);
                
                
            case {'RB_RL_weighting'} % reinforcement learning
                
                nameParameter = {'H', 'K', 'fixed_alpha', 'w'};
                lb = [0.0001, 0.0001, 0.0001, 0.0001]; % lower bound
                ub = [0.9999,     10, 0.9999, 0.9999]; % upper bound
                cutinterval = [5, 5, 5, 5]; % grid
                nParameter = numel(cutinterval);
                
                % multiple start seeds
                x0 = zeros(prod(cutinterval), nParameter);
                idx = 0;
                for i = 1:cutinterval(1)
                    for j = 1:cutinterval(2)
                        for k = 1:cutinterval(3)
                            for m = 1:cutinterval(4)
                                idx = idx + 1;
                                x0(idx, :) = [...
                                    lb(1)+(i-1)*(ub(1)-lb(1))/cutinterval(1),...
                                    lb(2)+(j-1)*(ub(2)-lb(2))/cutinterval(2)...
                                    lb(3)+(k-1)*(ub(3)-lb(3))/cutinterval(3)...
                                    lb(4)+(m-1)*(ub(4)-lb(4))/cutinterval(4)...
                                    ];
                            end
                        end
                    end
                end
                
                mleModel = @(x) model_RB_RL_weighting(x, data);
                
        end
        
        % fitting
        mse_all = zeros(idx, 1);
        x_all = zeros(idx, nParameter);
        options = optimoptions('fmincon','Algorithm','interior-point');
        tic
        for i = 1:idx
            %             [x, mse] = fmincon(@(x) mleModel(x), x0(i,:), [], [], [], [], lb, ub);
            [x, mse] = fmincon(@(x) mleModel(x), x0(i,:), [], [], [], [], lb, ub, [], options);
            mse_all(i,1) = mse;
            x_all(i,:) = x;
            fprintf('%d\t', i);
            fprintf('%d\t', mse);
            fprintf('%.5f\t', x);
            fprintf('\n');
        end
        toc
        
        [mse_bestfit, idx_bestfit] = min(mse_all);
        x_bestfit = x_all(idx_bestfit, :);
        
        fittingFile = fullfile(dirMLE, sprintf('mle_%s_%s_%s', model_name, blockname, subname));
        save(fittingFile,'nameParameter','x_bestfit', 'mse_bestfit', 'nTrial');
        
        
    end % end of block
end % end of subject








