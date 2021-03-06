classdef min_angle_CL

% min_angle_CL is a classifier object (CL) 
%  that learns a mean population vector (template) for each class from the 
%  training data.  When the classifier is tested, the cosine angle
%  is calculated between a test point and each of the class templates, and the 
%  class with the smallest angle between the test point and the templates is selected as the label
%  (and the decision values are the cosine angles).  If there is a only one
%  features in XTr (and XTe), the decision is made based on the shortest squared
%  deviation between training and test value (and the negative of these distances are 
%  returned as decision values). If two or more classes with the same smallest cosine angle
%  then one of the tied classes is chosen randomly as the predicted label.  Overall this is
%  very similar to the maximum correlation coefficient classifier except the mean
%  value over sites for each template and test point is not subtracted before the dot products are taken.
%
%
% Like all CL objects, there are two main methods, which are:
%
%  1.  cl = train(cl, XTr, YTr) 
%         This method takes the training data (XTr, YTr) and learns a mean vector
%           (i.e., a template) for each class.
% 
%  2.  [predicted_labels decision_values] = test(cl, XTe)
%         This method takes the test data and calculates the angle
%           value between each test point and each learned class template.  The 
%           predicted label for a test point is the class that had the smallest angle
%           value with the test point, and the decision values are the
%           cosine of these angles
%
%
%  Notes:  
%    1.  If there is only one feature in XTr and XTe, then the prediction 
%         is made based on the negative of the squared difference between the test
%         feature and the training feature for each class (and these are the
%         decision values that are returned).
%
%    2.  If there is a tie among the decision values  (i.e., if the corrcoef
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
        function cl = min_angle_CL
        end
        
        
        function cl = train(cl, XTr, YTr)  

            % added sanity check
            if size(YTr, 2) ~= size(XTr, 2)  &&  size(YTr, 1) ~= size(XTr, 2) 
               error('Number of columns in YTr, and XTr must be the same (i.e., there must be one and exactly one label for each data point)') 
            end

            unique_labels = unique(YTr);

            for i = 1:length(unique_labels)
                template(:, i) = mean(XTr(:, (YTr == unique_labels(i))), 2);
            end

            cl.templates = template;
            cl.labels = unique_labels;
            
        end
            

        
        function [predicted_labels decision_values] = test(cl, XTe)
        
                  
            if size(XTe, 1) > 1   % if each data point is only 1 dimensional (could return an error, but instead just returning the template that had the closest value)
           
                
                 %normalization_matrix = sqrt(diag(cl.templates' * cl.templates)) * sqrt(diag(XTe' * XTe))';
                 normalization_matrix = sqrt(sum(cl.templates .* cl.templates))' * sqrt(sum(XTe .* XTe));   % slightly faster
 
                 template_corrcoeffs = ((cl.templates' * XTe)./normalization_matrix)';
                

            
            else   %  if there is only one feature, select the class with closest value to that feature

                % the squared difference between each class mean and each test point  (which are both scalars)
                template_corrcoeffs  = -1 .* (repmat(cl.templates, [size(XTe, 2), 1]) - repmat(XTe', [1 size(cl.templates, 2)])).^2;   
                
            end

            
            [val ind] = randmax(template_corrcoeffs');   % using randmax to deal with ties in max correlation value
            predicted_labels = cl.labels(ind);
            decision_values = template_corrcoeffs; 


            if (size(template_corrcoeffs, 1) .* size(template_corrcoeffs, 2)  ~= sum(sum(isfinite(template_corrcoeffs))))
               warning('this matrix contains some numbers that are not finite!!!')
            end
            
            
        end
        
    end  % end public methods
       
   

   
end   % end classdef








