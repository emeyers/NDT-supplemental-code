classdef train_ds1_test_ds2_DS
    
    
 properties 
     
          the_datasource1;
          the_datasource2;
    
 end
 
 
 
    methods
     
          function ds = train_ds1_test_ds2_DS(ds1, ds2)          
              ds.the_datasource1 = ds1;
              ds.the_datasource2 = ds2;
          end


          function the_properties = get_DS_properties(ds)

              the_properties.ds1 = get_DS_properties(ds.the_datasource1);
              the_properties.ds2 = get_DS_properties(ds.the_datasource2);

          end


          function  [XTr_all_time_cv YTr_all_cv XTe_all_time_cv YTe_all_cv ADDITIONAL_DATASOURCE_INFO] = get_data(ds) 


                  [XTr_all_time_cv YTr_all_cv not_used_XTe not_used_YTe ADDITIONAL_DATASOURCE_INFO] = ds.the_datasource1.get_data;   


                  ds.the_datasource2.sites_to_use = ADDITIONAL_DATASOURCE_INFO.curr_bootstrap_sites_to_use;  % will need to set which sites to use before calling this function


                  [not_used_XTr not_used_YTr XTe_all_time_cv YTe_all_cv ADDITIONAL_DATASOURCE_INFO] = ds.the_datasource2.get_data;   

                  
                  % could add some sanity checking here (e.g., make sure the dimensions of training and test data are the same...)


          end
          
          
      
    end   % end methods
    
    
 
 
end
    
    
    
    
    
    
    