function [acc, info] = classifier_svm(set_train, set_test, classification_method, isUnbalanced, n_fold)

if nargin<4
    isUnbalanced = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% pick parameters %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
setting.n_fold = n_fold;

% initial parameter list
switch classification_method
    case {'svm_linear'}
        setting.list_log2c = log2([0.001, 0.01, 0.1, 1, 10, 100, 1000]);
end
setting.method = classification_method;

level_label = unique(set_train.label);
nLabel = numel(level_label);
number = zeros(nLabel,1);
for i = 1:nLabel
    idx_label = (set_train.label==level_label(i));
    number(i,1) = sum(idx_label);
end
ratio = (number./sum(number))*100;

setting.label = level_label;
if isUnbalanced==0
    setting.weight = ones(nLabel,1);
elseif isUnbalanced==1
    setting.weight = 1./ratio;
end

[best_cv, best_param] = pick_parameter(set_train, setting, isUnbalanced);


%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% train & test %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% model training
x = set_train.data;
y = set_train.label;
switch classification_method
    case {'svm_linear'}
        if isUnbalanced==0
            cmd = sprintf('-s 0 -t 0 -c %.10f -q', 2^best_param.log2c);
        elseif isUnbalanced==1
            cmd = sprintf('-s 0 -t 0 -c %.10f -q', 2^best_param.log2c);
            for w = 1:numel(setting.label)
                cmd = sprintf('%s -w%d %.3f', cmd, setting.label(w), setting.weight(w));
            end
        end
end
model = svmtrain(y, x, cmd);

% model testing
x = set_test.data;
y = set_test.label;
[yhat] = svmpredict(y, x, model);
[acc, acc_each] = balanced_acc(y,yhat);

% info
info.best_param = best_param;
info.acc_each = acc_each;




function [best_cv, best_param] = pick_parameter(set_train, setting, isUnbalanced)

label = set_train.label;
n_fold = setting.n_fold;
fold_list = create_fold_list(label, n_fold);

switch setting.method
    case {'svm_linear'}
        
        nC = numel(setting.list_log2c);
        
        % pick parameters by cross-validation
        best_cv = 0;
        for i = 1:nC
            
            log2c = setting.list_log2c(i);
            
            cv_fold = zeros(n_fold,1);
            for f = 1:n_fold
                
                idx_train = (fold_list~=f);
                idx_test = (fold_list==f);
                
                % train
                x_train = set_train.data(idx_train,:);
                y_train = set_train.label(idx_train);
                x_test = set_train.data(idx_test,:);
                y_test = set_train.label(idx_test);
                
                if isUnbalanced==0
                    cmd = sprintf('-s 0 -t 0 -c %.10f -q', 2^log2c);
                elseif isUnbalanced==1
                    cmd = sprintf('-s 0 -t 0 -c %.10f -q', 2^log2c);
                    for w = 1:numel(setting.label)
                        cmd = sprintf('%s -w%d %.3f', cmd, setting.label(w), setting.weight(w));
                    end
                end
                model = svmtrain(y_train, x_train, cmd);
                [yhat] = svmpredict(y_test, x_test, model);
                
                acc = balanced_acc(y_test,yhat);
                cv_fold(f,1) = acc;
                
            end
            
            cv = mean(cv_fold);
            if (cv >= best_cv)
                best_cv = cv;
                best_param.log2c = log2c;
            end
            
        end
        
end


