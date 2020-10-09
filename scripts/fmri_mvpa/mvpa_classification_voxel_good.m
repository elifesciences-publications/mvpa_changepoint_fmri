function mvpa_classification_voxel_good(subname, label_type, mask, roi_diameter, classification_method, blockname, idx_z)

addpath(genpath('../../matlab_toolbox'));

% label type
if nargin<2
    label_type = 'feedback';
end

% mask
if nargin<3
    mask = 'searchlight';
end

% roi_diameter
if nargin<4
    roi_diameter = 5;
end

% classification method
if nargin<5
    classification_method = 'svm_linear'; % svm_linear, svm_rbf
end


% directory
dirResult = sprintf('%s_good', classification_method);
mkdir(dirResult);
dirBeta = '../model_trial_lss_matlab/beta_voxel';
dirVar = '../behavior_variables';

% setting of classification
switch label_type
    case {'feedback_t', 'feedback_t-1',...
            'small_error_switch',...
            'errMag_max3_t',...
            'correct_t_feedback_t-1', 'error_t_feedback_t-1',...
            'certain_t_feedback_t-1', 'uncertain_t_feedback_t-1'}
        n_fold = 3;
end

% method of ROI
setting.shape = 'sphere';
setting.diameter = roi_diameter; % 5 voxles (2mm X 2mm X 2mm)
ROI_template = create_template(setting);


% mask
mask_file = 'subject_mask.mat';
load(mask_file);
maxDim = size(subject_mask);

% behavior variables
filename_var = fullfile(dirVar, sprintf('scan_%s.mat', subname));
load(filename_var);
exp_var.block1 = exp_var.HN;
exp_var.block2 = exp_var.LN;
exp_var = rmfield(exp_var, {'HN', 'LN'});


% organize data
blockData = exp_var.(blockname);
nTrial_block = numel(blockData);

triallist = [1:nTrial_block]';

% remove non-choice trials
idx_choice = ([blockData.idx_choice]'==1);

blockData = blockData(idx_choice);
triallist = triallist(idx_choice);

% organize data
errMag = [blockData.errMag]';
errMag_max3 = errMag;
errMag_max3(errMag_max3>3) = 3;
errMag_max3_n1 = [NaN; errMag_max3(1:end-1)];

feedback = double(errMag_max3==0);
feedback_n1 = [NaN; feedback(1:end-1)];

update = [blockData.update]';
isSwitchNext = double(update>=0.5);

% keep trials with good update
idx_goodupdate = ([blockData.idx_goodupdate]'==1);

errMag_max3 = errMag_max3(idx_goodupdate);
errMag_max3_n1 = errMag_max3_n1(idx_goodupdate);
feedback = feedback(idx_goodupdate);
feedback_n1 = feedback_n1(idx_goodupdate);
isSwitchNext = isSwitchNext(idx_goodupdate);

triallist = triallist(idx_goodupdate);


clear exp_var;

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% classification %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
isUnbalanced = 1;
switch label_type
    case {'feedback_t'}
        label = feedback;
        
        idx_valid = ~isnan(label);
        label = label(idx_valid);
        triallist = triallist(idx_valid);
        
        if numel(unique(label))~=2
            fprintf('not enough labels');
            return
        end
        
    case {'feedback_t-1'}
        label = feedback_n1;
        
        idx_valid = ~isnan(label);
        label = label(idx_valid);
        triallist = triallist(idx_valid);
        
        if numel(unique(label))~=2
            fprintf('not enough labels');
            return
        end
        
    case {'error_t_feedback_t-1'}
        label = feedback_n1;
        
        idx_select = (feedback==0);
        label = label(idx_select);
        triallist = triallist(idx_select);
        
        idx_valid = ~isnan(label);
        label = label(idx_valid);
        triallist = triallist(idx_valid);
        
        if numel(unique(label))~=2
            fprintf('not enough labels');
            return
        end
        
    case {'correct_t_feedback_t-1'}
        label = feedback_n1;
        
        idx_select = (feedback==1);
        label = label(idx_select);
        triallist = triallist(idx_select);
        
        idx_valid = ~isnan(label);
        label = label(idx_valid);
        triallist = triallist(idx_valid);
        
        if numel(unique(label))~=2
            fprintf('not enough labels');
            return
        end
        
    case {'certain_t_feedback_t-1'}
        label = feedback_n1;
        
        idx_select = (errMag_max3==0 | errMag_max3==3);
        label = label(idx_select);
        triallist = triallist(idx_select);
        
        idx_valid = ~isnan(label);
        label = label(idx_valid);
        triallist = triallist(idx_valid);
        
        if numel(unique(label))~=2
            fprintf('not enough labels');
            return
        end
        
    case {'uncertain_t_feedback_t-1'}
        label = feedback_n1;
        
        idx_select = (errMag_max3==1 | errMag_max3==2);
        label = label(idx_select);
        triallist = triallist(idx_select);
        
        idx_valid = ~isnan(label);
        label = label(idx_valid);
        triallist = triallist(idx_valid);
        
        if numel(unique(label))~=2
            fprintf('not enough labels');
            return
        end
        
    case {'errMag_max3_t'}
        label = errMag_max3;
        
        idx_valid = ~isnan(label);
        label = label(idx_valid);
        triallist = triallist(idx_valid);
        
        if numel(unique(label))~=4
            fprintf('not enough labels');
            return
        end
        
    case {'small_error_switch'}
        label = isSwitchNext;
        
        idx_select = (errMag_max3==1 | errMag_max3==2);
        label = label(idx_select);
        triallist = triallist(idx_select);
        
        idx_valid = ~isnan(label);
        label = label(idx_valid);
        triallist = triallist(idx_valid);
        
        if numel(unique(label))~=2
            fprintf('not enough labels');
            return
        end
        
end

% check number of trials for labels
level_label = unique(label);
nLabel = numel(level_label);
number = zeros(nLabel,1);
for i = 1:nLabel
    idx_select = (label==level_label(i));
    number(i,1) = sum(idx_select);
end
if any(number<n_fold*2)
    fprintf('not enough labels');
    return
end

% fold list
fold_list = create_fold_list(label, n_fold);

% organize data
label_all = label;
fold_list_all = fold_list;

% start to do classification
tic

k = idx_z;
idx_progress = 0;
matrix_acc = nan(maxDim(1),maxDim(2));
for i = 1:maxDim(1)
    for j = 1:maxDim(2)
        
        % progress
        idx_progress = idx_progress + 1;
        
        % ROI
        switch mask
            case {'searchlight'}
                ROI_peak = [i;j;k];
            otherwise
                ROI_peak = subject_peak;
        end
        
        % check if ROI coordinate within the size of the brain
        nCoordinate = size(ROI_template,2);
        ROI_coordinate = ROI_template + repmat(ROI_peak, 1, nCoordinate);
        idx_include = logical(ones(1,nCoordinate));
        for d = 1:3
            idx_include = idx_include & ROI_coordinate(d,:)>=1 & ROI_coordinate(d,:)<=maxDim(d);
        end
        ROI_coordinate = ROI_coordinate(:,idx_include);
        
        % check if there are data in the ROI
        nCoordinate = size(ROI_coordinate,2);
        idx_include = logical(ones(1,nCoordinate));
        for c = 1:nCoordinate
            
            x = ROI_coordinate(1,c);
            y = ROI_coordinate(2,c);
            z = ROI_coordinate(3,c);
            if subject_mask(x,y,z)==0
                idx_include(c) = logical(0);
            end
            
        end
        ROI_coordinate = ROI_coordinate(:, idx_include);
        
        % check if there are valid ROI_coordinate
        if isempty(ROI_coordinate)
            continue
        end
        
        % load data
        nCoordinate = size(ROI_coordinate,2);
        ROI_data = NaN(nTrial_block, nCoordinate);
        for c = 1:nCoordinate
            
            x = ROI_coordinate(1,c);
            y = ROI_coordinate(2,c);
            z = ROI_coordinate(3,c);
            
            voxel_file = fullfile(dirBeta, subname, blockname, sprintf('%s_%s_trial_beta_x%d_y%d_z%d.mat', subname, blockname, x, y, z));
            load(voxel_file); % voxel_beta
            
            ROI_data(:,c) = voxel_beta;
            
        end
        
        % select valid trials
        ROI_data = ROI_data(triallist, :);
        
        % remove trials with NaN
        idx_notnan = ~isnan(sum(ROI_data,2));
        ROI_data = ROI_data(idx_notnan,:);
        label = label_all(idx_notnan);
        fold_list = fold_list_all(idx_notnan);
        
        % normalize data into [-1, 1]
        switch classification_method
            case {'svm_linear', 'svm_rbf', 'svr_linear'}
                ROI_data = val_scaling(ROI_data);
        end
        
        % progress report
        fprintf('progress: %d/%d\n', idx_progress, maxDim(1)*maxDim(2));
        
        % do classification
        clear info_all
        acc_all = zeros(n_fold,1);
        for f = 1:n_fold
            
            % split data
            idx_test = (fold_list==f);
            idx_train = (fold_list~=f);
            
            set_train.data = ROI_data(idx_train,:);
            set_train.label = label(idx_train);
            set_test.data = ROI_data(idx_test,:);
            set_test.label = label(idx_test);
            
            % classification
            switch classification_method
                case {'svm_linear', 'svm_rbf'}
                    [acc, info] = classifier_svm(set_train, set_test, classification_method, isUnbalanced, n_fold);
                case {'svr_linear'}
                    [acc, info] = regression_svr(set_train, set_test, classification_method, n_fold);
            end
            acc_all(f,1) = acc;
            
        end % end of fold
        acc = mean(acc_all);
        matrix_acc(i,j) = acc;
        
    end
end
% save data
dirTemp = fullfile(dirResult,'voxel',label_type,blockname,subname);
mkdir(dirTemp);
filename = fullfile(dirTemp, sprintf('%dvoxel_z%d.mat', roi_diameter, k));
save(filename, 'matrix_acc');

toc






function ROI_template = create_template(setting)

nNeighbor = (setting.diameter-1)/2;
vector = [-nNeighbor:nNeighbor];
n = numel(vector);
cube_voxels = [sort(repmat(vector, 1, n^2)); repmat(sort(repmat(vector, 1, n)), 1, n); repmat(vector, 1, n^2)];

switch lower(setting.shape)
    case 'sphere'
        distance = (sum(cube_voxels.^2, 1)).^(1/2);
        idx = (distance<=nNeighbor);
        x = cube_voxels(:, idx);
    case 'cube'
        x = cube_voxels;
end
ROI_template = x;



function val = val_scaling(val)

nCol = size(val,2);
for i = 1:nCol
    
    data = val(:,i);
    val_max = max(data);
    val_min = min(data);
    
    data = (data-(val_max+val_min)/2)/((val_max-val_min)/2);
    val(:,i) = data;
    
end





