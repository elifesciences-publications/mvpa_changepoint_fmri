This code is associated with the paper from  Kao et al., "Neural encoding of task-dependent errors
during adaptive learning". eLife, 2020. http://doi.org/10.7554/eLife.58809


# mvpa_changepoint_fmri

## behavior_variables
This folder includes subjects' behavior variables from the task, subjects' choice and model prediction.

## scripts/behavior
This folder included scripts for the behavior analyses. The script of "run_behavior_model_fitting" is used to fit different models (e.g., RB_ideal, RB, RL, RB + P(stay), RB + RL). The script "group_behavior_summary" is used to generate the figures for the behavior results (Fig. 2 and Fig. S2). The sript of "schematic_model_var" is used to generated model prediction for CPP, RU and P(switch) (Fig. 3 and Fig., S3).

## scripts/fmri_mvpa
This folder includes scripts for mvpa anlaysis on fmri data. We used linear SVM to run the classification analysis, and we implemented linear SVM using the MATLAB version of the libsvm toolbox (https://www.csie.ntu.edu.tw/~cjlin/libsvm/). The main function for the analysis is "mvpa_classification_voxel_good".
