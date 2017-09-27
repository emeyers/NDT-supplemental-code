function STA_images = create_STA_images_from_binned_data(name_of_directory_of_images, binned_data_file_name, binned_labels_to_use, label_name_to_image_name_mapping, STA_image_normalization_type)

% This function create spike triggered average (STA) images from binned data and a directory of images.  A spike triggered average image is an image
%  that is the sum of each image that was shown to a neuron multiplied by the mean firing rate a neuron has to each image.  The inputs to this function are:
%
%   1.  name_of_directory_of_images:  a string containing the path to the directory that contains the images that were shown to each neuron
%   2.  binned_data_file_name: a string containing the name of a file in binned format (or a binned_data cell array)
%   3.  binned_labels_to_use:  a string containing the name of the specific binned_labels to use (or the cell array/vector of specific binned labels is binned_data is a cell array)
%   4.  label_name_to_image_name_mapping: a {num_stimuli_to_use} x {2} cell array that specifies which binned_label.specific_label corresponds to which image.  For
%           each stimulus that is used label_name_to_image_name_mapping{iStimulus_Label}{1} is a unique binned_label.specific_label name (or number) and 
%           label_name_to_image_name_mapping{iStimulus_Label}{2} is a string containing the name of an image in the name_of_directory_of_images directory. 
%   5.  STA_image_normalization_type (default is 2):  Specifying how the STA images should be normalized for display. A value of 1 makes it so that the maximum/minimum pixel value
%           in each image is determined by the maximum/minimum values from all neurons at all time bins;  a value of 2 makes it so that the maximum/minimum pixel 
%           valuein each image is determined by the maximum/minimum values separately for each neurons but take over all time bins; a value of 3 makes it so that 
%           the maximum/minimum pixel value in each image is determined by the maximum/minimum values separately for each neurons and separately for each time bin.
%
%  Function outputs:
%
%   1. STA_images:  A [num_sites x num_pixels_y x num_pixels_x x num_time_bins] matrix that contains the STA images for each site and each time bin.
%
%
%  note:  I have only tested this for black and white images, might have to make some modifications for color images (or perhaps all color images should be 
%       converted to black and white since it does not really make sense to average colors together).  Also could add the option to whiten the images but to do
%       this in a reasonable way might require setting a regularization parameter which could be annoying).  
%




% determins what the maximum 
if nargin < 5
    STA_image_normalization_type = 2;
end


% this should probably always be set to one so that if there is a bias in the stimulus set it will be subtracted out
subtract_stimuli_mean = 1;  


% load the binned data 
if isstr(binned_data_file_name)
    load(binned_data_file_name);
    specific_binned_labels = eval(['binned_labels.' binned_labels_to_use]);
elseif iscell(binned_data_file_name)
    binned_data = binned_data_file_name;
    specific_binned_labels = binned_labels_to_use;
end



% load all the images
for iImage = 1:numel(label_name_to_image_name_mapping)
    curr_image = imread([name_of_directory_of_images label_name_to_image_name_mapping{iImage}{2}]);
    image_size = size(curr_image);    % assuming all images are the same size (if not it will be impossible to average them)
    all_images(iImage, :) =  double(curr_image(:));
    label_names_to_use{iImage} = label_name_to_image_name_mapping{iImage}{1};
end


if subtract_stimuli_mean == 1
    all_images = all_images - repmat(mean(all_images), [size(all_images, 1), 1]);
end




STA_images = zeros([numel(binned_data) image_size, size(binned_data{1}, 2)]);


for iSite = 1:numel(binned_data)
    
    
    iSite
    
    curr_labels = specific_binned_labels{iSite};
    
    % calculate the mean firing rate for each site and each stimulus
    for iStim = 1:numel(label_names_to_use)        
         curr_stim_inds = find(ismember(curr_labels, label_names_to_use{iStim}));
         curr_mean = nanmean(binned_data{iSite}(curr_stim_inds, :), 1);   
         curr_mean(isnan(curr_mean)) = 0;
         curr_mean_firing_rates(iStim, :) = curr_mean;
    end
       
    
    % normalize all the means to sum to 1 
    curr_normalized_mean_firing_rates = curr_mean_firing_rates./(repmat(sum(curr_mean_firing_rates, 1), [size(curr_mean_firing_rates, 1), 1]) + ~repmat(sum(curr_mean_firing_rates, 1), [size(curr_mean_firing_rates, 1), 1]));
    
    
    STA_images(iSite, :, :, :)  = reshape(all_images' * curr_normalized_mean_firing_rates, [image_size size(binned_data{iSite}, 2)]);
   
   
    %all_firing_rates(iSite, :) = mean(curr_mean_firing_rates, 1);
   
    clear curr_mean_firing_rates curr_normalized_mean_firing_rates
    
   
end





% put images in the range of 0 to 255  

if STA_image_normalization_type == 1   % normalize image to the max and min across all images and all times
    
    STA_images =  STA_images - min(min(min(min(STA_images))));                      % might have to add another max/min if using color images...
    STA_images =  255 .* (STA_images./max(max(max(max(squeeze(STA_images))))));   

    
elseif STA_image_normalization_type == 2   % normalize image to the max and min across all times separately for each image    
 
   STA_images = STA_images - repmat(min(min(min(STA_images, [], 4), [], 3), [], 2), [1 image_size size(STA_images, 4)]);  % might have to add another max/min if using color images    
   STA_images = 255 .* (STA_images./repmat(max(max(max(STA_images, [], 4), [], 3), [], 2), [1 image_size size(STA_images, 4)]));

elseif STA_image_normalization_type == 3    % normalize image to the max and min separately for each image and at each time bin

    STA_images = STA_images - shiftdim(repmat(squeeze(shiftdim(min(min(STA_images, [], 3), [], 2), 1)), [1, 1, 100, 100]), 5);
    STA_images = 255 .* (STA_images./shiftdim(repmat(squeeze(shiftdim(max(max(STA_images, [], 3), [], 2), 1)), [1, 1, 100, 100]), 5));

end
















