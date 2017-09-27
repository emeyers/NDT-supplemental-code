function [ANOVA_pvals ANOVA_STATS] = compute_oneway_ANOVA(X_data, Y_labels)
% A helper function that does a one-way ANOVA on each time point.  This is 
%   essentially the same as running anova1 separately on each time point 
%   although this code is much faster. The input arguments to this function are: 
%  
%   1.  X_data:  that data in the form [num_samples x num_time_points]       
%       
%   2.  Y_labels: a vector of labels of the size [num_samples x 1]   
%
% Output: 
%   
%   1. ANOVA_pvals: the p-values for time point
%   
%   2. ANOVA_STATS: all the additional ANOVA statistics.  These are the same
%       statistics that are returned by anova1's ANOVATAB and STATS structures, 
%       as well as an estimate of eta squared.
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



unique_labels = unique(Y_labels);


for iLabel = 1:length(unique_labels)
    num_unique_labels(iLabel) = length(find(Y_labels == unique_labels(iLabel)));
end

if sum(abs(diff(num_unique_labels))) ~= 0   % there are a different number of examples for some of the labels, so need to run a slightly slower version of the code
    
    
    for iLabel = 1:length(unique_labels)
        X_data_ANOVA_format{iLabel} = X_data(Y_labels == unique_labels(iLabel), :);
    end

    [ANOVA_pvals ANOVA_STATS] = oneway_ANOVA_unbalanced(X_data_ANOVA_format);

    
else     % all the classes have the same number of examples, can use a sligttly faster version of the code...
    
    X_data_reshaped = zeros(num_unique_labels(1), length(unique_labels), size(X_data, 2));   % save time by preallocating memory
    
    for iLabel = 1:length(unique_labels)       
        X_data_reshaped(:, iLabel, :) = X_data(Y_labels == unique_labels(iLabel), :);   %(X_data(:, (Y_labels == unique_labels(iLabel))))';
    end
    
    
    [ANOVA_pvals ANOVA_STATS] = oneway_ANOVA_balanced(X_data_reshaped);

end


ANOVA_pvals = ANOVA_pvals';

    

% save the ANOVA_STATS.gnames as the numbers given to specify the groups in the ANOVA 
%ANOVA_STATS.stats.gnames = mat2cell(num2str(unique_labels)', 1, ones(length(unique_labels), 1))';   % giving an error so commented it out for now





function [pvals ANOVA_STATS] = oneway_ANOVA_balanced(ANOVA_data)
% A helper function that calcuate the balanced one-way ANOVA p-value for each feature,
%   i.e., calculates the one-way ANOVA p-values when there are the SAME number of points 
%   in all groups.
% ANOVA_data is a tensor of:  [num_points_per_group x num_groups x num_features]


[num_points_per_group, num_groups, num_features] = size(ANOVA_data);


overall_mean = mean(mean(ANOVA_data, 1), 2);  % mean for all of the features (over all points)
mean_for_each_group = mean(ANOVA_data, 1);


between_group_degrees_of_freedom = (num_groups -1);
within_group_degrees_of_freedom = num_groups .* (num_points_per_group -1);    % (obvious change this if there are are different number of points per group)


% Using MATLAB's notation: RSS (regression SS), TSS (total SS), and SSE (SS error), where TSS = RSS + SSE   

% Regression Sum of Squares: sum of how much the groups deviate from the grand mean (times of number of points per group); i.e., how much of the TSS does the group explain
RSS = num_points_per_group .* sum( (mean_for_each_group - repmat(overall_mean,[1,num_groups])).^2 ,2);   

% Total Sum of Squares: total of how much all the points differ from the overall mean
TSS = sum(sum((ANOVA_data - repmat(overall_mean,[num_points_per_group, num_groups])).^2,1)); 

% Sum of Squared Errors: difference between the total deviations from the group deviations; i.e., how much SS is not explained by the groups
SSE = TSS - RSS;    


if (within_group_degrees_of_freedom > 0)
   MSE = SSE/within_group_degrees_of_freedom;
else
   MSE = NaN;
end

%F = repmat(Inf,[1,1,num_features]);     % should this be Inf's or zeros (want p-values of 1 for the case when mean for both classes is zero)
F = zeros(num_features, 1);
pvals = ones(num_features, 1);            

indices = find(SSE~=0);   % to prevent errors ...
F(indices) = (RSS(indices)/between_group_degrees_of_freedom) ./ MSE(indices);  

pvals(indices) = 1 - fcdf(F(indices), between_group_degrees_of_freedom, within_group_degrees_of_freedom);     % probability of the F ratio if the means of all groups are equal


pvals = squeeze(pvals);


% calculate everything in the anova1 anovatab  (plus the eta.^2 values)

ANOVA_STATS.Group_SS = squeeze(RSS);
ANOVA_STATS.Error_SS = squeeze(SSE);
ANOVA_STATS.Total_SS = squeeze(TSS);
ANOVA_STATS.Group_df = between_group_degrees_of_freedom; 
ANOVA_STATS.Error_df = within_group_degrees_of_freedom;
ANOVA_STATS.Total_df = within_group_degrees_of_freedom + between_group_degrees_of_freedom;
ANOVA_STATS.Group_MS = ANOVA_STATS.Group_SS./between_group_degrees_of_freedom;
ANOVA_STATS.Error_MS = squeeze(MSE);

ANOVA_STATS.F = F;
ANOVA_STATS.pvalue = pvals;

ANOVA_STATS.eta_squared = ANOVA_STATS.Group_SS./(ANOVA_STATS.Total_SS +~ ANOVA_STATS.Total_SS);   %RSS./(TSS +~ TSS); 


% calculate everything in the anova1 stats structure 
ANOVA_STATS.stats.n = num_points_per_group .* ones(size(mean_for_each_group, 2), 1);
ANOVA_STATS.stats.source = 'compute_oneway_ANOVA__balanced';
ANOVA_STATS.stats.means = squeeze(mean_for_each_group)';
ANOVA_STATS.stats.df = within_group_degrees_of_freedom;
ANOVA_STATS.stats.s =  sqrt(ANOVA_STATS.Error_MS);









function [pvals ANOVA_STATS] = oneway_ANOVA_unbalanced(ANOVA_data)
% A helper function that calcuate the unbalanced ANOVA p-value for each feature, 
%   i.e., calculates a one-way ANOVA p-value when there are the DIFFERENT numbers of 
%   points in at least some of the groups.
%   ANOVA_data is a cell array:  ANOVA_data{num_groups} = [num_points_in_group x num_features]


num_groups = length(ANOVA_data);
num_features = size(ANOVA_data{1}, 2);   

for iGroup = 1:num_groups
    num_points_per_group(iGroup) = size(ANOVA_data{iGroup}, 1);    
    mean_for_each_group(iGroup, :) = mean(ANOVA_data{iGroup}, 1);
    
    sum_of_each_group(iGroup, :) = sum(ANOVA_data{iGroup}, 1);
    
    sum_of_squared_points_for_each_group(iGroup, :) = sum(ANOVA_data{iGroup}.^2, 1);   % used for alterative way to calculate p-values
    
end


overall_mean = sum(sum_of_each_group, 1)./repmat(sum(num_points_per_group), [1, num_features]);     % a real average over all points (groups with more points have a larger weight)


between_group_degrees_of_freedom = (num_groups -1);
within_group_degrees_of_freedom = sum(num_points_per_group - 1);    


for iGroup = 1:num_groups
    RSS_by_group(iGroup, :) = num_points_per_group(iGroup) .* (mean_for_each_group(iGroup, :) - overall_mean).^2;   %  sum of how much the groups deviate from the grand mean (times of number of points per group)
    TSS_by_group(iGroup, :) = sum((ANOVA_data{iGroup} - repmat(squeeze(overall_mean'), [1 num_points_per_group(iGroup)])').^2,1);  % total of how much all the points differ from the overall mean
end

RSS = sum(RSS_by_group, 1);  % between group sum of squares (SSb)  (also called treatment sum of squares)
TSS = sum(TSS_by_group, 1);  % total sum of squares (SStot)
SSE = TSS - RSS;    % difference between the total deviations from the group deviations (i.e. within group sum of squares (SSw) where SStot = SSb + SSw)


if (within_group_degrees_of_freedom > 0)
   MSE = SSE/within_group_degrees_of_freedom;
else
   MSE = NaN;
end


F = zeros(num_features, 1);
pvals = ones(num_features, 1);            

indices = find(SSE~=0);   % to prevent errors ...
F(indices) = (RSS(indices)/between_group_degrees_of_freedom) ./ MSE(indices);  

pvals(indices) = 1 - fcdf(F(indices), between_group_degrees_of_freedom, within_group_degrees_of_freedom);     % probability of the F ratio if the means of all groups are equal


pvals = squeeze(pvals);



% calculate everything in the anova1 anovatab  (plus the eta.^2 values)

ANOVA_STATS.Group_SS = RSS';
ANOVA_STATS.Error_SS = SSE';
ANOVA_STATS.Total_SS = TSS';
ANOVA_STATS.Group_df = between_group_degrees_of_freedom; 
ANOVA_STATS.Error_df = within_group_degrees_of_freedom;
ANOVA_STATS.Total_df = within_group_degrees_of_freedom + between_group_degrees_of_freedom;
ANOVA_STATS.Group_MS = (RSS./between_group_degrees_of_freedom)';
ANOVA_STATS.Error_MS = MSE';

ANOVA_STATS.F = F;
ANOVA_STATS.pvalue = pvals;

ANOVA_STATS.eta_squared = RSS./(TSS +~ TSS); 


% calculate everything in the anova1 stats structure 
ANOVA_STATS.stats.n = num_points_per_group;
ANOVA_STATS.stats.source = 'compute_oneway_ANOVA__unbalanced';
ANOVA_STATS.stats.means = mean_for_each_group';
ANOVA_STATS.stats.df = within_group_degrees_of_freedom;
ANOVA_STATS.stats.s =  sqrt(MSE);







% extra functions that allow one to disply an anova table and use the multcompare
%  function for data that is in the ANOVA_STATS format


function oneway_anova_multcompare(ANOVA_STATS, iTime)
% calls the multcompare function using data that is in the ANOVA_STATS format

anova_stats.n = ANOVA_STATS.stats.n;

anova_stats.source = 'anova1';
anova_stats.means = ANOVA_STATS.stats.means(iTime, :);
anova_stats.df = ANOVA_STATS.stats.df;
anova_stats.s = ANOVA_STATS.stats.s(iTime);
anova_stats.gnames = ANOVA_STATS.stats.gnames;

multcompare(anova_stats)




function display_oneway_anova_table(ANOVA_STATS, iTime)
% display an ANOVA table using results in ANOVA_STATS format

anova_tab1  = {'Source',     'SS',            'df',     'MS',            'F',         'Prob>F'};
anova_tab2 = {'Groups', ANOVA_STATS.Group_SS(iTime), ANOVA_STATS.Group_df, ANOVA_STATS.Group_MS(iTime), ANOVA_STATS.F(iTime), ANOVA_STATS.pvalue(iTime)};
anova_tab3 = {'Error', ANOVA_STATS.Error_SS(iTime), ANOVA_STATS.Error_df, ANOVA_STATS.Error_MS(iTime), [], []};
anova_tab4 = {'Total', ANOVA_STATS.Total_SS(iTime), ANOVA_STATS.Total_df, [], [], []};

for i = 1:6, 
    anova_tab{1, i} =  anova_tab1{i};
    anova_tab{2, i} =  anova_tab2{i};
    anova_tab{3, i} =  anova_tab3{i};
    anova_tab{4, i} =  anova_tab4{i};
end

statdisptable(anova_tab, 'Oneway ANOVA', 'Oneway ANOVA', '')






