function [binned_data, binned_labels_to_use] = retrieve_binned_format_data(binned_data_name, specific_binned_label_name)
%
% This helper function enables a user to pass either actual binned data or a file name that has binned data in it, and 
%   get back the same binned_data and specific_binned_labels in either case. This is useful for giving the user options of 
%   what should format the binned data should be in that is passed to a particular function. For example, if someone wants to modify
%   the data before passing it to another function (say a single neuron analysis function), then they could load the 
%   binned_data themselves, modify it. They could then pass the modified data to another function which would use the modified data. 
%   Alternatively, if they did not want to modify the data, then they could just specify a file name which is easier than loading the data
%   themselves.
%
%
% This funcion takes two arguments: binned_data_name, specific_binned_label_name. 
%  There are two possible settings for each of these arguments:
%
%   1) If binned_data_name is a cell array of binned data, and specific_binned_label_name is a cell array (or vector) of 
%       label names, then the function just returns these variables unmodified.
%
%   2) If binned_data_name is a string specifying a file name that has data in binned format, and if specific_binned_label_name is a
%       string this that notes the specific labels that should be used, then this function will load the file binned_data_name and return
%       the binned_data and the specific binned labels specified in the string specific_binned_label_name.
%
%   In the future this function could also be extended to use other binned_data formats (e.g., using Matlab's tables). 
%




% See whether the binned_data_name is the name of a file that has binned_data or whether it is is cell array of actual binned_data
if isstr(binned_data_name)
    load(binned_data_name);
else
    binned_data = binned_data_name;
end


% See whether specific_binned_label_name is a string specifying which binned labels should be used
% or a cell array containing the actual binned labels
if isstr(specific_binned_label_name)
    binned_labels_to_use = eval(['binned_labels.' specific_binned_label_name]);
else          
    binned_labels_to_use = specific_binned_label_name;
end









