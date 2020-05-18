function [mse, model_var] = model_RL(param, data)

% parameters
fixed_alpha = param(1);

% data
choice = data.choice;
errMag_all = data.errMag;
errMag_sign_all = data.errMag_sign;

idx_goodupdate = data.idx_goodupdate;
idx_goodchoice = logical([0;idx_goodupdate(1:end-1)]);



nTrial = numel(choice);
model_choice = NaN(nTrial,1);
model_choice(1) = choice(1);

model_update = NaN(nTrial,1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% RL model %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for t = 1:nTrial
    
    errMag = errMag_all(t);
    errMag_sign = errMag_sign_all(t);
    
    alpha = fixed_alpha;
    
    current_update = alpha.*errMag_sign;
    model_choice(t+1) = choice(t) + current_update;
    
    model_update(t) = current_update;
    
    model_choice(t+1) = mod(model_choice(t+1)+10-1,10)+1;
    
    if model_choice(t+1)>=10.5
        model_choice(t+1) = model_choice(t+1) - 10;
    elseif model_choice(t+1)<0.5
        model_choice(t+1) = model_choice(t+1) + 10;
    end
    
end
model_choice(end) = [];

% MSE
% choice_diff = abs(choice-model_choice);
choice_diff = abs(choice(idx_goodchoice)-model_choice(idx_goodchoice));
choice_diff = min(choice_diff, 10-choice_diff);
mse = mean(choice_diff.^2);

% model_var
model_var.cpp_all = NaN(nTrial,1);
model_var.ru_all = NaN(nTrial,1);
model_var.sd_all = NaN(nTrial,1);
model_var.update_all = round(abs(model_update));
model_var.model_choice = round(model_choice);



