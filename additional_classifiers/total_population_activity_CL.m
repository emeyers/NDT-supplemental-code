classdef total_population_activity_CL

% total_population_activity_CL is a classifier object (CL) 
%  that learns a scalar value (template) that is the sum of the population activity from all 
%  neurons from the training data (a separate scalar value is learned for each class).  
%  When the classifier is tested, the euclidean distance is calculated between a test point's total 
%  population activity and the population activity from each class template scalar value, 
%  and the class with the smallest euclidean distance value is selected as the label
%  (and the decision values are -1 times the euclidean distance).  
%
%
% Like all CL objects, there are two main methods, which are:
%
%  1.  cl = train(cl, XTr, YTr) 
%         This method takes the training data (XTr, YTr) and learns the mean population activity 
%           scalar (i.e., a template) for each class.
% 
%  2.  [predicted_labels decision_values] = test(cl, XTe)
%         This method takes the test data and calculates the euclidean distance
%           value between each test point total population activity and each learned class scalar template.  
%           The predicted label for a test point is the class that had the smallest euclidean distance
%           value with the test point, and the decision values are -1 times the distance values.
%
%
%  Notes:  
%
%    1.  If there is a tie among the decision values  (i.e., if the distance
%          value is the same for 2 different classes), then one of tied the classes
%          is chosen randomly as the predicted label.
%  
%
%   XTr and XTe are in the form [num_features x num_examples]
%   YTr is in the form [num_examples x 1]
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
        templates = [];   % average of the training vectors for each class
        labels = [];  % all the unique labels for each class (one for each template)  
  end



    methods 

        % constructor 
        function cl = total_population_activity_CL
        end
        
        
        function cl = train(cl, XTr, YTr)  

            % added sanity check
            if size(YTr, 2) ~= size(XTr, 2)  &&  size(YTr, 1) ~= size(XTr, 2) 
               error('Number of columns in YTr, and XTr must be the same (i.e., there must be one and exactly one label for each data point)') 
            end

            unique_labels = unique(YTr);

            
            XTr = sum(XTr);
            
            for i = 1:length(unique_labels)
                template(i) = mean(XTr(YTr == unique_labels(i)));
            end

            cl.templates = template;
            cl.labels = unique_labels;
            
        end
            

        
        function [predicted_labels decision_values] = test(cl, XTe)
        
                              
            XTe = sum(XTe); 
            
            decision_values = -1 .* abs(repmat(cl.templates, [size(XTe, 2)], 1) -  repmat(XTe', [1 size(cl.templates, 2)]));   % for each test point, find the closest population total
                                               
            [val ind] = randmax(decision_values');   % using randmax to deal with ties in max correlation value
            predicted_labels = cl.labels(ind);
            
            
            if (size(decision_values, 1) .* size(decision_values, 2)  ~= sum(sum(isfinite(decision_values))))
               warning('this matrix contains some numbers that are not finite!!!')
            end
            
            
        end
        
    end  % end public methods
       
   

   
end   % end classdef








