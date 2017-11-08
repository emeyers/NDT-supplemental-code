function raster_table = convert_raster_matrix_format_to_raster_table(raster_data, raster_labels, raster_site_info)
%
% A function that takes data in raster-matrix format: i.e., raster_data, raster_labels, raster_site_info and converts it into
%  raster-table format. For more information about these formats see: http://www.readout.info/toolbox-design/data-formats/raster-format/ 
%
%  Data in raster-table format has the following attributes:
%
%    1. The raster_data variable names in the table are in the format raster_data_time_x, where x refers to the time in the experiment.
%        If raster_site_info.alignment_event_time then this is set to time 0 (and times before event onset are indicated with an n)
%        otherwise x is consecutive numbers. 
%
%    2. All raster_labels are in the format raster_label_LABEL_NAME where LABEL_NAME is the specific label name. The label names are stored
%       as categorical variables.
%
%    3. The raster_site info is in the table property's UserData at: raster_table2.Properties.UserData
%
%    4. The field raster_table.Properties.VariableDescriptions indicates whether each variable is either 'rater_labels' or 'raster_data'
%
%
%
%
%  Input arguments:
%  
%    1. raster_data: raster_data in raster-matrix format, i.e., a matrix of data
%    2. raster_labels: raster_labels in raster-matrix format, i.e., a structure of label information
%    3. raster_site_info: raster_site_info in raster_matrix format, i.e., a structure containing meta information
%
%  Output arguments:
%  
%    1. raster_table: raster_data in raster-table format
%


% prefixes to be appended to the variable names for the raster_data variables and the raster_label variables
raster_data_prefix = 'time_';  %'raster_data_time_';
raster_label_prefix = '';  %'raster_labels_';


% add the times to the raster_data names as well
time_names = 1:size(raster_data, 2);

if isfield(raster_site_info, 'alignment_event_time') 
    time_names = time_names - raster_site_info.alignment_event_time;
end

time_names = strtrim(cellstr(num2str(time_names'))');  % get rid of leading spaces (could zero pad too?)
time_names = strrep(time_names, '-', 'n');   % replace minus sign with the letter n
%time_names =  strcat('raster_data_time_', time_names);  % concatenate 'raster_data_time_' to the experiment times
time_names =  strcat(raster_data_prefix, time_names);  % concatenate 'time_' to the experiment times


% create the raster table with the that has the data
raster_table = array2table(raster_data, 'VariableNames', time_names);


% create VariableDescriptions information that all this all these variables are data
data_type_description = repmat('raster_data', size(raster_data, 2), 1);
raster_table.Properties.VariableDescriptions =  cellstr(data_type_description);





% Add the raster_labels to the table

label_names = fields(raster_labels);
label_table = table();  % first creating a label_table rather than directly appending to raster_table 
                        % so that labels stay in the same order as in original raster_labels
                       
for iLabel = 1:numel(label_names)
    
    curr_label_name = label_names{iLabel};    
    curr_labels = eval(['raster_labels.' curr_label_name]);
    %curr_labels_as_table = cell2table(curr_labels', 'VariableNames', {['raster_labels_' curr_label_name]});
    curr_labels_as_table = cell2table(curr_labels', 'VariableNames', {[raster_label_prefix curr_label_name]});

    
    % convert the strings to a categorical variable 
    eval(['curr_labels_as_table.' raster_label_prefix curr_label_name ' =  categorical(curr_labels_as_table.' raster_label_prefix curr_label_name ');']);
  
    label_table = [label_table curr_labels_as_table];
       
end


% create VariableDescriptions information that all these variables are raster_labels
data_type_description = repmat('raster_labels', numel(label_names), 1);
label_table.Properties.VariableDescriptions =  cellstr(data_type_description);


% append label_table to the raster_table
raster_table = [label_table raster_table];





% Add the raster_site_info and other meta information
raster_table.Properties.UserData.raster_site_info = raster_site_info;


% add a description of the raster data...
raster_table.Properties.Description = 'Raster data in raster table format. See http://www.readout.info/toolbox-design/data-formats/raster-format/ for more details';






















