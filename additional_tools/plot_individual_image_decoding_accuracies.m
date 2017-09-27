function plot_individual_image_decoding_accuracies(standard_decoding_results_file_name, name_of_directory_of_images, ordered_image_names, num_top_images_to_plot, plot_with_decoding_accuracy)

% This function ranks the decoding accuracy of each image and plots them in order from the highest decoding accuracy in the upper left to the
%   lowest decoding accuracy in the bottom right.  
% 
%
% 
% Input arguments:
%
%   1. standard_decoding_results_file_name: a string specifying the name of the saved decoding results in standard results format
%   2. name_of_directory_of_images: a string specifying the path to the directory that contains the images
%   3. ordered_image_names a cell array that has the names of the images in the order that they appear in as rows of the standard results confusion matrix
%   4. num_top_images_to_plot: how many of the top images should be plotted. If this is not set, all the images will be plotted although this
%       might make it hard to see the images if there are too many of them
%   5. plot_with_decoding_accuracy (default = 1):  if set to 1 plot a colored bar at the top of the image indicating the decoding accuracy and also plots 
%       a title indicating the percent correct.  Otherwise it plots all the images as a montage without the decoding accuracy given.  
%
%   Note: could also save as a movie that is plotted as a function of time
%



% load the binned data 
load(standard_decoding_results_file_name)


% extract the confusion matrix
the_confusion_matrices = DECODING_RESULTS.ZERO_ONE_LOSS_RESULTS.confusion_matrix_results.confusion_matrix;
total_num_test_points = sum(the_confusion_matrices(:, :, 1));  % assuming the first time bin has as many test points as all other time bins
the_confusion_matrices = the_confusion_matrices./total_num_test_points(1);  % assuming all labels have the same number of test points 
the_confusion_matrices = the_confusion_matrices .* 100;  % convert to percent correct


% if the number of top images to plot is not specified plot all the images
if nargin < 4 || isempty(num_top_images_to_plot) || num_top_images_to_plot < 1
    num_top_images_to_plot = size(the_confusion_matrices, 1);
end

if nargin < 5
    plot_with_decoding_accuracy = 1;
end




max_accuracy = max(max(max(the_confusion_matrices))) + 2;

if max_accuracy > 100
    max_accuracy = 100;
end





if plot_with_decoding_accuracy == 1


    num_rows_and_cols = ceil(sqrt(num_top_images_to_plot + 1));   % the plus 1 is to have an extra subplot for the colorbar

    the_colormap = colormap;

    for iTime = 1:size(the_confusion_matrices, 3)

       [sorted_decoding_accuracy_vals sorted_image_inds] = sort(diag(squeeze(the_confusion_matrices(:, :, iTime))), 'descend');


        for iTopImage = 1:num_top_images_to_plot


            curr_image = imread([name_of_directory_of_images ordered_image_names{sorted_image_inds(iTopImage)}]); 
            curr_image_decoding_accuracy = sorted_decoding_accuracy_vals(iTopImage);


            % get the color based on the colormap!
            color_ind = (curr_image_decoding_accuracy./max_accuracy) .* size(the_colormap, 1)  + 1;      
            rgb_color = (((the_colormap(ceil(color_ind), :) .* (1 - (ceil(color_ind) - color_ind))) + (the_colormap(floor(color_ind), :) .* (1 - (color_ind  - floor(color_ind))))) .* 255);

            for i = 1:3
                new_image(:, :, i) = [rgb_color(i) .* ones(10, 100); curr_image]; 
            end

            subplot(num_rows_and_cols, num_rows_and_cols, iTopImage)
            imshow(new_image)

            title([num2str(round(curr_image_decoding_accuracy)) '%']);

        end


        % add the colorbar as the last image
        h = subplot(num_rows_and_cols, num_rows_and_cols, iTopImage  + 1);
        ax = get(h, 'position');  % prevents the axis from shrinking
        set(h, 'position', ax);
        axis off
        colorbar

        pause


    end 

    
    

else
    
    
    
      for iTime = 1:size(the_confusion_matrices, 3)

           [sorted_decoding_accuracy_vals sorted_image_inds] = sort(diag(squeeze(the_confusion_matrices(:, :, iTime))), 'descend');


            for iTopImage = 1:num_top_images_to_plot

                all_ordered_images{iTopImage} = [name_of_directory_of_images ordered_image_names{sorted_image_inds(iTopImage)}]; 

            end

            montage(all_ordered_images)

            pause
        
      end

      
      
end





set(gcf, 'paperPositionMode', 'auto')







