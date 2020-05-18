function fold_list = create_fold_list(label, n_fold)
nTrial = numel(label);
list_label = unique(label);
nLabel = numel(list_label);
fold_list = NaN(nTrial,1);

for i = 1:nLabel
    idx_label = (label==list_label(i));
    n_sub = sum(idx_label);
    fold_list(idx_label) = sort(mod([1:n_sub]', n_fold)+1);
end