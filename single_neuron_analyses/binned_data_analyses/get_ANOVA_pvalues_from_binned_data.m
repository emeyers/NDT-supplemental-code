function [ANOVA_pvalues_all_sites, ANOVA_STATS_all_sites] = get_ANOVA_pvalues_from_binned_data(binned_data_name, specific_binned_label_name, label_names_to_use, sites_to_use)

% This function calculates the p-values as to whether each site at each time point is selective
%   to the labels based on using a one-way analysis of variance (ANOVA).  Essentially this is the 
%   same as using anova1 on each site at each time point except that this function uses the helper
%   function compute_oneway_ANOVA to make the computations much faster.  The function also returns
%   all the same statistics that anova1 return in the cell array ANOVA_STATS_all_sites.  The input 
%   arguments to this function are:
%
%   1.  binned_data_name: is string that has the name of a file that has data in binned-format, 
%            or is a cell array of binned-format binned_data 
%
%   2.  specific_binned_label_name: is a string containing a specific binned-format label name, or  
%           is a cell array/vector containing the specific binned names (i.e., binned_labels.specific_binned_label_name)
%     
%     
%  Optional input arguments:
%
%   3.  label_names_to_use:  which labels numbers should be used (of the names/numbers listed in binned_labels_to_use). 
%           If this field is empty (or if this argument is not given) then all the labels available will be used.
%      
%   4.  sites_to_use: which sites to include in the analysis. If not set all sites will be used
%
%
%  The results returned by this function are:
%
%   1.  ANOVA_pvalues_all_sites:  a matrix that is [num_sites x num_times] large that has the p-values for each site 
%               at each point in time as computed via a oneway ANOVA.  
%
%   2. ANOVA_STATS_all_sites: a num_sites sized cell array containing additional information about each site 
%           that can be used to create a ANOVA tables and post hoc comparisons. 
%
%
%
%  Example: Plot the percentage of neurons at each time point that have a p-value of less than 0.05 (using only 4 particular labels)
%   
%   % specify the binned data and which labels should be used
%   binned_data_name = 'Binned_Zhang_Desimone_7object_data_150ms_bins_10ms_sampled.mat';
%   specific_binned_label_name = 'stimulus_ID';
%
%   % only use these 4 labels (if this argument is not given, than all labels will be used)
%   label_names_to_use = { 'hand',    'face',    'guitar',    'flower'};  
%  
%   % get the ANOVA p-values for all neurons at all time bins 
%   [ANOVA_pvalues_all_sites ANOVA_STATS_all_sites] = get_ANOVA_pvalues_from_binned_data(binned_data_name, specific_binned_label_name, label_names_to_use)
%
%   % plot the percentage of neurons that have p-values less than 0.05
%   plot(mean(ANOVA_pvalues_all_sites < .05))
%
%



%==========================================================================

%     This code is part of the Neural Decoding Toolbox.
%     Copyright (C) 2011 by Ethan Meyers (emeyers@mit.edu)
% 
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
%========================================================================== 



% gets the binned_data and the specific binned labels to use for different formats of binned_data_name and specific_binned_label_name
[binned_data, binned_labels_to_use] = retrieve_binned_format_data(binned_data_name, specific_binned_label_name);



if nargin < 3
    label_names_to_use = [];
end

if nargin < 4
    sites_to_use = 1:length(binned_data);
end


%addpath ../../helper_functions/   % add path to compute_oneway_ANOVA



% if binned_labels_to_use{iSite} is a cell array of strings, convert it into a vector of numbers
if iscell(binned_labels_to_use{1})
    binned_labels_to_use_numbers = convert_label_strings_into_numbers(binned_labels_to_use, 0);
else
    binned_labels_to_use_numbers = binned_labels_to_use;
end


for iSite = 1:length(sites_to_use)

     % if using only a subset of labels, eliminate data/labels from the unused trials
    if ~isempty(label_names_to_use)
        trial_inds_to_use = find(ismember(binned_labels_to_use{sites_to_use(iSite)}, label_names_to_use));       
        Y_labels = binned_labels_to_use_numbers{sites_to_use(iSite)}(trial_inds_to_use); 
        X_data = binned_data{sites_to_use(iSite)}(trial_inds_to_use, :);
    else
        Y_labels = binned_labels_to_use_numbers{sites_to_use(iSite)};
        X_data = binned_data{sites_to_use(iSite)};
    end
   
        
    [ANOVA_pvals, ANOVA_STATS] = compute_oneway_ANOVA(X_data, Y_labels);  % compute_oneway_ANOVA does all the heavy work
   
    
    ANOVA_pvalues_all_sites(iSite, :) = ANOVA_pvals;
    ANOVA_STATS_all_sites{iSite} = ANOVA_STATS;
        
end






