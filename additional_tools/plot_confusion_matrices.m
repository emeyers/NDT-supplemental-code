function plot_confusion_matrices(standard_decoding_results_file_name, time_bin_to_use, name_order, use_constant_decoding_accuracy_range_across_time)
%
% This function plots the confusion matrices for the zero-one loss decoding accuracy (could also plot the rank confusion matrices...) 
% 
% 
% Input arguments:
%
%   1. standard_decoding_results_file_name: a string specifying the name of the saved decoding results in standard results format
%
% Optional input arguments:
%   2. the_bin_to_use: time bin that should be used, if this isn't given or set to -1 then the confusion matrix will step through all time bins 
%   3. name_order: the order of the names in the rows and columns of the confusion matrix
%   4. use_constant_decoding_accuracy_range_across_time: have the color range in the imagesc matrix be the same across all times 
%        (set to the min and max decoding accuracies across all time and classes)
%
%   Note: could also save as a movie that is plotted as a function of time
%





% if a time bin to plot the confusion matrix is not specified then all then the results will step through all time bins
if (nargin < 2) || isempty(time_bin_to_use) 
    time_bin_to_use = -1;
end


if nargin < 3 
    name_order = [];
end

if nargin < 4 
    use_constant_decoding_accuracy_range_across_time = 0;
end



% load the binned data
load(standard_decoding_results_file_name)


% extract the confusion matrix for the zero-one loss results
the_confusion_matrices = DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.confusion_matrix_results.confusion_matrix;
total_num_test_points = sum(the_confusion_matrices(:, :, 1));  % assuming the first time bin has as many test points as all other time bins
the_confusion_matrices = the_confusion_matrices./total_num_test_points(1);  % assuming all labels have the same number of test points 
the_confusion_matrices = the_confusion_matrices .* 100;  % convert to percent correct


% get the names of the rows/columns of the confusion matrix
the_cm_label_mapping = DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.confusion_matrix_results.label_remapping;
num_to_name_mapping = DECODING_RESULTS.DS_PARAMETERS.label_names_to_label_numbers_mapping;

for iName = 1:numel(the_cm_label_mapping)
   
   curr_label_name = num_to_name_mapping{the_cm_label_mapping(iName)};
   
   if ~isempty(name_order)
       row_column_order(iName) = find(ismember(name_order, curr_label_name));
   else
       row_column_order(iName) = iName;  % otherwise use the identity transformation (i.e., don't change anything)
   end
   
   curr_label_name = strrep(curr_label_name,'_', ' ');  % replace underscores with spaces when displaying the names 
   confusion_matrix_row_and_colum_names{row_column_order(iName)} = curr_label_name;
   
end


% rearrange the rows and columns of the confusion matrix so that they are in the correct order given by the name_order
the_confusion_matrices = the_confusion_matrices(row_column_order, row_column_order, :); 





% min_and_max_accuracies are used for the colormap if one is plotting a constant color map across all time points...
if use_constant_decoding_accuracy_range_across_time == 1
    min_and_max_accuracies = [min(min(min(the_confusion_matrices))) max(max(max(the_confusion_matrices)))];
else
    min_and_max_accuracies = [];
end


if isscalar(time_bin_to_use) && time_bin_to_use < 1

    try
        start_bin_times = DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.the_bin_start_times;
        bin_width = DECODING_RESULTS.DS_PARAMETERS.binned_site_info.binning_parameters.the_bin_widths;
    catch
        start_bin_times = [];
        bin_width = [];
    end
    
    
    the_colormap = colormap;

    for iTime = 1:size(the_confusion_matrices, 3)

       if ~isempty(start_bin_times)
          the_title = ['Time ' num2str(start_bin_times(iTime)) '-'  num2str(start_bin_times(iTime) + bin_width(iTime) - 1) ' ms'];
       else
           the_title = '';
       end
        
        
       plot_one_confusion_matrix(squeeze(the_confusion_matrices(:, :, iTime)), confusion_matrix_row_and_colum_names, min_and_max_accuracies);
       title(the_title) 
       
       pause;
       
    end
    
    
else
    
       plot_one_confusion_matrix(squeeze(the_confusion_matrices(:, :, time_bin_to_use)), confusion_matrix_row_and_colum_names, min_and_max_accuracies);
     
end
   

set(gcf, 'paperPositionMode', 'auto')


end   % end of the main function





% helper function to actually plot the confusion matrix
function plot_one_confusion_matrix(confusion_matrix, row_and_colum_names, min_and_max_accuracies)


    if ~isempty(min_and_max_accuracies)
        h = imagesc(confusion_matrix, min_and_max_accuracies); colorbar
    else
        h = imagesc(confusion_matrix); colorbar
    end
    
    set(gca, 'YTickLabel', row_and_colum_names);
    set(gca, 'XTickLabel', row_and_colum_names);
    xtickangle(300);  % rearrange the orientation of the x-labels...

end






