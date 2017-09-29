function ROC_RESULTS = get_ROC_from_binned_data(binned_data_name, specific_binned_label_name, label_names_to_use, sites_to_use)
% 
% This function calculates the area under the ROC curve. For each class label i, the area under the ROC curve is caluclated using
% the data from class i and the first class, and the data from all the other classes as the second class. 
%
%
% The input arguments to this function are:
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
%  The results returned is ROC_RESULTS which is a cell array, where each cell ROC_RESULTS{i} contains the area under the ROC curve
%       between class i and all other classes.
%
%
%
%  Note: this function uses the cross-validators/get_AUC.m function from the Neural Decoding Toolbox
%
%
%  Example of plotting the mean deviation from unity (.5) on the ROC curve for each class compared to all other classes  
%
%   for i = 1:size(ROC_RESULTS) 
%        plot(mean(abs(.5 - ROC_RESULTS{i}))); 
%        pause
%   end
%       




% gets the binned_data and the specific binned labels to use for different formats of binned_data_name and specific_binned_label_name
[binned_data, binned_labels_to_use] = retrieve_binned_format_data(binned_data_name, specific_binned_label_name);



% if specific label numbers are not specified, use all the label numbers in the data
if nargin < 3
   label_names_to_use = [];   
end


% by default use all the sites 
if (nargin < 4) || isempty(sites_to_use)
    sites_to_use = 1:length(binned_data);
end



if iscell(binned_labels_to_use{1})
    [binned_labels_to_use, string_to_number_mapping] = convert_label_strings_into_numbers(binned_labels_to_use);
end



% if label_names_to_use is a cell array of strings, convert them to the appropriate numbers
if ~isempty(label_names_to_use) && iscell(label_names_to_use)
    label_names_to_use = find(ismember(string_to_number_mapping, label_names_to_use));
end




for iSite = 1:numel(sites_to_use)
    
    
    % could add code to display progress, but the code runs pretty fast...
    
    
    if isempty(label_names_to_use)
        curr_label_names_to_use = unique(binned_labels_to_use{iSite}); 
    else
        curr_label_names_to_use = label_names_to_use;
    end

    
    all_valid_label_inds = find(ismember(binned_labels_to_use{iSite}, curr_label_names_to_use));

    
    for iLabel = 1:numel(curr_label_names_to_use)
            
        target_present_inds = find(binned_labels_to_use{iSite} == curr_label_names_to_use(iLabel));
        target_absent_inds = intersect(all_valid_label_inds, find(binned_labels_to_use{iSite} ~= curr_label_names_to_use(iLabel))); 


        for iTime = 1:size(binned_data{iSite}, 2)            
            ROC_RESULTS{iLabel}(iSite, iTime) = get_AUC(binned_data{iSite}(target_present_inds, iTime),  binned_data{iSite}(target_absent_inds, iTime));
        end

    end

    
end
    
    












