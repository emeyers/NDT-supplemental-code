classdef binsize_latency_object

% This object create a matrix that has measures of selectivity as a funciton of bin size
%  (y-axis) and as a function of time (x-axis) for each site.  It also contains a method
%  that allows one to plot these matrices for each neuron to visualize at what time
%  and at what latency each neuron is selective.  
%
%  binsize_latency_object has the following methods:
%
%  1. A constructor: bl = binsize_latency_object(datadir_name, name_of_binned_labels, result_type, bin_widths, step_size, label_names_to_use)  
%     All arguments to the constructor are optional, however datadir_name and name_of_binned_labels must be set to run create_binsize_latency_matrix method.
%     The meaning of these arguments are described below.
%   
%  2.  binsize_latency_matrix = bl.create_binsize_latency_matrix
%       This method create the binsize_latency_matrix.  In order to call this method the datadir_name and name_of_binned_labels 
%       properties must be set (either through the construction or by setting them afterward).  
%
%  3. bl.plot_binsize_latency_matrices
%       This method plots the binsize_latency_matrix for each site (pressing a key advances the plot to the next site).
%       To run this method, the binsize_latency_matrix property must be set by either setting it directly, or by 
%       calling the fucntion bl.create_binsize_latency_matrix which sets this property.
%
%   The binsize_latency_object has the following properties that are used when creating a binsize_latency_matrix
%
%   1. result_type (default = 1) 
%       This property specifies what selectivity measure is used when creating the binsize_latency_matrices.  Options are:
%        result_type = 1:  -log10 of ANOVA pvalues  (as calculated through the get_ANOVA_pvalues_from_binned_data function)
%        result_type = 2:  => ANOVA eta squared values (as calculated through the get_ANOVA_pvalues_from_binned_data function)
%        result_type = 3:  => Mutual Information (as calculated through the get_MI_from_binned_data function)
%        result_type = 4:  => p-values calculated from Mutual Information permutation test (as calculated through the get_MI_from_binned_data function)  
%
%   2. datadir_name.  The name of the directory that contains the binned files at a number of different bin_widths and a fixed step_size. 
%       Prior to using this object, one should create a number of binned data files using a number of different bin_widths and a fixed 
%       step_size (using bin_widhts of 50:50:1000 and a step_size of 5 is recommended).   
%
%   3. name_of_binned_labels.  This is the name of the binned_labels that will be used when calculating the selectivity measure.
%
%   4. bin_widths = (default = 50:50:1000).  This specifies the bin_widths that should be used (for the y-axis of the binsize_latency_matrices).  
%       Binned data files must have already been created for these bin_widths for the step_size listed below. 
%
%   5. step_size (default = 5). The step_size that should be used (spacing between successive elements on the x-axis).  
%       Binned data files must have already been created for this step size with the bin_widths listed above. 
%
%   6. subset_of_label_names_to_use (default = [], which means use all labels).  Can specify a subset of label names to use 
%       when calculated the selective measure used in the binsize_latency_matrix;
%
%   7. data_prefix_name (default =  'binned_data_').  Specifies that prefix name for the binned_data files.  This object 
%       assumes that all binned_data files are in the form [prefix_name bin_width 'ms_bins_' step_size 'ms_sampled.mat'],
%       e.g., binned_data files should be named something like 'binned_data_100ms_bins_5ms_sampled.mat'.
%   
%   8. binsize_latency_matrix.  This is a three dimensional tensor where of the form binsize_latency_matrix(num_sites, binwidth, latency),
%       where the first index is for each site, the second index is for the binwidth used, and the third index is for the latency.  Results
%       are typically plotting for each site separate (e.g., imagesc(squeeze(binsize_latency_matrix(iSite, :, :)))).  This variable can 
%       be set by calling the bl.create_binsize_latency_matrix method or one can set this tensor manually and then call the bl.plot_binsize_latency_matrices
%       method to plot the results; this is useful for saving time when one can compute and save the binsize_latency matrices using the bl.create_binsize_latency_matrix
%       and then just load them later when one wants to plot the results.
%       
%  There are also a number of parameters that can be set for plotting the results.  All plotting paramaters are in the strucuture
%   plot_params which has the following fields:
% 
%   1.  plot_params.significant_event_times.  A vector that can be set that will draw vertical lines at particular times.
%
%   2.  plot_params.sort_site_by_max_value.  If this is set to 1, each site will be plotted in the order of its maximum selectivity value
%       (calculated over all binwidths and latencies).
%   
%   3.  plot_params.sites_to_use.  If this is set then only the subset of sites will be plotted as given by the indecies listed here.
%

% Note to self: it might be useful to have bl.binsize_latency_matrix be a cell array that can contain different types of binsize_latency_matrices.
%  This will be useful when calculating related binsize_latency_matrix that take a long time to compute (e.g., MI and MI_pvalues).


% add comments for:  1)  bl.plot_params.threshold_result_level
%                    2)  bl = realign_binsize_latency_matrix(bl, bin_alignment)
%                    3)  reduce_binned_label_name property
%                    4)  reduce_specific_labels_to_keep


 
properties 

    result_type = 1;  % use ANOVA p-values as a default
    datadir_name = [];
    name_of_binned_labels = [];
    bin_widths = 50:50:1000;
    step_size = 5;
    subset_of_label_names_to_use = [];
    data_prefix_name = 'binned_data_';
    binsize_latency_matrix = [];
     
    plot_params = struct('significant_event_times', [], 'sort_site_by_max_value', [], 'sites_to_use', [], 'threshold_result_level', []); 
   
    reduce_binned_label_name = [];
    reduce_specific_labels_to_keep = [];
    
    
    movie_save_name = [];   % need to add documentation about this to the top of this file
    
end


properties (GetAccess = 'public', SetAccess = 'private')
    
        bin_alignment = 1;  % 1 => center aligned, 2 => right aligned (so that end of bins are aligned), 3 => left aligned (so that start of bins are aligned)
end




methods

    
    % constructor
    function bl = binsize_latency_object(datadir_name, name_of_binned_labels, result_type, bin_widths, step_size, bin_alignment, label_names_to_use)
            
            if nargin > 0
                bl.datadir_name = datadir_name;
            end
            
            if nargin > 1
                bl.name_of_binned_labels = name_of_binned_labels;
            end
                
            if nargin > 2
                bl.result_type = result_type;
            end
            
            if nargin > 3
                bl.bin_widths = bin_widths;
            end

            if nargin > 4
                bl.step_size = step_size;
            end
            
            
            if nargin > 5
                bl.bin_alignment = bin_alignment;
            end
            
            if nargin > 6
                bl.label_names_to_use = label_names_to_use;
            end

    end
        

    
    
    % main method to generate the binsize_latency matrix
    function bl = create_binsize_latency_matrix(bl)
       

        if isempty(bl.datadir_name)
            error('datadir_name must be set before calling the create_binsize_latency_matrix method');
        end
        
        if isempty(bl.name_of_binned_labels)
            error('name_of_binned_labels must be set before calling the create_binsize_latency_matrix method');
        end
        
        
        
        for iBinWidth = 1:length(bl.bin_widths) 

            tic
            
            % load the binned data and get the labels
            load([bl.datadir_name bl.data_prefix_name num2str(bl.bin_widths(iBinWidth)) 'ms_bins_' num2str(bl.step_size) 'ms_sampled.mat']);
            
            
            if ~isempty(bl.reduce_binned_label_name)
                binned_reduced_labels_to_use = eval(['binned_labels.' bl.reduce_binned_label_name]);
                [binned_data, binned_labels] = reduce_data_to_particular_trials(binned_data, binned_labels, binned_reduced_labels_to_use, bl.reduce_specific_labels_to_keep);
            end
            
            
            the_labels = eval(['binned_labels.' bl.name_of_binned_labels]);
            
                      
            if bl.result_type == 1  % result_type 1  => -log10 of ANOVA pvalues
                
                ANOVA_pvalues_all_sites = get_ANOVA_pvalues_from_binned_data(binned_data, the_labels, bl.subset_of_label_names_to_use);           
                binsize_latency_cell_array{iBinWidth} = -log10(ANOVA_pvalues_all_sites);
                
            elseif bl.result_type == 2  % result_type 2  => ANOVA eta^2 values            
                
                [ANOVA_pvalues_all_sites ANOVA_STATS_all_sites] = get_ANOVA_pvalues_from_binned_data(binned_data, the_labels, bl.subset_of_label_names_to_use); 
                for iSite = 1:length(ANOVA_STATS_all_sites)
                   binsize_latency_cell_array{iBinWidth}(iSite, :) = ANOVA_STATS_all_sites{iSite}.eta_squared; 
                end
 
            elseif bl.result_type == 3  % result_type 3  => Mutual Information
                
               MI_RESULTS = get_MI_from_binned_data(binned_data, the_labels, bl.subset_of_label_names_to_use);  %num_bias_correction_shuffled_resamples, use_uniform_prior_stimulus_distribution)
               binsize_latency_cell_array{iBinWidth} = MI_RESULTS.MI;

            elseif bl.result_type == 4  % result_type 4  => p-values calculated from Mutual Information  (permutation test)
                
               MI_RESULTS = get_MI_from_binned_data(binned_data, the_labels, bl.subset_of_label_names_to_use);  %num_bias_correction_shuffled_resamples, use_uniform_prior_stimulus_distribution)
               binsize_latency_cell_array{iBinWidth} = -log10(MI_RESULTS.MI_pvalues);    
               
            end

            toc

        end



        % convert binsize_latency_cell_array into a matrix 

        [min_bin_size min_bin_ind] = min(bl.bin_widths);
        num_ms_in_experiment = ((size(binsize_latency_cell_array{min_bin_ind}, 2) - 1).* bl.step_size) + min_bin_size;  % hopefully this is always right 

        start_times = bl.bin_widths./2;
        end_times = num_ms_in_experiment - start_times;

        ref_range = start_times(min_bin_ind):bl.step_size:end_times(min_bin_ind);  

        num_bins_to_use = length(bl.bin_widths);

        binsize_latency_matrix = NaN .* ones(length(binsize_latency_cell_array), num_bins_to_use, length(ref_range));   % pre-allocate to save memory

        
        for iBinSize = 1:num_bins_to_use   % calculate which columns that the data from each bin size should start and end at
           all_start_end_inds(iBinSize, :) = [find(ref_range == start_times(iBinSize))  find(ref_range == end_times(iBinSize))];
        end


         for iSite = 1:size(binsize_latency_cell_array{1}, 1)

             curr_neuron_matrix = NaN .* ones(num_bins_to_use, length(ref_range));

            for iBinSize = 1:num_bins_to_use
               curr_neuron_matrix(iBinSize, all_start_end_inds(iBinSize, 1):all_start_end_inds(iBinSize, 2)) = binsize_latency_cell_array{iBinSize}(iSite, :); 
            end

            binsize_latency_matrix(iSite, :, :) = curr_neuron_matrix;

         end

         
         bl.binsize_latency_matrix = binsize_latency_matrix;
         
    end  % end create_binsize_latency_matrix
    

    
    function bl = realign_binsize_latency_matrix(bl, bin_alignment)

        if bl.bin_alignment == bin_alignment  % if current alignemnt is equal to the alignment to be set, do nothing (perhaps print a message?)
           return
        end
           
        num_bins_between_adjacent_bin_widths = diff(bl.bin_widths)./bl.step_size;          
        total_num_bins = size(bl.binsize_latency_matrix, 3);
        

        % I'm sure there is a more concise way to write the below three if statments, but my brain is not working well at the moment...
        
        % start center 
        if (bl.bin_alignment == 1)            
            
           original_start_inds = [cumsum((num_bins_between_adjacent_bin_widths./2)) + 1];
           original_end_inds = total_num_bins - original_start_inds + 1;
           
            if bin_alignment == 2   % align right
                new_start_inds = original_start_inds + cumsum((num_bins_between_adjacent_bin_widths./2));
                new_end_inds = original_end_inds + cumsum((num_bins_between_adjacent_bin_widths./2));
            elseif bin_alignment == 3   % align left
                new_start_inds = original_start_inds - cumsum((num_bins_between_adjacent_bin_widths./2));
                new_end_inds = original_end_inds - cumsum((num_bins_between_adjacent_bin_widths./2));
            end

        end

        % if start right
        if (bl.bin_alignment == 2)  
            
            original_start_inds = [cumsum(num_bins_between_adjacent_bin_widths) + 1];
            original_end_inds = total_num_bins .* ones(size(original_start_inds));
            
           if bin_alignment == 1   % align center
                new_start_inds = original_start_inds - cumsum((num_bins_between_adjacent_bin_widths./2));
                new_end_inds = original_end_inds - cumsum((num_bins_between_adjacent_bin_widths./2));
           elseif bin_alignment == 3 
                new_start_inds = original_start_inds - cumsum((num_bins_between_adjacent_bin_widths));
                new_end_inds = original_end_inds - cumsum((num_bins_between_adjacent_bin_widths));
           end
            
        end
        
       
        % if start left
        if (bl.bin_alignment == 3)  
            
            original_end_inds = total_num_bins - cumsum(num_bins_between_adjacent_bin_widths);
            original_start_inds = ones(size(original_end_inds));
            
           if bin_alignment == 1   % align center
                new_start_inds = original_start_inds + cumsum((num_bins_between_adjacent_bin_widths./2));
                new_end_inds = original_end_inds + cumsum((num_bins_between_adjacent_bin_widths./2));
           elseif bin_alignment == 2 
                new_start_inds = original_start_inds + cumsum((num_bins_between_adjacent_bin_widths));
                new_end_inds = original_end_inds + cumsum((num_bins_between_adjacent_bin_widths));
           end
            
        end
        
        
        
        
        % add in first bin with always starts at 1 and ends at the total number of bins
        original_start_inds = [1 original_start_inds];
        new_start_inds = [1 new_start_inds];

        original_end_inds = [total_num_bins original_end_inds];
        new_end_inds = [total_num_bins new_end_inds];
        
        
        new_binsize_latency_matrix = NaN .* ones(size(bl.binsize_latency_matrix));
        for iBinWidth = 1:length(bl.bin_widths)
            new_binsize_latency_matrix(:, iBinWidth, new_start_inds(iBinWidth):new_end_inds(iBinWidth)) = bl.binsize_latency_matrix(:, iBinWidth, original_start_inds(iBinWidth):original_end_inds(iBinWidth)); 
        end
        
        
        bl.binsize_latency_matrix = new_binsize_latency_matrix; 
        
        bl.bin_alignment = bin_alignment;  % set bin_alginment to the new value

    end
    
    
    
    

    function plot_binsize_latency_matrices(bl)

        
        if isempty(bl.binsize_latency_matrix)
            error('bl.binsize_latency_matrix must be set before plotting the results by either setting this field manually, or by running the create_binsize_latency_matrix method')            
        end
        
        
         if ~isempty(bl.movie_save_name)
                   mov = avifile([bl.movie_save_name '.avi'], 'fps', 2);        
         end
        
        
        if ~isempty(bl.plot_params.sites_to_use)           
            bl.binsize_latency_matrix = bl.binsize_latency_matrix(bl.plot_params.sites_to_use, :, :);
        end

        
        if ~isempty(bl.plot_params.sort_site_by_max_value)  
               [max_vals inds] = sort(squeeze(max(max(bl.binsize_latency_matrix, [], 3), [], 2)), 'descend');
               bl.binsize_latency_matrix = bl.binsize_latency_matrix(inds, :, :);
        end

        
        if ~isempty(bl.plot_params.threshold_result_level)
            bl.binsize_latency_matrix = (bl.binsize_latency_matrix > bl.plot_params.threshold_result_level);  % threshold results...
        end
            
        
        for iSite = 1:size(bl.binsize_latency_matrix, 1)
            
            
            imagesc(squeeze(bl.binsize_latency_matrix(iSite, :, :)));
            colorbar
            
            % hmmm, not sure about this...
            x_ticks = get(gca, 'XTick');
            the_interval = (bl.bin_widths(1))./2:bl.step_size:(bl.step_size * (x_ticks(end) + 10));
            set(gca, 'XTickLabel', the_interval(x_ticks))
            
            set(gca, 'YTickLabel', bl.bin_widths(get(gca, 'YTick')))
       
            
            % put a line at significant event times if they are given
            if ~isempty(bl.plot_params.significant_event_times)              
                for iSigTime = 1:length(bl.plot_params.significant_event_times)
                    [val sig_ind] = min(abs(the_interval -  bl.plot_params.significant_event_times(iSigTime)));
                    line([sig_ind sig_ind], get(gca, 'YLim'), 'color', [0 0 0]);
                end
            end

            
            if bl.bin_alignment == 1
                xlabel('Time (ms) center of bins aligned')
            elseif bl.bin_alignment == 2
                xlabel('Time (ms) ends of bins aligned')
            elseif bl.bin_alignment == 3
                xlabel('Time (ms) beginning of bins al')
            end
                
            ylabel('Bin size')
            
            
            % need to fix the below code to work with different alignments...
                        
%             [vals max_bin_size_inds equal_max_value1] = randmax(squeeze(bl.binsize_latency_matrix(iSite, :, :)));
%             [val max_latency_ind equal_max_value2] = randmax(vals);
%             
%             the_max_latency = the_interval(max_latency_ind);
%             the_max_binsize = bl.bin_widths(max_bin_size_inds(max_latency_ind));
%             
%             tie_latency_char = '';  tie_binwidth_char = '';
%             if equal_max_value2 == 1
%                 tie_latency_char = '*';   
%             end            
%             if equal_max_value1(max_latency_ind) == 1   % not exactly correct, b/c might have randomly selected a latency that has not binwidth ties, 
%                 tie_binwidth_char = '*';                %  but there could be other latencies that do have binwidth ties, but good enough for now...
%             end
%             
%             title(['Max binsize = ' num2str(the_max_binsize)  tie_binwidth_char '   Max latency = '  num2str(the_max_latency)  tie_latency_char '   Max value = ' num2str(val)]);
%             

            h = gcf;
            if ~isempty(bl.movie_save_name)
                    F = getframe(h);  % getframe(gcf);
                    mov = addframe(mov, F);
            else
                    pause
            end
            
           
            
            
        end            
        
        
        
        if ~isempty(bl.movie_save_name)
            mov = close(mov);
        end
        
        
        
    end
    
    
    
  
    

end  % end static methods



end % end classdef
   
    
    
    
    
    
 
    



