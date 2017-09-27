function [signal_correlation_matrix ave_signal_correlation stdev_signal_correlation] = create_signal_correlation_matrix_from_binned_data(binned_data_file_name, binned_labels_to_use, label_names_to_use)

% This funciton computes a [num_sites x num_sites x num_time_bins] matrix that indicates the signal correlation between all sites for all time periods.
%
% The input arguments to this function are:
%
%   1.  binned_data_file_name: the name of a file in binned format (or a binned_data cell array)
%   2.  binned_labels_to_use:  a string containing the name of the specific binned_labels to use (or the cell array/vector of specific binned labels is binned_data is a cell array)
%   3.  label_names_to_use: an optional argument that list which label names (of the specific label names) should be used.  If this argument
%          is not given, all the unqiue labels that are present in the first site will be used.
%
%  Function outputs:
%
%   1. signal_correlation_matrix: A [num_sites x num_sites x num_time_bins] matrix that has the signal correlation between all sites for all time periods
%   2. ave_signal_correlation:  A num_time_bins length vector that has the average signal correlation calculated over all (pairs of) sites as a function of time
%   3. stdev_signal_correlation:  A num_time_bins length vector that has the standard deviation of the signal correlation calculated over all (pairs of) sites as a function of time.
%       Note that the dividing this stdev_signal_correlation by the square root of the number of site is NOT a valid way to estimate the standard error of the ave_signal_correlation
%       since the signal correlation between pairs of sites are obviously not independent from one another when all pairs of sites are used

% could add an option to use only specific sites (e.g., only sites that are significantly modulated by the stimuli)



% load the binned data 
if isstr(binned_data_file_name)
    load(binned_data_file_name);
    specific_binned_labels = eval(['binned_labels.' binned_labels_to_use]);
elseif iscell(binned_data_file_name)
    binned_data = binned_data_file_name;
    specific_binned_labels = binned_labels_to_use;
end



% if label_names_to_use is not given as an argument, use all the labels that the first site has 
if nargin < 3
    label_names_to_use = unique(specific_binned_labels{1});  
end



% calculate the average firing rate to each stimulus for each site (for all time bins)
for iSite = 1:numel(binned_data)
    
    curr_labels = specific_binned_labels{iSite};
    
    % calculate the mean firing rate for each site and each stimulus
    for iStim = 1:numel(label_names_to_use)
         if iscell(label_names_to_use)
            curr_stim_inds = find(ismember(curr_labels, label_names_to_use{iStim}));
         else
            curr_stim_inds = find(ismember(curr_labels, label_names_to_use(iStim)));
         end
         
         curr_mean = nanmean(binned_data{iSite}(curr_stim_inds, :), 1);   
         curr_mean(isnan(curr_mean)) = 0;
         mean_firing_rates(iSite, iStim, :) = curr_mean;
    end
       
end



% Calculate the signal correlation for each time bin
valid_pair_inds = find(triu(ones(size(mean_firing_rates, 1), size(mean_firing_rates, 1)), 1));  % inds of all pairs of signal correlations (only upper triangular part of matrix)
for iTime = 1:size(mean_firing_rates, 3)
    
    all_correlation_coefficients = corrcoef([mean_firing_rates(:, :, iTime)', mean_firing_rates(:, :, iTime)']);  % use the corrcoef function to get the correlation coefficients
    curr_signal_correlation_matrix = all_correlation_coefficients(1:size(mean_firing_rates, 1), 1:size(mean_firing_rates, 1));  % temp store this value to compute the average/stdev of upper triangular part of it

    signal_correlation_matrix(:, :, iTime) = curr_signal_correlation_matrix;

    ave_signal_correlation(iTime) = nanmean(curr_signal_correlation_matrix(valid_pair_inds));
    stdev_signal_correlation(iTime) = nanstd(curr_signal_correlation_matrix(valid_pair_inds));

end













