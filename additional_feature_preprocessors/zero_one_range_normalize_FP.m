classdef zero_one_range_normalize_FP
    
% zero_one_range_normalize_FP is a feature preprocessing (FP) object that
%   normalizes each feature so that it has a maximum firing rate of 1 and a minimum 
%   firing rate of zero on the training data by subtracting the minium firing rate
%   and then dividing by the maximum firing rate.  These normalization parameters
%   are then applied to the test data (thus the test data can have values outside of the 
%   range of 0-1). 
%
% This object is useful if some features have different scales of activity, 
%   but one does not want a particular feature to dominate.  For example, 
%   different neurons might have very different ranges of firing rates, so 
%   applying this object can help ensure that neurons with higher firing rates 
%   are not the only neurons that are contributing to the classification results.
%
%
% Like all FP objects, there are two main methods, which are:
%
%  1. [fp XTr_normalized] = set_properties_with_training_data(fp, XTr) 
%        This method takes the training data (XTr) and calculates the minimum and 
%        and maximum value (after the minimum has been subtracted) for each feature 
%        (and changes the state of the object to contain these values).  It also 
%        returns a 0-1 normalized version of the training data (XTr_normalized), 
%        using these mean and stdev values.  
% 
%  2. X_normalized = preprocess_test_data(fp, X_data)
%       This method takes other data (e.g., the test data), and applies the 
%       0-1 normalization to this data using the parameters learned from the 
%       training data.
%
%  3. current_FP_info_to_save = get_current_info_to_save(fp).  Returns
%       an empty matrix indicating that there is no additional information to save
%       for this feature preprocessor.
%
%  Note: X_data is in the form [num_features x num_examples] 
%


%==========================================================================

%     This code is part of the Neural Decoding Toolbox.
%     Copyright (C) 2011 by Ethan Meyers (emeyers@mit.edu)
% 
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
%==========================================================================    




    properties 
        min_XTr = [];
        max_after_min_subtracted_XTr = [];
    end


    methods 

        % constructor 
        function fp = zero_one_range_normalize_FP
        end


        function current_FP_info_to_save = get_current_info_to_save(fp)
            current_FP_info_to_save = [];  % this FP object does not have any information that can be saved
        end
        

        function [fp XTr_normalized] = set_properties_with_training_data(fp, XTr, tilda_junk)   % inputs should really be (fp, XTr, YTr), matlab creators really do not understard OOP
        %function [fp XTr_normalized] = set_properties_with_training_data(fp, XTr, ~)  % changed this line so that the toolbox will be compatible with older versions of matlab  
         
        
            fp.min_XTr = min(XTr')';      
            XTr_after_min_subtracted = XTr - repmat(fp.min_XTr, [1, size(XTr, 2)]);
            
            max_after_min_subtracted_XTr = max(XTr_after_min_subtracted')';
            
            fp.max_after_min_subtracted_XTr = max_after_min_subtracted_XTr + ~max_after_min_subtracted_XTr;   % if max of 0, set it to 1 (not sure if this is the best thing to do)

            XTr_normalized = fp.preprocess_test_data(XTr);
               
        end


        function X_normalized = preprocess_test_data(fp, X_data)
            X_normalized = (X_data - repmat(fp.min_XTr, 1, size(X_data, 2)))./(repmat(fp.max_after_min_subtracted_XTr, 1, size(X_data, 2)));  
        end

        
        
    end  % end methods
    
end    % end classdef




    
    
    

 











