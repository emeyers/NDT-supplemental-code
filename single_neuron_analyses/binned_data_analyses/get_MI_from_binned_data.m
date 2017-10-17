function MI_RESULTS = get_MI_from_binned_data(binned_data_name, specific_binned_label_name, label_numbers_to_use, num_bias_correction_shuffled_resamples, use_uniform_prior_stimulus_distribution, sites_to_use)

% This function calculates the mutual information between binned_data and particular binned_labels 
%   for each site at all time periods, using the standard formula: 
%   MI(S; R) = sum_s p(S) .* sum_r p(R|S) log2 P(R|S)./P(R)  where R = binned_data{iSite}(:, iTime), 
%   and S = binned_labels_to_use{iSite}.  A biased correction is applied by subtracted the amount of 
%   mutual information found between the data and randomly shuffled labels (averaged over a number of 
%   random shuffles of the data; see Panzei J. Neurophys. 2007).  The biased version of the mutual information 
%   is also returned, along with p-values that assess how likely the real mutual information value is 
%   to have come from the shuffled null-distribution.  The input arguments to this function are:
%
%   1.  binned_data_name: the data in binned-format or a string that specifies a file that has data in binned format
%
%   2.  specific_binned_label_name: particular binned labels used to calculate mutual information from 
%          (e.g., binned_labels.specific_binned_label_name). This is a character array listing the name of the labels that should be used.
%
%  Optional input arguments:
%
%   3.  label_numbers_to_use:  which labels numbers should be used (of the names/numbers listed in binned_labels_to_use). 
%           If this field is empty (or if this argument is not given) then all the labels available will be 
%           used (i.e., label_numbers_to_use = unique(binned_labels_to_use{iSite}). This field can also be a cell array of
%           of strings with the names of labels to use if the binned_labels are strings.
%       
%   4.  num_bias_correction_shuffled_resamples: the number times the mutual information should be 
%           calcuated from randomly shuffled data when estimating the bias term that will be subtracted 
%           from the mutual information results (and when calculating the p-values for assessing the 
%           probability that the observed mutual information was due to chance).  The larger this 
%           number is the more accurate the bias correction term will be, and the more accurate the 
%           p-value can be.  By default num_bias_correction_shuffled_resamples = 100, which means that 
%           the smallest p-values is < 0.01.
%         
%   5.  use_uniform_prior_stimulus_distribution: indicates if whether the prior distribution over stimuli, P(S), 
%           should be calculated from binned_labels_to_use{iSite} or whether it should be assumed that all 
%           stimuli are equally likely (i.e., P(S) = 1/num_unique_stimuli).
%
%  The results from this function are returned in the structure MI_RESULTS that has the following fields:
%
%   1.  .MI:  a matrix that is [num_sites x num_times] large that has the mutual information for each site 
%               at each point in time.  This estimate of mutual information is bias correacted, where the 
%               bias is estimated by: a) randomly shuffling the labels and calculating the mutual information 
%               from calculating the mutual information between the data and the randomly shuffled labels 
%               b) repating step 'a' a number of times and then averaging the results over all these random 
%               shuffled MI estimates (see Panzei J. Neurophys. 2007 for more details).
%
%   2.  .no_bias_correction_MI:  the mutual information without the bias term subtracted. Unless one has 
%               a very very large amount of data, this estimate should not be used (and if one has a 
%               very very large amount of data, then this estimate should be the same as the bias corrected 
%               version MI_RESULTS.MI).
%
%   3.  .MI_pvalues: p-values in a [num_sites x num_times] matrix indicating the probability that a 
%               mutual information value for a particular site at a particular point in time was due 
%               to chance.  These values are calculated by observing where the real mutual information 
%               value lies in terms of the null-distribution that is calculated by randomly shuffling
%               the relationship between the labels and the data (i.e., the same null-distribution used 
%               to esimate the MI bias).
%
%   4.  .num_bias_correction_shuffled_resamples:  saves the input parameter listing how many randomly 
%               shuffled resamples were used to calculate the bias term and the MI_pvalues
%
%   5.  .use_uniform_prior_stimulus_distribution:  saves the input parameter listing whether P(S) 
%               was calculated from the data or whether a uniform prior over stimuli should be assumed
%
%   6.  .label_numbers_used:  saves the input parameter listing which label numbers were used when 
%               calculating the mutual information  
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


% if specific label numbers are not specified, use all the label numbers in the data
if nargin < 3
   label_numbers_to_use = [];   
end
    
%  use 100 randomly shuffled resamples of the data for bias correction as a default if a different number is not given    
if (nargin < 4) || isempty(num_bias_correction_shuffled_resamples)   
    num_bias_correction_shuffled_resamples= 100;
end

% by default use the number of times each stimulus was presented as the prior distribution for how likely each stimulus is 
%  (rather than a uniform distribution over stimuli)
if (nargin < 5) || isempty(use_uniform_prior_stimulus_distribution)
    use_uniform_prior_stimulus_distribution = 0;
end


% by default use all the sites 
if (nargin < 6) || isempty(sites_to_use)
    sites_to_use = 1:length(binned_data);
end


if iscell(binned_labels_to_use{1})
    [binned_labels_to_use, string_to_number_mapping] = convert_label_strings_into_numbers(binned_labels_to_use);
end


% if label_numbers_to_use is a cell array of strings, convert them to the appropriate numbers
if ~isempty(label_numbers_to_use) && iscell(label_numbers_to_use)
    label_numbers_to_use = find(ismember(string_to_number_mapping, label_numbers_to_use));
end


% pre-allocate the memory to store the shuffled MI results
MI_shuffled_values = NaN * ones(numel(sites_to_use), size(binned_data{1}, 2), num_bias_correction_shuffled_resamples);


for iSite = 1:numel(sites_to_use)
   
    
    % print a message about the progress of how many sites MI has been calculated for (since the code can be slow)
    curr_bin_string = [' Calculating MI for site: ' num2str(iSite) ' of ' num2str(numel(sites_to_use))];
    if iSite == 1
        disp(curr_bin_string); 
    else
        fprintf([repmat(8,1,bin_str_len) curr_bin_string]);         
    end
    bin_str_len = length(curr_bin_string);
   
   
   
   curr_site_ind = sites_to_use(iSite);
   
    
   [MI_bias_corrected, MI_no_bias_correction, MI_pvalues, curr_MI_shuffled_values] = get_MI_one_site_shuffle_bias_correction(binned_data{curr_site_ind}, binned_labels_to_use{curr_site_ind}, label_numbers_to_use, num_bias_correction_shuffled_resamples, use_uniform_prior_stimulus_distribution);    
    
   MI_RESULTS.MI(iSite, :) = MI_bias_corrected;
   MI_RESULTS.no_bias_correction_MI(iSite, :) = MI_no_bias_correction;    
   MI_RESULTS.MI_pvalues(iSite, :) = MI_pvalues;
   MI_shuffled_values(iSite, :, :) = curr_MI_shuffled_values;
         
end


% save a few additional parameters that were used to calculate the mutual information
MI_RESULTS.num_bias_correction_shuffled_resamples = num_bias_correction_shuffled_resamples;
MI_RESULTS.use_uniform_piror_stimulus_distribution = use_uniform_prior_stimulus_distribution;
MI_RESULTS.label_numbers_used = label_numbers_to_use;

MI_RESULTS.MI_shuffled_values = MI_shuffled_values;


% print a new line at the end so that the prompt is left justified
fprintf('\n')






function [MI_bias_corrected, MI_no_bias_correction, MI_pvalues, MI_shuffled] = get_MI_one_site_shuffle_bias_correction(R, S, label_numbers_to_use, num_bias_corrected_shuffles, use_uniform_stim_dist)
% A helper function that gets the mutual information from one binned site (at all times) using the formula:  
%   MI(S; R) = sum_s p(S) .* sum_r p(R|S) log2 P(R|S)./P(R) 
%
% The input arguments to this function are:
%  1. S:  [num_trials x 1] vector of stimulus labels
%  2. R:  [num_trials x num_time_periods] matrix of binned data
%
% There are also optional input arguments:
%  3. use_uniform_stim_dist: (default 0) if this is set to one then the MI will be computed using the prior P(S) = 1/S,
%      otherwise P(S) will be based on the proportion of the labels that belong to class k.
%  4. label_numbers_to_use:  if this is set then only specific labels (and their corresponding data) will be used when computing
%      the MI.  The default is to use all the unique labels in S.
%  5.  num_bias_corrected_shuffles:  (default = 100).  The number of random shuffles that should be used when computing the bias correction term.
%       the larger this number is the more accurate the bias correction will be, and the slower the code will run.



unique_stimuli_to_use = unique(S);
if (nargin > 2) && ~(isempty(label_numbers_to_use))
     unique_stimuli_to_use = intersect(unique_stimuli_to_use, label_numbers_to_use);
end


% if (nargin < 4) || isempty(use_uniform_stim_dist)
%     use_uniform_stim_dist = 0;
% end 
%     
% if (nargin < 5) || isempty(num_bias_corrected_shuffles)   
%     num_bias_corrected_shuffles = 100;
% end



% return that there is no MI if all the responses are always the same or if only 1 stimulus was used
unique_response = unique(R);

if (length(unique_response) == 1) || (length(unique_stimuli_to_use) == 1)
    MI_bias_corrected = 0;
    MI_no_bias_correction = 0;
    MI_pvalues = 1;
    MI_shuffled = 0;
    
    % print a warning if only one stimulus was used since you really shouldn't be computing MI if only 1 stimulus was used
    if (length(unique_stimuli_to_use) == 1)
        warning('Only one stimulus was used in this site, so you really should not be computing MI for this stite')
    end
    
    return
end



% variable name mapping:
% P_stim = P(S)         => the marginal probability of a given stimulus
% P_resp = P(R)         => the marginal probability of a given response value 
% P_R_given_S = P(R|S)  => a maxtrix sized [num_stim x num_responses] listing the conditional probability of a response given a stimulus



% calculate the conditional probability distribution P(R|S)
for iStim = 1:length(unique_stimuli_to_use)
    
    % calculate P(S)
    P_stim(iStim) = length(find(S == unique_stimuli_to_use(iStim)));
    
    curr_response = R((S == unique_stimuli_to_use(iStim)), :);
    
    if size(curr_response, 1) == 1   % this deals with the rare case where there is only 1 repetition of a particular stimulus
        curr_response = [curr_response; -Inf .* ones(size(curr_response))];
    end
        
   P_R_given_S(iStim, :, :) =  histc(curr_response, unique_response)./P_stim(iStim);    
    
end


% calculate P(S)
if use_uniform_stim_dist == 1
    P_stim = ones(size(P_stim))./length(unique_stimuli_to_use);
else
    P_stim = P_stim./sum(P_stim);
end


% calculate P(R)
P_resp = squeeze(sum(P_R_given_S))./length(unique_stimuli_to_use);


% calculate MI
if size(P_R_given_S, 3) > 1  % if there are more than 1 time bin being used
    MI_no_bias_correction = squeeze(nansum(P_R_given_S .* (log2(P_R_given_S) - shiftdim(repmat(log2(P_resp), [1, 1, size(P_R_given_S, 1)]), 2)), 2))' * P_stim';               
else
    MI_no_bias_correction = squeeze(nansum(P_R_given_S .* (log2(P_R_given_S) - repmat(log2(P_resp), [size(P_R_given_S, 1) 1])), 2))' * P_stim';  % (I think this is correct)             
end


% create the bias corrected version by getting the mutual information num_bias_corrected_shuffles times 
%  using randomly shuffled labels each time and then subtracting this bias estimate from the MI calculated using 
%  the real labels (see Panzei J Neurophys 2007).  I am using the same code as above - but I decided not to make
%  this a separate function b/c I figured it will run faster this way).

% pre-allocate memory to store stuffled MI results
MI_shuffled = NaN * ones(num_bias_corrected_shuffles, size(R, 2));

for iShuffle = 1:num_bias_corrected_shuffles
    
    clear P_stim P_R_given_S P_resp
    
    S = S(randperm(length(S)));
    
    % calculate the conditional probability distribution P(R|S)
    for iStim = 1:length(unique_stimuli_to_use)

        % calculate P(S)
        P_stim(iStim) = length(find(S == unique_stimuli_to_use(iStim)));

        curr_response = R((S == unique_stimuli_to_use(iStim)), :);

        
        if size(curr_response, 1) == 1   % this deals with the rare case where there is only 1 repetition of a particular stimulus
            curr_response = [curr_response; -Inf .* ones(size(curr_response))];
        end 
        
        P_R_given_S(iStim, :, :) =  histc(curr_response, unique_response)./P_stim(iStim);

    end


    % calculate P(S)
    if use_uniform_stim_dist == 1
        P_stim = ones(size(P_stim))./length(unique_stimuli_to_use);
    else
        P_stim = P_stim./sum(P_stim);
    end


    P_resp = squeeze(sum(P_R_given_S))./length(unique_stimuli_to_use);


    % calculate MI
    if size(P_R_given_S, 3) > 1  % if there are more than 1 time bin being used
        MI_shuffled(iShuffle, :) = squeeze(nansum(P_R_given_S .* (log2(P_R_given_S) - shiftdim(repmat(log2(P_resp), [1, 1, size(P_R_given_S, 1)]), 2)), 2))' * P_stim';               
    else
        MI_shuffled(iShuffle, :) = squeeze(nansum(P_R_given_S .* (log2(P_R_given_S) - repmat(log2(P_resp), [size(P_R_given_S, 1) 1])), 2))' * P_stim';  % (I think this is right)              
    end
    
 
    
end


MI_bias_corrected = MI_no_bias_correction - mean(MI_shuffled)';



% MI_pvalues
for iTime = 1:size(MI_shuffled, 2)
   MI_pvalues(iTime) = 1 - (length(find(MI_no_bias_correction(iTime) > MI_shuffled(:, iTime))))./size(MI_shuffled, 1);
end

MI_shuffled = MI_shuffled'; 

