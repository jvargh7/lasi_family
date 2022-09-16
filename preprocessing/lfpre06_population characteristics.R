
lasipop_df <- readRDS(paste0(path_cascade_folder,"/working/lasi1_individual.RDS")) %>%
  mutate(residence = case_when(residence == 1 ~ "Rural",
                               residence == 2 ~ "Urban"),
         status = case_when(is.na(htn_free) ~ "Excluded",
                            !is.na(htn_free) ~ "Analytic")) 

lasipop_svydesign <- lasipop_df %>% 
  as_survey_design(.data = .,
                   ids = psu,strata = state,
                   weight = sampleweight,
                   nest = TRUE,
                   variance = "YG",pps = "brewer")
