source("preprocessing/lfp_preprocessing.R")

ind_variables <- readxl::read_excel("data/LASI Family Variable List.xlsx",sheet="wave1") %>% 
  rename("selected" = individual) %>% 
  dplyr::select(level,new_var,selected) %>% 
  dplyr::filter(!is.na(selected))

bio_variables <- readxl::read_excel("data/LASI Family Variable List.xlsx",sheet="wave1") %>% 
  rename("selected" = biomarker) %>% 
  dplyr::select(level,new_var,selected) %>% 
  dplyr::filter(!is.na(selected))


biomarker <- haven::read_dta(paste0(path_lasi_data,"/AllstatesUTs/4_LASI_W1_Biomarker.dta"),
                             col_select = na.omit(bio_variables$selected)) %>% 
  rename_with(~ bio_variables$new_var[which(bio_variables$selected == .x)], 
              .cols = bio_variables$selected) %>% 
  mutate_at(vars(prioractivity_bp,bulky_circumference),function(x) case_when(x == 2 ~ 0,
                                                                             x == 1 ~ 1,
                                                                             TRUE ~ NA_real_)) %>% 
  dplyr::select(personid,prioractivity_bp,sbp1,sbp2,sbp3,sbp,dbp1,dbp2,dbp3,dbp,height,weight,waistcircumference,
                bulky_circumference,hipcircumference)  %>% 
  mutate(bmi = case_when(!is.na(height) ~ weight/(height/100)^2,
                         TRUE ~ NA_real_))


individual <- haven::read_dta(paste0(path_lasi_data,"/AllstatesUTs/3_LASI_W1_Individual.dta"),
                              col_select = na.omit(ind_variables$selected)) %>% 
  rename_with(~ ind_variables$new_var[which(ind_variables$selected == .x)], 
              .cols = ind_variables$selected) %>% 
  left_join(biomarker,
            by="personid") %>% 
  lfp_preprocessing(.)



saveRDS(individual,paste0(path_cascade_folder,"/working/lasi1_individual.RDS"))

