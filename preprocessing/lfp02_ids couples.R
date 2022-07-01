lasi_variables <- readxl::read_excel("data/LASI Family Variable List.xlsx",sheet="wave1") %>% 
  rename("selected" = cv_memberfile) %>% 
  dplyr::select(level,new_var,selected) %>% 
  dplyr::filter(!is.na(selected))

cv_memberfile <- haven::read_dta(paste0(path_lasi_data,"/AllstatesUTs/5_LASI_W1_CV_memberfile.dta"),
                                 col_select = na.omit(lasi_variables$selected)) %>% 
  rename_with(~ lasi_variables$new_var[which(lasi_variables$selected == .x)], 
              .cols = lasi_variables$selected) %>% 
  pivot_longer(cols=contains("cv013"),names_to="cv013",values_to="spouseid") %>% 
  dplyr::filter(!is.na(spouseid)) %>% 
  mutate(cv013 = str_replace(cv013,"cv013_","")) %>% 
  rename(spouseindex = cv013) %>% 
  mutate(personid = as.numeric(personid),
         spouseid = as.numeric(hhid) + spouseid)


cv_wife = cv_memberfile %>% 
  dplyr::filter(sex == 2) %>% 
  rename(wife = personid,
         husband = spouseid)
cv_husband = cv_memberfile %>% 
  dplyr::filter(sex == 1) %>% 
  rename(husband = personid,
         wife = spouseid)





bind_rows(cv_wife  %>% 
            dplyr::select(strata,hhid,wife,husband),
          cv_husband  %>% 
            dplyr::select(strata,hhid,wife,husband)) %>% 
  distinct(hhid,wife,husband,.keep_all=TRUE) %>% 
  dplyr::select(strata,hhid,wife,husband) %>% 
  dplyr::filter(!wife %in% husband) %>%
  left_join(cv_memberfile %>% 
              dplyr::select(personid,age) %>% 
              rename(wife_age = age),
            by = c("wife" = "personid")
            ) %>%
  left_join(cv_memberfile %>% 
              dplyr::select(personid,age) %>% 
              rename(husband_age = age),
            by = c("husband" = "personid")
  ) %>% 
  
  group_by(husband) %>%
  mutate(n_wife = n(),
         index_wife = 1:n()) %>%
  ungroup() %>%
  group_by(wife) %>%
  mutate(n_husband = n(),
         index_husband = 1:n()) %>%
  ungroup() %>%
  saveRDS(.,paste0(path_lasi_family_folder,"/working/lasi1_couples_ids.RDS"))

