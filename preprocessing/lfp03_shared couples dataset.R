individual <- readRDS(paste0(path_lasi_family_folder,"/working/lasi1_individual.RDS"))  %>% 
  mutate_at(vars(hhid,personid),~as.numeric(.))
couples_ids <- readRDS(paste0(path_lasi_family_folder,"/working/lasi1_couples_ids.RDS")) %>% 
  mutate_at(vars(hhid,wife,husband),~as.numeric(.))

couples_df <- couples_ids %>% 
  left_join(individual %>% 
              dplyr::select(state,residence,
                            sampleweight,
                            
                            wealth, religion, caste,
                            
                            hhid,personid,
                            sbp,dbp,
                            diagnosed_bp,medication_bp,
                            waistcircumference,hipcircumference,
                            age, weight, height, bmi, 
                            eduyr, education, smokeever,smokecurr, smokecount, alcohol, 
                            insurance, htn
              ) %>% 
              rename_at(vars(sbp:htn),~paste0("w_",.)),
            
            by = c("hhid","wife"="personid")
            
  ) %>% 
  left_join(individual %>% 
              dplyr::select(
                hhid,personid,
                sbp,dbp,
                diagnosed_bp,medication_bp,
                waistcircumference,hipcircumference,
                age, weight, height, bmi, 
                eduyr, education, smokeever,smokecurr, smokecount, alcohol, 
                insurance, htn
              ) %>% 
              rename_at(vars(sbp:htn),~paste0("h_",.)),
            
            by = c("hhid","husband"="personid")
            
  )

couples_df %>% 
  dplyr::select(-wife_age,-husband_age) %>% 
  dplyr::filter(!is.na(w_age)& !is.na(h_age)) %>% 

saveRDS(.,paste0(path_lasi_family_folder,"/working/LASI Couples.RDS"))
