classdef combine_ds1_and_ds2_DS < handle
    
    
 properties 
     
          the_datasource1;
          the_datasource2;
    
 end
 
 
 
    methods
     
          function ds = combine_ds1_and_ds2_DS(ds1, ds2)          
              ds.the_datasource1 = ds1;
              ds.the_datasource2 = ds2;
          end


          function the_properties = get_DS_properties(ds)

              the_properties.ds1 = get_DS_properties(ds.the_datasource1);
              the_properties.ds2 = get_DS_properties(ds.the_datasource2);

          end


          function  [XTr_all_time_cv YTr_all_cv XTe_all_time_cv YTe_all_cv] = get_data(ds) 

              
              % sanity checks
              if (ds.the_datasource1.num_resample_sites ~= ds.the_datasource2.num_resample_sites)
                  error('The number of resample sites for datasource 1 does not equal the number of resample sites for data source 2')
              end
              

              if (sum(ds.the_datasource1.sites_to_use ~= ds.the_datasource2.sites_to_use) > 0)
                  error('Datasource 1 and datasource 2 must select their data from the same potential sites')
              end
              
              
              if (sum(ds.the_datasource1.sites_to_exclude ~= ds.the_datasource2.sites_to_exclude) > 0)
                  error('Datasource 1 and datasource 2 must select their data from the same potential sites')
              end
              
              
              if (ds.the_datasource1.sample_sites_with_replacement ~= ds.the_datasource2.sample_sites_with_replacement)
                  error('Datasource 1 and datasource 2 must agree on whether they sample with replacement')
              end
              
              
              
              % probably more sanity checks I would add, but going to stop for now...
              


               % select the random sites num_resample_sites out of the larger possible sites_to_use
               % set both datasources to use these same sites...

               sites_to_use = ds.the_datasource1.sites_to_use;   % already checked that datasource2 has these same sites
               num_resample_sites = ds.the_datasource1.num_resample_sites; % already checked that both data sources are using the same # of sites
               sample_sites_with_replacement = ds.the_datasource1.sample_sites_with_replacement;
               

                if ~(sample_sites_with_replacement)   % only use each feature once in a population vector
                    curr_resample_sites_to_use = sites_to_use(randperm(length(sites_to_use)));
                    curr_resample_sites_to_use = sort(curr_resample_sites_to_use(1:num_resample_sites));  % sorting just for the heck of it

                else   % selecting random features with replacement (i.e., the same feature can be repeated multiple times in a population vector).    
                    initial_inds = ceil(rand(1, num_resample_sites) * num_resample_sites);  % can have multiple copies of the same feature within a population vector
                    curr_resample_sites_to_use = sort(sites_to_use(initial_inds));    
                end

                
                
                

                ds.the_datasource1.set_specific_sites_to_use(curr_resample_sites_to_use);
                ds.the_datasource2.set_specific_sites_to_use(curr_resample_sites_to_use);

            
            
              [XTr_all_time_cv1 YTr_all_cv1 XTe_all_time_cv1 YTe_all_cv1] = ds.the_datasource1.get_data;   


              [XTr_all_time_cv2 YTr_all_cv2 XTe_all_time_cv2 YTe_all_cv2] = ds.the_datasource2.get_data;   


              % could add some sanity checking here (e.g., make sure the dimensions of training and test data are the same...)


              % combine the data here...

              keyboard

                  
                  
                  

          end
          
          
      
    end   % end methods
    
    
 
 
end
    
    
    
    
    
    
    