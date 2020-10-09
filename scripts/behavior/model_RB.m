function [mse, model_var] = model_RB(param, data, blockname)

if nargin<3
    blockname = 'none';
end

% parameters
hazardRate = param(1);
k = param(2);
try
    prob_stay = param(3);
catch
    prob_stay = 0;
end

% data
choice = data.choice;
errMag_all = data.errMag;
errMag_sign_all = data.errMag_sign;

idx_goodupdate = data.idx_goodupdate;
idx_goodchoice = logical([0;idx_goodupdate(1:end-1)]);

switch blockname
    case {'LN'}
        if hazardRate<0
            hazardRate = 0.35;
        end
        if k<0
            likelihood_prob = [0, 0, 0, 0, 1, 0, 0, 0, 0, 0];
        else
            likelihood_prob = exp(k*cos(linspace(-pi, pi, 11)));
            likelihood_prob = likelihood_prob(2:end);
            likelihood_prob = likelihood_prob./sum(likelihood_prob);
        end
    case {'HN'}
        if hazardRate<0
            hazardRate = 0.02;
        end
        if k<0
            likelihood_prob = [0, 0, 0.05, 0.15, 0.6, 0.15, 0.05, 0, 0, 0];
        else
            likelihood_prob = exp(k*cos(linspace(-pi, pi, 11)));
            likelihood_prob = likelihood_prob(2:end);
            likelihood_prob = likelihood_prob./sum(likelihood_prob);
        end
    otherwise
        likelihood_prob = exp(k*cos(linspace(-pi, pi, 11)));
        likelihood_prob = likelihood_prob(2:end);
        likelihood_prob = likelihood_prob./sum(likelihood_prob);
end

errMag_vector = [-4, -3, -2, -1, 0, 1, 2, 3, 4, 5];
likelihood_var = sum(likelihood_prob.*errMag_vector.^2);


nTrial = numel(choice);
model_choice = NaN(nTrial,1);
model_choice(1) = choice(1);

model_update = NaN(nTrial,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% reduced bayesian model %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cpp_all = NaN(nTrial,1);
ru_all = NaN(nTrial,1);
sd_all = NaN(nTrial,1);

ru = 0.5;
ru_all(1) = ru;

cpp = 1;
cpp_all(1) = cpp;
exp_run = 1;
postDist = likelihood_prob;
for t = 1:nTrial
    
    errMag = errMag_all(t);
    errMag_sign = errMag_sign_all(t);
    
    exp_run = (1-cpp)*exp_run + 1;
    if t~=1
        
        idx = find(errMag_vector==errMag_sign);
        if isempty(idx)
            
            predProb = 0;
            
        else
            
            postDist = likelihood_prob.^exp_run;
            postDist = postDist./sum(postDist);
            
            predDist = conv(postDist,likelihood_prob);
            predDist(end-8:end-5) = predDist(end-8:end-5) + predDist(1:4);
            predDist(5:9) = predDist(5:9) + predDist(end-4:end);
            predDist = predDist(5:14);
            predDist = predDist./sum(predDist);
            predProb = predDist(idx);
            
        end
        
        cpp = (hazardRate*1/10)./((hazardRate*1/10) + (1-hazardRate)*predProb);
        
    else
        
        idx_dist = double(errMag_vector==errMag_sign);
        predDist = conv(idx_dist,likelihood_prob);
        predDist(end-8:end-5) = predDist(end-8:end-5) + predDist(1:4);
        predDist(5:9) = predDist(5:9) + predDist(end-4:end);
        predDist = predDist(5:14);
        predDist = predDist./sum(predDist);
        cpp = 1;
        
    end
    
    postVar = sum(postDist.*errMag_vector.^2);
    ru = (cpp*likelihood_var+(1-cpp)*postVar+cpp*(1-cpp)*(errMag*(1-ru))^2)/...
        ((cpp*likelihood_var+(1-cpp)*postVar+cpp*(1-cpp)*(errMag*(1-ru))^2) + likelihood_var);
    
    if isnan(ru)
        ru = 0;
    end
    cpp_all(t) = cpp;
    ru_all(t+1) = ru;
    sd_all(t) = sqrt(postVar);
    
    alpha = cpp_all(t) + (1-cpp_all(t)).*ru_all(t);
    
    current_update = alpha.*errMag_sign;
    current_update = prob_stay*0 + (1-prob_stay)*current_update;
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
ru_all(end) = [];
ru_all(isnan(ru_all)) = 0;

% MSE
choice_diff = abs(choice(idx_goodchoice)-model_choice(idx_goodchoice));
choice_diff = min(choice_diff, 10-choice_diff);
mse = mean(choice_diff.^2);

% model_var
model_var.cpp_all = cpp_all;
model_var.ru_all = ru_all;
model_var.sd_all = sd_all;
model_var.update_all = round(abs(model_update));
model_var.model_choice = round(model_choice);







