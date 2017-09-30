function [stimulus_time_average_activity_matrix, site_time_stimulus_activity_matrix] = get_average_population_activity_from_binned_data(binned_data_name, specific_binned_label_name, normalization_type, stimulus_names_to_use, get_results_for_each_stimulus_separately, sites_to_use)


% could add a return argument site_time_stimulus_stdev_matrix that returns the stdevs as well...

% This function takes the name of a binned data file and computes the population average activity over all sites (for each time bin).
%
%
%  The input arguments to this function are:
%
%   1. binned_data_name: the name of a data file in binned-format
%
%
%  Optional input arguments to this function are:
%
%   2. specific_binned_label_name (default = []): If this is empty, then data from all trials will be used, and results can not be calculated seprately for each stimulus.
%       If this is set to a string specifying the name of the stimulus labels, then if get_results_for_each_stimulus_separately = 1, the activity will be calculated
%       separately for each stimulus - and if get_results_for_each_stimulus_separately = 0 and stimulus_names_to_use is set, then only trials specified in 
%       stimulus_names_to_use will be used.
%
%   3.  normalization_type (default = 0): The normalization that is applied to each neuron before all the neurons are averaged together.  If this is set to 0 then 
%         no normalization is applied.  If this value is set to 1 then each neuron's activity is z-score normalized so that it has a mean of 0 and a standard deviation
%         of 1, where the mean and standard deviation use the data from over all stimuli and time points.  If this value is to 2 then each neuron's activity 
%         is 0-1 normalized so that it has a maximum of 1 to the stimulus with the highest firing rate at the optimal time and a value of zero to the stimulus with the 
%         loweset firing rate at the lowest time point.   
%
%   4.  stimulus_names_to_use (default = []):  If this is set to a cell array, then only stimulus names in this cell array will be used. If this is not set, then all
%         stimuli that the first site has will be used - specific_binned_label_name must be set to use this option.  
%
%   5.  get_results_for_each_stimulus_separately (default = 1).  If this is set to 1, then the results will be calculated separately for each stimulus.  Overwise,
%          the results will be averaged over all stimuli (note that stimuli that have more repeated trials will contribute more to this average).  
%
%   6.  sites_to_use (default use all the sites). If this is set to a vector of sites to use, the only those sites will be used when calculating the average firing rate. 
%
%
%  The results returned by this function are:
%
%   1.  stimulus_time_average_activity_matrix: The is a matrix that has the average population activity. If get_results_for_each_stimulus_separately was set to 1,
%           then this is a [num_stim x num_times] matrix, otherwise it is a [1 x num_times] matrix.
%
%   2.  site_time_stimulus_activity_matrix: This is a matrix that has the average firing rates calculated separately for each site.  If normalization is used, 
%           then the activity for each site have been normalized according to the normalization method specified.
%
%
%  Note:
%
%   If one calculates the activity activity separately for each stimulus and then later averages over all stimuli
%    (i.e., [stimulus_time_average_activity_matrix] = get_average_population_activity_from_binned_data(binned_data_name, specific_binned_label_name, 0, [], 0),
%    ave_over_stimuli_1 = mean(stimulus_time_average_activity_matrix, 1);), this average will be slightly different from collapsing across all stimuli first
%    (i.e., ave_over_stimuli_2 = get_average_population_activity_from_binned_data(binned_data_name, specific_binned_label_name, 0, [], 1)).
%    The reason is if one collapses across all stimuli first, then stimuli with more trials will be weighted more when calculated the population average.   
%


if nargin < 2
    specific_binned_label_name = [];
end

if nargin < 3
    normalization_type = 0;
end

if nargin < 4
    stimulus_names_to_use = [];
end

if nargin < 5 
    get_results_for_each_stimulus_separately = 1;
end


[binned_data, binned_labels_to_use] = retrieve_binned_format_data(binned_data_name, specific_binned_label_name);


if nargin < 6
    sites_to_use = 1:numel(binned_data);
end


% if specific_binned_label_name is empty or an empty string, use data from all trials
if isempty(specific_binned_label_name) || sum(strcmp(specific_binned_label_name, ''))
    
    get_results_for_each_stimulus_separately = 0;        
    stimulus_names_to_use = [];
    if ~isempty(stimulus_names_to_use)
        error('if specific_binned_label_name is empty or set to an empty string, then stimulus_names_to_use can not be set')
    end
    
    
else
    
    % If the labels are a cell array of strings, convert them to numbers
    if iscell(binned_labels_to_use{1})

        [binned_labels_to_use, string_to_number_mapping] = convert_label_strings_into_numbers(binned_labels_to_use);

        % only used specified strings
        if ~isempty(stimulus_names_to_use)
            stimulus_names_to_use = find(ismember(string_to_number_mapping, stimulus_names_to_use));
        end

    end
    
end




% This is used if one wants to average over all trials from all stimuli specified rather than calculating the average activity for each stimulus separately
if  get_results_for_each_stimulus_separately == 0
     
    for iSite = 1:length(sites_to_use)
        if isempty(stimulus_names_to_use)
            site_time_stimulus_activity_matrix(iSite, :) = mean(binned_data{sites_to_use(iSite)});   
        else
            trial_inds_to_use = find(ismember(binned_labels_to_use{sites_to_use(iSite)}, stimulus_names_to_use));            
            site_time_stimulus_activity_matrix(iSite, :) = mean(binned_data{sites_to_use(iSite)}(trial_inds_to_use, :)); 
        end
                
    end
    
    
    
% This is used so that the average activity is calculated separately for each stimulus. One can later average over all stimuli
%  however this average will cause each stimulus to have equal weight regardless of how many repeated trials there are for each stimulus.
else


    if isempty(stimulus_names_to_use)
        stimulus_names_to_use = unique(binned_labels_to_use{1});
    end

    for iSite = 1:length(sites_to_use)   
        
        for iStim = 1:numel(stimulus_names_to_use)
            curr_inds = find(binned_labels_to_use{sites_to_use(iSite)} == stimulus_names_to_use(iStim));           
            site_time_stimulus_activity_matrix(iSite, :, iStim) = mean(binned_data{sites_to_use(iSite)}(curr_inds, :));
            %site_time_stimulus_stdev_matrix(iSite, :, iStim) = std(binned_data{iSite}(curr_inds, :));
        end
            
    end
    
  
end
    


    
% apply normalization to all sites


% don't do any normalization
if normalization_type == 0

    
% z-score normalize the data   
elseif normalization_type == 1

    
    for iSite = 1:size(site_time_stimulus_activity_matrix, 1)    
        site_time_stimulus_activity_matrix(iSite, :, :) = site_time_stimulus_activity_matrix(iSite, :, :) - mean(mean(site_time_stimulus_activity_matrix(iSite, :, :)));
        curr_data = site_time_stimulus_activity_matrix(iSite, :, :);
        site_time_stimulus_activity_matrix(iSite, :, :) = site_time_stimulus_activity_matrix(iSite, :, :)./std(curr_data(:));        
    end
    
% 0-1 normalize the data    
elseif normalization_type == 2 
    
    for iSite = 1:size(site_time_stimulus_activity_matrix, 1)    
        site_time_stimulus_activity_matrix(iSite, :, :) = site_time_stimulus_activity_matrix(iSite, :, :) - min(min(site_time_stimulus_activity_matrix(iSite, :, :)));
        site_time_stimulus_activity_matrix(iSite, :, :) = site_time_stimulus_activity_matrix(iSite, :, :)./max(max(site_time_stimulus_activity_matrix(iSite, :, :)));     
    end
    
else 
    error('normalization type must be set to 0, 1 or 2')
end



% average the results over all sites
stimulus_time_average_activity_matrix = squeeze(nanmean(site_time_stimulus_activity_matrix, 1));

if size(stimulus_time_average_activity_matrix, 2) ~= 1
    stimulus_time_average_activity_matrix = stimulus_time_average_activity_matrix';
end


































