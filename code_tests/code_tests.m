

% test ANOVA code

clear

addpath ../helper_functions/
addpath ../single_neuron_analyses/binned_data_analyses/

binned_data_name = '../../NDT_tutorial/Binned_Zhang_Desimone_7object_data_150ms_bins_50ms_sampled.mat';

% if just passing a binned file to the function rather than passing actual binned data
binned_data = binned_data_name;
binned_labels_to_use = 'stimulus_ID';

%load(binned_data_name)
%binned_labels_to_use = binned_labels.stimulus_ID;

%[ANOVA_pvalues_all_sites ANOVA_STATS_all_sites] = get_ANOVA_pvalues_from_binned_data(binned_data, binned_labels_to_use);   % this works with strings - look over documentation/comments


% test whether this works with strings...
label_names_to_use = { 'hand',    'face',    'guitar',    'flower'};  
[ANOVA_pvalues_all_sites ANOVA_STATS_all_sites] = get_ANOVA_pvalues_from_binned_data(binned_data, binned_labels_to_use, label_names_to_use);



plot(mean(ANOVA_pvalues_all_sites < .05))



% Update: get_ANOVA_pvalues_from_binned_data

% 1) Make sure it works with strings as labels

% 2) Change it so that you can specify: 
%    a) a string that contains the name of a binned file and a string that 
%    b) a string that contains the labels to use 

% it will then load the binned file and compute the ANOVA values so you don't need to load it yourself
% this is similar to how you can do this in the NDT data source...





%Single neuron Matlab functions to finalize:
%  1) get_ANOVA_pvalues_from_binned_data.m  (and helper function)
%  2) get_average_population_activity_from_binned_data.m 


% compute_one_way_ANOVA.m  (done I think)





























