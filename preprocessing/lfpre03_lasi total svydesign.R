
lasi_df <- readRDS(paste0(path_cascade_folder,"/working/lasi1_individual.RDS")) %>%
  dplyr::filter(!is.na(htn_free)) %>%
  mutate(residence = case_when(residence == 2 ~ "Urban",
                               residence == 1 ~ "Rural")) 



lasi_svydesign <- lasi_df %>% 
  as_survey_design(.data = .,
                   ids = psu,strata = state,
                   weight = sampleweight,
                   nest = TRUE,
                   variance = "YG",pps = "brewer")

