function ROC_results = get_ROC_from_binned_data(binned_data, binned_labels_to_use, label_numbers_to_use, sites_to_use)


% might not be working perfectly yet since seems to be assymetry between ROC_results{1} and ROC_results{2} when only 2 labels are used...

% note: uses the cross-validators/get_AUC.m function

% to plot the results you can use:  for i = 1:size(ROC_RESULTS), plot(mean(abs(.5 - ROC_RESULTS{i}))); pause, end



% if binned data is the name of a file (rather than actual binned_data) load the file to get the binned data
if ischar(binned_data)
    load(binned_data)  % load the binned_data file name to get the actual binned data
end

% if binned_labels_to_use is the name of the labels that should be used (rather than the actual cell array of labels) 
%  get the actual array of labels that correspond to this name...
if ischar(binned_labels_to_use)
    binned_labels_to_use = eval(['binned_labels.' binned_labels_to_use]);
end


% if specific label numbers are not specified, use all the label numbers in the data
if nargin < 3
   label_numbers_to_use = [];   
end


% by default use all the sites 
if (nargin < 4) || isempty(sites_to_use)
    sites_to_use = 1:length(binned_data);
end



if iscell(binned_labels_to_use{1})
    [binned_labels_to_use, string_to_number_mapping] = convert_label_strings_into_numbers(binned_labels_to_use);
end



% if label_numbers_to_use is a cell array of strings, convert them to the appropriate numbers
if ~isempty(label_numbers_to_use) && iscell(label_numbers_to_use)
    label_numbers_to_use = find(ismember(string_to_number_mapping, label_numbers_to_use));
end




for iSite = 1:numel(sites_to_use)
    
    
    %iSite
    
    
    
    if isempty(label_numbers_to_use)
        curr_label_numbers_to_use = unique(binned_labels_to_use{iSite}); 
    else
        curr_label_numbers_to_use = label_numbers_to_use;
    end

    
    all_valid_label_inds = find(ismember(binned_labels_to_use{iSite}, curr_label_numbers_to_use));

    
    for iLabel = 1:numel(curr_label_numbers_to_use)
            
        target_present_inds = find(binned_labels_to_use{iSite} == curr_label_numbers_to_use(iLabel));
        target_absent_inds = intersect(all_valid_label_inds, find(binned_labels_to_use{iSite} ~= curr_label_numbers_to_use(iLabel))); 


        for iTime = 1:size(binned_data{iSite}, 2)            
            ROC_results{iLabel}(iSite, iTime) = get_AUC(binned_data{iSite}(target_present_inds, iTime),  binned_data{iSite}(target_absent_inds, iTime));
        end

    end

    
end
    
    












