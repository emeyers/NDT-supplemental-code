function [raster_data, raster_labels, raster_site_info, time_vals] = convert_raster_table_format_to_raster_matrix_data(raster_table)



% extract the raster data
data_inds = strcmp('raster_data', raster_table.Properties.VariableDescriptions);
raster_data_names = raster_table(:, data_inds).Properties.VariableNames;

raster_data = table2array(raster_table(:, data_inds));





% extract time values from the data variable names as well...
raster_data_prefix = 'time_';

time_vals = strrep(raster_data_names, raster_data_prefix, '');
time_vals = strrep(time_vals, 'n', '-');
time_vals = cellfun(@str2num, time_vals);




% extract raster_labels
label_inds = find(strcmp('raster_labels', raster_table.Properties.VariableDescriptions));
label_names = raster_table(:, label_inds).Properties.VariableNames;

for iLabel = 1:numel(label_inds)
    curr_label_name = label_names{iLabel};
    eval(['raster_labels.' curr_label_name ' = transpose(cellstr(char(raster_table(:, label_inds(iLabel)).' curr_label_name  ')));'])
end




% extract the raster_site_info
raster_site_info = raster_table.Properties.UserData.raster_site_info;



