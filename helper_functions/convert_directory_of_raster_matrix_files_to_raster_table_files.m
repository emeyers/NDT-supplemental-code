function convert_directory_of_raster_matrix_files_to_raster_table_files(basedir_name, savedir_name)


% create the save dir if it does not exist...
if ~exist(savedir_name)
    mkdir(savedir_name)
end


file_names = dir([basedir_name '*.mat']);

for iFile = 1:numel(file_names)

    
    % print a message about the progress of how many sites have been converted
    curr_bin_string = ['Converting raster-matrix to raster-table file: ' num2str(iFile) ' of ' num2str(numel(file_names))];
    if iFile == 1
        disp(curr_bin_string); 
    else
        fprintf([repmat(8,1,bin_str_len) curr_bin_string]);         
    end
    bin_str_len = length(curr_bin_string);
    
    
    
    curr_file_name = file_names(iFile).name;
    
    load([basedir_name curr_file_name]);

    raster_table = convert_raster_matrix_format_to_raster_table(raster_data, raster_labels, raster_site_info);
    
    try 
        curr_file_name = strrep(curr_file_name, 'data', 'table');
    end
    
    save([savedir_name curr_file_name], 'raster_table')

        
    clear raster_table raster_data  raster_labels raster_site_info time_vals

    
end


% print a new line at the end so that the prompt is left justified
fprintf('\n')

