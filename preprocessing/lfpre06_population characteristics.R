
lasipop_df <- readRDS(paste0(path_cascade_folder,"/working/lasi1_individual.RDS")) %>%
  mutate(residence = case_when(residence == 1 ~ "Rural",
                               residence == 2 ~ "Urban"),
         status = case_when(is.na(htn_free) ~ "Excluded",
                            !is.na(htn_free) ~ "Analytic")) %>% 
  # Based on Lee 2022 Plos Med
  # They additionally excluded people with missing education
  # Should also excluded missing insurance and household consumption
  # They had data from Pilot wave as well
  mutate(status = case_when(is.na(sbp) | is.na(dbp) ~ "Excluded",
                                 age < 45 ~ "Excluded 2",
                                 na_education == 1 ~ "Excluded 2",
                                 TRUE ~ "Analytic"))

lasipop_svydesign <- lasipop_df %>% 
  as_survey_design(.data = .,
                   ids = psu,strata = state,
                   weight = sampleweight,
                   nest = TRUE,
                   variance = "YG",pps = "brewer")
