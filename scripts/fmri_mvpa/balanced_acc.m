function [acc,list_acc] = balanced_acc(y,yhat)

list_label = unique(y);
nLabel = numel(list_label);
list_acc = zeros(nLabel,1);
for i = 1:nLabel
    target_label = list_label(i);
    list_acc(i,1) = sum(y==target_label&yhat==target_label)/sum(y==target_label);
end
acc = mean(list_acc);
